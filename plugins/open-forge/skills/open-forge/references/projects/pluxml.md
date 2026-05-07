---
name: pluxml
description: PluXml recipe for open-forge. Flat-file XML-based blog and CMS. No database required. PHP. GPL-3.0. Source: https://github.com/pluxml/PluXml
---

# PluXml

Flat-file CMS and blogging platform. Stores all data as XML files — no database required. Supports articles, static pages with PHP scripting, categories, tags, comments, a media manager, multi-user with permission levels, themes, and plugins. Multilingual (11 languages including English, French, German, Spanish). PHP 7.2+. GPL-3.0 licensed.

Upstream: https://github.com/pluxml/PluXml | Website: https://pluxml.org | Demo: https://demo.pluxml.org

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Apache2 + PHP | mod_rewrite needed for URL rewriting |
| Any | Nginx + PHP-FPM | URL rewriting via try_files |
| Any | Docker (PHP + Apache/Nginx) | No official image; use php:8.1-apache |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Admin username | Created during first-run web setup |
| install | Admin password | Created during first-run web setup |
| install | Site title | Set during first-run web setup |
| config | URL rewriting | Enable mod_rewrite (Apache) or configure try_files (Nginx) for clean URLs |

## Software-layer concerns

- No database: all data stored as XML files under data/ directory -- must be writable by the web server
- PHP extensions required: GD (image resizing/thumbnails), XML (parsing), and optionally mail support (PHPMailer uses PHP 7.2.5+)
- PHP versions: supports PHP 5.6.34+ up to PHP 8.1.2
- URL rewriting: optional but recommended. Requires Apache mod_rewrite or Nginx try_files config
- Data directory: persist the data/ directory across upgrades; it contains all articles, pages, comments, and settings

## Install -- Apache2 + PHP

```bash
# Download latest release
wget https://www.pluxml.org/download/pluxml-latest.zip
unzip pluxml-latest.zip -d /var/www/pluxml
chown -R www-data:www-data /var/www/pluxml

# Enable Apache mod_rewrite
a2enmod rewrite
```

Apache vhost (with AllowOverride All for .htaccess URL rewriting):

```apache
<VirtualHost *:80>
    ServerName blog.example.com
    DocumentRoot /var/www/pluxml
    <Directory /var/www/pluxml>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Navigate to http://blog.example.com/ and complete the first-run setup form.

## Install -- Docker (php:apache)

```yaml
services:
  pluxml:
    image: php:8.1-apache
    restart: unless-stopped
    ports:
      - 8080:80
    volumes:
      - ./pluxml:/var/www/html
    command: >
      bash -c "docker-php-ext-install gd && apache2-foreground"
```

Extract PluXml into ./pluxml/ and access http://yourserver:8080 to run setup.

## Upgrade procedure

1. Back up the data/ directory
2. Download the latest release ZIP
3. Extract and overwrite all files except the data/ directory
4. Check the changelog for any manual migration steps

## Gotchas

- data/ must be web-server-writable: PluXml writes XML files here for every article, page, comment, and setting. Wrong permissions = broken site.
- First-run setup is web-based: navigate to the site URL on first visit; a setup form collects admin credentials and site title.
- URL rewriting is optional: without it, URLs look like ?page=1&article=2. Enable mod_rewrite / try_files for clean /category/article-slug/ URLs.
- PHP 8.2+ compatibility: check the GitHub issues for any PHP 8.2+ incompatibilities before upgrading PHP.

## Links

- Source: https://github.com/pluxml/PluXml
- Website: https://pluxml.org
- Demo: https://demo.pluxml.org
- Demo admin: https://demo.pluxml.org/core/admin/auth.php?p=/core/admin/
