---
name: pimcore
description: Pimcore recipe for open-forge. Open-source data and experience management platform combining PIM, MDM, DAM, CMS, and digital commerce in one Symfony/PHP application. Self-hosted via Docker Compose (skeleton or demo project). Source: https://github.com/pimcore/pimcore. Docs: https://pimcore.com/docs.
---

# Pimcore

Open-source data and experience management platform built on Symfony + PHP. Combines PIM (Product Information Management), MDM (Master Data Management), DAM (Digital Asset Management), DXP/CMS, and digital commerce in one application. Designed for enterprises managing complex product catalogs, multi-channel content, and digital assets. Upstream: <https://github.com/pimcore/pimcore>. Docs: <https://pimcore.com/docs>.

> **Note on license:** The README references POCL (Pimcore Open Core License) for some enterprise features; the core framework is GPL-3.0. Verify the license for your specific use case at https://github.com/pimcore/pimcore/blob/11.x/LICENSE.md.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose (skeleton project) | Recommended for new projects; uses pimcore/pimcore PHP image |
| VPS / bare metal | Docker Compose (demo project) | Better for evaluation; ships with sample data |
| VPS / bare metal | Native PHP 8.2+ + MariaDB + Redis | Advanced setups; requires Composer, Symfony CLI knowledge |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "New project (skeleton) or evaluation (demo)?" | Skeleton = clean start; demo = pre-populated sample data |
| db | "MariaDB root password?" | Used by the Docker compose DB service |
| db | "Pimcore DB user password?" | Application DB user |
| admin | "Admin username and password?" | Set during pimcore-install step |
| domain | "Public domain?" | For NGINX vhost and TLS setup |

## Software-layer concerns

- Stack: PHP 8.2+ (FPM), NGINX, MariaDB 10.11+, Redis, RabbitMQ (async messaging)
- Config: .env file + config/packages/ (Symfony config); pimcore-specific settings in config/pimcore/
- Default port: 80
- Admin path: /admin
- Data dirs: var/ (cache, logs, versions), public/var/ (generated assets, thumbnails), public/assets/ (uploaded DAM files)
- PHP requirements: PHP 8.2+; extensions: gd, imagick, intl, mbstring, opcache, pdo_mysql, redis, zip + many others
- Async processing: RabbitMQ + Supervisor; required for background tasks (asset processing, versioning, search indexing)
- Install time: pimcore-install runs DB migrations and can take 10–20 minutes on first run

### Docker setup (skeleton project)

```bash
# 1. Create project with pimcore/pimcore image (no local PHP needed)
docker run -u $(id -u):$(id -g) --rm -v $(pwd):/var/www/html \
  pimcore/pimcore:php8.3-latest \
  composer create-project pimcore/skeleton my-project

cd my-project

# 2. Fix user ID in docker-compose.yaml
sed -i "s|#user: '1000:1000'|user: '$(id -u):$(id -g)'|g" docker-compose.yaml

# 3. Start services
docker compose up -d

# 4. Install Pimcore (runs DB migrations; takes 5-20 min)
docker compose exec php vendor/bin/pimcore-install \
  --install-profile='App\Installer\SkeletonProfile'
# Enter admin username and password when prompted

# 5. Access admin
xdg-open http://localhost/admin
```

### docker-compose.yaml services (from skeleton)

```yaml
services:
  redis:
    image: redis:alpine
    command: [redis-server, --maxmemory, 128mb, --maxmemory-policy, volatile-lru, --save, ""]

  rabbitmq:
    image: rabbitmq:alpine
    volumes:
      - pimcore-rabbitmq:/var/lib/rabbitmq/

  db:
    image: mariadb:10.11
    command: [mysqld, --character-set-server=utf8mb4, --collation-server=utf8mb4_unicode_520_ci]
    environment:
      MYSQL_ROOT_PASSWORD: ROOT
      MYSQL_DATABASE: pimcore
      MYSQL_USER: pimcore
      MYSQL_PASSWORD: pimcore
    volumes:
      - pimcore-database:/var/lib/mysql

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
    volumes:
      - .:/var/www/html:ro
      - ./.docker/nginx.conf:/etc/nginx/conf.d/default.conf:ro

  php:
    image: pimcore/pimcore:php8.3-latest
    volumes:
      - .:/var/www/html

volumes:
  pimcore-database:
  pimcore-rabbitmq:
```

## Upgrade procedure

1. Review upgrade notes in the UPGRADE.md file of the new version
2. `docker compose pull` to get new PHP image
3. Update composer dependencies: `docker compose exec php composer update`
4. Run migrations: `docker compose exec php bin/console doctrine:migrations:migrate`
5. Clear cache: `docker compose exec php bin/console cache:clear`
6. Check release notes: https://github.com/pimcore/pimcore/releases

## Gotchas

- **Install takes time**: The pimcore-install step runs many DB migrations and can take 10–20 minutes. Don't interrupt it.
- **user: UID:GID must be set**: Without the correct user mapping in docker-compose.yaml, var/ and public/var/ will be owned by root and PHP-FPM can't write to them. Run the sed command in step 2 above.
- **RabbitMQ + Supervisor required for async**: Asset processing (thumbnails, video transcoding, full-text extraction) runs asynchronously. Without RabbitMQ consumers running, background jobs queue up and never process.
- **Memory**: PHP needs 256–512 MB per request for heavy admin operations. Set memory_limit = 512M in php.ini.
- **Composer dependencies are large**: Initial composer install can take 5–10 minutes and pulls many packages.
- **License**: Some Pimcore bundles (e-commerce framework, etc.) are under the POCL commercial license. Check individual bundle licenses before using in commercial projects.

## Links

- Upstream repo: https://github.com/pimcore/pimcore
- Skeleton project: https://github.com/pimcore/skeleton
- Demo project: https://github.com/pimcore/demo
- Docs: https://pimcore.com/docs
- Docker Hub: https://hub.docker.com/r/pimcore/pimcore
- Release notes: https://github.com/pimcore/pimcore/releases
