---
name: craftcms
description: Craft CMS recipe for open-forge. Covers Composer-based install (recommended), DDEV local dev setup, Docker Compose, and upgrade procedure. Upstream: https://github.com/craftcms/cms
---

# Craft CMS

Flexible, user-friendly PHP CMS for building custom digital experiences. Clean-slate content modeling, Twig templating, auto-generated GraphQL API, and a plugin store with hundreds of extensions. Upstream: <https://github.com/craftcms/cms> — Craft License (proprietary-friendly; free for personal and small commercial use up to a revenue threshold; see <https://craftcms.com/license>).

Craft is a PHP application backed by MySQL or PostgreSQL, served via Apache or Nginx.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Composer (recommended) | <https://craftcms.com/docs/5.x/install.html> | Yes | Standard production install. PHP 8.2+ + MySQL 8/PostgreSQL 13+. |
| DDEV (local dev) | <https://craftcms.com/docs/5.x/install.html#with-ddev> | Yes | Preferred local development environment. Auto-configures PHP, Nginx, DB. |
| Docker Compose | Community | Community | Production containers. No official first-party Compose file. |
| Craft Cloud | <https://craftcms.com/cloud> | Yes (managed) | Out of scope for open-forge — paid managed hosting. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | Database type (MySQL 8 or PostgreSQL 13+)? | Choice | All methods |
| db | Database host, port, name, user, password | Free-text | All (skip for DDEV — auto-configured) |
| security | Security key (random 32+ char string) | Sensitive | All — set as CRAFT_SECURITY_KEY env var |
| domain | Public hostname | Free-text | Production installs |
| email | SMTP credentials for system email | Free-text | All — needed for user invites, password reset |
| storage | S3/GCS/R2 bucket for assets? (optional, local disk is default) | Choice | Production recommended for file storage |

## Composer install (production)

### Prerequisites

- PHP 8.2+ with extensions: bcmath, ctype, curl, dom, fileinfo, filter, gd, iconv, imagick (recommended), intl, json, mbstring, openssl, pcre, PDO + pdo_mysql/pdo_pgsql, tokenizer, zip
- Composer 2.x
- MySQL 8.0+ or PostgreSQL 13+
- Apache/Nginx

```bash
# Create new Craft project
composer create-project craftcms/craft my-project
cd my-project

# Configure environment
cp .env.example .env
nano .env   # Set DB_*, CRAFT_SECURITY_KEY, DEFAULT_SITE_URL

# Run installer
php craft setup
# or install via browser: http://<host>/index.php?p=admin/install
```

Example `.env` variables:

```dotenv
CRAFT_SECURITY_KEY=REPLACE_WITH_32_CHAR_RANDOM_STRING
CRAFT_DB_DRIVER=mysql
CRAFT_DB_SERVER=127.0.0.1
CRAFT_DB_PORT=3306
CRAFT_DB_DATABASE=craft
CRAFT_DB_USER=craft
CRAFT_DB_PASSWORD=REPLACE_DB_PASSWORD
CRAFT_DB_TABLE_PREFIX=
DEFAULT_SITE_URL=https://example.com
CRAFT_APP_ID=CraftCMS
```

## DDEV local dev install

```bash
mkdir my-project && cd my-project
ddev config --project-type=craftcms --docroot=web
ddev start
ddev composer create-project craftcms/craft .
ddev exec php craft setup/app-id --interactive=0
ddev exec php craft setup/security-key
# Follow the prompts or run install via browser:
ddev launch /admin/install
```

## Docker Compose (community)

No official Docker image. Community approach using `php:8.2-fpm` + Nginx:

```yaml
version: "3.8"

services:
  craft-db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ROOT_PASSWORD
      MYSQL_DATABASE: craft
      MYSQL_USER: craft
      MYSQL_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - craft_db:/var/lib/mysql

  craft-app:
    image: php:8.2-fpm
    restart: unless-stopped
    working_dir: /var/www/html
    depends_on:
      - craft-db
    environment:
      CRAFT_SECURITY_KEY: REPLACE_SECURITY_KEY
      CRAFT_DB_DRIVER: mysql
      CRAFT_DB_SERVER: craft-db
      CRAFT_DB_PORT: 3306
      CRAFT_DB_DATABASE: craft
      CRAFT_DB_USER: craft
      CRAFT_DB_PASSWORD: REPLACE_DB_PASSWORD
      DEFAULT_SITE_URL: https://example.com
    volumes:
      - ./:/var/www/html
      - craft_storage:/var/www/html/storage

  craft-web:
    image: nginx:stable-alpine
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - craft-app
    volumes:
      - ./web:/var/www/html/web
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro

volumes:
  craft_db:
  craft_storage:
```

## Upgrade procedure

```bash
cd my-project
composer update craftcms/cms
php craft migrate/all
php craft project-config/apply
```

For major version upgrades (e.g. Craft 4 to 5): follow the upgrade guide at <https://craftcms.com/docs/5.x/upgrade.html> — breaking changes require specific steps per major version.

## Gotchas

- **License note.** Craft CMS uses the Craft License, not a standard OSI license. It is free for personal use and small-revenue commercial use. Check <https://craftcms.com/license> for current thresholds. Craft Commerce (ecommerce plugin) is a separate paid license.
- **Security key is mandatory.** Never run without `CRAFT_SECURITY_KEY`. Generate with: `php craft setup/security-key` or `openssl rand -base64 32`.
- **Project config.** Craft 3.5+ uses a `config/project/` directory for schema-level config (fields, sections, etc.). Commit this directory to version control and apply with `php craft project-config/apply` when deploying.
- **Storage directory must be writable.** `/storage/` holds logs, backups, compiled templates, and session data. Mount it as a persistent volume in Docker.
- **Asset volumes.** By default assets are stored in `/web/uploads`. For production, configure an S3/R2/GCS asset volume via the Admin → Settings → Filesystems to avoid losing uploads on container recreation.
- **PHP extensions.** Imagick (not GD) is recommended for image transformations in production — significantly better quality and performance.
- **Nginx config.** Craft requires URL rewriting. Copy the recommended Nginx config from <https://craftcms.com/docs/5.x/requirements.html#nginx>.

## Upstream docs

- GitHub: <https://github.com/craftcms/cms>
- Install guide: <https://craftcms.com/docs/5.x/install.html>
- Server requirements: <https://craftcms.com/docs/5.x/requirements.html>
- DDEV setup: <https://craftcms.com/docs/5.x/install.html#with-ddev>
- Upgrade guide (Craft 5): <https://craftcms.com/docs/5.x/upgrade.html>
- License: <https://craftcms.com/license>
