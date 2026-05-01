---
name: FileRise
description: "Self-hosted web file manager and storage hub with WebDAV, sharing, per-folder ACLs, and optional folder-level encryption at rest. Docker. PHP. error311/FileRise. Drag-and-drop uploads, OnlyOffice integration, link sharing, file requests, PDF previews. MIT (core) + Pro tier."
---

# FileRise

**Self-hosted web file manager and storage hub.** Drag-and-drop uploads, per-folder ACLs, WebDAV, link sharing, upload-only file request links, PDF previews, and optional folder-level encryption at rest — all in one PHP app, no external database required. OnlyOffice integration for document editing. Free core (MIT) with a commercial Pro tier for groups, client portals, and AI workspace.

Built + maintained by **error311**. MIT (core) / Pro (commercial).

- Upstream repo: <https://github.com/error311/FileRise>
- Docker image: `error311/filerise-docker`
- Website: <https://filerise.net>
- Docs: <https://filerise.net/docs/>
- Live demo: <https://demo.filerise.net>

## Architecture in one minute

- **PHP** app — no external database (flat-file metadata)
- **Nginx** inside container (port 80)
- Uploads stored at `/var/www/uploads`
- Users/metadata at `/var/www/users`, `/var/www/metadata`
- Port **8080** (configurable via `HOST_HTTP_PORT`)
- Resource: **low** — PHP, no database overhead
- Optional: `pdftoppm` for PDF thumbnails (available in image)

## Compatible install methods

| Infra      | Runtime                          | Notes                                           |
| ---------- | -------------------------------- | ----------------------------------------------- |
| **Docker** | `error311/filerise-docker`       | **Primary** — single container; no DB           |

## Install via Docker

```yaml
services:
  filerise:
    image: error311/filerise-docker:latest
    container_name: filerise
    restart: unless-stopped
    ports:
      - "8080:80"
    environment:
      - TIMEZONE=UTC
      - DATE_TIME_FORMAT=m/d/y  h:iA
      - TOTAL_UPLOAD_SIZE=5G
      - SECURE=false
      - PUID=1000
      - PGID=1000
      - CHOWN_ON_START=true
      - SCAN_ON_START=true
      - PERSISTENT_TOKENS_KEY=       # leave blank to auto-generate; persisted in metadata volume
      - SHARE_URL=                   # optional: public URL for share links
    volumes:
      - ./data/uploads:/var/www/uploads
      - ./data/users:/var/www/users
      - ./data/metadata:/var/www/metadata
    healthcheck:
      test: ["CMD-SHELL", "curl -fsS http://localhost/ || exit 1"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 20s
```

```bash
docker compose up -d
```

Visit `http://localhost:8080` → create your admin account on first run.

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `TIMEZONE` | `UTC` | Server timezone |
| `DATE_TIME_FORMAT` | `m/d/y  h:iA` | PHP date format for UI |
| `TOTAL_UPLOAD_SIZE` | `5G` | Max total upload size per request |
| `SECURE` | `false` | Set `true` if serving over HTTPS (affects cookie flags) |
| `PUID` | `1000` | Host user ID for file ownership |
| `PGID` | `1000` | Host group ID for file ownership |
| `CHOWN_ON_START` | `true` | Fix ownership of volumes on container start |
| `SCAN_ON_START` | `true` | Scan upload directory on start |
| `PERSISTENT_TOKENS_KEY` | (auto) | Encryption key for persistent tokens; auto-generated and stored in metadata volume if blank |
| `SHARE_URL` | (none) | Public base URL for generating share links |

## Features overview

| Feature | Details |
|---------|---------|
| Drag-and-drop uploads | Chunked, resumable uploads with pause/resume and progress |
| Per-folder ACLs | View, Upload, Create, Edit, Rename, Move, Copy, Delete, Extract, Share — per folder |
| WebDAV | Mount FileRise as a WebDAV drive |
| Link sharing | Share folders (browsable or upload-only) with optional password and expiration |
| File request links | Upload-only links — external users submit files without seeing existing content |
| PDF viewing | Inline PDF preview in modal |
| PDF thumbnails | First-page PDF thumbnails (uses `pdftoppm`) |
| Folder-level encryption | Optional at-rest encryption per folder and descendants; transparent on download |
| Link File (deep links) | Internal authenticated deep links to specific files |
| Multiple storage roots | Multiple local root directories (Pro: additional source adapters) |
| WebDAV sources | Add remote WebDAV sources alongside local storage |
| Tags & search | Tag files; fast search |
| File previews | Images, PDFs, text, and more |
| OnlyOffice integration | Edit documents in-browser via OnlyOffice |
| No database | Flat-file metadata — no Postgres/MySQL required |
| PUID/PGID | Match container file ownership to host user |

## Folder-level encryption

Optional per-folder encryption at rest using authenticated encryption:
- Opt in per folder — inherited by subfolders
- Files stored encrypted on disk; transparently decrypted on download
- Master key auto-generated or supplied via environment variable
- **When encryption is enabled, incompatible features are disabled for that folder:** WebDAV, sharing, ZIP operations, and OnlyOffice

## Gotchas

- **No database — flat files only.** All metadata is stored in JSON files in the metadata volume. This keeps things simple but means no SQL queries, no joins, and less scalability at very large scales.
- **`SECURE=false` for HTTP.** If you're not serving over HTTPS (e.g. local LAN only), keep `SECURE=false`. Setting `SECURE=true` on HTTP will break cookie handling.
- **`PERSISTENT_TOKENS_KEY` — don't lose it.** If you manually set a key, back it up. If auto-generated, it's stored in the metadata volume — back up the volume.
- **Encryption disables sharing/WebDAV for encrypted folders.** If you encrypt a folder, sharing links and WebDAV access are automatically disabled for safety.
- **Pro features are commercial.** User groups, client portals, automation, gateway shares, and AI workspace require FileRise Pro. The core (MIT) covers individual/team use cases fully.
- **MIT license (core).** Free to use, modify, redistribute. Pro is a separate commercial product.

## Backup

```sh
# All data is in these three directories
tar -czf filerise-$(date +%F).tar.gz ./data/uploads ./data/users ./data/metadata
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active PHP development, MIT core, Docker-first, no-database design, Pro tier available.

## File-manager-family comparison

- **FileRise** — PHP, no-DB, per-folder ACLs, encryption at rest, WebDAV, OnlyOffice, MIT core
- **Nextcloud** — PHP, full platform (calendar, contacts, apps), own database; heavier; AGPL-3.0
- **Filebrowser** — Go, minimal file manager, no ACLs; Apache-2.0
- **Seafile** — C/Python, Dropbox-style sync + sharing; AGPL-3.0/commercial
- **Filestash** — Go, multi-backend file manager (S3, SFTP, WebDAV, etc.); AGPL-3.0

**Choose FileRise if:** you want a self-hosted file manager with per-folder ACLs, optional encryption at rest, WebDAV, and OnlyOffice integration — without needing a database.

## Links

- Repo: <https://github.com/error311/FileRise>
- Docker image repo: <https://github.com/error311/filerise-docker>
- Docs: <https://filerise.net/docs/>
- Demo: <https://demo.filerise.net>
