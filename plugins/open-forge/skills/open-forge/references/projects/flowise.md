# Flowise

Low-code drag-and-drop builder for LLM applications, AI agents, and chatflows. Build RAG pipelines, autonomous agents, multi-agent systems, and API integrations visually. 52K+ GitHub stars. Upstream: <https://github.com/FlowiseAI/Flowise>. Docs: <https://docs.flowiseai.com>.

Flowise runs as a Node.js app on port `3000` by default. Data persists to a local SQLite file or external PostgreSQL/MySQL database.

## Compatible install methods

Verified against upstream README at <https://github.com/FlowiseAI/Flowise#quick-start>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| npm (global) | `npm install -g flowise && npx flowise start` | ✅ | Quick local eval, no Docker needed |
| Docker Compose | `docker compose -f docker/docker-compose.yml up -d` | ✅ | Recommended for persistent self-hosting |
| Docker (single image) | `docker run -d -p 3000:3000 flowiseai/flowise` | ✅ | Simple single-container run |
| Railway | <https://docs.flowiseai.com/configuration/deployment/railway> | Community | 1-click cloud deploy |
| Render | <https://docs.flowiseai.com/configuration/deployment/render> | Community | 1-click cloud deploy |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| port | "Port for Flowise?" | Number (default `3000`) | All |
| auth | "Enable username/password authentication?" | `AskUserQuestion`: `Yes` / `No` | All |
| username | "Admin username?" | Free-text | When auth enabled |
| password | "Admin password?" | Free-text (sensitive) | When auth enabled |
| db | "Database type?" | `AskUserQuestion`: `SQLite (default, local)` / `PostgreSQL` / `MySQL` | All |
| db_url | "Database connection string?" | Free-text | PostgreSQL / MySQL only |

## Software-layer concerns

### Docker Compose quickstart

```bash
git clone https://github.com/FlowiseAI/Flowise
cd Flowise/docker
cp .env.example .env
# Edit .env as needed
docker compose up -d
```

Visit `http://localhost:3000`.

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `PORT` | Port to listen on | Default: `3000` |
| `FLOWISE_USERNAME` | Username for UI auth | Enables auth when set |
| `FLOWISE_PASSWORD` | Password for UI auth | Required when username is set |
| `DATABASE_TYPE` | DB type | `sqlite` (default), `postgres`, `mysql` |
| `DATABASE_HOST` | DB host | PostgreSQL/MySQL |
| `DATABASE_PORT` | DB port | PostgreSQL: `5432`, MySQL: `3306` |
| `DATABASE_USER` | DB username | PostgreSQL/MySQL |
| `DATABASE_PASSWORD` | DB password | PostgreSQL/MySQL (sensitive) |
| `DATABASE_NAME` | DB name | PostgreSQL/MySQL |
| `DATABASE_PATH` | SQLite file path | Default: `/root/.flowise` |
| `SECRETKEY_PATH` | Path for encrypted credential storage | Default: `/root/.flowise` |
| `FLOWISE_SECRETKEY_OVERWRITE` | Override the secret key | For deterministic encryption |
| `STORAGE_TYPE` | File storage type | `local` (default) or `s3` |
| `BLOB_STORAGE_PATH` | Local storage path | When `STORAGE_TYPE=local` |
| `S3_STORAGE_BUCKET_NAME` | S3 bucket | When `STORAGE_TYPE=s3` |
| `LOG_LEVEL` | Log verbosity | `error`, `warn`, `info`, `debug` |
| `DEBUG` | Debug mode | `true` / `false` |

### Minimal Docker Compose

```yaml
services:
  flowise:
    image: flowiseai/flowise:latest
    restart: always
    ports:
      - "3000:3000"
    environment:
      PORT: 3000
      FLOWISE_USERNAME: admin
      FLOWISE_PASSWORD: "${FLOWISE_PASSWORD}"
      DATABASE_TYPE: sqlite
      DATABASE_PATH: /root/.flowise
      SECRETKEY_PATH: /root/.flowise
    volumes:
      - flowise_data:/root/.flowise
    entrypoint: /bin/sh -c "sleep 3; flowise start"

volumes:
  flowise_data:
```

### What you can build

Flowise provides a node-based visual editor for:

- **Chatflows** — single-flow RAG chatbots, Q&A over documents
- **Agentflows** — multi-step autonomous agents with tool use
- **Multi-agent** — orchestrator + worker agent systems
- **API endpoints** — expose any flow as a REST API

Key node categories:
- LLMs: OpenAI, Anthropic, Ollama, Groq, Mistral, etc.
- Vector stores: Pinecone, Chroma, Weaviate, Supabase, local
- Document loaders: PDF, web scraper, GitHub, Notion, etc.
- Memory: Buffer, Window, Summary, Redis-backed
- Tools: Calculator, web search, custom functions, MCP tools

### Embedding in your app

Every Flowise chatflow can be embedded as a chatbot widget:

```html
<script type="module">
  import Chatbot from 'https://cdn.jsdelivr.net/npm/flowise-embed/dist/web.js'
  Chatbot.init({
    chatflowid: 'your-flow-id',
    apiHost: 'https://flowise.example.com',
  })
</script>
```

Or call the API directly:

```bash
curl -X POST https://flowise.example.com/api/v1/prediction/<flowId> \
  -H "Content-Type: application/json" \
  -d '{"question": "Hello!"}'
```

### Data directories

| Path | Contents |
|---|---|
| `/root/.flowise` | SQLite DB, credential secrets, local uploaded files |
| Custom `BLOB_STORAGE_PATH` | Uploaded documents for RAG |

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

SQLite database is automatically migrated. For PostgreSQL, migrations run on startup.

## Gotchas

- **Authentication is opt-in.** Without `FLOWISE_USERNAME`/`FLOWISE_PASSWORD`, the UI is open to anyone who can reach the port. Always set auth for internet-exposed deployments.
- **`entrypoint` has a `sleep 3`** in the upstream docker-compose. This is intentional — gives time for any startup dependencies to settle.
- **SQLite default is single-process only.** For high concurrency or multiple Flowise instances, use PostgreSQL.
- **Credentials are encrypted.** API keys you enter in Flowise (OpenAI, Pinecone, etc.) are stored encrypted using `SECRETKEY_PATH`. If you lose this key, stored credentials cannot be decrypted.
- **S3 required for multi-instance file storage.** If you run multiple Flowise containers (behind a load balancer), use `STORAGE_TYPE=s3` so all instances share the same file storage.
- **License: Apache 2.0.** Fully open-source.

## Links

- Upstream: <https://github.com/FlowiseAI/Flowise>
- Docs: <https://docs.flowiseai.com>
- Docker Compose: <https://github.com/FlowiseAI/Flowise/tree/main/docker>
- Embedding docs: <https://docs.flowiseai.com/using-flowise/embed>
- API reference: <https://docs.flowiseai.com/using-flowise/api>
