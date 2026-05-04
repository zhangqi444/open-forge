# Cal.diy (Cal.com)

Open-source scheduling and calendar booking platform. Cal.diy (the self-hosted version of Cal.com) lets you build Calendly-like booking pages with full control over your data. Supports team scheduling, round-robin routing, availability management, integrations (Google Calendar, Outlook, Zoom, Stripe), and embeddable booking widgets.

**Official site:** https://cal.com  
**Source:** https://github.com/calcom/cal.diy  
**Upstream docs:** https://cal.com/docs/self-hosting  
**License:** MIT (AGPL-3.0 for some enterprise features)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended self-hosted method |
| Vercel + external DB | Node.js / Next.js | Cloud-hosted frontend |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `NEXT_PUBLIC_WEBAPP_URL` | Public URL of your booking app | `https://cal.example.com` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://unicorn_user:magical_password@database:5432/calendso` |
| `NEXTAUTH_SECRET` | NextAuth signing secret | random 32+ char string |
| `CALENDSO_ENCRYPTION_KEY` | AES encryption key for secrets | random 32 char string |

### Optional
| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_API_V2_URL` | API v2 base URL |
| `NEXT_PUBLIC_LICENSE_CONSENT` | License consent flag |
| `NEXT_PUBLIC_SINGLE_ORG_SLUG` | Lock instance to a single org |
| `ORGANIZATIONS_ENABLED` | Enable multi-org support |
| `CALCOM_TELEMETRY_DISABLED` | Disable telemetry | `1` to opt out |
| `REDIS_PORT` | Redis port | `6379` |

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  database:
    image: postgres
    restart: always
    volumes:
      - database-data:/var/lib/postgresql
    environment:
      - POSTGRES_USER=unicorn_user
      - POSTGRES_PASSWORD=magical_password
      - POSTGRES_DB=calendso

  redis:
    image: redis:latest
    restart: always
    volumes:
      - redis-data:/data
    ports:
      - "${REDIS_PORT:-6379}:6379"

  calcom:
    image: calcom.docker.scarf.sh/calcom/cal.diy
    restart: always
    ports:
      - 3000:3000
    environment:
      - NEXT_PUBLIC_WEBAPP_URL=https://cal.example.com
      - DATABASE_URL=postgresql://unicorn_user:magical_password@database:5432/calendso
      - DATABASE_DIRECT_URL=${DATABASE_URL}
      - NEXTAUTH_SECRET=your-nextauth-secret
      - CALENDSO_ENCRYPTION_KEY=your-32char-key
    depends_on:
      - database
      - redis

volumes:
  database-data:
  redis-data:
```

### Build from source (alternative)
The official Docker image is available at `calcom.docker.scarf.sh/calcom/cal.diy`. To build locally:
```sh
git clone https://github.com/calcom/cal.diy.git
cd cal.diy
cp .env.example .env
# Edit .env, then:
docker compose build
docker compose up -d
```

### Database migrations
Run Prisma migrations on first start:
```sh
docker compose exec calcom npx prisma migrate deploy
```

### Integrations
Calendar and video integrations (Google Calendar, Zoom, Stripe, etc.) require OAuth app credentials set as env vars. See upstream docs for full list.

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull`
2. `docker compose up -d`
3. Run migrations if prompted: `docker compose exec calcom npx prisma migrate deploy`
4. Check release notes: https://github.com/calcom/cal.diy/releases

---

## Gotchas

- **NEXT_PUBLIC_* vars are baked in at build time** — they must be set correctly before building; using the pre-built image means these are pre-configured for `localhost:3000`; for custom domains, build from source or use environment substitution
- **DATABASE_DIRECT_URL** — set to the same value as `DATABASE_URL` unless using a connection pooler (like PgBouncer); Prisma requires a direct connection for migrations
- **Redis is required** — used for rate limiting and background jobs; don't skip it
- **License note** — core scheduling features are MIT; some enterprise/org features carry AGPL-3.0 terms; review before commercial use

---

## Links
- Upstream README: https://github.com/calcom/cal.diy
- Self-hosting docs: https://cal.com/docs/self-hosting
- Environment variable reference: https://cal.com/docs/self-hosting/env-vars
