---
name: sosse-project
description: Sosse recipe for open-forge. Self-hosted Selenium-based open-source search engine and web archiver. Crawl/index JavaScript-heavy pages via Firefox/Chromium+Selenium. Recurring crawl policies, HTML archiving, tag-based organization, file downloads, webhooks for AI processing, Atom feeds, authentication-aware crawling, multi-user permissions. Python + PostgreSQL + Django. Upstream: https://github.com/biolds/sosse / https://gitlab.com/biolds1/sosse
---

# Sosse

A self-hosted search engine and web archiver built in Python. Uses Firefox or Chromium via Selenium to index JavaScript-rendered pages -- sites that simple HTTP scrapers can't handle. Features recurring crawl schedules, full HTML archiving (with asset download and link rewriting), tag-based organization, batch file downloads, webhooks for AI/external integrations, Atom feed generation, authentication-aware crawling, and multi-user access control. Django admin interface.

Upstream: <https://github.com/biolds/sosse> | Docs: <https://sosse.readthedocs.io/en/stable/> | Website: <https://sosse.io>

2-container stack: app + PostgreSQL.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64) | Selenium/browser in container; CPU-heavy during crawls |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8000` (container runs on 80) |
| config | "DB credentials?" | `SOSSE_DB_NAME`, `SOSSE_DB_USER`, `SOSSE_DB_PASS` -- must match Postgres env |
| config | "DB host?" | `SOSSE_DB_HOST` -- service name of the Postgres container |

## Software-layer concerns

### Images

```
biolds/sosse:pip-compose      # app
postgres:17                   # database
```

### Compose

```yaml
services:
  sosse:
    image: biolds/sosse:pip-compose
    container_name: sosse_app
    depends_on:
      - postgres
    environment:
      - SOSSE_DB_NAME=sosse_db
      - SOSSE_DB_USER=sosse_user
      - SOSSE_DB_PASS=sosse_password
      - SOSSE_DB_HOST=postgres
    ports:
      - "8000:80"
    volumes:
      - sosse_data:/var/lib/sosse
    restart: always

  postgres:
    image: postgres:17
    container_name: sosse_db
    environment:
      POSTGRES_USER: sosse_user
      POSTGRES_PASSWORD: sosse_password
      POSTGRES_DB: sosse_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

volumes:
  sosse_data:
  postgres_data:
```

Source: upstream README -- https://github.com/biolds/sosse

### Key environment variables

All configuration variables are prefixed with `SOSSE_`. Full reference: <https://sosse.readthedocs.io/en/stable/config_file.html>

| Variable | Purpose |
|---|---|
| `SOSSE_DB_NAME` | PostgreSQL database name |
| `SOSSE_DB_USER` | PostgreSQL username |
| `SOSSE_DB_PASS` | PostgreSQL password |
| `SOSSE_DB_HOST` | PostgreSQL hostname (service name in compose) |

### Features

- **Browser-based crawling** -- uses Firefox or Chromium + Selenium for JS-rendered pages; falls back to Python Requests for faster crawls on simple pages
- **Recurring crawl policies** -- fixed interval or adaptive (adjusts based on content change rate)
- **Web archiving** -- saves HTML content, rewrites links for offline use, downloads assets (images, CSS, JS)
- **Tags** -- organize and filter crawled/archived pages
- **File downloads** -- batch download binary files (PDFs, ZIPs, etc.) discovered during crawls
- **Webhooks** -- trigger external services on new content; integrate with AI APIs (OpenAI, etc.) or local models for summarization/tagging/notifications
- **Atom feeds** -- generate RSS/Atom feeds for any website; monitor for keyword appearances
- **Authentication** -- crawler can log in to access private pages
- **Permissions** -- admin (full access), authenticated user (search + personal history), anonymous (read-only search if permitted)
- **Search history** -- private per-user search history
- **External search shortcuts** -- route searches to external engines via keyword shortcuts

### First run

After `docker compose up -d`, run Django migrations and create a superuser:

```bash
docker exec -it sosse_app sosse-admin migrate
docker exec -it sosse_app sosse-admin createsuperuser
```

Then access the admin interface at `http://your-host:8000/admin`.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker exec -it sosse_app sosse-admin migrate
```

Run migrations after every upgrade.

## Gotchas

- **CPU-heavy during crawls** -- browser-based crawling via Selenium is resource-intensive. On a small VPS, limit concurrent crawlers in the settings.
- **PostgreSQL required** -- no SQLite option. The Postgres container must be healthy before sosse starts; `depends_on` handles ordering but not readiness. Add a healthcheck if you see startup failures.
- **Port 5432 exposed** -- the example compose exposes Postgres on the host. Remove `ports:` from the postgres service if you don't need external DB access.
- **Migrations required** -- skipping `sosse-admin migrate` after upgrades will cause 500 errors or missing features.
- **Selenium image size** -- the `pip-compose` image includes a full browser environment and is large. Ensure adequate disk space.
- **`SOSSE_` prefix** -- every configuration option from the config file can be overridden via environment variable with the `SOSSE_` prefix. See full reference: <https://sosse.readthedocs.io/en/stable/config_file.html>

## Links

- Upstream README (GitHub): <https://github.com/biolds/sosse>
- GitLab mirror: <https://gitlab.com/biolds1/sosse>
- Documentation: <https://sosse.readthedocs.io/en/stable/>
- Config reference: <https://sosse.readthedocs.io/en/stable/config_file.html>
- Website: <https://sosse.io>
- Discord: <https://discord.gg/Vt9cMf7BGK>
