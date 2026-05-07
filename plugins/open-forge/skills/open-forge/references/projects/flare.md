# Flare

**Modern self-hosted file sharing platform with screenshot tool integration** — works seamlessly with ShareX, Flameshot, and KDE Spectacle. Combines file vault, URL shortener, pastebin, and OCR-powered search in one Next.js app backed by PostgreSQL.

**Official site:** https://github.com/FlintSH/Flare
**Source:** https://github.com/FlintSH/Flare
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended; needs PostgreSQL |
| Railway | One-click deploy | Button available in repo README |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname for your instance
- Storage backend: local filesystem or S3-compatible (Backblaze B2, MinIO, AWS S3, etc.)
- Whether to run PostgreSQL in Docker Compose or use an external DB

### Phase 2 — Deploy
- `DATABASE_URL` — PostgreSQL connection string
- `NEXTAUTH_SECRET` — random 32-byte base64 string (`openssl rand -base64 32`)
- `NEXTAUTH_URL` — full public URL of your instance (e.g. `https://files.example.com`)
- S3 credentials if using object storage: endpoint, bucket, access key, secret key
- Admin account email/password (created on first launch)

---

## Software-Layer Concerns

- **Stack:** Next.js (App Router), PostgreSQL (via Prisma ORM), optional S3 storage
- **Config:** All config via environment variables in `docker-compose.yml`
- **Data dirs:** Local storage at `/app/uploads` (mount a volume); DB schema managed by Prisma migrations
- **OCR:** Automatic text extraction from uploaded images; enables full-text search across uploads
- **URL shortener:** Custom short URLs under your domain with click tracking
- **Pastebin:** Code/text sharing with syntax highlighting
- **Storage quotas:** Per-user configurable via admin dashboard
- **Embeds:** Rich embeds on social platforms (Discord, Twitter, etc.)

---

## Deployment

```yaml
# docker-compose.yml
version: '3.8'
services:
  db:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: flareuser
      POSTGRES_PASSWORD: your-secure-password
      POSTGRES_DB: flaredb
    volumes:
      - ./postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U flareuser -d flaredb"]
      interval: 10s
      timeout: 5s
      retries: 5

  flare:
    image: flintsh/flare:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://flareuser:your-secure-password@db:5432/flaredb?schema=public
      NEXTAUTH_SECRET: your-secret-here
      NEXTAUTH_URL: https://files.example.com
    volumes:
      - ./uploads:/app/uploads
    depends_on:
      db:
        condition: service_healthy
```

```bash
docker compose up -d
# First-run: visit your URL and create the admin account
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
# Prisma migrations run automatically on startup
```

---

## Gotchas

- **PostgreSQL required** — no SQLite support; must have a running Postgres instance
- **`NEXTAUTH_URL` must match your public URL exactly** — auth callbacks will fail otherwise
- **First-run admin setup** happens via the web UI; no CLI provisioning
- **OCR processing** runs asynchronously after upload; search index builds gradually
- **ShareX config:** Download the pre-configured ShareX config from your Flare dashboard; no manual setup needed
- **S3 storage:** Requires additional env vars (`STORAGE_TYPE=s3`, endpoint, bucket, key, secret); see upstream docs
- **Local uploads volume** — ensure `./uploads` is on persistent storage; Docker volume recommended for production

---

## Links

- Upstream README: https://github.com/FlintSH/Flare#readme
- Discord: https://discord.gg/mwVAjKwPus
