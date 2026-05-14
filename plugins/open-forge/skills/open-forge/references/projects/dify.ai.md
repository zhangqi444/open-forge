# Dify.ai

Open-source LLM application development platform. Dify lets you build, deploy, and manage AI-powered workflows, chatbots, and agents. Supports orchestrating multiple LLM providers (OpenAI, Anthropic, Ollama, Azure, etc.), RAG pipelines, tool/plugin integrations, and visual prompt engineering.

**Official site:** https://dify.ai  
**Source:** https://github.com/langgenius/dify  
**Upstream docs:** https://docs.dify.ai/getting-started/install-self-hosted  
**License:** Apache-2.0 + Commons Clause (source-available; commercial use of hosted SaaS requires a license)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| Kubernetes | Helm chart | See helm chart in repo |

---

## Inputs to Collect

### Required
| Variable | Description | Default / Notes |
|----------|-------------|-----------------|
| `SECRET_KEY` | Flask secret key — change before production | `sk-9f73s3...` (insecure default) |
| `DB_PASSWORD` | PostgreSQL password | `difyai123456` (insecure default) |

### Optional
| Variable | Description | Default |
|----------|-------------|---------|
| `INIT_PASSWORD` | Initial admin password | unset (prompted on first login) |
| `CONSOLE_API_URL` | Public URL of your API server | auto-detected |
| `CONSOLE_WEB_URL` | Public URL of your web app | auto-detected |
| `LOG_LEVEL` | Logging verbosity | `INFO` |
| `MIGRATION_ENABLED` | Run DB migrations on startup | `true` |

---

## Software-Layer Concerns

### Services (docker-compose.yaml)
| Service | Image | Role |
|---------|-------|------|
| `api` | `langgenius/dify-api:1.14.1` | Backend API server |
| `worker` | `langgenius/dify-api:1.14.1` | Celery async worker |
| `worker_beat` | `langgenius/dify-api:1.14.1` | Celery beat scheduler |
| `web` | `langgenius/dify-web:1.14.1` | Next.js frontend |
| `db_postgres` | `postgres:15-alpine` | Primary database |
| `redis` | `redis:6-alpine` | Cache + task queue |
| `sandbox` | `langgenius/dify-sandbox:0.2.15` | Isolated code execution |
| `plugin_daemon` | `langgenius/dify-plugin-daemon:0.6.0-local` | Plugin manager |
| `ssrf_proxy` | `ubuntu/squid:latest` | SSRF protection proxy |
| `nginx` | `nginx:latest` | Reverse proxy (entrypoint) |

### Quick start
```sh
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env
# Edit .env: change SECRET_KEY and DB_PASSWORD at minimum
docker compose up -d
```

The nginx container proxies all traffic; access the app at `http://localhost` (port 80) by default.

### .env key variables
```env
SECRET_KEY=your-random-secret-here
INIT_PASSWORD=your-admin-password
DB_USERNAME=postgres
DB_PASSWORD=your-db-password
DB_HOST=db_postgres
DB_PORT=5432
DB_DATABASE=dify
REDIS_HOST=redis
REDIS_PORT=6379
```

### Data directories
- PostgreSQL volume: all app data, prompts, datasets, conversations
- Local file storage: uploaded documents/images under `./volumes/app/storage`
- Back up both before upgrades

### Vector store (optional)
Dify supports pluggable vector stores for RAG. Default vector DB is Weaviate (bundled in Compose). Alternatives: Qdrant, Milvus, pgvector, etc. — configured in `.env`.

---

## Upgrade Procedure

1. `cd dify/docker && git pull`
2. Review `.env.example` for new variables; merge into `.env`
3. `docker compose pull`
4. `docker compose up -d`
5. DB migrations run automatically on startup (`MIGRATION_ENABLED=true`)
6. Check release notes: https://github.com/langgenius/dify/releases

---

## Gotchas

- **Change SECRET_KEY before production** — the default value is public and insecure; changing it after deployment invalidates existing sessions
- **Commons Clause restriction** — the Apache-2.0 + Commons Clause license means you cannot sell Dify as a hosted service without a commercial license; self-hosting for internal use is fine
- **docker-compose.yaml is auto-generated** — do not edit it directly; instead modify `.env.example` or `docker-compose-template.yaml` and regenerate
- **SSRF proxy is required** — the `ssrf_proxy` service protects against server-side request forgery from tool integrations; do not remove it
- **Sandbox isolation** — the `sandbox` service runs user code in an isolated container; it requires `SYS_ADMIN` or similar capabilities on some hosts
- **nginx is the entry point** — do not expose `api` or `web` containers directly; all traffic should flow through the nginx container

---

## Links
- Upstream README: https://github.com/langgenius/dify
- Self-hosting docs: https://docs.dify.ai/getting-started/install-self-hosted
- Docker compose guide: https://docs.dify.ai/getting-started/install-self-hosted/docker-compose
