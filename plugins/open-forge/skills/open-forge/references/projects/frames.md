# Frames

**Modern self-hosted streaming platform for personal media**
Official site: https://github.com/eleven-am/frames

Frames is a feature-rich SVOD (streaming) platform built with React and NestJS. Stream MP4 files from local storage, S3, Dropbox, or Google Drive. Includes AI-powered recommendations via OpenAI embeddings, GroupWatch synchronized viewing, automatic metadata from TMDB/Fanart, and playlist support. Requires PostgreSQL (with pgvector) and Redis.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | App + Postgres (pgvector) + Redis |
| VPS with media storage | docker-compose | Mount local media directory |
| S3/cloud media | docker-compose | Configure via setup UI post-deploy |

## Inputs to Collect

### Phase: Pre-deployment (required)
- `DATABASE_URL` — PostgreSQL connection string with pgvector (pooling)
- `DIRECT_DATABASE_URL` — Direct PostgreSQL connection string (for migrations)
- `REDIS_HOST` — Redis hostname
- `REDIS_PORT` — Redis port (default: `6379`)
- `JWT_SECRET` — Strong random secret for JWT authentication
- Media directory path to mount at `/media`

### Phase: Optional (via setup UI or env)
- `TMDB_API_KEY` — Required for media metadata (free at themoviedb.org)
- `FAN_ART_API_KEY` — Fanart.tv API key for artwork (free tier available)
- `OPEN_AI_API_KEY` — OpenAI key for AI recommendations (optional)

> **Note:** TMDB, FanArt, and optionally OpenAI API keys are practically required — the app will prompt for them during first-run setup if not set via env.

## Software-Layer Concerns

**Docker image:** `elevenam/frames:latest`

**Required PostgreSQL image:** `pgvector/pgvector:pg14` — standard `postgres` image will not work (missing vector extension)

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Connection pool URL for runtime queries |
| `DIRECT_DATABASE_URL` | Direct URL for Prisma migrations |
| `REDIS_HOST` / `REDIS_PORT` | Cache and session storage |
| `REDIS_TTL` | Cache TTL in seconds (default: `86400`) |
| `REDIS_DB` | Redis database number (default: `0`) |
| `JWT_SECRET` | Auth token signing key |

**Ports:** App listens on `3000`

**Volumes:**
- `/media` — mount your local media directory here
- PostgreSQL data volume for persistence
- Redis data volume for persistence

## Upgrade Procedure

1. Pull latest image: `docker-compose pull frames`
2. Recreate: `docker-compose up -d frames`
3. Migrations run automatically on startup via Prisma
4. Check release notes before major version upgrades

## Gotchas

- **pgvector required** — must use `pgvector/pgvector:pg14` (or pg15/pg16) image, not plain `postgres`; standard Postgres lacks the vector extension for AI recommendations
- **API keys effectively required** — TMDB and FanArt keys are needed for metadata; app will prompt during setup but won't populate library without them
- **MP4 only** — Frames streams MP4 files; other formats (MKV, AVI) are not directly supported
- **OpenAI costs money** — AI recommendation feature uses OpenAI embeddings API; disable if you don't want API charges
- **Media file integrity** — Frames reads but does not modify source files; original media is safe

## References
- Upstream README: https://github.com/eleven-am/frames/blob/HEAD/README.md
- Docker Hub: https://hub.docker.com/r/elevenam/frames
