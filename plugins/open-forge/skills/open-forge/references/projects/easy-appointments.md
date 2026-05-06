---
name: easy-appointments
description: Easy!Appointments recipe for open-forge. Open-source web appointment scheduling app. Self-hosted via Docker Compose or LAMP/LEMP. Source: https://github.com/alextselegidis/easyappointments. Docs: https://easyappointments.org/docs.html.
---

# Easy!Appointments

Open-source web application for managing customer appointments. Customers self-book via an embeddable booking page; staff manage services, providers, and working hours in an admin panel. Supports Google Calendar sync. Written in PHP (CodeIgniter), backed by MySQL. Upstream: <https://github.com/alextselegidis/easyappointments>. Docs: <https://easyappointments.org/docs.html>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + MySQL | Upstream provides docker-compose.yml for dev; adapt for production |
| VPS / bare metal | Apache/NGINX + PHP 8.1+ + MySQL | Traditional LAMP/LEMP |
| Shared hosting | PHP + MySQL | Runs on most shared hosts with PHP 8.1+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker or LAMP?" | Drives install path |
| db | "MySQL database name, user, password?" | Dedicated DB user |
| admin | "Admin display name, email, password?" | First admin account |
| google | "Enable Google Calendar sync?" | Requires Google OAuth API credentials (optional) |
| domain | "Public domain?" | Used for the booking page URL and HTTPS |

## Software-layer concerns

- Config: config.php (or .env for Docker builds) sets DB credentials, app URL, debug mode
- Default port: 80
- Data dirs: storage/ (logs, cache); uploads/ if file attachments are used
- PHP requirements: PHP 8.1+; extensions: curl, gd, intl, mbstring, mysql, openssl, xml, zip
- Google Calendar sync: optional; requires creating a Google Cloud OAuth 2.0 credential and configuring client ID/secret in admin settings
- Embedding: booking page can be embedded in an external website via `<iframe>` or via the provided JS widget

### Docker Compose (production-ready)

```yaml
services:
  php-fpm:
    image: easyappointments/easyappointments:latest
    working_dir: /var/www/html
    volumes:
      - ea-storage:/var/www/html/storage
    environment:
      DB_HOST: mysql
      DB_NAME: easyappointments
      DB_USERNAME: easyappointments
      DB_PASSWORD: <db-password>
      APP_URL: https://your-domain.com
      DEBUG_MODE: false
    depends_on:
      - mysql
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - php-fpm
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: easyappointments
      MYSQL_USER: easyappointments
      MYSQL_PASSWORD: <db-password>
      MYSQL_ROOT_PASSWORD: <root-password>
    volumes:
      - mysql-data:/var/lib/mysql
    restart: unless-stopped

volumes:
  ea-storage:
  mysql-data:
```

> The upstream repo's docker-compose.yml is development-oriented (includes phpMyAdmin + Mailpit). Use a minimal production compose like above or follow the LAMP install for production.

### LAMP quick-install

```bash
# Download release zip
curl -L https://github.com/alextselegidis/easyappointments/releases/latest/download/easyappointments.zip -o ea.zip
unzip ea.zip -d /var/www/html/appointments

# Copy and edit config
cp /var/www/html/appointments/config-sample.php /var/www/html/appointments/config.php
# Edit config.php: set DB credentials, BASE_URL, DEBUG_MODE = FALSE

# Set permissions
chown -R www-data:www-data /var/www/html/appointments
```

Browse to your URL to complete setup. Admin login uses the credentials set in config.php.

## Upgrade procedure

1. Backup database and storage/
2. Download new release, replace application files (preserve config.php)
3. Browse to the app URL — Easy!Appointments will detect and run DB migrations automatically
4. Docker: pull new image, `docker compose up -d`
5. Check release notes: https://github.com/alextselegidis/easyappointments/releases

## Gotchas

- **BASE_URL must match your domain**: If BASE_URL in config.php doesn't match the browser URL, assets fail to load and redirects break.
- **Google Calendar sync**: Requires a Google Cloud project with the Calendar API enabled and an OAuth 2.0 Web Application credential. Callback URL must match your deployment URL.
- **Email notifications**: Configure SMTP in Admin > Settings > Email; required for appointment confirmation and reminder emails.
- **Timezone**: Set the default timezone in Admin > Settings > Business Logic to match your location; affects booking availability display.
- **Embedding**: The `<iframe>` embed URL is `https://your-domain/index.php/appointments`; width/height are customisable.
- **DEBUG_MODE**: Disable in production (DEBUG_MODE = FALSE) to prevent leaking stack traces to users.

## Links

- Upstream repo: https://github.com/alextselegidis/easyappointments
- Docs: https://easyappointments.org/docs.html
- Docker Hub: https://hub.docker.com/r/easyappointments/easyappointments
- Release notes: https://github.com/alextselegidis/easyappointments/releases
- Discord: https://discord.com/invite/UeeSkaw
