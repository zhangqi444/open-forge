---
name: baikal
description: Baïkal recipe for open-forge. Lightweight CalDAV and CardDAV server built on PHP and sabre/dav. Source: https://github.com/sabre-io/Baikal. Website: https://sabre.io/baikal/.
---

# Baïkal

Lightweight CalDAV (calendars) and CardDAV (contacts) server built on PHP and the [sabre/dav](https://sabre.io/dav/) library. Ideal for syncing calendars and address books across devices without a full Nextcloud install. Supports MySQL, PostgreSQL, and SQLite backends. Simple web admin panel for user and calendar management. License: GPL-3.0. Upstream: <https://github.com/sabre-io/Baikal>. Website: <https://sabre.io/baikal/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | PHP + Apache/Nginx | Most common; minimal requirements |
| VPS / bare metal | Docker Compose | Containerized with NGINX and PHP-FPM |
| Home server / Pi | PHP + Apache/Nginx | Runs well on low-powered hardware |
| Shared hosting | Apache + PHP | Works on PHP-capable shared hosts |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Domain/subdomain for Baïkal?" | e.g. dav.example.com |
| port | "Port to expose on (if Docker)?" | Default: 80 |
| db_type | "Database type? (sqlite / mysql / pgsql)" | SQLite is simplest for personal use |
| db_host | "Database host (if mysql/pgsql)?" | |
| db_name | "Database name?" | e.g. baikal |
| db_user | "Database user?" | |
| db_pass | "Database password?" | |
| admin_pass | "Admin password for web panel?" | Set during first-run wizard |
| timezone | "Timezone?" | e.g. Europe/Paris, America/New_York |

## Software-layer concerns

- **PHP 8.1+** required; required extensions: `curl`, `dom`, `intl`, `mbstring`, `pdo`, `pdo_sqlite` (or pdo_mysql/pdo_pgsql)
- Web server must pass all requests to `html/index.php` (see Nginx config below)
- First-run setup wizard at `https://your-domain/admin/` — must be completed before syncing clients
- Config files live in `config/` directory — mount this as a Docker volume for persistence
- SQLite database stored in `Specific/` directory — also needs to be a persistent volume
- Admin panel: `https://your-domain/admin/`
- CalDAV endpoint: `https://your-domain/cal.php/`
- CardDAV endpoint: `https://your-domain/card.php/`
- Principal URL (for auto-discovery): `https://your-domain/`

### Docker Compose

```yaml
services:
  baikal:
    image: ckulka/baikal:nginx
    container_name: baikal
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - baikal-config:/var/www/baikal/config
      - baikal-specific:/var/www/baikal/Specific

volumes:
  baikal-config:
  baikal-specific:
```

### Docker Compose (with MySQL)

```yaml
services:
  baikal:
    image: ckulka/baikal:nginx
    container_name: baikal
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - baikal-config:/var/www/baikal/config
      - baikal-specific:/var/www/baikal/Specific
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: baikal-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: baikal
      MYSQL_USER: baikal
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - baikal-db:/var/lib/mysql

volumes:
  baikal-config:
  baikal-specific:
  baikal-db:
```

### Bare-metal install (Debian/Ubuntu)

```bash
# Download the release package from GitHub
wget https://github.com/sabre-io/Baikal/releases/latest/download/baikal.zip
unzip baikal.zip -d /var/www/baikal
chown -R www-data:www-data /var/www/baikal
# Set up web server (see Nginx config below)
# Visit https://your-domain/admin/ to complete setup
```

### Nginx server block

```nginx
server {
    listen 443 ssl;
    server_name dav.example.com;

    ssl_certificate /etc/letsencrypt/live/dav.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dav.example.com/privkey.pem;

    root /var/www/baikal/html;
    index index.php;

    # Redirect to HTTPS
    rewrite ^/.well-known/caldav$ /dav.php redirect;
    rewrite ^/.well-known/carddav$ /dav.php redirect;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Block access to config and Specific dirs
    location ~ /(config|Specific)/ {
        deny all;
        return 404;
    }
}
```

### Client configuration

| Client | CalDAV URL | CardDAV URL |
|---|---|---|
| Thunderbird / Davx5 | `https://dav.example.com/cal.php/` | `https://dav.example.com/card.php/` |
| Apple Calendar/Contacts | `https://dav.example.com/` (auto-discovery) | same |
| Outlook (DAVMail or CalDAV-Sync) | `https://dav.example.com/cal.php/principals/<user>/` | — |

## Upgrade procedure

1. **Docker**: `docker compose pull && docker compose up -d` (config/data volumes are preserved)
2. **Bare metal**:
   - Download new release zip
   - Replace all files **except** `config/` and `Specific/` directories
   - Visit admin panel — Baïkal runs any needed database migrations automatically
3. Full upgrade guide: https://sabre.io/baikal/upgrade/

## Gotchas

- **Admin panel exposed**: The `/admin/` path is publicly accessible by default. Protect it with IP allowlisting or HTTP basic auth in your web server if the server is internet-facing.
- **`.well-known` redirects**: Apple devices use `.well-known/caldav` and `.well-known/carddav` for auto-discovery. Configure the rewrites in Nginx/Apache or iOS/macOS clients will fail to discover the server.
- **SQLite concurrent writes**: SQLite handles concurrent reads well but struggles under heavy concurrent writes. For multi-user deployments with many simultaneous syncs, use MySQL or PostgreSQL.
- **PHP timezone**: Set `date.timezone` in `php.ini` to your local timezone. Mismatched timezones between PHP and the database cause recurring events to shift.
- **Protect config/ and Specific/ directories**: These directories contain your database file (if using SQLite) and config with admin credentials. Ensure the web server denies direct access (the Nginx config above does this).
- **No user self-service**: Baïkal has no user registration or self-service portal. All user accounts must be created by an admin via the web panel.

## Links

- Upstream repo: https://github.com/sabre-io/Baikal
- Website: https://sabre.io/baikal/
- Installation guide: https://sabre.io/baikal/install/
- Upgrade guide: https://sabre.io/baikal/upgrade/
- sabre/dav documentation: https://sabre.io/dav/
- German installation guide: https://github.com/JsBergbau/BaikalAnleitung
- Release downloads: https://github.com/sabre-io/Baikal/releases
