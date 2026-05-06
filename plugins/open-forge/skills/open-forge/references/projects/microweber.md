---
name: microweber
description: Microweber recipe for open-forge. Drag-and-drop CMS and website builder built on PHP/Laravel. Source: https://github.com/microweber/microweber. Website: https://microweber.com.
---

# Microweber

Open-source drag-and-drop CMS and website builder built on the PHP Laravel framework. Supports real-time in-page editing, e-commerce, multilingual sites, and multiple database backends (MySQL, PostgreSQL, SQLite). Installable via Composer, web installer, or Docker. Upstream: <https://github.com/microweber/microweber>. Website: <https://microweber.com>. Demo: <https://demo.microweber.org/?template=dream>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Primary recommended method |
| VPS / bare metal | Composer + Apache/Nginx | Manual PHP install |
| Cloud marketplace | DigitalOcean / Linode / Vultr / Azure | One-click marketplace apps available |
| Shared hosting | Apache/Nginx + PHP | Suitable for PHP-capable shared hosts |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| port | "Port to expose Microweber on?" | Default: 80 |
| db_type | "Database type? (mysql / pgsql / sqlite)" | SQLite recommended for small sites |
| db_host | "Database host?" | e.g. 127.0.0.1 or Docker service name |
| db_name | "Database name?" | e.g. microweber |
| db_user | "Database username?" | |
| db_pass | "Database password?" | |
| admin_user | "Admin username?" | Set during web installer |
| admin_email | "Admin email?" | |
| admin_pass | "Admin password?" | |

## Software-layer concerns

- **PHP >= 8.2** required; required extensions: `bcmath`, `bz2`, `curl`, `dom`, `fileinfo`, `gd`, `intl`, `mbstring`, `mysql` (or pgsql/sqlite3), `opcache`, `xmlrpc`, `zip`
- **Composer** required for non-Docker installs
- Supports MySQL 5.7+, PostgreSQL, SQLite 3
- Data stored in `userfiles/` and `storage/` directories — mount these as Docker volumes for persistence
- Web installer runs at `/install` on first visit when no database is configured
- `.env` file stores database credentials and app key; auto-generated on install
- Docker image: `microweber/microweber` (Docker Hub)

### Docker Compose (with MySQL)

```yaml
services:
  microweber:
    image: microweber/microweber:latest
    container_name: microweber
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - MW_DB_TYPE=mysql
      - MW_DB_HOST=db
      - MW_DB_NAME=microweber
      - MW_DB_USER=microweber
      - MW_DB_PASS=secret
    volumes:
      - microweber-userfiles:/var/www/html/userfiles
      - microweber-storage:/var/www/html/storage
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: microweber-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: microweber
      MYSQL_USER: microweber
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - microweber-db:/var/lib/mysql

volumes:
  microweber-userfiles:
  microweber-storage:
  microweber-db:
```

### Docker Compose (with SQLite — minimal)

```yaml
services:
  microweber:
    image: microweber/microweber:latest
    container_name: microweber
    restart: unless-stopped
    ports:
      - "80:80"
    environment:
      - MW_DB_TYPE=sqlite
    volumes:
      - microweber-userfiles:/var/www/html/userfiles
      - microweber-storage:/var/www/html/storage

volumes:
  microweber-userfiles:
  microweber-storage:
```

### Composer install (bare metal)

```bash
COMPOSER_MEMORY_LIMIT=-1 composer create-project microweber/microweber ./my-site --prefer-dist
cd my-site
# Configure web server to point to ./my-site as document root
# Visit http://your-domain/install to complete setup
```

### Nginx server block (bare metal)

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/microweber;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }
    location ~ /(vendor|src|config|database|bootstrap|storage|app|routes|.git|.env) {
        deny all;
        return 404;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Upgrade procedure

1. Docker: `docker compose pull && docker compose up -d`
2. Composer/bare metal:
   ```bash
   composer update
   php artisan migrate --force
   ```
3. Clear caches after upgrade: Admin → Settings → Cache → Clear all
4. Check release notes: https://github.com/microweber/microweber/releases

## Gotchas

- **Web installer on first run**: If `MW_DB_*` env vars are not set in Docker, the web installer prompts for database config at `/install`. Complete it before sharing the URL publicly.
- **File permissions**: The `userfiles/` and `storage/` directories must be writable by the web server user (typically `www-data`). Docker volumes handle this automatically; bare-metal installs may need `chown -R www-data:www-data storage/ userfiles/`.
- **SQLite for production**: SQLite is fine for small or personal sites but not recommended under concurrent write load. Use MySQL or PostgreSQL for production.
- **Memory limit**: Composer install requires `COMPOSER_MEMORY_LIMIT=-1` or at least 512 MB RAM — default limits cause OOM failures.
- **IIS**: If running on IIS, enable the URL Rewrite module and import `.htaccess` rules manually.
- **PHP extensions**: Missing extensions (especially `gd`, `intl`, `fileinfo`) cause silent failures during media upload or locale handling — verify all required extensions are installed before deployment.

## Links

- Upstream repo: https://github.com/microweber/microweber
- Website: https://microweber.com
- Documentation: https://microweber.com/docs
- Docker Hub: https://hub.docker.com/r/microweber/microweber
- Demo: https://demo.microweber.org/?template=dream
- Release notes: https://github.com/microweber/microweber/releases
