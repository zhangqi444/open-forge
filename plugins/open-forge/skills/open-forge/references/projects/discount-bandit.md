---
name: discount-bandit
description: Discount Bandit recipe for open-forge. Self-hosted price tracker for products across Amazon, eBay, Walmart, and other stores, with notifications when prices drop to your target. Source: https://github.com/Cybrarist/Discount-Bandit
---

# Discount Bandit

Self-hosted price tracker for products across multiple online stores including Amazon, eBay, Walmart, and more. Set target prices and receive notifications (email, Slack, Discord, etc.) when prices drop to your criteria. Built with PHP/Laravel + SQLite or MySQL. Upstream: https://github.com/Cybrarist/Discount-Bandit. Docs: https://discount-bandit.cybrarist.com.

Note: Relies on scraping third-party store pages (marked `depends_3rdparty: true` in awesome-selfhosted). Store website changes may break tracking until the project updates scrapers.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker | Docker | Recommended. Official image on Docker Hub. |
| Manual (PHP/Composer) | PHP + Apache/nginx + SQLite/MySQL | Traditional LAMP/LEMP install. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Database type?" | SQLite (default, simpler) or MySQL |
| notifications | "Notification channels?" | Email (SMTP), Slack, Discord, Telegram, Pushover — configure in .env |
| setup | "App URL?" | e.g. http://discountbandit.example.com — set as APP_URL in .env |

## Software-layer concerns

### Docker install (recommended)

  # Pull the image
  docker pull cybrarist/discount-bandit

  # Run with SQLite (simplest):
  docker run -d \
    --name discount-bandit \
    -p 8080:80 \
    -v discount-bandit-data:/var/www/html/storage \
    -e APP_URL=http://localhost:8080 \
    cybrarist/discount-bandit

  # Access at http://localhost:8080

### Docker Compose with MySQL

  services:
    app:
      image: cybrarist/discount-bandit
      ports:
        - "8080:80"
      environment:
        - APP_URL=http://localhost:8080
        - DB_CONNECTION=mysql
        - DB_HOST=db
        - DB_DATABASE=discountbandit
        - DB_USERNAME=discountbandit
        - DB_PASSWORD=changeme
      volumes:
        - ./storage:/var/www/html/storage
      depends_on:
        - db
    db:
      image: mariadb:10.11
      environment:
        - MYSQL_DATABASE=discountbandit
        - MYSQL_USER=discountbandit
        - MYSQL_PASSWORD=changeme
        - MYSQL_ROOT_PASSWORD=rootchangeme
      volumes:
        - db-data:/var/lib/mysql
  volumes:
    db-data:

### Manual install (PHP)

  # Requirements: PHP 8.1+, Composer, Apache or nginx, SQLite or MySQL
  git clone https://github.com/Cybrarist/Discount-Bandit.git
  cd Discount-Bandit
  composer install
  cp .env.example .env
  php artisan key:generate
  # Edit .env: set APP_URL, DB_CONNECTION, MAIL_* for notifications
  php artisan migrate
  php artisan db:seed   # optional: seeds sample data

### Notification configuration (.env)

  # Email:
  MAIL_MAILER=smtp
  MAIL_HOST=smtp.example.com
  MAIL_PORT=587
  MAIL_USERNAME=user@example.com
  MAIL_PASSWORD=yourpassword
  MAIL_FROM_ADDRESS=alerts@example.com

  # Discord webhook:
  DISCORD_WEBHOOK=https://discord.com/api/webhooks/...

### Usage

1. Open the web UI
2. Paste a product URL (Amazon, eBay, Walmart, etc.)
3. Set your target price
4. The tracker checks the price periodically and notifies you when it drops

## Upgrade procedure

  # Docker:
  docker pull cybrarist/discount-bandit
  docker stop discount-bandit && docker rm discount-bandit
  # Re-run docker run with same volume mounts

  # Manual:
  git pull
  composer install
  php artisan migrate

## Gotchas

- **Third-party dependency**: scrapes store pages directly. Amazon, eBay, etc. frequently change their HTML — trackers may break until upstream updates scrapers. Check issue tracker for known broken stores.
- **Rate limiting/blocking**: excessive polling may get your server's IP blocked by stores. The app uses reasonable intervals, but use a residential IP or proxy if needed for high-volume tracking.
- **Storage volume**: always mount /var/www/html/storage as a volume — it contains the SQLite DB, logs, and cached data.
- **Laravel app key**: APP_KEY must be generated (php artisan key:generate) and kept stable — changing it invalidates encrypted data.
- **Scheduler**: for automatic price checks, the Laravel scheduler needs a cron job or the Docker image handles it internally. Verify price checks are running in the logs.

## References

- Upstream GitHub: https://github.com/Cybrarist/Discount-Bandit
- Documentation: https://discount-bandit.cybrarist.com
- Docker Hub: https://hub.docker.com/r/cybrarist/discount-bandit
- Discord community: https://discord.gg/VBMHvH8tuR
