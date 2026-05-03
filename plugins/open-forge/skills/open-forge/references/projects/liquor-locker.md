---
name: liquor-locker
description: Liquor Locker recipe for open-forge. Home bar management app to track bottles, mixers, and fresh ingredients with optional AI-powered cocktail recommendations.
---

# Liquor Locker

Home bar management app to track bottles, mixers, and fresh ingredients. Optionally integrates with an OpenAI-compatible LLM for AI cocktail recommendations. Upstream: <https://github.com/nguyenjessev/liquor-locker>.

Built with Go (backend) and a web frontend. SQLite database. Runs as a single container on port `8080`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | README `docker-compose.yml` snippet | ✅ | Recommended production path |
| Docker Compose (local dev) | `docker-compose.local.yml` | ✅ | Local development without installing Go/Node locally |
| Docker run | `ghcr.io/nguyenjessev/liquor-locker:2` | ✅ | Quick start |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | `ALLOWED_ORIGINS` | URL | Must match the URL the app will be served on; e.g. `https://bar.example.com` |
| optional | LLM API URL + API key | Free-text (sensitive) | Any OpenAI-compatible provider (OpenAI, Anthropic, OpenRouter); configured via the web UI after deploy |

## Software-layer concerns

Single-container, SQLite-backed. The `./data` volume holds the SQLite database. LLM configuration (API URL and key) is done via the Settings page in the web UI after deployment — not via environment variables.

```yaml
services:
  liquor-locker:
    image: ghcr.io/nguyenjessev/liquor-locker:2
    ports:
      - "8080:8080"
    environment:
      - ALLOWED_ORIGINS=https://localhost:8080
    volumes:
      - ./data:/app/internal/database/data
```

Use a specific version tag (e.g. `2`, `2.1`, `2.1.0`) rather than `latest` for reproducible deployments. The project uses SemVer.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database persists in the mounted volume. No migration steps documented upstream; check release notes before upgrading major versions.

## Gotchas

- `ALLOWED_ORIGINS` must match the exact URL you'll use to access the app (including scheme and port). CORS errors will occur if this is wrong.
- AI recommendations require a model that supports tool-calling and structured responses — not all LLM providers/models qualify.
- Swagger API docs are available at `/swagger/index.html` for local development.
- The app uses SemVer — pinning to a major version tag (e.g. `2`) is a reasonable middle ground between stability and receiving minor updates.
