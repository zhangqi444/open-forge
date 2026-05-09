---
name: telegram-files
description: Telegram Files recipe for open-forge. Self-hosted Telegram file downloader for continuous, stable, and unattended downloads from Telegram channels and groups. Supports multiple accounts, pause/resume, auto-transfer, and PWA. Stack: Java (Vert.x + TDLib) + Next.js. Upstream: https://github.com/jarvis2f/telegram-files
---

# Telegram Files

A self-hosted Telegram file downloader that enables continuous, unattended downloads from Telegram channels and groups. Supports multiple Telegram accounts, pause/resume, download rules, auto-transfer to other destinations, preview of videos/images, and Progressive Web App (PWA) access from mobile. Upstream: <https://github.com/jarvis2f/telegram-files>. License: MIT.

Telegram Files is a two-layer Docker application: a Java backend (Vert.x + TDLib for the Telegram MTProto connection) and a Next.js frontend. By default it uses SQLite for storage, but can optionally be configured with PostgreSQL or MySQL.

> **Note:** You must obtain a Telegram API ID and Hash from <https://my.telegram.org/apps> before deploying.

> **Security warning:** The upstream README explicitly states this service should NOT be exposed to the public internet without additional authentication. Use a reverse proxy with auth (e.g. Authelia, Basic Auth) or restrict access to a VPN/tailnet.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — official image with optional Postgres/MySQL sidecar. |
| Any Linux host | Docker run | Single container; SQLite data in `./data`. |
| unRAID | Community Applications | Available in unRAID Community Repositories as `telegram-files`. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Telegram API ID?" | Integer | Obtained from https://my.telegram.org/apps |
| preflight | "Telegram API Hash?" | Secret string | Obtained from https://my.telegram.org/apps |
| preflight | "Which port should the web UI be accessible on?" | Integer | Default `6543` (maps to container port `80`). |
| preflight | "Directory for downloaded files?" | Directory path | Mapped to `./data` by default; contains both the SQLite DB and downloaded files. |
| preflight (optional) | "Use an external database (PostgreSQL or MySQL)?" | Boolean | Default is SQLite. Set `DB_TYPE`, `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` if yes. |
| preflight (optional) | "PUID / PGID for file ownership?" | Integer pair | Set `PUID` and `PGID` to the UID/GID of the user who should own files in the mounted volume. |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `TELEGRAM_API_ID` | Telegram application API ID | **Required** |
| `TELEGRAM_API_HASH` | Telegram application API hash | **Required** |
| `APP_ENV` | Application environment | `prod` |
| `APP_ROOT` | Internal path for data storage | `/app/data` |
| `PUID` / `PGID` | File ownership UID/GID inside the container | unset |
| `DB_TYPE` | Database type: `sqlite` (default), `postgres`, `mysql` | `sqlite` |
| `DB_HOST` / `DB_PORT` / `DB_USER` / `DB_PASSWORD` / `DB_NAME` | External DB connection | Required if `DB_TYPE` is not `sqlite` |
| `NGINX_PORT` | Internal Nginx listen port | `80` |
| `TELEGRAM_LOG_LEVEL` | TDLib log verbosity (0=fatal … 5=verbose) | `0` |
| `OPENAI_API_KEY` / `OPENAI_MODEL` / `OPENAI_BASE_URL` | Optional AI features | unset |

Full template: <https://github.com/jarvis2f/telegram-files/blob/main/.env.example>

### .env file

```dotenv
# Required: obtain from https://my.telegram.org/apps
TELEGRAM_API_ID=your_api_id_here
TELEGRAM_API_HASH=your_api_hash_here

APP_ENV=prod
APP_ROOT=/app/data
TELEGRAM_LOG_LEVEL=0

# Optional: external database (defaults to SQLite)
# DB_TYPE=postgres
# DB_HOST=db
# DB_PORT=5432
# DB_USER=telegram_files
# DB_PASSWORD=changeme
# DB_NAME=telegram_files

# Optional: file ownership
# PUID=1000
# PGID=1000
```

### docker-compose.yml (from upstream)

```yaml
# compose.yml
# Source: https://github.com/jarvis2f/telegram-files/blob/main/docker-compose.yaml
services:
  telegram-files:
    container_name: telegram-files
    image: ghcr.io/jarvis2f/telegram-files:latest
    restart: always
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "curl", "-f", "http://127.0.0.1/api/health"]
      interval: 10s
      retries: 3
      timeout: 10s
      start_period: 10s
    ports:
      - "6543:80"
    volumes:
      - ./data:/app/data
      # Mount additional directories if using auto-transfer destinations
      # - ./other-files:/app/other-files
```

Source: <https://github.com/jarvis2f/telegram-files/blob/main/docker-compose.yaml>

### Quick start

```bash
# 1. Copy the example env file
curl -LO https://raw.githubusercontent.com/jarvis2f/telegram-files/main/.env.example
cp .env.example .env
# Edit .env: set TELEGRAM_API_ID and TELEGRAM_API_HASH

# 2. Copy the compose file
curl -LO https://raw.githubusercontent.com/jarvis2f/telegram-files/main/docker-compose.yaml

# 3. Start
docker compose up -d

# 4. Open the web UI
# http://<host>:6543
```

### First login

On first access, the web UI will prompt you to log in with your Telegram account (phone number + verification code). The session is stored in `./data` and reused on subsequent starts. You can add multiple Telegram accounts after the initial login.

### With PostgreSQL sidecar (optional)

For higher-volume setups, add a Postgres service. Uncomment and extend the compose file:

```yaml
services:
  telegram-files:
    # ... (as above)
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: tgfiles
      DB_PASSWORD: changeme
      DB_NAME: telegram_files

  db:
    image: postgres:15-alpine
    restart: always
    environment:
      POSTGRES_USER: tgfiles
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: telegram_files
    volumes:
      - ./data/db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 1s
      timeout: 3s
      retries: 30
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

Data in `./data` (SQLite DB, downloaded files, Telegram session) persists across upgrades.

## Gotchas

- **Telegram API credentials are mandatory** — the service will not start without `TELEGRAM_API_ID` and `TELEGRAM_API_HASH`. Apply at <https://my.telegram.org/apps>.
- **Do not expose publicly without authentication** — upstream explicitly warns against this. Front with a reverse proxy + auth (Authelia, HTTP Basic Auth) or restrict to VPN/tailnet.
- **Telegram session stored in `./data`** — losing or deleting this directory means re-authenticating all accounts. Back it up.
- **PUID/PGID for NAS deployments** — if the mounted `./data` directory is on a NAS or has specific ownership requirements, set `PUID`/`PGID` to match, otherwise downloaded files may be unreadable or unwriteable by the host user.
- **Auto-transfer paths must be mounted** — if you enable auto-transfer to another directory, mount that path as a volume in the compose file (e.g. `./other-files:/app/other-files`).
- **TDLib cold start** — on first launch, TDLib downloads metadata which can take 30–60 seconds. The healthcheck `start_period: 10s` may need to be increased on slow connections.

## Upstream docs

- GitHub: <https://github.com/jarvis2f/telegram-files>
- Releases: <https://github.com/jarvis2f/telegram-files/releases>
- Telegram API apps: <https://my.telegram.org/apps>
- unRAID Community Applications: search `telegram-files`
