---
name: shopware-community-edition
description: Shopware Community Edition recipe for open-forge. Open-source headless e-commerce platform built on Symfony and Vue.js. Source: https://github.com/shopware/shopware. Website: https://shopware.com.
---

# Shopware Community Edition

Open-source headless e-commerce platform built on Symfony 7 and Vue.js 3. Powers thousands of online shops worldwide. API-first architecture with a full-featured storefront, admin panel, and plugin ecosystem of 3,100+ extensions. Supports Docker-based deployment via the flex template. License: MIT. Upstream: <https://github.com/shopware/shopware>. Website: <https://shopware.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker + Flex template | Recommended production path |
| VPS / bare metal | Composer + Nginx/Apache | Manual install via flex template |
| Local dev | Symfony CLI / ddev | Official devenv support |
| Cloud | DigitalOcean / Hetzner / hosting partners | Pre-configured managed hosts available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Storefront domain?" | e.g. shop.example.com |
| db_host | "MySQL/MariaDB host?" | e.g. 127.0.0.1 or Docker service name |
| db_name | "Database name?" | e.g. shopware |
| db_user | "Database user?" | |
| db_pass | "Database password?" | |
| app_env | "APP_ENV (prod or dev)?" | Use prod for production |
| app_secret | "APP_SECRET (random string)?" | Generate with `openssl rand -hex 32` |
| mailer_dsn | "Mailer DSN?" | e.g. smtp://user:pass@host:587 |
| admin_user | "Initial admin username?" | Set during first-run wizard |
| admin_pass | "Initial admin password?" | |

## Software-layer concerns

- **PHP >= 8.2** required; recommended extensions: `curl`, `dom`, `fileinfo`, `gd`, `intl`, `json`, `mbstring`, `mysql` (or `pgsql`), `opcache`, `simplexml`, `xml`, `zip`, `zlib`
- **MySQL 8.0+ or MariaDB 10.6+** — required
- **Elasticsearch/OpenSearch** — optional but strongly recommended for large catalogs (10k+ products)
- **Redis** — optional but recommended for session storage and caching
- Config via `.env` file (`APP_ENV`, `APP_SECRET`, `DATABASE_URL`, `MAILER_DSN`, etc.)
- All media, plugins, and generated files live under `var/` and `public/` — mount these for persistence
- Admin panel: `https://your-domain/admin`
- Storefront: `https://your-domain/`

### Docker Compose (production skeleton)

```yaml
# Shopware uses the flex template — use the official Docker setup:
# https://developer.shopware.com/docs/guides/installation/

services:
  shopware:
    image: shopware/shopware:latest
    container_name: shopware
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      DATABASE_URL: "mysql://shopware:secret@db:3306/shopware"
      APP_ENV: prod
      APP_SECRET: changeme_use_openssl_rand
      MAILER_DSN: "smtp://localhost:25"
    volumes:
      - shopware-media:/var/www/html/public/media
      - shopware-var:/var/www/html/var
    depends_on:
      - db

  db:
    image: mysql:8.0
    container_name: shopware-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: shopware
      MYSQL_USER: shopware
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - shopware-db:/var/lib/mysql

volumes:
  shopware-media:
  shopware-var:
  shopware-db:
```

### Flex template install (bare metal / VPS)

```bash
# Install via the official flex template
composer create-project shopware/production:dev-main my-shop
cd my-shop
cp .env.dist .env
# Edit .env: set DATABASE_URL, APP_SECRET, etc.
bin/console system:install --create-database --basic-setup
bin/console theme:compile
bin/console cache:clear
```

Detailed guide: https://developer.shopware.com/docs/guides/installation/

## Upgrade procedure

1. **Docker**: update the image tag in `docker-compose.yml`, then:
   ```bash
   docker compose pull && docker compose up -d
   docker exec -it shopware bin/console system:update:finish
   ```
2. **Flex template**:
   ```bash
   composer update shopware/\*
   bin/console system:update:finish
   bin/console theme:compile
   bin/console cache:clear
   ```
3. Review the [changelog](https://github.com/shopware/shopware/blob/trunk/CHANGELOG.md) for breaking changes before major version upgrades.
4. Always backup the database before upgrading.

## Gotchas

- **Community Edition limits**: CE is fully functional but some advanced features (B2B suite, AI Copilot, advanced search) require paid commercial plans. Review the [pricing page](https://www.shopware.com/en/pricing/) before deployment.
- **Elasticsearch / OpenSearch required at scale**: Without a search engine, product search uses MySQL `LIKE` queries which degrade badly with large catalogs. Enable Elasticsearch for 10k+ products.
- **Theme compilation is slow**: `bin/console theme:compile` can take 2-5 minutes. Ensure adequate RAM (≥2 GB) and consider running it during off-peak hours.
- **APP_SECRET must be set**: An empty or default `APP_SECRET` causes a security warning and breaks encrypted session data. Generate with `openssl rand -hex 32`.
- **Plugin compatibility**: After Shopware version upgrades, verify all installed plugins are compatible. Incompatible plugins can break the storefront or admin.
- **CLI required for first-time setup**: The web installer is available but `bin/console system:install` is the more reliable path for automated/Docker deployments.

## Links

- Upstream repo: https://github.com/shopware/shopware
- Website: https://shopware.com
- Developer documentation: https://developer.shopware.com/docs/guides/installation/
- Docker setup guide: https://developer.shopware.com/docs/guides/installation/
- Flex template: https://github.com/shopware/production
- Extension store: https://store.shopware.com/en/
- Community forum: https://forum.shopware.com/
- Release changelog: https://github.com/shopware/shopware/blob/trunk/CHANGELOG.md
