---
name: open-source-pos
description: Open Source Point of Sale (OSPOS) recipe for open-forge. Web-based PHP/MySQL POS system for retail stores. Self-hosted via Docker Compose or LAMP. Source: https://github.com/opensourcepos/opensourcepos. Docs: https://github.com/opensourcepos/opensourcepos/wiki.
---

# Open Source Point of Sale (OSPOS)

Web-based point of sale system for retail stores. Written in PHP (CodeIgniter 4), backed by MySQL/MariaDB. Features include inventory management, sales transactions, invoicing, quotations, barcode generation, customer/supplier database, multi-user with role-based permissions, expense tracking, gift cards, and multi-language support. Upstream: <https://github.com/opensourcepos/opensourcepos>. Wiki: <https://github.com/opensourcepos/opensourcepos/wiki>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + MySQL | Recommended; upstream docker-compose.yml available |
| VPS / bare metal | Apache + PHP 8.1+ + MySQL/MariaDB | Traditional LAMP; full control over config |
| Raspberry Pi | Docker Compose | Lightweight enough for Pi 3B+ or better |
| Shared hosting | PHP + MySQL | Works on most shared hosts with PHP 8.1+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker or LAMP?" | Drives install path |
| db | "MySQL/MariaDB database name, user, password?" | Dedicated DB user recommended |
| site | "Admin username and password?" | Set during installer |
| locale | "Timezone?" | Used for sales timestamps; set PHP_TIMEZONE env var |
| currency | "Default currency symbol and code?" | Configured in OSPOS admin settings after install |

## Software-layer concerns

- Config: environment variables (Docker) or application/config/ files (LAMP)
- Default port: 80 (maps from container)
- Data dirs: public/uploads/ (receipt logos, etc.), writable/logs/
- PHP requirements: PHP 8.1+; extensions: gd, intl, mbstring, mysql, xml, zip
- Printing: receipt printing works via browser print dialog or ESC/POS thermal printers (via browser extension or local print server)
- Barcode: generates barcodes server-side; barcode scanner works as keyboard input in item search

### Docker Compose

```yaml
include:
  - docker/docker-mysql.yml

services:
  ospos:
    image: jekkos/opensourcepos:master
    restart: always
    depends_on:
      - mysql
    ports:
      - "80:80"
    volumes:
      - uploads:/app/public/uploads
      - logs:/app/writable/logs
    environment:
      - CI_ENVIRONMENT=production
      - FORCE_HTTPS=false
      - PHP_TIMEZONE=UTC
      - MYSQL_USERNAME=admin
      - MYSQL_PASSWORD=<db-password>
      - MYSQL_DB_NAME=ospos
      - MYSQL_HOST_NAME=mysql

volumes:
  uploads:
  logs:
```

Also need the MySQL service from docker/docker-mysql.yml (included above). Or define your own MySQL service:

```yaml
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: <root-password>
      MYSQL_DATABASE: ospos
      MYSQL_USER: admin
      MYSQL_PASSWORD: <db-password>
    volumes:
      - mysql-data:/var/lib/mysql
    restart: always
```

Browse to http://localhost after startup. Default admin credentials: admin / pointofsale (change immediately).

### LAMP quick-install

```bash
# Download release
curl -L https://github.com/opensourcepos/opensourcepos/releases/latest/download/opensourcepos.zip -o ospos.zip
unzip ospos.zip -d /var/www/html/ospos
# Create MySQL DB + user, then browse to /ospos to run installer
```

## Upgrade procedure

1. Backup database and uploads/ directory
2. Docker: `docker compose pull && docker compose up -d`; run database migration from Admin > System > Updates
3. LAMP: replace application files (preserve uploads/ and config), run DB migrations from admin panel
4. Check release notes: https://github.com/opensourcepos/opensourcepos/releases

## Gotchas

- **Default credentials**: admin / pointofsale. Change immediately on first login.
- **HTTPS**: Set FORCE_HTTPS=true (Docker) or configure HTTPS in your web server; POS terminals sending payment data should always use HTTPS.
- **Thermal receipt printing**: ESC/POS printing requires either a browser extension (e.g. QZ Tray) or a local print server. The web app itself handles printing via browser print dialog.
- **Barcode scanners**: Work as USB HID keyboard devices; most plug-and-play with the item search field. No special config needed.
- **Multi-location**: OSPOS supports multiple store locations (configured in admin); each location has separate cash registers and stock tracking.
- **Backup**: MySQL dump + uploads/ directory covers everything. Automate with cron + mysqldump.
- **PHP timezone**: Set PHP_TIMEZONE to your local timezone (e.g. America/New_York) so sales timestamps are correct.

## Links

- Upstream repo: https://github.com/opensourcepos/opensourcepos
- Wiki: https://github.com/opensourcepos/opensourcepos/wiki
- Docker Hub: https://hub.docker.com/r/jekkos/opensourcepos
- Live demo: https://www.opensourcepos.org (see README for credentials)
- Release notes: https://github.com/opensourcepos/opensourcepos/releases
