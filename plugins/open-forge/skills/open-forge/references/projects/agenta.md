---
name: agenta
description: Agenta recipe for open-forge. Covers self-hosted Docker Compose deployment. Open-source LLMOps platform for prompt management, LLM evaluation, and observability. Supports 50+ LLM models, version-controlled prompts, human and automated evaluation, and OpenTelemetry-native tracing. Sourced from https://github.com/agenta-ai/agenta.
---

# Agenta

Open-source LLMOps platform for building production-grade LLM applications. Provides collaborative prompt management, systematic LLM evaluation (human + automated), and OpenTelemetry-native observability. Supports 50+ LLM models and integrates with LangSmith, LangFuse, and other observability tools. Upstream: https://github.com/agenta-ai/agenta. Docs: https://agenta.ai/docs/.

Agenta is deployed as a suite of Docker Compose services. Agenta Cloud (managed) is available with a free tier; self-hosting is MIT-licensed.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (OSS) | https://agenta.ai/docs/self-host/quick-start | Self-hosted; all features except cloud-only SSO |
| Agenta Cloud | https://cloud.agenta.ai | Managed; free tier available |

## Architecture components

| Service | Purpose |
|---|---|
| agenta-backend | Python FastAPI backend; prompt/eval/trace APIs |
| agenta-web | Next.js frontend (playground, evaluations, traces) |
| agenta-worker | Async evaluation jobs |
| PostgreSQL | Primary datastore |
| Redis | Task queue and cache |
| Traefik (optional) | Reverse proxy with TLS |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Self-host or use Agenta Cloud?" | Drives method |
| llm | "Which LLM providers will you use?" | API keys entered in Agenta UI or .env file |
| domain | "Deploying on a remote host with a domain?" | Required for remote deploy; see docs |
| auth | "Enable user authentication / multi-tenancy?" | Cloud-only SSO or self-managed |

## Self-hosted install (Docker Compose)

```sh
# 1. Clone repo
git clone https://github.com/Agenta-AI/agenta && cd agenta

# 2. Copy environment file
cp hosting/docker-compose/oss/env.oss.gh.example \
   hosting/docker-compose/oss/.env.oss.gh

# 3. Start services (with web UI and Traefik proxy)
docker compose \
  -f hosting/docker-compose/oss/docker-compose.gh.yml \
  --env-file hosting/docker-compose/oss/.env.oss.gh \
  --profile with-web \
  --profile with-traefik \
  up -d

# 4. Open http://localhost
```

## Environment file key settings (.env.oss.gh)

| Variable | Purpose |
|---|---|
| DOMAIN | Hostname for remote deploy (default: localhost) |
| OPENAI_API_KEY | OpenAI API key (can also be set per-project in UI) |
| POSTGRES_USER / PASSWORD | Database credentials |
| SECRET_KEY | Django/FastAPI signing key — change for production |
| CELERY_BROKER_URL | Redis URL for task queue |

## Remote deployment

For deploying on a server with a domain name, refer to:
https://agenta.ai/docs/self-host/guides/deploy-remotely

Key difference: set DOMAIN in .env.oss.gh to your hostname; Traefik handles TLS via Let's Encrypt.

## Upgrade procedure

```sh
git pull
docker compose \
  -f hosting/docker-compose/oss/docker-compose.gh.yml \
  --env-file hosting/docker-compose/oss/.env.oss.gh \
  --profile with-web \
  --profile with-traefik \
  pull
docker compose \
  -f hosting/docker-compose/oss/docker-compose.gh.yml \
  --env-file hosting/docker-compose/oss/.env.oss.gh \
  --profile with-web \
  --profile with-traefik \
  up -d
```

## Gotchas

- **Profile flags required** — `--profile with-web` and `--profile with-traefik` must both be specified to start the frontend and proxy; omitting them starts only the backend API.
- **SECRET_KEY must be set for production** — a weak or default key allows session forgery; generate with `openssl rand -hex 32`.
- **LLM API keys per-project** — API keys can be set globally in .env or per-project in the Agenta UI; per-project keys take precedence.
- **Evaluation workers** — the agenta-worker service handles long-running evaluation jobs; ensure it has enough CPU/RAM for batch LLM calls.
- **OpenTelemetry tracing** — Agenta natively collects traces from apps instrumented with OpenLLMetry or OpenInference; no separate collector needed for basic use.
- **Remote deploy domain** — Traefik requires a valid domain for Let's Encrypt; localhost installs use HTTP only.

## Links

- GitHub: https://github.com/Agenta-AI/agenta
- Self-hosting quickstart: https://agenta.ai/docs/self-host/quick-start
- Remote deploy guide: https://agenta.ai/docs/self-host/guides/deploy-remotely
- Full docs: https://agenta.ai/docs/
- Docker Compose file: https://github.com/Agenta-AI/agenta/blob/main/hosting/docker-compose/oss/docker-compose.gh.yml
