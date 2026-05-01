---
name: Rachoon
description: "Self-hosted invoicing platform for freelancers and small businesses. Docker. Nuxt.js + AdonisJS + PostgreSQL + Gotenberg. ad-on-is/rachoon. Invoices, offers/quotes, client management, payment tracking, custom nunjucks templates, PDF export, multi-currency, tax support. MIT."
---

# Rachoon

**Self-hosted invoicing for freelancers and small businesses.** Create and manage invoices and quotations, track client payments, export professional PDFs via Gotenberg, and customise document templates with nunjucks. Multi-currency and tax support. Clean dashboard with revenue and payment status overview.

Built + maintained by **ad-on-is** (Adi). Name from _račun_ (Bosnian for "invoice") + raccoon. MIT license.

- Upstream repo: <https://github.com/ad-on-is/rachoon>
- Docker: `ghcr.io/ad-on-is/rachoon`

## Architecture in one minute

- **AdonisJS** backend (Node.js)
- **Nuxt.js** frontend
- **PostgreSQL** — all data
- **Gotenberg** — PDF generation (Chrome-based rendering)
- Port **8080**
- Resource: **low-medium** — Node.js + Postgres + Gotenberg (headless Chrome, ~200 MB RAM)

## Compatible install methods

| Infra      | Runtime                      | Notes                                             |
| ---------- | ---------------------------- | ------------------------------------------------- |
| **Docker** | `ghcr.io/ad-on-is/rachoon`   | **Primary** — three containers (app + DB + PDF)   |

## Install via Docker

```yaml
services:
  rachoon:
    image: ghcr.io/ad-on-is/rachoon
    container_name: rachoon
    restart: unless-stopped
    environment:
      - APP_KEY=changethisto32charminimumkey123  # min 32 chars; used to encrypt/sign sensitive data
      - DB_CONNECTION=pg
      - GOTENBERG_URL=http://gotenberg:3000
      - PG_HOST=postgres16
      - PG_PORT=5432
      - PG_USER=rachoon
      - PG_PASSWORD=changeme
      - PG_DB_NAME=rachoon
    ports:
      - "8080:8080"
    depends_on:
      - postgres16
      - gotenberg

  gotenberg:
    image: gotenberg/gotenberg:8
    restart: unless-stopped

  postgres16:
    container_name: postgres16
    image: postgres:16
    restart: unless-stopped
    environment:
      - POSTGRES_USER=rachoon
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=postgres
    volumes:
      - ./rachoon-data:/var/lib/postgresql/data
      - ./docker/init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
```

> The Postgres init script (`docker/init-db.sh`) creates the `rachoon` database. Fetch it from the repo or create it manually.

```bash
docker compose up -d
```

Visit `http://localhost:8080`.

## Environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `APP_KEY` | ✅ | Random string, minimum 32 characters — used to encrypt and sign sensitive data |
| `DB_CONNECTION` | ✅ | `pg` for PostgreSQL |
| `GOTENBERG_URL` | ✅ | URL of the Gotenberg service for PDF generation |
| `PG_HOST` | ✅ | PostgreSQL container hostname |
| `PG_PORT` | ✅ | PostgreSQL port (default: 5432) |
| `PG_USER` | ✅ | PostgreSQL user |
| `PG_PASSWORD` | ✅ | PostgreSQL password |
| `PG_DB_NAME` | ✅ | Database name (`rachoon`) |

## Features overview

| Feature | Details |
|---------|---------|
| Invoices | Create, edit, and manage invoices |
| Offers / Quotations | Create and send offers/quotes to clients |
| Client management | Store and search client information |
| Payment tracking | Log payment status; view balances and overdue invoices |
| PDF export | Professional PDF generation via Gotenberg (headless Chrome) |
| Custom templates | Nunjucks-based customisable invoice/offer templates |
| Multi-currency | Bill in any currency |
| Tax support | Flexible tax settings per invoice/line item |
| Dashboard | Revenue overview, pending payments, client stats |
| Branding | Custom logo and branding on documents |

## Gotchas

- **`APP_KEY` must be at least 32 characters.** AdonisJS uses this for encryption and signing. Use a long random string — `openssl rand -base64 32` works.
- **Gotenberg is required for PDF export.** Gotenberg runs a headless Chrome instance for PDF rendering. It uses ~200 MB RAM at idle and more during rendering — plan accordingly.
- **Init script needed for database creation.** The compose example mounts `docker/init-db.sh` to create the `rachoon` database. Fetch this script from the repo at `docker/init-db.sh`, or manually create the database after Postgres starts.
- **MIT license.** Free to use, modify, redistribute.

## Database init script

If you don't have the init script, create `docker/init-db.sh`:

```bash
#!/bin/bash
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  CREATE DATABASE rachoon;
  GRANT ALL PRIVILEGES ON DATABASE rachoon TO $POSTGRES_USER;
EOSQL
```

## Backup

```sh
docker compose exec postgres16 pg_dump -U rachoon rachoon > rachoon-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Nuxt.js/AdonisJS development, MIT license, Gotenberg PDF generation.

## Invoicing-family comparison

- **Rachoon** — Nuxt.js/AdonisJS/Postgres, invoices + quotes, nunjucks templates, Gotenberg PDF, MIT
- **Invoice Ninja** — PHP/Laravel, full-featured invoicing + CRM + payments, free/paid; Apache-2.0
- **Crater** — Vue.js/Laravel, invoices + expenses + estimates + payments; AGPL-3.0
- **SolidInvoice** — PHP/Symfony, invoices + quotes + payments; MIT

**Choose Rachoon if:** you want a clean, self-hosted invoicing app with nunjucks-based PDF templates and a modern Nuxt.js/AdonisJS stack — lighter than Invoice Ninja, built for freelancers and small businesses.

## Links

- Repo: <https://github.com/ad-on-is/rachoon>
- Docker: `ghcr.io/ad-on-is/rachoon`
