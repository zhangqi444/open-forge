---
name: Omeka S
description: Web publication system for universities, galleries, libraries, archives, and museums. Multi-site, shared metadata pools, Dublin Core. PHP + MySQL. GPL-3.0 licensed.
website: https://omeka.org/s/
source: https://github.com/omeka/omeka-s
license: GPL-3.0
stars: 481
tags:
  - digital-collections
  - museum
  - archive
  - library
  - publishing
  - php
platforms:
  - PHP
---

# Omeka S

Omeka S is the next-generation Omeka platform for institutions. Unlike Omeka Classic (single site), Omeka S supports multiple independently curated sites that share a collaboratively built pool of items, media, and metadata. Designed for universities, galleries, libraries, archives, and museums. Built on PHP with a MySQL/MariaDB backend.

Official site: https://omeka.org/s/
Source: https://github.com/omeka/omeka-s
User manual: https://omeka.org/s/docs/user-manual
Downloads: https://github.com/omeka/omeka-s/releases
Module directory: https://omeka.org/s/modules/
Theme directory: https://omeka.org/s/themes/

Note: See also `omeka.md` for **Omeka Classic** (single-site, simpler setup).

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | PHP 8.1+ + MySQL/MariaDB + Apache | Recommended |
| Any Linux VM / VPS | PHP 8.1+ + MySQL/MariaDB + Nginx | Works with PHP-FPM |
| Shared hosting | PHP 8.1+ + MySQL | Standard LAMP stack |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- PHP version (8.1+ required)
- MySQL/MariaDB credentials (host, database, user, password)
- ImageMagick version (6.7.5+ for thumbnails)
- Admin email and password

## Software-Layer Concerns

**Install from release zip (recommended):**

```bash
# Download from https://github.com/omeka/omeka-s/releases
wget https://github.com/omeka/omeka-s/releases/latest/download/omeka-s.zip
unzip omeka-s.zip -d /var/www/html/
mv /var/www/html/omeka-s-* /var/www/html/omeka-s

# Permissions
chown -R www-data:www-data /var/www/html/omeka-s
chmod -R 755 /var/www/html/omeka-s
chmod -R 775 /var/www/html/omeka-s/files/
```

**Configure database (`config/database.ini`):**

```ini
[database]
user     = "omeka_user"
password = "CHANGE_ME"
dbname   = "omeka_s_db"
host     = "localhost"
```

**Run web installer:** Open `http://yoursite.com/omeka-s/` in browser to complete setup.

**Install from GitHub (for development):**

```bash
git clone https://github.com/omeka/omeka-s.git /var/www/html/omeka-s
cd /var/www/html/omeka-s
npm install
npx gulp init
# Edit config/database.ini, then open browser to complete install
```

**PHP requirements:**
- PHP 8.1+ (latest stable preferred)
- Extensions: PDO, pdo_mysql, xml, gd or Imagick

**ImageMagick:** Required for thumbnails — must be version 6.7.5+.

```bash
sudo apt install imagemagick
```

**Apache config (AllowOverride required):**

```apache
<Directory /var/www/html/omeka-s>
    AllowOverride All
    Require all granted
</Directory>
```

Ensure `mod_rewrite` is enabled: `sudo a2enmod rewrite`

**Nginx config:**

```nginx
server {
    listen 80;
    server_name collections.example.com;
    root /var/www/html/omeka-s;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    location ~* /files/original/ { }
}
```

**Key directories:**
- Config: `config/`
- Uploaded files: `files/`
- Modules: `modules/`
- Themes: `themes/`

## Upgrade Procedure

1. **Back up** database and `files/`, `modules/`, `themes/`, `config/` directories
2. Download new release zip from https://github.com/omeka/omeka-s/releases
3. Replace all files **except** `config/local.config.php`, `config/database.ini`, `modules/`, `themes/`, `files/`
4. Restore your preserved directories
5. Open your site in browser and run any pending migrations
6. Full guide: https://omeka.org/s/docs/user-manual/install/#updating

## Gotchas

- **Omeka Classic vs Omeka S**: Different codebase, different database schema — not interchangeable. Omeka S is for institutions needing multiple sites; Classic is simpler for single projects
- **AllowOverride All**: Apache requires `AllowOverride All` and `mod_rewrite` — without this, URL routing breaks
- **ImageMagick version**: Version must be 6.7.5+ — older versions produce broken thumbnails
- **files/ permissions**: Must be writable by the web server; all uploaded media and derivatives go here — back up regularly
- **database.ini protection**: Contains plaintext credentials — ensure it is not web-accessible (the .htaccess in config/ handles this for Apache)
- **Module ecosystem**: Large module library at https://omeka.org/s/modules/ for CSV import, IIIF, Mapping, Scripto, etc.
- **Node.js for dev install**: Only needed for the `npx gulp init` step when installing from GitHub; not required for release zip installs

## Links

- Upstream README: https://github.com/omeka/omeka-s/blob/develop/README.md
- User manual: https://omeka.org/s/docs/user-manual
- Installation guide: https://omeka.org/s/docs/user-manual/install/
- Module directory: https://omeka.org/s/modules/
- Theme directory: https://omeka.org/s/themes/
- Releases: https://github.com/omeka/omeka-s/releases
