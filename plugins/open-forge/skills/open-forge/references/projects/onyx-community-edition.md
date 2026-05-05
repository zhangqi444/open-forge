---
name: onyx-community-edition
description: Onyx (Community Edition) recipe for open-forge. Enterprise AI assistant platform with RAG, document connectors, and team knowledge search. Self-hosted via Docker Compose. Based on upstream README and docs at https://docs.onyx.app/ and the onyx-dot-app/onyx repo.
---

# Onyx Community Edition

Open-source enterprise AI assistant and knowledge search platform. Connects to 25+ data sources (Slack, Confluence, Google Drive, GitHub, Jira, Notion, web crawl, local files, and more), indexes them with Vespa, and provides a chat interface with RAG (Retrieval-Augmented Generation) over your organization's documents. License: MIT. Upstream: <https://github.com/onyx-dot-app/onyx>. Docs: <https://docs.onyx.app/>.

The stack is multi-container Docker Compose: API server, background worker, Next.js web UI, inference model server (embedding/reranking), Vespa (vector + keyword search), OpenSearch (optional hybrid search), PostgreSQL, Redis, MinIO (S3-compatible file store), NGINX (reverse proxy).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (self-hosted) | https://docs.onyx.app/introduction | Yes | Primary self-hosted method. Linux or macOS with Docker. |
| Kubernetes / Helm | https://github.com/onyx-dot-app/onyx/tree/main/deployment/helm | Yes | Production-grade k8s deploy (Helm chart in repo). |
| Onyx Cloud (SaaS) | https://app.onyx.app | Yes | Managed hosted version — out of scope here. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Docker Compose / Kubernetes | Drives which section loads |
| auth | Authentication method? (basic / google_oauth / oidc / saml) | Choose | All installs |
| llm | Which LLM backend? (OpenAI / Azure OpenAI / Anthropic / local Ollama / other) | Choose | All installs |
| llm | API key for chosen LLM provider? | Free-text (sensitive) | Cloud LLM providers |
| domain | Public domain for Onyx (for HTTPS)? | Free-text | All public-facing installs |
| connectors | Which data sources to connect? (Slack / Confluence / Google Drive / etc.) | Multi-select | Post-install config via admin UI |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Services | api_server, background (worker), web_server (Next.js), inference_model_server, indexing_model_server, relational_db (PostgreSQL), index (Vespa), opensearch (optional), nginx, cache (Redis), minio, code-interpreter |
| Default port | 80 (NGINX reverse proxy). In dev mode: api_server on 8080 exposed directly. |
| Config | .env file in deployment/docker_compose/. Copy env.template to .env and fill in. |
| LLM config | Set GEN_AI_MODEL_PROVIDER, GEN_AI_API_KEY, GEN_AI_MODEL_VERSION in .env |
| Auth | AUTH_TYPE in .env: basic (default), google_oauth, oidc, saml |
| File storage | MinIO (S3-compatible) by default. Can switch to AWS S3 or GCS via FILE_STORE_BACKEND. |
| Embeddings | Default embedding model downloaded to Docker volume (model_cache_huggingface). ~2-4GB on first start. |
| Search index | Vespa (primary). OpenSearch optional for hybrid search — disable by removing opensearch service. |
| Persistent data | Docker volumes: db_volume (Postgres), vespa_volume, minio_data, model caches, logs. |
| Hardware | Minimum: 4 CPU, 8GB RAM. Recommended for production: 8+ CPU, 16GB+ RAM. GPU optional for local inference. |
| First-run time | Expect 5-10 min on first docker compose up — embedding models download on startup. |

## Method — Docker Compose

Source: https://docs.onyx.app/introduction and https://github.com/onyx-dot-app/onyx/tree/main/deployment/docker_compose

    git clone https://github.com/onyx-dot-app/onyx.git
    cd onyx/deployment/docker_compose

    # Copy and edit env file
    cp env.template .env
    # Edit .env — minimum required:
    #   GEN_AI_MODEL_PROVIDER=openai (or anthropic, azure, etc.)
    #   GEN_AI_API_KEY=<your key>
    #   GEN_AI_MODEL_VERSION=gpt-4o (or chosen model)
    #   AUTH_TYPE=basic (or google_oauth/oidc/saml)
    #   SECRET=<random string for session signing, e.g. openssl rand -hex 32>
    #   WEB_DOMAIN=https://yourdomain.com (if exposing publicly)

    # Start stack (pulls images on first run, ~5-10 min for model downloads)
    docker compose -f docker-compose.yml -p onyx up -d

    # Wait for api_server health
    docker compose -p onyx ps
    docker compose -p onyx logs api_server -f

Access UI at http://localhost:80 (or your domain if NGINX is configured with TLS).

### Development mode (ports exposed)

    docker compose -f docker-compose.yml -f docker-compose.dev.yml -p onyx up -d

This exposes individual service ports (api_server: 8080, PostgreSQL: 5432, Vespa: 8081/19071, MinIO: 9001) for debugging.

### Production hardening (from upstream checklist)

1. Remove port exposures except NGINX (80/443) — comment out ports for api_server, relational_db, index, cache, minio.
2. TLS: uncomment the certbot service in docker-compose.yml, add SSL volumes to nginx, change nginx command to app.conf.template.prod.
3. Set DOMAIN env var in .env and configure DNS.
4. Use explicit environment variables instead of env_file for secrets in production.
5. Choose and configure an auth method (google_oauth or oidc recommended over basic for teams).

## Key admin UI tasks (post-install)

1. Navigate to http://localhost/admin (or your domain /admin).
2. Create admin account on first login.
3. Add connectors: Admin -> Add Connector -> choose source (Slack, Confluence, Google Drive, etc.).
4. Configure LLM in Admin -> LLM if not set in .env.
5. Create user groups and assign document sets for access control.
6. Add personas (AI assistants with different system prompts and document set scope).

## Upgrade procedure

    cd onyx/deployment/docker_compose
    git pull
    docker compose -f docker-compose.yml -p onyx pull
    docker compose -f docker-compose.yml -p onyx up -d

Alembic DB migrations run automatically on api_server startup. Check logs for migration errors:

    docker compose -p onyx logs api_server | grep -i "alembic\|migration\|error"

## Gotchas

- First-run model download: embedding models (several GB) download to Docker volumes on first startup. The stack will appear unhealthy until downloads complete. Watch with: docker compose -p onyx logs inference_model_server -f
- Memory requirements: Vespa alone needs ~3GB. Running the full stack under 8GB RAM causes OOM kills. Monitor with: docker stats
- AUTH_TYPE=basic is insecure for multi-user: basic auth uses a shared login. For teams, configure google_oauth, oidc, or saml.
- SECRET must be set: without SECRET in .env, session tokens are not properly signed. Generate with: openssl rand -hex 32
- Vespa volume is large: the search index grows with document count. Plan storage accordingly — Vespa volume can reach tens of GB for large corpora.
- MinIO default credentials: minioadmin/minioadmin. Change S3_AWS_ACCESS_KEY_ID and S3_AWS_SECRET_ACCESS_KEY in .env before exposing publicly.
- OpenSearch is optional: if you don't need hybrid search, you can remove the opensearch service from docker-compose.yml to save ~2GB RAM.
- Connector credentials are encrypted: connector OAuth tokens and API keys are stored encrypted in PostgreSQL. Don't lose your encryption key (derived from SECRET).
- Onyx vs Danswer: Onyx is the renamed successor to Danswer (the project rebranded in 2024). Same codebase/team.

## Links

- Docs: https://docs.onyx.app/
- Quick start: https://docs.onyx.app/introduction
- Connector docs: https://docs.onyx.app/connectors/overview
- GitHub: https://github.com/onyx-dot-app/onyx
- Helm chart: https://github.com/onyx-dot-app/onyx/tree/main/deployment/helm
- Releases: https://github.com/onyx-dot-app/onyx/releases
