---
name: Omeka
description: Web publishing platform for libraries, museums, archives, and scholars. Build digital collections, exhibitions, and narratives. Dublin Core metadata standards. GPL-3.0 licensed.
website: https://omeka.org
source: https://github.com/omeka/Omeka
license: GPL-3.0
stars: 534
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

# Omeka

Omeka is a free, open-source web publishing platform for building digital collections, exhibitions, and narratives. Designed for scholars, museums, libraries, and archives, it adheres to Dublin Core metadata standards. Omeka Classic (this repo) is the original version; Omeka S is the newer multi-site version for larger institutions.

Official site: https://omeka.org
Source (Classic): https://github.com/omeka/Omeka
Source (Omeka S): https://github.com/omeka/omeka-s
Docs: https://omeka.org/classic/docs/
Downloads: https://omeka.org/classic/download/

Note: There are two versions:
- **Omeka Classic** (this recipe, 534 stars) — single-site, ideal for individual projects
- **Omeka S** — multi-site for institutions managing multiple collections

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | PHP 7.4+ + MySQL/MariaDB + Apache/Nginx | Recommended |
| Shared hosting | PHP + MySQL | Works on standard LAMP |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- PHP version (7.4+ required; 8.x supported in recent versions)
- MySQL/MariaDB credentials (host, database name, user, password)
- ImageMagick path (for image derivatives/thumbnails)
- Admin email and password

## Software-Layer Concerns

**Install:**

```bash
# Download latest release from https://omeka.org/classic/download/
wget https://github.com/omeka/Omeka/releases/latest/download/omeka-3.1.2.zip
unzip omeka-3.1.2.zip -d /var/www/html/omeka

# Set permissions
chown -R www-data:www-data /var/www/html/omeka
chmod -R 755 /var/www/html/omeka
chmod -R 777 /var/www/html/omeka/files/

# Install ImageMagick for image processing
sudo apt install imagemagick
```

**Configure db.ini (before running install):**

```ini
[database]
host     = "localhost"
username = "omeka_user"
password = "CHANGE_ME"
dbname   = "omeka_db"
prefix   = "omeka_"
charset  = "utf8"
```

Edit `/var/www/html/omeka/db.ini` with your database credentials.

**Run web installer:** Open `http://yoursite.com/omeka/install/install.php` in browser.

**Nginx config:**

```nginx
server {
    listen 80;
    server_name collections.example.com;
    root /var/www/html/omeka;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    location ~* /files/original/ {
        # Optionally restrict direct downloads
    }
}
```

**PHP requirements:**
- PHP 7.4+ (8.x recommended)
- Extensions: pdo_mysql, gd or Imagick, curl, exif, json

**ImageMagick path** — set in Admin > Settings > General:

```
/usr/bin/convert
```

**Key directories:**
- Config: `application/config/` and `db.ini`
- Uploaded files/derivatives: `files/`
- Plugins: `plugins/`
- Themes: `themes/`

**Plugin directory:** https://omeka.org/classic/plugins/

## Upgrade Procedure

1. Back up database and `files/` directory
2. Download new release zip from https://omeka.org/classic/download/
3. Overwrite all files except `db.ini`, `files/`, and custom plugins/themes
4. Run `http://yoursite.com/omeka/upgrade` in browser to run DB migrations
5. Upgrade guide: https://omeka.org/classic/docs/Installation/Upgrading/

## Gotchas

- **Two versions**: Omeka Classic (single site) vs Omeka S (multi-site) — different codebases; choose before installing
- **ImageMagick required**: Without it, image thumbnails and derivatives are not generated
- **files/ directory**: Must be writable by the web server; all uploaded items and derivative images go here — back it up
- **db.ini**: Contains database credentials in plain text — protect with file permissions (chmod 600) and ensure it is not web-accessible
- **Delete install script**: Remove `install/install.php` after installation to prevent reinstallation
- **PHP 8.x**: Fully supported in Omeka Classic 3.x; older versions may have PHP 8 compatibility issues
- **Plugin ecosystem**: Large plugin library at https://omeka.org/classic/plugins/ covering CSV import, OAI-PMH harvesting, Geolocation, and more

## Links

- Upstream README: https://github.com/omeka/Omeka/blob/master/README.md
- Installation guide: https://omeka.org/classic/docs/Installation/Installation/
- Upgrading: https://omeka.org/classic/docs/Installation/Upgrading/
- Plugin directory: https://omeka.org/classic/plugins/
- Theme directory: https://omeka.org/classic/themes/
- Omeka S (multi-site): https://omeka.org/s/
