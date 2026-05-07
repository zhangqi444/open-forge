---
name: projeqtor-project
description: ProjeQtOr recipe for open-forge. Mature open-source project management system in PHP/MySQL. Covers Docker Compose and manual PHP install. Based on upstream site https://www.projeqtor.org and AGPL-3.0 source at SourceForge.
---

# ProjeQtOr

Complete, mature, multi-user project management system covering all phases of a project: tasks, milestones, risks, issues, budget, resources, and reporting. PHP-based, MySQL/MariaDB backend. AGPL-3.0. Upstream: https://www.projeqtor.org. Source: https://sourceforge.net/p/projectorria/code/HEAD/tree/branches/. Demo: https://demo.projeqtor.org/.

ProjeQtOr has been in active development for 15+ years and supports Gantt charts, resource planning, budget tracking, risk registers, test cases, and ticketing — making it suitable as a full PMO tool for small to mid-size teams.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (community image) | Quickest containerised start |
| Manual PHP + MySQL | Full control on existing LAMP/LEMP server |
| Windows installer | Windows-only desktop/server install |

Note: ProjeQtOr does not maintain an official Docker image. Community images exist on Docker Hub (e.g. Nouuu/Docker-Projeqtor). Always verify image freshness against the upstream version at https://www.projeqtor.org/en/download.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method?" | Docker / PHP manual / Windows | Drives which section to follow |
| database | "MySQL root password?" | Free-text (sensitive) | For initial DB setup |
| database | "ProjeQtOr DB name / user / password?" | Three values | DB created during first-run wizard |
| config | "Admin email?" | email | Set during first-run web wizard |
| smtp | "SMTP server details?" | host, port, user, pass | For notifications and alerts |
| network | "Port to expose?" | Number (default 80) | HTTP port |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP 8.x |
| Database | MySQL 8.x or MariaDB 10.x |
| Web server | Apache (default in official packages and community Docker) |
| Config file | parameters.php in the projeqtor root — written by the setup wizard |
| Data directory | files/ subdirectory — stores uploaded attachments; must be writable |
| Cron | Requires a cron job for alerts, reminders, and scheduled tasks |
| Ports | HTTP 80 (or 443 behind reverse proxy) |
| PHP extensions required | pdo_mysql, gd, zip, mbstring, curl, ldap (optional) |

## Install: Docker Compose (community image)

Note: No official ProjeQtOr Docker image exists. The example below uses a community image. Verify the image version matches the upstream release at https://www.projeqtor.org/en/download before deploying.

```yaml
services:
  projeqtor:
    image: jbl2024/projeqtor:latest
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_NAME=projeqtor
      - DB_USER=projeqtor
      - DB_PASSWORD=changeme
    volumes:
      - projeqtor-files:/var/www/html/files
    depends_on:
      - db

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_DATABASE=projeqtor
      - MYSQL_USER=projeqtor
      - MYSQL_PASSWORD=changeme
    volumes:
      - mysql-data:/var/lib/mysql

volumes:
  projeqtor-files:
  mysql-data:
```

```bash
docker compose up -d
# Visit http://localhost — complete the web setup wizard
```

## Install: Manual PHP + MySQL

Source: https://www.projeqtor.org/en/download

1. Download the latest release zip from https://www.projeqtor.org/en/download
2. Extract to your web server root (e.g. /var/www/html/projeqtor)
3. Create a MySQL database and user:
```sql
CREATE DATABASE projeqtor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'projeqtor'@'localhost' IDENTIFIED BY 'changeme';
GRANT ALL PRIVILEGES ON projeqtor.* TO 'projeqtor'@'localhost';
FLUSH PRIVILEGES;
```
4. Ensure the files/ directory is writable by the web server:
```bash
chown -R www-data:www-data /var/www/html/projeqtor/files
```
5. Visit http://yourserver/projeqtor and complete the setup wizard.

### Cron job (required)

ProjeQtOr requires a cron job for background tasks (alerts, reminders, email notifications):

```bash
# Add to www-data crontab (or equivalent):
*/5 * * * * php /var/www/html/projeqtor/tool/cron.php > /dev/null 2>&1
```

## Upgrade procedure

Source: https://www.projeqtor.org/en/documentation

1. Back up the database: `mysqldump -u projeqtor -p projeqtor > backup_$(date +%Y%m%d).sql`
2. Back up the files/ directory: `cp -r /var/www/html/projeqtor/files /backup/projeqtor-files/`
3. Download the new release zip from https://www.projeqtor.org/en/download
4. Extract and overwrite all files EXCEPT the files/ directory and parameters.php
5. Visit the app — ProjeQtOr will detect the new version and run migrations automatically

Docker: `docker compose pull && docker compose up -d`, then visit the app to trigger migrations.

## Gotchas

- No official Docker image: Community images may lag behind upstream releases. Check image tags against https://www.projeqtor.org/en/download before deploying in production.
- Cron is required: Many features (email alerts, escalations, calendar reminders) silently fail without a working cron job.
- files/ directory permissions: PHP must be able to write to files/. Incorrect permissions cause attachment uploads to fail.
- parameters.php: This file contains DB credentials and is written by the setup wizard. Do not overwrite it during upgrades.
- PHP extensions: Missing gd, zip, or mbstring causes visible errors. Check php -m output before troubleshooting the app.
- AGPL-3.0: If you distribute or expose a modified version, you must publish the source changes.

## Links

- Official site: https://www.projeqtor.org
- Download: https://www.projeqtor.org/en/download
- Documentation: https://www.projeqtor.org/en/documentation
- Demo: https://demo.projeqtor.org/
- Source (SourceForge): https://sourceforge.net/p/projectorria/code/HEAD/tree/branches/
