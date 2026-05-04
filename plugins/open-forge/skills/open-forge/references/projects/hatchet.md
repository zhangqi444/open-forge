---
name: hatchet-project
description: Hatchet recipe for open-forge. Workflow orchestration for background tasks, AI agents, and durable workflows. Docker Compose self-hosting. MIT.
---

# Hatchet

Workflow orchestration engine for background tasks, AI agent pipelines, and durable workflows. SDKs for Python, TypeScript, Go, and Ruby. Self-hosting via Docker Compose or the Hatchet CLI. The Docker stack runs the platform (database, message broker, API, engine, dashboard); your application code runs workers separately using the SDK. Upstream: <https://github.com/hatchet-dev/hatchet>. Docs: <https://docs.hatchet.run>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.hatchet.run/self-hosting> | ✅ | Primary self-hosting path. Runs the full platform stack. |
| Hatchet CLI | <https://docs.hatchet.run/self-hosting> | ✅ | Quickstart wrapper around Docker Compose: `curl -fsSL https://install.hatchet.run/install.sh \| bash && hatchet server start`. |
| Kubernetes / Helm | <https://docs.hatchet.run/self-hosting> | ⚠️ | Check upstream docs for current Helm support status. |
| Hatchet Cloud (managed) | <https://hatchet.run> | ✅ | Out of scope for open-forge — hosted service. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Does the `hatchet_rabbitmq.conf` config file exist on the host before first start?" | Confirm / create | RabbitMQ bind-mount must exist before `docker compose up` |
| secrets | "Generate a random `SERVER_SECRET_KEY` and `ENCRYPTION_MASTER_KEYSET`?" | Auto-generate via `openssl rand -hex 32` | Hatchet API and encryption config |
| sdk | "Which SDK language?" | `Python` / `TypeScript` / `Go` / `Ruby` | Points to correct SDK docs for worker setup |
| workers | "Where will workers run (same host, separate VM, Kubernetes pod)?" | Free-text | Workers are NOT part of the Docker stack |

## Software-layer concerns

### Architecture

```
┌─────────────────────────────────────────────────┐
│  Docker Compose stack (platform)                │
│                                                  │
│  postgres ──► pgbouncer ──► hatchet-engine      │
│                         └──► hatchet-api        │
│  rabbitmq ──────────────────► hatchet-engine    │
│  hatchet-frontend (dashboard UI)                │
└─────────────────────────────────────────────────┘
        ▲
        │  SDK connects to API
        │
┌───────┴──────────────────────────────────────────┐
│  Your application (workers) — NOT in compose    │
│  Python / TypeScript / Go / Ruby SDK            │
└─────────────────────────────────────────────────┘
```

Workers run in **your application** using the SDK. The Docker Compose stack provides the orchestration platform only.

### Docker Compose (infrastructure services excerpt)

```yaml
services:
  postgres:
    image: postgres:15.6
    command: postgres -c 'max_connections=500'
    environment:
      POSTGRES_USER: hatchet
      POSTGRES_PASSWORD: hatchet
      POSTGRES_DB: hatchet
    ports:
      - "5431:5432"
    volumes:
      - hatchet_postgres_data:/var/lib/postgresql/data
    shm_size: 4g

  pgbouncer:
    image: edoburu/pgbouncer:v1.25.1-p0
    environment:
      DATABASE_URL: postgres://hatchet:hatchet@postgres:5432/hatchet
      POOL_MODE: transaction
      MAX_CLIENT_CONN: 1000
      DEFAULT_POOL_SIZE: 50
      AUTH_TYPE: plain
      LISTEN_PORT: 6432
    ports:
      - "6431:6432"
    depends_on:
      - postgres

  rabbitmq:
    image: rabbitmq:4-management
    hostname: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: user
      RABBITMQ_DEFAULT_PASS: password
    volumes:
      - hatchet_rabbitmq_data:/var/lib/rabbitmq
      - hatchet_rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf

  # hatchet-engine, hatchet-api, hatchet-frontend also run in full stack
  # see: https://docs.hatchet.run/self-hosting

volumes:
  hatchet_postgres_data:
  hatchet_rabbitmq_data:
  hatchet_rabbitmq.conf:
```

Full compose file (including `hatchet-engine`, `hatchet-api`, `hatchet-frontend`): <https://docs.hatchet.run/self-hosting>

### Ports

| Port | Service | Purpose |
|---|---|---|
| 5431 | postgres (host) | Direct PostgreSQL — use for advisory locks / LISTEN/NOTIFY |
| 6431 | pgbouncer (host) | Pooled PostgreSQL — use for normal application queries |
| 5672 | rabbitmq | AMQP |
| 15672 | rabbitmq | Management UI |
| 8080 | hatchet-api | API and dashboard (default; verify in your compose file) |

### Key environment variables (hatchet-api / hatchet-engine)

| Variable | Description |
|---|---|
| `SERVER_SECRET_KEY` | Secret key for the Hatchet API server |
| `DATABASE_URL` | PostgreSQL connection string (via pgbouncer: `postgres://hatchet:hatchet@pgbouncer:6432/hatchet`) |
| `RABBITMQ_DEFAULT_URL` | RabbitMQ AMQP URL |
| `ENCRYPTION_MASTER_KEYSET` | Encryption keyset for sensitive workflow data |

### Data directories

| Volume | Contents |
|---|---|
| `hatchet_postgres_data` | All workflow state, run history, tenant data |
| `hatchet_rabbitmq_data` | RabbitMQ message and queue persistence |
| `hatchet_rabbitmq.conf` | RabbitMQ config file bind-mount (must exist before first start) |

### RabbitMQ config file

The `hatchet_rabbitmq.conf` volume is a **bind-mount to a file** (not a named volume for a directory). Create a minimal config file before first `docker compose up`:

```bash
touch ./rabbitmq.conf
# Or create a minimal config:
cat > ./rabbitmq.conf << 'EOF'
# Hatchet RabbitMQ config
loopback_users.guest = false
EOF
```

Then in your compose file ensure the volume maps to this file:

```yaml
volumes:
  - ./rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Hatchet runs database migrations automatically on engine startup. Check engine logs to confirm migrations complete:

```bash
docker compose logs -f hatchet-engine
```

## Gotchas

- **Workers are NOT part of the Docker Compose stack.** The compose stack runs the Hatchet platform (API, engine, database, message broker, dashboard). Your application code — which defines and runs workflow workers — runs separately using the SDK and connects to the API. New users frequently expect the compose stack alone to run workflows.
- **RabbitMQ config file must exist before first start.** The `hatchet_rabbitmq.conf` volume entry in the compose file is a file bind-mount. If the file does not exist when `docker compose up` is run, Docker creates a *directory* at that path instead, causing RabbitMQ to fail with a config error. Create the file (even empty) before first start.
- **pgbouncer runs in transaction mode — do not use advisory locks or LISTEN/NOTIFY through it.** Transaction-mode pooling breaks PostgreSQL advisory locks and `LISTEN/NOTIFY` because they require a persistent connection. For those operations, connect directly to PostgreSQL on port 5431, bypassing pgbouncer.
- **`shm_size: 4g` on PostgreSQL is intentional.** Hatchet uses this for query plan analysis via `auto_explain`. On memory-constrained hosts, reduce or remove this setting — it does not allocate 4 GB upfront, but the limit may need adjustment for your environment.
- **Change default RabbitMQ credentials.** The compose example uses `user`/`password` for RabbitMQ. Replace these with strong credentials and update any Hatchet service configs that reference the AMQP URL.
- **Change default PostgreSQL credentials.** The compose example uses `hatchet`/`hatchet`. Change these in production and update all connection strings accordingly.

## Links

- GitHub: <https://github.com/hatchet-dev/hatchet>
- Docs: <https://docs.hatchet.run>
- Self-hosting docs: <https://docs.hatchet.run/self-hosting>
- Python SDK: <https://github.com/hatchet-dev/hatchet-python>
- TypeScript SDK: <https://github.com/hatchet-dev/hatchet-typescript>
- Go SDK: <https://github.com/hatchet-dev/hatchet-go>
- License: MIT
- Stars: ~5K
