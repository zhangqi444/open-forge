---
name: memtly
description: Memtly (formerly WeddingShare) recipe for open-forge. Event photo sharing platform with QR code gallery for guests to view and upload memories. ASP.NET Core + Docker. Source: https://github.com/Memtly/Memtly.Community
---

# Memtly

A self-hosted event photo sharing platform. Provide guests with a QR code or URL to a gallery; they can view existing photos and upload their own memories. Supports slideshows, image/video upload, an admin review panel, and multiple galleries. Formerly known as WeddingShare. GPL-3.0 licensed, built on ASP.NET Core. Upstream: <https://github.com/Memtly/Memtly.Community>. Docker Hub: <https://hub.docker.com/r/memtly/memtly>. Docs: <https://docs.memtly.com>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose | Official Docker image — recommended |
| Any Linux / Windows | .NET 8 native | Build from source |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Memtly?" | FQDN | e.g. memories.example.com |
| "Admin username?" | String | For the admin panel |
| "Admin password?" | String (sensitive) | Initial admin credentials |
| "Gallery name / event name?" | String | Shown on the gallery page |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Enable guest uploads?" | Yes / No | Whether guests can upload without approval |
| "Require admin approval for uploaded media?" | Yes / No | Review tab in admin panel |
| "SMTP config for notifications?" | host:port + credentials | Optional |
| "Allowed file types?" | Extension list | Default image/video types; do NOT add .HEIC (unsupported) |

## Software-Layer Concerns

- **Data persistence**: Uploaded images/videos stored in a configurable directory — must be a persistent volume.
- **QR codes**: Each gallery has a QR code and URL for sharing with guests. Print QR codes for distribution at the event.
- **Admin panel**: Includes tabs for Reviews (approve/reject uploads), Galleries, Users, Resources, Settings, Audit log, and Data management.
- **HEIC not supported**: Apple's .HEIC format is not supported by web browsers broadly and explicitly excluded by the project. Do not add it to allowed file types.
- **Config via env vars**: All configuration via Docker environment variables. See https://docs.memtly.com for full list.
- **Formerly WeddingShare**: If you find references to WeddingShare in older docs/issues, it's the same project.

## Deployment

### Docker Compose

```yaml
services:
  memtly:
    image: memtly/memtly:latest
    container_name: memtly
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/wwwroot/content
    environment:
      ADMIN_USERNAME: admin
      ADMIN_PASSWORD: changeme
      # Full config options: https://docs.memtly.com
    restart: unless-stopped
```

Access the admin panel at http://<host>:8080/admin

See full environment variable documentation at https://docs.memtly.com/self-hosting

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Backup the data volume before upgrading.
3. Check release notes at https://github.com/Memtly/Memtly.Community/releases.

## Gotchas

- **HEIC format**: Explicitly unsupported — do not add .HEIC to GALLERY_ALLOWED_FILE_TYPES. Apple devices should auto-convert to JPG.
- **Guest upload approvals**: If you want to curate the gallery, enable admin review so uploads go to a review queue before appearing publicly.
- **QR code distribution**: QR codes link to the gallery URL — print them before the event. The URL must be publicly accessible at event time.
- **ASP.NET Core**: Docker image bundles the .NET runtime; no separate installation needed.
- **Demo available**: Try https://demo.memtly.com before deploying.

## Links

- Source: https://github.com/Memtly/Memtly.Community
- Docker Hub: https://hub.docker.com/r/memtly/memtly
- Documentation: https://docs.memtly.com
- Demo: https://demo.memtly.com
- Releases: https://github.com/Memtly/Memtly.Community/releases
