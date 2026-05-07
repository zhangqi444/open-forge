---
name: zenphoto
description: Zenphoto recipe for open-forge. Standalone PHP CMS for multimedia-focused websites. Photo galleries, video/audio, Zenpage blog/CMS plugin, multiple themes. PHP + MySQL. Source: https://github.com/zenphoto/zenphoto
---

# Zenphoto

Standalone PHP CMS designed for multimedia-focused personal websites. Manages image galleries, video, and audio. The optional Zenpage plugin adds a fully integrated blog/news section and static pages, enabling it to run complete websites. Ideal for illustrators, artists, designers, photographers, and musicians. GPL-2.0 licensed.

Upstream: <https://github.com/zenphoto/zenphoto> | Website: <https://www.zenphoto.org>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | LAMP (Apache + PHP + MySQL) | Traditional stack; recommended |
| Linux | LEMP (nginx + PHP-FPM + MySQL) | Also supported |
| Any | Docker (community images) | No official Docker image |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | MySQL host, database name, user, password | |
| config | Admin username + password | Set during web installer |
| config | Web root path | Directory accessible by web server |
| config (optional) | PHP GD or Imagick extension | Required for image processing |

## Software-layer concerns

### PHP requirements

- PHP 7.4+ (PHP 8.x recommended)
- Extensions: GD or Imagick (image thumbnails), exif, mbstring, fileinfo, session
- MySQL 5.6+ / MariaDB

### Key directories

| Dir | Description |
|---|---|
| `albums/` | Uploaded photos and galleries |
| `cache/` | Thumbnail cache — writable by web server |
| `themes/` | UI themes |
| `plugins/` | Optional plugins (including Zenpage) |
| `zp-data/` | Config and metadata — writable by web server |

### Writable dirs

The following must be writable by the web server user:
- `albums/`
- `cache/`
- `zp-data/`
- `themes/` (for theme settings)

## Install

```bash
# 1. Download latest release
# https://github.com/zenphoto/zenphoto/releases/latest
# OR https://www.zenphoto.org/news/installation-and-upgrading
wget https://github.com/zenphoto/zenphoto/archive/refs/heads/master.zip
unzip master.zip -d /var/www/zenphoto

# 2. Create MySQL database
mysql -u root -p <<SQL
CREATE DATABASE zenphoto CHARACTER SET utf8mb4;
CREATE USER 'zenphoto'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON zenphoto.* TO 'zenphoto'@'localhost';
SQL

# 3. Set permissions
chown -R www-data:www-data /var/www/zenphoto
chmod -R 755 /var/www/zenphoto
chmod -R 777 /var/www/zenphoto/albums /var/www/zenphoto/cache /var/www/zenphoto/zp-data

# 4. Configure web server to serve /var/www/zenphoto

# 5. Run web installer: http://yourserver/zp-core/setup.php
#    Provide DB credentials, set admin account
```

See full install guide: https://www.zenphoto.org/news/installation-and-upgrading

## Upgrade procedure

```bash
# 1. Back up files (albums/) and database
# 2. Overwrite Zenphoto files with new release (preserve albums/, zp-data/)
# 3. Visit http://yourserver/zp-core/setup.php to run DB schema migration
```

## Gotchas

- GD or Imagick PHP extension is required for thumbnail generation — without it, gallery thumbnails won't render. Install `php-gd` or `php-imagick`.
- `albums/`, `cache/`, and `zp-data/` must all be writable by the web server user. Permission errors during setup always trace back to one of these three.
- The web installer (`setup.php`) must be run after every upgrade to apply any DB schema changes.
- Run setup.php as part of initial install AND after upgrades — it checks for needed migrations.
- No official Docker image is provided upstream; use the traditional LAMP stack or a community Docker image.

## Links

- Source: https://github.com/zenphoto/zenphoto
- Website: https://www.zenphoto.org
- Installation guide: https://www.zenphoto.org/news/installation-and-upgrading
- Features: https://www.zenphoto.org/news/features
- Support forum: https://www.zenphoto.org/support/
