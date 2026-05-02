---
name: quickdrop-project
description: QuickDrop recipe for open-forge. Self-hosted anonymous file sharing. Chunked uploads, optional encryption at rest, per-file passwords, share tokens (expiry + download limits), QR codes, admin console, CSRF protection, cleanup schedules. Single container. Upstream: https://github.com/RoastSlav/quickdrop
---

# QuickDrop

A self-hosted file sharing app for anonymous uploads. Chunked transfers for large files, optional encryption at rest, per-file passwords, token-based share links with expiry and download limits, QR code generation, a built-in admin console for storage/lifetime policies, cleanup schedules, and privacy controls. Single container. No external database.

Upstream: <https://github.com/RoastSlav/quickdrop> | Docker Hub: `roastslav/quickdrop`

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Single container; SQLite/flat-file storage; no external DB needed |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8080` — web UI |
| preflight | "UID/GID?" | `PUID`/`PGID`; default `1000`/`1000` — controls file ownership |
| preflight | "Timezone?" | `TZ`; e.g. `America/New_York` |

## Software-layer concerns

### Image

```
roastslav/quickdrop:latest
```

Docker Hub. Multi-arch.

### Compose

```yaml
services:
  quickdrop:
    image: roastslav/quickdrop:latest
    container_name: quickdrop
    ports:
      - "8080:8080"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./db:/app/db
      - ./log:/app/log
      - ./files:/app/files
    restart: unless-stopped
```

> Source: upstream docker-compose.yml — <https://github.com/RoastSlav/quickdrop>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PUID` | `1000` | User ID for file ownership inside the container |
| `PGID` | `1000` | Group ID for file ownership inside the container |
| `TZ` | `/etc/UTC` | Timezone for scheduled cleanup and log timestamps |

### Volumes

| Path | Purpose |
|---|---|
| `./db:/app/db` | Database / metadata |
| `./log:/app/log` | Application logs |
| `./files:/app/files` | Uploaded files |

Create these directories before first run:

```bash
mkdir -p db log files
```

### Features

- **Anonymous uploads** — no account required to share a file
- **Chunked uploads** — reliable large-file transfers
- **Folder uploads** — directory picker with preserved structure
- **Encryption at rest** — optional; admin-configured
- **Per-file passwords** — protect individual files
- **Share tokens** — per-link expiry dates and download limits
- **QR codes** — generate QR codes for any share link
- **File previews** — images, text, PDF, JSON, CSV; syntax highlighting for code
- **Privacy controls** — hide files from public list, disable public list entirely
- **Admin console** — manage storage quotas, default lifetime, cleanup schedules, whole-app and admin passwords, notification settings
- **Settings apply without restart** — admin changes take effect immediately
- **CSRF protection** — cookie-based

### Admin area

Access the admin console at `/admin`. Set an admin password on first visit. Admin controls include storage paths, max file size, default lifetime, encryption toggle, preview settings, and cleanup schedules.

### Whole-app password mode

Optionally password-protect the entire application (all uploads/downloads require a password). Configure in admin settings.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `./db`, `./log`, and `./files` bind mounts.

## Gotchas

- **Create volume directories first** — if Docker creates `./db`, `./log`, `./files` as root-owned dirs, file permission errors will occur. Run `mkdir -p db log files` before `docker compose up`.
- **`PUID`/`PGID`** — must match the UID/GID that owns the host-side bind mount directories, or the container will fail to write files.
- **No built-in TLS** — front with Caddy or nginx for HTTPS. Do not expose port 8080 publicly without TLS if you use per-file encryption or passwords (credentials travel in plaintext otherwise).
- **Chunked uploads and proxies** — if using nginx, set `client_max_body_size 0;` (or a large value) and `proxy_request_buffering off;` to allow large chunked uploads to pass through.
- **Share token cleanup** — share tokens are deleted when their linked file is deleted. Expired tokens are cleaned on the configured schedule.

## Links

- Upstream README: <https://github.com/RoastSlav/quickdrop>
- Docker Hub: <https://hub.docker.com/r/roastslav/quickdrop>
