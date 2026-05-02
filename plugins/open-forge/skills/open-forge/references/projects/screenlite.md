# Screenlite

An open-source digital signage solution — a self-hosted alternative to proprietary digital signage platforms. Manage content, schedules, and devices from a centralised web CMS, then display content on screens via the Screenlite Player (web-based, runs in any modern browser). Built with Node.js/Fastify + TypeScript + PostgreSQL + Redis + MinIO (S3) + FFmpeg.

> ⚠️ **Pre-production:** Screenlite is publicly under active development and not yet ready for production use. Database migrations may not be incremental; you may need to reset your database between updates. The client-side experience is partially incomplete — expect bugs.

- **GitHub (CMS):** https://github.com/screenlite/screenlite
- **GitHub (Player):** https://github.com/screenlite/web-player
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Full stack: CMS + frontend + PostgreSQL + Redis + MinIO + FFmpeg |

---

## Inputs to Collect

### Deploy Phase
All environment variables are set directly in docker-compose.yml for the default setup. No separate .env file required for quick start.

Key values (from docker-compose.yml defaults):
| Service | Default credential | Notes |
|---------|--------------------|-------|
| MinIO | screenlite / screenlite | Change for any non-local deployment |
| PostgreSQL | set in compose | Check docker-compose.yml |

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
- **server** — Node.js/Fastify backend API and business logic (port 3000)
- **client** — React frontend web UI (port 3001)
- **ffmpeg-service** — Sandboxed video processing (internal port 3002)
- **postgres** — PostgreSQL database (port 5432)
- **redis** — Redis cache and queue (port 6379)
- **minio** — S3-compatible object storage (API port 9000, console port 9001)

### Data Directories (named volumes)
| Volume | Contents |
|--------|----------|
| screenlite_storage | App file storage |
| postgres_data | PostgreSQL database |
| redis_data | Redis persistence |
| minio_data | MinIO object storage |
| ffmpeg_logs | FFmpeg processing logs |

### Ports
| Port | Service |
|------|---------|
| 3000 | Backend API |
| 3001 | Frontend web UI |
| 9001 | MinIO console |

---

## Setup Steps

```bash
git clone https://github.com/screenlite/screenlite.git && cd screenlite
docker compose up -d
# Frontend: http://localhost:3001
# Backend API: http://localhost:3000
# MinIO console: http://localhost:9001 (screenlite/screenlite)
```

---

## Upgrade Procedure

```bash
git pull
docker compose build
docker compose up -d
```

> ⚠️ During active development, database migrations may be non-incremental. If the app fails to start after an update, you may need to run `docker compose down -v` (destroys all data) and start fresh.

---

## Gotchas

- **Not production-ready:** The README explicitly states Screenlite is in public development; database migrations may require resets between versions — do not rely on it for critical signage without monitoring
- **MinIO default credentials:** Default MinIO user/pass is screenlite/screenlite — change before any network exposure
- **Player is a separate app:** The Screenlite Player (https://github.com/screenlite/web-player) is deployed separately and connects to your CMS backend; you need both running for a functional signage setup
- **FFmpeg sandboxed:** Video processing runs in a dedicated container to limit surface area; this is internal and does not require external access
- **Community in early stage:** Join the Discord for support and to report issues — active community engagement is encouraged at this stage

---

## References
- GitHub (CMS): https://github.com/screenlite/screenlite
- GitHub (Player): https://github.com/screenlite/web-player
- Deployment guide: https://github.com/screenlite/screenlite/blob/HEAD/DEPLOYMENT.md
- Discord: https://discord.gg/2wW8zDjAjr
