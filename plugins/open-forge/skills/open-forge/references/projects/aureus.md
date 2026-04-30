---
name: Aureus ERP
description: Modern open-source Enterprise Resource Planning suite. Laravel 11 + FilamentPHP 5 + Livewire 4 + TailwindCSS 4. Modular plugins for accounting, invoices, inventory, HR, recruiting, timesheets, CRM, projects, website/blog. MySQL 8+ or SQLite. MIT.
---

# Aureus ERP

Aureus ERP is a modern, modular, open-source ERP system aimed at small-to-medium enterprises. Built on Laravel 11 + FilamentPHP 5, it offers a developer-friendly foundation that competes with the likes of Odoo Community, Dolibarr, and ERPNext — with a cleaner code base, a modern stack, and a plugin-first architecture.

Think of it as "Odoo, but built with modern PHP and Filament's admin panel conventions."

What makes Aureus distinctive:

- **Modern stack** — Laravel 11 (not 8.x legacy), Filament 5, Livewire 4, TailwindCSS 4
- **Plugin-first** — install only what you need via Artisan commands (`php artisan invoices:install`)
- **Cohesive design** — Filament components = consistent UI across all modules
- **Role-based access control** — Filament Shield integration
- **Responsive** — built for desktop + mobile from the start
- **Multi-language** — i18n support built in

Core plugins (installed by default):

- **Analytics** — BI + reporting
- **Chatter** — internal messaging on any record (Odoo-style)
- **Fields** — custom field definitions per model
- **Security** — RBAC, auth
- **Support** — help desk + docs
- **Table View** — customizable data grids

Installable modules:

- **Financial**: Accounting, Accounts, Invoices, Payments
- **Operations**: Inventories, Products, Purchases, Sales
- **HR**: Employees, Recruitments, Timeoffs, Timesheet
- **CRM**: Contacts, Partners
- **Projects/Content**: Blogs, Projects, Website

- Upstream repo: <https://github.com/aureuserp/aureuserp>
- Website: <https://aureuserp.com>
- Packagist: <https://packagist.org/packages/aureuserp/aureuserp>

## Architecture in one minute

- **Laravel 11** PHP app (PHP 8.3+)
- **FilamentPHP 5** admin panel (the whole UI is Filament resources)
- **Livewire 4** for real-time interactivity
- **Database**: MySQL 8.0+ OR SQLite 3.8.3+ (Postgres NOT officially listed in README — check docs for status)
- **Queue/Cache**: Laravel defaults — Redis recommended for production
- **Plugins** = Laravel packages registered via Composer + migrated via Artisan

Standard LAMP-style deployment: PHP-FPM + nginx/Apache + MySQL + (optional) Redis.

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                              |
| ----------- | ------------------------------------------------------ | ------------------------------------------------------------------ |
| Single VM   | PHP-FPM + nginx + MySQL (LEMP)                           | **Recommended for prod** — standard Laravel deploy                   |
| Single VM   | Laravel Sail (Docker for dev)                              | Development; not a prod pattern                                        |
| Single VM   | `php artisan serve` (dev server)                             | Quick eval only                                                          |
| Cloud PaaS  | Laravel Forge / Ploi / Cleavr                                | Managed Laravel hosting                                                      |
| Kubernetes  | Community Helm charts (if any)                                 | Stateless app + DB                                                             |

## Inputs to collect

| Input                 | Example                          | Phase     | Notes                                                               |
| --------------------- | -------------------------------- | --------- | ------------------------------------------------------------------- |
| `APP_URL`             | `https://erp.example.com`         | URL       | Filament uses this for absolute URLs (emails, exports)                 |
| `APP_KEY`             | `base64:...`                      | Security  | `php artisan key:generate` — losing invalidates encrypted data           |
| Database              | MySQL 8+ or SQLite                 | DB        | `.env` `DB_*` vars                                                            |
| Admin user            | created by `php artisan erp:install` | Bootstrap | Interactive — don't skip the password prompt                                   |
| Mail                  | SMTP / SES / Postmark / Mailgun      | Email     | For password resets + invoice sending + notifications                                |
| Queue driver          | `redis` / `database`                  | Jobs      | For async tasks (email, PDF generation, imports)                                      |
| Cache / session        | `redis` recommended in prod           | Perf      | File cache works for tiny instances                                                        |

## Install (native LEMP)

```sh
# Prereqs: PHP 8.3+, Composer 2+, Node 18+, MySQL 8+
git clone https://github.com/aureuserp/aureuserp.git
cd aureuserp
composer install --no-dev --optimize-autoloader
cp .env.example .env
# Edit .env: APP_URL, DB_*, MAIL_*, QUEUE_CONNECTION, etc.
php artisan key:generate

# Frontend assets
npm install
npm run build

# Run the installer (migrations + seeders + admin user)
php artisan erp:install

# Link storage
php artisan storage:link

# Optimize for prod
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan filament:optimize

# Web server: point nginx at public/ directory; php-fpm on socket
```

Visit `https://erp.example.com/admin` → log in with the admin credentials created by `erp:install`.

## Install plugins (after base install)

```sh
# Install specific functional modules as needed
php artisan invoices:install
php artisan accounting:install
php artisan products:install
php artisan inventories:install
php artisan sales:install
php artisan employees:install
php artisan timesheet:install
# ... see `php artisan list` for all
```

**Dependencies are handled** — installing `inventories` auto-checks for `products` and prompts if re-seeding is needed.

### Uninstall

```sh
php artisan <plugin-name>:uninstall
```

⚠️ **Warning** (from upstream README): "Uninstalling a plugin will remove its database tables and data. Make sure to backup your data before uninstalling."

## Install via Docker (unofficial / ad-hoc)

Aureus doesn't ship an official Docker image. You can adapt standard Laravel Docker patterns:

```yaml
services:
  app:
    build: .                         # Dockerfile with PHP 8.3 + Composer + Node
    restart: unless-stopped
    environment:
      APP_ENV: production
      APP_URL: https://erp.example.com
      DB_HOST: db
      DB_DATABASE: aureus
      DB_USERNAME: aureus
      DB_PASSWORD: <strong>
      REDIS_HOST: redis
      QUEUE_CONNECTION: redis
      CACHE_DRIVER: redis
      SESSION_DRIVER: redis
    volumes:
      - ./storage:/var/www/html/storage
    depends_on: [db, redis]

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports: ["80:80"]
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - .:/var/www/html:ro
    depends_on: [app]

  db:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: aureus
      MYSQL_USER: aureus
      MYSQL_PASSWORD: <strong>
      MYSQL_ROOT_PASSWORD: <strong-root>
    volumes:
      - db:/var/lib/mysql

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  queue:
    build: .
    restart: unless-stopped
    command: php artisan queue:work --sleep=3 --tries=3
    depends_on: [db, redis]
    # Same env as app

volumes:
  db:
```

You'll need your own Dockerfile, nginx config, etc. — standard Laravel practice. Check the [Laravel Sail](https://laravel.com/docs/sail) defaults for templates.

## Data & config layout

Aureus is a standard Laravel app:

- `.env` — config, secrets
- `storage/app/` — uploaded files (attachments, logos, document generation)
- `storage/logs/` — application logs
- Database — all business data (invoices, products, employees, etc.)

## Backup

```sh
# DB
mysqldump -u aureus -p aureus | gzip > aureus-db-$(date +%F).sql.gz

# File uploads
tar czf aureus-storage-$(date +%F).tgz storage/app

# .env (encryption keys, SMTP creds)
cp .env aureus-env-$(date +%F).bak
```

**Losing `APP_KEY` = losing any encrypted columns / hashed tokens**. Back up `.env` with the same care as the DB.

## Upgrade

1. Releases: <https://github.com/aureuserp/aureuserp/releases>. Check Packagist for latest version.
2. Back up DB + `.env` + `storage/app/`.
3. `git pull` OR `composer update aureuserp/aureuserp`.
4. `composer install --no-dev --optimize-autoloader`
5. `npm install && npm run build`
6. `php artisan migrate`
7. `php artisan filament:upgrade`
8. Re-run plugin updates: `php artisan <plugin>:install` (with "Skip" on re-seed prompts)
9. Clear caches: `php artisan optimize:clear && php artisan optimize`

## Gotchas

- **Young project** — Aureus ERP is newer than Odoo/ERPNext/Dolibarr. Feature depth, community plugins, and mobile apps are less mature. Do a feature fit-check before committing.
- **PHP 8.3+ required** — no PHP 8.2 or older support. Plan your server accordingly.
- **MySQL 8.0+ or SQLite** — official support list does NOT include MariaDB or PostgreSQL in the README. Check the latest docs if those matter.
- **`php artisan erp:install` is interactive** — automate via `--no-interaction` flags OR run it once manually. Running it twice may re-seed data.
- **Uninstalling a plugin drops tables** — no soft-uninstall. Back up before playing with modules in prod.
- **No official Docker image** — deployment is via standard Laravel patterns (PHP-FPM + nginx + DB) OR Laravel Forge / Ploi. Community Docker setups may exist.
- **Queue worker must run** for async tasks (emails, PDF generation, imports, scheduled jobs). Add a systemd service or supervisord for `php artisan queue:work`.
- **Scheduler** — add to cron: `* * * * * cd /path/to/aureus && php artisan schedule:run >> /dev/null 2>&1`
- **Filament Shield** drives RBAC; role policies are Artisan-generated — run `php artisan shield:generate --all` after installing new plugins.
- **LiveWire over WebSockets**: Laravel Reverb (self-hosted WebSocket server) or Pusher / Ably can improve real-time UX. Not required, but nice.
- **Multi-tenancy** — Aureus itself isn't multi-tenant (one DB = one organization). For SaaS-style multi-tenancy, you'd need `spatie/laravel-multitenancy` or similar patterns on top.
- **Asset compilation**: after code changes, `npm run build` compiles Tailwind + Livewire assets. Missing this = broken UI.
- **Email templates** — configurable per-module in Filament; default templates are in English.
- **Internationalization** — i18n support exists; community translations vary by plugin. Some plugins are English-only.
- **Plugin licensing varies** — core is MIT; some community plugins may have different licenses. Check before deploying.
- **MIT license** — permissive; commercial use OK.
- **Alternatives worth knowing:**
  - **Odoo Community** — the granddaddy; huge ecosystem; LGPLv3; Python; complex
  - **ERPNext / Frappe** — Python-based; strong accounting; GPLv3
  - **Dolibarr** — PHP; mature; simpler than Aureus' stack
  - **Axelor Open Suite** — Java; enterprise-flavored; AGPLv3
  - **Akaunting** — PHP/Laravel; simpler; accounting-focused
  - **InvoicePlane** — PHP; invoice-only
  - **Tryton** — Python; serious modular ERP; GPLv3
  - **Choose Aureus if:** you want a modern PHP/Laravel stack, Filament's UI consistency, and are OK being an early adopter.
  - **Choose Odoo CE if:** you want the deepest ecosystem, are OK with Python complexity, and have ERP consultants available.
  - **Choose ERPNext if:** you want strong accounting + manufacturing + a mature community.
  - **Choose Dolibarr if:** you want a simple PHP ERP with lower learning curve.

## Links

- Repo: <https://github.com/aureuserp/aureuserp>
- Website: <https://aureuserp.com>
- Packagist: <https://packagist.org/packages/aureuserp/aureuserp>
- Laravel: <https://laravel.com>
- FilamentPHP: <https://filamentphp.com>
- Filament Shield: <https://github.com/bezhanSalleh/filament-shield>
- Issue tracker: <https://github.com/aureuserp/aureuserp/issues>
- Releases: <https://github.com/aureuserp/aureuserp/releases>
