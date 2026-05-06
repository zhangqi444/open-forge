---
name: pictshare
description: Recipe for PictShare — a multi-lingual image and file hosting service with resizing, API upload support, and optional access controls. PHP + Docker.
---

# PictShare

Multi-lingual image, GIF, MP4, and text hosting service with on-the-fly image resizing, a simple upload API, and optional access controls. No database required — fully file-based. Upstream: <https://github.com/HaschekSolutions/pictshare>. Website: <https://www.pictshare.net/>.

License: Apache-2.0. Platform: PHP 8.2+, Docker. Default port: `80`.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended — fastest way to get running |
| PHP/Apache native | For existing LAMP stacks |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Public URL (e.g. `https://pics.example.com`)?" | Set as `URL` env var |
| storage | "Host path for uploaded files?" | Mounted to `/var/www/data` |
| access | "Restrict uploads to specific IP subnets?" | `ALLOWED_SUBNET` env var — empty = open |
| access | "Upload code required for uploads?" | `UPLOAD_CODE` env var — empty = no code needed |
| access | "Master delete code?" | `MASTER_DELETE_CODE` — allows deleting any image |

## Docker (recommended)

### Quick start

```bash
docker run -d \
  -p 80:80 \
  --name=pictshare \
  -e "URL=http://localhost/" \
  -e "TITLE=My PictShare" \
  hascheksolutions/pictshare:latest
```

### Persistent data with Docker Compose

```bash
mkdir -p /data/pictshare
chown 1000 -R /data/pictshare
```

`docker-compose.yml`:
```yaml
services:
  pictshare:
    image: hascheksolutions/pictshare:latest
    ports:
      - "80:80"
    volumes:
      - /data/pictshare:/var/www/data
    environment:
      URL: "https://pics.example.com/"
      TITLE: "My Image Host"
      MAX_UPLOAD_SIZE: "100"        # MB, for nginx
      JPEG_COMPRESSION: "90"        # 0-100 quality
      PNG_COMPRESSION: "6"          # 0-9 compression
      # UPLOAD_CODE: "secretcode"   # require code to upload
      # ALLOWED_SUBNET: "192.168.0.0/16"  # restrict to subnet
      # MASTER_DELETE_CODE: "admincode"   # code to delete any image
      # MASTER_DELETE_IP: "127.0.0.1"     # IP that can delete anything
    restart: unless-stopped
```

```bash
docker compose up -d
```

PictShare is available at `http://your-host/`.

## API

PictShare exposes a simple upload API:

```bash
# Upload a file
curl -F "upload=@/path/to/image.jpg" https://pics.example.com/upload.php

# Response: {"status":"ok","url":"https://pics.example.com/abc123.jpg","hash":"abc123","filetype":"jpg"}
```

Image transformations via URL:
- Resize: `https://pics.example.com/400x300/abc123.jpg`
- Rotate: `https://pics.example.com/r_90/abc123.jpg`
- Blur: `https://pics.example.com/blur/abc123.jpg`
- Square crop: `https://pics.example.com/square/abc123.jpg`

## Software-layer concerns

| Concern | Detail |
|---|---|
| Storage | `/var/www/data` — all uploaded files live here; persist with a volume |
| Config | Environment variables (no config file needed) |
| Database | None — fully file-based |
| Default port | `80` |
| PHP version | 8.2+ |
| URL env var | Must end with a trailing slash: `https://pics.example.com/` |
| Image processing | Uses GD library (bundled in Docker image) |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in `/var/www/data` is preserved between upgrades as long as the volume is mounted.

## Gotchas

- **`URL` must have a trailing slash**: `https://pics.example.com/` not `https://pics.example.com`. Without it, generated links will be malformed.
- **v3 breaking changes**: PictShare v3 dropped some configuration options (`TITLE` via old config, `UPLOAD_FORM_LOCATION`). If migrating from v2, review the breaking changes list in the README.
- **No authentication/user accounts**: PictShare is a simple public (or code-gated) upload service — not a multi-user gallery. Use `UPLOAD_CODE` and/or `ALLOWED_SUBNET` to restrict access.
- **`chown 1000`**: The Docker image runs as UID 1000. Host directories mounted to `/var/www/data` must be owned by UID 1000 or uploads will fail.
- **Image resizing is URL-based**: Resized versions are generated on demand and cached. First request for a resized image will be slightly slower.

## Upstream links

- Source: <https://github.com/HaschekSolutions/pictshare>
- Docker docs: <https://github.com/HaschekSolutions/pictshare/blob/master/rtfm/DOCKER.md>
- API docs: <https://github.com/HaschekSolutions/pictshare/blob/master/rtfm/API.md>
- Configuration: <https://github.com/HaschekSolutions/pictshare/blob/master/rtfm/CONFIG.md>
