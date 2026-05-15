---
name: transfer-sh
description: transfer.sh recipe for open-forge. Covers Docker (local storage, S3, and other providers). transfer.sh is a lightweight Go service for easy command-line file sharing — upload with curl, share a URL, files expire automatically.
---

# transfer.sh

Easy and fast file sharing from the command line. Upload a file with curl, get back a URL, share it — files expire after a configurable duration. Supports local filesystem, Amazon S3, Google Drive, and Storj as storage backends. Upstream: <https://github.com/dutchcoders/transfer.sh>. Docker Hub: <https://hub.docker.com/r/dutchcoders/transfer.sh>.

**License:** MIT · **Language:** Go · **Default port:** 8080 · **Stars:** ~15,800

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (local storage) | <https://github.com/dutchcoders/transfer.sh#docker> | ✅ | Simplest self-hosted setup — files stored on local disk. |
| Docker (S3 backend) | <https://github.com/dutchcoders/transfer.sh#docker> | ✅ | Production with S3-compatible storage (AWS S3, MinIO, etc.). |
| Binary | <https://github.com/dutchcoders/transfer.sh/releases> | ✅ | Bare-metal installs without Docker. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| storage | "Storage backend: local disk, S3/S3-compatible, Google Drive, or Storj?" | AskUserQuestion | Determines provider flags. |
| s3_creds | "AWS access key, secret key, bucket name, and region?" | Free-text (sensitive) | S3 provider. |
| s3_endpoint | "Custom S3 endpoint URL? (for MinIO, Cloudflare R2, etc.)" | Free-text | S3-compatible non-AWS. |
| basedir | "Local directory for file storage? (e.g. /data/transfers)" | Free-text | Local provider. |
| domain | "Public URL for transfer.sh? (used in returned share URLs)" | Free-text | All methods. |
| max_size | "Maximum upload size in bytes? (default: unlimited)" | Free-text | Optional. |
| purge | "File retention / expiry in days? (default: no auto-purge)" | Free-text | Optional. |

## Install — Docker (local storage)

```bash
# Basic — stores files in /tmp inside container (ephemeral!)
docker run -d \
  --publish 8080:8080 \
  --name transfer-sh \
  dutchcoders/transfer.sh:v1.6.1-noroot \
  --provider local \
  --basedir /tmp/

# Persistent — mount a host directory
docker run -d \
  --publish 8080:8080 \
  --name transfer-sh \
  -v /opt/transfer-data:/data \
  dutchcoders/transfer.sh:v1.6.1-noroot \
  --provider local \
  --basedir /data
```

> **Use `-noroot` tag:** The `-noroot` image runs as UID/GID 5000 — recommended to reduce attack surface.

### Docker Compose (local storage)

```yaml
services:
  transfer-sh:
    image: dutchcoders/transfer.sh:v1.6.1-noroot
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - transfer-data:/data
    command: --provider local --basedir /data
    # Optional: set public URL for returned links
    # command: --provider local --basedir /data --listener 0.0.0.0:8080 --url https://transfer.example.com

volumes:
  transfer-data:
```

## Install — Docker (S3 backend)

```bash
docker run -d \
  --publish 8080:8080 \
  --name transfer-sh \
  dutchcoders/transfer.sh:v1.6.1-noroot \
  --provider s3 \
  --aws-access-key YOUR_ACCESS_KEY \
  --aws-secret-key YOUR_SECRET_KEY \
  --bucket your-bucket-name \
  --s3-region us-east-1
```

For **MinIO or other S3-compatible storage**, add `--s3-endpoint`:

```bash
docker run -d \
  --publish 8080:8080 \
  --name transfer-sh \
  dutchcoders/transfer.sh:v1.6.1-noroot \
  --provider s3 \
  --aws-access-key minio-access-key \
  --aws-secret-key minio-secret-key \
  --bucket transfers \
  --s3-endpoint https://minio.example.com \
  --s3-region us-east-1
```

## Usage (client side)

```bash
# Upload a file
curl --upload-file ./myfile.tar.gz https://transfer.example.com/myfile.tar.gz
# Returns: https://transfer.example.com/abc123/myfile.tar.gz

# Upload from stdin
cat /var/log/syslog | curl --upload-file - https://transfer.example.com/syslog.txt

# Encrypt before upload
gpg --armor --symmetric --output - /tmp/secret.txt | curl --upload-file - https://transfer.example.com/secret.txt.gpg

# Download
curl https://transfer.example.com/abc123/myfile.tar.gz -o myfile.tar.gz

# Delete (using X-Url-Delete response header)
curl -X DELETE <url-from-X-Url-Delete-header>

# Upload with max downloads and expiry
curl --upload-file ./file.txt https://transfer.example.com/file.txt \
  -H "Max-Downloads: 5" \
  -H "Max-Days: 3"
```

### Shell alias (convenience)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
transfer() {
    curl --upload-file "$1" https://transfer.example.com/$(basename "$1")
}
```

## nginx reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name transfer.example.com;

    client_max_body_size 0;  # allow unlimited uploads (or set a limit)

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;  # stream uploads without buffering
    }
}
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Storage backends | local, s3 (AWS + compatible), gdrive (Google Drive), storj (Storj.io). Set with `--provider`. |
| Public URL | Set `--url` (or `APP_URL` env) to your public HTTPS domain — otherwise returned links contain `localhost`. |
| File expiry | `--purge-days` removes files older than N days. Not set by default — local storage grows unboundedly without it. |
| Max upload size | Controlled by nginx `client_max_body_size` (default 1MB — set to 0 for unlimited) AND `--max-upload-size` flag. |
| Max downloads | Clients can set `Max-Downloads` header per upload. Server-side default configurable with `--max-downloads`. |
| Token auth | Add `--token` to require a pre-shared password for uploads (no auth by default). |
| HTTP/S3 presigned URLs | S3 backend returns direct S3 presigned URLs for downloads (bypasses the server). Requires public or presigned-accessible bucket. |
| TLS | No built-in TLS. Reverse proxy with nginx/Caddy. |

## Key CLI flags

| Flag | Env var | Default | Description |
|---|---|---|---|
| `--provider` | — | — | Storage provider: `local`, `s3`, `gdrive`, `storj` |
| `--basedir` | — | — | Base directory for local storage |
| `--listener` | — | `:8080` | Listen address |
| `--url` | `URL` | — | Public URL returned in upload responses |
| `--max-upload-size` | — | unlimited | Max upload size in bytes |
| `--purge-days` | — | 0 (no purge) | Auto-delete files older than N days |
| `--token` | — | — | Require auth token for uploads |
| `--temp-path` | — | `/tmp` | Temp directory for in-progress uploads |

## Upgrade procedure

```bash
docker pull dutchcoders/transfer.sh:v1.6.1-noroot
docker compose up -d
```

transfer.sh is stateless for local storage — the `/data` volume persists files independently of the container.

## Gotchas

- **`--basedir /tmp` is ephemeral:** The default Docker examples use `/tmp` inside the container. Files are lost on container restart. Mount a host volume or named volume to `/data` and use `--basedir /data` for persistence.
- **nginx `client_max_body_size`:** nginx's default 1MB body limit will block large uploads. Set `client_max_body_size 0;` (unlimited) or a specific size limit in your nginx config.
- **`proxy_request_buffering off`:** Without this, nginx buffers the entire upload to disk before proxying — doubles disk usage for large files. Always set it for upload proxies.
- **`--url` must be set:** Without it, the returned download URL is `http://localhost:8080/...` which is useless from the client's perspective.
- **No auth by default:** Anyone who can reach your transfer.sh instance can upload files. Add `--token` or put it behind nginx basic auth / IP allowlist if running publicly.
- **Avoid `latest` tag with Watchtower:** The `latest` tag can reference dev/nightly builds. Pin to a specific version tag (e.g. `v1.6.1-noroot`) for stable deploys.
- **Low maintenance recently:** Last release was December 2023. The project is stable but not actively developed. Check for security advisories periodically.

## Upstream links

- GitHub: <https://github.com/dutchcoders/transfer.sh>
- Docker Hub: <https://hub.docker.com/r/dutchcoders/transfer.sh>
- Releases: <https://github.com/dutchcoders/transfer.sh/releases>
