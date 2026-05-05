---
name: october-cms
description: October CMS recipe for open-forge. PHP CMS built on the Laravel framework. Covers Composer install (recommended), Docker local dev, server requirements, and plugin ecosystem. Upstream: https://octobercms.com
---

# October CMS

Open-source PHP content management system built on the Laravel framework. Designed for simplicity and developer productivity — clean separation of front-end themes and back-end plugins.

11,133 stars · MIT

Upstream: https://github.com/octobercms/october
Website: https://octobercms.com
Docs: https://docs.octobercms.com/
Changelog: https://octobercms.com/changelog

**License note**: October CMS is open source (MIT). New accounts include a complimentary license for the first year. After the first year, a paid license is required to receive updates and access the Marketplace. The core software remains open source; the update/marketplace service is commercial.

## What it is

October CMS focuses on developer experience:

- **Theme system** — File-based HTML/CSS/JS themes with Twig templating
- **Plugin architecture** — Modular Laravel packages for CMS functionality
- **Tailor** — Low-code content modeling system (built-in database-backed content types)
- **RainLab plugins** — Official plugin suite: Blog, Pages, Translate, User, Sitemap, and more
- **Form Builder** — Visual admin form builder
- **REST API** — Built-in API for headless/hybrid use
- **Media Manager** — File uploads, images, documents
- **Clean admin** — Polished, developer-friendly back office

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Composer (recommended) | https://docs.octobercms.com/3.x/setup/installation.html | Standard production and dev install |
| `october:install` command | https://docs.octobercms.com/3.x/setup/installation.html | Wizard-driven setup after Composer install |
| Softaculous / cPanel auto-installer | Hosting panels | Shared hosting |

## Requirements

- PHP 8.0 or higher (8.1/8.2 recommended)
- PHP extensions: `curl`, `json`, `mbstring`, `openssl`, `pdo`, `zip`, `gd` or `imagick`
- MySQL 5.7+ / MariaDB 10.4+ / PostgreSQL 9.6+ / SQLite 3.8.8+
- Apache (with `mod_rewrite`) or Nginx
- Composer 2.x

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "What domain will October CMS be served on?" | All |
| database | "Database type: MySQL, PostgreSQL, or SQLite?" | All |
| db_creds | "Database name, user, and password?" | MySQL/PostgreSQL |
| admin | "Admin email and password?" | All |

## Composer install (recommended)

Upstream: https://docs.octobercms.com/3.x/setup/installation.html

### 1. Create project via Composer

    composer create-project october/october mysite

This creates a `mysite/` directory with all dependencies installed.

### 2. Configure environment

    cd mysite
    cp .env.example .env
    php artisan key:generate

Edit `.env` for your database:

    DB_CONNECTION=mysql
    DB_HOST=127.0.0.1
    DB_PORT=3306
    DB_DATABASE=october
    DB_USERNAME=october
    DB_PASSWORD=your-password

    APP_URL=https://yourdomain.com
    APP_ENV=production
    APP_DEBUG=false

### 3. Run install wizard

    php artisan october:install

This runs database migrations and optionally seeds demo data.

### 4. Set permissions

    chmod -R 755 storage/ bootstrap/cache/
    chmod -R 777 storage/app/ storage/logs/ storage/framework/ bootstrap/cache/

### 5. Web server configuration

**Apache** (in `.htaccess` or virtual host):

    <VirtualHost *:80>
        ServerName yourdomain.com
        DocumentRoot /var/www/mysite
        <Directory /var/www/mysite>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>

The project includes a `.htaccess` file — requires `mod_rewrite` enabled.

**Nginx**:

    server {
        listen 80;
        server_name yourdomain.com;
        root /var/www/mysite;
        index index.php;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }

        location ~ /\. {
            deny all;
        }
    }

### 6. Admin panel

Access the backend at https://yourdomain.com/backend

Default admin credentials are set during `php artisan october:install`.

## Useful artisan commands

| Command | Description |
|---|---|
| `php artisan october:install` | Run setup wizard (initial install) |
| `php artisan october:up` | Run database migrations |
| `php artisan october:update` | Update October CMS and all plugins |
| `php artisan plugin:install Author.PluginName` | Install a plugin from the Marketplace |
| `php artisan plugin:refresh Author.PluginName` | Refresh plugin migrations |
| `php artisan cache:clear` | Clear application cache |

## Installing RainLab plugins

Official plugin suite from https://github.com/rainlab:

    php artisan plugin:install RainLab.Blog
    php artisan plugin:install RainLab.Pages
    php artisan plugin:install RainLab.Translate
    php artisan plugin:install RainLab.User

## Upgrade

    composer update
    php artisan october:up

Review the changelog at https://octobercms.com/changelog before upgrading major versions.

## Gotchas

- **License requirement after year one** — October CMS requires a paid license to receive updates from the Marketplace after the first year. The core software is MIT-licensed and runs indefinitely without a license; you just won't get updates via `october:update`.
- **`DocumentRoot` must point to project root** — Not to `public/`. October CMS uses `.htaccess` to route all requests; the web server must serve from the project root directory.
- **Storage permissions** — `storage/` and `bootstrap/cache/` must be writable by the web server user. Permission errors are the most common install issue.
- **`APP_DEBUG=false` in production** — Never run with `APP_DEBUG=true` publicly; it exposes stack traces and environment variables.
- **PHP 8.0 minimum** — PHP 7.x is not supported in October CMS v3.x.
- **SQLite** — Supported but only suitable for development or very low-traffic sites. Use MySQL/PostgreSQL for production.

## Links

- GitHub: https://github.com/octobercms/october
- Website: https://octobercms.com
- Docs: https://docs.octobercms.com/
- Install guide: https://docs.octobercms.com/3.x/setup/installation.html
- RainLab plugins: https://github.com/rainlab
- Plugin marketplace: https://octobercms.com/plugins
- Changelog: https://octobercms.com/changelog
