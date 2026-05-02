# Minne

**What it is:** A graph-powered personal knowledge management system and read-later app. Inspired by the Zettelkasten method — captures URLs, text, PDFs, audio, and images, then uses AI to automatically build a knowledge graph with connections between concepts.

**Official URL:** https://github.com/perstarkse/minne
**License:** AGPL-3.0
**Stack:** Rust (backend, SSR) + SurrealDB

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; SurrealDB bundled |
| Homelab | Docker Compose | arm64 supported |

---

## Inputs to Collect

### Pre-deployment
- `SURREALDB_ADDRESS` — WebSocket address of SurrealDB (e.g. `ws://db:8000`)
- `SURREALDB_USERNAME` / `SURREALDB_PASSWORD` — database credentials
- `SURREALDB_DATABASE` — database name (e.g. `minne_db`)
- `OPENAI_API_KEY` — **required**; used for AI entity extraction and chat
- `OPENAI_BASE_URL` — optional; override to use Ollama or other OpenAI-compatible APIs
- `JWT_SECRET` — random string for auth token signing

### Runtime
- Content ingestion: URLs, plain text, PDFs, audio, images
- AI model selection for structured outputs (must support structured outputs)

---

## Software-Layer Concerns

**Config:** Via `config.yaml` or environment variables (env vars take precedence).

**Database:** SurrealDB — a multi-model DB used as the graph backend. Included in the Docker Compose setup.

**Default port:** `3000`

**Quick start:**
```bash
git clone https://github.com/perstarkse/minne.git
cd minne
# Edit docker-compose.yml: add OPENAI_API_KEY
docker compose up -d
# Access at http://localhost:3000
```

**Optional reranking:** Set `RERANKING_ENABLED=true` to enable FastEmbed cross-encoder reranking of search results. Downloads ~1.1 GB model on first start; adds CPU overhead. Disabled by default.

**Data persistence:** SurrealDB data dir mounted as volume — back this up regularly.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Check release notes for migration steps: https://github.com/perstarkse/minne/releases

---

## Gotchas

- **OpenAI API key is required** even for local use — or configure `OPENAI_BASE_URL` to point at a local Ollama instance running a model that supports structured outputs (e.g. `llama3.1`, `qwen2.5`)
- **Structured outputs required** — not all models support this; check compatibility before using with Ollama
- **AGPL-3.0 license** — if you modify and deploy, you must share source changes
- **Reranking downloads ~1.1 GB** on first enable — plan disk space accordingly
- Single-user focused; multi-user support is limited
- SurrealDB is not a typical SQL DB — direct DB queries require SurrealQL

---

## Links
- GitHub: https://github.com/perstarkse/minne
- Live demo: https://minne.stark.pub (read-only)
