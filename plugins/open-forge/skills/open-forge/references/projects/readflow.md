---
name: Readflow
description: Lightweight news reader with modern interface. Full-text search, automatic categorization, archiving, offline support, notifications, and outgoing webhooks. PostgreSQL backend. MIT licensed.
website: https://readflow.app
source: https://github.com/ncarlier/readflow
license: MIT
stars: 468
tags:
  - rss
  - news-reader
  - read-later
  - articles
platforms:
  - Go
  - Docker
---

# Readflow

Readflow is a lightweight, self-hosted news reading application. Read articles from any source in one place, categorize them automatically, save for offline reading in multiple formats (HTML, PDF, EPUB, ZIP), and connect with external services via webhooks. Features a progressive web app for mobile, no ads, and no trackers.

Source: https://github.com/ncarlier/readflow
Hosted version: https://readflow.app
Docs: https://github.com/ncarlier/readflow/wiki
Docker Hub: https://hub.docker.com/r/ncarlier/readflow/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose + PostgreSQL | Recommended |
| Any Linux | Go binary + PostgreSQL | Native install |

## Inputs to Collect

**Phase: Planning**
- PostgreSQL connection URI
- Authentication method: `basic` (htpasswd), `proxy` (reverse proxy headers), or OIDC
- Port to expose (default: 8080)
- htpasswd file path (if using basic auth)

## Software-Layer Concerns

**Docker Compose:**

```yaml
services:
  db:
    image: postgres:17
    restart: always
    environment:
      - POSTGRES_DB=readflow
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=CHANGE_ME
    volumes:
      - db_data:/var/lib/postgresql/data

  readflow:
    image: ncarlier/readflow:edge
    restart: always
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - READFLOW_DATABASE_URI=postgres://postgres:CHANGE_ME@db/readflow?sslmode=disable
      - READFLOW_AUTHN_METHOD=basic
      - READFLOW_AUTHN_BASIC_HTPASSWD_FILE=file:///var/local/users.htpasswd
    volumes:
      - ./users.htpasswd:/var/local/users.htpasswd

volumes:
  db_data:
```

**Create htpasswd file:**

```bash
# Install htpasswd (apache2-utils)
sudo apt install apache2-utils
htpasswd -c users.htpasswd yourname
# Enter password when prompted
```

**Or start with docker compose using the official file:**

```bash
git clone https://github.com/ncarlier/readflow
cd readflow
docker compose up -d
# Default: demo/demo (from the included demo.htpasswd)
```

**Key environment variables:**

| Variable | Description |
|----------|-------------|
| READFLOW_DATABASE_URI | PostgreSQL connection string |
| READFLOW_AUTHN_METHOD | Auth method: `basic`, `proxy`, `oidc` |
| READFLOW_AUTHN_BASIC_HTPASSWD_FILE | Path to htpasswd file |
| READFLOW_CONFIG | Path to TOML config file (alternative to env vars) |

**Native install:**

```bash
go install -v github.com/ncarlier/readflow@latest
# Or use install script:
curl -s https://raw.githubusercontent.com/ncarlier/readflow/master/install.sh | bash
```

**Supported integrations (outgoing webhooks):**
- Pocket, Wallabag, Shaarli, Keeper
- RSS via feedpushr
- S3 bucket
- Newsletter/email
- Generic webhook

## Upgrade Procedure

1. `docker pull ncarlier/readflow:edge`
2. `docker compose down && docker compose up -d`
3. Migrations run automatically on startup
4. Check releases: https://github.com/ncarlier/readflow/releases

## Gotchas

- **Auth is external**: Readflow doesn't have a native user management UI — authentication is via htpasswd file, reverse proxy headers, or OIDC; plan your auth strategy before deploying
- **Default demo credentials**: The bundled docker-compose uses `demo/demo` — change the htpasswd file before exposing publicly
- **PWA support**: Works as a progressive web app on mobile — access via browser and add to home screen
- **Article ingestion**: Articles are pushed into readflow via its API or incoming webhooks; you feed it from RSS readers, browser extensions, or other services
- **`edge` tag**: The `edge` Docker image tracks the latest development build; use a specific version tag for more stable production deployments

## Links

- Upstream README: https://github.com/ncarlier/readflow/blob/master/README.md
- Wiki: https://github.com/ncarlier/readflow/wiki
- Docker Hub: https://hub.docker.com/r/ncarlier/readflow/
- Releases: https://github.com/ncarlier/readflow/releases
