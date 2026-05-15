---
name: vendure
description: Vendure recipe for open-forge. Headless e-commerce framework built on TypeScript/Node.js + NestJS + GraphQL. Self-hosted via Docker Compose (PostgreSQL backend). Source: https://github.com/vendurehq/vendure. Docs: https://docs.vendure.io.
---

# Vendure

Headless, open-source e-commerce framework built on TypeScript, Node.js, NestJS, and GraphQL. Provides a GraphQL API server, an admin dashboard (React), and a plugin architecture for full customisation. Production deployments use PostgreSQL; MySQL/MariaDB also supported. Upstream: <https://github.com/vendurehq/vendure>. Docs: <https://docs.vendure.io>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + PostgreSQL | Recommended production path per upstream docs |
| VPS / bare metal | Docker Compose + MySQL 8 | Supported; swap DB image + connection string |
| VPS / bare metal | Node.js (native) | Requires Node 20+, local DB; see upstream Getting Started guide |
| Local dev | Docker Compose + SQLite | Not recommended for production |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which database? PostgreSQL (recommended) or MySQL?" | Drives DB_CONNECTION env var |
| db | "Database name?" | e.g. vendure |
| db | "Database user?" | e.g. vendure |
| db | "Database password?" | Generate strong random string |
| app | "Superadmin password?" | Used for initial admin login; change after first login |
| smtp | "SMTP host, port, user, password?" | For transactional email; optional but needed for order confirmations |
| domain | "Public domain or IP for the shop API?" | Used to set CORS origin |

## Software-layer concerns

- Config: environment variables injected at runtime (Docker) or via vendure-config.ts (native)
- Default ports: 3000 (shop API + admin API), admin UI at /admin
- Data dirs: PostgreSQL volume (/var/lib/postgresql/data), assets at ./static/assets
- Plugin system: NPM packages; install into the Vendure app, rebuild image
- Admin UI compilation: first boot triggers UI compilation (~2 min); expect slow initial start

### Minimal Docker Compose (PostgreSQL)

```yaml
services:
  vendure:
    image: vendure/vendure:3.6.3
    depends_on:
      - postgres
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: vendure
      DB_USERNAME: vendure
      DB_PASSWORD: <db-password>
      SUPERADMIN_USERNAME: superadmin
      SUPERADMIN_PASSWORD: <superadmin-password>
      APP_ENV: production
    ports:
      - "3000:3000"
    volumes:
      - vendure-assets:/app/static/assets
    restart: unless-stopped

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: vendure
      POSTGRES_USER: vendure
      POSTGRES_PASSWORD: <db-password>
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  vendure-assets:
  postgres-data:
```

Pin to a specific version tag in production (e.g. vendure/vendure:3.x.y). Check https://hub.docker.com/r/vendure/vendure/tags.

## Upgrade procedure

1. Review release notes: https://github.com/vendurehq/vendure/releases
2. Check migration guide for breaking DB migrations: https://docs.vendure.io/guides/deployment/migration/
3. Pull updated image: docker compose pull
4. DB migrations run automatically on startup (Vendure uses TypeORM migration:run mode)
5. docker compose up -d
6. Verify admin UI loads at http://localhost:3000/admin

## Gotchas

- Admin UI compilation: On first run (or after plugin changes) Vendure compiles the admin UI. Adds 1-3 min to first boot - do not kill the container.
- Plugin installs: Plugins are NPM packages; adding them requires rebuilding the Docker image.
- CORS: Set cors.origin in vendure-config.ts (or env) to your storefront's origin; default is open in dev.
- Asset storage: Default local disk is fine for single-node; multi-replica needs S3-compatible storage via @vendure/asset-server-plugin.
- GraphQL playground: Enabled by default in dev (APP_ENV=development); disabled in production.
- License: GPLv3 (core). Enterprise license available for additional features.

## Links

- Upstream repo: https://github.com/vendurehq/vendure
- Docs / Getting Started: https://docs.vendure.io/guides/getting-started/installation/
- Docker Hub: https://hub.docker.com/r/vendure/vendure
- Release notes: https://github.com/vendurehq/vendure/releases
- Discord community: https://www.vendure.io/community
