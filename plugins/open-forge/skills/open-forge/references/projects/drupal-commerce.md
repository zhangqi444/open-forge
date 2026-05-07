---
name: drupal-commerce
description: Drupal Commerce recipe for open-forge. Flexible e-commerce module for Drupal CMS powering 60,000+ online stores. Supports payments, shipping, tax, and a vast module ecosystem. GPL-2.0, PHP. Source: https://git.drupalcode.org/project/commerce
---

# Drupal Commerce

The leading flexible e-commerce solution for Drupal, powering over 60,000 online stores. Deeply integrated with Drupal's content and configuration management, views, rules, and entity system. Supports dozens of payment gateways (Stripe, PayPal, Braintree), shipping modules, tax calculation, subscriptions, product variations, and more. GPL-2.0 licensed, PHP. Website: <https://drupalcommerce.org/>. Docs: <https://docs.drupalcommerce.org/>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux | PHP 8.1+ + Apache/NGINX | MySQL / MariaDB | Standard Drupal stack |
| Any Linux | PHP 8.1+ + Apache/NGINX | PostgreSQL | Supported |

> Note: Drupal Commerce is a **Drupal module** — you must have a working Drupal installation first. It is not a standalone e-commerce application.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Drupal version?" | 9.x / 10.x / 11.x | Commerce 2.x for D9/D10; Commerce 3.x for D10/D11 |
| "Domain?" | FQDN | Your Drupal site domain |
| "Database?" | MySQL / PostgreSQL | |
| "Payment gateway?" | Stripe / PayPal / other | Determines which Commerce payment module to install |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Currency?" | ISO 4217 code | e.g. USD, EUR |
| "Store name?" | string | Set during Commerce setup wizard |

## Software-Layer Concerns

- **Drupal prerequisite**: Drupal Commerce is a Drupal module — a full Drupal installation (Apache/NGINX + PHP + database) must exist before installing Commerce.
- **Composer-managed**: Both Drupal and Commerce are installed via Composer — do not manually download modules.
- **Commerce 2.x vs 3.x**: Commerce 2.x targets Drupal 9/10; Commerce 3.x targets Drupal 10/11. Check compatibility at https://www.drupal.org/project/commerce.
- **Payment gateways**: Separate modules per payment provider — install e.g. `drupal/commerce_stripe`, `drupal/commerce_paypal` via Composer.
- **Order workflows**: Commerce has configurable order state machines — customize fulfillment workflows in admin.
- **Product variations**: Products support multiple variations (size, color, etc.) with separate SKUs, prices, and inventory.
- **Views integration**: Catalog, cart, and checkout pages are built on Drupal Views — highly customizable.

## Deployment

### New Drupal + Commerce project (recommended)

```bash
# Create new Drupal Commerce project using the project template
composer create-project drupalcommerce/project-base mystore --stability dev --no-interaction
cd mystore

# Set up web server root to: web/
# Configure database in: web/sites/default/settings.php

# Install via Drush
vendor/bin/drush site:install commerce \
  --db-url=mysql://user:pass@localhost/mystore \
  --site-name="My Store" \
  --account-mail=admin@example.com \
  --account-pass=adminpass \
  -y

# Enable Commerce modules
vendor/bin/drush en commerce commerce_product commerce_order commerce_cart commerce_checkout commerce_payment -y
vendor/bin/drush cr
```

### Add to existing Drupal site

```bash
# Require Commerce and its dependencies
composer require drupal/commerce

# Enable modules
vendor/bin/drush en commerce commerce_product commerce_order commerce_cart commerce_checkout -y
vendor/bin/drush updatedb -y
vendor/bin/drush cr

# Optional: payment gateway
composer require drupal/commerce_stripe
vendor/bin/drush en commerce_stripe -y
```

### NGINX vhost for Drupal

```nginx
server {
    listen 443 ssl;
    server_name shop.example.com;
    root /var/www/mystore/web;
    index index.php;

    location / {
        try_files $uri /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(txt|log)$ { deny all; }
    location ~ ^/sites/.*/private/ { deny all; }
}
```

### Post-install store setup

1. Visit `/admin/commerce/stores` → add your first store (name, currency, address, tax zone)
2. `/admin/commerce/product-types` → configure product types
3. `/admin/commerce/config/payment-gateways` → configure payment providers
4. `/admin/commerce/config/checkout-flows` → customize checkout steps

## Upgrade Procedure

1. `composer update drupal/commerce drupal/core --with-all-dependencies`
2. `vendor/bin/drush updatedb -y`
3. `vendor/bin/drush cr`
4. Follow migration guides at https://docs.drupalcommerce.org/ for major version upgrades.

## Gotchas

- **Composer is mandatory**: Never manually upload Commerce module files — Composer manages the full dependency tree.
- **Not standalone**: Commerce is a Drupal module. You need a full Drupal site with theming, hosting, and Drupal administration experience.
- **Payment gateways are separate modules**: Core Commerce doesn't include any specific gateway — install `commerce_stripe`, `commerce_paypal`, etc. separately.
- **PHP memory limit**: Complex Composer operations need `memory_limit = -1` or at least 512MB.
- **Drupal cron required**: Order management, abandoned cart cleanup, and subscriptions rely on Drupal cron running regularly.

## Links

- Website: https://drupalcommerce.org/
- Documentation: https://docs.drupalcommerce.org/
- Source (Drupal GitLab): https://git.drupalcode.org/project/commerce
- Drupal.org project page: https://www.drupal.org/project/commerce
- Payment gateways list: https://docs.drupalcommerce.org/commerce2/developer-guide/payments/
