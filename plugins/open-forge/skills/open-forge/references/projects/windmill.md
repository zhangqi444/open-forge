---
name: Windmill
description: Developer platform for internal tools, workflows, and AI agents. Turns scripts (Python/TypeScript/Go/Bash/SQL) into auto-generated UIs, APIs, and event-triggered workflows. Open-source alternative to Retool + Airflow + Temporal. AGPL-3.0 (core), commercial EE.
---

# Windmill

Windmill lets you write a Python/TS/Go/Bash/SQL script, and instantly get an auto-generated input form, REST endpoint, scheduled cron, and visual flow-composer that can wire scripts together into multi-step workflows. Used for internal tools, ETL, AI agent orchestration, and replacing glue Lambdas.

It's a heavy stack — don't underestimate the memory/CPU footprint. Production Windmill wants ≥8 GB RAM and runs multiple worker replicas.

- Upstream repo: <https://github.com/windmill-labs/windmill>
- Docs: <https://www.windmill.dev/docs>
- Images: `ghcr.io/windmill-labs/windmill` (CE) / `ghcr.io/windmill-labs/windmill-ee` (Enterprise)

## Architecture in one minute

Single `WM_IMAGE` is the Windmill binary; the role is determined by the `MODE` env var:

1. **`windmill_server`** (`MODE=server`) — HTTP API + UI on :8000; also SMTP on :2525
2. **`windmill_worker`** (`MODE=worker`, default group) — runs user scripts; default 3 replicas; privileged (needs PID namespace isolation via `FAVOR_UNSHARE_PID`)
3. **`windmill_worker_native`** (`MODE=worker`, `NATIVE_MODE=true`, `WORKER_GROUP=native`) — lightweight in-process runner for "native" (no-spawn) jobs
4. **`windmill_indexer`** (`MODE=indexer`) — **EE-only** full-text job/log search
5. **`windmill_extra`** — separate image: LSP (code intel), multiplayer (EE), DAP debugger
6. **`dind`** — Docker-in-Docker sidecar so user scripts can `docker run` without the host socket
7. **`caddy`** (custom `caddy-l4` with Layer-4 support) — reverse proxy for HTTP + SMTP (:25)
8. **Postgres 16** — the *only* persistent store; everything else is cache/ephemeral

## Compatible install methods

| Infra                  | Runtime                                 | Notes                                                                  |
| ---------------------- | --------------------------------------- | ---------------------------------------------------------------------- |
| Single VM (8+ GB RAM)  | Docker Compose (upstream `docker-compose.yml`) | **Recommended** for self-hosters                                      |
| Kubernetes             | Helm charts                              | Upstream-maintained: <https://github.com/windmill-labs/windmill-helm-charts> |
| Bare metal             | Source build                             | Documented but not the typical path                                    |
| Managed                | Windmill Cloud                           | Upstream-hosted; EE features + zero ops                                 |

## Inputs to collect

| Input                 | Example                                          | Phase     | Notes                                                            |
| --------------------- | ------------------------------------------------ | --------- | ---------------------------------------------------------------- |
| `WM_IMAGE`            | `ghcr.io/windmill-labs/windmill:main` (CE) / `…windmill-ee:main` (EE) | Runtime | Pin to a release tag, never `:main` in production        |
| `DATABASE_URL`        | `postgres://postgres:PASS@db/windmill?sslmode=disable` | DB | External Postgres supported — set replicas of `db` to 0          |
| `BASE_URL`            | `https://windmill.example.com`                   | Runtime   | Used in generated links, OAuth callback URIs                     |
| Postgres password     | strong password                                  | DB        | Default `changeme` in the upstream `.env`                        |
| Worker replica count  | 3 (default) to 20+ for production                | Runtime   | Scale based on concurrent script executions                      |
| Script runtimes       | Python / Deno / Bun / Go / Bash / SQL / PowerShell | Runtime | Bundled in `WM_IMAGE`; no extra install                          |
| TLS                   | via Caddy auto-HTTPS or own reverse proxy         | Security  | `BASE_URL=mydomain.com` triggers Caddy auto-HTTPS                 |
| SMTP                  | any provider                                     | Runtime   | For password-reset emails, job alerts                             |
| OAuth/OIDC (optional) | Google / GitHub / Keycloak / etc.                | Auth      | Built-in; configure in admin UI                                  |
| Git sync (optional)   | repo URL + token                                 | Runtime   | Store scripts/flows/resources in git                              |

## Install via Docker Compose (recommended)

Upstream `docker-compose.yml` is the source of truth. Pull it alongside `.env` and `Caddyfile`:

```sh
mkdir windmill && cd windmill
curl -O https://raw.githubusercontent.com/windmill-labs/windmill/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/windmill-labs/windmill/main/Caddyfile
curl -O https://raw.githubusercontent.com/windmill-labs/windmill/main/.env

# Pin the image (default .env uses :main which moves daily)
sed -i 's|WM_IMAGE=.*|WM_IMAGE=ghcr.io/windmill-labs/windmill:v1.x.y|' .env  # replace with a release tag

# Set a real Postgres password:
sed -i 's|postgres:changeme|postgres:REPLACE_WITH_STRONG_PASSWORD|' .env
# Remember to also update the POSTGRES_PASSWORD in docker-compose.yml db service

docker compose up -d
```

The stack binds `:80` and `:25` by default (Caddy does both HTTP and SMTP L4). To enable auto-HTTPS, set `BASE_URL=windmill.example.com` in `.env` and uncomment the `- 443:443` port mapping.

First admin: browse `BASE_URL`, create the initial workspace — the first signup becomes admin. **Change the default admin email + password immediately**.

### Scaling workers

The default `deploy.replicas: 3` for `windmill_worker` handles modest loads. For production:

- Increase replicas (`docker compose up -d --scale windmill_worker=10`)
- Run workers on dedicated nodes (Swarm/K8s)
- Split worker groups: default workers, `native` for lightweight, `reports` for Chromium/scraping, `highpriority` for interactive

### DinD vs host Docker socket

Default setup includes a `dind` sidecar — user scripts wanting to `docker run` hit `DOCKER_HOST=tcp://dind:2375` instead of the host socket. This is the safe default.

The upstream compose has a commented-out alternative that mounts `/var/run/docker.sock` directly. **Don't uncomment that in production** unless you fully trust every script author — it gives scripts host-root equivalent.

## Install via Kubernetes (Helm)

```sh
helm repo add windmill https://windmill-labs.github.io/windmill-helm-charts/
helm install windmill windmill/windmill -n windmill --create-namespace \
  --set windmill.baseDomain=windmill.example.com \
  --set postgresql.auth.password=REPLACE_ME
```

Helm values reference: <https://github.com/windmill-labs/windmill-helm-charts>.

## Data & config layout

- **Postgres** — the only persistent store. Users, workspaces, scripts, flows, resources, variables, job history, audit logs, schedules, webhooks.
- `worker_dependency_cache` volume — pip/npm/go caches; recreatable
- `worker_logs` volume — job stdout/stderr; rotated by Windmill
- `windmill_index` volume — search index (EE only)
- `caddy_data` — Let's Encrypt state

Scripts themselves live in Postgres (as text). There is no `/scripts` directory to mount.

## Backup

```sh
# Postgres is everything.
docker compose exec -T db pg_dump -U postgres -Fc windmill > windmill-$(date +%F).dump

# Restore:
docker compose exec -T db pg_restore -U postgres -d windmill < windmill-DATE.dump
```

Git sync (enabled per-workspace) is an operational safety net — your scripts get mirrored into a Git repo on every change. Back up the repo too.

## Upgrade

1. Releases: <https://github.com/windmill-labs/windmill/releases> — fast-moving, weekly cadence.
2. Pin image tags; bump `WM_IMAGE=ghcr.io/windmill-labs/windmill:vX.Y.Z` in `.env`.
3. `docker compose pull && docker compose up -d`. Migrations run automatically on server startup.
4. Roll workers last: `docker compose up -d --no-deps windmill_worker` after the server is healthy.
5. Before major jumps, dump Postgres and read the release notes — occasional breaking schema changes (documented in release notes).

## Gotchas

- **First signup == admin.** Like ConvertX, the first account to hit the signup form becomes superadmin. Bootstrap the admin account *before* exposing BASE_URL publicly.
- **Default Postgres password is `changeme`.** Upstream `.env` ships with it. Change it in BOTH `.env` (DATABASE_URL) AND `docker-compose.yml` (`POSTGRES_PASSWORD`) — the two must match.
- **`:main` tag moves with every commit.** Production must pin to release tags. Staging can ride `:main` if you like pain.
- **Worker containers are `privileged: true`** by default for PID namespace isolation (`FAVOR_UNSHARE_PID=true`). That means a broken-out script has host-level capabilities. Don't loosen isolation further unless you trust all script authors.
- **`dind` sidecar is ~2 GB disk** per `/var/lib/docker` and can grow without bounds. Prune inside the sidecar (`docker exec dind docker system prune -af`) periodically.
- **Memory footprint is real.** 8 GB is the working minimum; below that, dependency caches thrash. Production deployments commonly use 16–32 GB.
- **SMTP on :25** is for receiving mail (triggering flows from email). Usually blocked by ISPs — most self-hosters ignore it. Remove the `- 25:25` port mapping if unused.
- **Multiplayer (real-time collaborative editing)** is EE-only. Community edition has all other features.
- **Indexer is EE-only.** Job-log full-text search requires `replicas: 1` on `windmill_indexer` + EE license.
- **Extensions and nsjail sandboxing**: `ENABLE_NSJAIL=true` on `windmill_extra` provides harder sandbox but requires `privileged: true` + additional kernel features. Default `false` is fine for internal deployments.
- **AGPL-3.0 for core.** If you modify Windmill and expose it as a service, you must provide source to users. Unmodified private internal use is fine.
- **Scripts run in shared worker containers by default.** Isolation is via unshare-PID + per-job temp dirs, but filesystem quota / CPU throttling is not built in. For truly adversarial multi-tenant workloads, use the EE `dedicated workers` feature or K8s with NetworkPolicies.
- **Secret management**: Windmill "variables" and "resources" are stored encrypted in Postgres. The encryption key is derived from `WINDMILL_KEY` env var — **set this explicitly**, else a fresh deploy generates a new one and all existing secrets become unreadable.
- **No built-in scheduler HA.** Cron schedules run on whichever server replica is active; multi-replica server setups need external leader election (Windmill has a native mechanism but it relies on Postgres advisory locks).
- **Native workers can run in-process** (`NATIVE_MODE=true`) — useful for lightweight jobs, skips container spawn overhead. Trade-off: a runaway native job takes down the worker.
- **Caddy `l4` extension** is used for SMTP pass-through on :25. If you replace Caddy with plain nginx/Traefik, you lose SMTP unless you proxy L4 separately.

## Links

- Repo: <https://github.com/windmill-labs/windmill>
- Docs: <https://www.windmill.dev/docs>
- Getting started: <https://www.windmill.dev/docs/getting_started/setup>
- Security & isolation: <https://www.windmill.dev/docs/advanced/security_isolation>
- Releases: <https://github.com/windmill-labs/windmill/releases>
- Helm charts: <https://github.com/windmill-labs/windmill-helm-charts>
- Community edition vs EE: <https://www.windmill.dev/docs/misc/ee_ce_differences>
- Hub (shared scripts/flows): <https://hub.windmill.dev/>
- Discord: <https://discord.gg/V7PM2YHsPB>
