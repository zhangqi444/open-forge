---
name: neos-cms
description: Neos CMS recipe for open-forge. Modern open source content application framework with true inline WYSIWYG editing, multi-language, multi-site, and publishing workflows. PHP/Flow framework. GPL-3.0. Based on upstream at https://github.com/neos and https://www.neos.io.
---

# Neos CMS

Modern open-source content application framework (CMS) with true inline WYSIWYG editing, publishing workspaces, multi-language, multi-site, personalisation/targeting dimensions, and an enterprise feature set. Built on the Neos Flow PHP framework. Powers large media, publisher, and enterprise websites. GPL-3.0. Upstream: https://github.com/neos. Website: https://www.neos.io.

## Compatible install methods

| Method | When to use |
|---|---|
| Composer (official) | Standard install; recommended by upstream |
| Docker | Community images; not an official upstream image |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "Database driver?" | mysql / pgsql / sqlite | MySQL/MariaDB and PostgreSQL most common for production |
| database | "Database host, name, user, password?" | Strings | |
| config | "Domain for Neos?" | FQDN | |
| config | "Admin username and password?" | Strings | Set during setup wizard or CLI |
| storage | "Web root directory?" | Host path | e.g. /var/www/neos |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP 8.1+ |
| Framework | Neos Flow (included as Composer dependency) |
| Database | MySQL / MariaDB / PostgreSQL (SQLite for dev) |
| Cache | File-based by default; Redis/Memcached for production |
| PHP extensions | Required: pdo_mysql or pdo_pgsql, mbstring, xml, curl, gd, fileinfo |
| Web server | Apache (with mod_rewrite) or nginx |
| Media storage | Local filesystem or S3/CDN |
| CLI tool | `./flow` (Neos Flow CLI) |

## Install: Composer

Source: https://www.neos.io/download-and-extend.html and https://docs.neos.io

**1. Install via Composer:**

```bash
composer create-project neos/neos-base-distribution neos
cd neos
```

**2. Configure web server** to point document root at `Web/` subdirectory:

```nginx
server {
    root /var/www/neos/Web;
    index index.php;
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

**3. Set permissions:**

```bash
./flow core:setfilepermissions www-data www-data www-data
```

**4. Configure database** in `Configuration/Settings.yaml`:

```yaml
Neos:
  Flow:
    persistence:
      backendOptions:
        driver: pdo_mysql
        dbname: neos
        user: neos
        password: CHANGEME
        host: 127.0.0.1
```

**5. Run setup wizard** at `http://yourdomain/setup` to complete installation and create admin user.

**Or CLI setup:**

```bash
./flow doctrine:migrate
./flow user:create --roles Administrator admin CHANGEME "Admin" "User"
```

## Upgrade procedure

```bash
composer update
./flow doctrine:migrate
./flow flow:cache:flush
```

Follow https://docs.neos.io/guide/upgrading for version-specific migration guides.

## Gotchas

- Setup wizard at /setup: After first install, visit `http://yourdomain/setup` to complete configuration. It walks through database, admin user, and initial site setup.
- Document root is Web/ not root: The Neos/Flow project root must NOT be web-accessible. Point your web server at the `Web/` subdirectory only.
- File permissions critical: Flow requires specific directory permissions. Run `./flow core:setfilepermissions` after install and after deployments. On shared hosting, use `sudo` as appropriate.
- Cache flush on changes: After config, template, or package changes, flush caches: `./flow flow:cache:flush`
- Content dimensions: Neos's multi-language/personalisation system uses "dimensions" — a powerful but non-trivial concept. Read the docs before modelling multi-language content.
- Not a traditional CMS: Neos uses a node-based content model (not page/post). The inline editing experience is unlike WordPress/Drupal. Budget time for the learning curve.

## Links

- Website: https://www.neos.io/
- Documentation: https://docs.neos.io/
- GitHub (organisation): https://github.com/neos
- Base distribution: https://github.com/neos/neos-base-distribution
- Download / install: https://www.neos.io/download-and-extend.html
- Upgrade guide: https://docs.neos.io/guide/upgrading
