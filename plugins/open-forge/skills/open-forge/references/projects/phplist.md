---
name: phplist
description: Recipe for phpList — an open-source email marketing and newsletter platform with subscriber management, bounce processing, analytics, and plugin architecture. PHP + MySQL/MariaDB + Docker.
---

# phpList

Open-source email marketing and newsletter manager. Handles subscriber management, campaign scheduling, bounce processing, real-time analytics, segmentation, and content personalisation. Available as a self-hosted PHP application or via the hosted phplist.com service. Upstream: <https://github.com/phpList/phplist3>. Website: <https://www.phplist.org/>.

License: AGPL-3.0. Platform: PHP, MySQL/MariaDB, Docker. Latest stable: v3.7.0-RC2. Docker image: `phplist/phplist:latest`.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended — official Docker image on Docker Hub |
| PHP/Apache native | For existing LAMP stacks |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "MySQL/MariaDB host, database name, user, password?" | phpList requires MySQL/MariaDB |
| mail | "Mail transfer method: PHP `mail()`, SMTP, or Amazon SES?" | SMTP recommended; SES has built-in optimised support |
| mail | "SMTP host, port, user, password?" | If using SMTP |
| network | "Public URL for phpList?" | Used for unsubscribe links and web interface |
| admin | "Admin email and password?" | Set during first-run install |

## Docker (recommended)

```bash
mkdir phplist && cd phplist
```

`docker-compose.yml`:
```yaml
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: phplist
      MYSQL_USER: phplist
      MYSQL_PASSWORD: strongpassword
    volumes:
      - phplist_db:/var/lib/mysql

  phplist:
    image: phplist/phplist:latest
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      PHPLIST_DB_HOST: db
      PHPLIST_DB_NAME: phplist
      PHPLIST_DB_USER: phplist
      PHPLIST_DB_PASS: strongpassword
      PHPLIST_SECURITY_SALT: "changeme-random-string-32chars"
      # SMTP config (recommended over PHP mail())
      # PHPLIST_SMTP_HOST: smtp.example.com
      # PHPLIST_SMTP_PORT: 587
      # PHPLIST_SMTP_USER: you@example.com
      # PHPLIST_SMTP_PASSWORD: smtppassword
    volumes:
      - phplist_data:/var/www/phplist/lists/admin/data
      - phplist_plugins:/var/www/phplist/lists/admin/plugins

volumes:
  phplist_db:
  phplist_data:
  phplist_plugins:
```

```bash
docker compose up -d
```

Complete the installation wizard at `http://your-host:8080/lists/admin/`.

## Native PHP install

```bash
# Prerequisites: PHP 8.1+, MySQL/MariaDB, Apache/nginx

# Download phpList
curl -fsSL https://github.com/phpList/phplist3/archive/refs/tags/v3.6.16.tar.gz | tar xz
mv phplist3-3.6.16 /var/www/html/phplist

# Set permissions
chown -R www-data:www-data /var/www/html/phplist

# Configure database in config/config.php
cp /var/www/html/phplist/lists/config/config.php.dist /var/www/html/phplist/lists/config/config.php
```

Edit `config/config.php`:
```php
$database_host = 'localhost';
$database_name = 'phplist';
$database_user = 'phplist';
$database_password = 'strongpassword';

// Mail settings
define('PHPMAILERHOST', 'smtp.example.com');
define('PHPMAILERPORT', 587);
```

Then visit `/lists/admin/?page=upgrade` to run database migrations.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | `lists/config/config.php` (native) or environment variables (Docker) |
| Data dir | `lists/admin/data/` — campaign data, exports |
| Plugins dir | `lists/admin/plugins/` — extend with plugins |
| Default port | `80` (internal); map to host port |
| Admin URL | `/lists/admin/` |
| CLI campaigns | `php -f lists/admin/index.php -- -c processqueue` |
| Queue processing | Run via cron for scheduled sends: `*/5 * * * * php /path/to/lists/admin/index.php -c processqueue` |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# Visit /lists/admin/?page=upgrade to apply DB migrations
```

## Gotchas

- **Install wizard on first run**: Browse to `/lists/admin/` and complete the setup wizard before the application is usable. The wizard creates database tables and the first admin account.
- **Queue processing requires cron**: phpList does not send campaigns automatically. You must configure a cron job to call `processqueue` regularly, or campaigns will sit in the queue unsent.
- **Security salt is required**: Set `PHPLIST_SECURITY_SALT` (Docker) or `$secret` in `config.php` to a long random string. Without it, subscriber tokens are predictable.
- **Port 25 from Docker**: Many cloud providers block outbound port 25 from containers. Use port 587 (STARTTLS) or 465 (TLS) for SMTP, not port 25.
- **v3.7.0-RC2 is current stable**: Despite the RC suffix, this is the currently recommended version. The project uses RC tagging for final releases.
- **Bounce processing**: For automatic bounce handling, configure a bounce email address and set up the bounce processing cron job. Without this, undeliverable email is not automatically processed.

## Upstream links

- Source: <https://github.com/phpList/phplist3>
- Docker Hub: <https://hub.docker.com/r/phplist/phplist>
- Docs: <https://resources.phplist.com/system/start>
- Demo: <https://demo.phplist.org>
