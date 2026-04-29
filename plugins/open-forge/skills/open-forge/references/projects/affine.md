---
name: affine-project
description: AFFiNE recipe for open-forge. MIT/AGPL next-gen knowledge and collaboration space (docs + whiteboard + database hybrid, open-source alternative to Notion + Miro). Covers the upstream-blessed self-host path (Docker Compose from `.docker/selfhost/compose.yml` in `toeverything/AFFiNE` on `canary`) with Postgres (pgvector/pg16) + Redis + AFFiNE server + one-shot migration container. Single-node only; no HA story upstream.
---

# AFFiNE

Open-source knowledge-base / collaboration workspace — combines docs, whiteboards, and databases in one tool. Upstream: <https://github.com/toeverything/AFFiNE>. Self-host docs: <https://docs.affine.pro/docs/self-host-affine> (upstream docs site) and the canonical compose at `.docker/selfhost/compose.yml` on branch `canary`.

AFFiNE self-host is a single-node Docker Compose stack: `affine` server on port `3010`, `postgres` (pgvector/pg16 — the `pgvector` extension is used for AFFiNE's AI features), and `redis`. A separate one-shot `affine_migration` container runs `node ./scripts/self-host-predeploy.js` on startup to apply schema migrations before the server boots. Three bind-mounted volumes persist state: `UPLOAD_LOCATION` (user files / images), `CONFIG_LOCATION` (server config JSON), and `DB_DATA_LOCATION` (Postgres data dir).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (self-host) | `.docker/selfhost/compose.yml` on `canary` | ✅ | The only upstream-documented self-host path. Single-node. |
| AFFiNE Cloud (managed) | <https://app.affine.pro/> | ✅ | Managed SaaS run by toeverything — out of scope for open-forge. |
| Desktop client (local-only) | <https://affine.pro/download> | ✅ | Standalone desktop app (Electron) with local storage; no server required. Not a self-host deploy; skip for open-forge. |
| Dev / from source | `pnpm dev` in repo | ✅ | Contributors only. Out of scope. |

There is **no** officially-blessed Helm chart, Kubernetes operator, or non-Docker install path. Upstream only publishes the Docker Compose flow.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Docker + Docker Compose available on the target host?" | `AskUserQuestion`: `Yes` / `No — install Docker first` | If no, hand off to `runtimes/docker.md` preflight. |
| dns | "What's the FQDN you want AFFiNE on?" (e.g. `affine.example.com`) | Free-text | Required to set `AFFINE_SERVER_HOST` / `AFFINE_SERVER_EXTERNAL_URL`. |
| dns | "Serve over HTTPS (recommended) or HTTP-only for LAN?" | `AskUserQuestion`: `HTTPS via reverse proxy` / `HTTP-only (LAN)` | HTTPS sets `AFFINE_SERVER_HTTPS=true` + requires reverse proxy (Caddy/Nginx/Traefik) in front — AFFiNE server itself does NOT terminate TLS. |
| storage | "Where should AFFiNE persist data on the host?" (default `~/.affine/self-host/`) | Free-text | Sets `DB_DATA_LOCATION`, `UPLOAD_LOCATION`, `CONFIG_LOCATION`. Host paths — must exist and be writable by the container user. |
| db | "Set a Postgres password? (recommended)" | Generated — `openssl rand -hex 32` | Sets `DB_PASSWORD`. Compose ships with `POSTGRES_HOST_AUTH_METHOD: trust` — fine for LAN but you should set a password for anything reachable off-host. |
| release | "Which AFFiNE release channel?" | `AskUserQuestion`: `stable` (default) / `beta` / `canary` | Sets `AFFINE_REVISION`. Use `stable` unless the user specifically wants pre-release. |
| port | "Expose on which host port?" (default `3010`) | Free-text | Sets `PORT` — bound directly on the host unless the reverse proxy binds separately. |

Write all answers to `inputs.*` in state so resume skips re-prompting.

## Install (from upstream's self-host guide)

Upstream's docs page: <https://docs.affine.pro/docs/self-host-affine>. The actual files fetched come from `.docker/selfhost/` on the `canary` branch. Versions of these files are pinned into the Docker image tag chosen via `AFFINE_REVISION`, so clone once, set `.env`, and let the compose file reference the tagged image.

```bash
# 1. Create a working directory
sudo mkdir -p /opt/affine && cd /opt/affine
sudo chown "$USER:$USER" /opt/affine

# 2. Download the three upstream self-host files (DO NOT hand-edit compose.yml)
curl -fsSL -o compose.yml             https://raw.githubusercontent.com/toeverything/AFFiNE/canary/.docker/selfhost/compose.yml
curl -fsSL -o .env                    https://raw.githubusercontent.com/toeverything/AFFiNE/canary/.docker/selfhost/.env.example
curl -fsSL --create-dirs -o config/affine.json \
    https://raw.githubusercontent.com/toeverything/AFFiNE/canary/.docker/selfhost/config.example.json

# 3. Generate a Postgres password + patch .env
DB_PW="$(openssl rand -hex 32)"
sed -i \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PW}|" \
  -e "s|^# *AFFINE_SERVER_HOST=.*|AFFINE_SERVER_HOST=${CANONICAL_HOST}|" \
  -e "s|^# *AFFINE_SERVER_HTTPS=.*|AFFINE_SERVER_HTTPS=true|" \
  .env

# 4. Point the three *_LOCATION paths at a location you're OK persisting
#    (defaults to ~/.affine/self-host/{postgres/pgdata,storage,config})
mkdir -p ~/.affine/self-host/{postgres/pgdata,storage,config}
cp config/affine.json ~/.affine/self-host/config/affine.json

# 5. Bring it up (migration container runs once, then server starts)
docker compose up -d

# 6. Watch it come up
docker compose ps
docker compose logs -f affine   # Ctrl-C once you see "AFFiNE server listening on port 3010"
```

Then put your reverse proxy in front of `http://<host>:3010` (see Caddy recipe for the canonical setup).

## Config surface

Two layers:

1. **`.env`** — deploy-time wiring (image tag, ports, DB creds, bind-mount paths, FQDN).
2. **`config/affine.json`** (bind-mounted to `/root/.affine/config` inside the container) — runtime app config. Schema published at `https://github.com/toeverything/affine/releases/latest/download/config.schema.json`. Minimal example:

   ```json
   {
     "$schema": "https://github.com/toeverything/affine/releases/latest/download/config.schema.json",
     "server": {
       "name": "AFFiNE Self Hosted Server"
     }
   }
   ```

   The admin-panel UI (login to AFFiNE as the first user, who becomes admin) can read/write more config keys at runtime — use the JSON file for bootstrap / disaster-recovery and the admin panel for day-to-day changes.

### Reverse-proxy / TLS

AFFiNE server binds `0.0.0.0:3010` plain HTTP. Terminate TLS upstream (Caddy, Traefik, nginx). Minimal Caddyfile:

```caddy
affine.example.com {
    reverse_proxy localhost:3010
    # AFFiNE uses WebSockets for real-time sync — Caddy's default reverse_proxy
    # handles Upgrade/Connection headers, so no extra config needed.
}
```

When TLS-terminated upstream, set in `.env`:

```
AFFINE_SERVER_HTTPS=true
AFFINE_SERVER_HOST=affine.example.com
# OR (mutually exclusive with the above two)
AFFINE_SERVER_EXTERNAL_URL=https://affine.example.com
```

Then `docker compose up -d --force-recreate affine affine_migration` to pick up the new env.

### SMTP (optional)

AFFiNE sends transactional email (invitations, password resets) via SMTP. Config lives in the runtime JSON (not `.env`). See upstream's config schema at <https://docs.affine.pro/docs/self-host-affine/configuration> for the exact path; as of this writing it's under `mailer.*` keys.

## Upgrade

```bash
cd /opt/affine

# 1. Pick the new revision (stable moves forward automatically if you stay on 'stable')
#    For a manual pin: edit .env to set AFFINE_REVISION=<new-tag>

# 2. Pull new images
docker compose pull

# 3. Up — the migration container re-runs with the new image and applies any
#    new migrations BEFORE the server boots
docker compose up -d

# 4. Verify migrations + server came up cleanly
docker compose logs --tail=100 affine_migration
docker compose logs --tail=100 affine
```

Rollback = set `AFFINE_REVISION` back to the previous tag + `docker compose up -d --force-recreate`. **However:** Postgres migrations may be one-way. Always `pg_dump` before upgrading to a major version.

```bash
# Quick DB dump before upgrading
docker compose exec -T postgres pg_dump -U affine affine | gzip \
  > /opt/affine/backups/affine-$(date +%Y%m%d-%H%M%S).sql.gz
```

## Gotchas

- **`pgvector/pgvector:pg16` image is mandatory** — the compose file pins it; don't swap for vanilla `postgres:16`. AFFiNE's AI / embedding features use the `pgvector` extension, and the server startup will fail if it's missing.
- **Migration container is a *one-shot***. It runs `node ./scripts/self-host-predeploy.js` and exits. If it crashes (check `docker compose logs affine_migration`), the server never starts — `affine_server` has `depends_on.affine_migration.condition: service_completed_successfully`.
- **Postgres `POSTGRES_HOST_AUTH_METHOD: trust` is the compose default** — fine for container-to-container on a private Docker network, but the DB port is NOT published to the host, so external access still requires a password or connection through the container. Set `DB_PASSWORD` anyway for defense-in-depth.
- **`AFFINE_SERVER_EXTERNAL_URL` vs `AFFINE_SERVER_HOST`+`AFFINE_SERVER_HTTPS`** — use one set or the other, not both. Setting both leads to confusing canonical-URL behavior.
- **WebSockets required for real-time sync.** If you stick a reverse proxy with `proxy_http_version 1.0` or an aggressive WAF in front, sync stops working silently. Caddy's `reverse_proxy` and Traefik defaults handle WS correctly; nginx needs explicit `proxy_http_version 1.1` + Upgrade headers.
- **`AFFINE_INDEXER_ENABLED=false` is the compose default.** That disables the background indexer service. Upstream's self-host guide flags the indexer as enterprise/cloud-only; changing it to `true` won't magically enable it without the missing `appflowy_search`-style sidecar.
- **No built-in backup.** Bind-mounted `DB_DATA_LOCATION` / `UPLOAD_LOCATION` / `CONFIG_LOCATION` are yours to snapshot. Stopping the stack + `tar`-ing those three dirs is the simplest backup; restic / borgbackup / `pg_dump` are the grown-up options.
- **Single-node only.** There is no upstream-blessed HA / multi-replica story. If the Postgres container dies, the whole site is down until it comes back.
- **Admin is "first user wins."** The first account created after install becomes workspace owner. Guard the URL during the bootstrap window or the user of your choosing won't be admin.

## Upstream references

- Repo: <https://github.com/toeverything/AFFiNE>
- Self-host docs: <https://docs.affine.pro/docs/self-host-affine>
- Self-host compose + env (source of truth): `.docker/selfhost/` on `canary` branch
- Release tags / channels: <https://github.com/toeverything/AFFiNE/releases>
- Config schema: `https://github.com/toeverything/affine/releases/latest/download/config.schema.json`

## TODO — verify on first deployment

- Confirm the `.docker/selfhost/compose.yml` path / branch is still canonical (upstream sometimes reorganises).
- Verify the `mailer.*` JSON config keys against the latest `config.schema.json`.
- Confirm whether `AFFINE_INDEXER_ENABLED=true` has become useful in self-host (i.e., whether upstream ships a self-hostable indexer service yet).
- Test upgrade path across a major version jump (migrations).
