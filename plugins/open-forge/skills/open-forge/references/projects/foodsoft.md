---
name: foodsoft
description: Foodsoft recipe for open-forge. Web-based software to manage a non-profit food cooperative — product catalog, ordering, accounting, and job scheduling. Source: https://github.com/foodcoops/foodsoft
---

# Foodsoft

Web-based software to manage a non-profit food cooperative (food coop). Handles product catalog, member ordering, accounting, and job/task scheduling. Members order products online and collect on a specified day; Foodsoft coordinates the logistics and finances. AGPL-licensed, Ruby on Rails app.

Upstream: <https://github.com/foodcoops/foodsoft> | Docs: <https://github.com/foodcoops/foodsoft/wiki>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (foodcoops/foodsoft) | Official image — recommended production path |
| Any | Docker Compose | Compose with MySQL + Redis + Foodsoft |
| Linux | Ruby on Rails (manual) | For development or custom deployments |
| Managed | foodcoops.net hosting | Out of scope for open-forge — managed service |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | SECRET_KEY_BASE | Random 30+ char string; generate with: ruby -e "require 'securerandom'; puts SecureRandom.hex(64)" |
| config | DATABASE_URL | MySQL2 connection string: mysql2://user:pass@host/dbname?encoding=utf8 |
| config | REDIS_URL | Redis connection: redis://host:6379 |
| config | App config file path | Copy config/app_config.yml.SAMPLE and customize |
| config | Domain / reverse proxy | Foodsoft listens on :3000; put behind nginx/Caddy for TLS |
| smtp | SMTP settings | For member notifications and password reset |

## Software-layer concerns

### Required external services

- MySQL (or MariaDB) — primary database
- Redis — background jobs (Sidekiq workers)

### Key environment variables

| Var | Description |
|---|---|
| SECRET_KEY_BASE | Rails secret key (mandatory) |
| DATABASE_URL | mysql2://user:pass@host/dbname?encoding=utf8 |
| REDIS_URL | redis://host:6379 |
| RAILS_FORCE_SSL | Set false if SSL terminated at reverse proxy |
| RAILS_ENV | production |

### Config file

Copy `config/app_config.yml.SAMPLE` to `config/app_config.yml` and mount it into the container. This file controls foodcoop name, currencies, features, email settings, and more.

### Data dirs

- Uploads: inside the container at Rails default paths. Mount a volume if persistent file uploads are needed.
- Database: external MySQL — no local data dir.

## Install — Docker Compose (recommended)

```bash
mkdir foodsoft && cd foodsoft

# Create app_config.yml from the sample
curl -O https://raw.githubusercontent.com/foodcoops/foodsoft/master/config/app_config.yml.SAMPLE
cp app_config.yml.SAMPLE app_config.yml
# Edit app_config.yml: set foodcoop name, timezone, email settings, etc.

cat > docker-compose.yml << 'EOF'
services:
  db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: foodsoft
      MYSQL_USER: foodsoft
      MYSQL_PASSWORD: foodsoftpass
    volumes:
      - db_data:/var/lib/mysql

  redis:
    image: redis:7-alpine
    restart: unless-stopped

  web:
    image: foodcoops/foodsoft:latest
    restart: unless-stopped
    depends_on: [db, redis]
    ports:
      - "3000:3000"
    environment:
      SECRET_KEY_BASE: CHANGE_ME_32_CHARS_MIN
      DATABASE_URL: mysql2://foodsoft:foodsoftpass@db/foodsoft?encoding=utf8
      REDIS_URL: redis://redis:6379
      RAILS_FORCE_SSL: "false"
    volumes:
      - ./app_config.yml:/usr/src/app/config/app_config.yml:ro

  worker:
    image: foodcoops/foodsoft:latest
    restart: unless-stopped
    depends_on: [db, redis]
    command: ./proc-start worker
    environment:
      SECRET_KEY_BASE: CHANGE_ME_32_CHARS_MIN
      DATABASE_URL: mysql2://foodsoft:foodsoftpass@db/foodsoft?encoding=utf8
      REDIS_URL: redis://redis:6379
    volumes:
      - ./app_config.yml:/usr/src/app/config/app_config.yml:ro

  cron:
    image: foodcoops/foodsoft:latest
    restart: unless-stopped
    depends_on: [db, redis]
    command: ./proc-start cron
    environment:
      SECRET_KEY_BASE: CHANGE_ME_32_CHARS_MIN
      DATABASE_URL: mysql2://foodsoft:foodsoftpass@db/foodsoft?encoding=utf8
      REDIS_URL: redis://redis:6379
    volumes:
      - ./app_config.yml:/usr/src/app/config/app_config.yml:ro

volumes:
  db_data:
EOF

# Initialize database (first run only)
docker compose run --rm web bundle exec rake db:setup

# Start
docker compose up -d
```

App available at http://localhost:3000. Put behind nginx or Caddy for TLS.

## Upgrade procedure

```bash
docker compose pull
docker compose run --rm web bundle exec rake db:migrate
docker compose up -d
```

Always back up the MySQL database before upgrading:
```bash
docker compose exec db mysqldump -u root -prootpass foodsoft > backup-$(date +%Y%m%d).sql
```

## Gotchas

- SECRET_KEY_BASE is mandatory — Foodsoft will not start without it. Generate with `ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"` or `openssl rand -hex 64`.
- db:setup vs db:migrate — run db:setup only on first install (creates + seeds tables). For upgrades, run db:migrate.
- Worker and cron containers are separate — the web container only handles HTTP; background jobs (order reminders, email, etc.) require the worker container. Cron handles scheduled tasks. Both should always be running.
- RAILS_FORCE_SSL — set to false if SSL is terminated at a reverse proxy (most setups). Set true only if Foodsoft itself terminates TLS.
- app_config.yml is required — without it, Foodsoft starts but many features (foodcoop name, currencies, features flags) use defaults. Mount the customized config before first run.
- Account creation is open by default — anyone who can reach the URL can register. Review and configure membership settings in the admin panel immediately after install.

## Links

- Upstream: https://github.com/foodcoops/foodsoft
- Wiki / docs: https://github.com/foodcoops/foodsoft/wiki
- Production setup guide: https://github.com/foodcoops/foodsoft/blob/master/doc/SETUP_PRODUCTION.md
- Docker Hub: https://hub.docker.com/r/foodcoops/foodsoft
