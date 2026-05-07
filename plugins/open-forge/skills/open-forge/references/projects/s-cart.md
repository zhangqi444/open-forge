---
name: s-cart
description: S-Cart recipe for open-forge. E-commerce platform for individuals and businesses built on Laravel Framework. PHP + MySQL/PostgreSQL. Source: https://github.com/gp247net/s-cart
---

# S-Cart

An open-source e-commerce platform for individuals and businesses, built on the Laravel framework. Provides storefront, product management, order management, customer management, and admin panel. MIT licensed, PHP/Laravel. Upstream: <https://github.com/gp247net/s-cart>. Website: <https://s-cart.org/>. Demo: <https://demo.s-cart.org/>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | PHP 8+ + Apache/NGINX | MySQL / MariaDB | Standard Laravel LAMP/LEMP stack |
| Any Linux VPS | PHP 8+ + NGINX | PostgreSQL | Also supported by Laravel |
| Any Linux VPS | Docker Compose | MySQL | Containerised setup |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for the store?" | FQDN | e.g. shop.example.com |
| "Database type?" | MySQL / MariaDB / PostgreSQL | MySQL/MariaDB recommended |
| "Database host, name, user, password?" | Connection details | |
| "Store name?" | String | Shown on storefront |
| "Admin email and password?" | email + string (sensitive) | Initial admin credentials |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Mail/SMTP config?" | host:port + credentials | For order confirmation emails to customers |
| "Currency and locale?" | ISO currency + locale | e.g. USD / en |
| "Payment gateway?" | Stripe / PayPal / COD / other | Configure via admin panel post-install |

## Software-Layer Concerns

- **Laravel app**: Standard Laravel deployment — requires PHP 8+, Composer, and a database.
- **Storage**: User uploads (product images) in `storage/app/public` — symlink to `public/storage` with `php artisan storage:link`.
- **Queue worker**: For email and async tasks, run `php artisan queue:work` (or configure queue driver in `.env`).
- **Cache**: Set `CACHE_DRIVER` and `SESSION_DRIVER` in `.env` — file/Redis/database supported.
- **APP_KEY**: Must generate with `php artisan key:generate` before first run.
- **Migrations**: Run `php artisan migrate --seed` to set up database and seed initial data.
- **Plugins/themes**: S-Cart has a plugin and theme system — browse at https://s-cart.org/addons.

## Deployment

### NGINX + PHP-FPM

```bash
git clone https://github.com/gp247net/s-cart.git /var/www/scart
cd /var/www/scart
composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate
# Edit .env: DB_*, APP_URL, MAIL_*, etc.
php artisan migrate --seed
php artisan storage:link
chown -R www-data:www-data /var/www/scart
```

NGINX config:
```nginx
server {
    listen 443 ssl;
    server_name shop.example.com;
    root /var/www/scart/public;
    index index.php;

    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Upgrade Procedure

1. `git pull` or download new release.
2. `composer install --no-dev --optimize-autoloader`
3. `php artisan migrate` for any new migrations.
4. `php artisan config:cache && php artisan route:cache && php artisan view:cache`
5. Backup database before upgrading.

## Gotchas

- **storage:link required**: Without it, product images won't be publicly accessible.
- **Queue driver**: Default is `sync` (runs inline, no worker needed) — for production, use Redis or database queue + a persistent worker.
- **APP_KEY**: Must be generated and kept stable — changing it invalidates encrypted data.
- **Low recent activity**: Commit history shows minimal activity in late 2025 through early 2026. Check upstream for maintenance status before production use.
- **Demo available**: https://demo.s-cart.org/ — try before deploying.

## Links

- Source: https://github.com/gp247net/s-cart
- Website: https://s-cart.org/
- Demo: https://demo.s-cart.org/
- Addons/plugins: https://s-cart.org/addons
- Releases: https://github.com/gp247net/s-cart/releases
