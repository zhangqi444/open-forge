---
name: wavelog
description: Wavelog recipe for open-forge. Web-based amateur radio QSO logging software. PHP/MySQL app with maps, statistics, callbook lookups, WSPR, FT8/JS8 support, and CAT control integration. Source: https://github.com/wavelog/wavelog
---

# Wavelog

Self-hosted web-based logging software for amateur radio operators. Enhanced fork of Cloudlog. Log QSOs (contacts) from any web browser, view statistics and band/mode maps, track DXCC/SOTA/IOTA entities, integrate CAT radio control via TCP/UDP, and sync with HamQTH/QRZ callbook. PHP + MySQL/MariaDB. Actively developed with Docker support.

Upstream: <https://github.com/wavelog/wavelog> | Docs: <https://docs.wavelog.org>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (ghcr.io/wavelog/wavelog) | Official image — recommended |
| Any | Docker Compose | Compose with MariaDB |
| Linux | LAMP stack (manual) | Apache/Nginx + PHP 8.2-8.4 + MySQL/MariaDB |
| Raspberry Pi | LAMP or Docker | Supported; 64-bit OS recommended for microwave QSO logging |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Amateur radio callsign | Used as the primary station callsign |
| preflight | Locator (Maidenhead grid square) | e.g. JO50xx |
| config | Database name, user, password | For the MariaDB/MySQL container |
| config | HTTP port | Default: 8080 |
| config | ADMIN_KEY (for Docker) | Used for initial admin setup |
| config | Timezone | Set in PHP and DB for correct log times |

## Software-layer concerns

### Requirements (manual install)

- PHP 8.2, 8.3, or 8.4 (8.5 unofficial)
- MySQL 8+ or MariaDB 10.2+
- Apache or Nginx web server
- PHP extensions: gd, xml, curl, mbstring, zip, intl

### Docker image tags

The official image is `ghcr.io/wavelog/wavelog`. Pinned tags available on GitHub Packages; `latest` tracks the current release.

### Data dirs

- Wavelog application config and uploads live inside the container at `/var/www/html`. Mount a volume if you want persistent uploads or config outside the container.
- Database: external MariaDB/MySQL container.

### Key env vars (Docker)

| Var | Description |
|---|---|
| WAVELOG_DB_HOST | Database host (e.g. db) |
| WAVELOG_DB_NAME | Database name |
| WAVELOG_DB_USER | Database user |
| WAVELOG_DB_PASS | Database password |
| ADMIN_KEY | Initial admin setup key |
| TZ | Timezone (e.g. Europe/London) |

## Install — Docker Compose (recommended)

```bash
mkdir wavelog && cd wavelog

cat > docker-compose.yml << 'EOF'
services:
  wavelog:
    image: ghcr.io/wavelog/wavelog:2.4.2
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:80"
    environment:
      WAVELOG_DB_HOST: db
      WAVELOG_DB_NAME: wavelog
      WAVELOG_DB_USER: wavelog
      WAVELOG_DB_PASS: wavelogpass
      ADMIN_KEY: changeme_admin_key
      TZ: UTC
    volumes:
      - wavelog_data:/var/www/html/uploads

  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: wavelog
      MYSQL_USER: wavelog
      MYSQL_PASSWORD: wavelogpass
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  wavelog_data:
  db_data:
EOF

docker compose up -d
```

Web UI at http://localhost:8080. Complete setup via the web installer using the ADMIN_KEY.

## Install — LAMP (manual)

```bash
# Install PHP + extensions on Ubuntu/Debian
sudo apt install php8.2 php8.2-{gd,xml,curl,mbstring,zip,intl,mysql} mariadb-server apache2 libapache2-mod-php

# Download latest release
curl -LO https://github.com/wavelog/wavelog/archive/refs/heads/master.zip
unzip master.zip -d /var/www/
mv /var/www/wavelog-master /var/www/wavelog

# Create DB
sudo mysql -u root <<SQL
CREATE DATABASE wavelog CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wavelog'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON wavelog.* TO 'wavelog'@'localhost';
SQL

# Set permissions
sudo chown -R www-data:www-data /var/www/wavelog
sudo chmod -R 755 /var/www/wavelog

# Configure Apache virtual host pointing to /var/www/wavelog
# Then visit http://yourserver/ to run the web installer
```

See the full installation docs at https://docs.wavelog.org/getting-started/installation/

## Upgrade procedure

Docker:
```bash
docker compose pull
docker compose up -d
```

Manual: Download new release, overwrite files (preserve application/config and uploads/), run DB migrations via the web interface if prompted.

## Gotchas

- 64-bit OS required for microwave QSO logging (> 1.3 GHz band). 32-bit will silently mismatch frequency calculations.
- PHP 8.5 is not officially supported as of v2.4.1 — use 8.2, 8.3, or 8.4.
- Wavelog is a fork of Cloudlog — do not mix config files or databases between the two; they have diverged.
- CAT control integration (rigctld/flrig) requires network access from the Wavelog server to your radio host; configure firewall rules if they are on different machines.
- ADMIN_KEY is only used during initial setup. After the admin account is created, it is no longer needed but should still be kept secret in your compose file.

## Links

- Upstream: https://github.com/wavelog/wavelog
- Documentation: https://docs.wavelog.org
- Docker install guide: https://docs.wavelog.org/getting-started/installation/docker/
- Demo: https://demo.wavelog.org (user: demo / pass: demo)
