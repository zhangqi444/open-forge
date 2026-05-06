---
name: svix
description: Svix recipe for open-forge. Enterprise-ready self-hosted webhook delivery service with retries, signatures, and a dashboard. Source: https://github.com/svix/svix-webhooks. Website: https://svix.com.
---

# Svix

Enterprise-ready webhook delivery service — self-hosted via Docker Compose or used as a managed cloud service. Handles webhook fan-out, delivery retries, HMAC-SHA256 signatures, event types, endpoint management, and an optional dashboard UI. Provides official SDKs for Python, JavaScript/TypeScript, Go, Java, Kotlin, Ruby, PHP, Rust, and C#. License: MIT. Upstream: <https://github.com/svix/svix-webhooks>. Website: <https://svix.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Primary method — includes Postgres, pgbouncer, Redis |
| Kubernetes | Helm | Official Helm chart available |
| Cloud managed | Svix Cloud | SaaS option; same API, no infra to manage |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| jwt_secret | "JWT secret for API authentication?" | Generate with `openssl rand -hex 32`; REQUIRED |
| port | "Port to expose Svix server on?" | Default: 8071 |
| db_password | "PostgreSQL password?" | Default in compose: postgres |
| org_id | "Default organization ID?" | Used when creating the first auth token |

## Software-layer concerns

- **Requires PostgreSQL + pgbouncer + Redis** — all included in the official docker-compose.yml
- Server image: `svix/svix-server` (Docker Hub)
- Config via environment variables — key ones:
  - `SVIX_JWT_SECRET` — **must be set**; used to sign API tokens
  - `SVIX_DB_DSN` — PostgreSQL connection string (via pgbouncer)
  - `SVIX_REDIS_DSN` — Redis connection string
  - `SVIX_QUEUE_TYPE` — queue backend (`redis` or `memory`; use redis for production)
  - `SVIX_CACHE_TYPE` — cache backend (`redis` or `memory`)
- Default API port: 8071
- Dashboard UI available at `http://host:8071/app/` (optional, enabled by default)
- Webhooks are delivered with HMAC-SHA256 signatures in the `svix-signature` header
- All data (events, endpoints, deliveries) stored in PostgreSQL

### Docker Compose (from official template)

```bash
# Use the official docker-compose.yml from the repo
curl -O https://raw.githubusercontent.com/svix/svix-webhooks/main/server/docker-compose.yml
# Edit: uncomment and set SVIX_JWT_SECRET
docker compose up -d
```

### docker-compose.yml (key sections)

```yaml
services:
  backend:
    image: svix/svix-server
    restart: unless-stopped
    environment:
      WAIT_FOR: "true"
      SVIX_REDIS_DSN: "redis://redis:6379"
      SVIX_DB_DSN: "postgresql://postgres:postgres@pgbouncer/postgres"
      SVIX_JWT_SECRET: "changeme_use_openssl_rand_hex_32"   # REQUIRED
    ports:
      - "8071:8071"
    depends_on:
      pgbouncer:
        condition: service_healthy
      redis:
        condition: service_healthy

  postgres:
    image: postgres:13.4
    environment:
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data/

  pgbouncer:
    image: edoburu/pgbouncer:1.15.0
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      MAX_CLIENT_CONN: 500
    depends_on:
      postgres:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    command: redis-server --save 60 1 --loglevel warning

volumes:
  postgres-data:
  redis-data:
```

### Generate an API authentication token

```bash
# After stack is running, create a token for your org
docker exec -it <backend_container> svix-server generate-token

# Or via API (once JWT_SECRET is set, sign a JWT with org_id claim)
# See: https://docs.svix.com/server-self-hosting#authentication
```

### Send a test webhook via API

```bash
# Create an application
curl -X POST http://localhost:8071/api/v1/app/ \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"name": "My App", "uid": "my-app"}'

# Add an endpoint
curl -X POST http://localhost:8071/api/v1/app/my-app/endpoint/ \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/webhook", "version": 1}'

# Send a message (webhook event)
curl -X POST http://localhost:8071/api/v1/app/my-app/msg/ \
  -H "Authorization: Bearer <your_token>" \
  -H "Content-Type: application/json" \
  -d '{"eventType": "user.signup", "payload": {"userId": "123"}}'
```

## Upgrade procedure

1. `docker compose pull && docker compose up -d`
2. The server runs database migrations automatically on startup
3. Check release notes for any breaking API changes: https://github.com/svix/svix-webhooks/releases

## Gotchas

- **`SVIX_JWT_SECRET` is mandatory**: The server will start but all API calls will fail with auth errors if this is not set. Set it before first startup.
- **pgbouncer is not optional**: The official compose uses pgbouncer as a connection pooler between the Svix server and PostgreSQL. Do not remove it — the server assumes a connection-pooled path.
- **Token generation**: Svix uses JWT tokens signed with `SVIX_JWT_SECRET`. Tokens must include the `org_id` claim. Use `svix-server generate-token` inside the container to create tokens easily.
- **Webhook signature verification**: Recipients should verify the `svix-signature` header on inbound webhooks. Use the official Svix SDKs for the simplest implementation: `wh.verify(payload, headers)`.
- **Retry behavior**: Failed webhook deliveries are retried with exponential backoff for up to 5 days. Monitor the dashboard or API for stuck deliveries.
- **Redis persistence**: The default Redis config in the compose file enables AOF persistence (`--save 60 1`). For production, ensure the `redis-data` volume is backed up.

## Links

- Upstream repo: https://github.com/svix/svix-webhooks
- Website: https://svix.com
- Documentation: https://docs.svix.com
- Self-hosting guide: https://docs.svix.com/server-self-hosting
- Docker Hub: https://hub.docker.com/r/svix/svix-server
- API reference: https://api.svix.com
- Release notes: https://github.com/svix/svix-webhooks/releases
