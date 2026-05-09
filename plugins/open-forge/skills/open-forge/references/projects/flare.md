---
name: Flare
description: "Modern self-hosted file sharing platform. Works with ShareX, Flameshot, KDE Spectacle out-of-the-box. Next.js + PostgreSQL + Docker. URL shortener, pastebin, OCR image search, rich embeds, S3-compatible storage option, admin dashboard, user management with quotas."
---

# Flare

Flare is a **modern, self-hostable file sharing platform** built with Next.js, designed for integration with screenshot tools like **ShareX, Flameshot, and KDE Spectacle**. One-click config/script download from the dashboard gets any of these tools wired up immediately. Features URL shortener, pastebin with syntax highlighting, OCR text extraction from uploaded images, and rich social media embeds.

- Upstream repo: <https://github.com/FlintSH/Flare>
- Docker Hub: <https://hub.docker.com/r/flintsh/flare>
- License: MIT
- Discord: <https://discord.gg/mwVAjKwPus>

## Architecture

- **Frontend + backend**: Next.js (port 3000)
- **Database**: PostgreSQL (required)
- **Storage**: Local filesystem (`./uploads`) or S3-compatible
- **OCR**: Automatic text extraction on image uploads (via optional dependency)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Docker Compose | flintsh/flare:latest | Primary |
| Railway | One-click template | Managed; set auth secret + create admin |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| Domain | share.example.com | dns | |
| NEXTAUTH_SECRET | openssl rand -base64 32 | preflight | JWT signing key |
| NEXTAUTH_URL | https://share.example.com | preflight | Full public URL |
| PostgreSQL password | strong-random-pw | db | |
| DATABASE_URL | postgresql://flareuser:pw@db:5432/flaredb?schema=public | db | Auto-built from above |
| Storage backend | local or S3 | storage | Configure in dashboard after setup |
| S3 endpoint / bucket / keys | varies | storage | Optional; configure in Settings |

## Install via Docker Compose

From upstream README: <https://github.com/FlintSH/Flare#docker-deployment-self-hosted>

```yaml
version: '3.8'

services:
  db:
    image: postgres:17-alpine
    container_name: flare-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: flareuser
      POSTGRES_PASSWORD: your-secure-password-here   # CHANGE THIS
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
    container_name: flare-app
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://flareuser:your-secure-password-here@db:5432/flaredb?schema=public
      NEXTAUTH_SECRET: securestuffhere   # openssl rand -base64 32
      NEXTAUTH_URL: http://localhost:3000  # change to https://yourdomain.com
    volumes:
      - ./uploads:/app/uploads
    depends_on:
      db:
        condition: service_healthy
```

```bash
docker compose up -d
# Open http://localhost:3000 to complete setup and create admin account
```

## First boot

1. Browse to `http://localhost:3000`
2. Complete setup wizard — creates admin account
3. Go to Dashboard > Settings to configure:
   - Storage quotas and file size limits
   - Registration options (open/invite-only/closed)
   - Appearance / custom CSS
4. Go to Dashboard > Integrations to download ShareX config or Bash upload script

## Configuration (in-app dashboard)

Most configuration is done through `/dashboard/settings`:

- **Storage**: file size limits, quotas per user
- **Registration**: open, invite-only, or disabled
- **Appearance**: theme, custom CSS, custom HTML
- **Advanced**: custom CSS/HTML injection

## ShareX integration

1. Log in → go to Dashboard > Integrations
2. Download the auto-generated ShareX config (`.sxcu` file)
3. Import into ShareX — uploads immediately go to your Flare instance

Same flow for Flameshot (bash script) and KDE Spectacle (bash script).

## S3-compatible storage

Configure in Settings after initial setup. Supports any S3-compatible provider (MinIO, Backblaze B2, Cloudflare R2, AWS S3).

## Features summary

- File upload with drag-and-drop
- URL shortener with click tracking
- Pastebin with syntax highlighting
- OCR — automatic text extraction from images, searchable
- Rich embeds on social platforms
- Admin dashboard: usage stats, user management, content moderation
- User management: role assignment, storage quotas
- Role-based permissions, private files, password-protected files
- Search by filename, OCR content, date with filters

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Gotchas

- NEXTAUTH_URL must exactly match your public URL (including https://) — wrong value causes auth failures
- NEXTAUTH_SECRET must be set and stable — changing it invalidates all sessions
- PostgreSQL is required — no SQLite option
- uploads/ volume must be persisted; data loss if container recreated without volume bind
- Behind a reverse proxy: set X-Forwarded-For and X-Real-IP headers; Next.js trusts proxied hosts
- Large file uploads: increase `client_max_body_size` in nginx or `upload_max_filesize` in proxy config

## TODO — verify on subsequent deployments

- Confirm S3 storage configuration UI fields match latest release
- Validate OCR search behavior with non-English text
