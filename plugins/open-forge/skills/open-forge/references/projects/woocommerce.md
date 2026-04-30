---
name: WooCommerce
description: "The canonical open-source e-commerce plugin for WordPress — turns a WordPress site into a full online store. Products, cart, checkout, orders, payments (via gateway plugins), shipping, taxes, reports. Requires WordPress 6.x + PHP 7.4+. GPL-2.0-or-later."
---

# WooCommerce

WooCommerce is the open-source e-commerce plugin for WordPress. It powers roughly a quarter of all online stores worldwide — competing with Shopify, BigCommerce, and Magento. Because it's a WordPress plugin, you install WordPress first, then WooCommerce, then extend with payment-gateway plugins, shipping plugins, and themes.

WooCommerce is maintained by **Automattic** (the company behind WordPress.com). The code is open-source (GPL); many extensions are commercial.

What you get out of the box:

- **Product catalog** — physical, digital, variable, grouped, subscription (via add-on)
- **Cart + checkout** — single-page or classic; customizable
- **Order management** — admin UI; email notifications; refunds
- **Payments** — core ships with "direct bank transfer" + "check" + "COD"; real payments (Stripe, PayPal, WooPayments) are separate plugins
- **Shipping** — flat rate / free / local pickup; rate-by-zone; extensions for UPS/USPS/FedEx/DHL
- **Taxes** — manual or automated (WooCommerce Tax extension or Avalara / TaxJar)
- **Reports + analytics** — sales, revenue, stock
- **REST API** — for mobile apps, PoS, integrations
- **Blocks editor support** — modern checkout/cart/product blocks via Gutenberg

**Note**: This recipe is for **self-hosting the WooCommerce plugin on your own WordPress install**. It is NOT about the WooCommerce monorepo development setup (which is what the GitHub README mostly covers). The monorepo README is aimed at contributors, not site operators.

- Plugin page on wordpress.org: <https://wordpress.org/plugins/woocommerce/>
- Upstream repo (monorepo): <https://github.com/woocommerce/woocommerce>
- Website: <https://woocommerce.com>
- Docs: <https://woocommerce.com/documentation/>
- Developer portal: <https://developer.woocommerce.com>

## Architecture in one minute

- **WordPress** (PHP + MySQL/MariaDB) is the base — cannot run without it
- **WooCommerce plugin** adds database tables (products, orders, sessions, etc.) + admin UI + storefront templates
- **Payment gateways** are separate plugins (Stripe, PayPal Payments, WooPayments, Square, etc.)
- **Themes** — any WP theme works; "Storefront" (by WooCommerce) is the canonical free theme; most modern themes have WooCommerce support
- **"HPOS" (High-Performance Order Storage)** — newer WooCommerce uses dedicated order tables instead of wp_posts; enable in `WooCommerce → Settings → Advanced → Features`

Typical stack: nginx + PHP-FPM + MySQL/MariaDB + Redis (object cache, optional) + WP-CLI.

## Compatible install methods

| Infra       | Runtime                                                   | Notes                                                           |
| ----------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | LEMP (Linux + nginx + MariaDB + PHP-FPM)                    | **Most common** self-hosted pattern                                |
| Single VM   | LAMP (Apache instead of nginx)                                | Same idea, Apache                                                    |
| Docker      | Official `wordpress:*` image + `mariadb` + reverse proxy      | Clean containerized deploy                                              |
| Managed WP  | WordPress.com Business+, Kinsta, WP Engine, SiteGround, Bluehost | Many WP hosts preinstall WooCommerce                                         |
| PaaS        | Cloudways, DigitalOcean 1-click WordPress droplets              | Easy spin-up                                                                    |

## Inputs to collect

| Input                      | Example                        | Phase     | Notes                                                              |
| -------------------------- | ------------------------------ | --------- | ------------------------------------------------------------------ |
| WordPress install           | `https://shop.example.com`      | Base      | You must install WP first                                              |
| DB credentials              | WP's own DB                     | DB        | WooCommerce adds tables in the existing WP DB                              |
| `WP_HOME` / `WP_SITEURL`    | from WP config                  | URL       | Changing later breaks caches + hardcoded URLs                              |
| Admin user                  | WP admin account                 | Bootstrap | Created during WP install                                                  |
| SSL cert                    | Let's Encrypt                    | TLS       | **REQUIRED** for payment gateways — none will accept plain HTTP              |
| Store currency / address    | collected by WP setup wizard      | Store     | Affects tax + shipping logic                                                  |
| Payment gateway credentials | Stripe keys / PayPal / etc.       | Payments  | Per-gateway; install the gateway plugin FIRST, then configure                     |
| SMTP                        | WP Mail SMTP or similar            | Email     | Order emails, receipts, admin notifications                                         |

## Install via Docker Compose (WordPress + WooCommerce)

```yaml
services:
  wordpress:
    image: wordpress:6.8-php8.3-fpm-alpine    # pin WP + PHP version
    container_name: wordpress
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: <strong>
      WORDPRESS_DB_NAME: wordpress
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_MEMORY_LIMIT', '512M');
        define('DISALLOW_FILE_EDIT', true);
        define('FORCE_SSL_ADMIN', true);
    volumes:
      - wp-content:/var/www/html/wp-content
      - ./uploads.ini:/usr/local/etc/php/conf.d/uploads.ini:ro

  nginx:
    image: nginx:alpine
    container_name: wp-nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - wp-content:/var/www/html/wp-content
    depends_on: [wordpress]

  db:
    image: mariadb:11
    container_name: wp-db
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong-root>
      MARIADB_DATABASE: wordpress
      MARIADB_USER: wordpress
      MARIADB_PASSWORD: <strong>
    volumes:
      - db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: wp-redis
    restart: unless-stopped

volumes:
  wp-content:
  db:
```

Then:

1. Browse `http://localhost` → WordPress install wizard → create admin account
2. Log in → **Plugins → Add New → search "WooCommerce" → Install → Activate**
3. WooCommerce setup wizard launches → store address, currency, sample products, payment methods
4. Before going live: install TLS (Caddy/Traefik/nginx-proxy-acme) — WP/WooCommerce requires HTTPS for real transactions

## Native LEMP (Debian/Ubuntu)

```sh
# Install LEMP (example Debian 12)
apt install -y nginx php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip php-intl mariadb-server wp-cli

# Create DB
mysql -uroot -p -e "CREATE DATABASE wordpress; CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '<strong>'; GRANT ALL ON wordpress.* TO 'wordpress'@'localhost'; FLUSH PRIVILEGES;"

# Install WordPress
mkdir -p /var/www/shop
cd /var/www/shop
wp core download --allow-root
wp config create --dbname=wordpress --dbuser=wordpress --dbpass='<strong>' --allow-root
wp core install --url=https://shop.example.com --title="My Store" \
  --admin_user=admin --admin_password='<strong>' --admin_email=admin@example.com --allow-root

# Install WooCommerce
wp plugin install woocommerce --activate --allow-root
```

Configure nginx vhost to point at `/var/www/shop` → `public_html`.

## First configuration

1. **WooCommerce setup wizard**: store address, currency, tax, shipping zones
2. **Install payment gateway plugins**:
   - **WooPayments** (Automattic's own) — Stripe-powered, integrated
   - **Stripe for WooCommerce** — direct Stripe
   - **PayPal Payments** — PayPal's official
   - **Square** / **Authorize.net** / etc.
3. **Install essentials**:
   - **WP Mail SMTP** (transactional email)
   - **Wordfence** or similar (security)
   - **Akismet** (comment spam)
   - Caching plugin: LiteSpeed Cache / WP Rocket (paid) / W3 Total Cache
4. **Enable HPOS**: `WooCommerce → Settings → Advanced → Features → High-Performance Order Storage`. New installs default to HPOS; confirm it's on.
5. **Add products**: `Products → Add New`
6. **Test checkout** with a test card (Stripe test mode: `4242 4242 4242 4242`)

## Data & config layout

Standard WordPress:

- `/var/www/html/wp-content/` — plugins, themes, uploads
- `/var/www/html/wp-content/uploads/` — product images, customer uploads
- `wp-config.php` — DB creds, secret keys, `WP_HOME`
- DB: WP tables (`wp_posts`, `wp_postmeta`, `wp_users`, etc.) + WooCommerce HPOS tables (`wp_wc_orders`, `wp_wc_order_addresses`, `wp_wc_order_operational_data`, etc.)

## Backup

**Critical: e-commerce data changes by the minute.** Automated backup is non-negotiable.

```sh
# DB
mysqldump -uwordpress -p wordpress | gzip > wp-db-$(date +%F).sql.gz

# wp-content (uploads + plugins + themes)
tar czf wp-content-$(date +%F).tgz /var/www/shop/wp-content

# wp-config.php (secrets — keep encrypted separately)
cp /var/www/shop/wp-config.php wp-config-$(date +%F).bak
```

Better: use [UpdraftPlus](https://wordpress.org/plugins/updraftplus/) (free, schedules backups to S3/GDrive/Dropbox), or a host-level backup product (Jetpack Backup / Kinsta / WP Engine).

## Upgrade

1. **Back up first. Always.**
2. WP admin → `Updates` → one-click update WordPress, WooCommerce, plugins, themes.
3. Test on a staging copy for **major** WooCommerce releases (e.g., 8.x → 9.x) — some include DB migrations.
4. **WP-CLI**: `wp core update && wp plugin update --all`
5. After WooCommerce updates, visit `WooCommerce → Status` — it will run any pending DB updates.

## Gotchas

- **This repo is a MONOREPO for developers**, not the installable plugin. Site operators install from wordpress.org or `wp plugin install woocommerce`. The repo is for contributors.
- **TLS is mandatory** for real payments. Every modern payment gateway refuses plain HTTP (Stripe, PayPal, Square). Use Let's Encrypt.
- **PCI-DSS**: if you handle card numbers on your own server (direct Stripe API), you're subject to PCI. Most gateways use hosted fields or redirects to keep you out of scope — use those.
- **WooCommerce is heavy** — large catalogs + many plugins = slow admin + slow store. Object cache (Redis), page cache (Varnish / LiteSpeed / WP Rocket), and a CDN (Cloudflare / BunnyCDN) are essentially required for production traffic.
- **HPOS (High-Performance Order Storage)** — dedicated order tables; much faster than legacy `wp_posts`. New installs: default on. Existing installs: toggle carefully; do the compatibility check + "sync" before flipping.
- **Plugin incompatibility** — not all WooCommerce plugins support HPOS. Check the compatibility notice in WP admin.
- **Blocks-based checkout** is the modern default (since WC 8.x). Legacy "shortcode" checkout still works but is being deprecated. Some custom checkout plugins only work with one or the other.
- **Variable products can explode** the product table — a product with 5 attributes × 4 values each creates 625 variations by default; limit variations or use "Any value" for flexible attributes.
- **Tax calculation** — built-in is simple; real-world sales-tax complexity (US nexus, EU VAT OSS, VAT digital goods MOSS) requires add-ons like WooCommerce Tax (Avalara), TaxJar, or Quaderno.
- **Stock management** — enable "Enable stock management" in WC settings; otherwise, products will oversell.
- **Subscriptions require the paid "WooCommerce Subscriptions"** extension from woocommerce.com — no free OSS equivalent in core.
- **WooCommerce Payments / WooPayments** is Automattic's own gateway — US-centric; great integration; not available in every country. Outside those, Stripe direct or PayPal.
- **Abandoned cart recovery** is not in core — requires an extension (e.g., CartBounty / Metorik).
- **Email deliverability** — WordPress uses `mail()` by default which spams-bin. Install **WP Mail SMTP** + route through SendGrid / Postmark / SES / Mailgun.
- **Multi-currency** is not in core — extensions like WPML Multi-Currency, Aelia Currency Switcher, or Automattic's own.
- **Site migrations** — changing domain breaks serialized data. Use WP-CLI `wp search-replace OLD_URL NEW_URL --precise --all-tables` (NOT find-and-replace on SQL dumps).
- **Security**: WordPress is the most-attacked CMS on the internet. Use Wordfence / iThemes Security, restrict `/wp-admin` by IP or 2FA, keep plugins updated, remove unused plugins.
- **Managed WP hosts** (WP Engine / Kinsta / Pressable) handle LEMP + security + backups + HPOS migrations for you at a cost; reasonable trade-off for non-technical store operators.
- **WooCommerce.com marketplace** is where most extensions live — commercial, annual licenses.
- **GPL-2.0-or-later** — core + most Automattic extensions; many marketplace extensions are also GPL (required by WP ecosystem rules) but sold with licenses granting support + updates.
- **Alternatives worth knowing:**
  - **Shopify** — SaaS; huge ecosystem; hands-off; monthly fee
  - **Magento / Adobe Commerce** — enterprise; complex; expensive
  - **PrestaShop** — OSS; PHP; traditional
  - **Sylius** — Symfony-based; developer-friendly; B2B focus
  - **Medusa** — Node.js headless commerce; modern
  - **Saleor** — Python/GraphQL headless
  - **OpenCart** — older PHP; simpler than Magento
  - **Snipcart** — JS widget bolted onto any site; SaaS
  - **Ghost Commerce / Memberful** — creator-focused
  - **Choose WooCommerce if:** you're on WordPress, want maximum ecosystem + plugins, OK self-hosting.
  - **Choose Shopify if:** you don't want to self-host; you want hands-off upgrades + security.
  - **Choose Medusa / Saleor if:** you want a modern headless commerce API for a custom frontend.

## Links

- Plugin on wordpress.org: <https://wordpress.org/plugins/woocommerce/>
- Monorepo (for contributors): <https://github.com/woocommerce/woocommerce>
- Website: <https://woocommerce.com>
- Docs: <https://woocommerce.com/documentation/>
- Developer docs: <https://developer.woocommerce.com/docs/>
- Developer blog: <https://developer.woocommerce.com/blog/>
- Community forum (wordpress.org): <https://wordpress.org/support/plugin/woocommerce/>
- WooCommerce marketplace (extensions): <https://woocommerce.com/products/>
- Storefront theme: <https://woocommerce.com/storefront/>
- HPOS migration guide: <https://github.com/woocommerce/woocommerce/wiki/High-Performance-Order-Storage-Upgrade-Recipe-Book>
- Support portal: <https://woocommerce.com/contact-us/>
- WooCommerce Slack community: <https://woocommerce.com/community-slack/>
- Security reports (HackerOne): <https://hackerone.com/automattic/>
