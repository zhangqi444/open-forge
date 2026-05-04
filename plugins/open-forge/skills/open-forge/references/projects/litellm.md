---
name: litellm
description: LiteLLM recipe for open-forge. Open-source AI Gateway providing a unified OpenAI-compatible interface for 100+ LLM providers. Self-hosted proxy with virtual API keys, spend tracking, and load balancing.
---

# LiteLLM

Open-source AI Gateway that provides a single, unified OpenAI-compatible interface for 100+ LLM providers — OpenAI, Anthropic, Gemini, Bedrock, Azure, and more. Deploy as a self-hosted proxy for your team or organization with virtual API keys, spend tracking, guardrails, and load balancing. Upstream: <https://github.com/BerriAI/litellm>. Docs: <https://docs.litellm.ai/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Self-hosted team proxy with PostgreSQL |
| Docker (single container) | Quick eval; no DB persistence |
| pip / Python | Direct SDK use in Python apps |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which LLM providers to proxy?" | OpenAI, Anthropic, Bedrock, Gemini, Azure, Ollama, etc. |
| preflight | "API keys for each provider?" | Set as env vars in config |
| preflight | "Master key for LiteLLM proxy?" | `LITELLM_MASTER_KEY`; used to generate virtual keys |

## Docker Compose example

```yaml
version: "3.9"
services:
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    restart: unless-stopped
    ports:
      - "4000:4000"
    volumes:
      - ./litellm-config.yaml:/app/config.yaml
    command: ["--config", "/app/config.yaml", "--port", "4000"]
    environment:
      LITELLM_MASTER_KEY: sk-changeme
      DATABASE_URL: postgresql://litellm:changeme@db:5432/litellm  # optional; for persistence

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: litellm
      POSTGRES_PASSWORD: changeme
    volumes:
      - litellm-db:/var/lib/postgresql/data

volumes:
  litellm-db:
```

## litellm-config.yaml example

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY

  - model_name: claude-3-5-sonnet
    litellm_params:
      model: anthropic/claude-3-5-sonnet-20241022
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: local-llama
    litellm_params:
      model: ollama/llama3.2
      api_base: http://ollama:11434

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
```

## Using the proxy

```bash
# OpenAI-compatible call — swap in any model_name from config
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-changeme" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-4o", "messages": [{"role": "user", "content": "Hello!"}]}'
```

## Software-layer concerns

- Container image: `ghcr.io/berriai/litellm` (GHCR, not Docker Hub)
- Port `4000`: proxy API (OpenAI-compatible) + admin UI at `/ui`
- Admin UI: http://localhost:4000/ui — manage virtual keys, view spend, configure models
- PostgreSQL is optional but required for virtual key persistence and spend tracking across restarts
- `LITELLM_MASTER_KEY` is the root key; create scoped virtual keys in the UI for team members
- Supports load balancing, fallbacks, and retry logic across providers

## Upgrade procedure

1. Pull new image: `docker compose pull litellm`
2. Restart: `docker compose up -d litellm`
3. DB migrations run automatically on startup

## Gotchas

- Image is on **GHCR** (`ghcr.io/berriai/litellm`), not Docker Hub
- Without PostgreSQL, virtual keys and spend data are lost on container restart
- Provider API keys must be set as environment variables referenced in config (`os.environ/KEY_NAME`)
- `main-latest` tag tracks the main branch; use a pinned version tag for production stability

## Links

- GitHub: <https://github.com/BerriAI/litellm>
- Docs: <https://docs.litellm.ai/>
- Proxy docs: <https://docs.litellm.ai/docs/simple_proxy>
- GHCR: <https://github.com/BerriAI/litellm/pkgs/container/litellm>
