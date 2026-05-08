---
name: baikal-project
description: Baïkal recipe for open-forge. Lightweight CalDAV and CardDAV server for calendar and contacts sync. Covers Docker and manual PHP install. Based on upstream docs at https://sabre.io/baikal/ and https://github.com/sabre-io/Baikal.
---

# Baïkal

Lightweight CalDAV and CardDAV server built on sabre/dav. Syncs calendars, contacts, and tasks with any standard client (Thunderbird, DavX5, iOS, Android, GNOME Calendar, etc.). PHP-based, SQLite or MySQL. GPL-3.0. Upstream: https://github.com/sabre-io/Baikal. Docs: https://sabre.io/baikal/.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (ckulka/baikal) | Simplest; well-maintained community image |
| Manual PHP install (Apache/nginx) | Existing LAMP/LEMP server |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Docker or manual PHP?" | Docker / Manual | Drives which section |
| config | "Admin password?" | Free-text (sensitive) | Set in web installer |
| database | "SQLite or MySQL?" | SQLite / MySQL | SQLite is simplest; MySQL for larger deployments |
| database | "MySQL host / name / user / password?" | Four values | MySQL path only |
| network | "Domain name?" | FQDN | e.g. dav.example.com |
| network | "Port to expose?" | Number (default 80) | |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP (see https://github.com/sabre-io/Baikal for supported version) |
| Database | SQLite (default, zero-config) or MySQL/MariaDB |
| Web server | Apache or nginx |
| Config dir | config/ — persisted volume in Docker |
| Data dir | Specific/ — stores calendar/contacts data |
| Well-known redirects | /.well-known/caldav and /.well-known/carddav must redirect to /dav.php |
| Setup wizard | Available at http://yourdomain/ on first run |

## Install: Docker

Source: https://sabre.io/baikal/install/ and https://github.com/ckulka/baikal-docker

Well-maintained community image: ckulka/baikal (nginx or apache variants).

```yaml
services:
  baikal:
    image: ckulka/baikal:nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - config:/var/www/baikal/config
      - data:/var/www/baikal/Specific

volumes:
  config:
  data:
```

```bash
docker compose up -d
# Visit http://localhost/ to complete the setup wizard
```

The setup wizard will ask for:
- Admin email and password
- Database type (SQLite or MySQL) and credentials
- Timezone

## Install: Manual PHP

Source: https://sabre.io/baikal/install/

### Requirements

- PHP (check https://github.com/sabre-io/Baikal for current supported version)
- MySQL/MariaDB or SQLite
- Apache or nginx

### Steps

1. Download the latest release from https://github.com/sabre-io/Baikal/releases

```bash
wget https://github.com/sabre-io/Baikal/releases/latest/download/baikal.zip
unzip baikal.zip -d /var/www/html/
```

2. Set permissions:
```bash
chown -R www-data:www-data /var/www/html/baikal
chmod -R 755 /var/www/html/baikal
chmod -R 775 /var/www/html/baikal/Specific /var/www/html/baikal/config
```

3. Apache virtual host:
```apache
<VirtualHost *:443>
    ServerName dav.example.com
    DocumentRoot /var/www/html/baikal/html
    RewriteEngine On
    RewriteRule /.well-known/carddav /dav.php [R=308,L]
    RewriteRule /.well-known/caldav  /dav.php [R=308,L]
    <Directory /var/www/html/baikal/html>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

4. nginx config:
```nginx
server {
    listen 443 ssl;
    server_name dav.example.com;
    root /var/www/html/baikal/html;
    index index.php;
    rewrite ^/.well-known/caldav /dav.php redirect;
    rewrite ^/.well-known/carddav /dav.php redirect;
    location ~ ^(.+\.php)(.*)$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

5. Visit http://dav.example.com/ to run the setup wizard.

## Connecting clients

After setup, client configuration:
- **CalDAV URL:** https://dav.example.com/dav.php/calendars/username/default/
- **CardDAV URL:** https://dav.example.com/dav.php/addressbooks/username/default/

Guides:
- Android (DavX5): https://sabre.io/baikal/clients/davdroid/
- iOS: Settings → Accounts → Add Account → Other → CalDAV/CardDAV
- Thunderbird: Thunderbird > Calendar > new → Network → CalDAV/CardDAV

## Upgrade procedure

Source: https://sabre.io/baikal/upgrade/

**Docker:**
```bash
docker compose pull && docker compose up -d
```

**Manual:** Download new release zip, extract, overwrite files except config/ and Specific/ directories.

Always back up the config/ and Specific/ directories before upgrading.

## Gotchas

- Well-known redirects are required: Many clients (iOS, Android) auto-discover CalDAV/CardDAV via /.well-known/ paths. Without rewrite rules, auto-discovery fails and users must enter full DAV URLs manually.
- config/ and Specific/ must be persisted: These directories hold all configuration and data. Losing them means losing all calendars and contacts.
- HTTPS strongly recommended: CalDAV/CardDAV credentials are sent per-request. Always use TLS in production.
- ckulka/baikal is a community image: Not maintained by the Baïkal project. It is well-maintained and widely used, but verify image freshness: https://hub.docker.com/r/ckulka/baikal
- Setup wizard runs once: After initial setup, the wizard is disabled. Re-enabling requires manual steps in config/.

## Links

- Docs: https://sabre.io/baikal/
- Install guide: https://sabre.io/baikal/install/
- Upgrade guide: https://sabre.io/baikal/upgrade/
- GitHub: https://github.com/sabre-io/Baikal
- Releases: https://github.com/sabre-io/Baikal/releases
- Docker image (ckulka): https://hub.docker.com/r/ckulka/baikal
