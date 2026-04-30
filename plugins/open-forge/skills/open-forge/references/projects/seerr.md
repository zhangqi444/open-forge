---
name: Seerr
description: Media request management for Jellyfin/Plex/Emby + Sonarr/Radarr. Users request movies/TV from a pretty catalog; admins approve; Sonarr/Radarr auto-download. Successor to Jellyseerr (which forked Overseerr). Node.js + SQLite/Postgres. MIT.
---

# Seerr

Seerr is the 2025 successor to **Jellyseerr** (which itself was a 2021 fork of **Overseerr** by an ex-Plex employee). Same core function: a pretty, Netflix-style catalog where users request movies or TV shows, admins approve, and Sonarr/Radarr download them.

The lineage:

- **Overseerr** (2020-2024) — Plex-centric request manager; maintenance slowed
- **Jellyseerr** (2021+) — fork that added Jellyfin + Emby support
- **Seerr** (2025+) — rebranded/refocused successor to Jellyseerr; unified Plex + Jellyfin + Emby

If you're starting fresh today: **use Seerr**. If you're on Jellyseerr: migrate via the [migration guide](https://docs.seerr.dev/migration-guide). If you're on Overseerr: same (though Plex-only).

Features:

- **Jellyfin / Plex / Emby** — authentication + user import, library scan to know what's already in your collection
- **Sonarr / Radarr** — send approved requests to download
- **Per-season TV requests**
- **Permission system** — granular (approve, request 4K, auto-approve, skip quality, etc.)
- **Notifications** — Discord, Slack, Telegram, email, webhook, Pushover, ntfy, Gotify
- **Watchlisting + blocklisting** — users mark things they want or don't want
- **Mobile-friendly UI**
- **PostgreSQL or SQLite** — dev → SQLite, prod → Postgres
- **Language/translation** — community-translated via Weblate

- Upstream repo: <https://github.com/seerr-team/seerr>
- Docs: <https://docs.seerr.dev>
- Docker Hub: <https://hub.docker.com/r/seerr/seerr>
- Migration guide: <https://docs.seerr.dev/migration-guide>

## Architecture in one minute

- **Single Node.js container** — Next.js frontend + API
- **Database**: SQLite (default, stored in config volume) OR PostgreSQL
- **Config volume**: `/app/config` — SQLite DB, logs, settings JSON
- **Port 5055** — web UI + API

Connects out to: your Jellyfin/Plex/Emby server (for auth + library scan), your Sonarr/Radarr instances (for requests), TMDb (for metadata).

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                               |
| ----------- | --------------------------------------------------- | ------------------------------------------------------------------- |
| Single VM   | Docker (`seerr/seerr:latest`)                          | **Most common**                                                      |
| Single VM   | Docker Compose (app + optional Postgres)               | For prod                                                               |
| Kubernetes  | Community Helm charts                                   | Stateless app + DB                                                      |
| Synology / QNAP | Via Container Station                              | Community-supported                                                     |
| Unraid      | Community Applications                                 | Widely used                                                              |

## Inputs to collect

| Input                 | Example                                 | Phase     | Notes                                                           |
| --------------------- | --------------------------------------- | --------- | --------------------------------------------------------------- |
| Media server          | Jellyfin URL + creds (or Plex/Emby)      | Setup     | Seerr authenticates against it                                    |
| Sonarr URL + API key  | `http://sonarr:8989/` + API key          | Setup     | Add via Settings → Services                                        |
| Radarr URL + API key  | `http://radarr:7878/` + API key          | Setup     | Same                                                               |
| Port                  | `5055`                                   | Network   | UI + API                                                           |
| Config volume         | `/app/config`                            | Filesystem | Persistent DB + logs + secrets                                      |
| `DB_TYPE`             | `sqlite` or `postgres`                    | DB        | Postgres recommended for >10 users                                  |
| Postgres (if used)    | host + user + pw + db                    | DB        | Via env vars                                                         |
| Reverse proxy         | `requests.example.com`                   | DNS       | For public/TLS access                                                |
| SMTP (optional)       | host + port + creds                       | Email     | For notifications                                                   |

## Install via Docker

```sh
docker run -d --name seerr \
  -e TZ=UTC -e LOG_LEVEL=info \
  -p 5055:5055 \
  -v $(pwd)/config:/app/config \
  --restart unless-stopped \
  seerr/seerr:1.x.x    # pin; check Docker Hub
```

Open `http://<host>:5055`. First-run wizard asks for media server creds + admin account.

## Install via Docker Compose

```yaml
services:
  seerr:
    image: seerr/seerr:1.x.x
    container_name: seerr
    restart: unless-stopped
    environment:
      TZ: UTC
      LOG_LEVEL: info
      # Postgres (optional)
      # DB_TYPE: postgres
      # DB_HOST: postgres
      # DB_PORT: 5432
      # DB_USER: seerr
      # DB_PASS: <strong>
      # DB_NAME: seerr
    ports:
      - "5055:5055"
    volumes:
      - ./config:/app/config
    # depends_on:
    #   postgres: { condition: service_healthy }

  # postgres:
  #   image: postgres:17-alpine
  #   environment:
  #     POSTGRES_USER: seerr
  #     POSTGRES_PASSWORD: <strong>
  #     POSTGRES_DB: seerr
  #   volumes:
  #     - seerr-db:/var/lib/postgresql/data
  #   healthcheck:
  #     test: ["CMD-SHELL", "pg_isready -U seerr"]
  #     interval: 10s
  #     retries: 5

# volumes:
#   seerr-db:
```

## First boot wizard

1. Browse `http://<host>:5055`
2. **Sign in with media server** — pick Jellyfin/Plex/Emby, enter admin creds (first login becomes Seerr admin)
3. **Settings → Services**:
   - **Sonarr**: add URL + API key → pick root folder + quality profile
   - **Radarr**: same
4. **Settings → Users** — import users from media server; set per-user permissions (can request? how many at a time? quality tier?)
5. **Settings → Notifications** — Discord/Slack/email as desired
6. Users log in with their media-server accounts → browse catalog → click request

## Data & config layout

Inside `/app/config/`:

- `db/db.sqlite3` — SQLite (default DB)
- `settings.json` — service configs + encrypted secrets
- `logs/`
- `sessions/`

**`settings.json` holds service API keys** (Sonarr/Radarr/Plex). It IS the secret store — don't share.

## Backup

```sh
# Config volume has everything
docker run --rm -v "$(pwd)/config:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/seerr-$(date +%F).tgz -C /src .

# Postgres (if external)
docker compose exec -T postgres pg_dump -U seerr seerr | gzip > seerr-db-$(date +%F).sql.gz
```

## Upgrade

1. Releases: <https://github.com/seerr-team/seerr/releases>. Active.
2. `docker compose pull && docker compose up -d`. Migrations run on startup.
3. **Back up config volume** before version bumps.
4. Migrating **from Jellyseerr/Overseerr**: stop old container, copy `/config` to Seerr's config path, start Seerr. Read full migration guide first: <https://docs.seerr.dev/migration-guide>.

## Gotchas

- **Migrating from Jellyseerr or Overseerr**: config format is mostly compatible but has gotchas. **Always read the migration guide first**. Specifically: DB schema migrations are one-way — back up, test, then migrate prod.
- **Plex users** who move between Plex + Jellyfin: Seerr supports both simultaneously; users can auth with either.
- **4K requests** are a separate permission bucket — allow only select users by default, or your 4K library fills with everyone's requests.
- **Auto-approve** on requests is a permission — either trusted friends only OR gated by admin approval. Default is "admin must approve."
- **Metadata source is TMDb** — if TMDb is blocked in your region (rare, but…), Seerr won't work well.
- **Sonarr/Radarr must be reachable** from Seerr's container. Use internal Docker network (`sonarr:8989`) not `localhost:8989`. For external Sonarr on another host, use that host's IP.
- **Per-user quota**: set in Settings → Users → per-user overrides. Useful for "family member gets 5 movies/week, not unlimited."
- **SQLite is fine for ≤20 users**; >20 users → switch to Postgres. Seerr doesn't advertise a hard limit but heavy concurrent use hits SQLite lock contention.
- **Public internet exposure** — put behind a reverse proxy with TLS. Seerr supports OAuth via media server login, but also exposes a request API.
- **Webhook notifications** → lots of bots exist for "auto-announce new requests to Discord channel."
- **Radarr/Sonarr minimum availability** settings — users can request "in cinemas" movies; configure min-availability in Radarr to avoid piling in-cinema items into your queue.
- **Refresh library from media server** — Seerr syncs your existing library so it won't let users request things you already have. Periodic auto-sync is configurable.
- **The Overseerr/Jellyseerr/Seerr relationship** is a family tree, not competition:
  - **Overseerr** — Plex-only, original; maintenance-mode (many people still happily use it)
  - **Jellyseerr** — fork that added Jellyfin/Emby; very popular 2022-2025
  - **Seerr** — 2025 successor that the Jellyseerr team is focusing effort on
- **MIT license** — use freely.
- **Alternatives worth knowing:**
  - **Ombi** — similar request system; PHP; supports Plex + Emby + Jellyfin
  - **Petio** — simpler; Plex-focused; lighter
  - **Requestrr** — chatbot-only (Discord + Telegram) — no web UI
  - **Doplarr** — Discord-only request bot

## Links

- Repo: <https://github.com/seerr-team/seerr>
- Docs: <https://docs.seerr.dev>
- Getting started: <https://docs.seerr.dev/getting-started/>
- Migration guide: <https://docs.seerr.dev/migration-guide>
- Docker Hub: <https://hub.docker.com/r/seerr/seerr>
- Releases: <https://github.com/seerr-team/seerr/releases>
- API docs: `http://<your-seerr>/api-docs`
- Release announcement: <https://docs.seerr.dev/blog/seerr-release>
- Discord: <https://discord.gg/seerr>
- Weblate (i18n): <https://translate.seerr.dev>
