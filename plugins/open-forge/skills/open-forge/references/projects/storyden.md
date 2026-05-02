---
name: storyden-project
description: Storyden recipe for open-forge. Covers Docker single-container and Docker Compose (with Postgres + Redis + MinIO + Weaviate) deployment of this modern community platform. Based on upstream README and docker-compose.yml at https://github.com/Southclaws/storyden.
---

# Storyden

Modern community platform — forum, wiki, link directory, and knowledgebase in one. Built in Go with a React/Next.js frontend. Upstream: <https://github.com/Southclaws/storyden>. Docs: <https://www.storyden.org/docs>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker (single container) | Quickstart: `docker run -p 8000:8000 ghcr.io/southclaws/storyden` |
| Any Linux host / VPS | Docker Compose (full stack) | Upstream `docker-compose.yml` includes Postgres, Redis, MinIO, Weaviate |
| Fly.io | Fly Deploy | Upstream uses Fly for their own live instance (makeroom.club) |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Public URL for your Storyden instance?" | URL | Sets `PUBLIC_API_ADDRESS` and `PUBLIC_WEB_ADDRESS` |
| database | "Postgres connection string?" | DSN | Used when running standalone (not full compose stack) |
| storage | "Asset storage type — local or S3?" | `local` / `s3` | Sets `ASSET_STORAGE_TYPE`; S3 needs additional vars |
| email | "Email provider?" | `smtp` / other | Sets `EMAIL_PROVIDER`; SMTP needs host/port/credentials |
| ai (optional) | "Language model provider?" | `openai` / none | Sets `LANGUAGE_MODEL_PROVIDER`; needs API key |

## Software-layer concerns

### Key environment variables (from upstream fly.toml and docker-compose.yml)

| Variable | Description |
|---|---|
| `PUBLIC_API_ADDRESS` | Full public URL of the API (e.g. `https://community.example.com`) |
| `PUBLIC_WEB_ADDRESS` | Full public URL of the frontend |
| `EMAIL_PROVIDER` | Email transport (`smtp`) |
| `ASSET_STORAGE_TYPE` | `local` or `s3` |
| `LANGUAGE_MODEL_PROVIDER` | `openai` or unset |
| `MCP_ENABLED` | Enable Model Context Protocol integration (`true`/`false`) |
| `SEMDEX_PROVIDER` | Semantic indexing backend (`pinecone` or unset) |

### Docker Compose services (upstream dev compose)

```yaml
services:
  postgres:
    image: postgres:18-alpine
    environment:
      POSTGRES_USER: default
      POSTGRES_PASSWORD: default

  redis:
    image: redis:8.0-M02-alpine

  minio:
    image: quay.io/minio/minio
    command: server /data --console-address ":9001"
    volumes:
      - ./data/minio:/data

  weaviate:   # optional: semantic search
    image: cr.weaviate.io/semitechnologies/weaviate:1.33.3
    volumes:
      - ./data/weaviate:/var/lib/weaviate
```

### Quick single-container start

```bash
docker run -p 8000:8000 ghcr.io/southclaws/storyden
```

Opens at <http://localhost:8000>. Uses in-memory/SQLite by default — not suitable for production.

### Volumes

| Path | Purpose |
|---|---|
| `./data/minio` | Object storage (uploads, images) |
| `./data/weaviate` | Semantic search index |
| Postgres volume | User data, posts, threads |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Storyden uses calendar-based versioning (`v1.YY.N`). Breaking changes are documented in release notes.

## Gotchas

- The upstream `docker-compose.yml` is a **development** compose; it does not include the Storyden app container itself — the app is built from source or run separately.
- For production, use the pre-built image `ghcr.io/southclaws/storyden` and supply your own Postgres/Redis.
- Both `PUBLIC_API_ADDRESS` and `PUBLIC_WEB_ADDRESS` must be set correctly for login, OAuth callbacks, and asset URLs to work.
- Weaviate and MinIO are optional; omit them if you don't need semantic search or S3-style storage.
- Storyden does not use semantic versioning — `v1.` is always `1`; don't interpret minor/patch as stability indicators.
- Put behind a TLS-terminating reverse proxy (nginx/Caddy) — the container listens on plain HTTP port `8000`.

## Links

- Upstream repo: <https://github.com/Southclaws/storyden>
- Docs: <https://www.storyden.org/docs>
- VPS self-hosting guide: <https://www.storyden.org/docs/introduction/vps>
- Container image: `ghcr.io/southclaws/storyden`
