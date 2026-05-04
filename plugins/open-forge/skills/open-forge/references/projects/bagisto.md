---
name: bagisto
description: Bagisto recipe for open-forge. Covers Docker Compose and traditional PHP/Laravel install. Open-source Laravel eCommerce framework with multi-inventory, multi-currency, multi-locale, and headless API support. Sourced from https://github.com/bagisto/bagisto and https://devdocs.bagisto.com/.
---

# Bagisto

Open-source [Laravel](https://laravel.com/) eCommerce framework built on Laravel (PHP) and Vue.js. Supports multi-currency, multi-locale (24+ languages), multi-channel storefronts, B2B workflows, multi-vendor marketplace, multi-tenant SaaS, POS, and headless commerce via REST/GraphQL APIs. Upstream: https://github.com/bagisto/bagisto. Docs: https://devdocs.bagisto.com/. MIT.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose | https://devdocs.bagisto.com/2.3/introduction/docker.html | Quick dev and testing |
| Composer (traditional) | https://devdocs.bagisto.com/2.3/introduction/installation.html | Shared hosting, full PHP stack |
| AWS AMI | https://aws.amazon.com/marketplace/pp/prodview-r3xv62axcqkpa | Cloud one-click |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker or traditional PHP install?" | Drives path |
| database | "MySQL/MariaDB credentials?" | Required |
| domain | "Storefront domain?" | Virtual host / APP_URL |
| admin | "Admin email and password?" | Created during install |
| currency | "Default currency?" | USD, EUR, etc. |

## Docker Compose

```yaml
version: "3.8"
services:
  bagisto:
    image: bagisto/bagisto:latest
    ports:
      - "80:80"
    environment:
      APP_NAME: "Bagisto"
      APP_URL: "http://localhost"
      DB_CONNECTION: mysql
      DB_HOST: db
      DB_PORT: 3306
      DB_DATABASE: bagisto
      DB_USERNAME: bagisto
      DB_PASSWORD: secret
      APP_TIMEZONE: UTC
      APP_LOCALE: en
      APP_CURRENCY: USD
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - bagisto-storage:/var/www/html/storage
      - bagisto-public:/var/www/html/public

  db:
    image: mariadb:10.6
    environment:
      MYSQL_DATABASE: bagisto
      MYSQL_USER: bagisto
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  bagisto-storage:
  bagisto-public:
  db-data:
```

After first start, run the installer:
```sh
docker exec -it <bagisto_container> php artisan bagisto:install
```

## Traditional Composer install (Ubuntu/Debian)

```sh
# Prerequisites: PHP 8.2+, Composer, MySQL/MariaDB, Node.js 18+
sudo apt-get install -y php8.2 php8.2-{bcmath,ctype,curl,dom,fileinfo,gd,intl,json,mbstring,openssl,pdo,mysql,tokenizer,xml,zip} \
    composer mysql-server nodejs npm

# Clone and install
composer create-project bagisto/bagisto bagisto
cd bagisto
cp .env.example .env
# Edit .env: set APP_URL, DB_* credentials
php artisan bagisto:install
npm install && npm run build
```

## Key environment variables (.env)

| Variable | Default | Purpose |
|---|---|---|
| APP_URL | http://localhost | Public storefront URL |
| APP_LOCALE | en | Default language |
| APP_CURRENCY | USD | Default currency |
| DB_CONNECTION | mysql | Database driver |
| QUEUE_CONNECTION | sync | Use `database` or `redis` for async jobs |
| MAIL_MAILER | smtp | Outgoing mail driver |

## Key ports

| Port | Purpose |
|---|---|
| 80/443 | Web storefront and admin panel |

Admin panel is at `/admin`. Default credentials set during installation.

## Upgrade procedure

```sh
# Traditional install
git pull
composer install --no-dev
php artisan migrate
php artisan bagisto:publish --force
npm install && npm run build
php artisan cache:clear && php artisan config:cache
```

For Docker: pull latest image, recreate container, then run `php artisan migrate`.

Always back up database before upgrading. Check [upgrade docs](https://devdocs.bagisto.com/).

## Gotchas

- **PHP 8.2+ required** — Bagisto 2.x requires PHP 8.2; PHP 8.1 is not supported.
- **Queue worker for async** — Set `QUEUE_CONNECTION=database` and run `php artisan queue:work` (or use Supervisor) for order processing, emails, and notifications; `sync` mode blocks requests.
- **Storage symlink** — Run `php artisan storage:link` after install to serve uploaded images; Docker image does this automatically.
- **Multi-channel** — Each channel has its own domain, theme, and currency; configure under Admin → Settings → Channels.
- **Elasticsearch optional** — Not required; default search uses DB. For large catalogs, configure Elasticsearch via `ELASTICSEARCH_*` env vars.
- **Composer memory** — Set `COMPOSER_MEMORY_LIMIT=-1` if Composer runs out of memory during install.

## Links

- GitHub: https://github.com/bagisto/bagisto
- Docker docs: https://devdocs.bagisto.com/2.3/introduction/docker.html
- Installation: https://devdocs.bagisto.com/2.3/introduction/installation.html
- REST API: https://devdocs.bagisto.com/2.3/api/
- Extensions marketplace: https://bagisto.com/en/extensions/
