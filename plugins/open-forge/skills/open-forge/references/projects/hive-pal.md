---
name: hive-pal
description: Hive Pal recipe for open-forge. Mobile-first beekeeping management app — track apiaries, hives, inspections, queen records, and equipment. Node.js + PostgreSQL + Docker. Source: https://github.com/martinhrvn/hive-pal
---

# Hive Pal

A modern beekeeping management application designed for both mobile and desktop use. Track apiaries, hives, inspection records, queen lineage, and equipment. Mobile-first design optimized for field data entry. MIT licensed, built on Node.js with a PostgreSQL backend. Upstream: <https://github.com/martinhrvn/hive-pal>. Demo: <https://hivepal.app>

> ⚠️ **Work in Progress**: Per upstream README — the API is mostly stable but breaking changes may occur.

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | PostgreSQL | Only supported database |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Hive Pal?" | FQDN | e.g. bees.example.com |
| "Admin email address?" | Email | Used for initial admin account |
| "Admin password?" | String (sensitive) | Initial admin credentials |
| "PostgreSQL password?" | String (sensitive) | For the bundled database |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Storage type for uploads?" | local / s3 | local = filesystem; s3 = S3-compatible object storage |
| "S3 credentials?" | bucket + key + secret | Only if using S3 storage |
| "Frontend URL?" | URL | Must match the public URL — used for CORS and links |

## Software-Layer Concerns

- **PostgreSQL required**: No SQLite or MySQL support — PostgreSQL is the only supported database.
- **Upload storage**: Inspection photo uploads go to either local filesystem (`/data/uploads`) or S3-compatible storage. Local storage requires persistent volume.
- **ADMIN_EMAIL / ADMIN_PASSWORD**: Used to seed the initial admin account on first run.
- **FRONTEND_URL**: Must exactly match the public URL of the instance — used for CORS configuration.
- **Actively developed**: As of early 2026, the project had very high commit activity (294 commits in March 2026). Expect frequent updates.
- **Database migrations**: Run automatically on startup.

## Deployment

### Docker Compose

```yaml
services:
  app:
    image: ghcr.io/martinhrvn/hive-pal:latest
    ports:
      - '80:3000'
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://postgres:changeme@postgres:5432/beekeeper
      ADMIN_EMAIL: admin@example.com
      ADMIN_PASSWORD: changeme123
      FRONTEND_URL: https://bees.example.com
      STORAGE_TYPE: local
    volumes:
      - uploads:/data/uploads
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: postgres:14
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: beekeeper
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres -d beekeeper']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
  uploads:
```

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Database migrations run automatically on startup.
3. Backup PostgreSQL data volume before upgrading: `docker compose exec postgres pg_dump -U postgres beekeeper > backup.sql`
4. Given the WIP status, check release notes at https://github.com/martinhrvn/hive-pal/releases before upgrading.

## Gotchas

- **WIP / breaking changes**: Upstream explicitly warns of possible breaking changes. Pin to a specific image tag for stability in production.
- **PostgreSQL only**: No other database backends supported.
- **FRONTEND_URL mismatch**: If FRONTEND_URL doesn't match the browser URL, CORS errors will prevent the app from loading.
- **S3 for multi-server setups**: Local storage won't work if you run multiple app instances behind a load balancer — use S3-compatible storage in that case.
- **Mobile-first**: UI is optimized for field use on phones. Desktop works but the primary design target is mobile.

## Links

- Source: https://github.com/martinhrvn/hive-pal
- Demo / Website: https://hivepal.app
- Releases: https://github.com/martinhrvn/hive-pal/releases
