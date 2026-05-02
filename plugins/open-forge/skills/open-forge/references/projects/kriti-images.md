---
name: kriti-images
description: Recipe for Kriti Images — high-performance URL-based image transformation service in Go. Open-source alternative to Cloudflare Images / ImageKit. Supports resize, crop, format conversion, color adjustments, blur, rotate. Local or S3 image source.
---

# Kriti Images

High-performance URL-based image transformation service. Upstream: https://github.com/kritihq/kriti-images

Go service that transforms images on-the-fly via URL parameters — resize, crop, rotate, blur, brightness/contrast/saturation, format conversion (JPEG/PNG/WebP), and more. Open-source alternative to Cloudflare Images and ImageKit. CDN-friendly (proper cache headers). Supports local filesystem or AWS S3 as image source.

Website: https://kritiimages.com | API demo: https://kritiimages.com/docs/transformations

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker (build from source) | Dockerfile in docker/ directory — no published image in README |
| Binary | Build from source with Go 1.21+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Image source type | local (filesystem) or awss3 |
| preflight | Local image base path | Directory containing source images (if local) |
| preflight | AWS S3 bucket + credentials | If using awss3 source (requires AWS CLI configured) |
| config | Server port | Default: 8080 |
| config | Max image dimension | Default: 8192px — images beyond this are rejected |
| config | Max file size | Default: 50MB |
| config | Rate limit | Default: 100 req/min |

## Software-layer concerns

**Config:** YAML or TOML config file (`config.yaml` or `config.toml`) mounted into the container. No environment variable config — file-based only.

**Key config options:**
```yaml
server:
  port: 8080
  read_timeout: 30s
  write_timeout: 30s
  limiter:
    max: 100
    expiration: 1m

images:
  source: local          # or awss3
  local:
    base_path: /app/web/static/assets
  max_image_dimension: 8192
  max_file_size_in_bytes: 52428800

experimental:
  enable_upload_api: false
```

**Port:** 8080.

**URL structure:**
```
/cgi/images/tr:<transformations>/<image-path>
```
Example: `/cgi/images/tr:width=300,format=webp/photo.jpg`

**S3 source:** Requires AWS CLI installed and configured in the container. Set `images.source: awss3` and `images.aws.s3.bucket`.

**Upload API:** Disabled by default (experimental). Enable with `experimental.enable_upload_api: true`. API may change or be removed.

**No published Docker image:** The docker/ directory has a Dockerfile but the README does not reference a published registry image. Build locally.

## Docker Compose (build from source)

```yaml
services:
  kriti-images:
    build:
      context: .
      dockerfile: docker/Dockerfile
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./config.yaml:/app/config.yaml
      - ./images:/app/web/static/assets
```

Or docker run:
```bash
docker run -p 8080:8080 \
  -v /path/to/images:/app/web/static/assets \
  -v /path/to/config.yaml:/app/config.yaml \
  kriti-images
```

## Upgrade procedure

```bash
git pull
docker compose build
docker compose up -d
```

Images and config are in mounted volumes — preserved across rebuilds.

## Gotchas

- **No pre-built public image** — must build from the Dockerfile in `docker/`.
- **Config file required** — there is no fallback to env vars; a config.yaml/config.toml must be mounted or present.
- **S3 requires AWS CLI** — the container must have AWS credentials available (env vars, mounted credentials file, or IAM role) if using S3 source.
- **Upload API is experimental** — the endpoint and behavior may change or be removed in future versions.
- **URL-escaped paths for URL sources** — when using a URL as the image source, the URL must be percent-encoded in the request path.

## Links

- Upstream repository: https://github.com/kritihq/kriti-images
- Docker setup guide: https://github.com/kritihq/kriti-images/blob/main/docker/README.md
- API reference + demo: https://kritiimages.com/docs/transformations
- Website: https://kritiimages.com
