---
name: Sylius
description: "Symfony-based open-source eCommerce framework — developer-friendly, BDD-tested, API-first platform for building custom online stores and headless commerce. PHP. MIT."
---

# Sylius

Sylius is an open-source eCommerce framework built on top of Symfony (PHP). It targets developers who need full control over their online store — highly customizable, BDD-tested, with a REST API for headless/composable commerce.

Unlike Magento (monolithic, complex) or WooCommerce (WordPress plugin), Sylius is a Symfony bundle — it integrates naturally into Symfony applications and follows Symfony's patterns. Designed for teams that want to build bespoke eCommerce experiences rather than configure a pre-built platform.

Maintained by Sylius SAS. MIT licensed. A Sylius Plus commercial add-on provides advanced features (B2B, multi-store, loyalty, etc.).

Use cases: (a) custom online stores with complex business logic (b) headless/API-first commerce (c) B2B eCommerce platforms (d) multi-vendor or marketplace platforms (e) agencies building client stores who want extensibility over out-of-the-box features.

Features:

- **Full eCommerce feature set** — products, variants, pricing, inventory, orders, shipments, returns, payments
- **REST API** — full JSON API for headless frontends
- **Flexible pricing** — price lists, promotions, coupons, tiered pricing
- **Multi-currency & multi-language** — i18n built-in
- **Promotions engine** — complex rule-based promotions and discounts
- **Shipping** — multiple shipping methods; calculator system
- **Payment** — Stripe, PayPal, and more via Payum payment gateway library
- **Taxation** — zones, tax rates, per-product tax categories
- **BDD testing** — full Behat + PHPUnit test suite included; test your customizations the same way
- **Symfony integration** — standard Symfony bundle; extend via Symfony's DI, events, and decorators
- **Customizable entities** — extend any entity via Symfony's resource layer
- **Admin panel** — SyliusAdminBundle provides management interface

- Upstream repo: https://github.com/Sylius/Sylius
- Homepage: https://sylius.com/
- Docs: https://docs.sylius.com/
- Demo: https://sylius.com/try/

## Architecture

- **PHP 8.1+** + Symfony 6.x/7.x
- **MySQL / PostgreSQL** — primary database (via Doctrine ORM)
- **Redis** — recommended for sessions, cache, messenger
- **Elasticsearch** — optional; for advanced catalog search
- **Nginx** or Apache web server
- **Messenger component** — async processing for order events, emails
- **Node.js + Webpack** — frontend asset compilation (Webpack Encore)

## Compatible install methods

| Infra         | Runtime                     | Notes                                           |
|---------------|-----------------------------|-------------------------------------------------|
| VPS/Dedicated | LEMP + Composer install     | Standard; PHP 8.1+                              |
| Docker        | Official Docker Compose     | https://docs.sylius.com/getting-started-with-sylius/sylius-ce-installation-with-docker |
| Cloud PaaS    | Platform.sh, Heroku, etc.   | Symfony-compatible PaaS platforms               |

## Inputs to collect

| Input         | Example                       | Phase    | Notes                                               |
|---------------|-------------------------------|----------|-----------------------------------------------------|
| Domain        | `shop.example.com`            | URL      | SSL recommended                                     |
| DB credentials| MySQL host + name + creds     | DB       |                                                     |
| Admin email   | `admin@example.com`           | Install  | First admin account                                 |
| Mailer        | SMTP credentials              | Mail     | For order confirmations, password resets            |
| App secret    | auto-generated                | Config   | Symfony app secret                                  |

## Install (Docker — recommended for getting started)

```sh
git clone https://github.com/Sylius/Sylius-Standard.git my-shop
cd my-shop
cp .env .env.local
# Edit .env.local: set APP_SECRET, DATABASE_URL, etc.

docker compose up -d
docker compose exec php composer install
docker compose exec php bin/console sylius:install
```

See https://docs.sylius.com/getting-started-with-sylius/sylius-ce-installation-with-docker for detailed steps.

## Install (Composer — bare server)

```sh
composer create-project sylius/sylius-standard my-shop
cd my-shop
# Edit .env.local
php bin/console sylius:install  # runs migrations + loads fixtures
php bin/console cache:warmup
yarn install && yarn build  # compile assets
```

## Data & config layout

- **`.env` / `.env.local`** — environment config (DB, mailer, Symfony env)
- **`config/`** — Symfony and Sylius configuration
- **`src/`** — your customizations (entities, controllers, listeners)
- **`public/`** — web root (Nginx/Apache document root)
- **`var/`** — cache, logs
- **MySQL** — all store data (orders, products, customers, etc.)

## Upgrade

1. `composer update sylius/sylius --with-all-dependencies`
2. `php bin/console doctrine:migrations:migrate`
3. `php bin/console cache:clear && php bin/console cache:warmup`
4. `yarn upgrade && yarn build`
5. Test thoroughly — customizations may need updates for new Sylius versions

## Gotchas

- **It's a framework, not a ready-to-go platform** — Sylius requires developer involvement for setup, customization, and maintenance. It's not a "download and configure" CMS. Budget developer hours.
- **BDD-driven development culture** — Sylius ships with Behat scenarios for all features. If you modify Sylius, write Behat tests. This is the expected workflow; skipping tests makes upgrades painful.
- **Symfony knowledge required** — Sylius customization is all standard Symfony: decoration, events, DI. Without Symfony experience, you'll struggle with non-trivial customizations.
- **Asset compilation step** — `yarn install && yarn build` (or `yarn watch` in dev) is required. Missing this after updates = broken frontend.
- **Messenger worker for async tasks** — email notifications, inventory updates, and similar work is processed via Symfony Messenger. Run a queue consumer: `php bin/console messenger:consume`. Without it, emails are queued but never sent.
- **Plugin ecosystem** — Sylius has fewer off-the-shelf plugins than Magento or WooCommerce. Expect to build more custom code.
- **Sylius Plus = commercial** — B2B, multi-store, loyalty, and partial fulfillment require Sylius Plus (paid license). The open-source MIT tier is feature-rich but lacks these.
- **Performance** — Sylius with Redis + PostgreSQL + Varnish/ESI handles significant traffic. Without caching, Symfony/Doctrine adds overhead; ensure OPcache is enabled in PHP.
- **Alternatives:** Magento Open Source (more features out of the box, heavier), WooCommerce (WordPress-based, simpler setup), Bagisto (Laravel-based), Medusa.js (Node.js headless), Aimeos (PHP framework-agnostic).

## Links

- Repo: https://github.com/Sylius/Sylius
- Homepage: https://sylius.com/
- Documentation: https://docs.sylius.com/
- Standard edition (starter project): https://github.com/Sylius/Sylius-Standard
- Docker install guide: https://docs.sylius.com/getting-started-with-sylius/sylius-ce-installation-with-docker
- Demo: https://sylius.com/try/
- Sylius Plus: https://sylius.com/plus/
- Community (Slack): https://sylius.com/slack
