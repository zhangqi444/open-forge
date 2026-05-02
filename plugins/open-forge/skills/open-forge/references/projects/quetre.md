# Quetre

**Privacy-respecting alternative front-end for Quora**
Official site: https://github.com/zyachel/quetre

Quetre proxies Quora content without ads, trackers, or browser fingerprinting. Fully responsive, supports dark/light themes, and exposes an unofficial JSON API. Built with Node.js; optionally caches via Redis.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | App + optional Redis cache |
| VPS / bare metal | Node.js (pnpm/npm) | Manual install, Redis optional |

## Inputs to Collect

### Phase: Pre-deployment
- `PORT` — listening port (default: `3000`)
- `CACHE_PERIOD` — cache duration e.g. `1h` (default: `1h`)

### Phase: Optional
- `REDIS_URL` — Redis host:port for response caching (e.g. `redis:6379`)
- `REDIS_TTL` — TTL in seconds (default: `3600`)

## Software-Layer Concerns

**Config file:** `.env` (copy from `.env.example`)

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `PORT` | HTTP listening port |
| `NODE_ENV` | Set to `production` for deployment |
| `CACHE_PERIOD` | How long to cache Quora responses |
| `REDIS_URL` | Optional Redis for response caching |
| `REDIS_TTL` | Redis entry TTL in seconds |

**Docker Compose note:** The upstream docker-compose.yml builds from source (`Dockerfile`). No prebuilt official image — must clone the repo.

**Alternative images:**
- PussTheCat.org image: https://github.com/PussTheCat-org/docker-quetre-quay
- Codeberg image: https://codeberg.org/video-prize-ranch/-/packages/container/quetre/latest

## Upgrade Procedure

1. Pull latest source: `git pull`
2. Rebuild container: `docker-compose build && docker-compose up -d`
3. Or for manual installs: `pnpm install && pnpm start`

## Gotchas

- **Quora may block scraping** — Quetre relies on scraping Quora's internal API; upstream changes can break functionality without notice
- **No persistent storage** — stateless; Redis cache is optional and ephemeral
- **Redis optional but recommended** — reduces Quora requests and improves response time
- **Builds from source** — no official Docker Hub image; must build locally or use community images
- **Active development slow** — maintainer has limited free time; check issues before deploying for production use

## References
- Upstream README: https://github.com/zyachel/quetre/blob/HEAD/README.md
- Docker Compose: https://github.com/zyachel/quetre/blob/HEAD/docker-compose.yml
