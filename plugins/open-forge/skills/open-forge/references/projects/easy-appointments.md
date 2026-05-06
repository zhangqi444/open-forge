---
name: easy-appointments
description: Easy!Appointments recipe for open-forge. Covers PHP web server install (nginx or Apache) with MySQL/MariaDB. Easy!Appointments is a web-based appointment scheduling app that lets customers book appointments online with optional Google Calendar sync.
---

# Easy!Appointments

Open-source web application that allows customers to book appointments via a web interface. Supports multiple services and providers, working schedules, booking rules, Google Calendar synchronization, and email notifications. Runs on any PHP-capable server with MySQL/MariaDB. Upstream: <https://github.com/alextselegidis/easyappointments>. Website: <https://easyappointments.org>. Demo: <https://demo.easyappointments.org>.

**License:** GPL-3.0 · **Language:** PHP (CodeIgniter 4) · **Default port:** 80/443 · **Stars:** ~4,200

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| PHP on nginx | <https://github.com/alextselegidis/easyappointments#installation> | ✅ | Recommended — nginx + PHP-FPM on Linux. |
| PHP on Apache | <https://github.com/alextselegidis/easyappointments#installation> | ✅ | Apache + mod_php or PHP-FPM; .htaccess required. |
| Shared hosting | <https://github.com/alextselegidis/easyappointments/releases> | ✅ | Upload release zip to any PHP host via FTP/SFTP. |

> **Note:** No official Docker image. Community images exist but may lag behind releases.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which web server — nginx or Apache?" | AskUserQuestion | Determines server config below. |
| domain | "What domain will Easy!Appointments be served on?" | Free-text | All methods. |
| database | "MySQL/MariaDB host, database name, username, and password?" | Free-text (sensitive) | All methods. |
| php | "PHP version available? (8.2+ required)" | Free-text | Verify before install. |
| google_cal | "Enable Google Calendar synchronization?" | AskUserQuestion: Yes / No | Optional feature. |
| google_cal_creds | "Google API key and client credentials?" | Free-text (sensitive) | If Google Calendar enabled. |

## Install

Reference: <https://github.com/alextselegidis/easyappointments#installation>

### 1. Create database

```sql
CREATE DATABASE easyappointments CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'easyappts'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON easyappointments.* TO 'easyappts'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Download and extract

```bash
# Download latest stable release from:
# https://github.com/alextselegidis/easyappointments/releases
wget https://github.com/alextselegidis/easyappointments/releases/latest/download/easy-appointments.zip
unzip easy-appointments.zip -d /var/www/easyappointments
cd /var/www/easyappointments
```

### 3. Configure

```bash
cp config-sample.php config.php
nano config.php
```

Minimal `config.php`:

```php
<?php
define('BASE_URL', 'https://appointments.example.com/');
define('STORAGE_PATH', __DIR__ . '/storage');
define('DEBUG_MODE', FALSE);
```

Database configuration is set through the web-based installation wizard that runs on first visit.

### 4. Set permissions

```bash
chown -R www-data:www-data /var/www/easyappointments
chmod -R 755 /var/www/easyappointments
chmod -R 775 /var/www/easyappointments/storage
```

### 5. Configure nginx

```nginx
server {
    listen 443 ssl;
    server_name appointments.example.com;

    root /var/www/easyappointments;
    index index.php;

    # Block direct access to storage
    location ^~ /storage {
        deny all;
    }

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    }
}
```

### 6. Run installation wizard

Open the domain in a browser. The installation wizard will guide you through:
1. Database connection setup (host, name, user, password)
2. Admin account creation
3. Initial configuration

## Software-layer concerns

| Concern | Detail |
|---|---|
| PHP version | Requires PHP 8.2+. Extensions: pdo, pdo_mysql, curl, json, xml, mbstring, gd, intl. |
| Database | MySQL 5.7+ or MariaDB 10.3+. Schema created automatically by the installation wizard. |
| config.php | Contains BASE_URL and storage path. Must survive upgrades. |
| storage/ directory | Contains application logs, caches, and uploads. Must be writable by www-data. |
| .htaccess | Required for Apache URL rewriting. Included in the release archive. |
| Email notifications | Configured via Settings → Email in admin panel. Supports SMTP. |
| Google Calendar sync | Optional. Configure via Settings → Integration. Requires Google Cloud project with Calendar API enabled. |
| Auth | Single admin account + provider accounts. No multi-user admin support. |
| Booking page | Public booking page at the root URL — no auth required for customers. |

## Upgrade procedure

Reference: <https://github.com/alextselegidis/easyappointments/wiki>

```bash
# 1. Backup database
mysqldump -u easyappts -p easyappointments > easyappointments-backup-$(date +%Y%m%d).sql

# 2. Backup config.php and storage/
cp /var/www/easyappointments/config.php ~/config.php.bak
tar czf ~/easyappointments-storage-bak.tar.gz /var/www/easyappointments/storage

# 3. Download new release
wget https://github.com/alextselegidis/easyappointments/releases/latest/download/easy-appointments.zip
unzip easy-appointments.zip -d /tmp/easyappointments-new

# 4. Deploy new files (preserve config.php and storage/)
rsync -av --exclude='config.php' --exclude='storage/' /tmp/easyappointments-new/ /var/www/easyappointments/

# 5. Fix permissions
chown -R www-data:www-data /var/www/easyappointments

# 6. Run database migrations
# Navigate to your Easy!Appointments URL — migrations run automatically on first load after upgrade
```

## Gotchas

- **BASE_URL must match your domain exactly** (including trailing slash): If it's wrong, redirects and assets break. Update config.php whenever you change the domain.
- **storage/ must be writable:** If PHP can't write to `storage/`, the app throws 500 errors. Run `chmod -R 775 storage && chown -R www-data:www-data storage`.
- **Apache .htaccess required:** Without .htaccess (or equivalent Apache config with `AllowOverride All`), URL routing breaks and all paths return 404.
- **Google Calendar sync requires OAuth setup:** You need a Google Cloud project with Calendar API enabled and an OAuth2 client credential. See upstream docs for the step-by-step.
- **No official Docker image:** No upstream-maintained Docker image exists. For containerized deployment you'll need to build your own or use a community image.
- **PHP 8.2+ required:** PHP 7.x is not supported as of current releases. Verify `php -v` before installing.

## Upstream links

- GitHub: <https://github.com/alextselegidis/easyappointments>
- Website: <https://easyappointments.org>
- Releases: <https://github.com/alextselegidis/easyappointments/releases>
- Demo: <https://demo.easyappointments.org>
- Google Calendar integration docs: <https://github.com/alextselegidis/easyappointments/wiki>
