---
name: Wiki.js
description: "Modern, lightweight wiki built on Node.js — markdown editing, rich media, full-text search, granular permissions, and 40+ auth providers. Self-hosts on PostgreSQL, MySQL, MariaDB, or SQLite. AGPLv3."
---

# Wiki.js

**What it is:** A powerful, extensible wiki platform that runs on Node.js. Supports Markdown (and other editors), git-based storage, full-text search (Elasticsearch, PostgreSQL, Manticore), granular role permissions, and 40+ authentication providers. Clean admin UI for managing pages, users, storage backends, and integrations.

**Official site:** https://js.wiki
**Docs:** https://docs.requarks.io
**GitHub:** https://github.com/requarks/wiki
**License:** AGPLv3

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | PostgreSQL | Recommended; best performance |
| Docker Compose | MySQL / MariaDB | Supported |
| Docker | SQLite | Dev/small installs only |
| Kubernetes / Helm | PostgreSQL | Helm chart available |
| Bare metal | Node.js 18+ + PostgreSQL | Advanced/dev setup |

---

## Inputs to Collect

### Required
- `DB_TYPE` — `postgres`, `mysql`, `mariadb`, or `sqlite`
- `DB_HOST` — database hostname
- `DB_PORT` — database port (5432 for Postgres)
- `DB_USER` — database user
- `DB_PASS` — database password
- `DB_NAME` — database name

### Optional
- `LETSENCRYPT_DOMAIN` — enable built-in Let's Encrypt TLS (alternative: use external reverse proxy)
- `LETSENCRYPT_EMAIL` — email for Let's Encrypt cert

---

## Software-Layer Concerns

### Services
| Service | Image | Port |
|---------|-------|------|
| wiki | `ghcr.io/requarks/wiki:2` | 3000 (HTTP), 3443 (HTTPS) |
| db | `postgres:15-alpine` | internal |

### Data volumes
- `db-data` — PostgreSQL data
- Wiki pages can optionally be mirrored to a git repo (configured in admin UI)

### Config
Wiki.js is configured entirely via the admin UI after first boot — no `.env` file for app settings (only DB connection details are env vars).

---

## Deployment Steps

```bash
mkdir -p ~/docker-apps/wikijs && cd ~/docker-apps/wikijs

cat > docker-compose.yml << 'COMPOSE'
version: "3"
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: wiki
      POSTGRES_PASSWORD: wikijsrocks
      POSTGRES_USER: wikijs
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped

  wiki:
    image: ghcr.io/requarks/wiki:2
    depends_on:
      - db
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: wikijs
      DB_PASS: wikijsrocks
      DB_NAME: wiki
    ports:
      - "3000:3000"
    restart: unless-stopped

volumes:
  db-data:
COMPOSE

docker compose up -d
# Admin setup wizard: http://localhost:3000
```

---

## Upgrade Procedure

```bash
cd ~/docker-apps/wikijs
docker compose pull
docker compose up -d
# Wiki.js auto-runs DB migrations on startup
```

---

## Gotchas

- **First-run wizard** — After first boot, navigate to `http://<host>:3000` to complete the setup wizard and create the admin account. Until this step completes, the wiki is not accessible.
- **PostgreSQL strongly preferred** — SQLite is only suitable for local dev; it lacks full-text search and some features. Use PostgreSQL for any real deployment.
- **Git storage is optional** — Wiki.js can push page content to a git repo for backup/versioning. Configure in Admin → Storage after setup.
- **Authentication** — Defaults to local username/password. Additional providers (GitHub, Google, LDAP, SAML, etc.) are configured in Admin → Authentication.
- **Search requires indexing** — After enabling a search provider in Admin → Search, trigger a full re-index from the admin UI.
- **AGPLv3 copyleft** — If you modify and distribute Wiki.js, the modified source must be made available under AGPLv3.
- **Port 3443** — For built-in TLS (Let's Encrypt), expose port 3443 and set `LETSENCRYPT_DOMAIN`/`LETSENCRYPT_EMAIL` env vars. Otherwise use an external reverse proxy.
- **Wiki.js 3 (beta)** — A v3 rewrite is in development. Current stable is v2; check the repo for migration notes before upgrading major versions.

---

## Links
- GitHub: https://github.com/requarks/wiki
- Documentation: https://docs.requarks.io
- Install guide: https://docs.requarks.io/install
- Docker install: https://docs.requarks.io/install/docker
- Requirements: https://docs.requarks.io/install/requirements
- Changelog: https://github.com/requarks/wiki/releases
