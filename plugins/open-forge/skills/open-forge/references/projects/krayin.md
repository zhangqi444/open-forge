---
name: Krayin CRM
description: "Free open-source Laravel CRM for SMEs and enterprises — manage contacts, leads, pipelines, activities, and the full customer lifecycle. PHP/Laravel. MIT."
---

# Krayin CRM

Krayin CRM is a free, open-source customer relationship management system built on Laravel (PHP) and Vue.js. It targets SMEs and enterprises needing full customer lifecycle management — leads, contacts, organizations, pipelines, activities, and email parsing — without vendor lock-in.

Maintained by Webkul (the same company behind Bagisto eCommerce). Active development; v2.x series current.

Use cases: (a) sales team pipeline and lead tracking (b) contact and account management (c) activity logging and scheduling (d) replacing Salesforce/HubSpot for teams that want self-hosted control (e) email-integrated CRM with Sendgrid parsing.

Features:

- **Leads management** — create, assign, and track leads through custom pipelines
- **Contacts & organizations** — full contact book with relationship mapping
- **Activity tracking** — calls, meetings, emails, notes linked to leads/contacts
- **Custom pipelines** — multiple pipeline stages per sales process
- **Custom attributes** — add custom fields to any entity
- **Email parsing** — inbound email → lead/activity via Sendgrid webhook
- **Admin dashboard** — overview of pipeline, activities, and conversions
- **Modular architecture** — extend via Laravel packages
- **Role-based access** — admin, agent, and custom roles
- **REST API** — JSON API for integrations
- **Multi-language** — i18n support

- Upstream repo: https://github.com/krayin/laravel-crm
- Homepage: https://krayincrm.com/
- Docs: https://devdocs.krayincrm.com/
- Demo: https://demo.krayincrm.com/

## Architecture

- **PHP 8.3+** + Laravel framework
- **Vue.js** frontend (SPA admin panel)
- **MySQL / MariaDB** — primary database
- **Redis** — recommended for queue and cache
- **Nginx** or Apache
- **Composer** — dependency management
- **Queue worker** — for async jobs (email parsing, notifications)

## Compatible install methods

| Infra         | Runtime                       | Notes                                        |
|---------------|-------------------------------|----------------------------------------------|
| VPS/Dedicated | LEMP + Composer install       | Standard path; PHP 8.3+ required             |
| Docker        | Docker Compose (official docs)| Quickest setup; see devdocs.krayincrm.com    |
| Shared hosting| Not recommended               | Requires CLI access for queue workers        |

## Inputs to collect

| Input          | Example                     | Phase    | Notes                                              |
|----------------|-----------------------------|----------|----------------------------------------------------|
| Domain         | `crm.example.com`           | URL      | SSL recommended                                    |
| DB credentials | MySQL host + name + creds   | DB       |                                                    |
| Mail config    | SMTP or Sendgrid             | Mail     | For outbound emails + inbound parsing              |
| Admin email    | `admin@example.com`         | Install  | First admin account                                |
| App key        | auto-generated               | Config   | `php artisan key:generate`                         |

## Install (Composer)

```sh
composer create-project krayin/laravel-crm

cd laravel-crm
cp .env.example .env
# Edit .env: DB_*, MAIL_*, APP_URL

php artisan key:generate
php artisan migrate --seed
php artisan storage:link

# Set web root to public/
# Start queue worker
php artisan queue:work
```

See https://devdocs.krayincrm.com/ for step-by-step setup including Docker path.

## Docker install

```sh
git clone https://github.com/krayin/laravel-crm.git
cd laravel-crm
cp .env.example .env
# Edit .env for your config
docker compose up -d
```

## Data & config layout

- **`.env`** — all config (DB, mail, queue, app key, URL)
- **`storage/`** — uploads, logs, cache; mount as Docker volume
- **MySQL DB** — all CRM data
- **`public/`** — web root; Nginx/Apache point here

## Upgrade

```sh
git pull
composer install --no-dev
php artisan migrate
php artisan cache:clear
php artisan config:cache
php artisan view:clear
sudo supervisorctl restart queue-worker
```

## Gotchas

- **Queue worker is required** — email parsing, notifications, and async jobs depend on the Laravel queue. Without a running worker (`php artisan queue:work`), these silently don't happen. Use Supervisor to keep it running.
- **PHP 8.3+ required** — check your hosting PHP version before installing. PHP 8.1/8.2 may work but 8.3 is recommended for v2.x.
- **Email parsing requires Sendgrid** — inbound email-to-lead features use Sendgrid's inbound parse webhook. If you don't use Sendgrid, this feature won't work (SMTP outbound still works with any provider).
- **Storage permissions** — `storage/` and `bootstrap/cache/` must be writable by the web server user. `chmod -R 775 storage bootstrap/cache` is the standard fix.
- **Custom attributes are powerful but not migrated automatically** — adding custom attributes is done through the UI; they're stored in DB. Backup before schema changes.
- **Redis recommended** — file-based queue and cache work but Redis significantly improves performance under load.
- **Not a full ERP** — Krayin is CRM-focused. It doesn't have inventory, invoicing, or project management built-in. If you need those, look at ERPNext (Frappe) or Odoo.
- **Alternatives:** Twenty (modern open-source CRM, TypeScript), SuiteCRM (Salesforce-style, PHP), EspoCRM (PHP, lightweight), Odoo CRM (part of Odoo ERP suite), HubSpot CRM (SaaS free tier).

## Links

- Repo: https://github.com/krayin/laravel-crm
- Homepage: https://krayincrm.com/
- Documentation: https://devdocs.krayincrm.com/
- Docker docs: https://devdocs.krayincrm.com/2.0/introduction/docker.html
- Demo: https://demo.krayincrm.com/
- Forums: https://forums.krayincrm.com/
- Releases: https://github.com/krayin/laravel-crm/releases
