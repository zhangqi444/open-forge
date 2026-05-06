---
name: homegallery
description: HomeGallery recipe for open-forge. Self-hosted personal photo and video gallery with AI-powered image discovery, face detection, tagging, and mobile-friendly UI. Source: https://github.com/xemle/home-gallery
---

# HomeGallery

Self-hosted open-source web gallery for browsing personal photos and videos. Features AI-powered image similarity search, face detection, tagging, mobile-friendly UI, and multi-source media directory support. Reads media directly from local directories without importing/copying files. Upstream: https://github.com/xemle/home-gallery. Docs: https://home-gallery.org/docs/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose | Docker | Recommended. Official images for gallery + AI API server. |
| Single binary | Linux / macOS / Windows | Prebuilt binary — no Docker required. |
| NPM (source) | Node.js 18+ | For development or customization. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Media source directories?" | Paths to photo/video directories (e.g. ~/Pictures, /mnt/nas/photos) |
| setup | "Port to expose gallery on?" | Default: 3000 |
| hardware | "Device type?" | Raspberry Pi / SBC → use BACKEND=wasm; x86 server → use BACKEND=node for best AI performance |

## Software-layer concerns

### Docker Compose (recommended)

  mkdir homegallery && cd homegallery

  # Create docker-compose.yml:
  services:
    api:
      image: xemle/home-gallery-api-server
      environment:
        - BACKEND=wasm          # wasm: good for ARM64/amd64; node: best for amd64
    gallery:
      image: xemle/home-gallery
      environment:
        - GALLERY_API_SERVER=http://api:3000
        - GALLERY_API_SERVER_CONCURRENT=1   # Use 5 on x86 servers; 1 for Raspberry Pi
        - GALLERY_API_SERVER_TIMEOUT=60     # Increase for slow SoC devices
        - GALLERY_OPEN_BROWSER=false
        - GALLERY_WATCH_POLL_INTERVAL=300   # Polling interval for file changes (seconds)
      volumes:
        - ./data:/data
        - /home/user/Pictures:/data/Pictures    # Mount your media directories here
        # Add more source dirs:
        # - /mnt/nas/photos:/data/NAS
      ports:
        - "3000:3000"
      user: "${CURRENT_USER}"   # Run as your user to read media files
      entrypoint: ['node', '/app/gallery.js']
      command: ['run', 'server']

  # Set CURRENT_USER before starting:
  export CURRENT_USER=$(id -u):$(id -g)
  docker compose up -d

### Single binary install (no Docker)

  # Linux:
  curl -sL https://dl.home-gallery.org/dist/latest/home-gallery-latest-linux-x64 -o gallery
  chmod 755 gallery

  # Init with your media source
  ./gallery init --source ~/Pictures

  # Start the server (http://localhost:3000)
  ./gallery run server

  # macOS:
  curl -sL https://dl.home-gallery.org/dist/latest/home-gallery-latest-darwin-x64 -o gallery
  chmod 755 gallery
  ./gallery init --source ~/Pictures
  ./gallery run server

### Multiple media sources

  # Add more sources after init:
  ./gallery config --add-source /mnt/nas/photos

### Key data directory layout (Docker: /data, binary: ~/.local/share/home-gallery)

  /data/
    gallery.config.yml    - configuration file (sources, API server URL, etc.)
    .index/               - file index (fast rescan without re-reading all files)
    .cache/               - image thumbnails and preview files
    .database/            - media metadata database

### AI features

The api-server container handles:
- Image similarity (vector embeddings)
- Face detection and clustering
- Object/scene recognition

First run processes all media — can take hours for large libraries. Progress shown in logs.

## Upgrade procedure

  # Docker:
  docker compose pull
  docker compose up -d

  # Binary:
  curl -sL https://dl.home-gallery.org/dist/latest/home-gallery-latest-linux-x64 -o gallery
  chmod 755 gallery
  # Data directory is preserved; restart server

## Gotchas

- **CURRENT_USER env var**: the gallery container must run as a user that can read your media directories. Set `user: "${CURRENT_USER}"` and export before `docker compose up`.
- **First-run indexing is slow**: AI processing of large libraries (10k+ photos) can take many hours. The gallery is usable while indexing continues.
- **BACKEND=wasm vs node**: on Raspberry Pi use wasm (better ARM support); on x86 use node for fastest AI inference. cpu backend works everywhere but is slowest.
- **Poll interval vs inotify**: GALLERY_WATCH_POLL_INTERVAL=0 uses inotify (faster change detection) but may not work with network mounts. Use 300+ for NFS/CIFS.
- **No multi-user auth**: HomeGallery is designed for a single user. There is no user login system — it serves all media to anyone who can reach the URL. Use a reverse proxy with basic auth or restrict to LAN only.
- **Cache is large**: thumbnails and AI embeddings can consume significant disk space for large libraries. Mount /data to a volume with adequate space.
- **.index speeds rescan**: the .index file allows fast incremental scans without re-reading all media. Don't delete it.

## References

- Upstream GitHub: https://github.com/xemle/home-gallery
- Documentation: https://home-gallery.org/docs/
- Demo: https://demo.home-gallery.org
- Docker Hub: https://hub.docker.com/r/xemle/home-gallery
- Prebuilt binaries: https://dl.home-gallery.org/dist/latest/
