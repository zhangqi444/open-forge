# Transmute

**Self-hosted file converter supporting 2,000+ format conversions — images, video, audio, JSON, Excel, and more.**

- **Official site:** https://transmute.sh
- **GitHub:** https://github.com/transmute-app/transmute
- **License:** See repo

## What It Is

Transmute is a web-based file conversion service you run on your own infrastructure. It accepts uploads and converts between over 2,000 format combinations across images, video, audio, documents, spreadsheets, and structured data files. No files leave your network.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS/VM | Docker Compose | Official image via GHCR |
| Any VPS/VM | Docker | Single container |

## Inputs to Collect

### All phases
- Port to expose (default: `3313`)
- Volume path for persistent data

## Software-Layer Concerns

- **Image:** `ghcr.io/transmute-app/transmute:latest`
- **Port:** `3313` (HTTP)
- **Data volume:** `/app/data` inside container — mount for persistence
- **Health check:** `GET /api/health/ready` — used by the built-in Docker healthcheck
- **Stack:** Python backend + frontend; requires no external database

### docker-compose.yml (from upstream)
```yaml
services:
  transmute:
    image: ghcr.io/transmute-app/transmute:latest
    container_name: transmute
    restart: unless-stopped
    ports:
      - "3313:3313"
    volumes:
      - transmute_data:/app/data
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "/dev/null", "--tries=1", "http://localhost:3313/api/health/ready"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  transmute_data:
```

## Upgrade Procedure

1. Pull the new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Verify `/api/health/ready` returns 200

## Gotchas

- **Conversion dependencies:** Heavy format conversions (video, audio) require FFmpeg and LibreOffice baked into the image — the official GHCR image includes these; building from source requires them installed
- **Resource usage:** Video conversions are CPU-intensive; size your host appropriately
- **No auth by default:** Place behind a reverse proxy with authentication if exposing beyond localhost
- **Temp file cleanup:** Converted files are stored temporarily in `/app/data`; disk usage grows with conversion volume

## References

- Site: https://transmute.sh
- GitHub: https://github.com/transmute-app/transmute
- Docker image: ghcr.io/transmute-app/transmute:latest
