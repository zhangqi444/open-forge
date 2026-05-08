---
name: gose-project
description: GoSE recipe for open-forge. Terascale S3-backed file uploader with client-side chunking, deduplication, and presigned URLs. Docker and binary install. Based on upstream README at https://codeberg.org/stv0g/gose.
---

# GoSƐ

Modern, scalable file uploader that uses S3 as its only backend. Uploads are chunked client-side, deduplicated via MD5 hash, and sent directly to S3 via presigned URLs — GoSƐ itself handles only small metadata requests. Apache-2.0. Upstream: https://codeberg.org/stv0g/gose. Docker: ghcr.io/stv0g/gose.

Works with AWS S3, Ceph RadosGW, MinIO, and any S3-compatible storage.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (with MinIO) | Self-contained; spins up GoSƐ + local S3 storage |
| Docker (existing S3 backend) | Use with AWS S3, Ceph, or existing MinIO |
| Binary | Smallest footprint; bare-metal |
| Kubernetes / Kustomize | Cluster deployments |
| Nix | Nixpkgs or flake |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "S3 endpoint (host:port)?" | host:port | MinIO default: localhost:9000; AWS: s3.amazonaws.com |
| config | "S3 bucket name?" | string | Created in S3/MinIO before starting GoSƐ |
| config | "S3 region?" | string | e.g. us-east-1 |
| config | "Access key?" | Free-text (sensitive) | GOSE_ACCESS_KEY |
| config | "Secret key?" | Free-text (sensitive) | GOSE_SECRET_KEY |
| config | "Base URL (public-facing)?" | URL | GOSE_BASE_URL — where users access GoSƐ |
| config | "Use HTTPS for S3?" | Yes / No | GOSE_NO_SSL=false for HTTPS |
| config | "Max upload size?" | e.g. 50GB | GOSE_MAX_UPLOAD_SIZE |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Go single binary |
| S3 requirement | An S3-compatible storage backend is required — GoSƐ has no local file storage |
| Port | 8080 (default) |
| Config methods | Environment variables or config.yaml file |
| Deduplication | Files are skipped on re-upload if same content hash already exists in S3 |
| Direct upload | Browsers upload directly to S3 via presigned URLs — GoSƐ sees only metadata |
| Retention | User-selectable expiration; implemented via S3 lifecycle policies |

## Install: Docker Compose (with MinIO)

Source: https://codeberg.org/stv0g/gose/src/branch/main/compose.yaml

Full self-contained stack including local S3 (MinIO):

```yaml
services:
  minio:
    image: minio/minio:RELEASE.2022-06-03T01-40-53Z.fips
    command: server /mnt/data --console-address ":9001"
    ports:
      - "9000:9000"   # S3 API
      - "9001:9001"   # MinIO web console
    environment:
      MINIO_ROOT_USER: "admin-user"       # changeme
      MINIO_ROOT_PASSWORD: "admin-pass"   # changeme
      MINIO_SERVER_URL: "http://localhost:9000"
      MINIO_SITE_REGION: "s3"
    volumes:
      - minio-data:/mnt/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/ready"]
      interval: 30s
      timeout: 20s
      retries: 3

  gose:
    image: ghcr.io/stv0g/gose:latest
    ports:
      - "8080:8080"
    environment:
      GOSE_LISTEN: ":8080"
      GOSE_BASE_URL: "http://localhost:8080"
      GOSE_BUCKET: "gose-uploads"
      GOSE_ENDPOINT: "minio:9000"
      GOSE_REGION: "s3"
      GOSE_PATH_STYLE: "true"
      GOSE_NO_SSL: "true"
      GOSE_ACCESS_KEY: "admin-user"   # changeme
      GOSE_SECRET_KEY: "admin-pass"   # changeme
      GOSE_MAX_UPLOAD_SIZE: "50GB"
      GOSE_PART_SIZE: "16MB"
    depends_on:
      - minio

volumes:
  minio-data:
```

Before starting, create the bucket in MinIO:
```bash
docker compose up -d minio
# Access http://localhost:9001, log in, create a bucket named "gose-uploads"
docker compose up -d gose
```

## Install: Docker (existing S3)

```bash
docker run -d \
  --name gose \
  --restart unless-stopped \
  -p 8080:8080 \
  -e GOSE_LISTEN=":8080" \
  -e GOSE_BASE_URL="https://upload.example.com" \
  -e GOSE_BUCKET="gose-uploads" \
  -e GOSE_ENDPOINT="s3.amazonaws.com" \
  -e GOSE_REGION="us-east-1" \
  -e GOSE_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE" \
  -e GOSE_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  ghcr.io/stv0g/gose:latest
```

## Install: Binary

Download for your OS/arch from https://codeberg.org/stv0g/gose/releases:

```bash
wget https://codeberg.org/stv0g/gose/releases/download/vX.Y.Z/gose_X.Y.Z_linux_amd64 -O /usr/local/bin/gose
chmod +x /usr/local/bin/gose

# Run with env vars or config file
GOSE_BUCKET=gose-uploads GOSE_ENDPOINT=minio:9000 ... gose

# Or with a config file
gose -config /etc/gose/config.yaml
```

## Configuration reference (key env vars)

| Variable | Default | Description |
|---|---|---|
| GOSE_LISTEN | :8080 | Listen address:port |
| GOSE_BASE_URL | http://localhost:8080 | Public-facing URL |
| GOSE_BUCKET | gose-uploads | S3 bucket name |
| GOSE_ENDPOINT | — | S3 host:port (no http://) |
| GOSE_REGION | us-east-1 | S3 region |
| GOSE_PATH_STYLE | false | true for MinIO/Ceph |
| GOSE_NO_SSL | false | true to disable TLS for S3 connection |
| GOSE_ACCESS_KEY | — | S3 access key |
| GOSE_SECRET_KEY | — | S3 secret key |
| GOSE_MAX_UPLOAD_SIZE | — | e.g. 50GB |
| GOSE_PART_SIZE | — | e.g. 16MB per chunk |

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

Binary: download new release binary, replace, restart.

## Gotchas

- S3 bucket must exist before starting: GoSƐ does not create the bucket automatically. Create it in MinIO console or via AWS CLI before first run.
- GOSE_PATH_STYLE=true required for MinIO/Ceph: AWS S3 uses virtual-hosted style (bucket.s3.amazonaws.com); MinIO/Ceph use path style (server:9000/bucket). Set accordingly.
- GOSE_NO_SSL=true for local MinIO: If MinIO runs without TLS on the same Docker network, GoSƐ must not try to use HTTPS to reach it.
- GOSE_BASE_URL must match public URL: Presigned URLs are generated using this base URL. A mismatch causes upload/download failures.
- Direct upload bypasses GoSƐ rate limiting: File data goes straight from browser to S3. GoSƐ cannot throttle upload bandwidth at the data level.
- S3 lifecycle policies handle expiration: If you enable user-selectable retention, configure S3/MinIO lifecycle rules for the bucket to actually delete expired objects.

## Links

- Upstream (Codeberg): https://codeberg.org/stv0g/gose
- Releases: https://codeberg.org/stv0g/gose/releases
- Example config: https://codeberg.org/stv0g/gose/src/branch/main/config.yaml
- Demo: https://gose.0l.de
- Blog post: https://noteblok.net/2022/04/03/gos%c9%9b-a-terascale-file-uploader/
