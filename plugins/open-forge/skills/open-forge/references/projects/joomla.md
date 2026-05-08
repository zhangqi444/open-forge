---
name: joomla-project
description: Joomla! recipe for open-forge. Mature open-source PHP CMS with Docker (official image) and manual LAMP install. Based on upstream Docker docs at https://hub.docker.com/_/joomla and https://docs.joomla.org.
---

# Joomla!

Free, open-source PHP content management system (CMS) for publishing web content. MVC framework, plugin/extension ecosystem, multilingual, MySQL/PostgreSQL storage. GPL-2.0. Upstream: https://github.com/joomla/joomla-cms. Docker image: https://hub.docker.com/_/joomla.

Current release: 6.x (PHP 8.4, latest), 5.x (LTS, PHP 8.3). Both maintained.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (official image) | Recommended containerised deploy |
| Manual LAMP/LEMP | Existing web server; full control |
| Joomla Quickstart packages | Pre-configured demos; development/testing |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Docker or manual LAMP?" | Docker / Manual | Drives which section |
| preflight | "Joomla version?" | 6 (latest) / 5 (LTS) | Default to 6 unless LTS required |
| config | "Site name?" | Free-text | JOOMLA_SITE_NAME |
| config | "Admin full name?" | Free-text | JOOMLA_ADMIN_USER |
| config | "Admin username?" | Free-text | JOOMLA_ADMIN_USERNAME |
| config | "Admin password?" | Free-text (sensitive) | JOOMLA_ADMIN_PASSWORD |
| config | "Admin email?" | email | JOOMLA_ADMIN_EMAIL |
| database | "MySQL/MariaDB root password?" | Free-text (sensitive) | For DB container |
| database | "Joomla DB password?" | Free-text (sensitive) | MYSQL_PASSWORD |
| smtp | "SMTP host and port?" | host:port | JOOMLA_SMTP_HOST / JOOMLA_SMTP_HOST_PORT |
| network | "Port to expose?" | Number (default 8080) | External HTTP port |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP 8.3 or 8.4 |
| Database | MySQL 8.x, MariaDB 10.x, or PostgreSQL (JOOMLA_DB_TYPE=pgsql) |
| Image variants | apache (default), fpm, fpm-alpine — apache is simplest |
| Auto-install | Set JOOMLA_SITE_NAME + JOOMLA_ADMIN_* env vars to skip the browser setup wizard |
| Extensions | Not bundled in image; add via FROM joomla + RUN apt-get install ... |
| Data dir | /var/www/html — mount for persistence of media uploads and extensions |
| Config file | configuration.php in /var/www/html — auto-generated on first run |

## Install: Docker Compose

Source: https://hub.docker.com/_/joomla and https://github.com/joomla-docker/docker-joomla

```yaml
services:
  joomla:
    image: joomla:latest   # or joomla:5 for LTS
    container_name: joomla
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      JOOMLA_DB_HOST: db
      JOOMLA_DB_USER: joomla
      JOOMLA_DB_PASSWORD: joomlapassword
      JOOMLA_DB_NAME: joomla
      # Auto-install (skip browser wizard):
      JOOMLA_SITE_NAME: "My Joomla Site"
      JOOMLA_ADMIN_USER: "Administrator"
      JOOMLA_ADMIN_USERNAME: admin
      JOOMLA_ADMIN_PASSWORD: adminpassword
      JOOMLA_ADMIN_EMAIL: admin@example.com
      # SMTP (optional):
      # JOOMLA_SMTP_HOST: smtp.example.com
      # JOOMLA_SMTP_HOST_PORT: 587
    volumes:
      - joomla-data:/var/www/html
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: joomla-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: joomla
      MYSQL_USER: joomla
      MYSQL_PASSWORD: joomlapassword
    volumes:
      - db-data:/var/lib/mysql

volumes:
  joomla-data:
  db-data:
```

```bash
docker compose up -d
# Access at http://localhost:8080
```

If JOOMLA_ADMIN_* env vars are set, the browser wizard is skipped. Otherwise visit http://localhost:8080 to complete setup.

## PostgreSQL variant

```yaml
environment:
  JOOMLA_DB_HOST: postgres
  JOOMLA_DB_USER: joomla
  JOOMLA_DB_PASSWORD: joomlapassword
  JOOMLA_DB_NAME: joomla
  JOOMLA_DB_TYPE: pgsql
```

## Install: Manual LAMP

Source: https://docs.joomla.org/J5.x:Installing_Joomla

Requirements:
- PHP 8.1+ (8.3+ recommended); extensions: mysqli, xml, json, zip, gd, mbstring, curl
- MySQL 8.0+ / MariaDB 10.4+ / PostgreSQL 12+
- Apache 2.4+ or nginx

```bash
# Download latest release
wget https://downloads.joomla.org/cms/joomla5/5-4-5/Joomla_5.4.5-Stable-Full_Package.zip
unzip Joomla_*.zip -d /var/www/html/joomla
chown -R www-data:www-data /var/www/html/joomla
# Create MySQL database, visit site to complete web installer
```

Full install guide: https://docs.joomla.org/J5.x:Installing_Joomla

## Upgrade procedure

**Docker:**
```bash
docker compose pull
docker compose up -d
```

**Manual:** Use the built-in Joomla Update component (System → Update → Joomla) or download the update package and install via Extensions Manager.

Always back up the database and /var/www/html before upgrading.

## Installing extensions

For Docker, create a custom image:

```dockerfile
FROM joomla:latest
RUN apt-get update && apt-get install -y php-imagick php-intl && rm -rf /var/lib/apt/lists/*
```

Extensions can be installed from the Joomla Extension Directory (JED): https://extensions.joomla.org

## Gotchas

- JOOMLA_DB_NAME is auto-created: If the specified database doesn't exist, Joomla will create it (requires GRANT CREATE on MySQL).
- Auto-install env vars skip setup wizard: Set JOOMLA_SITE_NAME + JOOMLA_ADMIN_* to skip browser setup. Useful for automated deployments.
- PHP extensions not bundled: If a plugin needs php-imagick or similar, you must build FROM joomla with the extra extensions.
- configuration.php is sensitive: Contains DB credentials. Do not expose it publicly; it lives at /var/www/html/configuration.php.
- Volume for /var/www/html: Without a volume mount, extension installs and media uploads are lost on container restart.
- Joomla 5 vs 6: v5 is the LTS line (supported through 2027); v6 is the latest standard release.

## Links

- Docker Hub: https://hub.docker.com/_/joomla
- Docker repo: https://github.com/joomla-docker/docker-joomla
- Install docs: https://docs.joomla.org/J5.x:Installing_Joomla
- Downloads: https://downloads.joomla.org
- Extension Directory: https://extensions.joomla.org
- GitHub (CMS): https://github.com/joomla/joomla-cms
