---
name: pmwiki-project
description: PmWiki recipe for open-forge. Lightweight PHP wiki requiring no database. Covers manual install on any PHP webserver. Based on upstream docs at https://www.pmwiki.org/wiki/PmWiki/Installation.
---

# PmWiki

Lightweight, flat-file wiki requiring only PHP and a web server — no database. Stores pages as plain files in wiki.d/. GPL-3.0. Upstream: https://www.pmwiki.org. Install docs: https://www.pmwiki.org/wiki/PmWiki/Installation.

PmWiki is intentionally simple: drop files into a web-accessible directory and visit pmwiki.php to start. No database setup, no migrations. Highly extensible via a large Cookbook of PHP recipes/plugins.

## Compatible install methods

| Method | When to use |
|---|---|
| Manual unpack (any PHP host) | Standard install; works on Apache, nginx, lighttpd, IIS |
| Docker (community image) | Containerised; no official image — use community images |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Web server type?" | Apache / nginx / lighttpd / IIS | Affects URL rewriting config |
| config | "Install path on server?" | Path (e.g. /var/www/html/pmwiki) | Where pmwiki.php will live |
| config | "Admin password?" | Free-text (sensitive) | Set in local/config.php |
| config | "Site title?" | Free-text | Set in local/config.php |
| config | "Enable URL rewriting?" | Yes / No | Clean URLs require webserver rewrite rules |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Requirements | PHP 7.0+ (PHP 8.x recommended); any webserver that runs PHP |
| Database | None required — flat-file storage in wiki.d/ |
| Data directory | wiki.d/ — must be writable by the web server process |
| Config file | local/config.php — created/edited manually |
| Cookbook | cookbook/ — drop PHP recipe files here to extend functionality |
| Skins | pub/skins/ — custom themes |
| URL rewriting | Optional; requires webserver .htaccess (Apache) or equivalent config |
| Upgrades | Replace all files except wiki.d/ and local/ with new release |

## Install

Source: https://www.pmwiki.org/wiki/PmWiki/Installation

### 1. Download and unpack

```bash
cd /var/www/html
wget https://pmwiki.org/pub/pmwiki/pmwiki-latest.tgz
tar zxvf pmwiki-latest.tgz
mv pmwiki-* pmwiki   # rename to a clean directory name
```

Or download the zip: https://pmwiki.org/pub/pmwiki/pmwiki-latest.zip

### 2. Set permissions

PmWiki will try to create wiki.d/ automatically on first visit. If it cannot, create it manually:

```bash
# Option A: Create manually
mkdir /var/www/html/pmwiki/wiki.d
chmod 777 /var/www/html/pmwiki/wiki.d

# Option B: Temporarily allow PmWiki to create it (reset after)
cd /var/www/html/pmwiki
chmod 2777 .
# Visit pmwiki.php in browser — wiki.d will be created
chmod 755 .
```

### 3. Visit pmwiki.php

Open a browser to http://yourserver/pmwiki/pmwiki.php. PmWiki will check configuration and display the default home page.

### 4. Configure

Create local/config.php:

```php
<?php
$WikiTitle = "My Wiki";
$DefaultPasswords['admin'] = pmcrypt('your-admin-password');
# Enable URL rewriting (optional):
# $EnablePathInfo = 1;
```

Reference: https://www.pmwiki.org/wiki/PmWiki/InitialSetupTasks

### 5. URL rewriting (Apache, optional)

For clean URLs (e.g. /pmwiki/PageName instead of /pmwiki/pmwiki.php?n=PageName), add to .htaccess:

```apache
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ pmwiki.php?n=$1 [L,QSA]
```

And in local/config.php:
```php
$EnablePathInfo = 1;
```

### Docker (community image)

No official Docker image. Example using a community image:

```yaml
services:
  pmwiki:
    image: leobr/pmwiki:latest   # community image — verify freshness
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./wiki.d:/var/www/html/pmwiki/wiki.d
      - ./local:/var/www/html/pmwiki/local
      - ./cookbook:/var/www/html/pmwiki/cookbook
```

## Upgrade procedure

Source: https://www.pmwiki.org/wiki/PmWiki/Upgrades

```bash
cd /var/www/html
wget https://pmwiki.org/pub/pmwiki/pmwiki-latest.tgz
tar zxvf pmwiki-latest.tgz
# Copy new files over old install, PRESERVING wiki.d/ and local/
rsync -av --exclude='wiki.d' --exclude='local' pmwiki-x.y.z/ pmwiki/
```

Always read the Release Notes before upgrading: https://www.pmwiki.org/wiki/PmWiki/ReleaseNotes

## Internationalization

Download the language pack and extract to wikilib.d/:
```
https://pmwiki.org/pub/pmwiki/i18n/i18n-all.zip
```

Enable in local/config.php:
```php
XLPage('fr', 'PmWikiFr.XLPage');  # French example
```

## Gotchas

- wiki.d/ must be writable: The single most common install failure. The web server process must have write access.
- Reset permissions after auto-creation: If you used chmod 2777 . to let PmWiki create wiki.d/, reset to chmod 755 . immediately after.
- No database = no SQL injection: PmWiki's flat-file design is a security feature, not a limitation.
- Cookbook recipes may break on PHP upgrades: After a PHP version upgrade, test recipes individually.
- local/config.php is not overwritten on upgrade: Safe to upgrade without losing configuration.
- admin password is hashed with pmcrypt(): Do not use a plain-text password in config.php.

## Links

- Install docs: https://www.pmwiki.org/wiki/PmWiki/Installation
- Requirements: https://www.pmwiki.org/wiki/PmWiki/Requirements
- Initial setup tasks: https://www.pmwiki.org/wiki/PmWiki/InitialSetupTasks
- Upgrade guide: https://www.pmwiki.org/wiki/PmWiki/Upgrades
- Release notes: https://www.pmwiki.org/wiki/PmWiki/ReleaseNotes
- Cookbook (plugins): https://www.pmwiki.org/wiki/Cookbook/Cookbook
- Download: https://pmwiki.org/pub/pmwiki/
