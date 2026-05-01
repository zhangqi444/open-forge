# Streamystats

**Statistics and analytics service for Jellyfin — watch history, library stats, user stats, AI chat with your library, embedding-based recommendations, multi-server support.**
GitHub: https://github.com/fredrikburmester/streamystats

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

---

## Inputs to Collect

### Required
- `SESSION_SECRET` — generate with `openssl rand -hex 64`
- Jellyfin server URL and API key (entered via setup wizard on first run)

### Optional
- OpenAI-compatible API key + model — for AI chat and embedding-based recommendations

---

## Software-Layer Concerns

### Docker Compose
Copy the `docker-compose.yml` from the repo, update `SESSION_SECRET`, then:
```bash
docker compose up -d
```
Access the setup wizard at http://localhost:3000 to connect your Jellyfin server.

### Ports
- `3000` — web UI

### Version tags
- `vX.Y.Z` — stable pinned releases (recommended for production)
- `latest` — tracks `main` branch; typically stable but may have breaking changes

### AI features (optional)
- Embeddings use any OpenAI-compatible API (multiple models/custom endpoints)
- Stored in vectorchord with support for any embedding dimension
- AI chat has 13 function-calling tools: recommendations, semantic search, watch stats, genre filtering, recently added, etc.

### Import from other tools
Supports importing history from Jellystat and Playback Reporting Plugin.

---

## Upgrade Procedure

1. **Take a database backup first** — schema downgrades are not supported
2. docker compose pull
3. docker compose up -d

> ⚠️ Downgrading image versions after a migration will break the app — restore from backup to rollback.

---

## Gotchas

- Database migrations run automatically on startup via the `job-server` container — wait for it to become healthy before using the app
- Downgrading is not supported without a DB backup restore — always backup before upgrading
- Playback Reporting Plugin is no longer required — Streamystats uses the Jellyfin API directly
- First load can be slow on large libraries while data syncs

---

## References
- GitHub: https://github.com/fredrikburmester/streamystats#readme
