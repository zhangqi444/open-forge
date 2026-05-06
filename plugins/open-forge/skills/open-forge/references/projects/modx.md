# MODX Revolution

MODX Revolution is an open-source PHP CMS and application framework offering full markup/template control, multi-language support, fine-grained permissions, and an extensible package system (Extras). The current major version is "Revolution" (3.x).

**Website:** https://modx.com/
**Source:** https://github.com/modxcms/revolution
**License:** GPL-2.0
**Stars:** ~1,395

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | PHP 8.0+ + MySQL/MariaDB + Apache/nginx | Classic LAMP/LEMP |
| Any Linux/VPS | Docker (community image) | No official image |
| Shared hosting | PHP 8.0+ + MySQL | Works; traditional deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- PHP 8.0+ environment (8.1 or 8.2 recommended)
- MySQL 5.7+ or MariaDB 10.4+
- Database name, user, password
- Site URL (used in config, affects all internal links)
- Admin username and password

### Phase 2 — Deployment
- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASS`
- `MODX_SITE_URL`
- Web root path
- PHP extensions: `pdo_mysql`, `gd`, `mbstring`, `curl`, `zip`, `xml`

---

## Software-Layer Concerns

### Download and Install
```bash
# Download latest release from https://modx.com/download
# or via CLI:
wget https://modx.com/download/direct/?id=modx-3.x.x-pl.zip -O modx.zip
unzip modx.zip -d /var/www/html/

# Navigate to web installer
# https://example.com/setup/
```

### Web Installer Flow
1. Browse to `https://yourdomain.com/setup/`
2. Choose language and click "Begin Install"
3. Enter database credentials
4. Set table prefix (default: `modx_`)
5. Set admin username/email/password
6. Complete installation
7. **Delete the `setup/` directory after installation**

```bash
# REQUIRED: Remove setup directory after install
rm -rf /var/www/html/setup/
```

### nginx Config
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    root /var/www/html;
    index index.php;

    location / {
        try_files $uri $uri/ @modx;
    }

    location @modx {
        rewrite ^(.+)$ /index.php?q=$1 last;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Protect sensitive directories
    location ~* /core/ { deny all; }
    location ~* /\.ht { deny all; }
}
```

### Apache .htaccess (included in download)
MODX ships with a `.htaccess` file that handles URL rewriting. Ensure `AllowOverride All` is set.

### Docker Compose (Community)
No official Docker image; common approach:
```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: modx
      MYSQL_USER: modx
      MYSQL_PASSWORD: modxpass
    volumes:
      - db_data:/var/lib/mysql

  web:
    image: php:8.2-apache
    ports:
      - "8080:80"
    volumes:
      - ./modx:/var/www/html
    depends_on:
      - db

volumes:
  db_data:
```

### Key Directories
| Directory | Purpose |
|-----------|---------|
| `core/` | MODX core files — never serve publicly |
| `assets/` | User-uploaded files, static assets |
| `manager/` | Admin backend |
| `connectors/` | AJAX connectors for the manager |

### Moving `core/` Outside Web Root (Security Best Practice)
MODX supports moving `core/` outside the web root. After install, edit `index.php` and `config.core.php`:
```php
// In index.php:
define('MODX_CORE_PATH', '/var/modx-core/');
define('MODX_CONFIG_KEY', 'config');
```

### Package Manager (Extras)
Install plugins, snippets, and themes from the MODX Package Manager (admin panel → Extras → Installer) or via Modmore and other third-party providers.

---

## Upgrade Procedure

```bash
# Backup database
mysqldump modx > modx_backup.sql

# Backup files (especially assets/ and core/config/)
tar -czf modx_files_backup.tar.gz /var/www/html/

# Download new MODX version
wget https://modx.com/download/direct/?id=modx-new.zip -O modx_new.zip

# Extract and run upgrade installer
unzip modx_new.zip
# Copy new files over existing installation
# Navigate to https://yourdomain.com/setup/ and choose "Upgrade"

# Remove setup/ after upgrade
rm -rf /var/www/html/setup/
```

---

## Gotchas

- **Delete `setup/` immediately**: The setup directory must be removed after installation/upgrade. It allows anyone to re-run the installer otherwise.
- **Move `core/` off web root**: The `core/` directory should not be publicly accessible. Use the `config.core.php` approach to relocate it.
- **File/cache permissions**: MODX writes extensively to `core/cache/` and `assets/`; these must be writable by the web server user.
- **No official Docker image**: Dockerizing MODX requires manual setup; no official maintained image exists.
- **Revolution vs. 2.x vs. 3.x**: "Revolution" is the current codebase. MODX 3.x dropped PHP 7 support — use PHP 8.0+ for 3.x installs.
- **Friendly URLs require rewrite rules**: `.htaccess` (Apache) or nginx `try_files` / `rewrite` rules are required for clean URLs.
- **Extras ecosystem**: Many features come as installable Extras (packages). Quality varies; test in staging before installing on production.

---

## Links
- Docs: https://docs.modx.com/3.x/en/
- Installation Guide: https://docs.modx.com/3.x/en/getting-started/installation
- Server Requirements: https://docs.modx.com/3.x/en/getting-started/server-requirements
- Download: https://modx.com/download
- Community: https://community.modx.com/
