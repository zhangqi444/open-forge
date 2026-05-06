---
name: gibbon
description: Gibbon recipe for open-forge. Flexible open source school management platform for teachers, students, parents, and school leaders. PHP/MySQL web app covering timetabling, attendance, markbook, units, planner, communication, and more. Extensible via modules. Source: https://github.com/GibbonEdu/core
---

# Gibbon

Flexible open source school management platform designed for teachers, students, parents, and school leaders. Covers daily school operations: timetabling, attendance tracking, markbook/gradebook, lesson planning, unit management, student reporting, messaging, and parent portal. Built on PHP with MySQL. Extensible via community modules and themes. Used by international schools worldwide. No official Docker image; standard LAMP/LEMP stack deployment. Upstream: https://github.com/GibbonEdu/core. Docs: https://docs.gibbonedu.org. GPLv3.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| LAMP/LEMP stack (Apache/nginx + PHP + MySQL) | Linux | Standard and recommended |
| Shared hosting (cPanel) | cPanel / Plesk | PHP + MySQL host required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "MySQL host / database name / user / password?" | Standard MySQL credentials |
| db | "MySQL root or admin user?" | For initial schema setup |
| web | "Domain / base URL?" | e.g. https://school.example.com |
| admin | "Admin (gibbonAdmin) email and password?" | Set during web installer |
| locale | "Country and locale?" | e.g. United Kingdom, en_GB |
| smtp | "SMTP host/user/password?" | For notifications and reports |

## Software-layer concerns

### Prerequisites

  # PHP 8.1+ with extensions:
  #   pdo_mysql, curl, gd, gettext, iconv, json, mbstring, xml, zip, intl
  # MySQL 8+ (or MariaDB 10.4+)
  # Apache (mod_rewrite) or nginx
  # Composer (optional; for cutting-edge installs)

### Install from release package (recommended)

  # Download latest release from https://gibbonedu.org/download/
  # or from GitHub releases:
  cd /var/www
  wget https://github.com/GibbonEdu/core/archive/refs/tags/v26.0.00.tar.gz
  tar xzf v26.0.00.tar.gz
  mv core-26.0.00 gibbon
  chown -R www-data:www-data /var/www/gibbon

### MySQL setup

  CREATE DATABASE gibbon CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER 'gibbon'@'localhost' IDENTIFIED BY 'secret';
  GRANT ALL PRIVILEGES ON gibbon.* TO 'gibbon'@'localhost';
  FLUSH PRIVILEGES;

### Web server — nginx example

  server {
      listen 80;
      server_name school.example.com;
      root /var/www/gibbon;
      index index.php;

      location / {
          try_files $uri $uri/ /index.php?$query_string;
      }

      location ~ \.php$ {
          fastcgi_pass unix:/run/php/php8.1-fpm.sock;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_name;
          include fastcgi_params;
      }

      location ~* \.(jpg|jpeg|png|gif|css|js|ico|woff2?)$ {
          expires 30d;
      }
  }

### Apache (mod_rewrite required)

  # .htaccess is included in the repo
  # Ensure AllowOverride All is set for the document root
  # a2enmod rewrite && systemctl reload apache2

### Web installer

  # Navigate to http://school.example.com/installer/install.php
  # Enter:
  # - Database credentials
  # - Base URL
  # - Admin account details
  # - School country and locale
  # - SMTP settings
  # The installer creates all tables and the initial admin account.

### config.php (created by installer)

  <?php
  $databaseServer = 'localhost';
  $databaseUsername = 'gibbon';
  $databasePassword = 'secret';
  $databaseName = 'gibbon';
  $guid = 'auto-generated-guid';
  ?>

### Key directories

  /var/www/gibbon/uploads/    # User uploads (profile photos, files) — make writable
  /var/www/gibbon/config.php  # Database config (created by installer)
  /var/www/gibbon/modules/    # Core and extension modules

### File permissions

  chmod -R 775 /var/www/gibbon/uploads
  chmod 640 /var/www/gibbon/config.php
  chown -R www-data:www-data /var/www/gibbon

### Ports

  80/tcp  443/tcp   # Web UI via Apache/nginx

### Cron jobs (required for notifications and reports)

  # Add to www-data crontab or /etc/cron.d/gibbon:
  */5 * * * * www-data php /var/www/gibbon/cron.php

## Upgrade procedure

  # 1. Back up database: mysqldump gibbon > gibbon_backup.sql
  # 2. Back up uploads/: cp -r /var/www/gibbon/uploads /backups/gibbon-uploads/
  # 3. Download new release and extract over existing install
  #    (preserve config.php and uploads/)
  # 4. Navigate to /installer/update.php to run database migrations
  # 5. Clear any opcode cache: systemctl restart php8.1-fpm

## Gotchas

- **Web installer required**: Unlike some apps, Gibbon must be configured via its web-based installer at `/installer/install.php`. Don't skip it.
- **No official Docker image**: Gibbon is a traditional PHP app. Use a LAMP/LEMP stack. Community Docker images exist but are unofficial.
- **Uploads directory**: Must be writable by the web server. Profile photos, student files, and attachments go here. Back it up.
- **Cron is required**: Many features (notifications, digest emails, report generation) depend on the cron job running every 5 minutes.
- **PHP memory limit**: Complex reports and large datasets may hit PHP's default memory limit. Set `memory_limit = 256M` in php.ini.
- **Modules extend functionality**: Additional modules (Library, Finance, Free Learning, etc.) are installed separately via `/admin/module.php`. Browse at https://gibbonedu.org/extend/.
- **Locale/language**: Gibbon supports many languages via POEditor translations. Set the school country and locale in the installer to get localized date formats, currencies, etc.
- **config.php permissions**: Set to 640 (readable only by www-data) to protect database credentials.

## References

- Upstream GitHub: https://github.com/GibbonEdu/core
- Documentation: https://docs.gibbonedu.org
- Website: https://gibbonedu.org
- Download: https://gibbonedu.org/download/
- Modules/themes: https://gibbonedu.org/extend/
- Community support: https://ask.gibbonedu.org
