---
name: opencart
description: OpenCart recipe for open-forge. Free open-source PHP e-commerce platform. Covers traditional LAMP install (production) and Docker local development. Upstream: https://www.opencart.com / https://github.com/opencart/opencart
---

# OpenCart

Free open-source e-commerce shopping cart platform built on PHP and MySQL. Feature-rich online store with products, categories, customers, orders, payments, shipping, extensions, and themes.

8,106 stars · GPL-3.0

Upstream: https://github.com/opencart/opencart
Website: https://www.opencart.com
Docs: https://docs.opencart.com/

## What it is

OpenCart provides a complete e-commerce solution:

- Product and category management
- Multi-store support
- Payment gateway integrations (PayPal, Stripe, and many via extensions)
- Shipping method integrations
- Customer accounts and groups
- Order management, invoicing
- Discount codes and vouchers
- Extension/plugin marketplace
- Multi-language and multi-currency
- Admin dashboard with sales analytics

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Traditional LAMP (Apache/Nginx + PHP + MySQL) | https://docs.opencart.com/installation/ | Production on a VPS or dedicated server |
| Docker Compose (local dev) | https://github.com/opencart/opencart (README) | Local development only — uses Makefile |
| cPanel / Softaculous auto-installer | Hosting panel | Shared hosting — automated, not documented here |

## Requirements

- PHP 8.0 or higher
- MySQL 5.7+ or MariaDB 10.3+
- Apache with `mod_rewrite` enabled, or Nginx
- PHP extensions: curl, zip, zlib, gd, mbstring, xml, json

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "VPS/LAMP production or local Docker dev?" | All |
| domain | "What domain will the store run on?" | LAMP production |
| database | "Database name, user, and password for OpenCart?" | LAMP production |
| admin | "Admin username, password, and email?" | All |

## Traditional LAMP install (production)

Upstream install guide: https://docs.opencart.com/installation/

### 1. Download and extract

    wget https://github.com/opencart/opencart/releases/latest/download/opencart-*.zip
    unzip opencart-*.zip -d /tmp/opencart
    cp -r /tmp/opencart/upload/. /var/www/html/opencart/

### 2. Prepare config files

    cd /var/www/html/opencart
    cp config-dist.php config.php
    cp admin/config-dist.php admin/config.php

### 3. Set permissions

    chmod 777 config.php admin/config.php
    chmod 777 system/storage/
    chmod 777 image/

Tighten permissions after installation is complete.

### 4. Run the web installer

Navigate to http://yourdomain.com/opencart/install/ and follow the wizard. Provide:

- Database host, name, user, password
- Admin account credentials
- Store URL and name

### 5. Post-install security (REQUIRED)

    # Delete the install directory — CRITICAL, do not skip
    rm -rf /var/www/html/opencart/install/

Leaving the `/install/` directory accessible is a serious security vulnerability. The installer will warn you, but deletion is manual.

Tighten config file permissions:

    chmod 644 config.php admin/config.php

### Apache virtual host

    <VirtualHost *:80>
        ServerName store.example.com
        DocumentRoot /var/www/html/opencart

        <Directory /var/www/html/opencart>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>

Requires `mod_rewrite` enabled (`a2enmod rewrite`).

### Nginx configuration

    server {
        listen 80;
        server_name store.example.com;
        root /var/www/html/opencart;
        index index.php;

        location / {
            try_files $uri $uri/ @opencart;
        }

        location @opencart {
            rewrite ^/(.+)$ /index.php?_route_=$1 last;
        }

        location /admin {
            try_files $uri $uri/ /admin/index.php?$args;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/run/php/php8.1-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }

## Docker local development

Upstream: https://github.com/opencart/opencart (README — "Local Development with Docker")

Prerequisites: Docker Desktop and `make` installed.

    git clone https://github.com/opencart/opencart
    cd opencart
    make build

This starts a local PHP/MySQL dev stack. See the Makefile for available targets.

**Windows users**: Use WSL2 backend for Docker Desktop. Without WSL2, file system performance is unusable.

## Upgrade

1. Back up the database and all files (especially `config.php`, `admin/config.php`, `image/`, `system/storage/`)
2. Download the new release zip
3. Extract and copy files over the existing installation
4. Run the upgrade script at `/install/upgrade.php` via browser
5. Delete `/install/` after upgrade completes

Changelog: https://github.com/opencart/opencart/blob/master/CHANGELOG.md

## Gotchas

- **Delete `/install/` after setup** — leaving it accessible is a critical security risk. This is the single most important post-install step.
- **PHP 8.0+ required** — PHP 7.x will cause errors. Check your hosting environment before installing.
- **Windows Docker dev**: Must use WSL2 backend — file system performance without it makes the app nearly unusable.
- **GPL-3.0 but marketplace extensions vary** — official OpenCart extensions and themes may use proprietary licenses. Verify before commercial use.
- **Latest release**: 3.0.5.0 (December 2025). Check GitHub releases for the current version.
- **Extensions**: Third-party extensions are installed via the admin extension installer or by extracting to the appropriate directory; quality and compatibility vary widely.
- **Storage directory**: `system/storage/` must be writable for caching, sessions, and uploads. Consider moving it outside the web root for security.

## Links

- GitHub: https://github.com/opencart/opencart
- Website: https://www.opencart.com
- Docs: https://docs.opencart.com/
- Install guide: https://docs.opencart.com/installation/
- Extension marketplace: https://www.opencart.com/index.php?route=marketplace/extension
- Changelog: https://github.com/opencart/opencart/blob/master/CHANGELOG.md
