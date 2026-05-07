---
name: CouchCMS
description: Simple open-source CMS for designers. Add CMS capabilities to any HTML/CSS template without writing PHP. Editable regions, cloned pages, comments, forms, RSS, search. CPAL-1.0 licensed.
website: https://www.couchcms.com/
source: https://github.com/CouchCMS/CouchCMS
license: CPAL-1.0
stars: 372
tags:
  - cms
  - php
  - designer-friendly
  - flat-file-like
platforms:
  - PHP
---

# CouchCMS

CouchCMS is a simple, open-source CMS designed for web designers who know HTML/CSS but not PHP. Add CMS functionality to any existing HTML/CSS template by embedding special XHTML tags — no PHP coding required. Features include editable regions, cloned pages (blogs, portfolios, galleries), comments, self-validating forms, RSS feeds, search, events calendar, and PayPal integration.

Official site: https://www.couchcms.com/
Source: https://github.com/CouchCMS/CouchCMS
Docs: http://docs.couchcms.com/
Forum: https://www.couchcms.com/forum/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / shared hosting | PHP 7.x+ + MySQL | Standard LAMP/LEMP stack |
| Shared hosting | PHP + MySQL | Works well on shared hosting |

## Inputs to Collect

**Phase: Planning**
- PHP version (7.x+ recommended; check current compatibility on couchcms.com)
- MySQL credentials (host, database, user, password)
- Domain/hostname
- Admin email and password

## Software-Layer Concerns

**Install:**

```bash
# Download from GitHub or couchcms.com
git clone https://github.com/CouchCMS/CouchCMS.git
# Or download zip from https://www.couchcms.com/

# Place in web root
cp -r CouchCMS/ /var/www/html/couch/

# Set permissions
chown -R www-data:www-data /var/www/html/couch/
chmod -R 755 /var/www/html/couch/
chmod 777 /var/www/html/couch/cache/
chmod 777 /var/www/html/couch/uploads/
```

**Configure (`couch/config.php`):**

```php
// Database settings
define( 'K_DB_HOST', 'localhost' );
define( 'K_DB_NAME', 'couchcms_db' );
define( 'K_DB_USER', 'couchcms_user' );
define( 'K_DB_PASSWORD', 'CHANGE_ME' );

// Table prefix
define( 'K_DB_TABLE_PREFIX', 'couch_' );

// Admin account (set before first run)
define( 'K_ADMIN_USER', 'admin' );
define( 'K_ADMIN_PASSWORD', 'CHANGE_ME' );
```

**Add CouchCMS to your HTML template:**

```php
<?php require_once( 'couch/cms.php' ); ?>
<!DOCTYPE html>
<html>
<head>
    <cms:template title='Home Page' />
</head>
<body>
    <cms:editable name='main_content' type='richtext'>
        Default content here
    </cms:editable>
</body>
</html>
<?php COUCH::invoke(); ?>
```

**First run:** Navigate to `http://yoursite.com/couch/` to complete installation and create the admin account.

**Key directories:**
- `couch/` — CouchCMS engine (do not modify)
- `couch/uploads/` — User-uploaded files (must be writable)
- `couch/cache/` — Page cache (must be writable)
- Your HTML templates — in the web root, referenced from CouchCMS

**Nginx config:**

```nginx
server {
    listen 80;
    server_name yoursite.com;
    root /var/www/html;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Upgrade Procedure

1. Back up `couch/` directory and MySQL database
2. Download new release from https://github.com/CouchCMS/CouchCMS/releases
3. Replace `couch/` directory, preserving your `config.php`
4. Navigate to `http://yoursite.com/couch/` — it will run any needed DB upgrades
5. Upgrade guide: http://docs.couchcms.com/miscellaneous/upgrading.html

## Gotchas

- **CPAL-1.0 license**: Attribution to CouchCMS in source code files cannot be waived — the CouchCMS footer/branding must remain unless you purchase a commercial license
- **Commercial license for white-labeling**: Removes the CouchCMS branding/footer and includes one month of premium support
- **PHP files as entry points**: All CouchCMS-powered pages are PHP files that include `cms.php` at the top — pure static HTML files won't work
- **Template approach**: CouchCMS doesn't have a separate "theme" system — you add CMS tags to your own HTML/CSS design files directly
- **couch/ security**: Protect `couch/` with IP restriction or authentication if you want to limit admin access to known IPs

## Links

- Upstream README: https://github.com/CouchCMS/CouchCMS/blob/master/README.md
- Documentation: http://docs.couchcms.com/
- Forum: https://www.couchcms.com/forum/
- Releases: https://github.com/CouchCMS/CouchCMS/releases
