---
name: Webtor
description: Self-hosted web-based torrent client with instant audio/video streaming, direct download links, and personal library management. Single Docker container deployment. MIT licensed.
website: https://github.com/webtor-io/self-hosted
source: https://github.com/webtor-io/self-hosted
license: MIT
stars: 566
tags:
  - torrent
  - media-streaming
  - download
  - self-hosted
platforms:
  - Docker
---

# Webtor

Webtor is a self-hosted web-based torrent client that allows instant streaming and downloading of torrent content without a separate torrent client. Add a magnet link or torrent file, then stream video/audio directly in the browser or download individual files. Includes a personal library, Stremio integration, and automatic movie/series detection.

Source: https://github.com/webtor-io/self-hosted  
Public service: https://webtor.io  
Latest image: `ghcr.io/webtor-io/self-hosted:latest`

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker (single container) | Recommended; all-in-one image |
| Any Linux VM / VPS | Docker + external PostgreSQL | For external DB management |

## Inputs to Collect

**Phase: Planning**
- Domain or IP for external access (`DOMAIN` env var)
- Port to expose (default: `8080`)
- Data volume path (for cached torrent data)
- PostgreSQL data volume path
- Disk space budget — autocleaner thresholds (`CLEANER_FREE`, `CLEANER_KEEP_FREE`)
- Whether to expose publicly (consider legal implications in your jurisdiction)

## Software-Layer Concerns

**Quick start (local):**
```bash
docker run -d \
  -p 8080:8080 \
  -v webtor_data:/data \
  -v webtor_pgdata:/pgdata \
  --name webtor \
  --restart=always \
  ghcr.io/webtor-io/self-hosted:latest
# Access at http://localhost:8080
```

**With custom domain:**
```bash
docker run -d \
  -e DOMAIN=https://webtor.example.com \
  -p 8080:8080 \
  -v webtor_data:/data \
  -v webtor_pgdata:/pgdata \
  --name webtor \
  --restart=always \
  ghcr.io/webtor-io/self-hosted:latest
```

**Docker Compose:**
```yaml
services:
  webtor:
    image: ghcr.io/webtor-io/self-hosted:latest
    restart: always
    ports:
      - 8080:8080
    environment:
      DOMAIN: https://webtor.example.com
      CLEANER_FREE: 35%
      CLEANER_KEEP_FREE: 25%
    volumes:
      - webtor_data:/data
      - webtor_pgdata:/pgdata

volumes:
  webtor_data:
  webtor_pgdata:
```

**Key environment variables:**
| Variable | Description | Default |
|----------|-------------|---------|
| `DOMAIN` | Public URL for the instance | `http://localhost:8080` |
| `CLEANER_FREE` | Space to free when threshold hit | `35%` |
| `CLEANER_KEEP_FREE` | Free space threshold to trigger cleaner | `25%` |

**Supported streaming formats:**
- Video: `avi`, `mkv`, `mp4`, `webm`, `m4v`, `ts`, `vob`
- Audio: `mp3`, `wav`, `ogg`, `flac`, `m4a`

**Data paths (inside container):**
- Torrent/media cache: `/data`
- PostgreSQL database: `/pgdata`

**Ports:** `8080` → Web UI + API

## Upgrade Procedure

1. `docker pull ghcr.io/webtor-io/self-hosted:latest`
2. `docker stop webtor && docker rm webtor`
3. Re-run the `docker run` command (volumes are preserved)
4. Check releases: https://github.com/webtor-io/self-hosted/releases

## Gotchas

- **Legal**: Torrent streaming may involve copyrighted content — understand the legal situation in your jurisdiction before exposing publicly
- **Disk autocleaner**: The built-in cleaner removes old cached data when disk space is low; configure thresholds to avoid running out of space
- **DOMAIN variable required**: If accessing from any hostname other than `localhost`, set `DOMAIN` to your full public URL — otherwise streaming links break
- **Embedded PostgreSQL**: The all-in-one image includes a bundled PostgreSQL — production deployments may prefer an external DB for easier backup/management
- **Stremio integration**: Webtor can serve as a Stremio addon; install via the URL shown in your profile settings
- **WebSockets**: Real-time streaming progress requires WebSocket support — ensure your reverse proxy passes upgrade headers

## Links

- Upstream README: https://github.com/webtor-io/self-hosted/blob/master/README.md
- Public service: https://webtor.io
- Releases: https://github.com/webtor-io/self-hosted/releases
- SDK (embed in your site): https://github.com/webtor-io/embed-sdk-js
