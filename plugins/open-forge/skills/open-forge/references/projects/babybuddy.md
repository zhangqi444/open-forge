---
name: babybuddy
description: Recipe for self-hosting Baby Buddy, a web app for tracking infant care — sleep, feedings, diaper changes, tummy time, and more. Based on upstream documentation at https://github.com/babybuddy/babybuddy.
---

# Baby Buddy

Web app for caregivers to track sleep, feedings, diaper changes, tummy time, and other infant activities — helping predict and understand a baby's needs. Integrates with Home Assistant. Upstream: <https://github.com/babybuddy/babybuddy>. Docs: <https://docs.baby-buddy.net>. Stars: 2.7k+. License: BSD-2-Clause.

Docker image maintained by the [LinuxServer.io](https://www.linuxserver.io/) community (`lscr.io/linuxserver/babybuddy`).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (LinuxServer image) | Recommended; multi-arch |
| Home Assistant host | Home Assistant Addon | Community-maintained; see upstream docs |
| DigitalOcean | Marketplace droplet | $6+/month one-click |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Data directory path | Host path for config/database persistence (mapped to /config) |
| optional | PUID / PGID | LinuxServer UID/GID for file permissions (default: 1000/1000) |
| optional | TZ | Timezone (e.g. America/New_York) |
| optional | SECRET_KEY | Django secret key; auto-generated if omitted |

## Docker Compose deployment

```yaml
services:
  babybuddy:
    image: lscr.io/linuxserver/babybuddy
    container_name: babybuddy
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      # Optional: set a fixed secret key (auto-generated if omitted)
      # - SECRET_KEY=your-secret-key
    volumes:
      - /path/to/appdata:/config
    ports:
      - 8000:8000
    restart: unless-stopped
```

```bash
docker compose up -d
```

Web UI: http://localhost:8000
Default login: `admin` / `admin` — **change immediately**.

## Data directory

All persistent data (SQLite database, media uploads, config) is stored in the `/config` volume. Back up this directory to preserve all data.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| PUID | 1000 | User ID for file permissions |
| PGID | 1000 | Group ID for file permissions |
| TZ | UTC | Timezone |
| SECRET_KEY | auto | Django secret key (persisted in /config after first run) |
| ALLOWED_HOSTS | * | Comma-separated list of allowed hostnames |
| DB_ENGINE | django.db.backends.sqlite3 | Database backend (SQLite default; PostgreSQL supported) |

For PostgreSQL instead of SQLite, set additional DB variables — see [LinuxServer docs](https://github.com/linuxserver/docker-babybuddy) for the full list.

## Running administrative commands

```bash
docker exec -it babybuddy /bin/bash
export DJANGO_SETTINGS_MODULE="babybuddy.settings.base"
export SECRET_KEY="$(cat /config/.secretkey)"
cd /app/www/public
python manage.py --help
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on container startup.

## Home Assistant integration

Baby Buddy integrates with Home Assistant via:
- [Home Assistant Addon](https://github.com/OttPeterR/addon-babybuddy) — hosts Baby Buddy inside HA
- [Home Assistant integration](https://github.com/jcgoette/baby_buddy_homeassistant) — connects HA to an existing Baby Buddy instance

## Gotchas

- **Default credentials are admin/admin** — change the password immediately after first login.
- The LinuxServer image is community-maintained, not official from the Baby Buddy project. It is, however, the upstream-recommended Docker deployment method.
- SQLite is the default database and works well for single-household use. For multiple concurrent users or higher load, configure PostgreSQL via the `DB_*` environment variables.
- `SECRET_KEY` is auto-generated and stored in `/config/.secretkey` on first run — this is fine for most deployments.

## Upstream docs

- README: https://github.com/babybuddy/babybuddy/blob/master/README.md
- Deployment guide: https://docs.baby-buddy.net/setup/deployment/
- Configuration reference: https://docs.baby-buddy.net/setup/configuration/
- LinuxServer Docker image: https://github.com/linuxserver/docker-babybuddy
