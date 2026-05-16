---
name: admidio-project
description: Admidio recipe for open-forge. Covers ZIP install on a web server and Docker Compose deployment. Open-source member management system for clubs, associations, and organisations — role model, events, messaging, photo albums, documents.
---

# Admidio

Open-source member management system for clubs, associations, and non-profit organisations. Flexible role model mirrors your org structure. Core modules: member lists, roles/groups, events, internal messaging, announcements, photo albums, document storage, guest book. GPL-2.0.

- **GitHub:** https://github.com/Admidio/admidio (455 stars)
- **Site:** https://www.admidio.org/
- **Docs:** https://www.admidio.org/dokuwiki/doku.php
- **Demo:** https://www.admidio.org/demo/

## Compatible install methods

| Method | When to use |
|---|---|
| ZIP download + web server | Traditional LAMP/LEMP stack |
| Docker Compose (`admidio/admidio`) | Containerised deployment |

## Requirements

| Component | Minimum |
|---|---|
| PHP | 8.2+ |
| MySQL | 5.0+ |
| MariaDB | 10.0+ |
| PostgreSQL | 11+ |
| Extensions | `pdo`, `pdo_mysql`/`pdo_pgsql`, `gd`, `mbstring`, `openssl`, `curl`, `zip` |
| Web server | Apache 2.4+ or NGINX |

## Install — ZIP on web server

```bash
# 1. Download latest release ZIP from GitHub
wget https://github.com/Admidio/admidio/releases/latest/download/admidio-<version>.zip

# 2. Extract
unzip admidio-<version>.zip -d /var/www/html/

# 3. Set permissions
chown -R www-data:www-data /var/www/html/admidio
# adm_my_files must be writable — this is where Admidio stores all persistent data
chmod -R 775 /var/www/html/admidio/adm_my_files

# 4. Create database (MySQL example)
mysql -u root -p -e "
  CREATE DATABASE admidio CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER 'admidio'@'localhost' IDENTIFIED BY 'changeme';
  GRANT ALL PRIVILEGES ON admidio.* TO 'admidio'@'localhost';
  FLUSH PRIVILEGES;"
```

Visit `http://your-domain/admidio/` to run the web installer.

## Docker Compose

```yaml
services:
  admidio:
    image: admidio/admidio:latest
    container_name: admidio
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      ADMIDIO_DB_HOST: db
      ADMIDIO_DB_PORT: 3306
      ADMIDIO_DB_NAME: admidio
      ADMIDIO_DB_USER: admidio
      ADMIDIO_DB_PASSWORD: changeme
      # Public URL of your Admidio install — used for links in emails
      ADMIDIO_ROOT_PATH: http://localhost:8080/admidio
      # Organisation name shown on the login page
      ADMIDIO_ORG_NAME: My Organisation
      # Short abbreviation used in table names (change before first install only)
      ADMIDIO_ORG_SHORTNAME: ORG
    volumes:
      # adm_my_files contains all uploaded files, config, and generated data
      # This MUST be persisted — losing it means losing all uploads and config
      - admidio-data:/var/www/html/admidio/adm_my_files
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: admidio-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: admidio
      MYSQL_USER: admidio
      MYSQL_PASSWORD: changeme
      MYSQL_ROOT_PASSWORD: changeme-root
    volumes:
      - admidio-db:/var/lib/mysql

volumes:
  admidio-data:
  admidio-db:
```

## Key environment variables (Docker)

| Variable | Description | Default |
|---|---|---|
| `ADMIDIO_DB_HOST` | Database hostname | `localhost` |
| `ADMIDIO_DB_PORT` | Database port | `3306` |
| `ADMIDIO_DB_NAME` | Database name | `admidio` |
| `ADMIDIO_DB_USER` | Database user | — |
| `ADMIDIO_DB_PASSWORD` | Database password | — |
| `ADMIDIO_ROOT_PATH` | Public URL of the install | — |
| `ADMIDIO_ORG_NAME` | Organisation display name | `My Organisation` |
| `ADMIDIO_ORG_SHORTNAME` | Short prefix for DB tables (set once) | `ORG` |
| `ADMIDIO_MAIL_HOST` | SMTP hostname | — |
| `ADMIDIO_MAIL_PORT` | SMTP port | `25` |
| `ADMIDIO_MAIL_USER` | SMTP username | — |
| `ADMIDIO_MAIL_PASSWORD` | SMTP password | — |

## Key directories

| Path | Purpose |
|---|---|
| `adm_my_files/` | **All** persistent data — uploads, generated config, session data, backups. Volume-mount this. |
| `adm_plugins/` | Third-party plugins |
| `adm_themes/` | Custom themes |

## Apache vhost

```apache
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/html/admidio

    <Directory /var/www/html/admidio>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Protect sensitive directories
    <Directory /var/www/html/admidio/adm_my_files>
        Require all denied
    </Directory>
</VirtualHost>
```

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Install method? (Docker / ZIP)" | |
| db | "Database type? (MySQL/MariaDB or PostgreSQL)" | |
| db | "Database host, name, user, password?" | |
| org | "Organisation name and short abbreviation?" | Short name is used as DB table prefix — cannot be changed after install |
| org | "Public URL where Admidio will be accessible?" | Set as `ADMIDIO_ROOT_PATH` |
| admin | "Admin email and password?" | First admin account created during install wizard |
| mail | "SMTP server details for email notifications?" | Events, new member registrations, messages |

## Features overview

| Module | What it does |
|---|---|
| Members | Custom profile fields, import/export CSV/Excel/PDF |
| Roles | Hierarchical roles mirroring your org chart; member-role assignments |
| Events | Create events, manage registrations, send invitations |
| Announcements | Internal news / bulletin board |
| Messaging | Private messages between members |
| Photo albums | Upload and share photo albums |
| Documents | File sharing and document library |
| Guest book | Public-facing guest book |
| Links | Curated link list for members |
| Forum | Discussion threads (optional module) |

## Notes

- The `adm_my_files/` directory is the single most important thing to back up — it contains all uploaded files and the generated `config.php`.
- `ADMIDIO_ORG_SHORTNAME` is used as a prefix for all database table names and **cannot be changed after the first install** without a full database migration.
- Admidio supports 20+ UI languages out of the box.
- Member relationships (spouse, parent/child, etc.) can be defined under **Configuration → User relation types**.
- Email notifications for events and registrations require SMTP to be configured under **Organisation Settings → Email**.
- Demo: https://www.admidio.org/demo/ (credentials shown on the page)
