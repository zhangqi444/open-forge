---
name: elgg
description: Elgg recipe for open-forge. Open source social networking engine and rapid development framework for socially aware web applications. Powers community platforms, intranets, and social networks. Source: https://github.com/Elgg/Elgg
---

# Elgg

Open source social networking engine and PHP framework for building socially aware web applications. Provides user profiles, groups, activity streams, notifications, file storage, plugins, and a REST API out of the box. Used as the foundation for community platforms, intranets, and custom social networks. Over 1000 community plugins available. Upstream: https://github.com/Elgg/Elgg. Docs: https://learn.elgg.org.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Composer + web server | PHP 8.1+ + MySQL/MariaDB | Recommended. Standard Composer-based PHP app install. |
| Manual (archive) | PHP 8.1+ + MySQL/MariaDB | Download release archive, configure, run web installer. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Domain name?" | e.g. social.example.com |
| database | "MySQL/MariaDB credentials?" | Database name, user, password, host |
| setup | "Admin username, email, password?" | Created in web installer |
| storage | "Data directory path?" | Outside web root — for user-uploaded files |

## Software-layer concerns

### Requirements

  PHP 8.1+
  PHP extensions: gd, mbstring, pdo_mysql, xml, intl, json, fileinfo, openssl
  MySQL 5.7+ or MariaDB 10.3+
  Web server: Apache (mod_rewrite) or nginx

### Composer install

  # Create project directory
  composer create-project elgg/starter-project:* my-elgg-site
  cd my-elgg-site

  # Set document root to the public/ directory in your web server config
  # Create a writable data directory OUTSIDE the web root:
  mkdir /var/elgg-data && chown www-data:www-data /var/elgg-data

  # Visit your site URL to run the web installer:
  # http://your-domain.com/install.php

### Web installer steps

1. Check requirements (page 1)
2. Set database credentials (MySQL/MariaDB connection)
3. Set site URL and data directory path
4. Create admin account
5. Complete — site is ready

### Apache configuration

  <VirtualHost *:80>
    ServerName social.example.com
    DocumentRoot /var/www/my-elgg-site/public
    <Directory /var/www/my-elgg-site/public>
      AllowOverride All
      Require all granted
    </Directory>
  </VirtualHost>

  # mod_rewrite is required:
  a2enmod rewrite

### nginx configuration

  server {
    listen 80;
    server_name social.example.com;
    root /var/www/my-elgg-site/public;
    index index.php;
    location / {
      try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
      fastcgi_pass unix:/run/php/php8.2-fpm.sock;
      fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
      include fastcgi_params;
    }
  }

### Data directory

The data directory (outside web root) stores:
  - User uploaded files
  - Cached views
  - System logs

Must be writable by the web server and NOT web-accessible.

### Plugins

Install plugins via Admin > Plugin manager. Browse plugins at: https://elgg.org/plugins/

Or install via Composer:
  composer require elgg/<plugin-name>

## Upgrade procedure

  composer update
  # Run database migrations:
  php vendor/bin/elgg-cli upgrade async
  # Clear caches: Admin > Develop > Flush Caches

## Gotchas

- **Data directory outside web root**: if the data directory is inside the web root, private files may be publicly accessible. Always place it outside.
- **mod_rewrite (Apache)**: clean URLs require mod_rewrite with AllowOverride All. Without it, only the homepage works.
- **PHP memory**: Elgg benefits from 256MB+ PHP memory limit for heavy pages with many plugins.
- **File permissions**: the data directory must be writable by the web server user (www-data / nginx / apache).
- **Caching**: for production, enable Elgg's built-in caching and optionally configure Redis/Memcache for sessions.
- **Plugin compatibility**: community plugins may not all support the latest Elgg version (7.x). Check plugin compatibility before installing.

## References

- Upstream GitHub: https://github.com/Elgg/Elgg
- Documentation: https://learn.elgg.org
- Plugin directory: https://elgg.org/plugins/
- Community: https://community.elgg.org
