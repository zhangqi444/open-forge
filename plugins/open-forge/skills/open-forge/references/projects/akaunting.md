---
name: Akaunting
description: Self-hosted accounting software for small businesses and freelancers. Invoicing, expense tracking, bank reconciliation, multi-currency, multi-user, tax/VAT, financial reports, modular App Store (some apps paid). Laravel + VueJS + Tailwind. BSL (Business Source License) — NOT OSI-approved.
---

# Akaunting

Akaunting is online accounting software built for small businesses and freelancers who need more than a spreadsheet but don't want QuickBooks' complexity/cost. It covers the essentials — invoicing, expenses, bank reconciliation, tax, reports — with a modular App Store for extensions.

Feature scope (core, free):

- **Invoicing + recurring invoices** — send, track, remind, payment link
- **Expenses + bills** — vendor bills, purchase categories
- **Bank reconciliation** — CSV import; automated imports via paid apps
- **Double-entry accounting** — proper chart of accounts + journal entries
- **Multi-currency** — auto exchange rates via paid app
- **Multi-company** — manage multiple legal entities from one login
- **Multi-user** — roles + permissions
- **Client portal** — customers can see/pay invoices online
- **Reports** — P&L, balance sheet, cash flow, tax summary
- **RESTful API** — for integrations
- **App Store** — extensions for payroll, inventory, project accounting, double-entry upgrade, import/export formats; many are paid

**License caveat (critical)**: Akaunting uses the **BSL (Business Source License)**. This is NOT OSI-approved open source. The BSL typically allows self-hosting for your own business but restricts commercial hosting of Akaunting as a service. Read the LICENSE file in the repo before commercial deployment.

- Upstream repo: <https://github.com/akaunting/akaunting>
- Website: <https://akaunting.com>
- Docs: <https://akaunting.com/hc/docs>
- Forum: <https://akaunting.com/forum>
- Developer portal: <https://developer.akaunting.com>
- App Store: <https://akaunting.com/apps>

## Architecture in one minute

- **Laravel 11** (PHP 8.1+) + **Vue.js 3** + **Tailwind**
- **Database**: MariaDB / MySQL / PostgreSQL / SQLite (MariaDB most common)
- **Module system** — "Apps" are Laravel packages installed via the App Store (or manually via composer)
- **Queue worker** recommended for background tasks (email, imports, report generation)
- **Cron** needed for scheduled tasks (recurring invoices, reminders, automatic imports)

Standard LAMP/LEMP deployment — nothing exotic.

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                            |
| ----------- | ---------------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | Native LEMP/LAMP                                      | **Most common**                                                    |
| Single VM   | Docker Compose (community images)                      | `docker.io/akaunting/akaunting` + MariaDB                              |
| Managed     | YunoHost / Cloudron / Softaculous                       | One-click deploys for easy hosting                                       |
| Managed SaaS | <https://akaunting.com>                                 | Paid hosted by upstream                                                     |

## Inputs to collect

| Input                | Example                              | Phase     | Notes                                                          |
| -------------------- | ------------------------------------ | --------- | -------------------------------------------------------------- |
| `APP_URL`            | `https://books.example.com`          | URL       | Used in invoice links + emails                                    |
| `APP_KEY`            | `php artisan key:generate` output      | Security  | Encrypts DB fields; losing = data loss                                |
| `DB_*`               | MariaDB creds                          | DB        | MariaDB 10.3+ / MySQL 5.7+ / PostgreSQL / SQLite                         |
| `ADMIN_EMAIL` / `PW` | `admin@example.com` + strong            | Bootstrap | Created via `php artisan install`                                            |
| SMTP                 | host + port + creds                     | Email     | Required for invoice emails + reminders                                         |
| TLS                  | Let's Encrypt                           | Security  | Required for client portal payments                                                  |
| `QUEUE_CONNECTION`   | `database` or `redis`                    | Jobs      | Email send, reports, imports                                                               |
| `SESSION_DRIVER`     | `file` / `database` / `redis`             | Sessions  | Redis is recommended for multi-worker deploys                                                       |

## Install via native LEMP

```sh
# Prereqs: PHP 8.1+ with ext-bcmath ext-mbstring ext-gd ext-zip ext-xml ext-curl ext-intl ext-mysql (or pgsql), Composer 2+, Node 18+, MariaDB 10.6+

# Create DB
mysql -uroot -p -e "CREATE DATABASE akaunting; CREATE USER 'akaunting'@'localhost' IDENTIFIED BY '<strong>'; GRANT ALL ON akaunting.* TO 'akaunting'@'localhost'; FLUSH PRIVILEGES;"

# Clone + install
cd /var/www
git clone -b master https://github.com/akaunting/akaunting.git
cd akaunting
composer install --no-dev --optimize-autoloader
npm install
npm run dev       # dev builds assets; for prod, `npm run production`

# Install via CLI (creates admin + runs migrations)
php artisan install \
  --db-host=localhost \
  --db-port=3306 \
  --db-name=akaunting \
  --db-username=akaunting \
  --db-password=<strong> \
  --admin-email=admin@example.com \
  --admin-password=<strong-admin>

# Optional: load demo data
php artisan sample-data:seed

# Cache config for prod
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Point nginx/Apache at `/var/www/akaunting/public`.

**Cron** (required for recurring invoices, reminders):

```
* * * * * cd /var/www/akaunting && php artisan schedule:run >> /dev/null 2>&1
```

**Queue worker** (for background jobs):

```
# systemd unit running:
php /var/www/akaunting/artisan queue:work --sleep=3 --tries=3
```

## Install via Docker Compose (community)

```yaml
services:
  akaunting:
    image: akaunting/akaunting:latest   # pin specific version in prod
    container_name: akaunting
    restart: unless-stopped
    depends_on:
      mariadb: { condition: service_healthy }
    ports:
      - "8080:80"
    environment:
      AKAUNTING_SETUP: "true"
      DB_HOST: mariadb
      DB_PORT: "3306"
      DB_NAME: akaunting
      DB_USERNAME: akaunting
      DB_PASSWORD: <strong>
      COMPANY_NAME: "My Company"
      COMPANY_EMAIL: admin@example.com
      ADMIN_EMAIL: admin@example.com
      ADMIN_PASSWORD: <strong-admin>
      APP_URL: https://books.example.com
      LOCALE: en-US
    volumes:
      - akaunting-data:/var/www/html

  mariadb:
    image: mariadb:11
    container_name: akaunting-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: akaunting
      MARIADB_USER: akaunting
      MARIADB_PASSWORD: <strong>
    volumes:
      - akaunting-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

volumes:
  akaunting-data:
  akaunting-db:
```

First visit: browse `http://<host>:8080` → wizard detects already-installed state, redirects to login. Log in with `ADMIN_EMAIL` / `ADMIN_PASSWORD`.

## First boot

1. Complete company setup wizard (currency, tax, fiscal year)
2. Create chart of accounts (defaults are provided per locale)
3. Add customers + suppliers
4. Configure payment gateways (Stripe/PayPal) via App Store
5. Create first invoice → send → test payment flow
6. Set up recurring invoices if applicable

## Data & config layout

- `.env` — config + secrets
- `storage/app/` — uploaded files (invoice attachments, logos, imports)
- `storage/logs/` — Laravel logs
- `modules/` — installed App Store modules
- MariaDB — all business data

## Backup

```sh
# DB (MOST CRITICAL — financial records!)
mysqldump -u akaunting -p akaunting | gzip > akaunting-db-$(date +%F).sql.gz

# Files (invoice PDFs, uploaded receipts)
tar czf akaunting-storage-$(date +%F).tgz storage/app

# .env
cp .env akaunting-env-$(date +%F).bak

# Installed modules
tar czf akaunting-modules-$(date +%F).tgz modules/
```

**Daily backup + offsite retention is non-negotiable** for accounting data. Lost accounting = tax-return nightmares.

## Upgrade

1. Releases: <https://github.com/akaunting/akaunting/releases>. Moderate cadence.
2. **Back up DB + storage + .env BEFORE upgrading** — seriously.
3. Docker: `docker compose pull && docker compose up -d`.
4. Native: stop web/queue → `git pull` (or re-extract release zip) → `composer install --no-dev --optimize-autoloader` → `npm run production` → `php artisan migrate --force` → `php artisan optimize:clear` → restart.
5. **Major version jumps** often require module updates (e.g., App Store apps may need paid-upgrades to the new major).

## Gotchas

- **License: BSL (Business Source License)**. This is **NOT OSI-approved open source**. Self-hosting for your own bookkeeping = fine. Offering "Akaunting-as-a-service" to others = violation. Read `LICENSE.txt` carefully. After the BSL "change date" (typically 4 years per release), older versions typically convert to Apache/MIT.
- **Accounting data = tax + legal records.** Back up daily; retain years (tax authorities may require 3-10 years depending on jurisdiction). One lost database can bankrupt a business.
- **`APP_KEY` encrypts sensitive DB fields** — losing it = permanent data loss. Part of secrets vault.
- **Cron is required** for recurring invoices + payment reminders. Missing cron = silent feature failure.
- **Queue worker** is required for email delivery + PDF generation to be reliable. Without it, emails send synchronously (slow + UI locks).
- **Many App Store apps are paid** — "Bank Feeds," "Fixed Assets," "Multi-Currency," "Double-Entry," "Estimates & Quotes," etc. The free core handles basics; many accounting features you'd expect are upsells. Review pricing at <https://akaunting.com/apps> before committing.
- **"Double Entry" app is paid** — Akaunting's core is technically cash-basis by default; the full double-entry module costs money. Depending on your accountant's needs, budget for it.
- **Multi-currency** — the core has basic currency codes; full multi-currency with auto-rates + gain/loss tracking is a paid app.
- **Client portal URL** is `APP_URL/portal` — must be HTTPS if accepting payments.
- **SMTP deliverability**: configure SPF/DKIM/DMARC for your domain. Invoices spam-binned = delayed payments.
- **Storage** — invoice PDFs + receipt uploads can accumulate. Plan disk. Consider S3 via filesystem config.
- **Installation prompts**: `php artisan install` creates admin + runs migrations. Don't run twice on the same DB; clean DB first.
- **Locale + translations** via Crowdin; 40+ languages supported. Currency/date formats follow locale.
- **Performance**: at scale (1000s of invoices/month), tune MariaDB, use Redis for queue/sessions/cache, add indexes as needed.
- **Security**: keep PHP updated; limit admin access; enable 2FA (via app).
- **Chart of accounts** is locale-specific — the wizard seeds defaults; customize to match your accountant's preferences.
- **Integration with banks** requires paid app + a supported feed provider (Plaid, TrueLayer, etc.) — not available in all countries.
- **Alternatives worth knowing:**
  - **InvoicePlane** — simpler, FOSS, invoice-only
  - **Invoice Ninja** — fuller featured; source-available Elastic License (separate recipe)
  - **Firefly III** — personal finance focus; FOSS
  - **Dolibarr** — broader ERP/CRM/accounting; FOSS (GPLv3)
  - **ERPNext / Frappe** — broader ERP; GPL
  - **Odoo CE** — huge ERP suite; LGPLv3
  - **QuickBooks / Xero / Sage** — commercial SaaS; the benchmark
  - **FreshBooks** — freelancer-focused SaaS
  - **hledger / ledger-cli** — CLI plain-text accounting; FOSS
  - **Choose Akaunting if:** you want a user-friendly accounting web app + OK with BSL + happy to pay for advanced modules.
  - **Choose Firefly III if:** you want personal finance tracking, not small-business accounting.
  - **Choose Invoice Ninja if:** you primarily need invoicing + time tracking + expense reports.
  - **Choose Dolibarr if:** you want a broader CRM/ERP/accounting combo in one tool (GPL).

## Links

- Repo: <https://github.com/akaunting/akaunting>
- Website: <https://akaunting.com>
- Docs: <https://akaunting.com/hc/docs>
- On-premise requirements: <https://akaunting.com/hc/docs/on-premise/requirements/>
- Forum: <https://akaunting.com/forum>
- App Store: <https://akaunting.com/apps>
- Developer portal: <https://developer.akaunting.com>
- Security policy: <https://github.com/akaunting/akaunting/security/policy>
- Translations: <https://crowdin.com/project/akaunting>
- Releases: <https://github.com/akaunting/akaunting/releases>
- Hosted SaaS: <https://akaunting.com>
- Cloudron package: <https://www.cloudron.io/store/com.akaunting.cloudronapp.html>
