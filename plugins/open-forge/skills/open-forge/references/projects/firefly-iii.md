---
name: Firefly III
description: Self-hosted personal finance manager — double-entry bookkeeping, budgets, recurring transactions, bill tracking, rules engine. PHP/Laravel + MariaDB/MySQL or PostgreSQL.
---

# Firefly III

Firefly III is a PHP/Laravel app for managing personal finances. It tracks accounts (checking, savings, credit, loans), enforces double-entry bookkeeping, and supports budgets, bills, and rule-based transaction categorization. A companion **Data Importer** service ingests CSV/Spectre/Nordigen feeds.

- App repo: <https://github.com/firefly-iii/firefly-iii>
- **Docker repo (use for self-hosting):** <https://github.com/firefly-iii/docker>
- Image: `fireflyiii/core` on Docker Hub
- Data Importer: `fireflyiii/data-importer` (optional)
- Docs: <https://docs.firefly-iii.org/>

## Compatible install methods

| Infra              | Runtime                                | Notes                                                     |
| ------------------ | -------------------------------------- | --------------------------------------------------------- |
| Single VM          | Docker + Compose                       | Recommended; upstream ships `docker-compose.yml`          |
| Kubernetes         | Helm chart (community)                 | Several; not upstream-official                            |
| Bare metal (PHP)   | PHP 8.3 / 8.4 + Composer + nginx       | Fully supported path; see docs                            |
| Managed hosting    | Supported on most AGPL-friendly hosts  | Shared hosting usually won't work (needs CLI + cron)      |

## Inputs to collect

| Input                  | Example                                          | Phase     | Notes                                                                       |
| ---------------------- | ------------------------------------------------ | --------- | --------------------------------------------------------------------------- |
| `APP_KEY`              | 32-char random string                            | Runtime   | **Required & permanent.** `head /dev/urandom \| LC_ALL=C tr -dc 'A-Za-z0-9' \| head -c 32` |
| `APP_URL`              | `https://ff3.example.com`                        | Runtime   | Full origin incl. scheme                                                    |
| `SITE_OWNER`           | `you@example.com`                                | Runtime   | Shown in error pages                                                        |
| `TZ`                   | `Europe/Amsterdam`                               | Runtime   | Used for schedules + cron                                                   |
| `TRUSTED_PROXIES`      | `**`                                             | Runtime   | Set to `**` when behind a reverse proxy                                     |
| `STATIC_CRON_TOKEN`    | **exactly 32 chars** alphanumeric                | Runtime   | Required by the cron sidecar container                                      |
| DB engine              | MariaDB LTS / PostgreSQL 15+                     | Data      | Either works; MariaDB is the compose default                                |
| DB user/password       | `firefly` / strong random                        | Data      | Must match in `.env` and `.db.env`                                          |
| SMTP creds             | any provider                                     | Runtime   | Needed for password reset, notifications                                    |

## Install via Docker Compose

Upstream's canonical compose (at <https://github.com/firefly-iii/docker/blob/main/docker-compose.yml>) pulls three services and expects two env files:

```sh
git clone https://github.com/firefly-iii/docker.git firefly
cd firefly

# App env — start from upstream example:
curl -fsSL https://raw.githubusercontent.com/firefly-iii/firefly-iii/main/.env.example -o .env
# Database env — MariaDB defaults:
cp database.env .db.env
```

Then edit:

- `.env`: set `APP_KEY` (32 chars), `APP_URL`, `SITE_OWNER`, `TZ`, `TRUSTED_PROXIES=**`, `DB_PASSWORD`, `STATIC_CRON_TOKEN` (32-char random).
- `.db.env`: set `MYSQL_PASSWORD` to match `DB_PASSWORD`; set `MYSQL_DATABASE=firefly`, `MYSQL_USER=firefly`.

Pin the image tag in `docker-compose.yml` (upstream default is `fireflyiii/core:latest`). Check releases at <https://github.com/firefly-iii/firefly-iii/releases> and prefer `fireflyiii/core:version-6.1.x` (major-minor-patch pin).

```sh
docker compose up -d
```

Browse `https://ff3.example.com` → register first account → that account gets admin.

### Using PostgreSQL instead

Change the `db` service image to `postgres:16-alpine`, remove the MariaDB env vars from `.db.env`, and uncomment the PostgreSQL env block:

```
POSTGRES_USER=firefly
POSTGRES_DB=firefly
POSTGRES_PASSWORD=secret_firefly_password
```

Set `DB_CONNECTION=pgsql` and `DB_PORT=5432` in `.env`.

### Data Importer (optional)

If you need bank/CSV imports, add the companion service from <https://github.com/firefly-iii/docker/blob/main/docker-compose-importer.yml>. It talks to Firefly III via a Personal Access Token you generate inside Firefly's profile settings.

## Data & config layout

- Volume `firefly_iii_upload` → `/var/www/html/storage/upload` — uploaded attachments (receipts, statements)
- Volume `firefly_iii_db` → `/var/lib/mysql` — MariaDB data dir
- Logs ship to stdout (`LOG_CHANNEL=stack` default)
- No local file config — everything via `.env` / `.db.env`

## Backup

```sh
# App uploads
docker run --rm -v firefly_iii_upload:/data -v "$PWD":/backup alpine \
  tar czf /backup/ff3-upload-$(date +%F).tgz -C /data .

# Database (MariaDB)
docker compose exec -T db mariadb-dump -u firefly -p"$DB_PASSWORD" firefly | gzip > ff3-db-$(date +%F).sql.gz
```

**Back up `.env` too** — `APP_KEY` lives there and is required to decrypt any encrypted data.

## Upgrade

1. Check release notes: <https://github.com/firefly-iii/firefly-iii/releases>. Read migration notes for major versions — occasionally a DB-altering migration requires maintenance-mode downtime.
2. Bump `fireflyiii/core` and `fireflyiii/data-importer` image tags.
3. `docker compose pull && docker compose up -d`.
4. On start, the entrypoint runs migrations + cache rebuilds automatically. Check logs: `docker compose logs -f app`.

## Gotchas

- **`APP_KEY` is permanent.** Once set, do not change it — encrypted fields (API tokens, attachments index) become unreadable. Keep it in your secret store.
- **`STATIC_CRON_TOKEN` is exactly 32 chars alphanumeric.** Shorter or longer = cron hits `/api/v1/cron/$TOKEN` and Firefly rejects it; scheduled tasks silently stop running.
- **Cron is a separate container.** Upstream's compose runs an `alpine` image that does `apk add tzdata` + installs a crontab calling the app's cron endpoint. Don't remove it — budgets, recurring transactions, and bill matching depend on it firing daily.
- **`TRUSTED_PROXIES=**`** is needed behind reverse proxies or Firefly rewrites URLs with `http://` even when the user came in via HTTPS.
- **Database timezone vs `TZ`** can drift. Keep `TZ` in `.env` and the DB container's TZ the same, or recurring transactions bill on the wrong calendar day.
- **Data Importer needs a Personal Access Token**, not your password — generate from Profile → OAuth in the UI.
- **AGPL license.** If you expose Firefly over a network with modifications, you must offer source.
- **No built-in multi-user self-service.** The first registered user is admin; subsequent users are invited through the admin UI and the SMTP mailer has to work.
- **MariaDB `lts` tag** floats across LTS majors — pin (e.g. `mariadb:11.4`) if you care about deterministic upgrades.

## Links

- App repo: <https://github.com/firefly-iii/firefly-iii>
- Docker repo: <https://github.com/firefly-iii/docker>
- Docs: <https://docs.firefly-iii.org/>
- Env var reference: <https://github.com/firefly-iii/firefly-iii/blob/main/.env.example>
- Docker Hub: <https://hub.docker.com/r/fireflyiii/core>
- Releases: <https://github.com/firefly-iii/firefly-iii/releases>
- Data Importer docs: <https://docs.firefly-iii.org/how-to/data-importer/installation/docker/>
