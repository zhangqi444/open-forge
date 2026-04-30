---
name: wallabag
description: Self-hosted read-later / bookmarking service. Save articles, strip cruft (ads, sidebars, popups), read later on web / mobile / Kobo / ePaper. PHP/Symfony + SQLite/MySQL/MariaDB/Postgres. Official Android + iOS apps, browser extensions for Firefox/Chrome/Safari. MIT.
---

# wallabag

wallabag is the de-facto OSS Pocket alternative. Save URLs via browser extension, mobile app, iOS share sheet, API, or bookmarklet; wallabag fetches the page, runs it through a readability parser (same engine as Mozilla Readability / Graby), strips ads + navigation + popups, and stores clean article text for later. Read on web, in official apps (Android / iOS), on Kobo e-readers (native wallabag client), or via the API.

Features: tags, annotations, highlights, full-text search, reading progress, multiple configurations per-user, share-a-link, RSS of your own archive, OPDS feed for e-readers.

- Upstream repo: <https://github.com/wallabag/wallabag>
- Website: <https://wallabag.org>
- Docs: <https://doc.wallabag.org>
- Install guide: <https://doc.wallabag.org/admin/installation/installation>
- Cloud: <https://wallabag.it> (commercial hosted)
- Apps: <https://app.wallabag.it>

## Architecture in one minute

- **`wallabag`** — PHP/Symfony web app + API. Serves HTTP, runs background parsers
- **DB**: SQLite (default for small installs), MariaDB/MySQL, or Postgres
- **Redis** (optional) — for caching + background queue
- **RabbitMQ** (optional) — for heavy parallel article fetching at scale
- **Official apps** (Android, iOS) and **browser extensions** (Firefox/Chrome/Safari) all use the same API

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                                  |
| ----------- | ------------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM   | Docker (`wallabag/wallabag:<VERSION>`)                  | **Recommended for most self-hosts**                                     |
| Single VM   | Docker Compose with MariaDB/Postgres                    | For shared/team installs                                                |
| Single VM   | Bare-metal PHP/Nginx + MariaDB                          | Classic; documented in upstream install docs                            |
| Kubernetes  | Community charts                                        | Not upstream-maintained                                                 |
| Managed     | wallabag.it                                              | SaaS option                                                             |
| NAS         | Synology / QNAP / YunoHost packages                      | YunoHost integration is mature                                          |

## Inputs to collect

| Input                        | Example                             | Phase     | Notes                                                           |
| ---------------------------- | ----------------------------------- | --------- | --------------------------------------------------------------- |
| Public URL                   | `https://wallabag.example.com`      | DNS       | Used in article share links + API OAuth flow                     |
| `SYMFONY__ENV__DOMAIN_NAME`  | `https://wallabag.example.com`      | Runtime   | Main domain config                                               |
| DB                           | SQLite (default) / MariaDB / Postgres | DB      | SQLite fine for solo; MariaDB for multi-user                     |
| `SYMFONY__ENV__DATABASE_*`   | host/port/name/user/pw              | DB        | Only if not using SQLite                                         |
| `SYMFONY__ENV__SECRET`       | `openssl rand -hex 32`              | Security  | **Critical** — Symfony signing key                               |
| Admin account                | via wizard on first visit           | Bootstrap | First user = admin; subsequent signups gated by user settings    |
| SMTP (optional)              | for password reset + notifications  | Email     | Not strictly required                                            |

## Install via Docker (single container, SQLite)

Simplest; bundles everything:

```yaml
services:
  wallabag:
    image: wallabag/wallabag:2.6.11     # pin
    container_name: wallabag
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - SYMFONY__ENV__DATABASE_DRIVER=pdo_sqlite
      - SYMFONY__ENV__DATABASE_PATH=/var/www/wallabag/data/db/wallabag.sqlite
      - SYMFONY__ENV__DOMAIN_NAME=https://wallabag.example.com
      - SYMFONY__ENV__SECRET=<openssl rand -hex 32>
      - SYMFONY__ENV__FOSUSER_REGISTRATION=false      # no public signup
      - SYMFONY__ENV__FOSUSER_CONFIRMATION=false      # no email verification required
    volumes:
      - wallabag_data:/var/www/wallabag/data
      - wallabag_images:/var/www/wallabag/web/assets/images

volumes:
  wallabag_data:
  wallabag_images:
```

Default admin: `wallabag` / `wallabag` — **CHANGE IMMEDIATELY**.

## Install via Docker Compose (MariaDB for multi-user)

```yaml
services:
  wallabag:
    image: wallabag/wallabag:2.6.11
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - SYMFONY__ENV__DATABASE_DRIVER=pdo_mysql
      - SYMFONY__ENV__DATABASE_HOST=db
      - SYMFONY__ENV__DATABASE_PORT=3306
      - SYMFONY__ENV__DATABASE_NAME=wallabag
      - SYMFONY__ENV__DATABASE_USER=wallabag
      - SYMFONY__ENV__DATABASE_PASSWORD=<strong>
      - SYMFONY__ENV__DOMAIN_NAME=https://wallabag.example.com
      - SYMFONY__ENV__SECRET=<openssl rand -hex 32>
      - SYMFONY__ENV__FOSUSER_REGISTRATION=false
      - SYMFONY__ENV__FROM_EMAIL=wallabag@example.com
      - SYMFONY__ENV__MAILER_DSN=smtp://user:pass@smtp.example.com:587
    depends_on:
      - db

  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      - MYSQL_DATABASE=wallabag
      - MYSQL_USER=wallabag
      - MYSQL_PASSWORD=<strong>
      - MYSQL_ROOT_PASSWORD=<strong>
    volumes:
      - wallabag_db:/var/lib/mysql

volumes:
  wallabag_db:
```

Upstream "official" production compose in the repo (`compose.yaml`) is the **dev-mode** compose — used by contributors. For production, build your own like above using the published `wallabag/wallabag` image.

## First boot

1. Browse `https://wallabag.example.com`
2. Log in as `wallabag` / `wallabag`
3. Go to **Config → User** → Change password; change username if desired
4. Config → System info → Take note of API client credentials (auto-generated)
5. Install browser extension from Firefox/Chrome store; point at your URL + log in with API credentials

## Connect the official mobile apps

Android / iOS apps ask for URL + username + password on first run. They use OAuth to request a token. Ensure your wallabag URL is externally reachable (either public or VPN).

## Data & config layout

Inside container:

- `/var/www/wallabag/data/` — primary data volume
  - `db/wallabag.sqlite` — SQLite DB (if SQLite mode)
  - `assets/` — fetched article assets
- `/var/www/wallabag/web/assets/images/` — per-article preview images
- `/var/www/wallabag/app/config/parameters.yml` — generated from env vars

Articles themselves: stored in the DB as HTML. Large imports are big — plan DB storage.

## Backup

```sh
# SQLite
docker run --rm -v wallabag_data:/src -v "$PWD":/backup alpine \
  tar czf /backup/wallabag-$(date +%F).tgz -C /src .

# MariaDB
docker compose exec -T db mysqldump -uroot -p"<pw>" wallabag | gzip > wallabag-db-$(date +%F).sql.gz

# Images separately
docker run --rm -v wallabag_images:/src -v "$PWD":/backup alpine \
  tar czf /backup/wallabag-images-$(date +%F).tgz -C /src .
```

## Upgrade

1. Releases: <https://github.com/wallabag/wallabag/releases>. Irregular (several per year).
2. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
3. **Backup DB before every upgrade.** Migrations are usually clean but occasionally need manual intervention.
4. Major versions (2.5 → 2.6) may change config env var names. Read release notes.
5. Upgrade guide per major: <https://doc.wallabag.org/admin/upgrade>.

## Gotchas

- **Default admin `wallabag` / `wallabag`** — change on first login. Bot scanners look for it.
- **Public signup is ON by default** (`SYMFONY__ENV__FOSUSER_REGISTRATION=true`). Disable unless you want anyone to sign up.
- **Domain baked into OAuth redirect URIs.** Changing `SYMFONY__ENV__DOMAIN_NAME` after apps are paired = apps lose access; reauthorize.
- **Article fetching uses Graby**, a PHP library that runs JS-free. Sites that are SPA-only (require a headless browser) won't parse well. For those, combine with **SingleFile** browser extension for a pre-fetch snapshot.
- **Paywalls, JS-gated content, and sites that block serverside fetch** don't parse. Browser extension's "fetch from page" mode uses your browser's rendered HTML and bypasses this.
- **SQLite works but has concurrency limits.** Bulk imports (500+ articles) may stall. MariaDB/Postgres scales better.
- **Symfony cache clear on upgrade** can be slow the first request after; expect a 10-30s hiccup.
- **RSS output of your archive** is per-user, tokenized via config. Useful for syncing to Feedly / Inoreader or Kobo.
- **Full-text search** uses MySQL FULLTEXT or Postgres tsvector if enabled; SQLite has limited FTS. Config in Internal settings.
- **Kobo sync** via the official `Koreader` e-reader plugin + wallabag's OPDS feed is a beloved pairing.
- **Import from Pocket / Instapaper / Readability / Wallabag v1** via Config → Import. Some formats (Pocket HTML export) require pre-processing.
- **Share a public article** — unique URL, unauth'd read. Check that your reverse proxy doesn't block the `/share/` paths.
- **Annotations API** lets you highlight + note text; supported by the official apps.
- **Hydroxide / OAuth2 clients**: you can create API tokens in Config → API Clients. Each app (mobile, extension) gets its own client_id/secret.
- **Default user quota: unlimited**. Multi-tenant installs may want to restrict via admin settings.
- **PDF / EPUB / MOBI export per-article** for offline reading.
- **`wallabagger` browser extension** is the Firefox/Chrome companion; install from browser extension stores.
- **SingleFile integration** (optional) lets you pre-render JS-heavy pages in your browser + send the full HTML to wallabag — major fidelity upgrade.
- **Memory**: modest — 200-500 MB typical.
- **License**: MIT. No copyleft.
- **Alternatives worth knowing:**
  - **Omnivore** — archived as of 2024; data export needed
  - **Karakeep / Hoarder** — newer, AI tagging, team-friendly
  - **Shiori** — minimal, Go-based bookmark manager
  - **LinkAce** — PHP, prettier UI, heavier feature set
  - **Linkwarden** — modern, Next.js, team + link archival
  - **Shaarli** — simple, single-user, PHP
  - **Pocket** — commercial (Mozilla); shutting down

## Links

- Repo: <https://github.com/wallabag/wallabag>
- Website: <https://wallabag.org>
- Docs: <https://doc.wallabag.org>
- Installation: <https://doc.wallabag.org/admin/installation/installation>
- Docker image: <https://hub.docker.com/r/wallabag/wallabag>
- Upgrade guide: <https://doc.wallabag.org/admin/upgrade>
- Releases: <https://github.com/wallabag/wallabag/releases>
- Android app: <https://github.com/wallabag/android-app>
- iOS app: <https://github.com/wallabag/ios-app>
- Firefox extension: <https://addons.mozilla.org/firefox/addon/wallabagger/>
- Chrome extension: <https://chrome.google.com/webstore/detail/wallabagger/gbmgphmejlcoihgedabhgjdkcahacjlj>
- Cloud: <https://wallabag.it>
- Demo: <https://app.wallabag.it>
