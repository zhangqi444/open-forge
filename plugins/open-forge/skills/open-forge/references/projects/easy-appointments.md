---
name: easy-appointments
description: Easy!Appointments recipe for open-forge. Covers self-hosting the open-source web appointment scheduling application. Upstream: https://github.com/alextselegidis/easyappointments
---

# Easy!Appointments

Highly customizable open-source appointment scheduling web app. Customers book appointments via a polished web interface; admins manage services, providers, working plans, and booking rules. Includes Google Calendar sync, email notifications, and a REST API. Upstream: <https://github.com/alextselegidis/easyappointments>. Site: <https://easyappointments.org>.

**License:** GPL-3.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (nginx + php-fpm + MySQL) | https://github.com/alextselegidis/easyappointments/blob/develop/docker-compose.yml | ✅ | Recommended for containerised deployments |
| Traditional PHP web server (LAMP/LEMP) | https://easyappointments.org/docs.html#1.4.0/installation | ✅ | Existing PHP stack; shared hosting or VPS |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| database | "DB name/user/password?" | Free-text | All |
| app | "Public URL?" | e.g. https://book.example.com | All |
| app | "App timezone?" | TZ string | All |
| google | "Google Calendar sync needed?" | Yes/No | Optional — requires Google OAuth credentials |
| email | "SMTP settings?" | host/port/user/pass | Optional; for email notifications |

## Docker Compose

```yaml
services:
  php-fpm:
    build: docker/php-fpm
    working_dir: /var/www/html
    volumes:
      - '.:/var/www/html'
      - './docker/php-fpm/php-ini-overrides.ini:/usr/local/etc/php/conf.d/99-overrides.ini'

  nginx:
    image: nginx:1.23.3-alpine
    working_dir: /var/www/html
    volumes:
      - '.:/var/www/html'
      - './docker/nginx/nginx.conf:/etc/nginx/conf.d/default.conf'
    ports:
      - '80:80'

  mysql:
    image: mysql:8.0
    volumes:
      - './docker/mysql:/var/lib/mysql'
    environment:
      - MYSQL_ROOT_PASSWORD=secret
      - MYSQL_DATABASE=easyappointments
      - MYSQL_USER=user
      - MYSQL_PASSWORD=password
    ports:
      - '3306:3306'
```

```bash
git clone https://github.com/alextselegidis/easyappointments.git
cd easyappointments
npm install && composer install
docker compose up -d
```

## Traditional PHP install

```bash
# Download from https://github.com/alextselegidis/easyappointments/releases
unzip easyappointments-<version>.zip -d /var/www/html/appointments

# Copy and edit config
cp /var/www/html/appointments/config-sample.php /var/www/html/appointments/config.php
# Edit config.php: DB credentials, base URL, timezone, Google OAuth, SMTP

# Set permissions
chown -R www-data:www-data /var/www/html/appointments
```

Then visit the configured URL — the installer runs on first access and creates the database schema.

## Software-layer concerns

### PHP requirements

- PHP 7.4+ (8.x recommended); extensions: mysqli, gd, curl, xml, mbstring

### Key config settings (config.php)

```php
define('DB_HOST', 'localhost');
define('DB_NAME', 'easyappointments');
define('DB_USERNAME', 'user');
define('DB_PASSWORD', 'password');
define('BASE_URL', 'https://book.example.com');
define('GOOGLE_SYNC_FEATURE', false); // set to true + add OAuth credentials for Google Calendar
```

### Writable directories

| Directory | Purpose |
|---|---|
| `storage/` | Cached data, logs; must be writable |

## Upgrade procedure

```bash
# Official: https://easyappointments.org/docs.html#1.4.0/upgrade
# 1. Back up database and files
# 2. Download new release, extract (preserve config.php)
# 3. Visit <base-url>/index.php/upgrade in browser to run DB migrations
```

## Gotchas

- **config.php is preserved across upgrades.** Do not overwrite it when updating files.
- **Google Calendar sync is optional.** Requires Google OAuth 2.0 credentials; disable (`GOOGLE_SYNC_FEATURE=false`) if not needed.
- **No HTTPS built-in.** Deploy behind nginx/Caddy with TLS; required for production and Google OAuth.
- **First visit runs installer.** On a fresh install, the first browser visit sets up the database schema. Protect the URL until setup is complete.
- **Docker Compose is dev-focused upstream.** The upstream compose includes phpMyAdmin and Mailpit (dev mail catcher). Strip these for production.

## Upstream docs

- Documentation: https://easyappointments.org/docs.html
- GitHub README: https://github.com/alextselegidis/easyappointments
- Releases: https://github.com/alextselegidis/easyappointments/releases
