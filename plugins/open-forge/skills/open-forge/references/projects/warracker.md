---
name: Warracker
description: "Open-source warranty tracker for individuals and teams. Docker. Python/Flask + PostgreSQL + Nginx. sassanix/Warracker. Expiry alerts, document storage, OIDC SSO, Paperless-ngx, claim tracking, 20 languages."
---

# Warracker

**Open-source warranty tracker for individuals and teams.** Centralized management of product warranties with purchase dates, durations, notes, photos, and documents. Expiry alerts (email + 100+ Apprise push services), warranty claims tracking, OIDC SSO, Paperless-ngx integration, CSV import/export, 20 languages, RTL support, tags, archiving, and admin dashboard. Multi-user with role-based permissions.

Built + maintained by **Sassanix** and contributors. MIT license.

- Upstream repo: <https://github.com/sassanix/Warracker>
- Docs: in `Docker/` directory of repo
- Discord: <https://discord.gg/PGxVS3U2Nw>
- GHCR: `ghcr.io/sassanix/warracker/main:1.0.2`

## Architecture in one minute

- **Python + Flask** backend
- **PostgreSQL 15** database
- **Nginx** reverse proxy (in the compose stack)
- Port **8005** (mapped to container port 80 via Nginx)
- File uploads stored in `/data/uploads` volume
- Resource: **low** — Flask + Postgres; typical home/team scale

## Compatible install methods

| Infra             | Runtime                                  | Notes                                                  |
| ----------------- | ---------------------------------------- | ------------------------------------------------------ |
| **Docker Compose**| `ghcr.io/sassanix/warracker/main:1.0.2` | **Primary** — see `Docker/` in repo for env + compose  |

## Inputs to collect

| Input                          | Example                           | Phase    | Notes                                                                                |
| ------------------------------ | --------------------------------- | -------- | ------------------------------------------------------------------------------------ |
| `POSTGRES_USER`                | `warracker`                       | Storage  | DB user (set in `.env`)                                                              |
| `POSTGRES_PASSWORD`            | strong random                     | Storage  | DB password (set in `.env`)                                                          |
| `POSTGRES_DB`                  | `warracker`                       | Storage  | DB name                                                                              |
| `SECRET_KEY`                   | random 32+ chars                  | Auth     | Flask session secret; required                                                       |
| SMTP settings (optional)       | host + port + user + pw           | Notify   | For email expiry alerts                                                              |
| Apprise URL (optional)         | Discord / Slack / etc.            | Notify   | 100+ notification services for expiry alerts                                         |
| OIDC settings (optional)       | Client ID + Secret + issuer       | Auth     | For Google, GitHub, Keycloak, etc. SSO                                               |
| Paperless-ngx URL + token      | internal URL + API token          | Storage  | For document management integration                                                  |
| Domain                         | `warranty.example.com`            | URL      | Reverse proxy + TLS                                                                  |

## Install via Docker Compose

Full compose + `.env` example in the repo's `Docker/` directory:

```yaml
# Abbreviated — see Docker/docker-compose.yml in repo for full version
services:
  warracker:
    image: ghcr.io/sassanix/warracker/main:1.0.2
    ports:
      - "8005:80"
    volumes:
      - warracker_uploads:/data/uploads
    env_file:
      - .env
    depends_on:
      warrackerdb:
        condition: service_healthy
    restart: unless-stopped

  warrackerdb:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    env_file:
      - .env
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
  warracker_uploads:
```

1. Clone repo → copy `Docker/docker-compose.yml` + `Docker/.env.example` → edit `.env`
2. `docker compose up -d`
3. Visit `http://localhost:8005`

## First boot

1. Configure `.env` with Postgres creds + `SECRET_KEY` before starting.
2. `docker compose up -d`.
3. Visit the web UI → **register the first account** — it auto-becomes admin.
4. Set up **notification preferences** (Settings → Notifications): email or Apprise.
5. Configure **expiry alert thresholds** (days before expiry to notify).
6. Add your first warranty: product name + purchase date + duration + optional photo/receipt.
7. Enable **OIDC SSO** if desired (Settings → Authentication).
8. Configure **Paperless-ngx** integration if you use it (Settings → Paperless-ngx).
9. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Warranty tracking | Name, purchase date, duration, expiry date (calculated), notes, serial numbers |
| Photos + documents | Upload product photos, receipts, invoices, manuals |
| Expiry alerts | Email + Apprise 100+ services; configurable days-before threshold |
| Warranty claims | Track claims end-to-end: status, dates, resolution, full history |
| Tags | Custom categorization; filter by tag |
| Archiving | Archive expired/unused warranties; stays accessible |
| Multi-user | Admin + regular users; role-based permissions; global/user-only views |
| OIDC SSO | Google, GitHub, Keycloak, and any OpenID provider |
| CSV import/export | Migrate from spreadsheets; export all data |
| Paperless-ngx | Store + manage warranty documents in Paperless-ngx |
| 20 languages | RTL support; instant language switching; native name display |
| Status dashboard | Visual analytics: charts + tables; global + user views |
| Audit trail | Log of all actions |
| Password reset | Token-based account recovery |
| Responsive UI | Mobile-friendly |

## Backup

```sh
docker compose exec warrackerdb pg_dump -U $POSTGRES_USER $POSTGRES_DB > warracker-$(date +%F).sql
sudo tar czf warracker-uploads-$(date +%F).tgz <warracker_uploads_volume>/
```

Contents: all warranty records + documents + photos + user accounts. PII (product ownership, purchase history, serial numbers). Encrypt backups.

## Upgrade

1. Releases: <https://github.com/sassanix/Warracker/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **First registered user = admin.** Register your own account immediately before opening to others. Or, if deploying for a team, coordinate who registers first.
- **`SECRET_KEY` must be set.** Flask sessions + CSRF rely on it. Don't leave it at the default placeholder.
- **Paperless-ngx integration is document-level control.** You can store, link, and manage warranty documents directly in Paperless-ngx rather than (or in addition to) the local upload volume. Set both the Paperless URL and API token in Settings.
- **OIDC redirect URI.** Register `https://your-domain.com/oidc/callback` (or similar — check current docs) as allowed redirect in your IdP.
- **Apprise for non-email notifications.** Email requires SMTP config; Apprise handles Discord, Slack, Telegram, Pushover, ntfy, etc. Both can be active simultaneously.
- **Multiple serial numbers per product.** Useful for multi-unit purchases (e.g. a 3-pack of hard drives).
- **Warranty claims feature.** Track the full lifecycle of a claim — submission, status updates, resolution. Useful for actually using the warranty when something breaks.
- **`warracker_uploads` volume holds all photos + documents.** Back it up alongside the DB.
- **Audit trail** — all admin actions logged; useful for team deployments to see who changed what.

## Project health

Active Python/Flask development, Discord community, OIDC, Paperless-ngx integration, 20 languages, multi-user, GHCR CI. Multi-contributor. MIT license. Active roadmap.

## Warranty-tracker-family comparison

- **Warracker** — Flask + Postgres, Docker, full-featured (claims/OIDC/Paperless/20 languages/Apprise), multi-user
- **Wallos** — PHP, subscription tracking (not warranty/product-focused)
- **Home inventory apps** (Grocy, HomeBox) — broader inventory management including warranty dates
- **Google Sheets / spreadsheet** — zero-setup but no alerts or document storage

**Choose Warracker if:** you want a dedicated, self-hosted warranty tracker with expiry alerts, document storage, claim tracking, and multi-user support for a household or small team.

## Links

- Repo: <https://github.com/sassanix/Warracker>
- Docker compose: <https://github.com/sassanix/Warracker/tree/main/Docker>
- Discord: <https://discord.gg/PGxVS3U2Nw>
