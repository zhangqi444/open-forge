---
name: contao
description: Contao recipe for open-forge. Powerful open source PHP CMS for professional websites and scalable web applications, managed via GUI Contao Manager or Composer CLI. Built on Symfony with Doctrine. Source: https://github.com/contao/contao
---

# Contao

Powerful open source PHP/Symfony CMS for building professional websites and scalable web applications. Installable via the graphical Contao Manager (GUI-based, no CLI required) or via Composer on the command line. Actively maintained with long-term support releases. Backed by a commercial partner ecosystem. Upstream: https://github.com/contao/contao. Docs: https://docs.contao.org/. Demo: https://demo.contao.org/contao.

Note: the `contao/contao` GitHub repo is a development monorepo — use `contao/managed-edition` for production installs.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Contao Manager (GUI) | Linux / macOS / Windows | Recommended for non-developers. Web-based installer. |
| Composer CLI | Linux / macOS / Windows | For developers and automated deployments. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Database type + credentials?" | MySQL/MariaDB (recommended) or PostgreSQL |
| install | "PHP version?" | PHP 8.1+ required; 8.2+ recommended |
| install | "Site domain?" | e.g. https://example.com — set in Contao back end after install |
| install | "Admin username + password?" | Created during install wizard |
| optional | "Contao version?" | Latest LTS (currently 5.3.x) recommended for new sites |

## Software-layer concerns

### Method 1: Contao Manager (GUI)

  1. Download contao-manager.phar from https://contao.org/en/download.html
  2. Upload to your server's web root as contao-manager.phar.php
  3. Navigate to https://yourdomain.com/contao-manager.phar.php
  4. Follow the setup wizard to:
     - Configure PHP path and hosting settings
     - Install Contao (select version)
     - Set database credentials
  5. After install, navigate to https://yourdomain.com/contao/install
     to create the database schema and admin account.

### Method 2: Composer CLI

  composer create-project contao/managed-edition mysite "^5.3"
  cd mysite

  # Configure database in .env.local:
  DATABASE_URL=mysql://user:password@127.0.0.1:3306/contaodb?serverVersion=8.0

  # Run install tool to create DB schema + admin user:
  vendor/bin/contao-console contao:migrate
  vendor/bin/contao-console contao:user:create --admin

  # Or open the graphical install tool at:
  https://yourdomain.com/contao/install

### Key paths

  config/         # Application configuration
  files/          # User-uploaded content (managed by Contao)
  templates/      # Custom template overrides
  var/cache/      # Cache — clear on deploy
  var/logs/       # Application logs
  web/ or public/ # Web root (point your web server here)

### Web server setup

  # Nginx — web root: /path/to/mysite/public/ (Contao 5) or web/ (Contao 4)
  root /var/www/mysite/public;
  location / {
      try_files $uri /index.php$is_args$args;
  }

  # Required PHP extensions: pdo_mysql (or pdo_pgsql), gd, intl, zip, mbstring

### Clear cache

  vendor/bin/contao-console cache:clear --env=prod
  vendor/bin/contao-console contao:cache:clear-assets

### Cron (required for scheduled tasks)

  # Add to system crontab or Contao handles via web cron:
  * * * * * /usr/bin/php /path/to/mysite/vendor/bin/contao-console contao:cron

### Back end access

  https://yourdomain.com/contao   # Contao CMS back end

## Upgrade procedure

  # Via Contao Manager: open the manager UI and click "Update"

  # Via Composer:
  composer update contao/*
  vendor/bin/contao-console contao:migrate
  vendor/bin/contao-console cache:clear --env=prod

## Gotchas

- **Web root is `public/` (v5) or `web/` (v4)**: never point the web server at the project root.
- **Contao Manager ≠ Contao**: the Manager is a separate tool that manages Contao installs. Upload it once; it persists and handles future upgrades.
- **Extensions via Composer**: Contao extensions (bundles) are installed via Composer or the Contao Manager. Unlike WordPress, there is no one-click extension installer in the back end by default.
- **File manager syncing**: after uploading files via SFTP to the `files/` directory, run the "Synchronise file system" tool in the Contao back end so Contao registers the new files in its database.
- **PHP memory**: Contao recommends at least 256MB PHP memory limit for the back end. Image processing can require more.
- **Cron dependency**: scheduled publishing, newsletter sending, and automation depend on the Contao cron service being configured.

## References

- Upstream GitHub: https://github.com/contao/contao
- Managed Edition: https://github.com/contao/managed-edition
- Documentation: https://docs.contao.org/
- Contao Manager download: https://contao.org/en/download.html
- Installation guide: https://docs.contao.org/manual/en/installation/install-contao/
