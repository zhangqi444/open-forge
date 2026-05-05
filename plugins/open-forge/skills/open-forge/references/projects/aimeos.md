# Aimeos

High-performance, API-first Laravel e-commerce platform supporting multi-vendor, multi-channel, and multi-warehouse setups. Handles millions of products, subscriptions, 100+ payment gateways, and a full admin backend. Can be installed as a standalone shop application or added to an existing Laravel project as a Composer package.

**Official site:** https://aimeos.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | PHP 8.2+ / Laravel / Composer | Recommended; standalone or Laravel package |
| Any Linux host | Docker Compose (custom) | Build your own image on top of `php:8.2-fpm` |
| Cloud / Kubernetes | Laravel Vapor / K8S | Native cloud support via Laravel ecosystem |

---

## Inputs to Collect

### Phase 1 — Planning
- Database: MySQL 8.0+ / MariaDB 10.5+ / PostgreSQL 14+ / SQLite (dev only)
- Admin email and password (set during `composer create-project`)
- Timezone and locale for the storefront
- Payment gateway integrations needed

### Phase 2 — Deployment
- Laravel `.env`: `DB_*`, `MAIL_*`, `APP_URL`, `APP_KEY`
- Whether to enable demo data (`--option=setup/default/demo:1`)

---

## Software-Layer Concerns

### Standalone Installation (Recommended for new shops)

```bash
# Install Composer
wget https://getcomposer.org/download/latest-stable/composer.phar -O composer

# Create a new Aimeos standalone shop
php composer create-project aimeos/aimeos myshop
cd myshop
```

You will be prompted for database credentials, mail server settings, and an admin account email/password.

### Add to Existing Laravel App

1. Add to `composer.json`:
```json
"require": {
    "aimeos/aimeos-laravel": "~2025.10"
}
```

2. Run:
```bash
php composer update -W
php artisan vendor:publish --tag=config --tag=public
php artisan migrate
php artisan aimeos:setup --option=setup/default/demo:1
```

3. Add Laravel auth (e.g. Breeze):
```bash
composer require laravel/breeze
php artisan breeze:install
npm install && npm run build
```

### Key Laravel `.env` Variables

| Variable | Description |
|----------|-------------|
| `APP_URL` | Public shop URL |
| `APP_KEY` | Laravel encryption key (`php artisan key:generate`) |
| `DB_CONNECTION` | `mysql` / `pgsql` / `sqlite` |
| `DB_HOST`, `DB_PORT`, `DB_DATABASE` | Database connection |
| `DB_USERNAME`, `DB_PASSWORD` | Database credentials |
| `MAIL_*` | SMTP/Mailgun settings for order emails |

### Config Paths
| Path | Purpose |
|------|---------|
| `config/shop.php` | Aimeos shop config (published from package) |
| `config/aimeos.php` | Aimeos core config |
| `resources/views/vendor/aimeos/` | Template overrides |
| `storage/` | Laravel file storage (invoices, uploads) |

### Admin Backend

Access at `https://your-shop/admin`. Log in with the email/password set during installation.

---

## Upgrade Procedure

```bash
php composer update -W
php artisan vendor:publish --tag=config --tag=public --force
php artisan migrate
php artisan aimeos:setup
```

For **major version upgrades** (e.g., 2024.x → 2025.x), check the [upgrade guide](https://aimeos.org/docs/latest/laravel/setup/#upgrade) — config keys and database schema may change.

---

## Gotchas

- **MySQL charset** — use `utf8mb4` / `utf8mb4_unicode_ci`; older MySQL 5.7 setups may hit 767-byte key limits and require `utf8` / `utf8_unicode_ci` as a workaround.
- **`APP_URL` must be exact** — used for asset URLs, payment callbacks, and SEO. Wrong value breaks checkout and payment redirects.
- **Demo data** — the `--option=setup/default/demo:1` flag installs demo products; omit it for production.
- **Laravel auth is separate** — Aimeos does not bundle user auth; install Laravel Breeze or Jetstream to handle login/registration.
- **Multi-vendor requires a license** — the base install is LGPL for single-vendor; multi-vendor marketplace features require a commercial license.
- **Performance** — enable Laravel cache (`php artisan config:cache`, `route:cache`) and use a persistent cache backend (Redis) for production.
- **PHP extensions required** — `intl`, `gd` (or `imagick`), `pdo_mysql` (or `pdo_pgsql`), `json`, `mbstring`. Check with `composer diagnose`.

---

## References
- GitHub (standalone): https://github.com/aimeos/aimeos
- GitHub (Laravel package): https://github.com/aimeos/aimeos-laravel
- Documentation: https://aimeos.org/docs/latest/laravel/setup/
- Demo: https://laravel.demo.aimeos.org
