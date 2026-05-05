# Baïkal

Lightweight CalDAV and CardDAV server for self-hosted calendar and contact sync. Built on the sabre/dav library, Baïkal lets you sync calendars and address books with any standards-compliant client (Apple Calendar, Thunderbird, DAVx⁵, etc.).

**Official site:** https://sabre.io/baikal/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official Docker image available |
| Any Linux host | PHP/Apache or Nginx | PHP 8.1+ with SQLite or MySQL/MariaDB |
| Raspberry Pi / ARM | Docker | ARM64 image available |
| Shared hosting | PHP | Works on any PHP 8.1+ host with write access |

---

## Inputs to Collect

### Phase 1 — Planning
- Database backend: SQLite (default, zero-setup) or MySQL/MariaDB
- Domain name / reverse-proxy configuration
- Whether to use HTTPS (strongly recommended for credential security)

### Phase 2 — Deployment
- Admin username and password
- Time zone
- Base URL (e.g. `https://dav.example.com/`)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  baikal:
    image: ckulka/baikal:nginx
    restart: always
    ports:
      - "80:80"
    volumes:
      - baikal-config:/var/www/baikal/config
      - baikal-specific:/var/www/baikal/Specific

volumes:
  baikal-config:
  baikal-specific:
```

> **Note:** The `ckulka/baikal` image is the de-facto community Docker image for Baïkal. The official project does not ship its own Docker image. Use the `nginx` tag for a self-contained nginx+PHP-FPM container.

### PHP / Web Server Install

```bash
# Download latest release
wget https://github.com/sabre-io/Baikal/releases/latest/download/baikal.zip
unzip baikal.zip -d /var/www/baikal
chown -R www-data:www-data /var/www/baikal
chmod -R 750 /var/www/baikal/Specific /var/www/baikal/config
```

Nginx vhost snippet:
```nginx
server {
    listen 443 ssl;
    server_name dav.example.com;
    root /var/www/baikal/html;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Configuration Paths
- `config/baikal.yaml` — main config (DB backend, auth, base URL)
- `Specific/` — SQLite database and user data
- Web-based setup wizard available at `/admin/` on first run

### Environment Variables (Docker)
| Variable | Default | Purpose |
|----------|---------|---------|
| (none standard) | — | Config is managed via the web admin UI or `config/baikal.yaml` |

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**PHP install:** Download new release zip, extract over existing install preserving `config/` and `Specific/` directories, run database migrations via the admin UI.

Follow the official upgrade guide: https://sabre.io/baikal/upgrade/

---

## Gotchas

- **`Specific/` must be writable** by the web server user — this is where SQLite DB and user data live.
- **No Docker image from upstream** — use `ckulka/baikal` (community-maintained, widely used).
- **Auth over HTTP sends credentials in cleartext** — always put Baïkal behind HTTPS/TLS.
- **MySQL users:** create a dedicated DB and user; Baïkal does not use the root MySQL user.
- **CardDAV URL format:** `https://dav.example.com/dav.php/addressbooks/<username>/default/`
- **CalDAV URL format:** `https://dav.example.com/dav.php/calendars/<username>/default/`
- Apple clients may auto-discover with just the base URL if configured properly.

---

## References
- GitHub: https://github.com/sabre-io/Baikal
- Official docs: https://sabre.io/baikal/
- Upgrade guide: https://sabre.io/baikal/upgrade/
- Community Docker image: https://github.com/ckulka/baikal-docker
