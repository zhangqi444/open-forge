---
name: cloudlog
description: Cloudlog recipe for open-forge. Self-hosted PHP application for logging amateur radio contacts (QSOs). Access from any browser. Upstream: https://github.com/magicbug/Cloudlog
---

# Cloudlog

Self-hosted web application for logging amateur radio contacts (QSOs). Access from any browser with an internet connection. Used by ham radio operators for contest logging, DXpeditions, and day-to-day contact logging. Supports LOTW, ClubLog, eQSL upload, band/mode tracking, awards tracking, and more. Upstream: <https://github.com/magicbug/Cloudlog> — MIT.

Built on PHP + MySQL/MariaDB + Apache/Nginx.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Manual PHP install | <https://github.com/magicbug/Cloudlog/wiki> | Yes | Recommended. Standard LAMP/LEMP stack. |
| Docker Compose | Community | Community | Note: upstream explicitly does not support Docker in production. Use for dev/testing only. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | Database name, user, password | Free-text / sensitive | All |
| db | Database host (default: localhost) | Free-text | All |
| admin | Admin callsign (used as username) | Free-text | All |
| admin | Admin password | Sensitive | All |
| station | Your amateur radio callsign | Free-text | First-run config |
| station | Your grid locator (e.g. IO91wm) | Free-text | First-run config |
| smtp | SMTP settings for email notifications | Free-text | Optional |

## Manual PHP install

Requirements: PHP 7.4–8.2, MySQL 5.7+ or MariaDB, Apache (recommended) or Nginx, 100 MB disk space.

```bash
# Clone the repository
git clone https://github.com/magicbug/Cloudlog.git /var/www/html/cloudlog
cd /var/www/html/cloudlog

# Set permissions
chown -R www-data:www-data /var/www/html/cloudlog
chmod -R 755 /var/www/html/cloudlog
chmod -R 777 /var/www/html/cloudlog/{application/logs,application/cache,uploads}

# Create MySQL database
mysql -u root -p << SQL
CREATE DATABASE cloudlog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'cloudlog'@'localhost' IDENTIFIED BY 'REPLACE_DB_PASSWORD';
GRANT ALL PRIVILEGES ON cloudlog.* TO 'cloudlog'@'localhost';
FLUSH PRIVILEGES;
SQL

# Copy config
cp application/config/database.php.example application/config/database.php
# Edit database.php with your DB credentials
nano application/config/database.php

# Point your web server root at /var/www/html/cloudlog
# Navigate to http://<host>/cloudlog to run the installer
```

Apache VirtualHost should have `AllowOverride All` to enable `.htaccess` rewriting.

## Docker Compose (development/testing only)

```yaml
version: "3.8"

services:
  cloudlog-db:
    image: mariadb:10.11
    container_name: cloudlog-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ROOT_PASSWORD
      MYSQL_DATABASE: cloudlog
      MYSQL_USER: cloudlog
      MYSQL_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - cloudlog_db:/var/lib/mysql

  cloudlog:
    image: ghcr.io/magicbug/cloudlog:latest
    container_name: cloudlog
    restart: unless-stopped
    depends_on:
      - cloudlog-db
    ports:
      - "8080:80"
    environment:
      DB_HOST: cloudlog-db
      DB_NAME: cloudlog
      DB_USER: cloudlog
      DB_PASS: REPLACE_DB_PASSWORD
    volumes:
      - cloudlog_uploads:/var/www/html/uploads

volumes:
  cloudlog_db:
  cloudlog_uploads:
```

Note: upstream does not provide support for Docker deployments.

## Key features

- **Logbook:** Log QSOs with date/time, callsign, band, mode, RST, name, QTH, notes
- **Awards tracking:** DXCC, WAZ, WAS, IOTA, SOTA
- **Upload to log aggregators:** Logbook of The World (LOTW), ClubLog, eQSL
- **Club log API:** Real-time match logging
- **Propagation data:** Integrated propagation and band condition widgets
- **API:** REST API for external tools (rig control software, etc.)
- **Contest logging:** Support for common contest formats
- **Online/offline sync:** Designed to work from the field with spotty connectivity

## Upgrade procedure

```bash
cd /var/www/html/cloudlog
git pull origin master
# Visit http://<host>/cloudlog to run any DB migrations via the update wizard
```

For Docker:
```bash
docker compose pull cloudlog
docker compose up -d cloudlog
```

## Gotchas

- **UTF-8mb4 required.** The database must use `utf8mb4` charset. Special characters in callsigns and notes (e.g. Japanese, Cyrillic) will corrupt with `latin1` or basic `utf8`.
- **Apache `.htaccess` must be allowed.** Without `AllowOverride All`, URL rewriting breaks and you get 404 errors on all pages except the root.
- **Uploads directory must be writable.** ADIF imports, avatar images, and exported logs are stored in `/uploads`.
- **LOTW integration requires a certificate.** Setting up LOTW upload requires your TQSL credentials and a signed certificate from the ARRL. See the Cloudlog wiki for the setup process.
- **Branch tracking.** The main branch is `master`. Use `git pull origin master` — do not use `main`.
- **Docker is community/experimental.** Upstream explicitly notes they don't support Docker in production and won't troubleshoot Docker issues.

## Upstream docs

- GitHub: <https://github.com/magicbug/Cloudlog>
- Wiki (installation + features): <https://github.com/magicbug/Cloudlog/wiki>
- Demo: <https://demo.cloudlog.co.uk>
