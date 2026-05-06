---
name: baikal
description: Baïkal recipe for open-forge. Covers self-hosting the lightweight CalDAV and CardDAV server. Upstream: https://github.com/sabre-io/Baikal
---

# Baïkal

Lightweight CalDAV and CardDAV server built on the sabre/dav library. Sync calendars and contacts between devices via standard protocols (CalDAV/CardDAV). Supports clients including Thunderbird (with Lightning), Apple Calendar, iOS, Android (via DAVx⁵), and any standard CalDAV/CardDAV client. Upstream: <https://github.com/sabre-io/Baikal>. Docs: <https://sabre.io/baikal/>.

**License:** GPL-3.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Download release ZIP + PHP web server | https://sabre.io/baikal/install/ | ✅ | Recommended; pre-built, no Composer required |
| Docker (ckulka/baikal) | https://hub.docker.com/r/ckulka/baikal | Community | Containerised deployment |
| Build from source (git + Composer) | https://github.com/sabre-io/Baikal | ✅ | Development or latest code |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Public URL?" | e.g. https://dav.example.com | All |
| database | "Use SQLite or MySQL?" | SQLite (default) or MySQL/MariaDB | All |
| database | "MySQL DB name/user/password?" | Free-text | MySQL only |
| admin | "Admin password?" | Free-text | Required |

## Install (release ZIP — recommended)

```bash
# Download latest release from https://github.com/sabre-io/Baikal/releases
wget https://github.com/sabre-io/Baikal/releases/download/<version>/baikal-<version>.zip
unzip baikal-<version>.zip -d /var/www/html/baikal

# Set permissions (Specific/data must be writable)
chown -R www-data:www-data /var/www/html/baikal
chmod -R 755 /var/www/html/baikal
chmod -R 777 /var/www/html/baikal/Specific

# Configure nginx or Apache to serve /var/www/html/baikal/html/
# See: https://sabre.io/baikal/install/#nginx
```

Then visit `http://yourhost/baikal/html/` to run the web-based setup wizard (database type, admin password).

## Docker (community image)

```yaml
services:
  baikal:
    image: ckulka/baikal:nginx
    restart: always
    ports:
      - 80:80
    volumes:
      - ./config:/var/www/baikal/config
      - ./Specific:/var/www/baikal/Specific
```

```bash
docker compose up -d
# Visit http://localhost/baikal/html/ for initial setup
```

## Software-layer concerns

### nginx config (key excerpt)

```nginx
server {
    listen 80;
    server_name dav.example.com;
    root /var/www/html/baikal/html;
    index index.php;

    rewrite ^/.well-known/caldav /dav.php redirect;
    rewrite ^/.well-known/carddav /dav.php redirect;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

The `.well-known` rewrites are required for CalDAV/CardDAV autodiscovery.

### Key directories

| Directory | Purpose |
|---|---|
| `Specific/` | SQLite database and config files; must be writable |
| `Specific/db/` | SQLite database file(s) |
| `config/` | Optional extra config (MySQL settings) |

### PHP requirements

PHP 7.3+ with extensions: pdo, pdo_sqlite (or pdo_mysql), curl, mbstring, xml

## Upgrade procedure

```bash
# Official: https://sabre.io/baikal/upgrade/
# 1. Back up Specific/ directory (contains database)
# 2. Download new release ZIP
# 3. Extract over existing directory (preserve Specific/)
# 4. Visit http://yourhost/baikal/html/ — upgrade wizard runs automatically if needed
```

## Gotchas

- **`Specific/` is your database.** Back it up before upgrading. All user data (calendars, contacts) lives here (SQLite) or in the MySQL DB.
- **`.well-known` rewrites are required.** Without them, iOS/macOS/Android clients using autodiscovery won't find the server.
- **No built-in TLS.** Deploy behind a reverse proxy (nginx/Caddy) with HTTPS. CalDAV/CardDAV clients typically require HTTPS in modern versions.
- **SQLite vs MySQL.** SQLite is fine for personal use and small teams. Use MySQL/MariaDB for larger deployments or when you need concurrent writes.
- **Principal URL format.** When configuring clients manually, use the principal URL: `https://dav.example.com/baikal/dav.php/principals/username/`.

## Upstream docs

- Install guide: https://sabre.io/baikal/install/
- Upgrade guide: https://sabre.io/baikal/upgrade/
- Client setup (DAVx⁵/Thunderbird/iOS): https://sabre.io/baikal/
- GitHub README: https://github.com/sabre-io/Baikal
- Releases: https://github.com/sabre-io/Baikal/releases
