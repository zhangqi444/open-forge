---
name: Collective Access — Providence
description: Highly configurable web-based collections management framework for museums, archives, libraries, and research institutions. Supports rich metadata standards, media types, and digital preservation. GPL-3.0 licensed.
website: https://collectiveaccess.org/
source: https://github.com/collectiveaccess/providence
license: GPL-3.0
stars: 367
tags:
  - collections-management
  - museum
  - archive
  - digital-preservation
  - metadata
platforms:
  - PHP
---

# Collective Access — Providence

CollectiveAccess Providence is the back-end cataloging and management component of the CollectiveAccess suite. It provides a highly configurable web framework for managing, describing, and discovering digital and physical collections in museum, archival, and research contexts. Supports multiple metadata standards (Dublin Core, VRA, PBCore, EAD, CDWA, etc.), rich media types (images, audio, video, 3D, documents), and a GraphQL API. The companion public-facing app is [Pawtucket2](https://github.com/collectiveaccess/pawtucket2).

Official site: https://collectiveaccess.org/
Source: https://github.com/collectiveaccess/providence
Docs: https://docs.collectiveaccess.org/providence/
Demo: https://demo.collectiveaccess.org/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (2GB+ RAM) | PHP 8.2/8.3 + MySQL/MariaDB + Apache | Recommended |
| Linux | Docker (community) | Community-maintained; check collectiveaccess/docker |

## Inputs to Collect

**Phase: Planning**
- PHP version (8.2 or 8.3 required for v2.0)
- MySQL/MariaDB credentials
- Media storage path (images, audio, video)
- ImageMagick and FFmpeg paths (for media derivatives)
- Domain/hostname
- Installation profile (determines default metadata configuration)

## Software-Layer Concerns

**System requirements (v2.0):**
- PHP 8.2 or 8.3 (8.4 untested but likely works)
- MySQL 5.7+ or MariaDB 10.2+
- Apache with mod_rewrite (AllowOverride All)
- ImageMagick 6.x+ (for image derivatives)
- FFmpeg (for video/audio)
- Ghostscript (for PDF thumbnails)
- php extensions: curl, gd or imagick, pdo_mysql, zip, xml, mbstring

**Install (from release archive):**

```bash
# Download from https://github.com/collectiveaccess/providence/releases
wget https://github.com/collectiveaccess/providence/archive/refs/tags/2.0.11.tar.gz
tar -xzf 2.0.11.tar.gz -C /var/www/html/
mv /var/www/html/providence-2.0.11 /var/www/html/providence

# Set permissions
chown -R www-data:www-data /var/www/html/providence
chmod -R 755 /var/www/html/providence
chmod -R 777 /var/www/html/providence/media/
chmod -R 777 /var/www/html/providence/app/tmp/

# Copy and edit setup.php
cp /var/www/html/providence/setup.php-dist /var/www/html/providence/setup.php
```

**Configure `setup.php` (key settings):**

```php
define('__CA_DB_HOST__', 'localhost');
define('__CA_DB_USER__', 'ca_user');
define('__CA_DB_PASSWORD__', 'CHANGE_ME');
define('__CA_DB_DATABASE__', 'collectiveaccess');

define('__CA_APP_DISPLAY_NAME__', 'My Museum Collection');
define('__CA_ADMIN_EMAIL__', 'admin@example.com');

define('__CA_BASE_DIR__', '/var/www/html/providence');
define('__CA_URL_ROOT__', '/providence');

// Media storage
define('__CA_MEDIA_BASE_DIR__', '/var/www/html/providence/media');
```

**Apache config (mod_rewrite required):**

```apache
<VirtualHost *:80>
    ServerName collections.example.com
    DocumentRoot /var/www/html/providence

    <Directory /var/www/html/providence>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

**Run web installer:** Open `http://yoursite.com/providence/install/` in browser to complete installation, select an installation profile, and create the admin account.

**Installation profiles:** Define the metadata schema — choose from standard profiles (museum_simple, museum_full, archives, etc.) or create a custom profile.

## Upgrade Procedure

1. **BACKUP** the database and `app/conf/local/`, `media/`, and `app/printTemplates/` directories
2. Download new release and replace all files except preserved directories
3. Restore `setup.php`, `app/conf/local/`, `media/`, and custom templates
4. Navigate to the login page — the system will prompt to run schema migrations
5. Full guide: https://docs.collectiveaccess.org/providence/user/upgrades/

## Gotchas

- **v2.0 requires PHP 8.2+**: Older PHP versions are not officially supported for v2.0; v1.7.x supported PHP 7.4
- **AllowOverride All required**: URL routing depends on mod_rewrite; without it, navigation breaks entirely
- **Media directory**: All uploaded images, audio, video go here — must be writable and large enough; plan for significant storage
- **Installation profiles**: Choosing the wrong profile is difficult to undo — review profile options carefully before installing
- **Not beginner-friendly**: CollectiveAccess has a steep learning curve; designed for institutions with cataloging staff familiar with metadata standards
- **Pawtucket2 is separate**: The public-facing website is a separate application (https://github.com/collectiveaccess/pawtucket2); Providence is the admin/cataloging back-end only
- **Background processing**: v2.0 improved background media processing — ensure PHP CLI is available for async jobs

## Links

- Upstream README: https://github.com/collectiveaccess/providence/blob/master/README.md
- Documentation: https://docs.collectiveaccess.org/providence/
- Installation guide: https://docs.collectiveaccess.org/providence/user/setup/install/
- Upgrade guide: https://docs.collectiveaccess.org/providence/user/upgrades/
- System requirements: https://docs.collectiveaccess.org/providence/user/setup/systemReq
- Pawtucket2 (public site): https://github.com/collectiveaccess/pawtucket2
- Releases: https://github.com/collectiveaccess/providence/releases
