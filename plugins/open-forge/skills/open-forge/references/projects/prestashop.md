---
name: PrestaShop
description: "Open-source e-commerce platform used by hundreds of thousands of merchants. Full storefront + back-office for catalog, orders, customers, taxes, shipping, payments; theming + module (extension) marketplace. PHP/Symfony + MySQL/MariaDB. OSL-3.0 (core) + AFL-3.0 (modules/themes)."
---

# PrestaShop

PrestaShop is a mature open-source **e-commerce platform** — a full shop-in-a-box (storefront + back-office + payment gateway + tax/VAT handling + shipping + CRM + inventory). It powers **hundreds of thousands of merchants worldwide**, particularly in Europe/Latin America. Its commercial module + theme marketplace (<https://addons.prestashop.com>) is one of the largest in OSS e-commerce.

Core features:

- **Catalog** — products, categories, attributes, combinations, variants, virtual/downloadable
- **Orders + CRM** — order flow, invoicing, returns, customer messaging
- **Checkout + payments** — PayPal, Stripe, Adyen, local payment methods (via modules)
- **Taxes + VAT** — EU-ready; multi-country tax rules
- **Shipping** — carriers + rules + zones
- **Multi-store** from single install (multi-shop)
- **Multi-currency + multi-language**
- **Themes** — storefront theming system
- **Modules** — PHP plugins for payments, marketing, analytics, ERP sync
- **B2B features** — quotes, custom prices per customer
- **SEO** — friendly URLs, meta, sitemap, hreflang
- **GDPR** — plugin bundled + consent management
- **REST Webservice API** — XML/JSON

- Upstream repo: <https://github.com/PrestaShop/PrestaShop>
- Website: <https://www.prestashop.com>
- Docs: <https://docs.prestashop-project.org>
- Addons marketplace: <https://addons.prestashop.com>
- Dev docs: <https://devdocs.prestashop-project.org>

## Architecture in one minute

- **PHP 7.2–8.x** (version requirements by release; 8.1+ for 8.x branch)
- **Symfony** (progressively more Symfonyized each release)
- **MySQL 5.6+ / MariaDB 10.x+** — no Postgres support
- **Smarty + Twig** templating
- **Required PHP extensions**: curl, gd, intl, mbstring, mysqli, openssl, pdo_mysql, zip, opcache, fileinfo, soap
- **Composer** for dependency management (devs)
- **Node/npm** for dev tooling (building themes + admin assets)
- Standard LAMP/LEMP deploy

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                            |
| ----------- | ------------------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | Native LAMP/LEMP                                          | **Most common** — standard PHP hosting                               |
| Single VM   | Docker (`prestashop/prestashop:X.Y.Z-fpm`)                   | Official image                                                           |
| Shared host | cPanel 1-click (common)                                      | Many hosts offer it                                                          |
| Kubernetes  | PHP-FPM + nginx + MySQL                                          | Works; non-trivial                                                                 |
| Managed     | PrestaShop Hosted / partner hosts                                    | Commercial option                                                                        |

## Inputs to collect

| Input               | Example                          | Phase     | Notes                                                           |
| ------------------- | -------------------------------- | --------- | --------------------------------------------------------------- |
| Domain              | `shop.example.com`                 | URL       | Used in install wizard                                              |
| DB                  | MySQL/MariaDB creds + name          | DB        | MySQL 5.6+                                                                   |
| Admin user          | set via install wizard                | Bootstrap | Username for back-office; rename admin folder after install (see below)                |
| Payment gateways    | Stripe, PayPal, bank transfer, etc.     | Payments  | Install relevant modules                                                                         |
| Tax config          | Country-specific rules                    | Locale    | EU: VAT rules + MOSS/OSS                                                                              |
| TLS                 | Let's Encrypt                              | Security  | **Mandatory** for PCI-DSS on checkout                                                                          |
| Email / SMTP        | host + port + creds                         | Email     | Order confirmations; bounce handling matters                                                                          |

## Install via Docker Compose

```yaml
services:
  prestashop:
    image: prestashop/prestashop:9.1.1-apache   # pin; check Docker Hub
    container_name: prestashop
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "8080:80"
    environment:
      DB_SERVER: db
      DB_NAME: prestashop
      DB_USER: prestashop
      DB_PASSWD: <strong>
      DB_PREFIX: ps_
      PS_DOMAIN: shop.example.com
      PS_ENABLE_SSL: "1"
      PS_INSTALL_AUTO: "1"              # run install during first-boot
      PS_DEV_MODE: "0"
      ADMIN_MAIL: admin@example.com
      ADMIN_PASSWD: <strong>
    volumes:
      - ./prestashop:/var/www/html

  db:
    image: mariadb:10.11
    container_name: prestashop-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: prestashop
      MARIADB_USER: prestashop
      MARIADB_PASSWORD: <strong>
    volumes:
      - prestashop-db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s

volumes:
  prestashop-db:
```

Browse `http://<host>:8080` → wizard walks you through (if `PS_INSTALL_AUTO=0`).

## Install natively (LEMP)

```sh
# Prereqs: PHP 8.1 with required extensions; MySQL; nginx/Apache
cd /var/www
wget https://www.prestashop.com/download/old/prestashop_X.Y.Z.zip
unzip prestashop_X.Y.Z.zip -d prestashop
cd prestashop && unzip prestashop.zip
chown -R www-data:www-data /var/www/prestashop
# Browse https://shop.example.com/install — wizard configures DB + admin
# AFTER install: delete install/ dir; RENAME admin/ dir to something random
```

## Post-install hardening (critical!)

1. **Delete `install/` directory** — wizard reminds you; don't skip
2. **Rename `admin/` directory** to something random (`admin-abc123/`) — the wizard does this too; write down the new name
3. **Change file permissions**: `config/defines.inc.php`, `classes/*`, `controllers/*` should be read-only for web user
4. **Enable HTTPS** in Back-office → Shop Parameters → General → Enable SSL everywhere
5. **Back-office 2FA**: install a 2FA module (Google Authenticator, Email 2FA)
6. **Force strong passwords** — customer + employee password policies
7. **Update** to latest patch version

## First boot

1. Browse back-office → change default language + currency
2. Shop Parameters → set shop name, logo, contact
3. Catalog → create categories + first product
4. Modules → install payment module (PayPal, Stripe, ...)
5. International → set country, taxes, zones, shipping carriers
6. Design → choose theme (default "Classic" works fine)
7. Advanced Parameters → performance → enable CCC (Combine/Compress/Cache) for production
8. Generate sitemap (SEO module)

## Data & config layout

- `app/config/parameters.php` — DB creds, secret keys, env flags
- `img/` — product images, category images, supplier/manufacturer images
- `themes/<theme>/` — theme assets
- `modules/<module>/` — installed modules
- `upload/` — customer-uploaded files (customizable products)
- `download/` — downloadable products
- `var/cache/` — Symfony + Smarty cache (safe to flush)
- `var/logs/` — logs
- DB — everything transactional (products, orders, customers, configurations)

## Backup

```sh
# DB (CRITICAL — orders, customers, products)
mysqldump -uprestashop -p --single-transaction prestashop | gzip > ps-db-$(date +%F).sql.gz

# Images + uploads
tar czf ps-files-$(date +%F).tgz img/ upload/ download/ modules/ themes/

# Config
cp app/config/parameters.php ps-config-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/PrestaShop/PrestaShop/releases>. Active.
2. **ALWAYS back up DB, files, config first.** PrestaShop upgrades have historically been risky.
3. **Use the 1-Click Upgrade module** (available in Back-office → Advanced Parameters). Auto-downloads + applies. Test on staging first.
4. Manual: extract new release, preserve `app/config/parameters.php`, `img/`, `modules/`, `themes/`, `upload/`, `download/`; overwrite rest; run migrations via `/install/upgrade/upgrade.php`.
5. **Major version bumps** (7.x → 8.x) often break paid modules/themes — budget for module updates or replacements.
6. **PHP version compatibility** — each PrestaShop version supports specific PHP versions; check compatibility matrix before upgrading host PHP.

## Gotchas

- **Paid modules are the norm** — the marketplace is full of $50-300 modules for features that Shopify includes. Budget accordingly. Many essential integrations (advanced search, specific payment gateways, shipping carriers) are paid.
- **Breaking changes between major versions hurt paid modules/themes** — a 7→8 upgrade may require buying new versions of all your modules + theme. This is a significant cost.
- **PHP version treadmill** — PrestaShop follows PHP LTS windows; if you're on PHP 7.4 and PrestaShop stops supporting it, you must upgrade host PHP + PrestaShop + modules together.
- **Module quality varies wildly** — well-rated paid modules are usually solid; unrated modules can introduce SQL injection, XSS, or simply break. Vet carefully. Community free modules on GitHub are hit-or-miss.
- **Admin folder naming** — the install wizard renames `admin/` to something random. **Write it down** — there's no "forgot your admin URL" flow without DB access.
- **Post-install security**: install-folder deletion + admin-folder rename + cache-directory permissions. Missing these = compromise risk.
- **Caching + performance**: CCC (Combine/Compress/Cache) + OPcache + Redis/Memcached for sessions. Without them, large catalogs crawl.
- **Multi-shop** is powerful but fragile — rules for "what is shared vs per-shop" are tricky; theme/module compatibility with multi-shop varies.
- **Image handling**: PrestaShop generates many thumbnail sizes. Disk usage balloons. Use S3 / Cloudflare R2 CDN module if possible.
- **GDPR**: official GDPR module is bundled; still needs configuration (cookie consent, data export, right-to-be-forgotten workflows).
- **EU VAT MOSS/OSS**: if selling digital goods to EU consumers, VAT handling requires specific modules + registration. PrestaShop's built-in VAT is catalog-focused, not invoicing-focused.
- **PCI-DSS**: if storing card data, you're in PCI scope. Most merchants use tokenized gateways (Stripe, Adyen) to avoid this — the card data never touches PrestaShop.
- **Webservice API** uses XML by default; JSON via `Output-Format: JSON` header. Permissions are role-based but broad; use a dedicated API user.
- **SEO URL rewriting** — enable in Shop Parameters → Traffic & SEO; requires `.htaccess` regeneration (Apache) or nginx rewrites.
- **Email deliverability**: out-of-the-box PHP `mail()` = instant spam folder. Use a real SMTP relay (SendGrid, Mailgun, Postmark).
- **Pricing + inventory rules** are surprisingly deep; worth reading docs thoroughly before modeling your catalog.
- **B2B mode** has some features (quotes, per-customer prices) but is less polished than B2C. Dedicated B2B shops often use additional modules.
- **License caveat**: PrestaShop **core is OSL-3.0** (a copyleft + network-use-is-distribution like AGPL). **Modules + themes are AFL-3.0** (permissive). This is why you can sell proprietary modules. Your own modifications to core must be shared if you distribute.
- **PrestaShop Inc.** (the company) offers paid support contracts and runs the official marketplace. Community-run fork discussions surface occasionally; current ecosystem is unified.
- **Alternatives worth knowing:**
  - **WooCommerce** — WordPress plugin; biggest OSS e-commerce share globally; depends on WP (separate recipe)
  - **Magento/Adobe Commerce** — larger, heavier, enterprise-focused; OSS (Community) or commercial
  - **OpenCart** — simpler; PHP/MySQL; smaller catalog
  - **EverShop** — Node.js modern stack; early-stage (separate recipe)
  - **Medusa** — Node.js; headless e-commerce; modern
  - **Sylius** — Symfony-native; developer-friendly; smaller ecosystem
  - **Shopify / BigCommerce** — SaaS
  - **Shopware** — German; strong in B2B
  - **Choose PrestaShop if:** you're in EU/LatAm, want a mature full-stack PHP shop, are OK buying paid modules, and want multi-shop support.
  - **Choose WooCommerce if:** you already run (or want) WordPress + content + shop together.
  - **Choose Shopware if:** you're a B2B-heavy German-speaking market merchant.

## Links

- Repo: <https://github.com/PrestaShop/PrestaShop>
- Website: <https://www.prestashop.com>
- Docs: <https://docs.prestashop-project.org>
- Dev docs: <https://devdocs.prestashop-project.org>
- Addons marketplace: <https://addons.prestashop.com>
- System requirements: <https://docs.prestashop-project.org/8-user-documentation/getting-started/system-requirements>
- Install: <https://docs.prestashop-project.org/8-user-documentation/getting-started/installing-prestashop>
- Upgrade: <https://docs.prestashop-project.org/8-user-documentation/getting-started/updating-prestashop>
- Docker Hub: <https://hub.docker.com/_/prestashop>
- Releases: <https://github.com/PrestaShop/PrestaShop/releases>
- Webservice API: <https://devdocs.prestashop-project.org/1.7/webservice/>
- Community forum: <https://www.prestashop.com/forums/>
