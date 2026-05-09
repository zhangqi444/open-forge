---
name: prismarr-project
description: Prismarr recipe for open-forge. Unified self-hosted media dashboard combining Radarr, Sonarr, Prowlarr, Jellyseerr, qBittorrent, and TMDb in a single Symfony 8 container. One search bar, one calendar, one dashboard. SQLite, zero external dependencies.
---

# Prismarr

Self-hosted unified media management dashboard that combines qBittorrent, Radarr, Sonarr, Prowlarr, Seerr, and TMDb in a single modern web interface. Not a replacement for those tools — a unified control surface on top of them. Single Docker container, embedded SQLite, setup wizard. Upstream: https://github.com/Shoshuo/Prismarr.

Prismarr v1.x. Language: PHP 8.4 / Symfony 8 + FrankenPHP. License: AGPL-3.0. Single container, multi-arch. Image: shoshuo/prismarr (Docker Hub). Default port: 7070.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Engine + Compose | Single container, no external DB or cache needed |
| Any Linux host | Docker run | Minimal single-container deployment |

Requirements: at least one of qBittorrent, Radarr, Sonarr, Prowlarr, or Seerr already running and reachable. Prismarr does not replace these services — it connects to their APIs.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup wizard | Admin email and password | Created during 7-step first-boot wizard at /setup |
| setup wizard | TMDb API key (optional) | Free key from themoviedb.org; enables Discovery page |
| setup wizard | Radarr URL and API key | Optional; enables movies view |
| setup wizard | Sonarr URL and API key | Optional; enables series view |
| setup wizard | Prowlarr URL and API key | Optional; enables indexer integration |
| setup wizard | Seerr URL and API key | Optional; enables media requests |
| setup wizard | qBittorrent URL, username, password | Optional; enables downloads dashboard |
| setup wizard | Gluetun URL and API key (optional) | For VPN port-forwarding sync with qBittorrent |
| optional | TZ | Container timezone (e.g. Europe/Paris, America/New_York) |
| optional | TRUSTED_PROXIES | Set if running behind Traefik/nginx/Caddy/Cloudflare Tunnel |

## Software-layer concerns

### Config paths

| Item | Path |
|---|---|
| SQLite database | /var/www/html/var/data/prismarr.db (inside container) |
| Auto-generated secrets | /var/www/html/var/data/.env.local (APP_SECRET, MERCURE_JWT_SECRET) |
| Login sessions | /var/www/html/var/data/sessions/ |
| Cache (thumbnails) | /var/www/html/var/data/cache/ |
| User avatars | /var/www/html/var/data/avatars/ |
| Persistent volume | Mount prismarr_data to /var/www/html/var/data |

All credentials (API keys, passwords) are stored in the SQLite database, never in environment variables or on-disk config files.

### Key environment variables (optional)

| Variable | Default | Purpose |
|---|---|---|
| APP_ENV | prod | Set to dev only for local development |
| PRISMARR_PORT | 7070 | Internal listening port |
| TRUSTED_PROXIES | 127.0.0.1,REMOTE_ADDR | Adjust for reverse proxy setups |
| TZ | UTC | Container timezone |
| PHP_MEMORY_LIMIT | 1024M | PHP memory per request; increase for large libraries |
| PHP_MAX_EXECUTION_TIME | 120 | PHP time limit per request; increase if series/films page times out |

### Docker Compose

  services:
    prismarr:
      image: shoshuo/prismarr:latest
      container_name: prismarr
      restart: unless-stopped
      stop_grace_period: 30s
      ports:
        - "7070:7070"
      volumes:
        - prismarr_data:/var/www/html/var/data
      environment:
        - TZ=UTC
        # - TRUSTED_PROXIES=172.16.0.0/12  # uncomment behind reverse proxy

  volumes:
    prismarr_data:

Access: http://localhost:7070 — first boot launches the 7-step setup wizard.

To download the upstream example compose file:
  curl -O https://raw.githubusercontent.com/Shoshuo/Prismarr/main/docker-compose.example.yml

### First-boot wizard

The 7-step wizard at /setup covers:
1. Admin account creation
2. TMDb API key (optional)
3. Radarr URL + API key
4. Sonarr URL + API key
5. Prowlarr URL + API key
6. Seerr URL + API key
7. qBittorrent + optional Gluetun

APP_SECRET and MERCURE_JWT_SECRET are auto-generated on first boot and persisted in the volume. No .env editing required.

### Backup

  docker run --rm \
    -v prismarr_data:/data \
    -v $(pwd):/backup \
    alpine tar czf /backup/prismarr-data.tgz -C /data .

## Upgrade procedure

  docker compose pull
  docker compose up -d

SQLite migrations run automatically on container start. The prismarr_data volume is preserved across upgrades.

To pin a specific version:
  image: shoshuo/prismarr:1.0.0

## Gotchas

- Single developer project — actively maintained but support/features land on the developer's schedule; no SLA or commercial backing. Check https://github.com/users/Shoshuo/projects/3 for the roadmap.
- Not a replacement for Radarr/Sonarr — Prismarr sits on top of these services via their APIs; the underlying *arr apps must be running separately.
- PHP memory limit — for very large Radarr/Sonarr libraries, the default 1024M PHP_MEMORY_LIMIT may need to be increased to 2048M or -1 (unlimited).
- Reverse proxy TRUSTED_PROXIES — without setting this correctly behind Traefik/nginx/Caddy/Cloudflare Tunnel, Symfony may misread client IPs for rate limiting and SSRF protection.
- SSRF protection — user-provided service URLs are validated against a protocol allowlist and cloud-metadata blocklist; internal network URLs (RFC1918) are permitted.
- Large library timeouts — if the films or series page times out on a large library, increase both PHP_MEMORY_LIMIT and PHP_MAX_EXECUTION_TIME together.
- Forgot admin password: docker exec -it prismarr php bin/console app:user:reset-password <email>
- Setup wizard loops: delete the setup_completed flag via docker exec -it prismarr php bin/console doctrine:query:sql "DELETE FROM setting WHERE key = 'setup_completed'"

## Links

- Upstream README: https://github.com/Shoshuo/Prismarr
- Changelog: https://github.com/Shoshuo/Prismarr/blob/main/CHANGELOG.md
- Roadmap: https://github.com/users/Shoshuo/projects/3
- Docker Hub: https://hub.docker.com/r/shoshuo/prismarr
