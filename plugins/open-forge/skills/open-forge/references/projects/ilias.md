---
name: ilias
description: ILIAS recipe for open-forge. Powerful open source Learning Management System (LMS) for e-learning, training, and course management. PHP/MySQL web app with Apache. Used by universities and enterprises. Source: https://github.com/ILIAS-eLearning/ILIAS
---

# ILIAS

Powerful open source Learning Management System (LMS) designed for e-learning, corporate training, and higher education. Features include courses, learning modules, tests and assessments, SCORM/xAPI content, wikis, forums, portfolios, webinars, competence management, and a configurable RBAC permission system. Built on PHP 8.3+ with MySQL/MariaDB and Apache/nginx. Used by universities and enterprises worldwide. GPLv3. Upstream: https://github.com/ILIAS-eLearning/ILIAS. Docs: https://docs.gibbonedu.org (see ILIAS docs: https://www.ilias.de/docu/).

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| LAMP/LEMP stack (source/release tarball) | Linux (Debian/Ubuntu recommended) | Standard install; see official install guide |
| Docker (community images) | Linux | No official Docker image; community images exist |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "MySQL/MariaDB host / database / user / password?" | Standard MySQL credentials |
| web | "Domain / base URL?" | e.g. https://lms.example.com |
| admin | "ILIAS root admin password?" | Set via password-reset on first login |
| storage | "Data directory path?" | Outside web root; default: /var/iliasdata |
| smtp | "SMTP host/user/password?" | For notifications, password reset |

## Software-layer concerns

### System requirements (ILIAS 11)

  # OS: Debian 12 / Ubuntu 22.04+
  # PHP: 8.3 or 8.4 (with extensions: pdo_mysql, gd, curl, xml, zip, mbstring, intl, soap)
  # MySQL 8.0.21+ or MariaDB 10.5–11.8
  # Apache 2.4+ or nginx 1.12+
  # Java OpenJDK 11/17/21 (for some features like LaTeX rendering)
  # Node.js 22+ (for asset compilation)
  # Imagemagick 6.9+
  # Ghostscript 10+
  # RAM: 4 GB minimum; 8 GB+ recommended

### Install PHP and dependencies (Ubuntu 22.04)

  sudo apt install php8.3 php8.3-{pdo,mysql,gd,curl,xml,zip,mbstring,intl,soap,bcmath,opcache} \
    apache2 mysql-server imagemagick ghostscript openjdk-17-jre-headless

### Download ILIAS release

  # Get latest release from https://github.com/ILIAS-eLearning/ILIAS/releases
  cd /var/www
  wget https://github.com/ILIAS-eLearning/ILIAS/archive/refs/tags/v11.0.tar.gz
  tar xzf v11.0.tar.gz
  mv ILIAS-11.0 ilias
  chown -R www-data:www-data /var/www/ilias

### Create data directory (outside web root)

  sudo mkdir -p /var/iliasdata /var/iliasdata/client
  sudo chown -R www-data:www-data /var/iliasdata

### MySQL setup

  CREATE DATABASE ilias CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER 'ilias'@'localhost' IDENTIFIED BY 'secret';
  GRANT ALL PRIVILEGES ON ilias.* TO 'ilias'@'localhost';
  FLUSH PRIVILEGES;

### Apache vhost

  <VirtualHost *:443>
      ServerName lms.example.com
      DocumentRoot /var/www/ilias

      <Directory /var/www/ilias>
          AllowOverride All
          Options FollowSymLinks
          Require all granted
      </Directory>

      # Block direct access to sensitive dirs:
      <Directory /var/www/ilias/data>
          Require all denied
      </Directory>
  </VirtualHost>

  # Enable: a2enmod rewrite ssl headers && a2ensite ilias

### nginx example

  server {
      listen 443 ssl;
      server_name lms.example.com;
      root /var/www/ilias;
      index index.php;

      location / { try_files $uri $uri/ /index.php?$query_string; }
      location ~ \.php$ {
          fastcgi_pass unix:/run/php/php8.3-fpm.sock;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_name;
          include fastcgi_params;
      }
  }

### Web installer

  # Navigate to https://lms.example.com/setup/setup.php
  # Complete the setup wizard:
  # - Database connection
  # - Data directory path (/var/iliasdata)
  # - Client ID and name
  # - Admin password (set via "Forgot password" on first login as "root")

### Key config file

  /var/www/ilias/ilias.ini.php   # Main config (created by installer)
  /var/iliasdata/                # User files, uploads, temp files

### Ports

  80/tcp  443/tcp   # Web UI via Apache/nginx

### Cron jobs

  # ILIAS requires a cron job for background tasks (notifications, reports, etc.)
  # Add to /etc/cron.d/ilias:
  * * * * * www-data php /var/www/ilias/cron/cron.php root <client_id> >> /var/log/ilias-cron.log 2>&1

  # Replace <client_id> with the client ID set during installation.

## Upgrade procedure

  # 1. Back up database: mysqldump ilias > ilias_backup.sql
  # 2. Back up /var/iliasdata/
  # 3. Download new release tarball and extract over existing install (preserve ilias.ini.php)
  # 4. Navigate to /setup/setup.php and run the database update
  # 5. See: https://github.com/ILIAS-eLearning/ILIAS/blob/master/docs/configuration/install.md#upgrading-ilias

## Gotchas

- **PHP 8.3/8.4 required**: ILIAS 11 requires PHP 8.3 or 8.4. Older PHP versions will not work.
- **Java required for some features**: LaTeX rendering and some other features need OpenJDK 11/17/21. Install even if you don't plan to use LaTeX — it prevents errors.
- **Data directory outside web root**: `/var/iliasdata` (or wherever you put it) must be outside the Apache/nginx document root for security. The installer will warn you if it isn't.
- **Cron is mandatory**: Background tasks (notifications, certificate generation, search indexing) require the cron job. Without it, many features silently fail.
- **Root user password reset**: The initial "root" admin account password is set via the "Forgot Password" function on the login page after installation. There's no installer step for it.
- **Heavy system requirements**: ILIAS is a full-featured LMS with many optional components. On a loaded system with many users, plan for 8+ GB RAM and SSD storage.
- **No official Docker image**: There's no official Docker image. Use the Debian/Ubuntu package install. Community Docker images exist but may lag behind releases.
- **Plugin compatibility**: Plugins must match the ILIAS version. Check compatibility before installing third-party plugins.

## References

- Upstream GitHub: https://github.com/ILIAS-eLearning/ILIAS
- Installation guide: https://github.com/ILIAS-eLearning/ILIAS/blob/master/docs/configuration/install.md
- Website: https://www.ilias.de
- Documentation: https://www.ilias.de/docu/
- Plugin repository: https://www.ilias.de/docu/goto.php?target=cat_1442&client_id=docu
