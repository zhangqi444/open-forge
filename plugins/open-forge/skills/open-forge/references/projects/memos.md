---
name: memos-project
description: Memos recipe for open-forge. MIT open-source self-hosted note-taking app built for instant capture. Single Go binary, ~20MB Docker image, SQLite by default (MySQL/Postgres optional). Covers the recommended Docker install (`neosmemo/memos`), native binary via install.sh, and docker-compose. Timeline-first UI, Markdown-native, REST+gRPC APIs. Fits the "tiny self-host, run it and forget" profile.
---

# Memos

MIT-licensed self-hosted note-taking app. Timeline UI, Markdown-native, ~20 MB Docker image, single Go binary. Upstream: <https://github.com/usememos/memos>. Docs: <https://usememos.com/docs>. Live demo: <https://demo.usememos.com/>.

Memos is the "low-ceremony" end of the self-host spectrum — one container, one volume, one port, and you're done. Default DB is SQLite in the data volume; swap to MySQL / PostgreSQL via env if you want external DB.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`neosmemo/memos:stable`) | <https://hub.docker.com/r/neosmemo/memos> | ✅ | Recommended. |
| Docker Compose | `scripts/compose.yaml` on `main` | ✅ | Same container, compose-managed. |
| Native binary (`install.sh`) | `scripts/install.sh` on `main` | ✅ | Bare metal; auto-detects OS/arch, installs systemd unit. |
| Pre-built binaries (manual) | <https://github.com/usememos/memos/releases> | ✅ | Linux, macOS, Windows. Manual install + your own service manager. |
| Build from source | Standard Go build | ✅ | Dev / custom builds. Needs Go + Node.js (frontend embed). |
| Kubernetes (Helm / manifests) | Referenced in README, lives in community-maintained charts | ⚠️ Community | If you run everything on k8s. Verify chart freshness before relying on it. |

No official Helm chart is published by upstream (as of this writing); README says "Helm charts and manifests available" without linking to an upstream-maintained location — treat the linked charts as community.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Docker or native binary?" | `AskUserQuestion`: `Docker (recommended)` / `Native binary` | Drives install section. |
| dns | "What's the FQDN?" (e.g. `memos.example.com`) | Free-text | For reverse proxy + external URL. Memos doesn't require this env-wise, but reverse proxy needs it. |
| storage | "Data dir on the host?" (default `~/.memos/`) | Free-text | Bind-mounted to `/var/opt/memos` in the container. SQLite DB + uploads live here. |
| port | "Expose on which host port?" (default `5230`) | Free-text | Default `5230`. Change only if conflicting. |
| db | "Database backend?" | `AskUserQuestion`: `SQLite (default)` / `MySQL` / `PostgreSQL` | SQLite is fine for anyone not on a team; MySQL/Postgres for scale or shared infra. |
| tls | "Terminate TLS where?" | `AskUserQuestion`: `Caddy (auto-TLS)` / `Nginx` / `Traefik` / `HTTP only (LAN)` | Memos serves plain HTTP; reverse proxy is the upstream-expected TLS path. |
| admin | "First user becomes host account." | (informational) | The first user to sign up after install is automatically the host/admin. Guard the URL during bootstrap. |

## Install — Docker (recommended)

Per upstream README's Quick Start:

```bash
docker run -d \
  --name memos \
  -p 5230:5230 \
  -v ~/.memos:/var/opt/memos \
  --restart unless-stopped \
  neosmemo/memos:stable
```

Then open `http://localhost:5230` (or your FQDN behind a reverse proxy). Sign up — **the first user becomes the host account** with admin privileges.

### Docker Compose

Upstream's `scripts/compose.yaml` on `main`:

```yaml
services:
  memos:
    image: neosmemo/memos:stable
    container_name: memos
    volumes:
      - ~/.memos/:/var/opt/memos
    ports:
      - 5230:5230
```

```bash
mkdir -p ~/.memos
docker compose up -d
docker compose logs -f memos
```

### Image tags

- `stable` — latest stable release (upstream-recommended).
- `latest` — tracks `main`; can include beta features. Don't use in production.
- `<version>` (e.g. `0.25.0`) — pin a specific release for reproducibility.

## Install — Native binary

The upstream installer handles OS/arch detection + systemd registration (Linux) / launchd (macOS).

```bash
curl -fsSL https://raw.githubusercontent.com/usememos/memos/main/scripts/install.sh | sh
```

On Linux, this drops the binary into `/usr/local/bin/memos` and registers `memos.service` (systemd). On macOS, it drops into `/usr/local/bin` and expects you to run it manually or wrap in launchd.

Manual install:

1. Download the right binary from <https://github.com/usememos/memos/releases/latest>.
2. `tar xzf` and move to `/usr/local/bin/`.
3. Run `memos --mode prod --port 5230 --data /var/opt/memos`.
4. Wrap in a systemd unit (or your OS's equivalent) for auto-restart.

## Reverse proxy + HTTPS

Memos itself serves plain HTTP. Upstream expects a reverse proxy for TLS.

### Caddy (easiest)

```caddy
memos.example.com {
    reverse_proxy localhost:5230
}
```

Caddy handles Let's Encrypt automatically.

### Nginx

```nginx
server {
    listen 443 ssl http2;
    server_name memos.example.com;

    ssl_certificate     /etc/letsencrypt/live/memos.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/memos.example.com/privkey.pem;

    client_max_body_size 32M;  # for attachment uploads; raise if needed

    location / {
        proxy_pass http://127.0.0.1:5230;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Memos uses WebSocket for some features
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Config surface

Memos config is primarily CLI-flag / env-var driven. The binary's flags (from `memos --help` and upstream docs at <https://usememos.com/docs>):

| Flag | Env | Default | Purpose |
|---|---|---|---|
| `--mode` | `MEMOS_MODE` | `dev` | `prod` for production, `dev` for local dev, `demo` for a read-mostly demo. |
| `--port` | `MEMOS_PORT` | `5230` | Listen port. |
| `--addr` | `MEMOS_ADDR` | `0.0.0.0` | Listen address. |
| `--data` | `MEMOS_DATA` | `/var/opt/memos` | Data directory (SQLite DB, uploads). |
| `--driver` | `MEMOS_DRIVER` | `sqlite` | DB driver: `sqlite`, `mysql`, `postgres`. |
| `--dsn` | `MEMOS_DSN` | (empty) | DB connection string when `--driver` ≠ sqlite. |
| `--instance-url` | `MEMOS_INSTANCE_URL` | (empty) | Public URL for email / embed links. Set to your FQDN (`https://memos.example.com`). |

Example MySQL:

```bash
docker run -d --name memos \
  -p 5230:5230 \
  -v ~/.memos:/var/opt/memos \
  -e MEMOS_DRIVER=mysql \
  -e MEMOS_DSN="memos:${DB_PW}@tcp(mysql.internal:3306)/memos?charset=utf8mb4&parseTime=True&loc=Local" \
  -e MEMOS_MODE=prod \
  -e MEMOS_INSTANCE_URL=https://memos.example.com \
  neosmemo/memos:stable
```

Example PostgreSQL:

```bash
# DSN format:
# MEMOS_DSN=postgresql://user:pass@host:5432/dbname?sslmode=disable
```

Most runtime config (site title, custom style, custom JS, allowed signup, storage backend for uploads) is set via the in-app **Settings** UI as the host user — not via env. Those settings persist to the DB.

## Upgrade

```bash
# Docker
docker pull neosmemo/memos:stable
docker stop memos && docker rm memos
# Re-run the same `docker run` as before.
```

Always back up `~/.memos/` first:

```bash
tar czf ~/memos-backup-$(date +%Y%m%d).tar.gz -C ~ .memos
```

DB schema migrations run on startup. Forward-only; rolling back to an older image after a migration may fail — `tar`-extract your backup if needed.

For MySQL/Postgres users, `mysqldump` / `pg_dump` the Memos DB before every upgrade.

## Gotchas

- **First user is host.** Sign up immediately after install, or guard the URL. Anyone reaching the signup page first becomes the admin.
- **Public access + open signup = spam.** Memos defaults to allowing signups. Turn **Settings → Workspace Settings → Disable user signup** on as soon as your account exists.
- **Attachments live in the data dir.** `~/.memos/uploads/` (default). If you change `--data`, uploaded images move with it — don't manually split dirs.
- **`MEMOS_MODE=prod` is important.** Without it, Memos runs in `dev` mode with verbose logs, hot reload assumptions, and (in older versions) weaker security defaults.
- **DB driver pinning for v0.x upgrades.** Memos is pre-1.0 — minor version bumps have historically included DB schema changes. Always dump the DB before minor upgrades.
- **Time zone handling is UTC-only in storage.** The frontend localizes, but API responses are UTC. Automation that POSTs timestamps should format as UTC.
- **No built-in backup.** `tar`-of-data-dir + DB dump is the upstream expectation. No S3 off-site backup UI; wire that up yourself (restic / borg / rclone cron).
- **API tokens live in Settings → My Account.** The REST + gRPC APIs need a bearer token. Old OpenAPI automations predating the current token system will need updating.
- **No official Helm chart.** Community charts exist (search ArtifactHub) but aren't tracked by upstream. If you need k8s, vet the chart before relying on it.
- **Mobile clients exist but are community-built.** Memos itself is a web app; "Moe Memos" / other apps connecting to your self-host are third-party. Upstream isn't responsible for their behavior.

## Upstream references

- Repo: <https://github.com/usememos/memos>
- Docs: <https://usememos.com/docs>
- Deploy guide: <https://usememos.com/docs/deploy>
- Releases: <https://github.com/usememos/memos/releases>
- Docker Hub: <https://hub.docker.com/r/neosmemo/memos>
- Compose example: `scripts/compose.yaml` on `main`
- Install script: `scripts/install.sh` on `main`
- Live demo: <https://demo.usememos.com/>

## TODO — verify on first deployment

- Confirm `memos --help` flag names match what the recipe lists (minor versions have tweaked them).
- Verify default data dir on bare-metal install from `install.sh` (scripts change).
- Confirm the "first user is host" flow hasn't been replaced by an explicit `memos.init` step.
- Check whether an official Helm chart has landed upstream since writing; if so, promote the k8s row to first-party.
