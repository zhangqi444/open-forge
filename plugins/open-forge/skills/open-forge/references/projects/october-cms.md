---
name: october-cms
description: October CMS recipe for open-forge. Covers Composer install on PHP/nginx or Apache. October CMS is a Laravel-based CMS platform. Note that while open source, a license subscription is required after the first year for marketplace/updates access.
---

# October CMS

CMS platform built on the Laravel PHP framework. Known for its clean, simple design philosophy. Supports a plugin marketplace, theme system, backend form builder, and a strong developer community. Upstream: <https://github.com/octobercms/october>. Website: <https://octobercms.com>. Docs: <https://docs.octobercms.com>.

**License:** Proprietary (EULA — free for first year, license subscription required for ongoing Marketplace/updates access) · **Language:** PHP (Laravel) · **Default port:** 80/443 · **Stars:** ~11,100

> **Note:** October CMS requires a paid license after the first year for marketplace access and updates. Review the [EULA](https://github.com/octobercms/october/blob/develop/LICENSE.md) before deploying for commercial use.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Composer (recommended) | <https://docs.octobercms.com/3.x/setup/installation.html> | ✅ | Standard install on any PHP server. |
| Manual archive | <https://octobercms.com/download> | ✅ | Shared hosting or servers without Composer. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which web server — nginx or Apache?" | AskUserQuestion | Determines vhost config. |
| php | "PHP version available? (8.1+ required, 8.2+ recommended)" | Free-text | Verify before install. |
| domain | "What domain will October CMS serve?" | Free-text | All methods. |
| database | "Database engine: MySQL, MariaDB, PostgreSQL, or SQLite?" | AskUserQuestion | All methods. |
| db_credentials | "Database host, name, username, password?" | Free-text (sensitive) | MySQL/MariaDB/PostgreSQL. |
| env | "Production or development environment?" | AskUserQuestion: production / development | All methods. |

## Install — Composer (recommended)

Reference: <https://docs.octobercms.com/3.x/setup/installation.html>

```bash
# Install into directory 'myoctober'
composer create-project october/october myoctober

cd myoctober

# Run the interactive installer (sets up DB, admin account, etc.)
php artisan october:install
```

The `october:install` wizard configures:
- Database connection
- Administrator account
- Application URL and encryption key
- Demo content (optional)

### nginx vhost

```nginx
server {
    listen 443 ssl;
    server_name cms.example.com;
    root /var/www/myoctober;

    index index.php;

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ ^/index.php {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Block sensitive paths
    location ~ /\. { deny all; }
    location ~* ^/(config|bootstrap|modules|storage|vendor|plugins)/ { deny all; }
}
```

### Apache .htaccess

October ships with `.htaccess` in the project root — enable `AllowOverride All` in your vhost and mod_rewrite will handle routing automatically.

## Software-layer concerns

| Concern | Detail |
|---|---|
| PHP version | Requires PHP 8.1+; PHP 8.2+ recommended. Extensions: pdo, pdo_mysql or pdo_pgsql, mbstring, openssl, curl, json, gd, xml, fileinfo, zip. |
| Database | MySQL 5.7+ / MariaDB 10.3+ / PostgreSQL 9.6+ / SQLite 3. Config in `config/database.php` or `.env`. |
| .env file | Contains APP_KEY, DB_*, MAIL_* settings. Never commit to git. |
| storage/ | Writable by web server (www-data). Contains caches, logs, uploads, media library. |
| plugins/ | Third-party plugins installed here via `php artisan plugin:install Vendor.Plugin` or October marketplace. |
| themes/ | Active theme set in Settings → CMS → Theme. |
| Cron | Required for scheduled tasks: `* * * * * php /path/to/artisan schedule:run >> /dev/null 2>&1` |
| Queue | Optional but recommended for emails/async jobs: `php artisan queue:work` |
| Marketplace | Requires an October CMS account and active license for plugin/theme downloads. |

## Upgrade procedure

Reference: <https://docs.octobercms.com/3.x/setup/updating.html>

```bash
cd /var/www/myoctober

# Put site in maintenance mode (optional)
php artisan down

# Pull updates
php artisan october:update

# Or use Composer
composer update

# Run any pending migrations
php artisan october:migrate

# Clear caches
php artisan cache:clear
php artisan config:clear

php artisan up
```

Back up the database and `storage/` directory before any major version update.

## Gotchas

- **License required after year 1:** October CMS is free to install but requires a paid license to receive updates and access the plugin/theme Marketplace beyond the first year. See <https://octobercms.com/pricing>.
- **APP_KEY must be preserved:** The encryption key in `.env` is used for encrypting session data and sensitive fields. Never regenerate it on an existing install — it will invalidate all sessions and encrypted values.
- **storage/ permissions:** The entire `storage/` tree must be writable by the PHP process. Run `chmod -R 775 storage && chown -R www-data:www-data storage` after install.
- **Cron required for scheduled tasks:** Email queues, cache pruning, and other scheduled tasks require the cron entry for `schedule:run`. Without it, those features silently fail.
- **Plugin compatibility:** Plugins are versioned against specific October CMS versions. Check plugin compatibility before upgrading the CMS version.
- **Composer memory limit:** The initial `composer create-project` can require a lot of memory. Set `COMPOSER_MEMORY_LIMIT=-1` if it fails with memory errors.

## Upstream links

- GitHub: <https://github.com/octobercms/october>
- Documentation: <https://docs.octobercms.com>
- Installation guide: <https://docs.octobercms.com/3.x/setup/installation.html>
- Plugin marketplace: <https://octobercms.com/plugins>
- Pricing / licensing: <https://octobercms.com/pricing>
