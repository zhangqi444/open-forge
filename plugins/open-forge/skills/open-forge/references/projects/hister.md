# Hister

**Privacy-focused self-hosted personal search engine with full-text indexing of visited websites, local file indexing, and optional AI semantic search.**
Official site: https://hister.org
GitHub: https://github.com/asciimoo/hister

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Build from source | Go + NPM required |

---

## Inputs to Collect

### All phases
- `HISTER__SERVER__BASE_URL` — public URL (e.g. http://hister.example.com:4433)
- `HISTER__SERVER__ADDRESS` — bind address (default: 0.0.0.0:4433)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  hister:
    image: ghcr.io/asciimoo/hister:latest
    container_name: hister
    init: true
    restart: unless-stopped
    read_only: true
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    ports:
      - '4433:4433'
    volumes:
      - hister_data:/hister/data
    tmpfs:
      - /tmp:noexec,nosuid,size=64m
    environment:
      - HISTER__SERVER__ADDRESS=0.0.0.0:4433
      - HISTER__SERVER__BASE_URL=http://localhost:4433

volumes:
  hister_data:
```

### Build from source
```bash
git clone https://github.com/asciimoo/hister
cd hister
./manage.sh build
# or: go generate ./...; go build
```

### Ports
- `4433` — web UI

### Data
- Volume: hister_data (persistent search index)

### Features
- Full-text indexing of browsed pages (via browser extension or crawler)
- Local file indexing
- Advanced query language: https://hister.org/docs/query-language
- Multi-user support
- Optional semantic search (AI-enhanced)
- MCP server for AI agent integration
- Headless browser or traditional crawler for bulk indexing

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Docker image runs with hardened security (read_only, no-new-privileges, all caps dropped) — don't remove these without reason
- Set BASE_URL correctly or browser extension / crawler links will break
- License: AGPLv3 or later

---

## References
- Documentation: https://hister.org/docs
- Query language: https://hister.org/docs/query-language
- GitHub: https://github.com/asciimoo/hister#readme
