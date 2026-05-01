---
name: NextExplorer
description: "Self-hosted modern file explorer with secure access control, polished UX, and Docker-first deployment. Node.js + SvelteKit. nxzai/NextExplorer. Grid/list/column views, drag-and-drop, ripgrep search, fast media previews, built-in editor, link sharing, OIDC SSO. MIT."
---

# NextExplorer

**A modern, self-hosted file explorer with secure access control, polished UX, and a Docker-first deployment.** Grid/list/column views, drag-and-drop, context menus, keyboard shortcuts, fast media previews (images, videos, PDFs, thumbnails via FFmpeg), built-in code editor, ripgrep-backed search, link-based sharing (read-only/write), guest access, and optional OIDC SSO.

Built + maintained by **nxzai**. MIT.

- Upstream repo: <https://github.com/nxzai/NextExplorer>
- Docker Hub: `nxzai/explorer`
- Docs: <https://explorer.nxz.ai>
- Live demo: <https://explorer-latest.onrender.com> (user: `demo@example.com` / pw: `password`)

## Architecture in one minute

- **SvelteKit** frontend + **Express** API backend (Node.js)
- **SQLite** — built-in, file-based (no external DB needed by default; optional external PostgreSQL)
- Mounts any number of directories under `/mnt/<Label>` — each becomes a top-level volume in the UI
- Port **3000** (internal and default external)
- Config + DB: `/config` volume; thumbnails + ripgrep index: `/cache` volume
- Resource: **low-medium** — Node.js app; FFmpeg for thumbnails

## Compatible install methods

| Infra      | Runtime             | Notes                                             |
| ---------- | ------------------- | ------------------------------------------------- |
| **Docker** | `nxzai/explorer`    | **Primary** — single container, SQLite built-in   |
| Docker + PostgreSQL | `nxzai/explorer` + `postgres` | External DB for larger deployments |

## Install via Docker Compose

```yaml
services:
  nextexplorer:
    image: nxzai/explorer:latest
    container_name: nextexplorer
    restart: unless-stopped
    ports:
      - '3000:3000'
    volumes:
      - ./config:/config       # Config files, SQLite DB, settings
      - ./cache:/cache         # Thumbnail cache, ripgrep index, temp files
      # Each /mnt/<Label> mount becomes a top-level volume in the UI
      - /path/to/your/files:/mnt/Files
      # Add more mounts as needed:
      # - /media/movies:/mnt/Movies
    environment:
      - NODE_ENV=production
      - PUBLIC_URL=http://localhost:3000   # Set to your external URL (no trailing slash)
```

```bash
docker compose up -d
```

Visit `http://localhost:3000`.

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `NODE_ENV` | — | Set to `production` for Docker image defaults |
| `PORT` | `3000` | Internal port |
| `PUBLIC_URL` | — | External URL (no trailing slash). Drives cookies, CORS defaults, OIDC callback URLs |
| `TRUST_PROXY` | — | Express trust proxy config; often auto-derived from `PUBLIC_URL`. Set when behind a reverse proxy |
| `CORS_ORIGINS` | `PUBLIC_URL` origin | Comma-separated allowed origins |
| `SESSION_SECRET` | auto-generated | Cookie secret — set a long random stable string (≥32 chars) to keep sessions across restarts |
| `AUTH_MODE` | `both` | `local\|oidc\|both\|disabled` — what auth methods to enable |
| `AUTH_ADMIN_EMAIL` | — | Bootstrap admin user email on first run |
| `AUTH_ADMIN_PASSWORD` | — | Bootstrap admin user password on first run |
| `AUTH_MAX_FAILED` | `5` | Failed login attempts before lockout |
| `AUTH_LOCK_MINUTES` | `15` | Lockout duration in minutes |
| `OIDC_ENABLED` | `false` | Enable OIDC SSO authentication |
| `OIDC_ISSUER` | — | IdP issuer URL (discovery) |
| `OIDC_CLIENT_ID` | — | OIDC client ID |
| `OIDC_CLIENT_SECRET` | — | OIDC client secret |
| `OIDC_CALLBACK_URL` | `${PUBLIC_URL}/callback` | OIDC callback URL |
| `OIDC_ADMIN_GROUPS` | — | Groups that grant admin rights |
| `OIDC_AUTO_CREATE_USERS` | `true` | Auto-create users on OIDC login |
| `PG_HOST` | — | Optional external PostgreSQL host |
| `LOG_LEVEL` | `info` | `trace\|debug\|info\|warn\|error` |
| `VOLUME_ROOT` | `/mnt` | Root for volume mounts |
| `CONFIG_DIR` | `/config` | Config, DB, extensions |
| `CACHE_DIR` | `/cache` | Thumbnails, ripgrep index, temp |
| `EDITOR_EXTENSIONS` | — | Additional editor extensions to enable |

## Gotchas

- **Volume mounts define the UI.** Every directory mounted under `/mnt/<Label>` appears as a top-level item in the file explorer. Name them meaningfully (e.g. `/mnt/Documents`, `/mnt/Photos`).
- **`PUBLIC_URL` must match.** Accessing the app via a URL different from `PUBLIC_URL` causes CORS, cookie, and OIDC redirect issues. Always set this to the URL you actually use.
- **`SESSION_SECRET`.** Omitting this auto-generates a random secret on startup, which logs out all users on container restart. Set a stable value.
- **FFmpeg for previews.** Video thumbnails and previews require FFmpeg — it's included in the Docker image.
- **ripgrep for search.** Full filename + content search uses ripgrep — bundled in the Docker image.
- **PostgreSQL optional.** By default, SQLite is used (`/config`). Set `PG_HOST` and related vars for external Postgres.
- **MIT license.** Free for commercial and personal use.

## Backup

```sh
# All state is in config/ and cache/ bind mounts (or named volumes)
tar czf nextexplorer-backup-$(date +%F).tar.gz ./config
# cache can be regenerated; skip it if space is tight
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active development, MIT license, OIDC support, ripgrep + FFmpeg integration.

## File-explorer-family comparison

- **NextExplorer** — Node.js/SvelteKit, modern UX, media previews, ripgrep search, OIDC; MIT
- **Filebrowser** — Go, simple UI, user management, web editor; Apache-2.0
- **Seafile** — Python, sync + share, mobile clients; AGPL-3.0
- **Nextcloud** — PHP, full cloud suite with Files app; AGPL-3.0
- **Pydio Cells** — Go, enterprise features, collaboration; AGPL-3.0

**Choose NextExplorer if:** you want a polished self-hosted file explorer with fast media previews, link sharing, OIDC SSO, and ripgrep search — without the complexity of a full cloud suite.

## Links

- Repo: <https://github.com/nxzai/NextExplorer>
- Docs: <https://explorer.nxz.ai>
- Demo: <https://explorer-latest.onrender.com>
