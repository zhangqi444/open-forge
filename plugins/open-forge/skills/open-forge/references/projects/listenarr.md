# Listenarr

**Automated audiobook collection management — search, download, and organize audiobooks from torrent and NZB indexers. Supports qBittorrent, Transmission, SABnzbd, NZBGet, and metadata from Audible/Amazon.**
GitHub: https://github.com/Listenarrs/Listenarr
Discord: https://discord.gg/CwZ2Sqp9NF

> ⚠️ Beta software — expect breaking changes; maintain backups of important data.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Docker run | Single container |

---

## Inputs to Collect

### Required
- Audiobook library path (host)
- Download client path (host)

### Optional
- `PUID` / `PGID` — user/group for file permissions (default: root)
- `UMASK` — file creation mask (default: `022`)
- `LISTENARR_PUBLIC_URL` — public URL for Discord bot integration

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  listenarr:
    image: ghcr.io/listenarrs/listenarr:canary
    container_name: listenarr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=022
      # - LISTENARR_PUBLIC_URL=https://your-domain.com
    volumes:
      - listenarr_data:/app/config
      - /path/to/audiobooks:/audiobooks
      - /path/to/downloads:/downloads
    ports:
      - "4545:4545"
    restart: unless-stopped

volumes:
  listenarr_data:
```

### Docker run
```bash
docker run -d \
  --name listenarr \
  -p 4545:4545 \
  -e PUID=1000 -e PGID=1000 -e UMASK=022 \
  -v listenarr_data:/app/config \
  -v /path/to/audiobooks:/audiobooks \
  -v /path/to/downloads:/downloads \
  ghcr.io/listenarrs/listenarr:canary
```

### Image registry
GHCR is the preferred registry: `ghcr.io/listenarrs/listenarr`
Docker Hub mirror (`therobbiedavis/listenarr`) available for backwards compatibility.

### Tags
- `canary` — latest pre-release build (currently the most up-to-date)
- `beta` / `beta-X.Y.Z` — beta builds
- `X.Y.Z` — specific release versions
- `latest`/`stable` — coming soon

### Ports
- `4545` — web UI

### Supported audio formats
MP3, M4A, M4B, FLAC, AAC, OGG, OPUS

### Download clients
qBittorrent, Transmission, SABnzbd, NZBGet

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Project is in beta — data loss is possible; keep backups
- `PGID` defaults to the value of `PUID` if omitted
- Legacy env alias: `GID` = `PGID`, `UMASK_SET` = `UMASK`

---

## References
- GitHub: https://github.com/Listenarrs/Listenarr#readme
- Discord: https://discord.gg/CwZ2Sqp9NF
