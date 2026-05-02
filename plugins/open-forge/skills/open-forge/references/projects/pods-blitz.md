# Pods-Blitz

**What it is:** A self-hosted podcast publishing platform. Import existing podcasts, schedule episode publication, host a per-podcast website, manage subscribers with premium/paid feeds, and store media in any S3-compatible bucket. Multi-tenant — host unlimited podcasts from one instance. Includes Podlove web player and subscribe button integration.

**Official URL:** https://pods-blitz.org
**Docs:** https://docs.pods-blitz.org
**Repo:** https://codeberg.org/pods-blitz/pods-blitz
**License:** MIT / Apache-2.0 (dual)
**Stack:** Rust + MariaDB; Docker Compose (build from source)

> **Note:** No pre-built Docker image on a public registry — must build from source using the provided `docker-compose.yml` and `Dockerfile`.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose (build) | Clone repo and `docker compose up --build` |

---

## Inputs to Collect

### Pre-deployment (`.env` or environment)
- `DB_ROOT_PASSWORD` — MariaDB root password
- `DB_NAME` — database name (default: `podsblitz`)
- `DB_USER` — database user (default: `podsblitz`)
- `DB_PASSWORD` — database user password
- `BASE_URL` — public URL of your instance (e.g. `https://podcasts.example.com/`)
- `HOST_PORT` — host port to bind (default: `3002`)
- `ASSETS_PATH` — host path for uploaded media/assets (default: `./data/assets`)
- `RSS_PATH` — host path for generated RSS feeds (default: `./data/rss`)

### Optional
- S3-compatible bucket credentials — configured in `config.toml` for external media storage

---

## Software-Layer Concerns

**Installation:**
```bash
git clone https://codeberg.org/pods-blitz/pods-blitz.git
cd pods-blitz
cp config.toml.example config.toml   # edit as needed
# Create a .env file with DB and URL settings
docker compose up -d --build
```

**Docker Compose overview:**
```yaml
services:
  db:
    image: mariadb:11
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-changeme}
      MYSQL_DATABASE: ${DB_NAME:-podsblitz}
      MYSQL_USER: ${DB_USER:-podsblitz}
      MYSQL_PASSWORD: ${DB_PASSWORD:-changeme}
    volumes:
      - db_data:/var/lib/mysql

  app:
    build: .
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: mysql://${DB_USER}:${DB_PASSWORD}@db/${DB_NAME}
      BASE_URL: ${BASE_URL:-http://localhost:3002/}
      LISTEN_PORT: "3002"
    volumes:
      - ${ASSETS_PATH:-./data/assets}:/app/assets
      - ${RSS_PATH:-./data/rss}:/app/rss
      - ./config.toml:/app/config.toml:ro
    ports:
      - "${HOST_PORT:-3002}:3002"
```

**Default port:** `3002`

**`config.toml`:** Contains application-level settings including optional S3 storage config. Start from `config.toml.example` in the repo.

**Upgrade procedure:**
```bash
git pull
docker compose up -d --build
```

---

## Gotchas

- **Build from source** — no public container image; must build with Docker using the repo's `Dockerfile`
- **MariaDB healthcheck required** — app waits for DB to be healthy before starting; already handled in the compose file
- **`BASE_URL` must match your public URL** — incorrect URL breaks RSS feed links and podcast website URLs
- **S3 storage is optional** — without it, media files are stored in the local `./data/assets` volume

---

## Links
- Codeberg: https://codeberg.org/pods-blitz/pods-blitz
- Docs: https://docs.pods-blitz.org
- Website: https://pods-blitz.org
