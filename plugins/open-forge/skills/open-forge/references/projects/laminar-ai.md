---
name: laminar-ai
description: Recipe for self-hosting Laminar (lmnr), an open-source observability platform for AI agents — tracing, evals, AI monitoring, dashboards, and SQL access over agent execution data. Based on upstream documentation at https://github.com/lmnr-ai/lmnr.
---

# Laminar (lmnr)

Open-source observability platform built for AI agents. Provides OpenTelemetry-native tracing, evaluations, AI monitoring (Signals), custom dashboards, SQL editor, and data annotation — purpose-built for LLM-based applications. Written in Rust for high performance. Upstream: <https://github.com/lmnr-ai/lmnr>. Docs: <https://laminar.sh/docs>. Stars: 2.9k+. License: Apache-2.0.

Automatically instruments Vercel AI SDK, LangChain, OpenAI, Anthropic, Gemini, Browser Use, Stagehand, and more via 1-line SDK integration.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (lightweight) | Quickstart; omits RabbitMQ; suitable for local/moderate use |
| Any Linux host | Docker Compose (full) | Production; includes RabbitMQ for high-throughput ingestion |

## Service architecture (lightweight stack)

| Service | Image | Port | Role |
|---|---|---|---|
| postgres | postgres:16 | 5433 (host) | Primary metadata database |
| clickhouse | clickhouse-server | — (internal) | Trace/span analytics storage |
| query-engine | lmnr-ai/query-engine | 8903 | SQL query engine |
| app-server | lmnr-ai/app-server | 8000 (REST), 8001 (gRPC), 8002 (RT) | Core API server |
| frontend | lmnr-ai/frontend | 5667 | Web UI |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | POSTGRES_PASSWORD | PostgreSQL password (change from default) |
| required | AEAD_SECRET_KEY | Exactly 64 hex characters (32 bytes) for encryption |
| required | NEXTAUTH_SECRET | Any random string for session signing |
| required | SHARED_SECRET_TOKEN | Internal service auth token |
| optional | GOOGLE_GENERATIVE_AI_API_KEY | Required to enable Signals / AI monitoring feature |

## Docker Compose deployment

```bash
git clone https://github.com/lmnr-ai/lmnr
cd lmnr

# The repo ships a default .env — edit it before starting
# nano .env   # Update passwords, AEAD_SECRET_KEY, NEXTAUTH_SECRET

# Lightweight stack (quickstart)
docker compose up -d

# Full production stack (includes RabbitMQ)
docker compose -f docker-compose-full.yml up -d
```

Web UI: http://localhost:5667

## .env reference

```bash
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres_passwordabc   # CHANGE THIS
POSTGRES_DB=postgres
POSTGRES_PORT=5433

# Internal auth
SHARED_SECRET_TOKEN=some_secret          # CHANGE THIS

# ClickHouse
CLICKHOUSE_USER=ch_user
CLICKHOUSE_RO_USER=ch_user
CLICKHOUSE_PASSWORD=ch_passwd            # CHANGE THIS
CLICKHOUSE_RO_PASSWORD=ch_passwd

# Encryption (must be exactly 64 hex chars = 32 bytes)
AEAD_SECRET_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  # CHANGE THIS

# NextAuth session secret
NEXTAUTH_SECRET=0123456789abcdef0123456789abcdef  # CHANGE THIS

# Optional: enable Signals / AI monitoring feature
# GOOGLE_GENERATIVE_AI_API_KEY=your-key-here

# RabbitMQ (full stack only)
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=adminpasswd        # CHANGE THIS
```

## SDK integration (after deployment)

```python
# Python
pip install lmnr
from lmnr import Laminar
Laminar.initialize(project_api_key="...", base_url="http://your-server:8000")

# TypeScript
npm add @lmnr-ai/lmnr
import { Laminar } from '@lmnr-ai/lmnr';
Laminar.initialize({ projectApiKey: '...', baseUrl: 'http://your-server:8000' });
```

Create a project and generate an API key from the web UI at http://localhost:5667.

## Ports reference

| Port | Service | Protocol |
|---|---|---|
| 5667 | Frontend (web UI) | HTTP |
| 8000 | app-server REST API | HTTP |
| 8001 | app-server gRPC | gRPC |
| 7280 | app-server UI + REST | HTTP |
| 7281 | OTLP / gRPC ingest | gRPC |
| 5433 | PostgreSQL | TCP |
| 8903 | Query engine | HTTP |

## Upgrade procedure

```bash
cd lmnr
git pull
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Gotchas

- **The repo ships a default `.env` with weak placeholder secrets** — change `POSTGRES_PASSWORD`, `AEAD_SECRET_KEY`, `NEXTAUTH_SECRET`, and `SHARED_SECRET_TOKEN` before exposing to any network.
- `AEAD_SECRET_KEY` must be exactly 64 hex characters (32 bytes). Generating: `openssl rand -hex 32`.
- The lightweight Compose file sets `ENVIRONMENT: LITE` on the frontend — this disables some runtime dependencies. Use `docker-compose-full.yml` for full production feature parity.
- Signals / AI monitoring requires `GOOGLE_GENERATIVE_AI_API_KEY` in `.env` — without it, the Signals panel is non-functional.
- PostgreSQL is exposed on host port 5433 (not the default 5432) to avoid conflicts with a locally running Postgres.
- The `NEXTAUTH_SECRET` in the default .env is a placeholder (`0123...`) — replace it with a strong random value.

## Upstream docs

- README: https://github.com/lmnr-ai/lmnr/blob/main/README.md
- Self-hosting guide: https://laminar.sh/docs/hosting-options#self-hosted-docker-compose
- SDK docs: https://laminar.sh/docs/tracing/introduction
