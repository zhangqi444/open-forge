---
name: teampass
description: Teampass recipe for open-forge. Collaborative password manager for teams. Based on upstream docs at https://teampass.net and https://github.com/nilsteampassnet/TeamPass
---

# Teampass

Collaborative password manager for teams. Uses a single symmetric encryption key to encrypt all shared passwords, stored server-side. Supports folders, roles, user permissions, and API access. Upstream: <https://github.com/nilsteampassnet/TeamPass>. Docs: <https://teampass.readthedocs.io/>

Stack: PHP + MySQL/MariaDB + Apache/Nginx. Current stable release: v3.1.7.6 (April 2026).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://hub.docker.com/r/teampass/teampass/> | ✅ | Quickest path; official Docker Hub image |
| Manual PHP install | <https://teampass.readthedocs.io/en/latest/install/> | ✅ | Custom server setup with existing LAMP/LEMP stack |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install via Docker or manual PHP?" | `AskUserQuestion`: Docker / Manual | Drives method |
| database | "Database root password?" | Free-text (sensitive) | Docker: set in compose env |
| database | "Teampass DB password?" | Free-text (sensitive) | All |
| network | "Domain or IP for Teampass?" | Free-text | All |
| tls | "Set up HTTPS?" | `AskUserQuestion`: Yes / No | All (strongly recommended — passwords transit in plaintext without TLS) |

## Software-layer concerns

**Config paths:**
- `includes/config/settings.php` — main app config (DB connection, salt key)
- Populated by the web-based installer on first run

**Environment:**
- PHP 8.1+ with extensions: `mcrypt`, `openssl`, `bcmath`, `mbstring`, `gd`, `xml`, `curl`, `pdo_mysql`
- MySQL 5.7+ or MariaDB 10.3+
- Apache or Nginx with mod_rewrite / try_files

**Data dirs:**
- `files/` — encrypted attachments
- `upload/` — temp uploads

**Security note:** The symmetric encryption key is stored server-side. Teampass provides access control (folders, roles, LDAP) but is **not** a zero-knowledge password manager — server-side compromise exposes all passwords.

## Method — Docker Compose

> **Source:** <https://hub.docker.com/r/teampass/teampass/> · Image: `teampass/teampass:latest`

The official Docker Hub image (`teampass/teampass`) bundles PHP-FPM and Apache. A reverse proxy (jwilder/nginx-proxy or Traefik) is commonly used for TLS.

### Compose template

```yaml
version: "3"
services:
  teampass-web:
    image: teampass/teampass:latest
    restart: unless-stopped
    environment:
      VIRTUAL_HOST: ${HOSTNAME}
      VIRTUAL_PORT: 80
    volumes:
      - ./teampass-html:/var/www/html
    ports:
      - "8080:80"        # remove if using a reverse proxy
    networks:
      - teampass-internal
      - backend
    depends_on:
      - db

  db:
    image: yobasystems/alpine-mariadb:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PW}
      MYSQL_DATABASE: teampass
      MYSQL_PASSWORD: ${DB_PW}
      MYSQL_USER: teampass
    volumes:
      - ./teampass-db:/var/lib/mysql
    networks:
      - teampass-internal

networks:
  teampass-internal:
  backend:
```

```bash
# Create .env
cat > .env << EOL
HOSTNAME=teampass.example.com
DB_ROOT_PW=$(openssl rand -hex 32)
DB_PW=$(openssl rand -hex 32)
EOL

docker compose up -d
```

After startup, visit `http://<HOSTNAME>/install/install.php` to run the web installer. Use the DB credentials from your `.env`.

### Web installer inputs

| Field | Value |
|---|---|
| Database host | `db` (service name) |
| Database name | `teampass` |
| Database login | `teampass` |
| Database password | `${DB_PW}` |
| Absolute path | `/var/www/html` |
| Admin password | Choose a strong password |
| Salt key | Auto-generated (save it!) |

> ⚠️ **Save the salt key.** If lost, all encrypted passwords become unrecoverable. Back up `settings.php` after install.

## Method — Manual PHP install

> **Source:** <https://teampass.readthedocs.io/en/latest/install/>

```bash
# 1. Install dependencies (Ubuntu/Debian)
sudo apt install apache2 php8.1 php8.1-mysql php8.1-gd php8.1-mcrypt \
  php8.1-mbstring php8.1-xml php8.1-curl php8.1-bcmath mariadb-server

# 2. Download Teampass
cd /var/www/html
sudo git clone https://github.com/nilsteampassnet/TeamPass.git teampass
sudo chown -R www-data:www-data teampass/
sudo chmod -R 755 teampass/
sudo chmod -R 777 teampass/files teampass/upload teampass/includes/config teampass/includes/avatars

# 3. Create database
sudo mysql -e "
  CREATE DATABASE teampass CHARACTER SET utf8 COLLATE utf8_general_ci;
  CREATE USER 'teampass'@'localhost' IDENTIFIED BY '${DB_PW}';
  GRANT ALL PRIVILEGES ON teampass.* TO 'teampass'@'localhost';
  FLUSH PRIVILEGES;"

# 4. Configure Apache vhost, then visit http://<host>/teampass/install/install.php
```

## Upgrade procedure

**Docker:**
```bash
docker compose pull
docker compose up -d
# Teampass auto-runs DB migrations on startup
```

**Manual:**
```bash
cd /var/www/html/teampass
git pull
# Visit http://<host>/teampass/upgrade.php if prompted
```

Always back up the database and `includes/config/settings.php` before upgrading.

## Gotchas

- **Salt key is critical:** The salt key in `settings.php` is used to encrypt all passwords. Back it up immediately after install. Loss = all data unrecoverable.
- **Folder/file permissions:** The `files/`, `upload/`, `includes/config/`, and `includes/avatars/` dirs must be web-server writable or the installer and file uploads will fail.
- **Character set:** Database must be created with `CHARACTER SET utf8 COLLATE utf8_general_ci` — utf8mb4 can cause issues with older Teampass versions.
- **PHP version:** Requires PHP 8.1+. PHP 8.2/8.3 are supported in v3.1.x. PHP 7.x is not supported.
- **LDAP/AD integration:** Teampass supports LDAP for authentication — configure under Admin → LDAP. LDAP passwords are not stored; only local Teampass passwords are encrypted.
- **Two-Factor Authentication:** Supported via Google Authenticator — enable per-user under Admin settings.
- **Not zero-knowledge:** The encryption key is server-side. Privileged server access = access to all passwords. Audit server access accordingly.

## Links

- Upstream source: <https://github.com/nilsteampassnet/TeamPass>
- Documentation: <https://teampass.readthedocs.io/>
- Docker Hub: <https://hub.docker.com/r/teampass/teampass/>
- Official website: <https://teampass.net>
