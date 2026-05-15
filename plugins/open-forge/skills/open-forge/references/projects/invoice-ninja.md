---
name: Invoice Ninja
description: "Full-featured invoicing, billing, expense, and time-tracking platform for freelancers and SMBs. Client portal, 40+ payment gateways, recurring invoicing, quotes, projects, subscriptions, vendor bills. Laravel + Flutter apps. Elastic License 2.0 (source-available, NOT OSI-approved)."
---

# Invoice Ninja

Invoice Ninja is the granddaddy of open-source invoicing — a full-featured billing system covering invoices, quotes, recurring subscriptions, expenses, time tracking, projects, tasks, vendor bills, credit notes, and a client portal. Version 5 (current) is a complete rewrite in Laravel + Flutter (mobile/desktop) from the v4 PHP/jQuery codebase.

What Invoice Ninja gets you:

- **Invoicing** — one-time + recurring; auto-reminders; late fees; payment links
- **40+ payment gateways** — Stripe, PayPal, Authorize.net, WePay, Checkout.com, Mollie, GoCardless, Square, BTCPay (crypto), Razorpay, and many more
- **Quotes + proposals** — convert to invoice when accepted
- **Expenses** — categorize, attach receipts, bill back to client
- **Time tracking** — per-project, per-task; billable + non-billable
- **Projects + tasks** — Kanban-style task management tied to invoices
- **Vendor bills + purchase orders**
- **Subscriptions** — recurring billing with Stripe/PayPal subscriptions integration
- **Client portal** — clients see invoices, download PDFs, pay online
- **Multi-company** — manage multiple legal entities from one login
- **Multi-user** — role-based permissions
- **Mobile apps** — iOS, Android (+F-Droid), Windows, macOS, Linux (Snap/Flatpak)
- **REST API** — well-documented; has community SDKs (Go, PHP, others)

**License** (important): Invoice Ninja v5 uses the **Elastic License 2.0** — source-available but **NOT OSI-approved open source**. You can self-host for your own business. You CANNOT resell it as a hosted SaaS. A **$40/year white-label license** removes branding from client-facing parts.

- Upstream repo: <https://github.com/invoiceninja/invoiceninja>
- Self-host landing: <https://www.invoiceninja.org>
- Hosted SaaS: <https://www.invoiceninja.com>
- Docs: <https://invoiceninja.github.io>
- Install guide (self-host): <https://invoiceninja.github.io/en/self-host-installation/>
- API docs: <https://api-docs.invoicing.co>
- Docker Hub: <https://hub.docker.com/r/invoiceninja/invoiceninja>

## Architecture in one minute

- **Laravel 11** (PHP 8.2+) — server
- **Flutter** — mobile + desktop client apps (talk to server via API)
- **React** — web client portal (v5)
- **MySQL 8+ / MariaDB 10.7+ / PostgreSQL** — all variants supported
- **Queue worker** required for PDF generation, email delivery, recurring invoicing
- **Cron** required for scheduled tasks
- **Redis** recommended at scale

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                                   |
| ----------- | ------------------------------------------------ | ----------------------------------------------------------------------- |
| Single VM   | Native LEMP/LAMP                                  | Upstream-recommended                                                       |
| Single VM   | Docker Compose (community images)                    | `invoiceninja/invoiceninja`                                                  |
| Managed     | Cloudron, Softaculous, Elestio, YunoHost              | 1-click                                                                            |
| Managed SaaS | <https://invoiceninja.com>                           | Paid hosted by upstream                                                                 |

## Inputs to collect

| Input                | Example                             | Phase     | Notes                                                              |
| -------------------- | ----------------------------------- | --------- | ------------------------------------------------------------------ |
| `APP_URL`            | `https://invoice.example.com`        | URL       | **PERMANENT** — invoice PDFs + client-portal links bake this in       |
| `APP_KEY`            | `php artisan key:generate` output     | Security  | **LOSING IT = YOU CANNOT DECRYPT DATA.** Upstream explicitly warns.      |
| `DB_*`               | MySQL/MariaDB/Postgres                 | DB        | 8.0+ / 10.7+                                                                |
| Admin user           | created via `/setup` wizard             | Bootstrap | First access on fresh install                                                    |
| Mail driver          | SMTP / Postmark / SES / Mailgun          | Email     | Invoice delivery; **Postmark is upstream-recommended**                                |
| `QUEUE_CONNECTION`   | `database` or `redis`                     | Jobs      | Required — all PDF + email + recurring logic is async                                          |
| Payment gateway creds | Stripe/PayPal keys                       | Payments  | Configure per gateway in UI                                                                         |
| TLS                  | Let's Encrypt                              | Security  | Client portal + payment pages                                                                             |
| White-label license  | $40/year (optional)                         | Branding  | Removes "Powered by Invoice Ninja" branding                                                                       |

## Install via native LEMP (upstream pattern)

```sh
# Prereqs: PHP 8.2+ with ext-bcmath ext-zip ext-gd ext-gmp ext-intl ext-mysql ext-mbstring ext-xml ext-curl ext-xmlwriter; Composer 2; Node.js; Web server; DB

# Clone specific tag (avoid v5-develop in prod)
git clone --depth 1 -b v5.13.22 https://github.com/invoiceninja/invoiceninja.git
cd invoiceninja
cp .env.example .env
# Edit .env: APP_URL, DB_*, MAIL_*, QUEUE_CONNECTION
php artisan key:generate   # generates APP_KEY - BACK UP THE .env NOW

composer i -o --no-dev

# Point web server at /public
# Visit https://invoice.example.com/setup to complete

# Cron (required)
echo '* * * * * cd /var/www/invoiceninja && php artisan schedule:run >/dev/null 2>&1' | crontab -

# Queue worker (required) - run via systemd / supervisor
php artisan queue:work --sleep=3 --tries=3
```

Visit `https://invoice.example.com/setup` → fills in DB creds + creates admin.

## Install via Docker Compose

```yaml
services:
  invoiceninja:
    image: invoiceninja/invoiceninja:5            # pin specific patch tag in prod
    container_name: invoiceninja
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "8080:9000"
    environment:
      APP_URL: https://invoice.example.com
      APP_KEY: base64:<run once: docker exec ... php artisan key:generate --show>
      APP_DEBUG: "false"
      DB_HOST: db
      DB_DATABASE: ninja
      DB_USERNAME: ninja
      DB_PASSWORD: <strong>
      MAIL_MAILER: smtp
      MAIL_HOST: smtp.example.com
      MAIL_PORT: "587"
      MAIL_USERNAME: admin@example.com
      MAIL_PASSWORD: <smtp-pass>
      MAIL_FROM_ADDRESS: invoice@example.com
      MAIL_FROM_NAME: "My Company"
      QUEUE_CONNECTION: database
      REQUIRE_HTTPS: "true"
      TRUSTED_PROXIES: "*"
    volumes:
      - ninja-public:/var/www/app/public
      - ninja-storage:/var/www/app/storage

  nginx:
    image: nginx:stable-alpine
    container_name: ninja-nginx
    restart: unless-stopped
    depends_on: [invoiceninja]
    ports: ["80:80"]
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - ninja-public:/var/www/app/public:ro

  db:
    image: mariadb:11
    container_name: ninja-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: ninja
      MARIADB_USER: ninja
      MARIADB_PASSWORD: <strong>
    volumes:
      - ninja-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

  queue:
    image: invoiceninja/invoiceninja:5
    container_name: ninja-queue
    restart: unless-stopped
    depends_on: [db, invoiceninja]
    command: php artisan queue:work --sleep=3 --tries=3
    environment:
      # SAME env as invoiceninja service
      APP_URL: https://invoice.example.com
      APP_KEY: <SAME AS ABOVE>
      DB_HOST: db
      DB_DATABASE: ninja
      DB_USERNAME: ninja
      DB_PASSWORD: <strong>
      QUEUE_CONNECTION: database

  cron:
    image: invoiceninja/invoiceninja:5
    container_name: ninja-cron
    restart: unless-stopped
    depends_on: [db]
    entrypoint: >
      sh -c "while true; do php /var/www/app/artisan schedule:run; sleep 60; done"
    environment:
      # SAME env as invoiceninja service
      APP_URL: https://invoice.example.com
      APP_KEY: <SAME AS ABOVE>
      DB_HOST: db
      DB_DATABASE: ninja
      DB_USERNAME: ninja
      DB_PASSWORD: <strong>
      QUEUE_CONNECTION: database

volumes:
  ninja-public:
  ninja-storage:
  ninja-db:
```

Four containers: app, nginx (reverse proxy inside stack), DB, queue worker, cron runner.

## First boot

1. Browse `https://invoice.example.com/setup` → wizard
2. Enter DB config (already in env; just click through), SMTP, admin email + password
3. Wizard runs migrations + seeds defaults
4. Log in at `/`
5. Go to Settings → Tax Settings / Company Details / Products / Clients / Payment Gateways
6. Create first invoice → send to a test client → test payment via Stripe test mode

## Data & config layout

- `.env` — secrets (APP_KEY, DB, SMTP, gateway keys)
- `storage/app/` — invoice PDFs, client logos, uploaded receipts
- `storage/framework/` — cache, sessions, views
- `public/` — static assets + uploaded logos
- DB — invoices, clients, line items, payments, projects, tasks, users

## Backup

```sh
# DB (PRIMARY — contains ALL invoices, payments, clients)
mysqldump -uninja -p ninja | gzip > ninja-db-$(date +%F).sql.gz

# Storage
tar czf ninja-storage-$(date +%F).tgz storage/

# .env - BACK UP SEPARATELY
cp .env ninja-env-$(date +%F).bak
```

**Daily DB backup + offsite retention is non-negotiable.** These are financial records.

## Upgrade

1. Releases: <https://github.com/invoiceninja/invoiceninja/releases>. Very active (weekly patches).
2. **Always use tagged versions, not `v5-develop` branch.** Upstream explicitly warns against running develop in prod.
3. Back up DB + storage + .env.
4. Docker: `docker compose pull && docker compose up -d` (all containers).
5. Native: `git fetch --tags && git checkout v5.x.x && composer i -o --no-dev && php artisan migrate --force && php artisan optimize:clear`.
6. **Put app in maintenance mode** for big upgrades: `php artisan down`.

## Gotchas

- **Elastic License 2.0 is NOT OSI-approved.** Self-host for own business = fine. Commercial hosted-SaaS offerings violate the license. Read <https://www.elastic.co/licensing/elastic-license> carefully.
- **Losing `APP_KEY` = data loss.** From upstream: "Your APP_KEY in the .env file is used to encrypt data, if you lose this you will not be able to run the application." Back up alongside DB.
- **Pin to tagged versions** — `v5-develop` branch is work-in-progress and breaks in subtle ways. Use the latest `v5.x.y` release tag.
- **`APP_URL` is baked into invoice PDFs + client-portal links** — changing post-deploy breaks old links. Pick permanently (set up DNS + TLS BEFORE first run).
- **Queue worker + cron are REQUIRED** — without them, emails don't send, recurring invoices don't generate, PDFs fail. Run both as systemd services or separate containers.
- **`TRUSTED_PROXIES: "*"`** is needed behind reverse proxy so Laravel sees the real client IP. Set to your proxy's IP for more security.
- **`REQUIRE_HTTPS=true`** forces HTTPS — enable in production.
- **React-based client portal** (v5) is a separate SPA served alongside the main app. Check the repo's `react-app` directory for the correct URL structure.
- **Email deliverability** — upstream recommends Postmark; it's excellent for transactional. SPF/DKIM/DMARC essential. Invoices in spam = unpaid invoices.
- **Payment gateway testing** — always test in sandbox mode with each gateway before going live. Invoice Ninja's gateway setup can be finicky (multiple accounts, webhooks, etc.).
- **Multi-currency** is built in — exchange rates via ECB feed.
- **Recurring invoices** — set up once, Invoice Ninja auto-generates on schedule + sends (if cron/queue running).
- **Mobile apps** — free tier shows ads/branding; white-label license removes them. Works via API against your self-hosted instance.
- **Subscription module** (new-ish in v5) — integrate with Stripe Subscriptions / PayPal subscription products; useful for SaaS billing.
- **Multi-company**: one install, multiple "companies" (Settings → Companies → add). Each company has separate clients, invoices, branding.
- **Storage growth** — invoice PDFs + email attachments accumulate. Plan disk. Consider S3 via Laravel's filesystem config.
- **Large client lists (>10k)** — tune MySQL, add indexes, consider Redis for sessions/cache.
- **v4 → v5 migration** — available but requires care; v4 is EOL.
- **Security**: 2FA (TOTP) supported; enable for admin accounts. Role-based permissions in paid whitelabel tier are more granular.
- **Alternatives worth knowing:**
  - **Akaunting** — similar feature scope; BSL license; modular App Store (separate recipe)
  - **Firefly III** — personal finance; different audience (not SMB invoicing)
  - **Dolibarr** — broader ERP + invoicing; GPLv3
  - **Odoo CE** — full ERP including invoicing; LGPLv3; heavier
  - **InvoicePlane** — simpler, FOSS, invoice-only
  - **Crater** — newer Laravel-based; MIT; smaller feature set
  - **BTCPay Server** — crypto-focused invoicing + POS (separate recipe)
  - **Zoho Invoice / FreshBooks / Harvest / Wave** — SaaS competitors
  - **QuickBooks / Xero** — enterprise SaaS
  - **Choose Invoice Ninja if:** you want the richest FOSS-ish self-hostable invoicing + project + time-tracking platform.
  - **Choose Akaunting if:** you want accounting-first with invoicing on top.
  - **Choose Crater if:** you want an MIT-licensed simpler alternative.

## Links

- Repo: <https://github.com/invoiceninja/invoiceninja>
- Self-hosted info: <https://www.invoiceninja.org>
- Hosted SaaS: <https://www.invoiceninja.com>
- Installation guide: <https://invoiceninja.github.io/en/self-host-installation/>
- User guide: <https://invoiceninja.github.io/en/user-guide/>
- Developer guide: <https://invoiceninja.github.io/en/developer-guide/>
- API docs: <https://api-docs.invoicing.co/>
- Docker Hub: <https://hub.docker.com/r/invoiceninja/invoiceninja>
- Releases: <https://github.com/invoiceninja/invoiceninja/releases>
- Mobile app (iOS/macOS): <https://apps.apple.com/app/id1503970375>
- Mobile app (Android): <https://play.google.com/store/apps/details?id=com.invoiceninja.app>
- F-Droid: <https://f-droid.org/en/packages/com.invoiceninja.app>
- Desktop Linux (Snap): <https://snapcraft.io/invoiceninja>
- Desktop Linux (Flatpak): <https://flathub.org/apps/com.invoiceninja.InvoiceNinja>
- Forum: <https://forum.invoiceninja.com>
- Slack: <http://slack.invoiceninja.com>
- Discord: <https://discord.gg/ZwEdtfCwXA>
- Elastic License 2.0: <https://www.elastic.co/licensing/elastic-license>
- YouTube channel: <https://www.youtube.com/@appinvoiceninja>
