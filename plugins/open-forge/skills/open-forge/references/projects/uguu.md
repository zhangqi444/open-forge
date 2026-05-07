---
name: Uguu
description: Simple lightweight temporary (or permanent) file hosting and sharing platform. One-click upload, no registration required. PHP + SQLite/MySQL/PostgreSQL. MIT licensed.
website: https://github.com/nokonoko/uguu
source: https://github.com/nokonoko/uguu
license: MIT
stars: 1151
tags:
  - file-sharing
  - file-upload
  - temporary-files
  - pastebin
platforms:
  - PHP
---

# Uguu

Uguu is a minimal, modern temporary file hosting platform. Users can upload files via drag-and-drop, paste, or API — no registration required. Files are deleted after a configurable time period (or kept permanently). Supports ShareX and other screenshot/upload tools via its API.

Source: https://github.com/nokonoko/uguu  
Live demo: https://uguu.se  
Docs: https://github.com/nokonoko/Uguu/wiki/Uguu-Configuration-&-Installation  
Latest release: v1.9.9 (December 2025)

> **Note**: Recent commit activity is sparse (1-2 commits/month in 2025, none since Dec 2025). The project is functional and stable but not under rapid development.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Nginx + PHP 8.3 + SQLite | Recommended; lightest setup |
| Any Linux VM / VPS | Nginx + PHP 8.3 + MySQL/PostgreSQL | For higher-volume deployments |
| Shared hosting | PHP 8.x + SQLite | Works on standard PHP hosts |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- Database type: SQLite, MySQL, or PostgreSQL
- Database credentials (if not SQLite)
- Maximum file size (bytes)
- File retention period (hours or `0` for permanent)
- Allowed/blocked file extensions and MIME types
- Storage directory path

**Phase: Installation**
- Admin panel credentials (configured in `config.php`)

## Software-Layer Concerns

**Requirements:**
- PHP 8.3+ with extensions: pdo, pdo_sqlite (or pdo_mysql/pdo_pgsql), json, fileinfo
- Nginx (recommended) or Apache
- Bun (for compiling frontend assets — run once at install time)
- SQLite, MySQL 5.7+, or PostgreSQL

**Install steps:**
```bash
git clone https://github.com/nokonoko/Uguu /var/www/uguu
cd /var/www/uguu

# Install frontend dependencies and build
bun install && bun run build

# Copy and configure
cp dist/ /var/www/html/uguu/ -r
cp dist/config.php /var/www/html/uguu/
# Edit config.php with your settings
```

**Key `config.php` settings:**
```php
define('UGUU_DB_CONN', 'sqlite:/var/lib/uguu/uguu.sq3');
// or: 'mysql:host=localhost;dbname=uguu'
define('UGUU_DB_USER', '');
define('UGUU_DB_PASS', '');

define('UGUU_FILES_ROOT', '/var/www/html/uguu/files/');
define('UGUU_URL', 'https://uguu.example.com/');
define('UGUU_MAX_FILE_SIZE', 128 * 1024 * 1024);  // 128 MB
define('UGUU_FILE_EXPIRY', 24);     // hours; 0 = permanent
define('UGUU_RATE_LIMIT', true);
```

**Nginx config (key directives):**
```nginx
server {
    listen 80;
    server_name uguu.example.com;
    root /var/www/html/uguu;
    index index.html index.php;

    client_max_body_size 128M;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Upload API:**
```bash
# Text response
curl -F "files[]=@/path/to/file.png" https://uguu.example.com/upload.php?output=text

# JSON response
curl -F "files[]=@/path/to/file.png" https://uguu.example.com/upload.php?output=json
```

**Data paths:**
- SQLite database: `/var/lib/uguu/uguu.sq3` (configurable)
- Uploaded files: `UGUU_FILES_ROOT` (configurable)

## Upgrade Procedure

1. `git pull` in the Uguu source directory
2. Re-run `bun install && bun run build`
3. Copy updated `dist/` to web root
4. Check changelog: https://github.com/nokonoko/Uguu/releases
5. Run any DB migration scripts if provided

## Gotchas

- **Bun required for build**: Uguu uses Bun (not Node/npm) to compile frontend assets — install Bun first: https://bun.sh/
- **Only `dist/` served**: The public web root should serve from the compiled `dist/` directory, not the source root
- **File expiry is time-based**: Files are deleted based on upload time + expiry period; a cron job or the built-in cleanup handles deletion
- **No built-in auth on upload**: Anonymous uploads by default — use rate limiting and extension blacklists to mitigate abuse
- **Admin panel**: A simple admin interface is available for managing files and blacklists
- **ShareX integration**: Configure ShareX custom uploader with your Uguu URL for screenshot uploads

## Links

- Upstream README: https://github.com/nokonoko/Uguu/blob/main/README.md
- Configuration & Installation wiki: https://github.com/nokonoko/Uguu/wiki/Uguu-Configuration-%26-Installation
- Releases: https://github.com/nokonoko/Uguu/releases
