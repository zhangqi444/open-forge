---
name: uvdesk
description: UVDesk recipe for open-forge. Open-source PHP/Symfony helpdesk system with ticketing, email piping, multi-channel support, and a plugin/bundle architecture. Covers Composer install on LAMP/LEMP stack. Upstream: https://github.com/uvdesk/community-skeleton
---

# UVDesk Community Helpdesk

Open-source, service-oriented helpdesk system built on Symfony (PHP). Supports email-based ticket management, multi-channel support, agents/teams, workflows, and an extensible bundle/plugin architecture.

18,539 stars · MIT

Upstream: https://github.com/uvdesk/community-skeleton
Website: https://www.uvdesk.com/en/opensource/
Docs: https://docs.uvdesk.com/
Installation guide: https://www.uvdesk.com/en/blog/open-source-helpdesk-installation-on-ubuntu-uvdesk/

## What it is

UVDesk provides a complete helpdesk stack:

- **Ticket management** — Email piping, ticket creation, assignment, priorities, status workflows
- **Multi-channel** — Email, web forms; API-driven integrations for other channels
- **Agents & teams** — Role-based access, team assignments, agent collaboration
- **Automation & workflows** — Triggered actions based on ticket conditions
- **Knowledge base** — Article/FAQ management
- **Reports** — Ticket volume, agent performance
- **Extensible** — Symfony bundle architecture; official and community bundles for Shopify, Amazon, WooCommerce integrations

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Composer (recommended) | https://github.com/uvdesk/community-skeleton | Standard install on any PHP/MySQL server |
| Docker | Community Dockerfile available | Dev/testing |

This recipe covers the **Composer install** method.

## Requirements

- PHP 8.1 or higher
- PHP extensions: `curl`, `imap`, `mbstring`, `mysql`, `xml`, `zip`, `gd`
- MySQL 5.7+ or MariaDB 10.3+
- Composer 2.x
- Apache 2.4+ (`mod_rewrite`) or Nginx
- Web server writable directories: `var/`, `public/`

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "What domain will UVDesk be served on?" | All |
| db_name | "Database name for UVDesk?" | All |
| db_user | "Database user and password?" | All |
| admin_email | "Admin email address?" | All |
| admin_pass | "Admin password?" | All |
| mailer | "Outgoing mail: SMTP host, port, user, and password?" | All |

## Composer install

Upstream: https://docs.uvdesk.com/

### 1. Create project

    composer create-project uvdesk/community-skeleton helpdesk-app --stability=RC

    cd helpdesk-app

### 2. Configure environment

    cp .env .env.local

Edit `.env.local`:

    APP_ENV=prod
    APP_SECRET=<generate: openssl rand -hex 32>
    DATABASE_URL="mysql://db_user:db_pass@127.0.0.1:3306/uvdesk?serverVersion=8.0"
    MAILER_DSN=smtp://user:pass@smtp.example.com:587

### 3. Create the database and run migrations

    php bin/console doctrine:database:create
    php bin/console doctrine:migrations:migrate --no-interaction

### 4. Set permissions

    chmod -R 777 var/ public/assets/

### 5. Web server configuration

**Apache** virtual host:

    <VirtualHost *:80>
        ServerName helpdesk.example.com
        DocumentRoot /var/www/helpdesk-app/public

        <Directory /var/www/helpdesk-app/public>
            AllowOverride All
            Require all granted
            FallbackResource /index.php
        </Directory>
    </VirtualHost>

Enable `mod_rewrite`: `a2enmod rewrite && systemctl restart apache2`

**Nginx**:

    server {
        listen 80;
        server_name helpdesk.example.com;
        root /var/www/helpdesk-app/public;

        location / {
            try_files $uri /index.php$is_args$args;
        }

        location ~ ^/index\.php(/|$) {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_split_path_info ^(.+\.php)(/.*)$;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
            fastcgi_param DOCUMENT_ROOT $realpath_root;
            internal;
        }

        location ~ \.php$ { return 404; }
    }

### 6. Run the setup wizard

Open `http://helpdesk.example.com/en/member/setup` in a browser to complete setup:

1. Database configuration (pre-filled from .env.local)
2. Admin account creation
3. Website/helpdesk name
4. Email piping configuration

### 7. Configure email piping (incoming tickets)

Set up a mailbox that pipes to UVDesk:

    # Procmail / .forward method:
    php /var/www/helpdesk-app/bin/console uvdesk_mailbox:process-mail < /dev/stdin

Or configure IMAP polling in the admin panel under **Mailboxes**.

## Upgrade

    cd helpdesk-app
    composer update
    php bin/console doctrine:migrations:migrate --no-interaction
    php bin/console cache:clear

## Gotchas

- **`var/` must be writable** — Symfony writes cache and logs here. `chmod -R 777 var/` is required; narrow permissions to the web server user in production.
- **PHP `imap` extension** — Required for mailbox polling. Install with `apt install php8.2-imap` on Debian/Ubuntu.
- **Setup wizard at `/en/member/setup`** — The Composer install doesn't auto-run migrations for the admin account. You must visit the setup URL to create the first admin user.
- **`stability=RC`** — The project uses RC releases. Omitting `--stability=RC` may result in "no matching package" errors with strict Composer stability settings.
- **Cache must be cleared on deploy** — After any code or config change, run `php bin/console cache:clear --env=prod`.
- **HTTPS**: Configure TLS termination at Nginx/Apache. UVDesk itself has no built-in TLS.

## Links

- GitHub: https://github.com/uvdesk/community-skeleton
- Website: https://www.uvdesk.com/en/opensource/
- Docs: https://docs.uvdesk.com/
- Installation guide: https://www.uvdesk.com/en/blog/open-source-helpdesk-installation-on-ubuntu-uvdesk/
- All UVDesk packages: https://github.com/uvdesk
