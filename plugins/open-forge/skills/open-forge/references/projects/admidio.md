---
name: admidio
description: Admidio recipe for open-forge. Open-source user management system for clubs, associations and organisations. Flexible role model, event management, member lists, messaging, photo albums. Upstream: https://github.com/Admidio/admidio
---

# Admidio

Open-source user management system designed for clubs, associations, and organisations. Uses a flexible role model to mirror your org's structure and permissions. Built-in modules: member lists, event management, messaging, photo albums, document repository, and customisable profile fields. Available in 20+ languages. Upstream: <https://github.com/Admidio/admidio> — GPL-2.0.

PHP 8.2+ + MySQL 5.0+ / MariaDB 10+ / PostgreSQL 11+.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://hub.docker.com/r/admidio/admidio> | Yes | Recommended. First-party image. |
| Manual PHP install | <https://www.admidio.org/dokuwiki/doku.php?id=en:2.0:installation> | Yes | Shared hosting or existing LAMP/LEMP stack. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | Database host | Free-text | All |
| db | Database name, user, password | Free-text / sensitive | All |
| admin | Admin username, password, email | Free-text / sensitive | All |
| site | Organisation name | Free-text | First-run config |
| domain | Public root URL (ADMIDIO_ROOT_PATH) | Free-text | Docker — used for links in emails and UI |

## Docker Compose method

```yaml
version: "3.8"

services:
  admidio-db:
    image: mariadb:10.11
    container_name: admidio-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ROOT_PASSWORD
      MYSQL_DATABASE: admidio
      MYSQL_USER: admidio
      MYSQL_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - admidio_db:/var/lib/mysql

  admidio:
    image: admidio/admidio:latest
    container_name: admidio
    restart: unless-stopped
    depends_on:
      - admidio-db
    ports:
      - "8080:8080"
    environment:
      ADMIDIO_DB_HOST: admidio-db
      ADMIDIO_DB_NAME: admidio
      ADMIDIO_DB_USER: admidio
      ADMIDIO_DB_PASSWORD: REPLACE_DB_PASSWORD
      # Root path must match the public URL your users will use
      ADMIDIO_ROOT_PATH: https://members.example.com
    volumes:
      - admidio_data:/var/www/html/adm_my_files

volumes:
  admidio_db:
  admidio_data:
```

After first start, navigate to `http://<host>:8080` and complete the web installer (creates DB tables and first admin account).

## Manual PHP install

Requirements: PHP 8.2+ with pdo_mysql/pdo_pgsql, gd, json, mbstring; web server with URL rewriting.

```bash
# Download latest release
wget https://github.com/Admidio/admidio/releases/latest/download/admidio-latest.zip
unzip admidio-latest.zip -d /var/www/html/admidio

# Set permissions
chown -R www-data:www-data /var/www/html/admidio
chmod -R 777 /var/www/html/admidio/adm_my_files

# Visit http://<host>/admidio/installation/ to run the installer
```

## Key environment variables (Docker)

| Variable | Purpose |
|---|---|
| `ADMIDIO_DB_HOST` | Database host |
| `ADMIDIO_DB_NAME` | Database name |
| `ADMIDIO_DB_USER` | Database username |
| `ADMIDIO_DB_PASSWORD` | Database password |
| `ADMIDIO_ROOT_PATH` | Full public URL (e.g. https://members.example.com) — used in email links |

## Key directories

| Path | Purpose |
|---|---|
| `adm_my_files/` | All persistent data: uploads, config, generated files — must be volume-mounted |
| `adm_plugins/` | Third-party plugins — persist if using plugins |
| `adm_themes/` | Custom themes |

## Key features

- **Flexible roles:** Create roles (e.g. Board Member, Volunteer, Coach) with custom permissions; members can belong to multiple roles
- **Custom profile fields:** Add/remove fields per role (phone, address, instrument, jersey number — whatever your org needs)
- **Member relationships:** Link members as spouse, parent/child, coach/athlete
- **Event management:** Create events, publish online, track member sign-ups and attendance
- **Messaging:** Send HTML emails to all members, specific roles, or groups
- **Photo albums:** Upload and manage photo collections with member tagging
- **Document repository:** Store and share files with role-based access
- **Export:** Member lists to CSV, Excel (ODS), and PDF
- **Import:** Bulk import members from CSV

## Upgrade procedure

```bash
docker compose pull admidio
docker compose up -d admidio
```

For manual installs — from the Admidio wiki:
1. Delete all files and folders **except** `adm_my_files/` and `adm_plugins/`
2. Copy all folders from the new release **except** `adm_my_files/`
3. Visit `http://<host>/admidio/installation/update.php` to run database migrations

## Gotchas

- **`adm_my_files/` is everything.** All user uploads, config, and session data live here. In Docker, this volume is the only thing you need to back up (plus the database). Never lose it.
- **`ADMIDIO_ROOT_PATH` must be exact.** If you run behind a reverse proxy with a subdirectory path (e.g. `https://example.com/members`), set it accordingly. Wrong paths cause broken email links and login redirects.
- **Installer lock file.** After installation, the installer directory is locked by a flag file in `adm_my_files/`. Don't delete `adm_my_files/` unless you want to reinstall from scratch.
- **PHP GD required.** Photo album thumbnails and image resizing need the GD extension. Without it, photos will upload but not display correctly.
- **Upgrade order: files first, then DB migration.** If you swap files before running the update wizard, the app may show errors until migrations complete. Run the update wizard promptly after file replacement.

## Upstream docs

- GitHub: <https://github.com/Admidio/admidio>
- Installation guide: <https://www.admidio.org/dokuwiki/doku.php?id=en:2.0:installation>
- Update guide: <https://www.admidio.org/dokuwiki/doku.php?id=en:2.0:update>
- Docker Hub: <https://hub.docker.com/r/admidio/admidio>
- Demo: <https://www.admidio.org/demo/>
