---
name: bricksllm
description: "Enterprise-grade LLM API gateway. MIT. bricks-cloud. Docker Compose + PostgreSQL + Redis. Per-key rate limiting, cost controls, spend analytics, PII detection/masking, request caching, failover/retry, multi-provider support (OpenAI, Azure OpenAI, Anthropic, vLLM, Deepinfra). Drop-in OpenAI-compatible proxy endpoint."
---

# BricksLLM

**Cloud-native AI gateway for putting LLMs in production.** Manage, rate-limit, and monitor LLM API usage across teams, users, or environments — with per-key cost limits, PII masking, caching, and failover. Drop-in OpenAI-compatible proxy. MIT license.

Built + maintained by **bricks-cloud** (Y Combinator S22).

- Upstream repo: <https://github.com/bricks-cloud/BricksLLM>
- Deploy repo: <https://github.com/bricks-cloud/BricksLLM-Docker>
- Docs / cookbooks: <https://github.com/bricks-cloud/BricksLLM/tree/main/cookbook>

## Architecture in one minute

- Go service exposing two ports:
  - **`:8001`** — Admin API (create/manage keys, providers, policies)
  - **`:8002`** — Proxy API (OpenAI-compatible endpoint for LLM requests)
- Backed by **PostgreSQL** (key/config storage) and **Redis** (rate limiting, caching)
- No browser UI — managed via REST API calls or SDK

## Compatible install methods

| Method | Notes |
|--------|-------|
| **Docker Compose** | **Primary** — via `bricks-cloud/BricksLLM-Docker` |
| Source (Go) | Build and run the Go binary directly |

## Inputs to collect

| Input | Example | Phase | Notes |
|-------|---------|-------|-------|
| LLM provider API key | `sk-...` | Config | OpenAI, Anthropic, Azure, etc. |
| PostgreSQL password | — | Database | Credentials for the embedded PostgreSQL container |
| Redis password | — | Cache | Credentials for the embedded Redis container |

## Install via Docker Compose

### Step 1 — Clone the deploy repo

```bash
git clone https://github.com/bricks-cloud/BricksLLM-Docker
cd BricksLLM-Docker
```

### Step 2 — Set your LLM provider API key

```bash
export OPENAI_API_KEY=sk-your-openai-key
```

Or add it to a `.env` file in the directory.

### Step 3 — Start the stack

```bash
docker compose up -d
```

This starts PostgreSQL, Redis, and BricksLLM.

## Docker Compose

```yaml
version: '3.8'
services:
  redis:
    image: redis:6.2-alpine
    restart: always
    command: redis-server --save 20 1 --loglevel warning --requirepass eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81
    volumes:
      - redis:/data

  postgresql:
    image: postgres:14.1-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - postgresql:/var/lib/postgresql/data

  bricksllm:
    depends_on:
      - redis
      - postgresql
    image: luyuanxin1995/bricksllm
    restart: on-failure
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - POSTGRESQL_USERNAME=postgres
      - POSTGRESQL_PASSWORD=postgres
      - REDIS_PASSWORD=eYVX7EwVmmxKPCDmwMtyKVge8oLd2t81
      - POSTGRESQL_HOSTS=postgresql
      - REDIS_HOSTS=redis
    ports:
      - '8001:8001'
      - '8002:8002'
    command:
      - '-m=dev'

volumes:
  redis:
  postgresql:
```

> **Security note:** Change `POSTGRES_PASSWORD` and the Redis password (`requirepass` + `REDIS_PASSWORD`) before exposing to any network.

## Usage: Create a provider setting

Register your LLM provider API key with BricksLLM:

```bash
curl -X PUT http://localhost:8001/api/provider-settings \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "openai",
    "setting": {
      "apikey": "YOUR_OPENAI_KEY"
    }
  }'
```

Copy the `id` from the response — you'll use it as `settingId` when creating API keys.

## Usage: Create a managed API key

Create a key with rate limits and a spend ceiling:

```bash
curl -X PUT http://localhost:8001/api/key-management/keys \
  -H "Content-Type: application/json" \
  -d '{
    "name": "team-alpha",
    "key": "team-alpha-secret",
    "tags": ["team-alpha"],
    "settingIds": ["SETTING_ID_FROM_ABOVE"],
    "rateLimitOverTime": 100,
    "rateLimitUnit": "m",
    "costLimitInUsd": 10.00
  }'
```

## Usage: Make LLM requests via the proxy

Point your OpenAI SDK or `baseURL` to `http://localhost:8002/api/providers/openai/v1`:

```bash
curl -X POST http://localhost:8002/api/providers/openai/v1/chat/completions \
  -H "Authorization: Bearer team-alpha-secret" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

Or in the OpenAI Node SDK:

```js
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: "team-alpha-secret",
  baseURL: "http://localhost:8002/api/providers/openai/v1",
});
```

## Supported providers

| Provider | Notes |
|----------|-------|
| OpenAI | All endpoints (chat, completions, embeddings, images, etc.) |
| Azure OpenAI | Native support |
| Anthropic | Native support |
| vLLM | Self-hosted LLMs |
| Deepinfra | Native support |
| Custom deployments | Configurable |

## Key features

- **Per-key cost limits**: Hard spending caps per API key (`costLimitInUsd`)
- **Rate limiting**: Requests/minute, requests/hour, or requests/day per key
- **PII detection & masking**: Scan requests for PII before forwarding to the LLM provider
- **Caching**: Cache identical LLM responses to reduce API cost
- **Failover & retry**: Automatic retries with configurable Azure OpenAI failover
- **Cost & request analytics**: Per-key usage logs via Admin API
- **Datadog integration**: Metrics export to Datadog

## Updating

```bash
docker compose pull
docker compose up -d
```
