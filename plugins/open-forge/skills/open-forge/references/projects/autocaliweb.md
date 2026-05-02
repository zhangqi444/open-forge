---
name: autocaliweb
description: Recipe for Autocaliweb — fork of Calibre-Web with automatic ingest, conversion, metadata enforcement, OIDC, and more. Docker Compose, single container. Active development moved to Codeberg as of Feb 2026.
---

# Autocaliweb

Web interface for Calibre eBook libraries with automation features. Upstream: https://codeberg.org/gelbphoenix/autocaliweb

> **Note:** As of 1 February 2026, active development has moved to Codeberg. GitHub remains available but is no longer the primary repository.

Fork of Calibre-Web + Calibre-Web Automated. Adds auto-ingest (drop books into a folder → auto-added to library), automatic format conversion, metadata enforcement, cover enforcement, EPub fixer, Kobo sync improvements, OIDC support, duplicate management, split library support, and more. GPL v3.

Docker Hub: https://hub.docker.com/r/gelbphoenix/autocaliweb
Documentation: https://github.com/gelbphoenix/autocaliweb/wiki (may still be on GitHub)

## Prerequisites

- An existing Calibre library (`.db` file + book files) or a new empty library directory
- Calibre installed on the host (optional — needed for format conversion features)

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — single container, LSIO-style |
| Docker run | Supported |
| Proxmox VE script | Community script available |
| Manual install | On your own risk — not officially supported on Windows |

> Windows with Docker Desktop is not supported. WSL is on your own risk.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Calibre library path | Host path to your Calibre library directory |
| preflight | Config path | Host path for Autocaliweb config/data |
| preflight | Book ingest path | Host path for auto-ingest drop folder (/acw-book-ingest) |
| preflight | PUID + PGID | User/group IDs for file permissions |
| preflight | Timezone (TZ) | e.g. America/New_York |
| auth (opt) | OIDC settings | Configured post-install in the admin UI |

## Software-layer concerns

**Config:** Minimal environment variables at deploy time. Most settings (SMTP, OIDC, metadata providers, etc.) are configured via the admin web UI after first launch.

**Key env vars:**
| Var | Default | Description |
|---|---|---|
| TZ | Etc/UTC | Container timezone |
| PUID | 1000 | User ID for file ownership |
| PGID | 1000 | Group ID for file ownership |

**Port:** 8083.

**Volumes:**
- `/config` — Autocaliweb config and database
- `/calibre-library` — Your Calibre library (must be writable)
- `/acw-book-ingest` — Drop new books here for auto-ingest

**Auto-ingest:** Books dropped into the ingest volume are automatically added to the Calibre library (with optional conversion, metadata fetch, cover enforcement).

**stop_signal: SIGINT + stop_grace_period: 15s** — recommended in compose to allow graceful shutdown of background services.

**Codeberg primary:** Issues and new releases are at https://codeberg.org/gelbphoenix/autocaliweb. The GitHub repo at https://github.com/gelbphoenix/autocaliweb still exists but is no longer actively maintained.

## Docker Compose

```yaml
services:
  autocaliweb:
    image: gelbphoenix/autocaliweb:latest
    container_name: autocaliweb
    restart: unless-stopped
    ports:
      - "8083:8083"
    environment:
      - TZ=America/New_York
      - PUID=1000
      - PGID=1000
    volumes:
      - /path/to/config:/config
      - /path/to/book/ingest:/acw-book-ingest
      - /path/to/calibre-library:/calibre-library
    stop_signal: SIGINT
    stop_grace_period: 15s
```

## Upgrade procedure

```bash
docker compose pull autocaliweb
docker compose up -d autocaliweb
```

Config volume is preserved. Check Codeberg releases for breaking changes.

## Gotchas

- **PUID/PGID must match file ownership** — the Calibre library files must be owned by (or readable/writable by) the specified PUID/PGID, otherwise the app cannot modify the library.
- **Calibre library path must be writable** — Autocaliweb modifies the library (adds books, updates metadata). Mount as read-write.
- **Windows Docker Desktop unsupported** — use WSL or a Linux host.
- **Development moved to Codeberg** — check https://codeberg.org/gelbphoenix/autocaliweb for releases and issues, not GitHub.

## Links

- Primary upstream (Codeberg): https://codeberg.org/gelbphoenix/autocaliweb
- GitHub (mirror, less active): https://github.com/gelbphoenix/autocaliweb
- Docker Hub: https://hub.docker.com/r/gelbphoenix/autocaliweb
- Original Calibre-Web: https://github.com/janeczku/calibre-web
