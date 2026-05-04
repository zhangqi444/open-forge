---
name: openlit
description: OpenLIT recipe for open-forge. Open-source AI engineering platform with OpenTelemetry-native LLM observability, prompt management, API key vault, evaluations, guardrails, and playground.
---

# OpenLIT

Open-source AI engineering platform for GenAI and LLM applications. Provides OpenTelemetry-native observability (traces, metrics, costs), prompt management, API key vault, built-in LLM evaluations, guardrails, a model playground, and Fleet Hub for managing OTel collectors. Instrument with one line of Python/TypeScript/Go code. Upstream: <https://github.com/openlit/openlit>. Docs: <https://docs.openlit.io/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Kubernetes / Helm | Production K8s |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for OpenLIT?" | For reverse-proxy TLS |
| preflight | "Admin email and password?" | Set via env vars on first run |

## Docker Compose example

```yaml
version: "3.9"
services:
  openlit:
    image: ghcr.io/openlit/openlit:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    depends_on:
      - clickhouse
    environment:
      INIT_DB_HOST: clickhouse
      INIT_DB_PORT: 9000
      INIT_DB_DATABASE: openlit
      INIT_DB_USERNAME: default
      INIT_DB_PASSWORD: ""
      SQLITE_DATABASE_URL: file:/app/client/data/data.db
    volumes:
      - openlit-data:/app/client/data

  clickhouse:
    image: clickhouse/clickhouse-server:latest
    restart: unless-stopped
    ulimits:
      nofile:
        soft: 262144
        hard: 262144
    volumes:
      - clickhouse-data:/var/lib/clickhouse

volumes:
  openlit-data:
  clickhouse-data:
```

- UI: http://localhost:3000

## SDK instrumentation (Python, 1 line)

```python
import openlit

openlit.init(otlp_endpoint="http://localhost:4318")
```

This automatically captures LLM calls (OpenAI, Anthropic, Gemini, LangChain, LlamaIndex, etc.) as OTel traces and sends them to OpenLIT.

## Software-layer concerns

- Container image: `ghcr.io/openlit/openlit` (GHCR)
- Port `3000`: Web UI
- Port `4318`: OTLP HTTP receiver (for SDK traces)
- ClickHouse stores traces and metrics; SQLite stores app config/prompts/API keys
- Supports 50+ LLM providers and vector databases for auto-instrumentation
- Built-in evaluation types: hallucination, bias, toxicity, safety, relevance, coherence, and more
- Follows OpenTelemetry GenAI semantic conventions

## Upgrade procedure

1. Pull new image: `docker compose pull openlit`
2. Restart: `docker compose up -d openlit`
3. DB migrations run automatically

## Gotchas

- Image is on **GHCR** (`ghcr.io/openlit/openlit`), not Docker Hub
- ClickHouse is memory-hungry — needs ≥ 2 GB RAM on the host
- OTLP endpoint in SDK must point to OpenLIT's OTLP receiver port (`4318` for HTTP, `4317` for gRPC)
- Both ClickHouse volumes and SQLite volume should be persisted

## Links

- GitHub: <https://github.com/openlit/openlit>
- Docs: <https://docs.openlit.io/>
- GHCR: <https://github.com/openlit/openlit/pkgs/container/openlit>
