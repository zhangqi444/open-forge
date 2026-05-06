---
name: suitecrm
description: SuiteCRM recipe for open-forge. Award-winning open-source enterprise CRM built on PHP/Apache/MySQL. Covers Docker Compose and manual LAMP install. Upstream: https://github.com/SuiteCRM/SuiteCRM
---

# SuiteCRM

Award-winning, enterprise-class open-source CRM built on PHP (fork of SugarCRM Community Edition). Provides a full sales, marketing, and support CRM with modules for leads, accounts, contacts, opportunities, campaigns, cases, and more.

5,410 stars · LGPL-3.0

Upstream: https://github.com/SuiteCRM/SuiteCRM
Website: https://suitecrm.com/
Docs: https://docs.suitecrm.com/
Installation guide: https://docs.suitecrm.com/admin/installation-guide/downloading-installing/
Docker: https://github.com/SuiteCRM/SuiteCRM-docker

## What it is

SuiteCRM provides a complete CRM platform:

- **Leads & Contacts** — Lead capture, nurturing, and conversion to contacts
- **Accounts & Opportunities** — Company accounts, deal pipeline, forecasting
- **Cases & Support** — Customer support ticketing and case management
- **Campaigns** — Email and direct mail marketing campaign management
- **Reports & Dashboards** — Custom reports, dashlets, analytics
- **Workflows** — Automated process flows and business rules
- **REST API** — JSON API v8 for integrations
- **Extension framework** — Module loader for plugins and customizations
- **Studio** — Point-and-click CRM customization (custom fields, layouts, relationships)
- **Multi-language** — Dozens of community-contributed translations

**SuiteCRM 7 vs 8**: SuiteCRM 7 is the mature, stable branch (PHP). SuiteCRM 8 is the newer Angular-based frontend (in active development, not yet feature-complete). This recipe covers SuiteCRM 7.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (recommended) | https://github.com/SuiteCRM/SuiteCRM-docker | Quickest production deploy |
| Manual LAMP | https://docs.suitecrm.com/admin/installation-guide/ | Shared hosting or existing LAMP stack |

## Requirements

- PHP 8.1–8.4
- MySQL 5.7+ or MariaDB 10.4+ (recommended)
- Apache 2.4+ or Nginx
- PHP extensions: `curl`, `gd`, `mbstring`, `pdo`, `pdo_mysql`, `xml`, `zip`, `imap`, `openssl`
- 2 GB RAM minimum; 4 GB recommended
- 500 MB disk for base install

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "Domain for SuiteCRM?" | All |
| db_pass | "MySQL root/app password?" | All |
| admin_user | "CRM admin username and password?" | All |
| smtp | "SMTP server for email sending?" | Optional |

## Docker install (recommended)

Upstream: https://github.com/SuiteCRM/SuiteCRM-docker

    git clone https://github.com/SuiteCRM/SuiteCRM-docker.git
    cd SuiteCRM-docker

    cp .env.example .env

Edit `.env`:

    DATABASE_ROOT_PASSWORD=rootpassword
    DATABASE_HOST=db
    DATABASE_NAME=suitecrm
    DATABASE_USER=suitecrm
    DATABASE_PASSWORD=suitecrmpassword
    SITE_URL=https://crm.example.com

    docker compose up -d

Access the web installer at http://localhost:8080 (or your domain).

### Docker Compose structure

The Docker Compose stack includes:
- `suitecrm` — PHP-Apache application container
- `db` — MySQL database
- (optional) `nginx` — Reverse proxy with TLS

## Manual LAMP install

Upstream: https://docs.suitecrm.com/admin/installation-guide/downloading-installing/

### 1. Install prerequisites

    apt install -y apache2 php8.2 php8.2-mysql php8.2-curl php8.2-gd \
      php8.2-mbstring php8.2-xml php8.2-zip php8.2-imap php8.2-intl \
      libapache2-mod-php8.2 mariadb-server

    a2enmod rewrite headers expires
    systemctl restart apache2

### 2. Create database

    mysql -u root -p << 'SQL'
    CREATE DATABASE suitecrm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER 'suitecrm'@'localhost' IDENTIFIED BY 'yourpassword';
    GRANT ALL PRIVILEGES ON suitecrm.* TO 'suitecrm'@'localhost';
    FLUSH PRIVILEGES;
    SQL

### 3. Download SuiteCRM

    cd /var/www/html
    wget https://suitecrm.com/download/suite-crm-zip/ -O suitecrm.zip
    unzip suitecrm.zip
    chown -R www-data:www-data SuiteCRM/
    chmod -R 755 SuiteCRM/
    chmod -R 775 SuiteCRM/cache/ SuiteCRM/upload/ SuiteCRM/custom/ SuiteCRM/modules/

    # Or download specific version from GitHub releases:
    # https://github.com/SuiteCRM/SuiteCRM/releases

### 4. Apache virtual host

    <VirtualHost *:80>
        ServerName crm.example.com
        DocumentRoot /var/www/html/SuiteCRM

        <Directory /var/www/html/SuiteCRM>
            Options FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>

### 5. Complete web installer

Open `http://crm.example.com` in a browser and follow the installer:
1. Verify requirements
2. Enter database credentials
3. Set admin username/password
4. Site URL and SMTP settings

## Scheduled tasks (cron)

SuiteCRM requires a cron job for background processing (email queue, reminders, reports):

    # Add to crontab for www-data user:
    * * * * * cd /var/www/html/SuiteCRM && php -f cron.php > /dev/null 2>&1

## Upgrade

1. Back up database and files
2. Download new release
3. Extract over existing installation (do not overwrite `config.php`)
4. Run upgrade wizard at `http://your-site/index.php?module=Administration&action=UpgradeWizard`

Full upgrade guide: https://docs.suitecrm.com/developer/upgrading/

## Gotchas

- **`AllowOverride All`** — SuiteCRM relies heavily on `.htaccess` files. Apache must have `AllowOverride All` in the virtual host config.
- **File permissions** — `cache/`, `upload/`, `custom/`, and `modules/` directories must be writable by the web server user. Permission errors are the #1 install issue.
- **PHP memory limit** — SuiteCRM recommends `memory_limit = 256M` in `php.ini`. Lower values cause timeouts on large operations.
- **Cron required** — Without cron, scheduled reports, email campaigns, and reminder notifications don't run.
- **SuiteCRM 7 vs 8** — SuiteCRM 8 has a new Angular frontend but is not yet feature-complete. SuiteCRM 7 is the recommended production choice.
- **LGPL license** — SuiteCRM core is LGPL. You can use it commercially; the license allows proprietary modules.

## Links

- GitHub: https://github.com/SuiteCRM/SuiteCRM
- Website: https://suitecrm.com/
- Docs: https://docs.suitecrm.com/
- Installation guide: https://docs.suitecrm.com/admin/installation-guide/downloading-installing/
- Docker: https://github.com/SuiteCRM/SuiteCRM-docker
- Community forum: https://community.suitecrm.com/
- Upgrade guide: https://docs.suitecrm.com/developer/upgrading/
