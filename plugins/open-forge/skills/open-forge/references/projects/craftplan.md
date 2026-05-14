---
name: craftplan
description: Recipe for self-hosting Craftplan — an open-source ERP platform for small-scale artisanal manufacturers and craft businesses, covering catalog/BOM management, inventory, production planning, order processing, purchasing, and CRM.
---

# Craftplan

Open-source ERP for small-scale artisanal manufacturers and craft businesses. Covers product catalog with Bills of Materials (BOMs), inventory with lot traceability, production batching, order management with calendar scheduling, purchasing, and a CRM — all in one self-hosted Elixir/Phoenix (with Ash Framework) app. Upstream: <https://github.com/puemos/craftplan>. Docs: <https://puemos.github.io/craftplan/docs/>. License: AGPLv3.

Uses PostgreSQL for data and MinIO for file/image storage. Ships a ready-to-deploy `docker-compose.yml` that requires no repo clone.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Official method. PostgreSQL + MinIO bundled. |
| Cloud VM (e.g. Fly.io) | Fly.io deploy | Live demo runs on Fly; upstream has Fly config. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| secrets | "Generate `SECRET_KEY_BASE` (Phoenix secret, min 64 bytes): `openssl rand -base64 48`" | Required. |
| secrets | "Generate `TOKEN_SIGNING_SECRET`: `openssl rand -base64 48`" | Required. |
| secrets | "Generate `CLOAK_KEY` (32-byte AES key): `openssl rand -base64 32`" | Required — encrypts API keys at rest. |
| db | "PostgreSQL password for the bundled container?" | Used as `POSTGRES_PASSWORD`. |
| app | "Public hostname (e.g. `craftplan.example.com`)?" | Used as `HOST` env var. |
| app | "Port? (default: 4000)" | Used as `PORT` env var. |
| minio (optional) | "MinIO root user/password? (defaults: `minioadmin`/`minioadmin`)" | Used for `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`. Change from defaults in production. |
| smtp (optional) | "SMTP provider and credentials for transactional email?" | Supports SMTP, SendGrid, Mailgun, Postmark, Brevo, Amazon SES — configurable from the Settings UI after deploy. |

## Software-layer concerns

### Config paths
All config is via `.env` file (no config file on disk). Copy `.env.example` from upstream:

```bash
curl -O https://raw.githubusercontent.com/puemos/craftplan/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/puemos/craftplan/main/.env.example
cp .env.example .env
# Edit .env with required secrets
```

### Key env vars (in `.env`)

```
# Required secrets
SECRET_KEY_BASE=<openssl rand -base64 48>
TOKEN_SIGNING_SECRET=<openssl rand -base64 48>
CLOAK_KEY=<openssl rand -base64 32>
POSTGRES_PASSWORD=<your-db-password>

# Host & networking
HOST=localhost          # or your public domain
PORT=4000

# MinIO credentials (change from defaults in production)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
AWS_S3_BUCKET=craftplan
```

### Docker Compose (from upstream)

```yaml
services:
  craftplan:
    image: ghcr.io/puemos/craftplan:latest
    ports:
      - "${PORT:-4000}:${PORT:-4000}"
    env_file: .env
    environment:
      DATABASE_URL: "ecto://postgres:${POSTGRES_PASSWORD}@postgres/craftplan"
      AWS_S3_SCHEME: "http://"
      AWS_S3_HOST: minio
      AWS_ACCESS_KEY_ID: "${MINIO_ROOT_USER:-minioadmin}"
      AWS_SECRET_ACCESS_KEY: "${MINIO_ROOT_PASSWORD:-minioadmin}"
      AWS_S3_BUCKET: "${AWS_S3_BUCKET:-craftplan}"
      AWS_REGION: "us-east-1"
    depends_on:
      postgres:
        condition: service_healthy
      minio:
        condition: service_started
    restart: unless-stopped

  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: craftplan
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  minio:
    image: minio/minio:latest
    entrypoint: sh
    command: -c 'mkdir -p /data/craftplan && /usr/bin/minio server /data --console-address ":9001"'
    environment:
      MINIO_ROOT_USER: "${MINIO_ROOT_USER:-minioadmin}"
      MINIO_ROOT_PASSWORD: "${MINIO_ROOT_PASSWORD:-minioadmin}"
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  minio_data:
```

### Ports
- 4000/tcp — Craftplan web UI (configurable via `PORT`)
- 9000/tcp — MinIO S3 API
- 9001/tcp — MinIO web console

### API access
Craftplan exposes both JSON:API and GraphQL endpoints. Authentication uses API keys (encrypted at rest with `CLOAK_KEY`). Generate API keys from the Settings page.

### Calendar feed
An iCal `.ics` feed is available for order deliveries and production schedules. Subscribe URL is generated and revocable from Settings. Compatible with Google Calendar, Apple Calendar, and any iCal client.

## Upgrade procedure

```bash
docker compose pull craftplan
docker compose up -d craftplan
```

Check release notes at: <https://github.com/puemos/craftplan/releases>

## Gotchas

- **All three secrets are required** — `SECRET_KEY_BASE`, `TOKEN_SIGNING_SECRET`, and `CLOAK_KEY` must be set before first start; the app will refuse to start without them.
- **Change MinIO defaults in production** — The default `minioadmin`/`minioadmin` credentials are fine for local dev but must be changed for any internet-facing deployment.
- **SMTP is configured from the UI** — Unlike most apps, email provider setup is done in the Craftplan Settings page (not env vars). Supported: SMTP, SendGrid, Mailgun, Postmark, Brevo, Amazon SES. API keys are encrypted at rest using `CLOAK_KEY`.
- **PostgreSQL 16 required** — The bundled compose uses `postgres:16`. If using an external database, ensure version compatibility.
- **BOM versioning** — Bills of Materials are versioned; only the latest version is editable. Older versions are read-only — plan schema changes accordingly.
- **CSV import format** — Bulk import is available for products, materials, and customers via CSV. Check the Settings → Import page for the expected column format before preparing data.

## References
- Upstream README: <https://github.com/puemos/craftplan#readme>
- Docs: <https://puemos.github.io/craftplan/docs/>
- Self-hosting guide: <https://puemos.github.io/craftplan/docs/self-hosting/>
- API reference: <https://puemos.github.io/craftplan/docs/api/>
- Live demo: <https://craftplan.fly.dev> (credentials: `test@test.com` / `Aa123123123123`)
- Release notes: <https://github.com/puemos/craftplan/releases>
