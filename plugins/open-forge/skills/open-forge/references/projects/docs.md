---
name: docs
description: La Suite Docs recipe for open-forge. Open-source collaborative document editor (Notion/Google Docs alternative) by the French government's La Suite Numérique initiative. Docker Compose deploy. Upstream: https://github.com/suitenumerique/docs
---

# La Suite Docs

Open-source collaborative document editor built for real-time writing, knowledge organization, and team documentation. Created by the French government's La Suite Numérique initiative as an open alternative to Notion and Google Docs.

16,466 stars · MIT

Upstream: https://github.com/suitenumerique/docs
Website: https://docs.numerique.gouv.fr/
Docs: https://github.com/suitenumerique/docs/blob/main/docs/

## What it is

Docs provides a full collaborative writing environment:

- **Rich-text editing** — Slash commands, block system, Markdown support, beautiful formatting
- **Real-time collaboration** — Live cursors, presence indicators, simultaneous editing
- **Knowledge organization** — Nested documents, teams, granular access control
- **Offline editing** — Works without network connection; syncs when reconnected
- **AI writing helpers** (optional) — Rewrite, summarize, translate, fix typos (requires external AI endpoint)
- **Comments & sharing** — Thread comments, public sharing links
- **Open standard** — Documents stored as structured content; export to Markdown, PDF, DOCX

Built for public organizations, companies, and open communities that want data sovereignty.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose | https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md | Production and local dev — recommended approach |
| Source (dev) | https://github.com/suitenumerique/docs/blob/main/docs/dev.md | Contributing to the codebase |

## Requirements

- Docker Engine 24+ and Docker Compose v2
- PostgreSQL 14+ (bundled in Compose)
- 2 GB RAM minimum; 4 GB recommended for production

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "What domain will Docs be served on?" | Production deploy |
| auth | "Use external OIDC/SSO provider, or local email/password?" | All |
| oidc | "OIDC provider client ID and secret?" | If using SSO |
| storage | "Local filesystem storage or S3-compatible object storage?" | Production |
| s3 | "S3 bucket name, endpoint, access key, and secret?" | If using S3 |

## Docker Compose install

Upstream: https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md

### 1. Clone and configure

    git clone https://github.com/suitenumerique/docs.git
    cd docs
    cp env.d/development/common.dist.env env.d/development/common.env

Edit `env.d/development/common.env` — at minimum set:

    SECRET_KEY=<generate with: openssl rand -hex 32>
    DJANGO_ALLOWED_HOSTS=yourdomain.com

### 2. Start the stack

    docker compose up -d

Services started:

| Service | Role |
|---|---|
| app | Django backend (port 8000 internal) |
| frontend | Next.js web UI |
| postgres | PostgreSQL database |
| redis | Session cache and real-time pub/sub |
| y-provider | Yjs CRDT collaboration backend |
| nginx | Reverse proxy (port 80) |

### 3. Create initial admin

    docker compose exec app python manage.py createsuperuser

### 4. Access

Open http://localhost or http://yourdomain.com.

## Environment variables (key ones)

| Variable | Notes |
|---|---|
| `SECRET_KEY` | Django secret key — generate with `openssl rand -hex 32` |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated list of allowed hostnames |
| `DB_HOST` / `DB_NAME` / `DB_USER` / `DB_PASSWORD` | PostgreSQL connection |
| `REDIS_URL` | Redis connection URL (default: redis://redis:6379/1) |
| `AWS_S3_ENDPOINT_URL` | S3-compatible endpoint for file storage |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | S3 credentials |
| `OIDC_RP_CLIENT_ID` / `OIDC_RP_CLIENT_SECRET` | OIDC provider credentials |

Full env reference: https://github.com/suitenumerique/docs/blob/main/docs/env.md

## HTTPS / reverse proxy

For production, terminate TLS at a reverse proxy (Nginx, Caddy, Traefik) in front of the Docker Compose stack. The Compose `nginx` service handles internal routing; expose only port 443 externally.

Caddy example (add to Caddyfile):

    docs.example.com {
        reverse_proxy localhost:80
    }

## Upgrade

    git pull origin main
    docker compose pull
    docker compose up -d
    docker compose exec app python manage.py migrate

## Backup

The full state lives in PostgreSQL and (if configured) S3/local storage.

    # Database
    docker compose exec postgres pg_dump -U docs docs > docs-backup-$(date +%F).sql

    # Local media files
    tar -czf docs-media-$(date +%F).tar.gz data/media/

## Gotchas

- **Yjs provider is required for real-time collaboration** — `y-provider` service must be running; without it, live cursor/presence features are disabled.
- **SECRET_KEY must be stable** — Changing it invalidates all existing sessions and tokens. Generate it once and store it securely.
- **ALLOWED_HOSTS** — Django will return 400 Bad Request for any hostname not listed in `DJANGO_ALLOWED_HOSTS`. Set it to your actual domain in production.
- **Early-stage project** — First public release was mid-2024. Actively developed; expect breaking changes between minor versions. Check the changelog before upgrading.
- **AI features require external config** — Optional AI helpers (rewrite, summarize) need an external LLM API endpoint configured; they are not bundled.
- **License**: MIT — permissive, fully open source.

## Links

- GitHub: https://github.com/suitenumerique/docs
- Website: https://docs.numerique.gouv.fr/
- Install docs: https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md
- Environment reference: https://github.com/suitenumerique/docs/blob/main/docs/env.md
- Dev setup: https://github.com/suitenumerique/docs/blob/main/docs/dev.md
