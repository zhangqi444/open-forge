---
name: serendipity
description: Serendipity (s9y) recipe for open-forge. Highly extensible PHP blog engine using Smarty templates. PHP 8.4, MySQL/PostgreSQL/SQLite. BSD-3-Clause. Source: https://github.com/s9y/serendipity
---

# Serendipity (s9y)

Highly extensible and customizable PHP blog engine. Uses Smarty templating. Features articles, comments, trackbacks, pingbacks, webmentions, a plugin architecture, media library, multi-user support, categories, and 2FA login. Supports MySQL, PostgreSQL, and SQLite. PHP 8.4 supported as of v2.6.0. Active development since 2002. BSD-3-Clause licensed.

Upstream: https://github.com/s9y/serendipity | Website: https://docs.s9y.org | Demo: https://www.s9y.org/demos.html

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Apache2 + PHP + MySQL | Classic LAMP stack; mod_rewrite for clean URLs |
| Any | Nginx + PHP-FPM + MySQL | Also supported |
| Any | PHP + PostgreSQL | Supported |
| Any | PHP + SQLite | Supported (small sites) |
| Any | Docker (PHP + web server) | No official image; use php:8.4-apache |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Database type | MySQL, PostgreSQL, or SQLite |
| install | Database host, name, user, password | MySQL/PostgreSQL only |
| install | Admin username + password | Created during web installer |
| install | Blog name and URL | Base URL must be set correctly |
| config | PHP version | PHP 7.4+ required; 8.4 officially supported in v2.6.0 |
| config | Clean URLs | Requires mod_rewrite (Apache) or equivalent Nginx config |

## Software-layer concerns

- Smarty templates: themes are Smarty-based; thousands of community plugins and themes available
- Plugin system: extends functionality via the Serendipity Styx plugin repository (https://ophian.github.io/styx/)
- WebP/AVIF: media library supports WebP and AVIF since v2.6.0
- 2FA: optional email-based second factor for login (v2.6.0+)
- Security: v2.6.0 is also a security release fixing host header injection vulnerabilities -- upgrade older installations promptly

## Install -- Apache2 + PHP + MySQL

```bash
# Download latest release
wget https://github.com/s9y/Serendipity/releases/latest/download/serendipity-2.6.0.zip
unzip serendipity-2.6.0.zip -d /var/www/blog
chown -R www-data:www-data /var/www/blog
```

Apache vhost:

```apache
<VirtualHost *:80>
    ServerName blog.example.com
    DocumentRoot /var/www/blog
    <Directory /var/www/blog>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
a2enmod rewrite
systemctl restart apache2
# Navigate to http://blog.example.com/ -- web installer runs automatically
```

MySQL setup:

```sql
CREATE DATABASE serendipity CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 's9y'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON serendipity.* TO 's9y'@'localhost';
FLUSH PRIVILEGES;
```

## Install -- Docker (php:apache)

```yaml
services:
  serendipity:
    image: php:8.4-apache
    restart: unless-stopped
    ports:
      - 8080:80
    volumes:
      - ./serendipity:/var/www/html
    environment:
      APACHE_DOCUMENT_ROOT: /var/www/html

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: serendipity
      MYSQL_USER: s9y
      MYSQL_PASSWORD: yourpassword
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

Extract the Serendipity release into ./serendipity/ and enable required PHP extensions (pdo, pdo_mysql, gd, mbstring).

## Upgrade procedure

1. Back up the database and the entire blog directory
2. Download the new release ZIP
3. Extract over the existing installation (the web installer detects and performs DB migration)
4. Clear the Smarty template cache
5. Navigate to the admin panel -- if prompted, run the DB upgrade

## Gotchas

- v2.6.0 is a security release: if you're running an older version, upgrade now to fix host header injection vulnerabilities.
- AllowOverride All required: Serendipity uses .htaccess for clean URLs and security rules on Apache. Without AllowOverride All, many features break silently.
- Upload permissions: the uploads/ directory must be writable by the web server process.
- PHP extension requirements: gd, mbstring, pdo (+ pdo_mysql or pdo_pgsql), curl. Missing extensions cause cryptic installer failures.
- Plugin compatibility: older plugins may not be compatible with PHP 8.x. Test in staging before upgrading PHP.

## Links

- Source: https://github.com/s9y/serendipity
- Documentation: https://docs.s9y.org
- Releases: https://github.com/s9y/Serendipity/releases
- Plugin/theme repository: https://ophian.github.io/styx/
