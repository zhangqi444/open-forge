# Medusa

Open-source digital commerce platform. Medusa is a modular, headless commerce engine for building custom storefronts, B2B platforms, marketplaces, and subscription services. Built on Node.js with a framework for customization — bring your own frontend (Next.js, Remix, etc.) or use the Medusa storefront starter.

**Official site:** https://medusajs.com  
**Source:** https://github.com/medusajs/medusa  
**Upstream docs:** https://docs.medusajs.com  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Node.js (npm/yarn) | Primary development method |
| Any Linux host | Docker Compose | Community-supported; no official compose in v2 |
| Medusa Cloud | Managed | Official hosted option |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://medusa:password@localhost:5432/medusa` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379` |
| `JWT_SECRET` | JWT signing secret | random 32+ char string |
| `COOKIE_SECRET` | Cookie signing secret | random 32+ char string |

### Optional
| Variable | Description |
|----------|-------------|
| `STORE_CORS` | CORS origins for storefront | `http://localhost:8000` |
| `ADMIN_CORS` | CORS origins for admin panel | `http://localhost:7001` |
| `AUTH_CORS` | CORS origins for auth | `http://localhost:7001,http://localhost:8000` |

---

## Software-Layer Concerns

### Quick start (Node.js)
```sh
npx create-medusa-app@latest
# Follow prompts: choose project name, skip cloud setup for local
cd my-medusa-store
# Start backend
medusa develop
# Admin panel runs at http://localhost:7001
# Backend API at http://localhost:9000
```

### Docker Compose (community)
No official Docker Compose file is included in Medusa v2. Community approach:
```yaml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: medusa
      POSTGRES_PASSWORD: medusa
      POSTGRES_DB: medusa
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  medusa:
    image: node:20-alpine
    working_dir: /app
    volumes:
      - ./:/app
    environment:
      DATABASE_URL: postgresql://medusa:medusa@postgres:5432/medusa
      REDIS_URL: redis://redis:6379
      JWT_SECRET: your-jwt-secret
      COOKIE_SECRET: your-cookie-secret
    command: sh -c "npm install && npx medusa db:migrate && npx medusa develop"
    ports:
      - "9000:9000"
      - "7001:7001"
    depends_on:
      - postgres
      - redis

volumes:
  pg_data:
  redis_data:
```

### Architecture
- **Backend API** — port 9000; REST + GraphQL; handles products, orders, customers, payments
- **Admin panel** — port 7001; built-in dashboard for managing catalog, orders, customers
- **Storefront** — separate Next.js app (starter: `github.com/medusajs/nextjs-starter-medusa`); port 8000
- **Modules** — commerce logic (products, orders, pricing, promotions) are standalone npm packages

### Database migrations
Run after install and before each upgrade:
```sh
npx medusa db:migrate
```

---

## Upgrade Procedure

1. Update dependencies: `npm install @medusajs/medusa@latest`
2. Run migrations: `npx medusa db:migrate`
3. Restart the server
4. Check release notes: https://github.com/medusajs/medusa/releases

---

## Gotchas

- **Medusa v2 is a full rewrite** — breaking changes from v1; modules system, config format, and deploy process differ significantly from v1 docs
- **No official Docker image** — Medusa v2 is designed as a Node.js framework you deploy via your own build; use Node.js base images in Docker
- **PostgreSQL required** — SQLite is not supported in production; PostgreSQL 14+ recommended
- **Redis required for v2** — used for event bus and workflow engine; not optional
- **CORS configuration critical** — `STORE_CORS`, `ADMIN_CORS`, and `AUTH_CORS` must include all origins that access the API; wrong values cause 403s in the browser

---

## Links
- Upstream README: https://github.com/medusajs/medusa
- Documentation: https://docs.medusajs.com
- Commerce modules: https://docs.medusajs.com/resources/commerce-modules
- Next.js storefront starter: https://github.com/medusajs/nextjs-starter-medusa
