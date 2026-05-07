---
name: redaxo
description: REDAXO recipe for open-forge. Flexible PHP CMS with a module/addon system. Simple for editors, powerful for developers. Create content from custom modules with full I/O control. Multilingual, extensible. Docker or manual PHP install. Source: https://github.com/redaxo/core
---

# REDAXO

PHP content management system focused on simplicity for editors and flexibility for developers. Build websites with custom modules that give you full control over data input and output. Multilingual, highly extensible via addons, and adapts to your workflow. Primarily used in German-speaking countries but multilingual and internationally accessible. MIT licensed.

Upstream: <https://github.com/redaxo/core> | Docs: <https://redaxo.org/doku/5.x>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose (official image) | `friendsofredaxo/redaxo:5` + MySQL |
| Linux | LAMP/LEMP (manual) | PHP 7.4+ / 8.x, MySQL 5.7+ / MariaDB |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 80 (set `REDAXO_PORT` env var) |
| config | MySQL database, user, password | Used in docker-compose or manual install |
| config | Admin username + password | Set during web installer |
| config | Site language | English and others available |

## Software-layer concerns

### Architecture

- PHP application served by Apache (in official Docker image)
- MySQL 8 — primary database
- Addon/module system — extend via the built-in Installer addon

### Data dirs (Docker)

- App files: mounted from project root (`.:/var/www/html`)
- Database: persisted at `./.docker/db`

> Note: The default docker-compose.yml mounts the current directory as the app root — pull/clone the REDAXO core repo first, then run compose from inside it.

### Key env vars

| Var | Description | Default |
|---|---|---|
| REDAXO_PORT | Host port for the web server | 80 |

MySQL credentials in docker-compose:
```yaml
MYSQL_DATABASE: redaxo
MYSQL_USER: redaxo
MYSQL_PASSWORD: redaxo   # CHANGE for production
```

## Install — Docker Compose

```bash
git clone https://github.com/redaxo/core.git redaxo
cd redaxo

# Start (default port 80)
docker compose up -d

# Or with a custom port
REDAXO_PORT=8080 docker compose up -d
```

Then open http://localhost (or your configured port) and complete the web installer:
1. Choose language
2. Set admin credentials
3. Configure database (uses the Docker MySQL service — host: `db`, database: `redaxo`, user/pass as in compose file)
4. Install demo content (optional — search for `demo_base` for the English demo)

## Install — Manual (LEMP)

```bash
# PHP 8.x + MySQL + Nginx
sudo apt install php8.2 php8.2-{mysql,gd,xml,mbstring,zip,intl,curl} \
  mysql-server nginx

# Download latest release
curl -LO https://github.com/redaxo/core/releases/latest/download/redaxo_5.x.x.zip
unzip redaxo_5.x.x.zip -d /var/www/redaxo

# Create MySQL database
mysql -u root -p <<SQL
CREATE DATABASE redaxo CHARACTER SET utf8mb4;
CREATE USER 'redaxo'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON redaxo.* TO 'redaxo'@'localhost';
SQL

# Configure Nginx virtual host → /var/www/redaxo
# Run web installer: http://yourserver/
```

## Upgrade procedure

```bash
# Use the built-in Updater addon in the REDAXO backend
# System → Updater → Update core

# Docker: pull new image
docker compose pull
docker compose up -d
```

## Gotchas

- MySQL credentials in the default `docker-compose.yml` are `redaxo/redaxo` — **change `MYSQL_PASSWORD`** before any internet-exposed deployment.
- The project's primary community is German-speaking — documentation and addons may be in German. The `demo_base` addon is fully translated into English and is the best way to get started in English.
- Addon ecosystem: REDAXO is extended via addons available in the built-in Installer. Search https://redaxo.org/doku/5.x or the Slack community for available addons.
- The Docker image mounts the project directory as the web root — keep source files and Docker volumes in the same directory structure as the cloned repo.
- Friends of REDAXO (https://friendsofredaxo.github.io) maintains the community addons, demos, tricks, and PHP API docs.

## Links

- Source: https://github.com/redaxo/core
- Documentation: https://redaxo.org/doku/5.x
- Releases: https://github.com/redaxo/core/releases
- Community/Slack: https://www.redaxo.org/slack/
- Friends of REDAXO: https://friendsofredaxo.github.io
- API docs: https://friendsofredaxo.github.io/phpdoc/
