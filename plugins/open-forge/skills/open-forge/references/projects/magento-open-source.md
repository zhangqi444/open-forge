---
name: Magento Open Source
description: "Full-featured open-source eCommerce platform by Adobe — build online stores with product catalog, checkout, payment integrations, and order management. PHP. OSL-3.0."
---

# Magento Open Source

Magento Open Source (formerly Magento Community Edition) is Adobe's open-source eCommerce platform — a full-stack PHP application for building and running online stores. It handles product catalog management, customer accounts, checkout, payment processing, order management, and multi-store configurations.

Adobe acquired Magento in 2018. The open-source tier (OSL-3.0) covers the core storefront and admin. The paid **Adobe Commerce** tier adds B2B features, AI-powered merchandising, and managed cloud hosting.

- Upstream repo: https://github.com/magento/magento2
- Homepage: https://magento.com/products/magento-open-source
- Docs: https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/overview.html
- Developer docs: https://developer.adobe.com/commerce/docs/

## Architecture

- **PHP 8.1–8.3**
- **MySQL 8.0 / MariaDB 10.6**
- **Elasticsearch 7.x / OpenSearch 2.x** — required for catalog search
- **Redis** — recommended for session + full-page cache
- **RabbitMQ** — recommended for async message queue
- **Nginx** (recommended) or Apache
- **Resource**: 4+ GB RAM minimum, 8+ GB recommended for production

## Compatible install methods

| Infra         | Runtime                                    | Notes                                   |
|---------------|--------------------------------------------|-----------------------------------------|
| VPS/Dedicated | LEMP + Composer install                    | Standard production path                |
| Docker        | Warden (warden.dev) or cloud-docker image  | Warden is community-standard dev env    |
| Bare-metal    | Composer install                           | Fine for high-traffic with proper tuning|

## Inputs to collect

| Input           | Example                       | Phase    | Notes                                               |
|-----------------|-------------------------------|----------|-----------------------------------------------------|
| Domain          | `shop.example.com`            | URL      | SSL required                                        |
| DB credentials  | MySQL 8.0 host + creds        | DB       | Large schema; 200+ tables                           |
| Elasticsearch   | `localhost:9200`              | Search   | Required; catalog search won't work without it      |
| Redis           | `localhost:6379`              | Cache    | Separate DBs for session vs FPC vs default cache    |
| Admin URI       | `/admin_xyz`                  | Security | Don't use `/admin` — bots target it                |
| Composer auth   | repo.magento.com credentials  | Install  | Free account at account.magento.com                 |

## Install (Composer)

```sh
composer create-project --repository-url=https://repo.magento.com/ \
  magento/project-community-edition=2.4.x /var/www/magento

cd /var/www/magento
bin/magento setup:install \
  --base-url=https://shop.example.com/ \
  --db-host=localhost --db-name=magento2 \
  --db-user=magento --db-password=secret \
  --admin-email=admin@example.com \
  --admin-user=admin --admin-password=Admin1234! \
  --language=en_US --currency=USD \
  --use-rewrites=1 \
  --search-engine=elasticsearch7 \
  --elasticsearch-host=localhost --elasticsearch-port=9200 \
  --backend-frontname=admin_secret

bin/magento setup:static-content:deploy -f
bin/magento indexer:reindex
bin/magento cache:flush
bin/magento cron:install
```

See https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/composer.html for authoritative steps.

## Data & config layout

- **`app/etc/env.php`** — DB creds, cache config, encryption key
- **`app/etc/config.php`** — scoped config (track in VCS)
- **`var/`** — cache, log, session, generated code
- **`pub/media/`** — product images, uploaded files
- **`pub/static/`** — compiled static assets (regenerated; don't backup)

## Upgrade

1. `bin/magento maintenance:enable`
2. Back up DB + `app/etc/env.php`
3. `composer require magento/product-community-edition=<new-version> --no-update`
4. `composer update`
5. `bin/magento setup:upgrade`
6. `bin/magento setup:static-content:deploy -f`
7. `bin/magento indexer:reindex`
8. `bin/magento maintenance:disable`

## Gotchas

- **Performance requires Redis + Elasticsearch** — Magento on flat files/DB cache is painfully slow at scale. Both are non-optional in production.
- **Cron is critical** — reindexing, email sending, order processing all depend on cron. `bin/magento cron:install` is mandatory. Missing cron = catalog goes stale, emails don't send.
- **Static content deployment** — after every code or theme change: `bin/magento setup:static-content:deploy`. Forgetting this = broken CSS/JS.
- **Admin URL security** — default `/admin` path is constantly brute-forced. Set a custom backend frontname at install time.
- **Hyva theme** — the community-built Hyva theme (hyva.io) is a modern Tailwind/Alpine.js replacement for the bloated Luma theme. Paid license (~€1,000/project) but strongly recommended for new stores.
- **Composer auth required** — free Adobe account → generate auth keys at `account.magento.com` → add to `~/.composer/auth.json`.
- **Resource requirements are real** — budget 4–8 GB RAM minimum. A $5 VPS will not run Magento.
- **B2B features require Adobe Commerce** — company accounts, shared catalogs, purchase orders are paid-tier only.
- **License nuance** — OSL-3.0 requires open-sourcing modifications if you *distribute* the software. Self-hosters running their own store are generally unaffected.
- **Alternatives:** WooCommerce (simpler, WordPress-based), PrestaShop (lighter PHP), Sylius (Symfony, API-first), Medusa.js (Node.js headless), Bagisto (Laravel-based).

## Links

- Repo: https://github.com/magento/magento2
- Homepage: https://magento.com/products/magento-open-source
- Installation guide: https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/overview.html
- Upgrade guide: https://experienceleague.adobe.com/docs/commerce-operations/upgrade-guide/overview.html
- Developer docs: https://developer.adobe.com/commerce/docs/
- System requirements: https://experienceleague.adobe.com/docs/commerce-operations/installation-guide/system-requirements.html
- Warden dev environment: https://warden.dev
- Hyva theme: https://www.hyva.io
