# Loops

Loops is a federated short-video sharing platform (TikTok-style) with ActivityPub federation — the fediverse equivalent of TikTok. Built on Laravel (PHP 8.3+), MySQL, Redis, and FFmpeg for video processing. Videos and avatars require S3-compatible object storage (AWS S3, MinIO, DigitalOcean Spaces); local filesystem storage is not yet supported.

- **Official site / docs:** https://joinloops.org
- **GitHub:** https://github.com/joinloops/loops-server
- **API docs:** https://docs.joinloops.org
- **License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| VPS | Docker Compose | App + MySQL + Redis stack; S3 storage required externally |
| VPS | Bare metal | PHP 8.3+, MySQL 8.0+, Redis, FFmpeg, Node.js 18+ |

---

## Inputs to Collect

### Deploy Phase (.env)
| Variable | Required | Description |
|----------|----------|-------------|
| APP_URL | Yes | Your public domain (e.g. https://loops.example.com) |
| APP_KEY | Yes | Laravel app key — generate with: php artisan key:generate |
| DB_DATABASE | Yes | MySQL database name |
| DB_USERNAME | Yes | MySQL username |
| DB_PASSWORD | Yes | MySQL password |
| DB_ROOT_PASSWORD | Yes | MySQL root password (Docker compose only) |
| REDIS_PASSWORD | Yes | Redis password |
| AWS_ACCESS_KEY_ID | Yes | S3 access key |
| AWS_SECRET_ACCESS_KEY | Yes | S3 secret key |
| AWS_DEFAULT_REGION | Yes | S3 region (e.g. us-east-1) |
| AWS_BUCKET | Yes | S3 bucket name for video/avatar storage |
| AWS_USE_PATH_STYLE_ENDPOINT | No | Set true for MinIO/self-hosted S3 |
| AWS_URL | No | Custom S3 endpoint URL (for MinIO/DO Spaces etc.) |
| APP_ENV | No | production |
| APP_DEBUG | No | false |

### Queue and cache
| Variable | Required | Description |
|----------|----------|-------------|
| CACHE_DRIVER | No | redis (recommended) |
| QUEUE_CONNECTION | No | redis (recommended) |
| SESSION_DRIVER | No | redis (recommended) |

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
- **loops** — PHP-FPM + Laravel application (port 8080)
- **mysqldb** — MySQL 9 database
- **redis** — Redis Stack server for cache/queue/sessions

### Config
- .env at project root (copy from .env.example)
- AUTORUN_* env vars control automatic migrations/cache-building on container start
- PHP limits configurable via PHP_POST_MAX_SIZE, PHP_UPLOAD_MAX_FILE_SIZE, PHP_MEMORY_LIMIT

### Data Directories
- ./storage — Laravel storage (uploads, logs, cache) — must be persisted
- ./bootstrap/cache — Laravel bootstrap cache
- ./mysqldb-9-data — MySQL data volume
- ./redis-data — Redis AOF persistence

### Ports
- 8080 — Application (put behind reverse proxy with TLS)

### S3 Storage — Required
Loops requires S3-compatible object storage for all media. Self-hosted options:
- **MinIO** — run locally alongside Loops (set AWS_USE_PATH_STYLE_ENDPOINT=true)
- **DigitalOcean Spaces / Backblaze B2** — managed S3-compatible services

---

## Setup Steps

```bash
git clone https://github.com/joinloops/loops-server.git && cd loops-server
cp .env.example .env
# Edit .env: fill in all required variables
docker compose build
docker compose up -d
docker compose exec loops php artisan key:generate
docker compose exec loops php artisan migrate --force
docker compose exec loops php artisan storage:link
```

---

## Upgrade Procedure

```bash
git pull
docker compose build
docker compose up -d
docker compose exec loops php artisan migrate --force
docker compose exec loops php artisan optimize:clear
```

---

## Gotchas

- **S3 storage is mandatory:** Local filesystem storage is not yet implemented; you must provide S3 credentials before starting — no workaround currently
- **APP_KEY must be generated:** Run `php artisan key:generate` after first deploy; without it the app won't start
- **Federation requires public HTTPS domain:** ActivityPub federation needs a publicly reachable HTTPS URL; local/private IPs won't federate
- **FFmpeg required for video processing:** Ensure FFmpeg 4.5+ (5.0+ recommended) is available — included in the Docker image but required on bare metal
- **Queue worker needed:** Video transcoding and federation jobs run via Laravel queues; the Docker image includes a built-in worker, but on bare metal you need to run `php artisan queue:work`
- **Horizon for queue monitoring:** Loops uses Laravel Horizon for queue management — accessible at /horizon (admin only)
- **Early stage project:** Loops is actively developed; check release notes for breaking changes before upgrading

---

## References
- Installation guide: https://github.com/joinloops/loops-server/blob/main/INSTALLATION.md
- API documentation: https://docs.joinloops.org
- GitHub: https://github.com/joinloops/loops-server
- Translations: https://crowdin.com/project/loops
