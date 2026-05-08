---
name: mytube-project
description: MyTube recipe for open-forge. Self-hosted yt-dlp-backed video downloader and media library with subscriptions, RSS feeds, and TMDB metadata. Docker Compose (two-container or single-container). Based on upstream README and Docker guide at https://github.com/franklioxygen/MyTube.
---

# MyTube

Self-hosted video downloader and media player for YouTube, Bilibili, Twitch, and any yt-dlp-supported site. Features channel subscriptions with auto-download, local library with TMDB metadata, RSS feed generation, and built-in Cloudflare Tunnel support. Node.js + SQLite backend, React frontend. MIT. Upstream: https://github.com/franklioxygen/MyTube. Images: ghcr.io/franklioxygen/mytube and franklioxygen/mytube.

Note: 100% AI-generated codebase (upstream's own description). Active development; review release notes before upgrading.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (two-container: backend + frontend) | Default; separate images for backend and frontend |
| Docker Compose (single-container) | Simplest; frontend static assets bundled into backend image |
| Manual (Node.js) | Development or environments without Docker |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Single-container or two-container?" | Single / Two | Single is simpler for small installs |
| config | "Admin trust level?" | application / container / host | See deployment-security-model.md; container is default |
| config | "PUID/PGID for file ownership?" | Integer pair (default 1000:1000) | Matches host UID/GID for bind-mounted volumes |
| storage | "Directory for uploads?" | Host path | Mounted to /app/uploads |
| storage | "Directory for data (DB)?" | Host path | Mounted to /app/data |
| network | "Port to expose (frontend)?" | Number (default 5556) | Two-container: frontend port |
| network | "Port to expose (backend API)?" | Number (default 5551) | Two-container: backend port |
| optional | "TMDB API key?" | String | For automatic metadata scraping from filename |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Node.js (TypeScript) backend + React frontend |
| Database | SQLite (auto-created at /app/data/mytube.db) |
| Video downloads | yt-dlp bundled in Docker image |
| Deno runtime | Included for yt-dlp JS challenge solving; ~90MB overhead |
| Data dirs | /app/uploads (video files) and /app/data (SQLite DB, config) |
| Port (backend) | 5551 |
| Port (frontend) | 5556 |
| Auth | Built-in login with passkeys (WebAuthn) support; visitor read-only role available |
| Architectures | amd64 and arm64 (automatic) |

## Install: Docker Compose (two-container -- default)

Source: https://github.com/franklioxygen/MyTube/blob/master/documents/en/docker-guide.md

```yaml
services:
  backend:
    image: franklioxygen/mytube:backend-latest
    container_name: mytube-backend
    pull_policy: always
    restart: unless-stopped
    ports:
      - "5551:5551"
    networks:
      - mytube-network
    environment:
      - PORT=5551
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - MYTUBE_ADMIN_TRUST_LEVEL=container
    volumes:
      - ./uploads:/app/uploads
      - ./data:/app/data

  frontend:
    image: franklioxygen/mytube:frontend-latest
    container_name: mytube-frontend
    pull_policy: always
    restart: unless-stopped
    ports:
      - "5556:5556"
    depends_on:
      - backend
    networks:
      - mytube-network
    environment:
      - VITE_API_URL=/api
      - VITE_BACKEND_URL=

networks:
  mytube-network:
    driver: bridge
```

```bash
docker compose up -d
# Frontend: http://localhost:5556
# Backend API: http://localhost:5551
```

## Install: Docker Compose (single-container)

Frontend assets bundled in the GHCR image:

```yaml
services:
  mytube:
    image: ghcr.io/franklioxygen/mytube:latest
    container_name: mytube
    pull_policy: always
    restart: unless-stopped
    ports:
      - "5551:5551"
    environment:
      - PORT=5551
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - MYTUBE_ADMIN_TRUST_LEVEL=container
    volumes:
      - ./uploads:/app/uploads
      - ./data:/app/data
```

```bash
docker compose up -d
# Access: http://localhost:5551
```

## Install: Manual (Node.js)

Source: https://github.com/franklioxygen/MyTube/blob/master/documents/en/getting-started.md

Requirements: Node.js 18+, Python 3.8+, yt-dlp, ffmpeg.

```bash
git clone https://github.com/franklioxygen/MyTube.git
cd MyTube
npm run install:all

# Install yt-dlp
pip install yt-dlp bgutil-ytdlp-pot-provider

# Configure backend
cat > backend/.env << 'EOF'
PORT=5551
MYTUBE_ADMIN_TRUST_LEVEL=container
EOF

# Build and run
npm run build
cd backend && npm run start
```

## Configuration: key environment variables

| Variable | Default | Description |
|---|---|---|
| PORT | 5551 | Backend listen port |
| PUID | 1000 | UID for file ownership in container |
| PGID | 1000 | GID for file ownership in container |
| MYTUBE_ADMIN_TRUST_LEVEL | container | Admin trust boundary: application / container / host |
| MYTUBE_AUTO_FIX_PERMISSIONS | 1 | Auto-chown bind-mount directories on startup |
| YT_DLP_JS_RUNTIME | deno | JS runtime for yt-dlp; set to node on Alpine/musl |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Gotchas

- yt-dlp updates are the main maintenance item: YouTube changes its API frequently; if downloads fail, check for a newer MyTube image with an updated yt-dlp.
- MYTUBE_ADMIN_TRUST_LEVEL matters: In container mode (default), admin has full container-level access. In host mode, admin can run commands on the host. Read the security model doc before changing this setting.
- Two-container setup requires both ports reachable: Frontend at 5556 proxies API calls to backend at 5551. A reverse proxy (nginx/Caddy) in front of 5556 is the recommended production setup.
- PUID/PGID must match host directory ownership: If ./uploads or ./data are owned by a different UID, downloads will fail. Leave MYTUBE_AUTO_FIX_PERMISSIONS=1 (default) to auto-correct.
- Age-restricted content requires cookies.txt: Upload via settings page. Downloading content you don't have rights to may violate terms of service.
- AI-generated codebase: Per upstream documentation, no code was written manually. Review security-sensitive configurations carefully before production deployment.

## Links

- GitHub: https://github.com/franklioxygen/MyTube
- Docker guide: https://github.com/franklioxygen/MyTube/blob/master/documents/en/docker-guide.md
- Getting started: https://github.com/franklioxygen/MyTube/blob/master/documents/en/getting-started.md
- Security model: https://github.com/franklioxygen/MyTube/blob/master/documents/en/deployment-security-model.md
- Demo: https://mytube-demo.vercel.app
- Releases: https://github.com/franklioxygen/MyTube/releases
