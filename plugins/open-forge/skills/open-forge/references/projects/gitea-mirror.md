---
name: gitea-mirror
description: Gitea Mirror automatically mirrors GitHub repositories (public, private, starred, org) to a self-hosted Gitea or Forgejo instance, with a web UI for configuration, real-time dashboard, and scheduled syncs. Upstream: https://github.com/RayLabsHQ/gitea-mirror
---

# Gitea Mirror

Gitea Mirror automatically syncs GitHub repositories to a self-hosted [Gitea](https://gitea.io/) or [Forgejo](https://forgejo.org/) instance. It mirrors public, private, starred, and organizational repos on a configurable schedule, copies optional metadata (issues, PRs, labels, milestones, wiki), and exposes a real-time dashboard for monitoring sync status. Single-container Docker deployment backed by SQLite. Upstream: <https://github.com/RayLabsHQ/gitea-mirror>.

Latest stable release: **v3.15.10** (check <https://github.com/RayLabsHQ/gitea-mirror/releases> for latest).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare-metal | Docker + Docker Compose | Recommended. Single container, SQLite embedded. |
| Raspberry Pi (ARM64) | Docker + Docker Compose | Multi-arch image supports `linux/arm64`. |
| Behind reverse proxy (Caddy / Nginx / Traefik) | Docker + Docker Compose | Set `BETTER_AUTH_URL` and trusted origins to external URL. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What is the base URL where Gitea Mirror will be accessible?" | e.g. `https://mirror.example.com` or `http://localhost:4321`. Used for session cookies and OIDC. |
| preflight | "PUID / PGID for the container user?" | Defaults to `1000:1000`. Match the owner of `./data`. |
| credentials | "GitHub Personal Access Token (PAT) for mirroring?" | Needs `repo` scope (for private repos) or `public_repo` (public only). Configured via web UI after first boot. |
| credentials | "Gitea / Forgejo base URL + admin API token?" | Configured via web UI. Token must have `write:repository` scope on Gitea/Forgejo. |
| optional | "Enable OIDC / SSO authentication?" | Off by default; if yes, collect OIDC issuer URL + client ID + client secret. |

## Software-layer concerns

### Config paths

| Path | What |
|---|---|
| `./data/gitea-mirror.db` | SQLite database (repos, config, activity logs). Back this up. |
| `./data/` | All persistent state. Mount as named volume or bind-mount. |

### Key environment variables

| Variable | Default | Required | Notes |
|---|---|---|---|
| `BETTER_AUTH_SECRET` | — | **Yes** | Min 32-char random string. Session signing key. Generate with `openssl rand -hex 32`. |
| `BETTER_AUTH_URL` | `http://localhost:4321` | Yes (behind proxy) | Set to the **external** URL when behind a reverse proxy. |
| `PUBLIC_BETTER_AUTH_URL` | `http://localhost:4321` | Yes (behind proxy) | Must match `BETTER_AUTH_URL` for the browser. |
| `BETTER_AUTH_TRUSTED_ORIGINS` | `http://localhost:4321` | Yes (behind proxy) | Set to external URL; CSRF protection. |
| `BASE_URL` | `/` | Only if path-prefix | e.g. `/mirror` for `https://git.example.com/mirror`. |
| `PORT` | `4321` | No | Internal container port. |
| `PUID` / `PGID` | `1000` | No | Run as specific UID/GID (matches data dir owner). |
| `DATABASE_URL` | `file:data/gitea-mirror.db` | No | Override only if redirecting to an external path. |

All GitHub / Gitea configuration (tokens, mirror settings, intervals) is set via the web UI after first boot — not env vars.

### Data directory

```bash
mkdir -p ./data
chown 1000:1000 ./data   # match PUID:PGID
```

## Quick-start Docker Compose

```yaml
# docker-compose.yml
services:
  gitea-mirror:
    image: ghcr.io/raylabshq/gitea-mirror:latest
    container_name: gitea-mirror
    restart: unless-stopped
    ports:
      - "${PORT:-4321}:4321"
    user: "${PUID:-1000}:${PGID:-1000}"
    volumes:
      - ./data:/app/data
    environment:
      - BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
      - BETTER_AUTH_URL=${BETTER_AUTH_URL:-http://localhost:4321}
      - PUBLIC_BETTER_AUTH_URL=${BETTER_AUTH_URL:-http://localhost:4321}
      - BETTER_AUTH_TRUSTED_ORIGINS=${BETTER_AUTH_URL:-http://localhost:4321}
      - NODE_ENV=production
      - DATABASE_URL=file:data/gitea-mirror.db
      - HOST=0.0.0.0
      - PORT=4321
      - BASE_URL=${BASE_URL:-/}
    healthcheck:
      test: ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:4321/api/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 15s
```

```bash
# 1. Generate auth secret
echo "BETTER_AUTH_SECRET=$(openssl rand -hex 32)" >> .env
echo "BETTER_AUTH_URL=http://localhost:4321" >> .env   # change for proxy

# 2. Pull and start
docker compose pull
docker compose up -d

# 3. Open http://localhost:4321 -- first user signup becomes admin
```

## Behind a reverse proxy

When accessing Gitea Mirror through Caddy, Nginx, or Traefik, **all three** auth env vars must be set to the external URL — otherwise sessions will fail or the CSRF check will block logins:

```env
BETTER_AUTH_URL=https://mirror.example.com
PUBLIC_BETTER_AUTH_URL=https://mirror.example.com
BETTER_AUTH_TRUSTED_ORIGINS=https://mirror.example.com
```

For a **path-prefix** deploy (e.g. `https://git.example.com/mirror`):

```env
BASE_URL=/mirror
BETTER_AUTH_URL=https://git.example.com
PUBLIC_BETTER_AUTH_URL=https://git.example.com
BETTER_AUTH_TRUSTED_ORIGINS=https://git.example.com
```

## Post-install setup (web UI)

1. Sign up → first user becomes admin.
2. **Configuration → GitHub** — paste GitHub PAT (`repo` or `public_repo` scope).
3. **Configuration → Gitea/Forgejo** — paste Gitea base URL + admin API token.
4. Set mirror options: skip forks, mirror private repos, mirror issues/wiki, sync interval.
5. **Repositories → Sync All** to run the first full sync.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d   # rolling restart, data volume untouched
```

No manual migrations needed — schema migrations run automatically on startup.

## Gotchas

- **`BETTER_AUTH_SECRET` is write-once in practice.** Changing it invalidates all existing sessions (users get logged out). Treat it as immutable; store it in a secrets manager or `.env` file that persists across upgrades.
- **GitHub token rotation does not auto-update already-created mirror credentials in Gitea/Forgejo.** After rotating the PAT, if sync logs show `terminal prompts disabled` or auth failures, go to the affected repository's **Settings → Mirror Settings** in Gitea/Forgejo and update the token there — or delete and re-mirror the repo.
- **Metadata (issues, PRs) is not retroactively synced.** If you enable metadata mirroring *after* repos were already mirrored, select them in the UI and click **Re-run Metadata** to backfill.
- **`GITEA_MIRROR_INTERVAL` must be >= Gitea's `mirror.MIN_INTERVAL`.** If your Gitea server is configured with `MIN_INTERVAL = 24h` and you set Gitea Mirror to `8h`, sync will fail when it tries to apply the shorter interval.
- **SQLite is the only supported DB.** No Postgres/MySQL option. For large repos or high mirror counts, ensure the host has fast I/O for `./data/`.

## Upstream docs

Full README and advanced configuration: <https://github.com/RayLabsHQ/gitea-mirror>  
Environment variables reference: <https://github.com/RayLabsHQ/gitea-mirror/blob/main/docs/ENVIRONMENT_VARIABLES.md>
