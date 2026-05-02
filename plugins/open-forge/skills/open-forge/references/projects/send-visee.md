---
name: send-visee-project
description: Send (timvisee fork) recipe for open-forge. Covers Docker and Docker Compose deployment of this encrypted file sharing service (Firefox Send fork). Based on upstream README and docs/docker.md at https://gitlab.com/timvisee/send.
---

# Send (timvisee fork)

Encrypted, self-destructing file sharing — a community-maintained fork of Mozilla's discontinued Firefox Send. Files are encrypted in the browser before upload; links expire after a configurable number of downloads or time period. Upstream: <https://gitlab.com/timvisee/send>. Docker docs: <https://gitlab.com/timvisee/send/-/blob/master/docs/docker.md>. Also compatible with [`ffsend`](https://github.com/timvisee/ffsend) CLI.

> ⚠️ **Public exposure risk**: Long expiration times on public servers can attract abuse (free file hosting, malware distribution). Consider restricting to LAN/intranet, adding proxy-level auth, or setting `SEND_FOOTER_DMCA_URL` for takedown requests.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker (single container) | Image `registry.gitlab.com/timvisee/send:latest` |
| Any Linux host / VPS | Docker Compose | See [send-docker-compose](https://github.com/timvisee/send-docker-compose) community repo |
| Any Linux host / VPS | Bare metal (Node.js 16+) | `npm install && npm start`; requires Redis |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Public HTTPS URL for Send?" | URL | Sets `BASE_URL` (e.g. `https://send.example.com`) — required for correct share links |
| storage | "Storage backend — local filesystem or S3?" | `local` / `s3` | Local: set `FILE_DIR`; S3: set `S3_BUCKET` + credentials |
| storage | "S3 bucket name (if using S3)?" | Free-text | Sets `S3_BUCKET`; also set `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` |
| storage | "S3 endpoint (if using non-AWS S3-compatible storage)?" | URL | Sets `S3_ENDPOINT` (e.g. Backblaze B2, MinIO) |
| redis | "Redis host?" | Hostname | Sets `REDIS_HOST`; Redis is required for metadata |
| limits | "Max file size in bytes?" | Integer | Sets `MAX_FILE_SIZE`; default `2147483648` (2 GB) |
| limits | "Max expiry time in seconds?" | Integer | Sets `MAX_EXPIRE_SECONDS`; default `604800` (7 days) |
| limits | "Max downloads per file?" | Integer | Sets `MAX_DOWNLOADS`; default `100` |
| dmca | "DMCA/abuse contact URL (recommended for public instances)?" | URL | Sets `SEND_FOOTER_DMCA_URL`; shown in footer |

## Software-layer concerns

### Key environment variables (from upstream docs/docker.md)

**Server:**

| Variable | Default | Description |
|---|---|---|
| `BASE_URL` | — | Full HTTPS URL where the app is served |
| `DETECT_BASE_URL` | `false` | Autodetect base URL from browser if `BASE_URL` unset |
| `PORT` | `1443` | Port the server listens on |
| `NODE_ENV` | `production` | Run mode; use `production` for deployments |
| `SEND_FOOTER_DMCA_URL` | — | Abuse contact URL shown in footer |

**Upload/Download limits:**

| Variable | Default | Description |
|---|---|---|
| `MAX_FILE_SIZE` | `2147483648` | Max upload in bytes (2 GB) |
| `MAX_EXPIRE_SECONDS` | `604800` | Max expiry in seconds (7 days) |
| `MAX_DOWNLOADS` | `100` | Max download count |
| `DEFAULT_DOWNLOADS` | `1` | Default download limit in UI |
| `DEFAULT_EXPIRE_SECONDS` | `86400` | Default expiry in UI (1 day) |
| `EXPIRE_TIMES_SECONDS` | — | CSV of expiry options (e.g. `3600,86400,604800`) |
| `DOWNLOAD_COUNTS` | — | CSV of download count options |

**Storage:**

| Variable | Description |
|---|---|
| `FILE_DIR` | Local upload directory inside container (default `/uploads`) |
| `REDIS_HOST` | Redis hostname (required) |
| `REDIS_PORT` | Redis port (default `6379`) |
| `REDIS_PASSWORD` | Redis password (if set) |
| `S3_BUCKET` | S3 bucket name (S3 storage only) |
| `S3_ENDPOINT` | Custom S3-compatible endpoint (non-AWS) |
| `AWS_ACCESS_KEY_ID` | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key |

### Docker quickstart (from upstream docs/docker.md)

```bash
docker run -v $PWD/uploads:/uploads -p 1443:1443 \
    -e 'DETECT_BASE_URL=true' \
    -e 'REDIS_HOST=<redis-host>' \
    -e 'FILE_DIR=/uploads' \
    registry.gitlab.com/timvisee/send:latest
```

### Docker Compose (community repo pattern)

See <https://github.com/timvisee/send-docker-compose> for a maintained Compose example. Basic pattern:

```yaml
services:
  send:
    image: registry.gitlab.com/timvisee/send:latest
    restart: unless-stopped
    ports:
      - "1443:1443"
    volumes:
      - ./uploads:/uploads
    environment:
      - BASE_URL=https://send.example.com
      - FILE_DIR=/uploads
      - REDIS_HOST=redis
    depends_on:
      - redis
  redis:
    image: redis:alpine
    restart: unless-stopped
```

### Volumes

| Path | Purpose |
|---|---|
| `/uploads` | File upload storage (local filesystem mode) |

## Upgrade procedure

```bash
docker pull registry.gitlab.com/timvisee/send:latest
docker compose up -d
```

Uploads and Redis metadata are preserved in volumes. No database migrations needed.

## Gotchas

- Redis is **required** regardless of storage backend — it stores file metadata, download counts, and expiry.
- `BASE_URL` must be an HTTPS URL in production; HTTP will cause browser warnings and may break the Web Crypto API used for client-side encryption.
- Default port is `1443`, not `443` or `80` — map to your preferred host port and put behind a reverse proxy.
- File encryption happens entirely in the browser — the server never sees plaintext file contents.
- `DETECT_BASE_URL=true` is a convenience for development; in production, explicitly set `BASE_URL`.
- For S3-compatible storage (Backblaze B2, MinIO, etc.), set `S3_USE_PATH_STYLE_ENDPOINT=true` if using path-style URLs.
- The upstream docker-compose.yml in the repo includes Selenium for testing — do not use it for production deployment; use the community [send-docker-compose](https://github.com/timvisee/send-docker-compose) instead.

## Links

- Upstream GitLab repo: <https://gitlab.com/timvisee/send>
- Docker docs: <https://gitlab.com/timvisee/send/-/blob/master/docs/docker.md>
- Docker Compose community repo: <https://github.com/timvisee/send-docker-compose>
- Container registry: `registry.gitlab.com/timvisee/send:latest`
- `ffsend` CLI: <https://github.com/timvisee/ffsend>
- All config options: <https://gitlab.com/timvisee/send/-/blob/master/server/config.js>
