---
name: dify-ai
description: Dify.ai recipe for open-forge. LLM application development platform — build, test, and deploy AI workflows, chatbots, and agents with a visual interface. Apache-2.0 + Commons Clause. Source: https://github.com/langgenius/dify
---

# Dify.ai

A platform for building, testing, and deploying LLM-powered applications. Provides a visual workflow builder, RAG pipelines, agent frameworks, prompt management, and API access for AI apps. Used for chatbots, AI assistants, content pipelines, and custom LLM workflows. Apache-2.0 + Commons Clause licensed (self-hosting is free; reselling is restricted). Source: <https://github.com/langgenius/dify>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker Compose | Primary supported deployment |
| Kubernetes | Helm chart | Official Helm chart available |

> Minimum recommended: 2 CPU cores, 4 GB RAM. LLM inference is via external API (OpenAI, Anthropic, Ollama, etc.) — not bundled.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. dify.example.com |
| "LLM provider?" | openai / anthropic / ollama / azure / other | External API or local Ollama |
| "LLM API key?" | String | If using cloud provider |
| "Initial admin password?" | String | Set via `INIT_PASSWORD`; changed at first login |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Secret key?" | Random 32+ char string | Flask `SECRET_KEY` — change from default |
| "Storage backend?" | local / s3 / azure-blob / google-storage | For uploaded files and model artifacts |
| "TLS?" | Yes / No | Handled by reverse proxy |

## Software-Layer Concerns

- **Multi-service stack**: Dify runs multiple containers — `api`, `worker`, `web`, `db` (PostgreSQL), `redis`, `sandbox`, `weaviate` (vector DB), and optionally `nginx`. All managed via Docker Compose.
- **SECRET_KEY**: Must be changed from the default in `.env` — losing it invalidates all sessions.
- **INIT_PASSWORD**: Sets the initial admin password; can be left blank to set at first login.
- **Database**: PostgreSQL (bundled in Compose); data in `./volumes/db/data` or a named volume.
- **Vector DB**: Weaviate bundled by default; other backends (Qdrant, Pinecone, Milvus) configurable in `.env`.
- **Redis**: Required for task queues and caching; bundled in Compose.
- **Sandbox container**: Runs code execution for workflow code nodes — isolated via seccomp.
- **File storage**: Local by default (`./volumes/app/storage`); S3 or equivalent recommended for production.
- **LLM connections**: Configured in the UI after login — no API keys needed at deploy time (can be added per-workspace).
- **Commons Clause**: Self-hosting and internal use is free; selling Dify as a service to others is prohibited without a commercial license.

## Deployment

```bash
# Clone the repo and enter the docker directory
git clone https://github.com/langgenius/dify.git
cd dify/docker

# Copy and edit the environment file
cp .env.example .env
vim .env
# Key vars to change:
#   SECRET_KEY=<random-32-char-string>
#   INIT_PASSWORD=<your-admin-password>
#   CONSOLE_API_URL=https://dify.example.com
#   APP_API_URL=https://dify.example.com
#   CONSOLE_WEB_URL=https://dify.example.com

# Start all services
docker compose up -d

# Check status
docker compose ps
```

First login: `https://dify.example.com` → create admin account → add LLM provider under Settings → Model Provider.

### NGINX reverse proxy (if not using bundled NGINX container)

```nginx
server {
    listen 443 ssl;
    server_name dify.example.com;

    location / {
        proxy_pass http://127.0.0.1:80;  # bundled nginx container
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        # SSE streams for workflows:
        proxy_buffering off;
        proxy_read_timeout 3600s;
    }
}
```

### Kubernetes (Helm)

```bash
helm repo add dify https://langgenius.github.io/dify-helm
helm repo update
helm upgrade --install dify dify/dify \
  --namespace dify --create-namespace \
  -f values.yaml
```

See: https://github.com/langgenius/dify-helm

## Upgrade Procedure

```bash
cd dify/docker
git pull
docker compose pull
docker compose up -d
# Migrations run automatically on api container startup
```

> Check the release notes at https://github.com/langgenius/dify/releases for breaking changes or manual migration steps.

## Gotchas

- **Change SECRET_KEY immediately**: The default key in `.env.example` is public — using it means anyone can forge session tokens.
- **SSE / streaming**: Reverse proxies must have `proxy_buffering off` and a long `proxy_read_timeout` (3600s+) for workflow streaming to work.
- **Commons Clause**: Self-hosting for personal/organizational use is fine. Selling Dify-as-a-service requires a commercial license.
- **Vector DB migrations**: Switching vector backends after data is stored is non-trivial — pick your backend before adding data.
- **Resource usage**: The full stack (API, worker, web, db, redis, weaviate) uses ~2–4 GB RAM at minimum. Plan accordingly.
- **Sandbox isolation**: The code execution sandbox uses Linux seccomp — ensure your Docker host supports it (not all minimal VPS kernels do).
- **Weaviate schema**: If you reset the vector DB, you must re-index all knowledge bases.
- **INIT_PASSWORD**: Only applies to the very first account creation; ignored after the admin account exists.

## Links

- Homepage: https://dify.ai
- Source: https://github.com/langgenius/dify
- Self-hosting docs: https://docs.dify.ai/getting-started/install-self-hosted
- Helm chart: https://github.com/langgenius/dify-helm
- Release notes: https://github.com/langgenius/dify/releases
