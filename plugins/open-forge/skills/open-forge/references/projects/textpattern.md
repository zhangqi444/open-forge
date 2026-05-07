---
name: Textpattern CMS
description: Flexible, elegant, fast, and easy-to-use CMS written in PHP. Designed for content-focused websites with a powerful template/tag system. GPL-2.0.
website: https://textpattern.com/
source: https://github.com/textpattern/textpattern
license: GPL-2.0
stars: 862
tags:
  - cms
  - content-management
  - php
  - blogging
platforms:
  - PHP
---

# Textpattern CMS

Textpattern is a clean, classic CMS built on PHP and MySQL. Known for its elegant tag-based templating system (Txp tags), it's particularly suited for content-focused websites and blogs. It's lightweight, fast, and has a small but dedicated community. Current release: v4.9.1.

Official site: https://textpattern.com/  
Source: https://github.com/textpattern/textpattern  
Docs: https://docs.textpattern.com/  
Latest release: v4.9.1  
Forum: https://forum.textpattern.com

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | PHP 7.4+ + MySQL/MariaDB + Nginx/Apache | Recommended |
| Shared hosting | PHP 7.4+ + MySQL | Works on any standard LAMP host |
| Any Linux VM / VPS | PHP 7.4+ + PostgreSQL | Supported |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- Database type: MySQL/MariaDB or PostgreSQL
- Database credentials (host, name, user, password, table prefix)
- PHP version (7.4+ required; 8.x recommended)

**Phase: First Boot**
- Admin username, password, email (entered during install wizard)
- Site name and default language

## Software-Layer Concerns

**Install:**
```bash
# Download latest release
wget https://github.com/textpattern/textpattern/releases/download/4.9.1/textpattern-4.9.1.zip
unzip textpattern-4.9.1.zip -d /var/www/html/
# Open http://yoursite.com/textpattern/setup/ in browser
# Complete web-based install wizard
```

**PHP requirements:**
- PHP 7.4+ (8.1+ recommended)
- Extensions: pdo_mysql (or pdo_pgsql), json, pcre, filter, hash
- MySQL 5.5+ / MariaDB 10.1+ / PostgreSQL 9.5+

**Nginx config:**
```nginx
server {
    listen 80;
    server_name site.example.com;
    root /var/www/html/textpattern;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**Apache:** `.htaccess` included; requires `mod_rewrite` enabled.

**Directory structure:**
- Admin panel: `textpattern/` subdirectory (can be renamed for security)
- Public files: `files/`, `images/`
- Templates: managed in database via admin UI
- Plugins: `textpattern/plugins/` (or installed via admin UI)

**Config file:** `textpattern/config.php` (auto-generated during install)
```php
$txpcfg['db'] = 'textpattern_db';
$txpcfg['user'] = 'txp_user';
$txpcfg['pass'] = 'CHANGE_ME';
$txpcfg['host'] = 'localhost';
$txpcfg['table_prefix'] = 'txp_';
$txpcfg['txpath'] = '/var/www/html/textpattern/textpattern';
```

**Multi-site support:** Available in `.tar.gz` release only; configure multiple sites sharing one codebase.

## Upgrade Procedure

1. Back up database and `files/`, `images/` directories
2. Download new release zip and overwrite files (preserve `config.php`)
3. Run upgrade wizard: navigate to admin panel — Textpattern detects the new version and runs DB migrations automatically
4. Full upgrade instructions: https://github.com/textpattern/textpattern/blob/main/UPGRADE.txt

## Gotchas

- **Tag-based templating**: Textpattern uses its own `<txp:tag />` system rather than Twig/Smarty/Blade — there's a learning curve if you're used to other CMSs
- **Templates in database**: Page templates and forms are stored in the database, not as files — use version control plugins (e.g., `cxc_template_sync`) if you want file-based templates
- **Small ecosystem**: Fewer plugins and themes compared to WordPress/Joomla — check https://textpattern.com/plugins for the plugin repository
- **Clean URL setup**: Requires proper Nginx/Apache rewrite rules for clean URLs (set in Admin → Preferences → Permanent link mode)
- **Admin directory rename**: For security, rename the `textpattern/` admin directory — update `txpath` in `config.php` accordingly
- **Active development**: v4.9.1 released 2024; development continues but at a measured pace

## Links

- Upstream README: https://github.com/textpattern/textpattern/blob/main/README.md
- Install guide: https://github.com/textpattern/textpattern/blob/main/INSTALL.txt
- Documentation: https://docs.textpattern.com/
- Plugin repository: https://textpattern.com/plugins
- Forum: https://forum.textpattern.com
- Releases: https://github.com/textpattern/textpattern/releases
