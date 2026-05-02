# Photofield

**What it is:** Self-hosted photo gallery focused on speed and scale. Single-binary server that displays thousands of photos simultaneously in a seamless zoomable interface. Non-invasive — never modifies original files. Optional AI semantic search, tagging, reverse geolocation, and video support.

**Official site:** https://photofield.dev  
**Quick Start:** https://photofield.dev/quick-start  
**Demo:** https://demo.photofield.dev  
**GitHub:** https://github.com/SmilyOrg/photofield  
**License:** See repo

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Official images available |
| Any Linux VPS/VM | Binary | Single static binary, no runtime deps |
| Bare metal | Binary | Same as above |
| NAS (Synology, etc.) | Docker or binary | Re-uses Synology Moments/Photo Station thumbnails |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Photos directory | Path to existing photo library (mounted read-only recommended) |
| Data/cache directory | Where SQLite cache and thumbnails are stored |
| Listen port | Default: `8080` |

---

## Software-Layer Concerns

- **Single SQLite database** for cache, thumbnails, and metadata — persist separately from photos
- **Read-only photo mount recommended** — Photofield never writes to original files, but mounting read-only enforces this guarantee
- **Thumbnail sources supported:**
  - Extracted from JPEG EXIF data
  - Synology Moments / Photo Station pre-generated thumbnails
  - SQLite-stored small thumbnails (generated on first index)
  - FFmpeg for on-the-fly video/format conversion
- **Indexing:** Runs at 1,000–10,000 files/sec on fast SSD; EXIF extraction follows at ~200 files/sec
- **Collections** are directory-based — file system is the source of truth
- **No user accounts or auth built in** — add a reverse proxy with auth (e.g., Authelia, Caddy basic auth) if exposing beyond localhost

### Optional features requiring extra config

| Feature | Requirement |
|---------|-------------|
| Semantic search | [photofield-ai](https://github.com/SmilyOrg/photofield-ai) sidecar |
| Tagging | Enable in config (alpha feature) |
| Reverse geolocation | Embedded by default (~50k places via tinygpkg) |
| Video transcoding | FFmpeg — on-the-fly conversion supported |

---

## Example Docker Compose

```yaml
services:
  photofield:
    image: smilyorg/photofield
    container_name: photofield
    ports:
      - "8080:8080"
    volumes:
      - /path/to/photos:/photos:ro
      - photofield_data:/app/data
    restart: unless-stopped

volumes:
  photofield_data:
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. For binary: download new release from GitHub, replace binary, restart

---

## Gotchas

- **Not optimized for many concurrent users** — server-side state per client means CPU/memory issues with several simultaneous users
- **Initial page load can be slow** — first layout calculation for a large collection is CPU/IO intensive; subsequent loads use cache
- **No permalinks survive database wipe or file moves** — deep links break if you move photos or delete the cache database
- **No authentication** — must be combined with a reverse proxy auth layer for any internet-facing deployment
- **Video transcoding** requires FFmpeg installed (or in the Docker image); on-the-fly only, no pre-transcoding queue
- Layouts are window-size-dependent — different browser window sizes generate separate layout caches

---

## Links

- Website: https://photofield.dev
- Quick Start: https://photofield.dev/quick-start
- Demo: https://demo.photofield.dev
- GitHub: https://github.com/SmilyOrg/photofield
