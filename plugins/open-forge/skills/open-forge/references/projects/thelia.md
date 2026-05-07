---
name: Thelia
description: Open-source, flexible e-commerce solution built on PHP/Symfony. Full-featured online store platform with modules, hooks, templates, and REST API. LGPL-3.0.
website: https://thelia.net/
source: https://github.com/thelia/thelia
license: LGPL-3.0
stars: 873
tags:
  - ecommerce
  - shop
  - symfony
  - php
platforms:
  - PHP
  - Docker
---

# Thelia

Thelia is an open-source e-commerce platform built on PHP and Symfony. It provides a full-featured online store with product management, order processing, customer accounts, payment/shipping modules, and a templating engine. It's designed for flexibility via its hook and module system, and includes a REST API for headless use.

Official site: https://thelia.net/  
Source: https://github.com/thelia/thelia  
Docs: https://docs.thelia.net/  
Latest release: v2.6.x

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | PHP 7.4+ + MySQL/MariaDB + Nginx | Recommended for production |
| Any Linux VM / VPS | Docker (Nginx + PHP-FPM + MariaDB) | Official Docker dev setup available |
| Shared hosting | PHP 7.4+ + MySQL | Works on standard LAMP hosts |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- MySQL/MariaDB credentials (host, database, user, password, root password)
- PHP version (7.4+ required; 8.x recommended)
- Store currency and locale
- Admin email address

**Phase: First Boot**
- Admin username and password (set during web install wizard)
- Store name, currency, language

## Software-Layer Concerns

**Docker Compose (development):**
```yaml
version: "3.7"
services:
  mariadb:
    image: mariadb:10.3
    volumes:
      - thelia_db:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: CHANGE_ME_ROOT
      MYSQL_DATABASE: thelia
      MYSQL_USER: thelia
      MYSQL_PASSWORD: CHANGE_ME

  webserver:
    image: nginx:alpine
    volumes:
      - ./:/application
      - ./.docker/nginx/nginx.conf:/etc/nginx/conf.d/default.conf
    ports:
      - 8080:80
    depends_on:
      - php-fpm

  php-fpm:
    image: php:8.1-fpm
    volumes:
      - ./:/application
    depends_on:
      - mariadb

volumes:
  thelia_db:
```

**Install from Composer:**
```bash
composer create-project thelia/thelia-project /var/www/thelia
cd /var/www/thelia
# Configure database in local/config/database.yml
# Run install wizard: http://yoursite.com/install
```

**Key config:**
- Database: `local/config/database.yml`
- App config: `local/config/`
- Templates: `templates/`
- Modules: `local/modules/`

**Web server (Nginx):**
```nginx
server {
    listen 80;
    server_name shop.example.com;
    root /var/www/thelia/web;
    index index.php index.html;

    location / {
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Data paths:**
- Media/uploads: `web/assets/`
- Logs: `log/`
- Cache: `cache/`

## Upgrade Procedure

1. Back up database and `local/` + `web/assets/` directories
2. `composer update` in project directory
3. Run database migrations: `php Thelia thelia:update`
4. Clear cache: `php Thelia cache:clear`
5. Check migration notes: https://github.com/thelia/thelia/releases

## Gotchas

- **Symfony-based**: Familiarity with Symfony framework helps for custom module development
- **Module ecosystem**: Payment (Stripe, PayPal), shipping, and feature modules available at https://thelia.net/module — quality varies
- **PHP version**: Officially supports PHP 7.4–8.1; PHP 8.2+ may require testing
- **Not as popular as WooCommerce/PrestaShop**: Smaller community and ecosystem; finding ready-made modules may be harder
- **French origins**: Primarily developed in France; community and some docs are French-first, though English docs exist
- **LGPL-3.0**: Allows use in proprietary projects without forcing LGPL on your code (as long as Thelia itself is unmodified)

## Links

- Upstream README: https://github.com/thelia/thelia/blob/master/README.md
- Documentation: https://docs.thelia.net/
- Module marketplace: https://thelia.net/module
- Docker setup: https://github.com/thelia-labs/thelia-docker
- Releases: https://github.com/thelia/thelia/releases
