---
name: onyx-community-edition
description: Onyx (Community Edition) recipe for open-forge. AI-powered search and answer engine with RAG, 50+ connectors, and multi-LLM support. Covers Docker Compose single-server deploy. Based on upstream docs at https://docs.onyx.app/ and the onyx-dot-app/onyx repo.
---

# Onyx Community Edition

AI-powered enterprise search, Q&A, and chat platform with Retrieval-Augmented Generation (RAG). Connects to 50+ data sources (Slack, Confluence, Google Drive, Jira, GitHub, etc.), indexes documents, and answers questions with citations. Self-hosted MIT-licensed Community Edition. Upstream: <https://github.com/onyx-dot-app/onyx>. Docs: <https://docs.onyx.app/>.

Onyx is a multi-container application: API server, background workers, Vespa vector/search index, PostgreSQL, Redis, Nginx frontend, and optional model inference servers. The Docker Compose stack is the standard self-hosted path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (single server) | https://docs.onyx.app/deployment/docker_compose | Yes | Standard self-hosted deploy. All services on one host. |
| Kubernetes / Helm | https://docs.onyx.app/deployment/kubernetes | Yes | Multi-node, higher availability. Uses community Helm chart. |
| AWS / GCP / Azure cloud deploy | https://docs.onyx.app/deployment | Yes | Cloud-specific guides in upstream docs. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Choose from table above | Drives which section loads |
| auth | Which authentication method? (basic / Google OAuth / OIDC / SAML / disabled) | Choose | All deploys — see AUTH_TYPE env var |
| llm | Which LLM provider? (OpenAI / Anthropic / Azure OpenAI / self-hosted via Ollama / other) | Choose | All deploys |
| llm | API key for chosen LLM provider | Free-text (sensitive) | All cloud LLM providers |
| storage | Host path for persistent data volumes (e.g. /opt/onyx) | Free-text | Docker Compose |
| domain | Domain or IP where Onyx will be accessed | Free-text | All deploys — for DOMAIN env var and TLS setup |
| tls | Enable HTTPS via Let's Encrypt? | Yes/No | All public-facing deploys |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Services | api_server (port 8080), background (worker), web_server (nginx, port 80/443), vespa (vector index, port 19071/8081), relational_db (postgres, port 5432), cache (redis), inference_model_server (embedding), indexing_model_server |
| Default ports | 80 (HTTP via nginx), 443 (HTTPS), 8080 (API, internal) |
| Config file | deployment/docker_compose/.env — copy from env.template |
| Auth | AUTH_TYPE env var: disabled / basic / google_oauth / oidc / saml. Default is basic (email+password). |
| LLM | GEN_AI_MODEL_PROVIDER + GEN_AI_API_KEY env vars. Supports OpenAI, Anthropic, Azure OpenAI, Bedrock, Ollama, and others. |
| Embedding | Default uses a local model server (no API key needed). Can switch to OpenAI/Cohere embeddings via env vars. |
| Data volumes | Vespa index, Postgres DB, and file store (MinIO or local) hold all indexed documents and chat history. Back these up. |
| File storage | FILE_STORE_BACKEND: local (default) or s3/minio for production. |
| Connectors | Configured in the Onyx web UI after deploy. 50+ connectors including Slack, Confluence, Google Drive, Jira, GitHub, Notion, Salesforce, and more. |
| Min resources | 4 vCPUs, 16 GB RAM recommended. Vespa alone requires ~4 GB RAM. |

## Method — Docker Compose (single server)

Source: https://docs.onyx.app/deployment/docker_compose

    # 1. Clone the repo
    git clone https://github.com/onyx-dot-app/onyx.git
    cd onyx/deployment/docker_compose

    # 2. Copy env template
    cp env.template .env

    # 3. Edit .env — minimum required changes:
    #   - Set AUTH_TYPE (disabled for quick test, basic for production)
    #   - Set GEN_AI_MODEL_PROVIDER and GEN_AI_API_KEY
    #   - Set SECRET_JWT_KEY to a random string: openssl rand -hex 32
    #   - Set DOMAIN if using custom domain + TLS

    # 4. Pull images and start
    docker compose -f docker-compose.yml up -d --wait

    # Check status
    docker compose ps

On startup, wait ~2-3 minutes for Vespa to initialize. Access at http://<host>:80.

### Key .env settings

    # Authentication
    AUTH_TYPE=basic                          # disabled / basic / google_oauth / oidc / saml

    # LLM (example: OpenAI)
    GEN_AI_MODEL_PROVIDER=openai
    GEN_AI_API_KEY=sk-...
    GEN_AI_MODEL_VERSION=gpt-4o

    # Security — generate fresh values
    SECRET_JWT_KEY=$(openssl rand -hex 32)
    ENCRYPTION_KEY_SECRET=$(openssl rand -hex 32)

    # Domain
    DOMAIN=onyx.example.com

    # File storage (local is default; use s3 for production scale)
    FILE_STORE_BACKEND=local

### Enable HTTPS

In .env, set DOMAIN to your domain. Then bring up with the prod docker-compose override which uses certbot:

    docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

The prod compose file adds a certbot service and configures Nginx for SSL. DNS A-record must point to the server before running.

### Expose ports for debugging (dev mode)

    docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --wait

This exposes api_server (8080), postgres (5432), vespa (8081/19071) for direct access during development.

## First-time setup

1. Visit http://<host>/ after containers are healthy.
2. Create the first admin account (first signup becomes admin — secure this window).
3. Go to Admin -> Connectors to add data sources.
4. Configure the LLM under Admin -> LLM Providers if not set via env vars.
5. Add users/groups under Admin -> Users.

## Upgrade procedure

    cd onyx/deployment/docker_compose
    git pull
    docker compose pull
    docker compose up -d --wait

Alembic DB migrations run automatically on api_server startup. Review the changelog at https://github.com/onyx-dot-app/onyx/releases for breaking changes before major version upgrades.

## Gotchas

- Min resources are real: Vespa requires ~4 GB RAM on its own. On a 4 GB host, other services will OOM. Use at least 8-16 GB RAM in production.
- First signup = admin: the first user to register on a fresh deploy gets admin rights. On a public-facing instance, complete setup immediately or set AUTH_TYPE=disabled temporarily and configure OIDC/SAML before opening to users.
- .env passwords are write-once: POSTGRES_PASSWORD and similar DB credentials cannot be changed after first init without a full volume reset + restore. Treat them as immutable.
- SECRET_JWT_KEY must be set: the default template value is a placeholder. Use openssl rand -hex 32 to generate a real key. A known/default JWT key allows token forgery.
- Connector credentials are stored encrypted: the ENCRYPTION_KEY_SECRET env var must be consistent across restarts. If it changes, all stored connector credentials become unreadable.
- Vespa startup is slow: it takes 1-3 minutes for Vespa to reach healthy state. docker compose ps will show unhealthy briefly — wait for --wait to complete or check docker compose logs vespa.
- Self-hosted embedding: the default embedding model server downloads a model on first start (~500MB). Ensure internet access or pre-pull the image.
- MIT license (Community Edition): the enterprise features (SAML, advanced permissions, etc.) are in the Enterprise Edition. CE is MIT-licensed and fully functional for most self-hosted use cases.

## Links

- Docs: https://docs.onyx.app/
- Docker Compose deploy: https://docs.onyx.app/deployment/docker_compose
- Connectors: https://docs.onyx.app/connectors/overview
- LLM configuration: https://docs.onyx.app/configuration_guide
- GitHub: https://github.com/onyx-dot-app/onyx
- Releases: https://github.com/onyx-dot-app/onyx/releases
