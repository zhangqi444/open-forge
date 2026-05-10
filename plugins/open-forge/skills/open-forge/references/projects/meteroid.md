---
name: meteroid
description: Recipe for self-hosting Meteroid, an open-source pricing and billing infrastructure for SaaS — subscription management, usage-based billing, invoicing, and revenue analytics. Based on upstream documentation at https://github.com/meteroid-oss/meteroid.
---

# Meteroid

Open-source pricing and billing infrastructure for product-led SaaS. Handles subscription management, usage-based billing, invoicing, cost limiting, grandfathering, experiments, and revenue analytics. Upstream: <https://github.com/meteroid-oss/meteroid>. Stars: 1k+. License: AGPL v3.

Self-host via Docker Compose (development/testing) or Kubernetes Helm chart (production).

**Status note:** The README marks this as "experimental" — suitable for testing and early production. Check the upstream Discord for stability guidance before deploying to production billing.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Provided in docker/deploy/ — minimal setup for testing |
| Kubernetes | Helm chart | See k8s/meteroid/ in upstream repo |

## Service architecture

Meteroid is a multi-service stack:

| Service | Image | Port | Role |
|---|---|---|---|
| meteroid-db | meteroid-postgres (PostgreSQL) | 5432 | Primary database |
| clickhouse | clickhouse-server | 8123, 9000 | Analytics / metering data |
| redpanda | redpanda (Kafka-compatible) | 9092 | Event streaming |
| meteroid-api | meteroid-api | 8084 (REST), 50061 (gRPC) | Core billing API |
| meteroid-scheduler | meteroid-scheduler | — | Async billing jobs |
| metering-api | metering-api | 50062 (gRPC) | Usage event ingestion |
| meteroid-web | meteroid-web | 3000 | Web UI |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | JWT_SECRET | Secure random string |
| required | INTERNAL_API_SECRET | Secure random string |
| required | SECRETS_CRYPT_KEY | Exactly 32 characters |
| required | DATABASE_PASSWORD | PostgreSQL password |
| optional | VITE_METEROID_API_EXTERNAL_URL | Public gRPC API URL (default: http://localhost:50061) |
| optional | VITE_METEROID_REST_API_EXTERNAL_URL | Public REST API URL (default: http://localhost:8084) |
| optional | METEROID_PUBLIC_URL | Public web UI URL (default: http://localhost:3000) |
| optional | Object store | Default: local filesystem volume; can use S3-compatible |

## Docker Compose deployment

```bash
# 1. Clone the repo
git clone https://github.com/meteroid-oss/meteroid.git
cd meteroid/docker/deploy

# 2. Configure environment
cp .env.example .env
# Edit .env: set JWT_SECRET, INTERNAL_API_SECRET, SECRETS_CRYPT_KEY (32 chars), DATABASE_PASSWORD

# 3. Start the stack
docker compose up -d

# 4. Check all services are healthy
docker compose ps
```

Web UI: http://localhost:3000
REST API: http://localhost:8084
gRPC API: http://localhost:50061

## Environment variables (.env)

```bash
## Required secrets (change all of these!)
JWT_SECRET=changeMeToASecureRandomString
INTERNAL_API_SECRET=changeMeToASecureRandomString
SECRETS_CRYPT_KEY=00000000000000000000000000000000  # must be exactly 32 chars

## Database
DATABASE_USER=meteroid
DATABASE_PASSWORD=changeMeToASecurePassword
DATABASE_NAME=meteroid

## ClickHouse
CLICKHOUSE_DATABASE=meteroid
CLICKHOUSE_USERNAME=default
CLICKHOUSE_PASSWORD=default

## Public URLs (update if deploying behind a reverse proxy/domain)
VITE_METEROID_API_EXTERNAL_URL=http://localhost:50061
VITE_METEROID_REST_API_EXTERNAL_URL=http://localhost:8084
METEROID_PUBLIC_URL=http://localhost:3000

## Multi-organization mode
ENABLE_MULTI_ORGANIZATION=false
```

## Data directories

| Volume | Contents |
|---|---|
| pg_data | PostgreSQL database files |
| clickhouse_data | ClickHouse analytics data |
| redpanda_data | Kafka/Redpanda event log |
| object_store_data | Object storage (invoices, exports) |

## Upgrade procedure

```bash
cd meteroid/docker/deploy
git pull
docker compose pull
docker compose up -d
```

Upgrades may include database migrations run automatically on meteroid-api startup — check logs with `docker compose logs meteroid-api` after upgrading.

## Gotchas

- SECRETS_CRYPT_KEY must be exactly 32 characters — startup will fail otherwise.
- The stack is resource-intensive: PostgreSQL + ClickHouse + Redpanda require several GB of RAM. Not suitable for low-memory homelabs.
- In development mode (the provided Compose file), PostgreSQL port 5432 is exposed to the host — restrict this in production or use a firewall rule.
- Multi-organization mode is disabled by default; enable with `ENABLE_MULTI_ORGANIZATION=true` for SaaS deployments serving multiple tenants.
- The project is marked "experimental" upstream — check the Discord before deploying to production billing.
- For S3-compatible object storage instead of local filesystem, set `OBJECT_STORE_URI=s3://meteroid` with `AWS_ENDPOINT`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

## Upstream docs

- README: https://github.com/meteroid-oss/meteroid/blob/main/README.md
- Docker Compose: https://github.com/meteroid-oss/meteroid/tree/main/docker/deploy
- Helm chart: https://github.com/meteroid-oss/meteroid/tree/main/k8s/meteroid
- Discord: https://go.meteroid.com/discord
