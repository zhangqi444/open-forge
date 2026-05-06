---
name: known
description: Known (Idno) recipe for open-forge. Collaborative social publishing platform with IndieWeb support, ActivityPub, Webmentions, and RSS. PHP 8.3+ app backed by MySQL/MongoDB. Source: https://github.com/idno/idno
---

# Known (Idno)

Collaborative social publishing platform with a strong IndieWeb focus. Supports writing posts, notes, photos, bookmarks, likes, and RSVPs — all published to your own domain. Integrates with ActivityPub (federated social), Webmentions, and RSS. Built on PHP 8.3+ with MySQL or MongoDB as the database backend. Official name: Known (project repo: idno). Upstream: https://github.com/idno/idno. Docs: http://docs.idno.co/en/latest/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Composer (create-project) | Linux / macOS | Recommended |
| Git clone + composer install | Linux / macOS | For dev/bleeding-edge |
| Shared hosting | cPanel / Plesk | PHP + MySQL host required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "Database type?" | MySQL (recommended) or MongoDB |
| db | "Database host / name / user / password?" | Standard MySQL credentials |
| web | "Domain / base URL?" | e.g. https://blog.example.com |
| admin | "Admin email and password?" | Created via web installer |
| async | "Enable async queue?" | Recommended for ActivityPub; requires a background worker |

## Software-layer concerns

### Prerequisites

  # PHP 8.3+ with extensions:
  #   pdo_mysql (or mongodb), curl, gd, json, mbstring, xml, zip
  # Composer
  # MySQL 8+ (or MongoDB)
  # Web server: Apache (mod_rewrite) or nginx

### Install via Composer

  composer create-project idno/idno /var/www/known
  # Or bleeding-edge:
  # composer create-project idno/idno /var/www/known -s dev

  cd /var/www/known
  cp config.ini-dist config.ini
  # Edit config.ini with database credentials and base URL

### config.ini key settings

  database        = MySQL           # or MongoDB
  dbhost          = 127.0.0.1
  dbname          = known
  dbuser          = known
  dbpassword      = secret
  url             = https://blog.example.com
  # For async queue (recommended for ActivityPub):
  event_queue     = AsynchronousQueue

### MySQL setup

  CREATE DATABASE known CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
  CREATE USER 'known'@'localhost' IDENTIFIED BY 'secret';
  GRANT ALL PRIVILEGES ON known.* TO 'known'@'localhost';
  FLUSH PRIVILEGES;

### Web server — nginx example

  server {
      listen 80;
      server_name blog.example.com;
      root /var/www/known;
      index index.php;

      location / {
          try_files $uri $uri/ /index.php?$query_string;
      }

      location ~ \.php$ {
          fastcgi_pass unix:/run/php/php8.3-fpm.sock;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_name;
          include fastcgi_params;
      }
  }

### Apache (mod_rewrite must be enabled)

  # .htaccess is included in the repo — ensure AllowOverride All is set.
  # a2enmod rewrite && systemctl reload apache2

### Async event queue worker (required for ActivityPub)

  # Add to config.ini:
  event_queue = AsynchronousQueue

  # Run the worker (e.g. via systemd or screen):
  sudo -u www-data IDNO_DOMAIN='blog.example.com' ./idno.php service-event-queue

  # Systemd unit example:
  # [Service]
  # User=www-data
  # Environment=IDNO_DOMAIN=blog.example.com
  # ExecStart=/usr/bin/php /var/www/known/idno.php service-event-queue
  # Restart=always

### File permissions

  chmod -R 775 /var/www/known/Uploads
  chown -R www-data:www-data /var/www/known

### Ports

  80/tcp  443/tcp   # Web UI via nginx/Apache

## Upgrade procedure

  cd /var/www/known
  git pull            # if using git clone
  # or: composer update
  # Run any database migrations via web UI (/admin)
  # Clear any opcode cache: systemctl restart php8.3-fpm

## Gotchas

- **PHP 8.3+ required**: Known dropped support for older PHP versions. Check `php --version`.
- **ActivityPub needs async queue**: Without the event queue worker running, federation (follows, posts to remote servers) silently stalls. The worker must stay running.
- **mod_rewrite / try_files**: All routing goes through `index.php`. If clean URLs return 404, the rewrite rule isn't active.
- **Uploads directory**: Must be writable by the web server user (`www-data`). Uploaded images and media go here.
- **MongoDB alternative**: MongoDB support exists but MySQL is more commonly tested. Stick to MySQL unless you have a reason.
- **No Docker image maintained**: No official Docker image; use the Composer install on a LEMP/LAMP stack.
- **Unofficial packages**: Unofficial pre-built packages exist at https://www.marcus-povey.co.uk/known/ if Composer isn't available.

## References

- Upstream GitHub: https://github.com/idno/idno
- Documentation: http://docs.idno.co/en/latest/
- Website: https://withknown.com/
- IndieWeb wiki: https://indieweb.org/Known
