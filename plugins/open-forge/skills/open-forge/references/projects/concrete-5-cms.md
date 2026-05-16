---
name: concrete-5-cms-project
description: Concrete CMS (formerly concrete5) recipe for open-forge. Covers Composer install, ZIP download, Docker Compose, and web-server configuration. PHP CMS with inline page editing and an official marketplace for add-ons and themes.
---

# Concrete CMS

Open-source PHP CMS with inline page editing (click any element on a live page to edit it), an official marketplace for add-ons and themes, and Express Objects for custom data structures. Formerly known as concrete5; rebranded to Concrete CMS in 2021. MIT licensed.

- **GitHub:** https://github.com/concretecms/concretecms (828 stars)
- **Site:** https://www.concretecms.com
- **Download:** https://www.concretecms.com/download
- **Marketplace:** https://marketplace.concretecms.com
- **Docs:** https://documentation.concretecms.org/

## Compatible install methods

| Method | When to use |
|---|---|
| Composer (`create-project`) | Recommended for new installs; pulls latest stable |
| ZIP download | Manual install or air-gapped environments |
| Docker Compose (community image) | Containerised deployments |

## Requirements

| Component | Minimum |
|---|---|
| PHP | 8.1+ (8.2 recommended) |
| MySQL | 8.0+ |
| MariaDB | 10.4+ |
| PostgreSQL | 14+ |
| Extensions | `pdo`, `pdo_mysql`/`pdo_pgsql`, `json`, `dom`, `mbstring`, `openssl`, `curl`, `gd` or `imagick`, `fileinfo`, `zip` |
| Web server | Apache 2.4+ (mod_rewrite required) or NGINX |
| Memory limit | 128 MB minimum (256 MB recommended) |

## Install — Composer

```bash
# Install Concrete CMS into ./my-site
composer create-project -n concrete5/concrete5 my-site

# Move into your web root or configure your web server to point at my-site/
cd my-site
```

Then visit `http://your-domain/` in a browser to run the web-based installer.

## Install — ZIP download

```bash
# Download from https://www.concretecms.com/download
unzip concrete-cms-<version>.zip -d /var/www/html/my-site

# Set permissions
chown -R www-data:www-data /var/www/html/my-site
find /var/www/html/my-site -type d -exec chmod 755 {} \;
find /var/www/html/my-site -type f -exec chmod 644 {} \;

# application/files and application/config must be writable
chmod -R 775 /var/www/html/my-site/application/files
chmod -R 775 /var/www/html/my-site/application/config
```

Visit the site URL to run the installer.

## Docker Compose (community image)

```yaml
services:
  concretecms:
    image: concrete5/concrete5:latest
    container_name: concretecms
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - CONCRETE5_DB_SERVER=db
      - CONCRETE5_DB_DATABASE=concretecms
      - CONCRETE5_DB_USERNAME=concretecms
      - CONCRETE5_DB_PASSWORD=changeme
    volumes:
      - concrete-files:/var/www/html/application/files
      - concrete-config:/var/www/html/application/config
      - concrete-packages:/var/www/html/packages
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: concretecms-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: concretecms
      MYSQL_USER: concretecms
      MYSQL_PASSWORD: changeme
      MYSQL_ROOT_PASSWORD: changeme-root
    volumes:
      - concrete-db:/var/lib/mysql

volumes:
  concrete-files:
  concrete-config:
  concrete-packages:
  concrete-db:
```

## Apache vhost

```apache
<VirtualHost *:80>
    ServerName example.com
    DocumentRoot /var/www/html/my-site

    <Directory /var/www/html/my-site>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/concretecms_error.log
    CustomLog ${APACHE_LOG_DIR}/concretecms_access.log combined
</VirtualHost>
```

Ensure `mod_rewrite` is enabled: `sudo a2enmod rewrite && sudo systemctl reload apache2`

## NGINX server block

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/html/my-site;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Block direct access to application internals
    location ~ ^/application/(cache|config|files/cache|logs|tmp) {
        deny all;
    }
}
```

## Key directories

| Path | Purpose |
|---|---|
| `application/files/` | User uploads and file manager — **must be writable, volume-mount in Docker** |
| `application/config/` | Generated config (database, site settings) — **must be writable** |
| `application/cache/` | Page / block cache — writable |
| `packages/` | Installed marketplace add-ons |
| `concrete/` | Core CMS files — do not modify |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Install method? (Composer / ZIP / Docker)" | |
| db | "Database type? (MySQL / MariaDB / PostgreSQL)" | |
| db | "Database host, name, user, password?" | |
| site | "Site URL?" | Used during install wizard |
| site | "Admin email and password?" | First admin account |
| mail | "SMTP server details?" | Concrete CMS sends email for user registration, notifications |

## Upgrading

In the Concrete CMS Dashboard: **System & Settings → Update Concrete CMS → Check for Updates**.

Or via CLI (Concrete CLI tool):

```bash
cd /var/www/html/my-site
./vendor/bin/concrete5 c5:update
```

## Notes

- The `application/` directory persists all user data — back it up before upgrading.
- After a major upgrade, run **Dashboard → System & Settings → Clear Cache** if you see layout issues.
- Marketplace add-ons are installed via Dashboard → Extend Concrete → Add Functionality.
- Concrete CMS supports multi-language sites natively via the Multilingual package.
- Demo available at https://www.concretecms.com/about/try-concrete-cms
