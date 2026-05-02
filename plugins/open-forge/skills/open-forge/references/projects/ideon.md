---
name: ideon-project
description: Ideon recipe for open-forge. Self-hosted visual workspace / infinite canvas for project management. Embed GitHub/GitLab/Gitea/Forgejo repos and issues directly on a spatial canvas. Markdown notes, images, links, files. Real-time multiplayer collaboration. Time travel (workspace history). Go/Next.js + PostgreSQL. GHCR image. Upstream: https://github.com/3xpyth0n/ideon
---

# Ideon

A self-hosted visual workspace built around an infinite canvas. Instead of nested folders and tabs, you organize your project context spatially -- drag GitHub repositories, design notes, Markdown files, tasks, images, and links onto a shared map. What's close is related. Supports real-time multiplayer collaboration, time-travel history (view past workspace snapshots), and live integrations with GitHub, GitLab, Gitea, and Forgejo.

GHCR image + PostgreSQL. 2-container stack.

Upstream: <https://github.com/3xpyth0n/ideon> | Website: <https://www.theideon.com> | Docs: <https://www.theideon.com/docs/> | Demo: <https://demo.theideon.com> (user: `ideon-demo`, pass: `ideon-demo`)

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | 2-container stack; PostgreSQL required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | `APP_PORT` -- default `3000` |
| preflight | "App URL?" | `APP_URL` -- full URL including protocol and port (e.g. `http://192.168.1.10:3000` or `https://ideon.example.com`) |
| config | "DB credentials?" | `DB_USER`, `DB_PASS`, `DB_NAME` -- arbitrary values; must match between app and postgres |
| config | "Secret key?" | `SECRET_KEY` -- generate with `openssl rand -hex 32` |

## Software-layer concerns

### Images

```
ghcr.io/3xpyth0n/ideon:latest    # app
postgres:18-alpine                 # database
```

### .env file

The app is configured entirely via a `.env` file referenced by `env_file:` in compose. Create `.env` in your deployment directory:

```ini
APP_PORT=3000
APP_URL=http://localhost:3000

SECRET_KEY=<generate: openssl rand -hex 32>

DB_USER=ideon
DB_PASS=<generate: openssl rand -base64 15>
DB_NAME=ideon_db
```

Generate secrets with:

```bash
openssl rand -hex 32    # for SECRET_KEY
openssl rand -base64 15 # for DB_PASS
```

Or use the official installer (interactive, generates secrets automatically):

```bash
curl -fsSL https://install.theideon.com | sh
```

Installer supports flags: `--port 3000 --url https://ideon.example.com --silent`

### Compose

```yaml
services:
  ideon-app:
    image: ghcr.io/3xpyth0n/ideon:latest
    container_name: ideon-app
    env_file:
      - .env
    depends_on:
      ideon-db:
        condition: service_healthy
    restart: unless-stopped
    ports:
      - "${APP_PORT:-3000}:${APP_PORT:-3000}"
    volumes:
      - ideon-app-data:/app/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:${APP_PORT:-3000}/api/health"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  ideon-db:
    image: postgres:18-alpine
    container_name: ideon-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASS}
      POSTGRES_DB: ${DB_NAME}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ideon-db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 2s
      timeout: 5s
      retries: 5

volumes:
  ideon-app-data:
  ideon-db-data:
```

Source: upstream docker-compose.yml -- https://github.com/3xpyth0n/ideon

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `APP_PORT` | -- | Server port; default `3000` |
| `APP_URL` | Yes | Full public URL (e.g. `https://ideon.example.com`); used for collaboration links |
| `SECRET_KEY` | Yes | App secret; generate with `openssl rand -hex 32` |
| `DB_USER` | Yes | PostgreSQL username |
| `DB_PASS` | Yes | PostgreSQL password |
| `DB_NAME` | Yes | PostgreSQL database name |
| `PUID` / `PGID` | -- | Optional; user/group ID for file ownership inside container (default: 1001) |

### Volumes

| Path | Purpose |
|---|---|
| `ideon-app-data:/app/storage` | App storage (uploads, workspace data) |
| `ideon-db-data:/var/lib/postgresql/data` | PostgreSQL database |

### Features

- **Infinite canvas** -- spatial, drag-and-drop workspace; no nested folders
- **Live integrations** -- embed GitHub, GitLab, Gitea, Forgejo repos + issues as canvas blocks
- **Rich media blocks** -- Markdown notes, images, links, files, code snippets
- **Real-time multiplayer** -- collaborate with your team live on the same canvas
- **Time travel** -- view historical snapshots of your workspace to trace decisions
- **Self-hosted** -- full data ownership; AGPL 3.0 licensed

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in named volumes `ideon-app-data` and `ideon-db-data`.

## Gotchas

- **`APP_URL` must be correct** -- collaboration links and internal routing depend on this. Use the public-facing URL (including protocol), not `localhost`, if you share with teammates.
- **`.env` file required** -- the compose file uses `env_file: .env`. Create it before `docker compose up` or the containers will fail with missing variable errors.
- **Generate secrets before first run** -- don't leave `SECRET_KEY` blank or set to a weak value. Use `openssl rand -hex 32`.
- **PostgreSQL healthcheck** -- the app uses `condition: service_healthy` on the DB. The compose healthcheck uses `pg_isready`; if the DB takes longer to init, the app container will wait and retry automatically.
- **PUID/PGID** -- if you see permission errors on the `ideon-app-data` volume, set `PUID`/`PGID` to match your host user.
- **No built-in TLS** -- front with Caddy or nginx for HTTPS. Update `APP_URL` to `https://...` when adding TLS.

## Links

- Upstream README: <https://github.com/3xpyth0n/ideon>
- Website: <https://www.theideon.com>
- Documentation: <https://www.theideon.com/docs/>
- Demo: <https://demo.theideon.com>
- Installer script: <https://install.theideon.com>
- Discord: <https://discord.gg/X6gJSjupz3>
- Roadmap: <https://github.com/users/3xpyth0n/projects/3>
