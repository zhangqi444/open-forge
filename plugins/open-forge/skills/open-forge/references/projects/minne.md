# Minne

**What it is:** A graph-powered personal knowledge management (PKM) system and save-for-later app. Inspired by the Zettelkasten method, Minne uses a SurrealDB graph database to automatically create connections between notes/entities. Features AI-assisted relationship discovery, full-text + vector search, a conversational chat interface to query your knowledge base, multi-format ingestion (text, URLs, PDFs, audio, images), a visual D3 graph explorer, and a scratchpad for quick capture.

**Official URL:** https://github.com/perstarkse/minne
**Container:** Build from source (no public registry image)
**License:** AGPL-3.0
**Stack:** Rust (server-side rendering) + SurrealDB (RocksDB backend); Docker Compose

> **Note:** No pre-built Docker Hub image — must build from source.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose (build) | Clone repo and `docker compose up -d` |

---

## Inputs to Collect

### Pre-deployment (environment variables)
- `SURREALDB_USERNAME` — SurrealDB admin username (default: `root_user`)
- `SURREALDB_PASSWORD` — SurrealDB admin password (default: `root_password` — **change this**)
- `SURREALDB_DATABASE` — database name (default: `test` — rename for production)
- `SURREALDB_NAMESPACE` — namespace (default: `test` — rename for production)
- `OPENAI_API_KEY` — OpenAI API key (or any OpenAI-compatible endpoint) for AI features
- `HTTP_PORT` — app port (default: `3000`)
- `RERANKING_ENABLED` — `true`/`false`; improves search quality; requires compatible model

---

## Software-Layer Concerns

**Installation:**
```bash
git clone https://github.com/perstarkse/minne.git
cd minne
# Edit docker-compose.yml to set passwords and API key
docker compose up -d
```

**Docker Compose (from repo):**
```yaml
services:
  minne:
    build: .
    ports:
      - "3000:3000"
    environment:
      SURREALDB_ADDRESS: "ws://surrealdb:8000"
      SURREALDB_USERNAME: "root_user"
      SURREALDB_PASSWORD: "change-me"
      SURREALDB_DATABASE: "minne"
      SURREALDB_NAMESPACE: "production"
      OPENAI_API_KEY: "sk-your-key"
      HTTP_PORT: 3000
      RERANKING_ENABLED: false
    depends_on:
      - surrealdb

  surrealdb:
    image: surrealdb/surrealdb:latest
    volumes:
      - ./database:/database
    command: >
      start --log info
      --user root_user --pass root_password
      rocksdb:./database/database.db
```

**AI configuration:** Minne works with any OpenAI-compatible API that supports structured outputs. Set `OPENAI_API_KEY` and optionally configure an alternative base URL for local models (LM Studio, Ollama, etc.).

**Demo:** https://minne.stark.pub (read-only demo)

**Upgrade procedure:**
```bash
git pull
docker compose up -d --build
```

---

## Gotchas

- **Build from source** — no public Docker image; Docker build required on first run
- **`sleep 10` in startup command** — app waits 10 seconds for SurrealDB to initialize; normal behavior
- **Change default credentials** — `root_user`/`root_password` must be changed before exposing to the internet
- **AI key required for AI features** — without an `OPENAI_API_KEY`, AI-assisted entity extraction and chat won't function; basic note capture still works
- **AGPL-3.0** — modifications must be open-sourced if distributed

---

## Links
- GitHub: https://github.com/perstarkse/minne
- Demo: https://minne.stark.pub
