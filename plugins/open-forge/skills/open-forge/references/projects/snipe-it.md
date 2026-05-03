---
name: Snipe-IT
description: Open-source IT asset management. Tracks hardware (laptops, phones, servers), licenses, consumables, components, accessories — who has what, when it was assigned, depreciation, audit history. Laravel + MariaDB. AGPL-3.0.
---

# Snipe-IT

Snipe-IT is the go-to open-source IT asset management system for small-to-medium orgs. Track every laptop, phone, monitor, software license, patch cable, and USB dongle; assign to users; trace check-in/check-out history; depreciate assets; print barcode labels; audit remotely via mobile app. Used by schools, hospitals, small businesses, MSPs.

Recently changed ownership: repo moved from `snipe/snipe-it` to `grokability/snipe-it` (Grokability acquired). Development continues.

- Upstream repo: <https://github.com/grokability/snipe-it>
- Website: <https://snipeitapp.com>
- Docs: <https://snipe-it.readme.io>
- Install docs: <https://snipe-it.readme.io/docs/installation>
- Docker docs: <https://snipe-it.readme.io/docs/docker>
- Demo: <https://demo.snipeitapp.com>

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                                    |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------------------------ |
| Single VM   | Docker Compose (`snipe/snipe-it` image + MariaDB)       | **Upstream-maintained** — this recipe                                     |
| Single VM   | LAMP stack manual install                                | Classic path; upstream docs walk through                                  |
| Kubernetes  | Community charts                                         | Not upstream                                                              |
| Managed     | snipeitapp.com hosted                                   | Commercial Snipe-IT Cloud (paid)                                          |

## Inputs to collect

| Input                | Example                                      | Phase     | Notes                                                              |
| -------------------- | -------------------------------------------- | --------- | ------------------------------------------------------------------ |
| Domain / URL         | `https://snipeit.example.com`                | DNS       | `APP_URL` env; used in email links                                  |
| `APP_KEY`            | `base64:…` (32 bytes)                        | Security  | **Critical** — Laravel key encrypts session + password reset tokens  |
| DB creds             | `DB_DATABASE=snipeit`, user+password         | DB        | MariaDB 11.4+ recommended                                            |
| `MYSQL_ROOT_PASSWORD` | strong                                      | DB        | Set even if not directly used (healthcheck path)                     |
| Admin account        | via web wizard on first visit                | Bootstrap | Creates super-user via `/setup`                                      |
| SMTP                 | required for password reset + notifications  | Email     | Without, users can't reset passwords; config in `.env`               |
| LDAP/SAML (optional) | configured via UI post-install               | Auth      | SSO integrations                                                     |

## Install via Docker Compose

From <https://github.com/grokability/snipe-it/blob/master/docker-compose.yml> + `.env.docker`:

```yaml
volumes:
  db_data:
  storage:

services:
  app:
    image: snipe/snipe-it:v8.4.1          # pin! :latest moves fast
    restart: unless-stopped
    volumes:
      - storage:/var/lib/snipeit         # uploads, logs, backups
    ports:
      - "${APP_PORT:-8000}:80"
    depends_on:
      db: { condition: service_healthy, restart: true }
    env_file: [.env]

  db:
    image: mariadb:11.4.7
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/mysql
    environment:
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      retries: 5
```

Matching `.env` (copy `.env.docker` and edit):

```sh
# URL + app key
APP_URL=https://snipeit.example.com
APP_KEY=base64:...  # generate: docker run --rm snipe/snipe-it php artisan key:generate --show

# Database
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=snipeit
DB_USERNAME=snipeit
DB_PASSWORD=<strong>
MYSQL_ROOT_PASSWORD=<strong>

# Email (required for password reset)
MAIL_DRIVER=smtp
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=...
MAIL_PASSWORD=...
MAIL_FROM_ADDR=snipeit@example.com
MAIL_FROM_NAME="Snipe-IT"
MAIL_REPLYTO_ADDR=helpdesk@example.com
MAIL_REPLYTO_NAME="IT Helpdesk"

# Optional
APP_TIMEZONE='UTC'
APP_LOCALE=en-US
APP_DEBUG=false
```

### First-boot setup

1. `docker compose up -d`
2. On first visit to `APP_URL` → `/setup` wizard runs migrations + creates admin user
3. Install CA cert or put behind a reverse proxy for TLS (don't serve HTTP to real users — session cookies travel with credentials)

## Data & config layout

Inside `storage` volume (`/var/lib/snipeit`):

- `app/uploads/` — asset images, user avatars, imported CSVs, label logos
- `app/backups/` — output of the in-app backup tool (Admin → Utilities → Backups)
- `logs/laravel.log` — app log
- `framework/cache/`, `framework/sessions/` — runtime caches

Inside `db` volume — MariaDB data dir.

Main `.env` file — on the host, mounted via env_file. Contains APP_KEY + DB creds + SMTP creds.

## Backup

**Use the in-app backup tool.** Admin → Utilities → Backups → Generate Backup produces a single `.zip` with DB dump + file uploads.

```sh
# From host, pull the latest app backup
docker cp $(docker compose ps -q app):/var/lib/snipeit/app/backups/ ./snipeit-backups-$(date +%F)/

# Or DB-only pg_dump equivalent
docker compose exec -T db mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" snipeit | gzip > snipeit-db-$(date +%F).sql.gz
```

Back up the `.env` file separately (contains `APP_KEY`).

**Losing `APP_KEY` means losing access to encrypted fields** (API keys, LDAP passwords stored in settings). Database contents are still readable, but sealed fields become ciphertext garbage.

## Upgrade

1. Releases: <https://github.com/grokability/snipe-it/releases>. Frequent point releases.
2. Docker: update image tag → `docker compose pull app && docker compose up -d`. Migrations run on startup.
3. Minor version (v8.2 → v8.3) usually safe. Major (v7 → v8) read release notes; sometimes requires manual post-upgrade step.
4. **Back up `storage` + DB BEFORE upgrade.** Snipe-IT migrations are occasionally destructive (renames, drops).
5. Repo moved from `snipe/snipe-it` to `grokability/snipe-it` in 2024. Update your git remotes. **Docker image name is still `snipe/snipe-it`** (Docker Hub path didn't rename).
6. Switching from LAMP to Docker: upstream has a migration guide at <https://snipe-it.readme.io/docs/migrating-from-a-non-docker-install>.

## Gotchas

- **Repo rename.** `snipe/snipe-it` GitHub repo redirects to `grokability/snipe-it`. Update bookmarks + git remotes (`git remote set-url origin https://github.com/grokability/snipe-it.git`).
- **`APP_KEY` is critical.** Generated via `php artisan key:generate --show`. Losing it = sealed fields (API keys, LDAP pw, SAML cert pw) become unreadable. Back up the `.env` separately from the DB.
- **NEVER run the `/setup` wizard twice.** Second run attempts to re-create admin and errors out; clear DB if you really need to reset.
- **MariaDB 11.4.x is in the default compose.** Older (10.x) also works. MySQL works but MariaDB is upstream-tested.
- **`APP_URL` must exactly match what users type.** Mismatch = broken password reset links, broken label QR codes, broken asset URLs.
- **Email is required** for password reset flow. Without SMTP, a forgotten admin password = manual DB reset.
- **LDAP integration** is powerful but brittle. Test with a single test OU before mass import. Settings → LDAP.
- **Barcodes + labels** are generated in-app; label template is in Settings → Labels. Printer settings (DYMO/Zebra) via browser print dialog.
- **Asset model vs asset tag.** Model = "MacBook Pro 14 M3". Asset = specific serial number. Tag = human-readable identifier (sticker on the laptop). Category = depreciation class.
- **Depreciation** is computed per-asset from model → category depreciation rule. Changes are NOT retroactive to existing assets unless you re-run the calc.
- **Custom fields** are per-asset-model. Great for MAC addresses, warranty dates; bad if you add 50 of them and they apply to every asset.
- **API is REST with bearer tokens.** Create a personal access token in Admin → API. Docs: <https://snipe-it.readme.io/reference>.
- **CSV import** is how most orgs bulk-seed. Use the sample CSV in Admin → Imports; common gotcha is date format mismatch.
- **Time zone.** Set `APP_TIMEZONE` correctly or audit timestamps will be wrong.
- **Laravel queue worker** is not started in the default compose. Bulk operations and some emails rely on it — for large installs, add a `queue` service that runs `php artisan queue:work`.
- **Automatic update notifications** in UI sometimes show false positives if your image tag is newer than the GitHub release feed expects.
- **Two-factor auth** (Google Authenticator) works; enable per-user in profile, or force org-wide in Settings → Security.
- **SAML/SSO** setup is post-install through UI; test in a secondary browser to avoid locking yourself out.
- **AGPL-3.0.** Modified public-facing Snipe-IT = offer source.
- **Alternatives worth knowing:**
  - **GLPI** — larger, ITIL-aligned, heavier
  - **Ralph NG** — Python/Django, similar scope
  - **iTop** — ITSM + CMDB, more enterprise
  - **OpenBoxes** — inventory-focused
  - **AssetTiger** — commercial SaaS

## Links

- Repo: <https://github.com/grokability/snipe-it>
- Website: <https://snipeitapp.com>
- Docs: <https://snipe-it.readme.io>
- Installation: <https://snipe-it.readme.io/docs/installation>
- Docker install: <https://snipe-it.readme.io/docs/docker>
- Migrate to Docker: <https://snipe-it.readme.io/docs/migrating-from-a-non-docker-install>
- API reference: <https://snipe-it.readme.io/reference>
- Releases: <https://github.com/grokability/snipe-it/releases>
- Docker Hub: <https://hub.docker.com/r/snipe/snipe-it>
- Community: <https://snipeitapp.com/community>
- Demo: <https://demo.snipeitapp.com>
