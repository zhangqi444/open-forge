---
name: plainpad
description: Plainpad recipe for open-forge. Self-hosted note taking application with a clean interface. PWA support, cloud sync, PHP + MySQL backend, Docker Compose install. Source: https://github.com/alextselegidis/plainpad
---

# Plainpad

Self-hosted note taking application with a clean, minimal interface. Progressive Web App (PWA) support for offline use and mobile installation. PHP backend + MySQL database. Docker Compose based install. GPL-3.0 licensed.

Upstream: <https://github.com/alextselegidis/plainpad> | Demo: <https://alextselegidis.com/try/plainpad/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended — includes PHP-FPM, Nginx, MySQL |
| Linux | LAMP/LEMP stack (manual) | PHP + MySQL + Apache/Nginx |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Nginx port | Set via `NGINX_PORT` env var (default 80) |
| config | MySQL port | Set via `MYSQL_PORT` env var |
| config | MySQL root password | Set in compose env |
| config | MySQL user + password | Default: user / password (change for production) |
| config (optional) | phpMyAdmin port | Set via `PHPMYADMIN_PORT` |

## Software-layer concerns

### Architecture

- PHP-FPM — application backend
- Nginx — web server / reverse proxy to PHP-FPM
- MySQL 8 — database
- phpMyAdmin (optional) — DB management UI (included in compose)
- Mailpit (optional) — local mail catcher for dev/testing

### Data dirs

- MySQL data persisted at `./docker/mysql` (relative to project root)
- App code mounted from project root into containers

### Env vars (`.env` file)

```env
NGINX_PORT=80
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080
```

### MySQL credentials (in docker-compose.yml)

```yaml
MYSQL_ROOT_PASSWORD: secret
MYSQL_DATABASE: plainpad
MYSQL_USER: user
MYSQL_PASSWORD: password
```

Change these for production deployments.

## Install — Docker Compose

```bash
git clone https://github.com/alextselegidis/plainpad.git
cd plainpad

# Create .env file with port settings
cat > .env << 'EOF'
NGINX_PORT=80
MYSQL_PORT=3306
PHPMYADMIN_PORT=8080
EOF

# Edit docker/docker-compose.yml to set strong MySQL credentials

docker compose up -d
```

Access Plainpad at http://localhost (or your configured NGINX_PORT).

## Manual install (LEMP)

```bash
# Requirements: PHP 7.4+, MySQL 8, Nginx

# Clone repo to web root
git clone https://github.com/alextselegidis/plainpad.git /var/www/plainpad

# Create MySQL database
mysql -u root -p <<SQL
CREATE DATABASE plainpad;
CREATE USER 'plainpad'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON plainpad.* TO 'plainpad'@'localhost';
SQL

# Configure .env (copy from .env.example if present)
cp .env.example .env
# Edit .env: set DB_HOST, DB_DATABASE, DB_USERNAME, DB_PASSWORD

# Configure Nginx virtual host pointing to /var/www/plainpad/public
# Restart Nginx
sudo systemctl restart nginx

# Run migrations (if applicable)
php artisan migrate
```

## Upgrade procedure

```bash
git pull
docker compose up -d --build
```

## Gotchas

- MySQL data is stored at `./docker/mysql` — this is NOT a named Docker volume, it's a bind mount in the project directory. Back it up before running `docker compose down -v` or deleting the directory.
- Default MySQL credentials (`user`/`password`) are development defaults — change `MYSQL_ROOT_PASSWORD`, `MYSQL_USER`, and `MYSQL_PASSWORD` in the compose file before any internet-exposed deployment.
- phpMyAdmin is included by default — restrict its port or remove it from compose for production.
- Mailpit is included for local mail testing and can be removed from compose if not needed.
- PWA features (offline, installable on mobile) require HTTPS — put a TLS-terminating reverse proxy (Caddy, nginx + Certbot) in front for production.

## Links

- Source: https://github.com/alextselegidis/plainpad
- Demo: https://alextselegidis.com/try/plainpad/
- Website: https://alextselegidis.com/get/plainpad/
