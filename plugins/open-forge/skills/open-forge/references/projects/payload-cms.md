# Payload CMS

Next.js-native headless CMS and application framework. Payload installs directly into your existing Next.js `/app` folder — the admin panel, API, and database layer are all part of the same codebase. Supports MongoDB and PostgreSQL, rich text, custom fields, auth, file uploads, and access control. Self-hosted, no vendor lock-in.

**Official site:** https://payloadcms.com  
**Source:** https://github.com/payloadcms/payload  
**Upstream docs:** https://payloadcms.com/docs  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Node.js (Next.js) | Primary method; runs as part of Next.js app |
| Vercel + external DB | Serverless | Official free tier on Vercel |
| Any host | Docker | Community-supported; build your own image |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URI` | MongoDB or PostgreSQL connection string | `mongodb://localhost/payload` or `postgresql://user:pass@host:5432/db` |
| `PAYLOAD_SECRET` | Encryption/signing secret | random 32+ char string |

### Optional
| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_SERVER_URL` | Public base URL (used for media uploads and emails) | `https://cms.example.com` |
| `PAYLOAD_CONFIG_PATH` | Path to Payload config file | `src/payload.config.ts` |

---

## Software-Layer Concerns

### Quick start (new project)
```sh
pnpx create-payload-app@latest
# Choose a template:
#   website     — full featured (recommended for learning)
#   blank       — minimal setup
#   ecommerce   — shop starter with products, cart, checkout
cd my-payload-app
pnpm dev
# Admin panel: http://localhost:3000/admin
# API: http://localhost:3000/api
```

### Adding Payload to existing Next.js app
```sh
pnpx create-payload-app@latest --init-existing-project
```

### Docker Compose (with MongoDB)
```yaml
services:
  payload:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URI: mongodb://mongo:27017/payload
      PAYLOAD_SECRET: your-secret-here
      NEXT_PUBLIC_SERVER_URL: http://localhost:3000
    depends_on:
      - mongo

  mongo:
    image: mongo:7
    volumes:
      - mongo_data:/data/db

volumes:
  mongo_data:
```

### Database support
- **MongoDB** — traditional choice; flexible schema; recommended for content-heavy projects
- **PostgreSQL** — Drizzle ORM adapter; recommended for relational data, transactions, analytics

### Key concepts
- `payload.config.ts` — central config: collections, globals, fields, plugins, access control
- **Collections** — data models (like Posts, Users, Products); each gets auto-generated API endpoints + admin UI
- **Globals** — singleton documents (like site settings, nav menus)
- **Local API** — call `payload.find(...)` etc. directly in React Server Components (no HTTP)
- **REST + GraphQL** — auto-generated from your collections config

### Media uploads
Files stored locally by default (`/public/media`). Configure S3, Cloudflare R2, etc. via upload adapters in `payload.config.ts`.

---

## Upgrade Procedure

1. Update: `pnpm add payload@latest @payloadcms/next@latest @payloadcms/db-mongodb@latest` (or postgres adapter)
2. Review migration guide: https://payloadcms.com/docs/migration
3. Run DB migrations (if using Postgres adapter): `pnpm payload migrate`
4. Restart app

---

## Gotchas

- **Payload v3 is Next.js-native** — it installs inside your Next.js app, not as a separate service; previous v1/v2 was a standalone Express server
- **No official Docker image** — build your own Dockerfile based on `node:20-alpine`; many community templates exist
- **DATABASE_URI is required at build time** — Next.js builds require DB access; ensure DB is available during `next build`
- **PAYLOAD_SECRET must not change** — all tokens and encrypted fields use this key; rotating it invalidates all sessions and some encrypted data
- **Local API is the fastest path** — for Next.js apps colocated with Payload, use the Local API (direct function calls) rather than HTTP for better performance

---

## Links
- Upstream README: https://github.com/payloadcms/payload
- Documentation: https://payloadcms.com/docs
- Templates: https://github.com/payloadcms/payload/tree/main/templates
