---
name: framadate
description: Framadate recipe for open-forge. Online poll/scheduling tool for planning appointments and group decisions. No registration required. PHP + MySQL/PostgreSQL. CECILL-B. Source: https://framagit.org/framasoft/framadate
---

# Framadate

An open-source online scheduling and polling tool for planning meetings and group decisions. Participants vote on proposed dates or options — no registration required. Fork of the STUdS project, operated publicly by Framasoft at framadate.org. CECILL-B licensed, written in PHP, backed by MySQL or PostgreSQL. Upstream: <https://framagit.org/framasoft/framadate>. Demo: <https://framadate.org/>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux | PHP 5.6+ + Apache/NGINX | MySQL 5.5+ / MariaDB | Most common |
| Any Linux | PHP 5.6+ + Apache/NGINX | PostgreSQL | Supported |

> Note: PHP 5.6 is the documented minimum, but modern deployments should use PHP 7.4+ or PHP 8.x for security. Test compatibility before deploying.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. polls.example.com |
| "Database type?" | MySQL / PostgreSQL | |
| "Database host, name, user, password?" | Connection details | |
| "Admin email?" | email | For admin account |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Site name / branding?" | string | Displayed in UI header |
| "Allow public poll creation?" | Yes / No | Open or restricted to authenticated users |
| "SMTP for email notifications?" | host:port + credentials | Optional — poll notifications to participants |

## Software-Layer Concerns

- **Smarty templating**: Framadate uses Smarty — `cache/` and `tpl_c/` must be writable.
- **No registration required for participants**: Poll creators share a link; voters don't need accounts. Admin accounts are separate.
- **Configuration via `app/conf/configuration.php`**: Copy from `configuration.php.dist` and edit — contains DB credentials, SMTP, and app settings.
- **Two poll modes**: Date polls (pick from proposed dates) and "classic" polls (vote on arbitrary options).
- **Composer dependencies**: Run `composer install` after cloning to install PHP libraries.
- **Limited recent development**: Framadate is mature and stable but not heavily maintained — verify the latest release before deploying.

## Deployment

### NGINX + PHP-FPM

```bash
# Clone from Framagit (or download release archive)
git clone https://framagit.org/framasoft/framadate.git /var/www/framadate
cd /var/www/framadate

# Install PHP dependencies
composer install --no-dev

# Configure
cp app/conf/configuration.php.dist app/conf/configuration.php
# Edit app/conf/configuration.php with DB credentials, SMTP, site name

# Set permissions
chown -R www-data:www-data /var/www/framadate
chmod -R 755 /var/www/framadate
chmod -R 777 tpl_c/ cache/
```

NGINX vhost:
```nginx
server {
    listen 443 ssl;
    server_name polls.example.com;
    root /var/www/framadate;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* /(app|vendor)/ {
        deny all;
    }
}
```

### Database setup

```sql
CREATE DATABASE framadate CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'framadate'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL ON framadate.* TO 'framadate'@'localhost';
```

Visit `https://polls.example.com/admin/install.php` to run the web installer (creates schema and admin account).

### `configuration.php` key settings

```php
define('DB_CONNECTION_STRING', 'mysql:host=localhost;dbname=framadate;charset=utf8mb4');
define('DB_USER', 'framadate');
define('DB_PASSWORD', 'yourpassword');
define('SITE_NAME', 'My Polls');
define('ADMIN_MAIL', 'admin@example.com');
define('SMTP_HOST', 'smtp.example.com');
```

## Upgrade Procedure

1. Back up database and `app/conf/configuration.php`.
2. `git pull` or extract new release archive — overwrite files.
3. Run `composer install --no-dev` to update dependencies.
4. Check for migration scripts in `install/` and run if present.
5. Clear `tpl_c/` and `cache/` directories.

## Gotchas

- **PHP version**: Documented minimum is PHP 5.6 (very old) but use PHP 7.4+ in practice. Check https://framagit.org/framasoft/framadate for current PHP compatibility.
- **`tpl_c/` and `cache/` must be writable**: Smarty template compilation fails with permissions errors — `chmod 777` or set correct ownership.
- **Delete installer**: Remove or restrict `admin/install.php` after initial setup.
- **No registration for voters**: By design — polls are open-link. If you need restricted voting, implement IP-based or token-based limits via config.
- **Limited maintenance**: Check the Framagit issue tracker before deploying — verify it's still actively maintained for your PHP version.

## Links

- Source: https://framagit.org/framasoft/framadate
- Wiki / install guide: https://framagit.org/framasoft/framadate/wikis/home
- Live demo: https://framadate.org/
- Framasoft: https://framasoft.org/
