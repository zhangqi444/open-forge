---
name: easy-appointments-project
description: Easy!Appointments recipe for open-forge. Open-source appointment scheduling web app in PHP + MySQL. Covers manual LAMP install. Based on upstream README at https://github.com/alextselegidis/easyappointments and docs at https://easyappointments.org.
---

# Easy!Appointments

Open-source appointment scheduling application that lets customers book appointments online. PHP-based, MySQL backend, Google Calendar sync, email notifications, translatable UI. GPL-3.0. Upstream: https://github.com/alextselegidis/easyappointments. Site: https://easyappointments.org. Current release: 1.5.2.

## Compatible install methods

| Method | When to use |
|---|---|
| Manual LAMP/LEMP | Standard; download release zip and configure |
| Docker (dev build) | Development only — the official docker-compose.yml builds from source |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "LAMP or Docker?" | LAMP / Docker | Docker compose in repo is for development use |
| database | "MySQL host / name / user / password?" | Four values | Set in config.php |
| config | "App URL?" | URL (e.g. https://appointments.example.com) | BASE_URL in config.php |
| config | "Admin email?" | email | Set during web setup wizard |
| config | "Admin password?" | Free-text (sensitive) | Set during web setup wizard |
| smtp | "SMTP host, port, user, password?" | Separate values | For booking confirmation and notification emails |
| google | "Google Calendar sync?" | Yes / No | Requires Google Calendar API credentials if yes |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP 8.x (recommended) |
| Database | MySQL 8.x or MariaDB 10.x |
| Web server | Apache (mod_rewrite) or nginx |
| Config file | config.php — copy from config-sample.php and edit |
| Writable dir | storage/ — must be writable by web server |
| Setup wizard | Available on first visit to the app URL |
| Google Calendar | Optional; requires OAuth2 client ID and secret from Google Cloud Console |
| REST API | Built-in; documented via OpenAPI (openapi.yml in repo) |

## Install: Manual LAMP

Source: https://github.com/alextselegidis/easyappointments/blob/master/README.md#installation

### 1. Download the latest release

```bash
# Download from GitHub releases
wget https://github.com/alextselegidis/easyappointments/releases/download/1.5.2/easyappointments-1.5.2.zip
unzip easyappointments-1.5.2.zip -d /var/www/html/
mv /var/www/html/easyappointments-1.5.2 /var/www/html/appointments
```

Or use the direct download from https://easyappointments.org.

### 2. Set permissions

```bash
chown -R www-data:www-data /var/www/html/appointments
chmod -R 755 /var/www/html/appointments
chmod -R 775 /var/www/html/appointments/storage
```

### 3. Configure

```bash
cd /var/www/html/appointments
cp config-sample.php config.php
```

Edit config.php — set at minimum:
```php
define('BASE_URL', 'https://appointments.example.com');
define('DB_HOST', 'localhost');
define('DB_NAME', 'easyappointments');
define('DB_USERNAME', 'eauser');
define('DB_PASSWORD', 'yourpassword');
define('GOOGLE_SYNC_FEATURE', FALSE); // set TRUE to enable Google Calendar
```

### 4. Create MySQL database

```sql
CREATE DATABASE easyappointments CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'eauser'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON easyappointments.* TO 'eauser'@'localhost';
FLUSH PRIVILEGES;
```

### 5. Apache virtual host

```apache
<VirtualHost *:80>
    ServerName appointments.example.com
    DocumentRoot /var/www/html/appointments
    <Directory /var/www/html/appointments>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Enable mod_rewrite: `sudo a2enmod rewrite && sudo systemctl restart apache2`

### 6. Complete setup wizard

Visit https://appointments.example.com in a browser. The setup wizard will guide you through creating the admin account and verifying the database connection.

## Upgrade procedure

1. Back up the database: `mysqldump -u eauser -p easyappointments > backup_$(date +%Y%m%d).sql`
2. Back up storage/ directory
3. Download the new release from https://github.com/alextselegidis/easyappointments/releases
4. Extract and overwrite all files except config.php and storage/
5. Visit the app — the upgrade will run automatically if needed

## Gotchas

- mod_rewrite required: Apache must have mod_rewrite enabled and AllowOverride All set. Without it, all routes except the root return 404.
- storage/ must be writable: File uploads and cache writes go here. Incorrect permissions cause silent failures.
- config.php is not overwritten on upgrade: Safe to deploy new version without losing configuration.
- Google Calendar sync needs API credentials: Go to Google Cloud Console, create an OAuth2 client, and enter the credentials in config.php. Users must authorise the connection individually.
- Docker compose in repo is for development: It builds from source and uses dev tooling. Not suitable for production use.
- BASE_URL must match your actual URL: Mismatched BASE_URL causes redirect loops and broken asset loading.

## Links

- GitHub: https://github.com/alextselegidis/easyappointments
- Releases: https://github.com/alextselegidis/easyappointments/releases
- Official site: https://easyappointments.org
- Discord: https://discord.com/invite/UeeSkaw
- OpenAPI docs: https://github.com/alextselegidis/easyappointments/blob/master/openapi.yml
