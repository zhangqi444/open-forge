---
name: Picsur
description: "Self-hosted image sharing and hosting platform. Docker. NestJS/Node.js + PostgreSQL. CaramelFur/Picsur. Upload, view, convert, edit images; anonymous + authenticated uploads; ShareX endpoint. ⚠️ NOT MAINTAINED."
---

# Picsur

**Self-hosted image hosting and sharing platform.** Upload images; get direct links; share via unique URLs. Anonymous + authenticated uploads, user roles, image conversion and basic editing (resize/rotate/flip), EXIF stripping, expiring images, ShareX endpoint, and support for unusual formats (QOI, HEIF, JXL). Think self-hosted Imgur.

Built + maintained by **CaramelFur**. See repo license.

> ⚠️ **NOT ACTIVELY MAINTAINED.** The author has stated the project is no longer maintained due to time constraints. The codebase is functional but receives no new features or security patches. Consider forking or using an alternative (Immich for photo management, Zipline for file sharing + images). The demo at picsur.org continues running.

- Upstream repo: <https://github.com/CaramelFur/Picsur>
- Demo: <https://picsur.org>
- GHCR: `ghcr.io/caramelfur/picsur`

## Architecture in one minute

- **NestJS / Node.js** backend + Angular frontend
- **PostgreSQL** database
- Port **8080** (web UI + API)
- Docker Compose: `picsur` + `picsur_postgres` containers
- Images stored internally (configurable)
- Supports: QOI, JPG, PNG, WEBP (animated), TIFF, HEIF, BMP, GIF (animated), JXL, JP2
- Resource: **low-medium** — Node.js + PostgreSQL

## Compatible install methods

| Infra          | Runtime                          | Notes                        |
| -------------- | -------------------------------- | ---------------------------- |
| **Docker**     | `ghcr.io/caramelfur/picsur`      | **Primary** — GHCR; amd64 + arm64 |

## Inputs to collect

| Input                      | Example             | Phase    | Notes                                                              |
| -------------------------- | ------------------- | -------- | ------------------------------------------------------------------ |
| `PICSUR_DB_HOST`           | `picsur_postgres`   | DB       | Postgres host (service name in compose)                            |
| `PICSUR_DB_PASSWORD`       | strong random       | DB       | Postgres password (match across picsur + postgres services)        |
| `PICSUR_ADMIN_PASSWORD`    | strong random       | Auth     | Admin account password (default username: `admin`)                 |
| `PICSUR_JWT_SECRET`        | random string       | Security | JWT signing secret; auto-generated if not set — set explicitly for persistence |
| `PICSUR_MAX_FILE_SIZE`     | `128000000`         | Config   | Max upload size in bytes (default 128 MB)                          |

## Install via Docker Compose

```yaml
version: '3'
services:
  picsur:
    image: ghcr.io/caramelfur/picsur:latest
    container_name: picsur
    ports:
      - '8080:8080'
    environment:
      PICSUR_DB_HOST: picsur_postgres
      PICSUR_DB_PASSWORD: changeme
      PICSUR_ADMIN_PASSWORD: changeme_admin
      PICSUR_JWT_SECRET: change_this_random_secret
      # PICSUR_MAX_FILE_SIZE: 128000000
    restart: unless-stopped

  picsur_postgres:
    image: postgres:17-alpine
    container_name: picsur_postgres
    environment:
      POSTGRES_DB: picsur
      POSTGRES_PASSWORD: changeme
      POSTGRES_USER: picsur
    restart: unless-stopped
    volumes:
      - picsur-data:/var/lib/postgresql/data

volumes:
  picsur-data:
```

Visit `http://localhost:8080`. Default admin username: `admin`.

## First boot

1. Set `PICSUR_ADMIN_PASSWORD` and `PICSUR_JWT_SECRET` before starting.
2. `docker compose up -d`.
3. Visit `http://localhost:8080` → log in as `admin`.
4. Configure roles: Settings → Roles → Guest → add `Register` permission to allow self-signup (off by default).
5. Enable "Keep original" in Settings → General if you want original files preserved (off by default; EXIF not stripped from originals).
6. Set up **ShareX** by configuring the Picsur endpoint in ShareX settings.
7. Put behind HTTPS — required for clipboard copy in the browser UI.

## Features overview

| Feature | Details |
|---------|---------|
| Uploading | Anonymous + authenticated; drag-and-drop + API |
| Format support | QOI, JPG, PNG, WEBP, TIFF, HEIF, BMP, GIF, JXL, JP2 |
| Conversion | Convert uploaded images to any supported format on view |
| Editing | Resize, rotate, flip, strip transparency, negative, greyscale |
| EXIF stripping | Removes EXIF data by default (privacy); optional keep-original |
| Expiring images | Set TTL per image |
| ShareX | Custom uploader endpoint compatible with ShareX |
| User roles | Admin-configurable role permissions (upload, register, delete, etc.) |
| REST API | Postman collection available |
| Internal format | Images stored as QOI internally for fast decode |

## Gotchas

- **⚠️ Not maintained.** No security updates since the author stepped away. Treat this as a frozen release. Monitor the repo for any community forks that have taken over active maintenance.
- **Registration is closed by default.** Only admin can create accounts. To allow self-signup, grant the `Register` permission to the Guest role in Settings → Roles.
- **HTTPS required for clipboard.** The "copy link" button uses the Clipboard API, which browsers restrict to secure contexts (HTTPS or localhost). HTTP installs won't be able to copy to clipboard.
- **EXIF data in originals.** If you enable "Keep original", the original file retains EXIF data (including potentially location info). Only the processed version has EXIF stripped. Be cautious about sharing originals.
- **`PICSUR_JWT_SECRET` persistence.** If not set, a random secret is generated on startup. If the container restarts without a fixed secret, all existing sessions become invalid. Set it explicitly.
- **QOI internal storage.** Picsur converts all uploads to QOI format internally. The original is kept separately only if "Keep original" is enabled. QOI is lossless and fast.
- **Fork opportunity.** The author explicitly welcomes forks and potential new maintainers. Check GitHub for active forks if you need ongoing development.

## Backup

```sh
docker compose exec picsur_postgres pg_dump -U picsur picsur > picsur-$(date +%F).sql
```

## Project health

⚠️ **Unmaintained since ~2024.** Functional but frozen. No active development or security patches.

## Image-hosting-family comparison (maintained alternatives)

- **Picsur** — NestJS, image-specific, ShareX support, EXIF strip; ⚠️ unmaintained
- **Zipline** — Node.js, file + image sharing, ShareX, active development; direct functional successor
- **Immich** — Go+Node, photo library + backup, timeline UI; broader scope than image hosting
- **Lychee** — PHP, photo album management; different UX paradigm
- **Pinry** — Python, Pinterest-style image board; different scope

**⚠️ Consider using Zipline instead** for maintained ShareX + image hosting functionality.

## Links

- Repo: <https://github.com/CaramelFur/Picsur>
- Demo: <https://picsur.org>
- GHCR: `ghcr.io/caramelfur/picsur`
- API (Postman): see README
