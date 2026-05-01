# Meme Search

**Self-hosted AI-powered meme search engine — indexes your meme library using image-to-text extraction and vector embeddings so you can find memes by semantic search of their content.**
GitHub: https://github.com/neonwatty/meme-search
Discord: https://discord.gg/damGu7aEHH

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — includes app, DB, and description generator |

---

## Inputs to Collect

### Required
- Path to meme image library (host directory)

---

## Software-Layer Concerns

### Docker Compose (recommended)
```bash
git clone https://github.com/neonwatty/meme-search
cd meme-search
docker compose up
```
Access at http://localhost:3000

The compose file starts three containers: the Rails web app, PostgreSQL with pgvector, and the Python-based auto-description generator.

### Ports
- `3000` — web UI

### Linux note
On Linux, add `extra_hosts` to the `meme_search` service for inter-container communication:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

### How it works
1. Point it at your meme directory
2. It extracts text/content from images using a local image-to-text model
3. Generates vector embeddings stored in PostgreSQL (pgvector)
4. Search by semantic query — all processing is local (no external API calls)

### First run note
The first meme description generation takes longer — image-to-text model weights are downloaded and cached. Subsequent runs are faster.

### Key features
- Semantic search of meme content and text
- Meme editing, filtering, dark mode
- Drag-and-drop upload
- Meme generation (bulk and individual)
- Rescan with options
- All processing local — no data leaves your server
- Additional models downloadable from settings

### Tech stack (bare metal)
Ruby 3.4.2, Rails 8.0.4, Python 3.12, Node.js 20 LTS, PostgreSQL 17 + pgvector

---

## Upgrade Procedure

1. git pull
2. docker compose up --build

---

## Gotchas

- First-time indexing is slow while model weights download
- Linux users need `extra_hosts` entry for host.docker.internal
- PostgreSQL with pgvector is required (included in compose)

---

## References
- GitHub: https://github.com/neonwatty/meme-search#readme
- Discord: https://discord.gg/damGu7aEHH
