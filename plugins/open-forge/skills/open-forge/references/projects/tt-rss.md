# Tiny Tiny RSS (tt-rss)

Web-based RSS/Atom feed reader and aggregator. Runs as a self-hosted service that continuously fetches and stores articles from subscribed feeds, providing a centralized reading interface accessible from any browser or via API to mobile clients.

**Official site:** https://tt-rss.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; multi-container (app + updater + nginx + db) |
| Any Linux host | PHP + PostgreSQL | Manual install on Debian/Ubuntu with PHP 8.2+ |
| Raspberry Pi / ARM | Docker Compose | ARM64 images available (`ghcr.io/tt-rss/tt-rss`) |

---

## Inputs to Collect

### Phase 1 — Planning
- PostgreSQL credentials (`TTRSS_DB_USER`, `TTRSS_DB_PASS`, `TTRSS_DB_NAME`)
- HTTP port to expose (default `127.0.0.1:8280` — localhost only; remove prefix for public)
- Admin password (optional — random generated on first start if not set)

### Phase 2 — Deployment
- `.env` file with DB credentials and port config
- Whether to expose directly or behind a reverse proxy

---

## Software-Layer Concerns

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:17-alpine
    restart: unless-stopped
    env_file:
      - .env
    environment:
      - POSTGRES_USER=${TTRSS_DB_USER}
      - POSTGRES_PASSWORD=${TTRSS_DB_PASS}
      - POSTGRES_DB=${TTRSS_DB_NAME}
    volumes:
      - db:/var/lib/postgresql/data

  app:
    image: supahgreg/tt-rss:latest
    # or: ghcr.io/tt-rss/tt-rss:latest
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - app:/var/www/html
      - ./config.d:/opt/tt-rss/config.d:ro
    depends_on:
      - db

  updater:
    image: supahgreg/tt-rss:latest
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - app:/var/www/html
      - ./config.d:/opt/tt-rss/config.d:ro
    depends_on:
      - app
    command: /opt/tt-rss/updater.sh

  web-nginx:
    image: supahgreg/tt-rss-web-nginx:latest
    # or: ghcr.io/tt-rss/tt-rss-web-nginx:latest
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - ${HTTP_PORT}:80
    volumes:
      - app:/var/www/html:ro
    depends_on:
      - app

volumes:
  db:
  app:
```

### .env

```ini
# Database credentials
TTRSS_DB_USER=postgres
TTRSS_DB_NAME=postgres
TTRSS_DB_PASS=change-me

# HTTP bind — use 127.0.0.1:8280 behind reverse proxy, or 8280 to expose directly
HTTP_PORT=127.0.0.1:8280

# Optional: set admin password on startup (random if unset — check 'app' container logs)
#ADMIN_USER_PASS=

# Optional: auto-create a second user
#AUTO_CREATE_USER=
#AUTO_CREATE_USER_PASS=
```

### Key Config Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `TTRSS_DB_USER` | — | PostgreSQL username |
| `TTRSS_DB_PASS` | — | PostgreSQL password |
| `TTRSS_DB_NAME` | — | PostgreSQL database name |
| `HTTP_PORT` | `127.0.0.1:8280` | Host:port binding for nginx container |
| `ADMIN_USER_PASS` | (random) | Admin password; check app logs if unset |
| `OWNER_UID` / `OWNER_GID` | (container default) | UID/GID for PHP-FPM process |

### Access
After `docker compose up -d`, open `http://127.0.0.1:8280/tt-rss` (or your configured `HTTP_PORT`). Log in as `admin` with the password set in `.env` or found in `docker compose logs app`.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

If a database schema upgrade is required, tt-rss redirects to an upgrade screen in the browser — follow the prompts. Back up PostgreSQL data before major upgrades.

**PostgreSQL major version upgrade** (e.g., 15 → 17): requires a pg_dumpall + restore cycle; see [FAQ](https://tt-rss.github.io/docs/Installation-Guide.html).

---

## Gotchas

- **Three containers for the app** — `app` (PHP-FPM), `updater` (feed fetcher daemon), and `web-nginx` (HTTP frontend) all share the same `app` volume.
- **`updater` container is required** — without it, feeds are never fetched. It's not a cron job; it's a long-running daemon.
- **Random admin password** — if `ADMIN_USER_PASS` is not set, check `docker compose logs app` for the generated password on first start.
- **PostgreSQL only** — MySQL/MariaDB is not supported.
- **Port binding** — default `HTTP_PORT=127.0.0.1:8280` only binds to localhost; intended for use behind a reverse proxy. Remove `127.0.0.1:` to expose to the network.
- **Project history** — the original tt-rss at `tt-rss.org` was retired 2025-11-01; this GitHub fork (`github.com/tt-rss/tt-rss`) is the active continuation with drop-in compatible Docker images.
- **Plugin config** — drop custom PHP config overrides into `./config.d/` (mounted at `/opt/tt-rss/config.d:ro`).

---

## References
- GitHub: https://github.com/tt-rss/tt-rss
- Installation guide: https://tt-rss.github.io/docs/Installation-Guide.html
- Docker Hub: https://hub.docker.com/r/supahgreg/tt-rss
- GHCR: https://github.com/orgs/tt-rss/packages
