---
name: url-to-png
description: Recipe for URL-to-PNG — self-hosted URL screenshot service. Generates PNG images from URLs via HTTP query params using Playwright/Chromium. Supports filesystem, S3, and CouchDB caching. Prometheus metrics, domain allow/block lists, encryption.
---

# URL-to-PNG

Self-hosted URL-to-screenshot service. Upstream: https://github.com/jasonraimondi/url-to-png

Node.js service using Playwright/Chromium to render URLs as PNG images, accessible via simple HTTP query params. Supports parallel rendering, configurable viewport/dimensions, mobile UA emulation, dark mode, full-page capture, caching (filesystem, S3, CouchDB), domain allow/block lists, Prometheus metrics, and optional URL encryption. MIT licensed.

Docs: https://jasonraimondi.github.io/url-to-png/

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker | `ghcr.io/jasonraimondi/url-to-png` — Playwright + Chromium included |
| Docker Compose | Recommended for persistent filesystem caching |
| Local (pnpm) | Requires Node.js + Playwright + Chromium installed locally |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Port | Default: 3089 |
| storage | Storage provider | stub (no cache), filesystem, s3, or couchdb |
| storage | IMAGE_STORAGE_PATH | If filesystem storage: host path for cached images |
| storage | AWS credentials | If s3: bucket, access key, secret, region |
| storage | CouchDB credentials | If couchdb: protocol, host, port, user, pass, db name |
| security (opt) | ALLOW_LIST | Comma-separated allowed domains (empty = all allowed) |
| security (opt) | BLOCK_LIST | Comma-separated blocked domains |
| security (opt) | CRYPTO_KEY | Encryption key for URL parameter encryption |

## API usage

```
GET http://localhost:3089?url=https://example.com
GET http://localhost:3089?url=https://example.com&width=1200&height=630
GET http://localhost:3089?url=https://example.com&isFullPage=true&isDarkMode=true
GET http://localhost:3089?url=https://example.com&isMobile=true&viewportWidth=390
```

Embed in HTML:
```html
<img src="http://localhost:3089?url=https://example.com&width=600">
```

## Software-layer concerns

**Config:** All via environment variables — no config file.

**Key env vars:**

| Var | Default | Description |
|---|---|---|
| PORT | 3089 | Listen port |
| LOG_LEVEL | debug | debug/info/warn/error |
| NODE_ENV | development | Set production in prod |
| CACHE_CONTROL | public, max-age=86400, immutable | Response Cache-Control header |
| ALLOW_LIST | (empty = all) | Comma-separated allowed domains |
| BLOCK_LIST | (empty = none) | Comma-separated blocked domains |
| BROWSER_TIMEOUT | 10000 | Playwright render timeout (ms) |
| BROWSER_WAIT_UNTIL | domcontentloaded | load / domcontentloaded / networkidle |
| POOL_MAX | 10 | Max browser connections in pool |
| DEFAULT_WIDTH | 250 | Default output image width |
| DEFAULT_HEIGHT | 250 | Default output image height |
| DEFAULT_VIEWPORT_WIDTH | 1080 | Default browser viewport width |
| STORAGE_PROVIDER | stub | stub / filesystem / s3 / couchdb |
| IMAGE_STORAGE_PATH | (required if filesystem) | Cache directory |
| METRICS | false | Enable Prometheus metrics endpoint |
| CRYPTO_KEY | (opt) | Key for URL parameter encryption |

**Chromium included:** The Docker image bundles Playwright and Chromium — no additional browser install needed.

**Security:** In public/shared environments, set ALLOW_LIST to restrict which domains can be screenshotted, or BLOCK_LIST to exclude specific domains.

## Docker Compose (with filesystem caching)

```yaml
services:
  url-to-png:
    image: ghcr.io/jasonraimondi/url-to-png:latest
    restart: unless-stopped
    ports:
      - "3089:3089"
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=info
      - STORAGE_PROVIDER=filesystem
      - IMAGE_STORAGE_PATH=/app/images
      - CACHE_CONTROL=public, max-age=86400, immutable
    volumes:
      - url_to_png_cache:/app/images

volumes:
  url_to_png_cache:
```

## Upgrade procedure

```bash
docker compose pull url-to-png
docker compose up -d url-to-png
```

Image cache (volume) is preserved. No database migrations.

## Gotchas

- **Chromium is resource-intensive** — each render spins up a headless browser. Set POOL_MAX appropriately for your hardware; more pool slots = more memory.
- **stub storage = no caching** — default storage provider does not cache renders. Set STORAGE_PROVIDER=filesystem (or s3/couchdb) in production to avoid re-rendering on every request.
- **ALLOW_LIST for public instances** — without an ALLOW_LIST, anyone who can reach the service can screenshot any URL. Restrict access or set an ALLOW_LIST.
- **JavaScript-heavy pages** — use BROWSER_WAIT_UNTIL=networkidle for SPAs that render after initial load, at the cost of longer render times.

## Links

- Upstream repository: https://github.com/jasonraimondi/url-to-png
- Full documentation: https://jasonraimondi.github.io/url-to-png/
- Config reference: https://jasonraimondi.github.io/url-to-png/config/
- Docker Hub: https://hub.docker.com/r/jasonraimondi/url-to-png
- GitHub Container Registry: https://ghcr.io/jasonraimondi/url-to-png
