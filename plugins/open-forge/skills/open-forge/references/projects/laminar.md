---
name: laminar
description: Laminar (lmnr) is an open-source AI observability platform purpose-built for AI agents — OpenTelemetry-native tracing, evals, AI monitoring with natural-language event definitions, dashboards, SQL access to all data, and data annotation. Rust backend + Next.js frontend + ClickHouse + PostgreSQL. Upstream: https://github.com/lmnr-ai/lmnr
---

# Laminar

Laminar (package name: `lmnr`) is an **open-source observability platform for AI agents and LLM applications**. It provides OpenTelemetry-native tracing with automatic instrumentation for major LLM SDKs (Vercel AI SDK, OpenAI, Anthropic, Gemini, LangChain, Browser Use, Stagehand), evaluations, AI monitoring via natural-language event definitions, dashboards, and a built-in SQL editor — all self-hostable via Docker Compose.

Upstream: <https://github.com/lmnr-ai/lmnr>  
Docs: <https://laminar.sh/docs>  
Managed cloud: <https://laminar.sh>  
License: Apache-2.0

## What it does

- **OpenTelemetry-native tracing** — 1 line of code to auto-trace Vercel AI SDK, OpenAI, Anthropic, Gemini, LangChain, Browser Use, Stagehand, and more; custom spans via `observe()`/`@observe()`
- **Real-time trace viewer** — custom Rust-based realtime engine streams traces as they happen
- **Evaluations** — run evals locally or in CI/CD via SDK + CLI; visualise and compare results in the UI
- **AI monitoring / Signals** — define monitoring events with natural language descriptions to track agent issues, logical errors, and custom behaviour
- **Dashboards** — custom dashboard builder with support for SQL queries over traces, metrics, and events
- **SQL editor** — full SQL access to all trace/metric/event data; bulk create datasets from queries
- **Data annotation and datasets** — custom rendering UI for fast data labelling and dataset creation
- **Full-text search** — ultra-fast search over span data via Quickwit
- **Python + TypeScript SDKs**

## Architecture

- **Rust backend** (`app-server`) — high-performance trace ingestion and API; gRPC + REST
- **Next.js frontend** — dashboard UI on port `5667`
- **PostgreSQL 16** — primary relational store
- **ClickHouse** — analytics store for spans and events
- **Quickwit** — full-text search over span data (OTLP/gRPC on port `7281`)
- **Query engine** — dedicated service for SQL editor queries
- **Lightweight compose** (`docker-compose.yml`) — omits RabbitMQ; suitable for local quickstart
- **Full compose** (`docker-compose-full.yml`) — includes RabbitMQ; recommended for production

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (lightweight) | Quickstart. No RabbitMQ. |
| Any Linux host | Docker Compose (full) | Production. Includes RabbitMQ for background job queues. |
| Managed cloud | laminar.sh | SaaS; no self-host required. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Data path for persistent volumes?" | e.g. `/opt/laminar`. Volumes: `postgres-data`, `clickhouse-data`, `quickwit-data`. |
| env | "Postgres credentials?" | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`. |
| env | "ClickHouse credentials?" | `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD`, `CLICKHOUSE_RO_USER`, `CLICKHOUSE_RO_PASSWORD`. |
| env | "Shared secret token?" | `SHARED_SECRET_TOKEN` — used between services; generate with `openssl rand -hex 32`. |
| env | "AEAD encryption key?" | `AEAD_SECRET_KEY` — generate with `openssl rand -hex 32`. |
| optional | "OpenAI API key?" | `OPENAI_API_KEY` — optional; used by some eval features. |
| optional | "Google Generative AI API key?" | `GOOGLE_GENERATIVE_AI_API_KEY` — required for Signals / AI monitoring feature. |

## Quick start

```bash
# Clone the repo (needed for docker-compose.yml + config files)
git clone https://github.com/lmnr-ai/lmnr
cd lmnr

# Copy and fill in environment variables
cp .env.example .env
# Edit .env — set POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB,
#              CLICKHOUSE_USER, CLICKHOUSE_PASSWORD, CLICKHOUSE_RO_USER, CLICKHOUSE_RO_PASSWORD,
#              SHARED_SECRET_TOKEN, AEAD_SECRET_KEY

# Start (lightweight — no RabbitMQ)
docker compose up -d
```

Access the dashboard at `http://localhost:5667`.

For production with RabbitMQ:

```bash
docker compose -f docker-compose-full.yml up -d
```

## Environment variables reference

| Variable | Required | Description |
|---|---|---|
| `POSTGRES_USER` | ✅ | PostgreSQL username |
| `POSTGRES_PASSWORD` | ✅ | PostgreSQL password |
| `POSTGRES_DB` | ✅ | PostgreSQL database name |
| `CLICKHOUSE_USER` | ✅ | ClickHouse username |
| `CLICKHOUSE_PASSWORD` | ✅ | ClickHouse password |
| `CLICKHOUSE_RO_USER` | ✅ | ClickHouse read-only username |
| `CLICKHOUSE_RO_PASSWORD` | ✅ | ClickHouse read-only password |
| `SHARED_SECRET_TOKEN` | ✅ | Inter-service auth token (generate with `openssl rand -hex 32`) |
| `AEAD_SECRET_KEY` | ✅ | AEAD encryption key (generate with `openssl rand -hex 32`) |
| `OPENAI_API_KEY` | ➖ | Optional; enables OpenAI-backed eval features |
| `GOOGLE_GENERATIVE_AI_API_KEY` | ➖ | Required for Signals / AI monitoring feature |
| `APP_SERVER_HOST_PORT` | ➖ | Host port for app-server REST API (default `8000`) |
| `APP_SERVER_GRPC_HOST_PORT` | ➖ | Host port for app-server gRPC (default `8001`) |
| `QUERY_ENGINE_HOST_PORT` | ➖ | Host port for query engine (default `8903`) |

## SDK quickstart

### TypeScript

```bash
npm add @lmnr-ai/lmnr
```

```typescript
import { Laminar } from '@lmnr-ai/lmnr';

Laminar.initialize({
  projectApiKey: process.env.LMNR_PROJECT_API_KEY,
  baseUrl: 'http://localhost',    // self-hosted URL
  // httpPort: 5667,              // frontend port (for API key creation)
  // grpcPort: 8001,              // gRPC ingest port
});
```

### Python

```bash
pip install 'lmnr[all]'
```

```python
from lmnr import Laminar

Laminar.initialize(
    project_api_key="<LMNR_PROJECT_API_KEY>",
    base_url="http://localhost",   # self-hosted URL
)
```

See the [self-hosting guide](https://laminar.sh/docs/hosting-options#self-hosted-docker-compose) for SDK port configuration details.

## Service ports

| Service | Default host port | Description |
|---|---|---|
| Frontend (Next.js) | `5667` | Dashboard UI + API key management |
| app-server (REST) | `8000` | Trace ingestion REST API |
| app-server (gRPC) | `8001` | Trace ingestion gRPC (used by SDKs) |
| app-server (RT) | `8002` | Realtime trace streaming |
| PostgreSQL | `5433` | DB (mapped to non-default host port to avoid conflicts) |
| Quickwit REST | `7280` | Search REST API + UI |
| Quickwit gRPC/OTLP | `7281` | OTLP span ingestion |
| Query engine | `8903` | SQL editor backend |

## Enabling Signals (AI monitoring)

Set `GOOGLE_GENERATIVE_AI_API_KEY` in `.env` before starting (or restart after adding it):

```bash
# In .env
GOOGLE_GENERATIVE_AI_API_KEY=your_key_here
```

Both `app-server` and the `frontend` services consume this key.

## Upgrade

```bash
cd lmnr
git pull
docker compose pull
docker compose up -d
```

## Backup

Back up the named Docker volumes:

```bash
# PostgreSQL
docker exec lmnr-postgres-1 pg_dumpall -U "$POSTGRES_USER" > laminar-postgres-$(date +%Y%m%d).sql

# ClickHouse (backup tool or volume snapshot)
# For the quickwit-data and clickhouse-data volumes, use docker volume backup or host-level snapshots
```

## Gotchas

- **Repo clone required** — unlike single-image deploys, Laminar's `docker-compose.yml` references a bind-mounted `clickhouse-profiles-config.xml` file from the repo root. Run from the cloned directory, not from a standalone `docker-compose.yml`.
- **ClickHouse version pin** — the compose file notes that ClickHouse 26.3 breaks queries on the `spans_v0` view (known bug); the image is pinned to `latest` with a comment to update once fixed. Check the upstream repo before upgrading ClickHouse independently.
- **PostgreSQL mapped to port 5433** — the host port is `5433` (not `5432`) to avoid collisions with a locally-installed PostgreSQL instance.
- **Lightweight vs full compose** — the lightweight `docker-compose.yml` disables RabbitMQ-dependent features (`ENVIRONMENT: LITE`). For full background job processing, use `docker-compose-full.yml`.
- **SDK `baseUrl` configuration for self-hosted** — SDKs default to `laminar.sh` cloud. When self-hosting, set `baseUrl` to the host and configure `httpPort`/`grpcPort` to point at your instance. See the [self-hosting SDK guide](https://laminar.sh/docs/hosting-options#self-hosted-docker-compose).
- **First project and API key** — create a project via the dashboard (`http://localhost:5667/projects`) and generate a project API key to use with the SDK.
