---
name: chamilo-lms
description: Chamilo LMS recipe for open-forge. Covers Docker Compose install and manual PHP install. An e-learning platform (LMS) used by 40M+ people worldwide. Verified Digital Public Good. Upstream: https://github.com/chamilo/chamilo-lms
---

# Chamilo LMS

Open-source e-learning platform (Learning Management System) for education and corporate training. Used by 40M+ users worldwide since 2010. Features courses, quizzes (20+ question types), learning paths, SCORM/LTI/xAPI support, video conferencing integrations, GDPR compliance, multilingual (60+ languages), skills management, certificates with QR codes, and AI co-creation tools. Verified Digital Public Good. Upstream: <https://github.com/chamilo/chamilo-lms> — GPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/chamilo/chamilo-lms#installation-guide> | Yes | Recommended for self-hosting. PHP-FPM + Nginx + MySQL. |
| Manual PHP install | <https://docs.chamilo.org/> | Yes | Existing LAMP/LEMP stack. PHP 8.1+ + MySQL 8/MariaDB. |
| Bitnami | <https://bitnami.com/stack/chamilo> | Community | Pre-packaged VM/container. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | MySQL root password | Sensitive | Docker / manual |
| db | Chamilo DB name, user, password | Free-text / sensitive | All |
| admin | Admin login, password, email | Free-text / sensitive | All |
| domain | Public URL (e.g. https://lms.example.com) | Free-text | All — used in site settings |
| smtp | SMTP host, port, user, password | Free-text | Recommended — student notifications, cert delivery |
| storage | Upload path (default: /var/www/html/app/upload) | Free-text | Docker — mount as volume |

## Docker Compose method

Upstream: <https://github.com/chamilo/chamilo-lms/blob/master/docker-compose.yml>

```yaml
version: "3.8"

services:
  chamilo-db:
    image: mysql:8.0
    container_name: chamilo-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ROOT_PASSWORD
      MYSQL_DATABASE: chamilo
      MYSQL_USER: chamilo
      MYSQL_PASSWORD: REPLACE_DB_PASSWORD
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    volumes:
      - chamilo_db:/var/lib/mysql

  chamilo:
    image: chamilo/chamilo-lms:latest
    container_name: chamilo
    restart: unless-stopped
    depends_on:
      - chamilo-db
    ports:
      - "8080:80"
    environment:
      DB_HOST: chamilo-db
      DB_PORT: 3306
      DB_NAME: chamilo
      DB_USER: chamilo
      DB_PASSWORD: REPLACE_DB_PASSWORD
      APP_INSTALLED: 0        # Set to 1 after first install
      PLATFORM_URL: https://lms.example.com/
    volumes:
      - chamilo_upload:/var/www/html/app/upload
      - chamilo_courses:/var/www/html/app/courses

volumes:
  chamilo_db:
  chamilo_upload:
  chamilo_courses:
```

After containers start, navigate to `http://<host>:8080/main/install/` to run the web installer.

## Manual PHP method

Requirements: PHP 8.1+ with extensions: curl, dom, gd, intl, json, mbstring, mysql/pdo_mysql, openssl, pcre, xml, zip. MySQL 8+ or MariaDB 10.4+.

```bash
# Clone the repo (or download release archive)
git clone https://github.com/chamilo/chamilo-lms.git /var/www/html/chamilo
cd /var/www/html/chamilo

# Install PHP dependencies
composer install --no-dev

# Set permissions
chown -R www-data:www-data /var/www/html/chamilo
chmod -R 755 /var/www/html/chamilo
chmod -R 777 /var/www/html/chamilo/{app/upload,app/cache,app/logs,public/css,public/js}

# Run web installer
# Navigate to http://<host>/chamilo/main/install/
```

## Key paths

| Path | Contents |
|---|---|
| `app/upload/` | Course content, uploaded files, certificates |
| `app/courses/` | Course data directories |
| `app/cache/` | Application cache — must be writable |
| `app/logs/` | Application logs |
| `app/config/configuration.php` | Generated config (DB, site URL, etc.) |

## First-run setup

1. Navigate to `http://<host>/main/install/`
2. Choose language → accept licence → verify prerequisites → configure DB credentials → set admin account
3. After install completes, set `APP_INSTALLED=1` (Docker) or protect `/main/install/` via Nginx/Apache
4. Configure portal settings: Admin panel → Platform → Settings → Portal → Site name, URL, contact email
5. Configure SMTP: Admin panel → Platform → Email configuration

## Upgrade procedure

```bash
cd /var/www/html/chamilo
git pull
composer install --no-dev
# Navigate to http://<host>/main/install/ — it detects existing install and runs upgrade wizard
# Or Docker:
docker compose pull && docker compose up -d
```

Always back up the database and `app/upload/` before upgrading.

## Gotchas

- **Platform URL is critical.** Must be set to the exact public URL (including trailing slash) used to access Chamilo. Wrong URL breaks course links, certificate QRs, and OAuth callbacks.
- **UTF-8 / utf8mb4 required.** Set MySQL to `--character-set-server=utf8mb4` and `--collation-server=utf8mb4_unicode_ci`. Non-UTF8 databases cause data corruption with multilingual content.
- **Upload volume is large.** Course videos, SCORM packages, and student uploads accumulate quickly. Plan for generous disk allocation on the upload volume.
- **PHP memory limit.** Set `memory_limit = 256M` or higher. SCORM processing and report generation are memory-intensive.
- **Install directory must be protected post-install.** After completing the installer, disable or remove access to `/main/install/` — leaving it exposed is a security risk.
- **Chamilo 1.x vs 2.x.** Version 2.x (on the `master` branch) is a full Symfony rewrite and is not backwards-compatible with 1.x. Check your target version before deploying. Docker Hub `latest` may track 2.x.
- **Cron jobs required.** Chamilo needs cron for sending notification emails, cleanup tasks, and analytics. Add: `* * * * * www-data php /var/www/html/chamilo/public/cron.php` to crontab.

## Upstream docs

- GitHub: <https://github.com/chamilo/chamilo-lms>
- Documentation: <https://docs.chamilo.org/>
- Installation guide: <https://github.com/chamilo/chamilo-lms#installation-guide>
- Docker Hub: <https://hub.docker.com/r/chamilo/chamilo-lms>
