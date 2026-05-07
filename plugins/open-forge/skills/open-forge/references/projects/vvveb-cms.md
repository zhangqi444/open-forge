---
name: Vvveb CMS
description: Powerful CMS with drag-and-drop page builder for websites, blogs, and e-commerce stores. PHP + MySQL/SQLite/PostgreSQL. Hybrid traditional + Headless CMS with GraphQL/REST API. AGPL-3.0.
website: https://www.vvveb.com
source: https://github.com/givanz/Vvveb
license: AGPL-3.0
stars: 1048
tags:
  - cms
  - ecommerce
  - page-builder
  - headless-cms
platforms:
  - PHP
  - Docker
---

# Vvveb CMS

Vvveb CMS is a full-featured content management system with an integrated drag-and-drop page builder. It supports websites, blogs, and e-commerce stores out of the box. Key capabilities include multi-site support, localization, subscriptions, digital downloads, coupons, product variants, themes/plugins marketplace, and a Headless CMS mode with GraphQL and REST APIs.

Official site: https://www.vvveb.com  
Source: https://github.com/givanz/Vvveb  
Docs: https://docs.vvveb.com/  
Demo: https://demo.vvveb.com / Admin: https://demo.vvveb.com/admin  
Latest release: v1.0.8.1 (April 2026)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | PHP 8.3+ + MySQL/MariaDB | Recommended for production |
| Any Linux VM / VPS | PHP 8.3+ + SQLite | Good for development/small sites |
| Any Linux VM / VPS | PHP 8.3+ + PostgreSQL | Supported |
| Shared hosting | PHP 7.4+ + MySQL | Works; only one PHP file exposed publicly |
| Any Linux VM / VPS | Docker | No official image; community-maintained |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- Database type: MySQL/MariaDB, SQLite, or PostgreSQL
- Database credentials (host, user, password, database name)
- PHP version (7.4+ minimum, 8.3+ recommended)

**Phase: First Boot**
- Admin account username, password, email (entered during web setup)
- Site name and base URL

## Software-Layer Concerns

**Quick install:**
```bash
# Download release zip from https://vvveb.com/download.php
# or clone + build:
git clone --recurse-submodules https://github.com/givanz/Vvveb /var/www/vvveb
cd /var/www/vvveb
./build.sh    # produces vvveb.zip

# Extract to web root
unzip vvveb.zip -d /var/www/html/vvveb

# Open in browser → web-based installer runs automatically
# http://localhost/ or http://yourserver.com/
```

**No setup wizard required:** Just upload files and open in browser — the installer detects a fresh install and walks through database config + admin account creation.

**PHP requirements:**
```
PHP 7.4+ (8.3+ recommended)
Extensions: mysqli OR sqlite3 OR pgsql, xml, pcre, zip, dom, curl, gettext, gd or imagick
```

**Web server config (Nginx):**
```nginx
server {
    listen 80;
    server_name vvveb.example.com;
    root /var/www/html/vvveb;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Security model:** Only `index.php` is exposed to the public web root — all other code is above the web root. Includes brute force protection, SQL injection protection, and hidden admin login URL.

**Data paths:**
- Config: `config/config.php` (auto-generated during install)
- Uploads/media: `public/uploads/`
- Themes: `themes/`
- Plugins: `plugins/`

**Admin URL:** `http://yoursite.com/admin/` (can be customized for security)

## Upgrade Procedure

1. Back up database and `public/uploads/` directory
2. Download new release zip or `git pull --recurse-submodules`
3. Overwrite files (preserve `config/config.php` and `public/uploads/`)
4. Open admin → any pending DB migrations run automatically
5. Check release notes: https://github.com/givanz/Vvveb/releases

## Gotchas

- **Build step required from source**: Must run `./build.sh` after cloning (or use the pre-built release zip)
- **Submodules**: Uses git submodules — always clone with `--recurse-submodules` or run `git submodule update --recursive --remote` after pull
- **No official Docker image**: Must build your own or find community images
- **E-commerce licensing**: AGPL-3.0 applies; commercial/SaaS use requires review
- **Plugin marketplace**: Themes and plugins installable directly from admin dashboard (requires internet access from server)
- **Headless mode**: GraphQL and REST API available for decoupled frontends — see https://docs.vvveb.com/api
- **Very active**: 149 commits in June 2025, 85 in Feb 2026, 48 in April 2026 — expect frequent updates and occasional breaking changes

## Links

- Upstream README: https://github.com/givanz/Vvveb/blob/master/README.md
- Documentation: https://docs.vvveb.com/
- Live demo: https://demo.vvveb.com
- Admin demo: https://demo.vvveb.com/admin (user: admin / pass: admin)
- Releases: https://github.com/givanz/Vvveb/releases
