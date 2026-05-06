---
name: fusion
description: Fusion recipe for open-forge. Lightweight RSS aggregator and reader — fast workflow, Fever API for mobile clients, bookmarks, keyboard shortcuts. Docker or single binary. Upstream: https://github.com/0x2E/fusion
---

# Fusion

Lightweight RSS aggregator and reader. Fast reading workflow with unread tracking, bookmarks, search, and keyboard shortcuts. Fever API compatibility for mobile clients (Reeder, Unread, FeedMe). Single binary or Docker — no external database needed.

2,069 stars · MIT

Upstream: https://github.com/0x2E/fusion
Docker image: ghcr.io/0x2e/fusion

## What it is

Fusion provides a focused, distraction-free RSS reading experience:

- **RSS/Atom parsing** — Full RSS 1.0/2.0 and Atom feed support
- **Feed auto-discovery** — Paste a URL and Fusion finds the feed
- **Group organization** — Organize feeds into groups
- **Unread tracking** — Mark read/unread; focus on what's new
- **Bookmarks** — Save articles for later
- **Full-text search** — Search across all articles
- **Keyboard shortcuts** — Google Reader-style navigation
- **Fever API** — Compatible with Reeder, Unread, FeedMe, and other mobile clients
- **Responsive web UI** — Works on desktop and mobile browsers
- **PWA support** — Install as app on phone or desktop
- **i18n** — English, Chinese, German, French, Spanish, Russian, Portuguese, Swedish
- **No AI features** — Deliberately focused and minimal
- **Single binary** — No external database; SQLite embedded

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | ghcr.io/0x2e/fusion; recommended |
| Bare metal | Go binary | Download from releases; no dependencies |

## Inputs to collect

### Phase 1 — Pre-install
- Password for the web interface (FUSION_PASSWORD)
- Port to expose (default: 8080)
- Data directory for persistent storage

## Software-layer concerns

### Key environment variables
  FUSION_PASSWORD=yourpassword          # required (or set FUSION_ALLOW_EMPTY_PASSWORD=true for trusted LAN)
  FUSION_PORT=8080                      # optional, default 8080
  FUSION_DB_PATH=/data/fusion.db        # optional, default /data/fusion.db
  FUSION_CORS_ALLOWED_ORIGINS=https://reader.example.com  # if behind reverse proxy
  FUSION_TRUSTED_PROXIES=127.0.0.1     # if behind reverse proxy

### Data paths
- /data/ — SQLite database and any persistent data; mount as volume

### Ports
- 8080 — HTTP web interface and Fever API

### Fever API endpoint (for mobile clients)
  http://<host>:8080/fever/
  Username: <any string>
  Password: your FUSION_PASSWORD

## Docker run

  docker run -it -d -p 8080:8080 \
    -v $(pwd)/data:/data \
    -e FUSION_PASSWORD="yourpassword" \
    ghcr.io/0x2e/fusion:latest

## Docker Compose install

  version: "3"
  services:
    fusion:
      image: ghcr.io/0x2e/fusion:latest
      restart: unless-stopped
      ports:
        - "127.0.0.1:8080:8080"
      environment:
        - FUSION_PASSWORD=yourpassword
      volumes:
        - ./data:/data

Access at http://localhost:8080

## Binary install

  # Download from https://github.com/0x2E/fusion/releases
  chmod +x fusion
  FUSION_PASSWORD="yourpassword" ./fusion
  # Open http://localhost:8080

## Upgrade procedure

1. Pull latest image: docker pull ghcr.io/0x2e/fusion:latest
2. Restart: docker compose up -d --force-recreate fusion
3. For binary: download new release binary, stop old process, start new

## Gotchas

- Single user — Fusion is designed for a single user; no multi-account support
- No external DB — uses embedded SQLite; suitable for personal use; not designed for large teams
- Fever API auth — the Fever API uses the password directly; use HTTPS via reverse proxy to protect credentials in transit
- FUSION_ALLOW_EMPTY_PASSWORD — only use on trusted local networks; never expose without a password on the internet
- Reverse proxy required for HTTPS — set FUSION_CORS_ALLOWED_ORIGINS and FUSION_TRUSTED_PROXIES when behind Nginx/Traefik
- Feed refresh — Fusion polls feeds automatically; check logs if feeds aren't updating

## Links

- Upstream README: https://github.com/0x2E/fusion/blob/main/README.md
- Releases: https://github.com/0x2E/fusion/releases
- Docker image: ghcr.io/0x2e/fusion
