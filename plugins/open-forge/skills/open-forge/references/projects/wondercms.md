---
name: WonderCMS
description: The smallest flat-file CMS since 2008. No database required — install by uploading a single PHP file. MIT licensed.
website: https://www.wondercms.com
source: https://github.com/WonderCMS/wondercms
license: MIT
stars: 722
tags:
  - cms
  - flat-file
  - php
  - minimal
platforms:
  - PHP
---

# WonderCMS

WonderCMS is an ultra-minimal flat-file CMS — a single PHP file (~50KB), no database, no configuration. Upload `index.php` to any PHP host, open it in a browser, and your site is live. It includes a theme/plugin installer, in-browser editing, and consistently scores 100/100 on PageSpeed tests.

Official site: https://www.wondercms.com  
Source: https://github.com/WonderCMS/wondercms  
Latest release: v3.6.0

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any shared hosting | PHP 7.4+ | Ideal use case — drop a file and go |
| Any Linux VM / VPS | PHP 7.4+ + Nginx/Apache | Works equally well |
| Docker | PHP-FPM + Nginx | Possible but overengineered for this CMS |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- PHP version (7.4+ required)
- Admin password (set on first visit)

## Software-Layer Concerns

**Install (literally one step):**
```bash
# Option 1: Download and place
wget https://github.com/WonderCMS/wondercms/releases/latest/download/wondercms.zip
unzip wondercms.zip -d /var/www/html/

# Option 2: Clone
git clone https://github.com/WonderCMS/wondercms /var/www/html/wcms

# Open http://yoursite.com/ in browser — done
# Set admin password on first visit
```

**No database, no config file, no setup wizard.** All data stored in `data/` as JSON files.

**Nginx config:**
```nginx
server {
    listen 80;
    server_name site.example.com;
    root /var/www/html/wcms;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    # Protect data directory
    location ^~ /data/ { deny all; }
}
```

**Apache `.htaccess`** included in download — `mod_rewrite` required.

**PHP requirements:**
- PHP 7.4+ (8.x works)
- Extensions: json, openssl, zip (for theme/plugin installer)

**Data paths:**
- All site data: `data/` directory (JSON files — back this up)
- Themes: `themes/`
- Plugins: `plugins/`

**Admin access:** Click the padlock icon at bottom of any page, enter password.

## Upgrade Procedure

1. Back up `data/` directory
2. Download new `index.php` from releases and overwrite existing file
3. No migration needed — data format is backward compatible
4. Check release notes: https://github.com/WonderCMS/wondercms/releases

## Gotchas

- **Very minimal**: No user accounts, no multi-user editing, no blog/post system by default — extend via plugins
- **Single admin user**: No role-based access; one admin password for the entire site
- **Flat-file only**: All data in JSON files — fine for small sites, not designed for high traffic or large content volumes
- **Security**: Protect the `data/` directory via web server config (Nginx location block or `.htaccess`) — the default `.htaccess` does this for Apache
- **Plugin ecosystem**: Themes and plugins installable from admin panel; community-maintained at https://www.wondercms.com/themes-plugins
- **Not for complex sites**: Perfect for simple portfolios, landing pages, small business sites — not for e-commerce or complex content workflows

## Links

- Upstream README: https://github.com/WonderCMS/wondercms/blob/master/README.md
- Documentation: https://www.wondercms.com/docs
- Themes & plugins: https://www.wondercms.com/themes-plugins
- Requirements: https://www.wondercms.com/requirements
- Releases: https://github.com/WonderCMS/wondercms/releases
