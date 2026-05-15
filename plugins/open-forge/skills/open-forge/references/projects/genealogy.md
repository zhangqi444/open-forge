---
name: genealogy
description: Genealogy recipe for open-forge. Family tree web application built on Laravel 12. Record family members, relationships, build visual trees. PHP 8.4 + MySQL/MariaDB, requires HTTPS. Source: https://github.com/MGeurts/genealogy
---

# Genealogy

Free and open-source family tree web application. Record family members and their relationships (biological parents, partners, children, siblings) and build a browsable family tree. Built on the TALL stack (Tailwind CSS, Alpine.js, Livewire 4, Laravel 12) with Filament 5 table builder and Laravel Jetstream teams. PHP 8.4 + MySQL 8+ / MariaDB 10.2+. MIT licensed.

Live demo: <https://genealogy.kreaweb.be/> | Upstream: <https://github.com/MGeurts/genealogy>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | PHP 8.4 + Composer + Node.js + MySQL/MariaDB | Requires HTTPS |
| Any | Docker (community) | No official Docker image; check community forks |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | HTTPS required | Application enforces HTTPS — HTTP-only installs will have issues |
| config | Domain name (HTTPS) | Must be served over HTTPS |
| config | MySQL/MariaDB host, DB name, user, password | MySQL 8.0.1+ or MariaDB 10.2.2+ with CTE support |
| config | App URL (APP_URL) | Full HTTPS URL, e.g. https://genealogy.example.com |
| config | Mail server | SMTP config for invitations and notifications |
| config | Admin email + password | Set during first login after seeding |

## Software-layer concerns

### Requirements

- PHP 8.4 (not 8.2 or 8.3 — Laravel 12 requires 8.4)
- MySQL 8.0.1+ or MariaDB 10.2.2+ — requires Recursive Common Table Expressions (CTEs)
- Composer (PHP dependency manager)
- Node.js + npm (frontend build)
- HTTPS — application requires secure context

### Key files

| File/Dir | Description |
|---|---|
| `.env` | Environment config (copy from `.env.example`) |
| `storage/` | Uploaded files, logs — needs writable permissions |
| `public/storage` | Symlink to storage (created by `artisan storage:link`) |

## Install

```bash
# 1. Clone
git clone https://github.com/MGeurts/genealogy.git /var/www/genealogy
cd /var/www/genealogy

# 2. Configure environment
cp .env.example .env
# Edit .env: set APP_URL, DB_*, MAIL_*, APP_KEY will be generated next

# 3. Install PHP dependencies
composer install --no-dev --optimize-autoloader

# 4. Generate app key
php artisan key:generate

# 5. Link storage
php artisan storage:link

# 6. Run database migrations + seed default data
php artisan migrate:fresh --seed

# 7. Install and build frontend assets
npm install && npm run build

# 8. Set permissions
chown -R www-data:www-data storage bootstrap/cache

# 9. Serve (dev preview)
php artisan serve
# Or configure nginx/Apache virtual host pointing to public/
```

After install, log in at `/login` — default credentials are set by the seeder (check `database/seeders/` or `.env` for `APP_ADMIN_EMAIL`/`APP_ADMIN_PASSWORD`).

## Upgrade procedure

```bash
git pull
composer install --no-dev --optimize-autoloader
npm install && npm run build
php artisan migrate
php artisan cache:clear
php artisan config:clear
# Restart web server / PHP-FPM
```

## Gotchas

- **HTTPS is mandatory** — the application requires a secure context. Use Certbot + nginx with a valid TLS certificate before installing.
- PHP 8.4 required — Laravel 12 dropped support for older PHP versions. Verify with `php -v` before installing.
- Database must support Recursive CTEs — MySQL < 8.0.1 and MariaDB < 10.2.2 will fail on queries. Standard MySQL 8 or MariaDB 10.6+ recommended.
- `migrate:fresh --seed` drops all existing tables — only run on fresh installs. For upgrades, run `php artisan migrate` (without `--seed` or `--fresh`).
- No official Docker image — the project is PHP/Laravel and runs best on a traditional LEMP stack. Check GitHub issues/forks for community Docker setups.

## Links

- Source: https://github.com/MGeurts/genealogy
- Demo: https://genealogy.kreaweb.be/
- Releases: https://github.com/MGeurts/genealogy/releases
