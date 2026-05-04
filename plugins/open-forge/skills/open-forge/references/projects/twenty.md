---
name: twenty-project
description: Twenty CRM recipe for open-forge. Open-source CRM. Docker Compose is the official self-hosting path. AGPL-3.0.
---

# Twenty

Open-source CRM built as a modern alternative to Salesforce. Docker Compose is the official self-hosting path. Architecture: a single `twentycrm/twenty` image runs both the API server and a separate worker process, backed by PostgreSQL 15 and Redis. Upstream: <https://github.com/twentyhq/twenty>. Site: <https://twenty.com>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.twenty.com/developers/self-host/capabilities/docker-compose> | ✅ | Recommended self-hosting path. Single `docker compose up -d` starts the full stack. |
| Kubernetes / Helm | <https://docs.twenty.com/developers/self-host> | ⚠️ Community | Community-maintained; not the primary upstream path. |
| Railway / Render | <https://docs.twenty.com/developers/self-host> | ⚠️ Third-party | One-click templates on PaaS platforms; verify at deploy time. |
| Twenty Cloud (managed) | <https://twenty.com/pricing> | ✅ | Out of scope for open-forge — hosted service. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| dns | "What is the public URL for this Twenty instance?" | Free-text URL (e.g. `https://crm.example.com`) | Sets `SERVER_URL` — must match exactly |
| secrets | "APP_SECRET value?" | Generate with `openssl rand -base64 32` or user-provided | JWT signing secret — must remain stable |
| storage | "Local storage or S3-compatible?" | `local` / `s3` | S3 requires additional vars |
| storage | "S3 bucket name, region, and endpoint?" | Free-text | Only if `STORAGE_TYPE=s3` |
| email | "Set up outbound email (SMTP)?" | `Yes` / `Skip` | Required for invites, notifications, password reset |
| email | "SMTP host, port, user, password, from address?" | Free-text | Only if email enabled |
| oauth | "Enable Google OAuth?" | `Yes` / `No` | Requires Google Cloud OAuth app |
| oauth | "Enable Microsoft OAuth?" | `Yes` / `No` | Requires Azure AD app registration |

## Software-layer concerns

### Docker Compose (upstream `packages/twenty-docker/docker-compose.yml`)

```yaml
name: twenty
services:
  server:
    image: twentycrm/twenty:${TAG:-latest}
    volumes:
      - server-local-data:/app/packages/twenty-server/.local-storage
    ports:
      - "3000:3000"
    environment:
      NODE_PORT: 3000
      PG_DATABASE_URL: postgres://postgres:postgres@db:5432/default
      SERVER_URL: ${SERVER_URL}
      REDIS_URL: redis://redis:6379
      APP_SECRET: ${APP_SECRET:-replace_me}
      STORAGE_TYPE: local
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: always

  worker:
    image: twentycrm/twenty:${TAG:-latest}
    command: ["yarn", "worker:prod"]
    environment:
      PG_DATABASE_URL: postgres://postgres:postgres@db:5432/default
      SERVER_URL: ${SERVER_URL}
      REDIS_URL: redis://redis:6379
      APP_SECRET: ${APP_SECRET:-replace_me}
      DISABLE_DB_MIGRATIONS: "true"
      DISABLE_CRON_JOBS_REGISTRATION: "true"
    depends_on:
      server:
        condition: service_healthy
    restart: always

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: default
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 20
    restart: always

  redis:
    image: redis
    restart: always

volumes:
  server-local-data:
  db-data:
```

### Environment variables

| Variable | Required | Description |
|---|---|---|
| `SERVER_URL` | ✅ | Public URL (e.g. `https://crm.example.com`) — used for OAuth callbacks and file URLs |
| `APP_SECRET` | ✅ | JWT signing secret. Generate: `openssl rand -base64 32`. **Never change after first run.** |
| `TAG` | Optional | Image tag to pin (default: `latest`) |
| `PG_DATABASE_URL` | ✅ | PostgreSQL connection string |
| `REDIS_URL` | ✅ | Redis connection string |
| `STORAGE_TYPE` | Optional | `local` (default) or `s3` |
| `STORAGE_S3_REGION` | S3 only | AWS region or custom |
| `STORAGE_S3_NAME` | S3 only | Bucket name |
| `STORAGE_S3_ENDPOINT` | S3 only | Custom endpoint for non-AWS S3 |
| `DISABLE_DB_MIGRATIONS` | Worker | Set `"true"` on the worker to prevent migration race with the server |
| `DISABLE_CRON_JOBS_REGISTRATION` | Worker | Set `"true"` on the worker |
| `EMAIL_DRIVER` | Optional | `smtp` to enable email |
| `EMAIL_SMTP_HOST` | SMTP | SMTP server hostname |
| `EMAIL_SMTP_PORT` | SMTP | SMTP port |
| `EMAIL_SMTP_USER` | SMTP | SMTP username |
| `EMAIL_SMTP_PASSWORD` | SMTP | SMTP password |
| `EMAIL_FROM_ADDRESS` | SMTP | From address |
| `AUTH_GOOGLE_CLIENT_ID` | OAuth | Google OAuth client ID |
| `AUTH_GOOGLE_CLIENT_SECRET` | OAuth | Google OAuth client secret |
| `AUTH_GOOGLE_CALLBACK_URL` | OAuth | `${SERVER_URL}/auth/google/callback` |
| `AUTH_MICROSOFT_CLIENT_ID` | OAuth | Microsoft OAuth client ID |
| `AUTH_MICROSOFT_CLIENT_SECRET` | OAuth | Microsoft OAuth client secret |
| `AUTH_MICROSOFT_CALLBACK_URL` | OAuth | `${SERVER_URL}/auth/microsoft/callback` |

### Config paths and data directories

| Path | Description |
|---|---|
| `server-local-data` volume | Uploaded file attachments (local storage mode) |
| `db-data` volume | PostgreSQL data directory — primary data store |
| Environment-only | No config files; all configuration is via environment variables |

### `.env` file (recommended for Compose)

```bash
# .env alongside docker-compose.yml
SERVER_URL=https://crm.example.com
APP_SECRET=<output of: openssl rand -base64 32>
TAG=latest
```

## Upgrade procedure

```bash
# Pull new images
docker compose pull

# Restart — server auto-runs DB migrations on startup
docker compose up -d
```

Monitor server logs during the upgrade to confirm migrations complete before the worker starts:

```bash
docker compose logs -f server
```

If the worker starts before migrations finish, it will fail and restart — this is handled by the `depends_on: service_healthy` check.

## Gotchas

- **`APP_SECRET` is write-once.** Changing it invalidates all existing user sessions and JWT tokens — every user will be logged out and any pending email verification links will break. Set it once and keep it.
- **`SERVER_URL` must match the exact public URL.** It is used to construct OAuth callback URLs and file download URLs. A mismatch causes OAuth flows to fail silently or files to 404.
- **Worker must have `DISABLE_DB_MIGRATIONS=true`.** If both server and worker run migrations simultaneously on startup, you risk a race condition that corrupts the migration state. The upstream compose file sets this correctly — do not remove it.
- **Back up `server-local-data` alongside PostgreSQL.** In local storage mode, uploaded attachments live in this volume. A database restore without the matching file volume leaves attachment records with broken links.
- **Default PostgreSQL credentials are not production-grade.** The upstream compose file uses `postgres`/`postgres`. Change `POSTGRES_USER`, `POSTGRES_PASSWORD`, and update `PG_DATABASE_URL` accordingly for production deployments.
- **Redis is not optional.** The worker and server use Redis for job queues and pub/sub. Removing Redis from the stack will break background job processing.

## Links

- GitHub: <https://github.com/twentyhq/twenty>
- Site: <https://twenty.com>
- Self-hosting docs: <https://docs.twenty.com/developers/self-host/capabilities/docker-compose>
- Environment variable reference: <https://docs.twenty.com/developers/self-host/environment-variables>
- License: AGPL-3.0
- Stars: ~25K
