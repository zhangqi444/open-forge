---
name: podfetch-project
description: PodFetch recipe for open-forge. Self-hosted podcast manager written in Rust+React. Download and stream podcasts, GPodder sync, OIDC/basic auth, S3 storage, Telegram notifications, and a mobile app. SQLite or PostgreSQL. Upstream: https://github.com/SamTV12345/PodFetch
---

# PodFetch

A self-hosted podcast manager built with Rust (backend) and React (frontend). Download podcasts, listen online, sync playback position across devices via GPodder protocol, and manage subscriptions through a clean web UI.

Upstream: <https://github.com/SamTV12345/PodFetch> | Docs: <https://samtv12345.github.io/PodFetch/>

> Rolling releases — a new Docker image is pushed on every commit to main. Use Watchtower or a pinned digest for stability.

## Compatible combos

| Infra | DB | Notes |
|---|---|---|
| Any Linux host | SQLite (default) | Single container; simplest setup |
| Any Linux host | PostgreSQL | Multi-container compose |
| Unraid | SQLite | Supported via Community Apps (XML template included) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "SQLite or PostgreSQL?" | Determines which compose file to use |
| preflight | "Host port to bind PodFetch on?" | Default: `8000` (host) → container `8000` |
| preflight | "UID/GID to run as?" | Default: `1000:1000`; set `UID`/`GID` env vars |
| preflight | "Podcast download directory on host?" | Bind-mounted as `/app/podcasts` |
| config | "Authentication type?" | Basic auth, OIDC, or none (reverse-proxy auth) |
| config (basic auth) | "Username and password?" | `USERNAME`, `PASSWORD`, and `BASIC_AUTH=true` |
| config (OIDC) | "OIDC authority URL, client ID, redirect URI, JWKS URI?" | See OIDC section below |
| config | "Telegram notifications for new episodes?" | `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_CHAT_ID`, `TELEGRAM_API_ENABLED=true` |
| config | "S3 storage for podcast files?" | See S3 env vars below |

## Software-layer concerns

### Image

```
samuel19982/podfetch:v5.1.1
```

Docker Hub: <https://hub.docker.com/r/samuel19982/podfetch>

Use a specific tag or digest for stability, or pair with Watchtower for auto-updates.

### Compose (SQLite)

```yaml
services:
  podfetch:
    image: samuel19982/podfetch:v5.1.1
    user: ${UID:-1000}:${GID:-1000}
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - podfetch-podcasts:/app/podcasts
      - podfetch-db:/app/db
    environment:
      - POLLING_INTERVAL=60     # minutes between episode checks
      - DATABASE_URL=sqlite:///app/db/podcast.db

volumes:
  podfetch-podcasts:
  podfetch-db:
```

### Compose (PostgreSQL)

```yaml
services:
  podfetch:
    image: samuel19982/podfetch:v5.1.1
    user: ${UID:-1000}:${GID:-1000}
    restart: unless-stopped
    ports:
      - "8000:8000"
    volumes:
      - ./podcasts:/app/podcasts
    environment:
      - POLLING_INTERVAL=300
      - DATABASE_URL=postgresql://postgres:changeme@postgres/podfetch
    depends_on:
      - postgres

  postgres:
    image: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
      PGDATA: /data/postgres
      POSTGRES_DB: ${POSTGRES_DB:-podfetch}
    volumes:
      - postgres:/data/postgres

volumes:
  postgres:
```

> Source: upstream docker-compose.yml + docker-compose-postgres.yml — <https://github.com/SamTV12345/PodFetch>

### Key environment variables

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | SQLite (`sqlite:///app/db/podcast.db`) or PostgreSQL connection string |
| `POLLING_INTERVAL` | Minutes between podcast feed checks (default: 60) |
| `BASIC_AUTH` | Set `true` to enable HTTP basic auth |
| `USERNAME` / `PASSWORD` | Credentials for basic auth (all three required if using basic auth) |
| `OIDC_AUTH` | Set `true` to enable OIDC; mutually exclusive with `BASIC_AUTH` |
| `OIDC_AUTHORITY` | OIDC authority URL |
| `OIDC_CLIENT_ID` | OIDC client ID |
| `OIDC_REDIRECT_URI` | Post-login redirect (e.g. `https://podfetch.example.com/ui/login`) |
| `OIDC_SCOPE` | OIDC scope (e.g. `openid profile email`) |
| `OIDC_JWKS` | JWKS endpoint URL |
| `TELEGRAM_API_ENABLED` | Set `true` for Telegram new-episode notifications |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token (from BotFather) |
| `TELEGRAM_BOT_CHAT_ID` | Telegram chat ID to receive notifications |
| `PODFETCH_PROXY` | Outbound HTTP proxy for fetching podcast feeds |
| `SUB_DIRECTORY` | Sub-path if running under a prefix without a proxy (e.g. `/podfetch`) |

### Reverse proxy requirements

PodFetch auto-derives its public URL from request headers. Your reverse proxy **must** forward:

| Header | Value |
|---|---|
| `X-Forwarded-Host` | Public hostname (e.g. `podfetch.example.com`) |
| `X-Forwarded-Proto` | `https` or `http` |
| `X-Forwarded-Prefix` | Sub-path if serving under a directory (e.g. `/podfetch`) |

Also enable **WebSocket support** in your reverse proxy — PodFetch uses WebSockets for real-time UI updates.

### OIDC authentication

OIDC is supported with Keycloak, Authelia, and other providers. Use `Public` client type (no client secret needed).

```yaml
environment:
  - OIDC_AUTH=true
  - OIDC_AUTHORITY=https://auth.example.com
  - OIDC_CLIENT_ID=podfetch
  - OIDC_REDIRECT_URI=https://podfetch.example.com/ui/login
  - OIDC_SCOPE=openid profile email
  - OIDC_JWKS=https://auth.example.com/jwks.json
```

> After first OIDC login, promote the user to admin via CLI:
> ```bash
> docker exec -it podfetch /app/podfetch users update
> # Enter: username → role → admin
> ```

### S3 storage

Configure S3-compatible storage for podcast files (instead of local volume):
Full S3 environment variable reference: <https://samtv12345.github.io/PodFetch/S3.html>

### GPodder sync

PodFetch implements the GPodder API, allowing podcast apps that support GPodder (e.g. AntennaPod, gPodder desktop) to sync subscriptions and episode progress.

Point your GPodder-compatible app at PodFetch's URL with your PodFetch credentials.

### Mobile app

A companion mobile app is available: <https://samtv12345.github.io/PodFetch/Mobile.html>

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Podcast downloads in the mounted volume and the database persist across upgrades.

## Gotchas

- **All three basic auth vars required** — if `BASIC_AUTH=true`, you must also set `USERNAME` and `PASSWORD`. Missing any one causes a startup crash.
- **OIDC and basic auth are mutually exclusive** — do not set both `BASIC_AUTH=true` and `OIDC_AUTH=true`.
- **Promote first OIDC user to admin via CLI** — OIDC users have no admin rights by default. Run the `users update` command inside the container after first login.
- **WebSocket support required in reverse proxy** — without it, real-time progress updates in the UI don't work.
- **`X-Forwarded-*` headers required behind a proxy** — PodFetch derives its public URL from these headers. Missing/wrong values break absolute URLs in the UI and GPodder API responses.
- **Rolling releases** — the `latest` tag is updated on every commit. Use Watchtower for automatic updates or pin a specific digest.
- **UID/GID matters for volume permissions** — set `UID` and `GID` env vars to match the host user owning the podcast directory to avoid permission errors.
- **PostgreSQL compose doesn't include a DB volume for podcasts** — add a volume/bind-mount for `./podcasts:/app/podcasts` explicitly when using the Postgres compose.

## Links

- Upstream README: <https://github.com/SamTV12345/PodFetch>
- Documentation: <https://samtv12345.github.io/PodFetch/>
- S3 configuration: <https://samtv12345.github.io/PodFetch/S3.html>
- Mobile app: <https://samtv12345.github.io/PodFetch/Mobile.html>
- Docker Hub: <https://hub.docker.com/r/samuel19982/podfetch>
