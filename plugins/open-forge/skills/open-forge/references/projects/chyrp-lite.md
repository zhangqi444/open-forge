---
name: chyrp-lite
description: Chyrp Lite recipe for open-forge. Extra-lightweight PHP blog engine with tumbleblog features, Twig templating, and a module/feather extension system. Upstream: https://github.com/xenocrat/chyrp-lite
---

# Chyrp Lite

Extra-lightweight PHP blog engine with tumbleblog capabilities. Supports traditional blog posts, photo, quote, link, video, and audio content types ("Feathers"), plus extensible pages and a rights management system. W3C-valid, accessible, responsive HTML5. Twig-based theme system. Available in 18+ languages. Upstream: <https://github.com/xenocrat/chyrp-lite> — BSD-3-Clause.

No database required beyond SQLite (default) or MySQL/MariaDB.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Manual PHP install | <https://github.com/xenocrat/chyrp-lite/wiki/Installing> | Yes | Standard LAMP/LEMP or shared hosting with PHP. |
| Docker Compose | Community | Community | Containerised deployment. No official image. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | Database type (SQLite or MySQL/MariaDB) | Choice | SQLite needs no extra setup; MySQL needs separate DB |
| db | MySQL database name, user, password | Free-text / sensitive | Only if MySQL selected |
| admin | Admin username, password, email | Free-text / sensitive | All |
| site | Blog title and description | Free-text | First-run setup |
| domain | Public hostname | Free-text | All |

## Manual PHP install

Requirements: PHP 8.0+ with extensions: pdo_sqlite (or pdo_mysql), gd, json, xml, session, ctype, filter. Apache or Nginx.

```bash
# Download latest release
wget https://github.com/xenocrat/chyrp-lite/releases/latest/download/chyrp-lite.zip
unzip chyrp-lite.zip -d /var/www/html/chyrp/

# Set permissions
chown -R www-data:www-data /var/www/html/chyrp
chmod -R 755 /var/www/html/chyrp
chmod -R 777 /var/www/html/chyrp/{includes/caches,uploads,themes}

# Navigate to http://<host>/chyrp/install.php to run the installer
```

For SQLite, the installer creates `includes/database.yaml` and the SQLite file automatically — no manual database setup needed.

For Apache: the bundled `.htaccess` handles URL rewriting (requires `mod_rewrite`, `AllowOverride All`).

For Nginx, add to server block:

```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

## Docker Compose (community)

```yaml
version: "3.8"

services:
  chyrp:
    image: php:8.2-apache
    container_name: chyrp-lite
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./chyrp-lite:/var/www/html
      - chyrp_uploads:/var/www/html/uploads
    environment:
      - APACHE_DOCUMENT_ROOT=/var/www/html

volumes:
  chyrp_uploads:
```

After container start, install Chyrp Lite source into `./chyrp-lite/` and visit `http://<host>:8080/install.php`.

## Extension system

| Type | Purpose | Example |
|---|---|---|
| **Feathers** | Content types for blog entries | Text, Photo, Quote, Link, Video, Audio, Uploader |
| **Modules** | Site-wide functionality extensions | Cacher, Categorize, Tags, Comments, Sitemap, Analytics |
| **Themes** | Visual presentation | Default Blossom theme + 5 built-in themes |

Enable Feathers and Modules in the admin panel under Extend.

## Upgrade procedure

```bash
cd /var/www/html/chyrp

# Backup first
cp -r . /backup/chyrp-$(date +%Y%m%d)

# Download new release and extract over existing install
# (preserves config, uploads, and custom themes)
wget https://github.com/xenocrat/chyrp-lite/releases/latest/download/chyrp-lite.zip
unzip -o chyrp-lite.zip

# Visit http://<host>/chyrp/upgrade.php to run DB migrations
# Delete upgrade.php after completion
rm upgrade.php
```

## Gotchas

- **Remove install.php and upgrade.php post-install.** Leaving them accessible is a security risk. Delete them after completing the respective operations.
- **Upload directory must be writable.** Photos, videos, and audio uploaded via Feathers are stored in `/uploads`. Mount it persistently in Docker.
- **Caches directory must be writable.** The Cacher module and Twig template cache use `/includes/caches`. Non-writable cache degrades performance.
- **SQLite file location.** By default the SQLite database file is stored inside the install directory. Ensure it is not web-accessible (Chyrp places it in `/includes/` which is protected by `.htaccess`).
- **GD extension required** for image resizing (photo thumbnails in the Photo feather).
- **No multi-user blogging.** Chyrp Lite has user accounts and roles, but it's designed as a personal/single-author blog. Not suitable as a multi-author platform like WordPress Multisite.

## Upstream docs

- GitHub: <https://github.com/xenocrat/chyrp-lite>
- Install guide: <https://github.com/xenocrat/chyrp-lite/wiki/Installing>
- Upgrade guide: <https://github.com/xenocrat/chyrp-lite/wiki/Upgrading>
- Configuration: <https://github.com/xenocrat/chyrp-lite/wiki/Configuring>
