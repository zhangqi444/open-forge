---
name: pigallery-2
description: PiGallery 2 recipe for open-forge. Directory-first photo gallery website optimized for low-resource servers — shows your folder structure as-is, read-only, fast. Docker/Node.js install. Upstream: https://github.com/bpatrik/pigallery2
---

# PiGallery 2

Fast, directory-first photo gallery website optimized for low-resource servers (especially Raspberry Pi). Point it at your existing photo directory structure and it creates a beautiful gallery — read-only, no moving or modifying your files.

2,174 stars · MIT

Upstream: https://github.com/bpatrik/pigallery2
Website: https://bpatrik.github.io/pigallery2/
Docs: https://bpatrik.github.io/pigallery2/
Demo: https://pigallery2.onrender.com/
Docker Hub: https://hub.docker.com/r/bpatrik/pigallery2

## What it is

PiGallery 2 provides a lightweight photo gallery:

- **Directory-first** — Reads and shows your existing folder structure as-is; no database migration of files
- **Read-only** — Never modifies your photo directory
- **Fast** — Optimized for Raspberry Pi and low-powered servers; efficient thumbnail caching
- **Photo & video support** — JPEG, PNG, GIF, WebP, HEIC, MP4, and more
- **GPS map** — Show photos on a map using EXIF GPS data
- **Search** — Full-text search across filenames, EXIF data, and GPS locations
- **Slideshow** — Automatic slideshow mode
- **Video transcoding** — Optional ffmpeg-based transcoding for browser playback
- **Face detection** — Optional face recognition (requires additional setup)
- **Metadata** — EXIF data display (camera, lens, settings, location)
- **Sharing** — Share albums/photos via public links
- **Albums** — Virtual albums using saved searches
- **Random photo** — Random photo endpoint for screensavers
- **Multi-user** — User accounts with per-user access to directories
- **Dark mode** — Automatic system-preference dark mode
- **Mobile responsive** — Works well on phones and tablets
- **PWA** — Installable as a progressive web app

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | Recommended; official image |
| Docker Compose | With reverse proxy | Add Nginx/Traefik for HTTPS |
| Node.js | npm start | For development or bare-metal |

## Inputs to collect

### Phase 1 — Pre-install
- Photo directory path to mount read-only into container
- Thumbnail cache directory (for storing generated thumbnails)
- Port to expose (default: 80)
- Admin username and password

## Software-layer concerns

### Ports
- 80 — HTTP (inside container); map to any external port

### Config paths
- /app/data/config/config.json — main configuration (auto-created; mount as volume)
- /app/data/db/ — SQLite database for metadata cache
- /app/data/cache/ — Generated thumbnails

### Key config options (config.json, set via web UI)
  Users, admin password, album directory path, thumbnail settings, video transcoding

### Docker run
  docker run -d \
    --name pigallery2 \
    -p 8080:80 \
    -v /path/to/photos:/app/data/images:ro \
    -v ./config:/app/data/config \
    -v ./cache:/app/data/cache \
    bpatrik/pigallery2:latest

### Docker Compose
  version: '3'
  services:
    pigallery2:
      image: bpatrik/pigallery2:latest
      container_name: pigallery2
      restart: unless-stopped
      ports:
        - "8080:80"
      volumes:
        - /path/to/photos:/app/data/images:ro
        - ./config:/app/data/config
        - ./cache:/app/data/cache
      environment:
        - NODE_ENV=production

Access at http://localhost:8080
First run: log in with admin / admin, then change password in settings.

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name photos.example.com;
    client_max_body_size 0;
    location / {
      proxy_pass http://localhost:8080;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }

## Upgrade procedure

1. docker pull bpatrik/pigallery2:latest
2. docker compose up -d --force-recreate pigallery2
3. No database migration needed for most updates — thumbnail cache is regenerated on demand

## Gotchas

- Default admin/admin — change the admin password immediately after first login
- Read-only mount — always mount your photo directory with :ro to prevent any accidental writes
- Initial scan is slow — the first full scan of a large library (10k+ photos) takes significant time; thumbnails are generated lazily on demand after that
- HEIC support — HEIC/HEIF from iPhones may need additional codecs (sharp + libheif); check Docker image notes for support status
- Video transcoding — requires ffmpeg in the container; enabled by default in official image but transcoding large videos is CPU-intensive
- Cache directory size — thumbnail cache can grow to 20-50% of original photo library size depending on settings
- Native install unsupported — the project recommends Docker; native Node.js install is possible but not officially supported
- Face detection — optional feature requiring separate ML model setup; not enabled by default

## Links

- Upstream README: https://github.com/bpatrik/pigallery2/blob/master/README.md
- Documentation: https://bpatrik.github.io/pigallery2/
- Docker Hub: https://hub.docker.com/r/bpatrik/pigallery2
- Configuration guide: https://bpatrik.github.io/pigallery2/user-guide/configuration
- Demo: https://pigallery2.onrender.com/
