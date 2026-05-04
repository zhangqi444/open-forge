---
name: langflow
description: Langflow recipe for open-forge. Covers Docker, pip/uv local install, and Docker Compose deployment. Visual AI workflow builder with built-in API and MCP server. Sourced from https://github.com/langflow-ai/langflow and https://docs.langflow.org/deployment-docker.
---

# Langflow

Visual platform for building and deploying AI agents and workflows. Provides a drag-and-drop builder, built-in REST API and MCP (Model Context Protocol) server, multi-agent orchestration, and integrations with all major LLMs, vector databases, and AI tools. Upstream: https://github.com/langflow-ai/langflow. Docs: https://docs.langflow.org/.

Every workflow is automatically exposed as an API endpoint and can also be turned into an MCP server tool — usable from any MCP-compatible client (Claude Desktop, Cursor, etc.).

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (single container) | https://docs.langflow.org/deployment-docker | Quickstart; no persistence across restarts without volume |
| Docker Compose | https://docs.langflow.org/deployment-docker | Production with PostgreSQL backend |
| pip / uv local | https://github.com/langflow-ai/langflow#install-locally-recommended | Dev; requires Python 3.10–3.13 |
| Langflow Desktop | https://www.langflow.org/desktop | Windows/macOS; no Python env needed |
| Cloud (DataStax Astra) | https://langflow.org | Managed; out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Docker or pip/uv local install?" | Drives method |
| storage | "Persist flows and settings across restarts?" | Docker: mount a volume or use Compose+Postgres |
| auth | "Set a superuser password?" | LANGFLOW_SUPERUSER / LANGFLOW_SUPERUSER_PASSWORD env vars |
| port | "Expose on a custom port?" | Default: 7860 |
| llm | "Which LLM provider(s) will you connect?" | API keys entered in the Langflow UI after install |

## Docker quickstart

```sh
docker run -p 7860:7860 langflowai/langflow:latest
# Open http://localhost:7860
```

With persistent storage:

```sh
docker run -p 7860:7860 \
  -v langflow-data:/app/langflow \
  langflowai/langflow:latest
```

## Docker Compose (with PostgreSQL)

```yaml
version: "3.8"
services:
  langflow:
    image: langflowai/langflow:latest
    ports:
      - "7860:7860"
    environment:
      - LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@db:5432/langflow
      - LANGFLOW_SUPERUSER=admin
      - LANGFLOW_SUPERUSER_PASSWORD=changeme
    depends_on:
      - db
    volumes:
      - langflow-data:/app/langflow

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: langflow
      POSTGRES_PASSWORD: langflow
      POSTGRES_DB: langflow
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  langflow-data:
  pgdata:
```

## Local install (pip / uv)

```sh
# Requires Python 3.10-3.13
uv pip install langflow -U
uv run langflow run
# Open http://127.0.0.1:7860
```

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| LANGFLOW_DATABASE_URL | SQLite (ephemeral) | Set to PostgreSQL URL for production |
| LANGFLOW_SUPERUSER | - | Admin username |
| LANGFLOW_SUPERUSER_PASSWORD | - | Admin password |
| LANGFLOW_HOST | 127.0.0.1 | Bind address |
| LANGFLOW_PORT | 7860 | Listen port |
| LANGFLOW_WORKERS | 1 | Number of uvicorn workers |
| LANGFLOW_AUTO_LOGIN | true | Set false to require login |
| LANGFLOW_SECRET_KEY | auto-generated | Session signing key — set explicitly in production |

## Upgrade procedure

```sh
# Docker
docker pull langflowai/langflow:latest
docker compose up -d   # if using Compose

# pip/uv
uv pip install langflow -U
```

## Gotchas

- **Default SQLite is ephemeral in Docker** — without a volume mount or PostgreSQL backend, all flows are lost on container restart.
- **LANGFLOW_AUTO_LOGIN=true by default** — anyone who can reach port 7860 is immediately logged in as admin; disable in production.
- **LANGFLOW_SECRET_KEY** — if not set, a new key is generated each startup, invalidating all user sessions. Set it explicitly.
- **MCP server** — each flow can be exposed as an MCP tool; requires the flow to be deployed/published first.
- **Component dependencies** — some components install additional Python packages on first use; container needs internet access or a pre-warmed image.
- **Workers vs async** — increase LANGFLOW_WORKERS for high concurrency; each worker is a full uvicorn process with its own memory.

## Links

- GitHub: https://github.com/langflow-ai/langflow
- Docker deployment guide: https://docs.langflow.org/deployment-docker
- Full docs: https://docs.langflow.org/
- Docker Hub: https://hub.docker.com/r/langflowai/langflow
