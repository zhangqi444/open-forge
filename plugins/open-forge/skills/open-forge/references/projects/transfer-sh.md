---
name: transfer-sh
description: transfer.sh recipe for open-forge. Easy file sharing from the command line — self-hosted Go server. Supports local filesystem, S3, and Google Drive backends. Upstream: https://github.com/dutchcoders/transfer.sh
---

# transfer.sh

Easy and fast file sharing from the command line. A Go server you self-host that lets you upload files with `curl` and share download links instantly.

15,834 stars · MIT

Upstream: https://github.com/dutchcoders/transfer.sh
Docker Hub: https://hub.docker.com/r/dutchcoders/transfer.sh

## What it is

transfer.sh provides a simple HTTP file sharing service:

- Upload files with `curl --upload-file` and get a shareable URL back
- Optional client-side encryption before upload (via GPG)
- Configurable storage backends: local disk, Amazon S3, Google Drive, Storj
- Configurable max file size and TTL (auto-delete)
- Optional virus scanning (ClamAV integration)
- HTTPS support (built-in Let's Encrypt or bring-your-own TLS)
- Optional upload token authentication to restrict who can upload
- Tor `.onion` address support

The maintainers' position is that you should host your own instance rather than rely on any public installations.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (recommended) | https://github.com/dutchcoders/transfer.sh#docker | Easiest — single container |
| Binary | https://github.com/dutchcoders/transfer.sh/releases | Bare metal / VM without Docker |
| Build from source | https://github.com/dutchcoders/transfer.sh#building | Development |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "What domain will transfer.sh be served on?" | All |
| storage | "Storage backend: local, S3, or Google Drive?" | All |
| s3 | "S3 bucket, region, access key, secret key?" | If using S3 |
| max_size | "Max upload file size in bytes? (default: 10 GB)" | All |
| purge_days | "How many days before uploaded files are deleted?" | All |
| token | "Restrict uploads with a token? (yes/no)" | Optional |

## Docker install (recommended)

### Local filesystem storage

    mkdir -p /opt/transfersh/data

    docker run -d \
      --name transfer \
      --restart always \
      -p 8080:8080 \
      -v /opt/transfersh/data:/tmp \
      dutchcoders/transfer.sh:latest \
        --provider local \
        --basedir /tmp/ \
        --listener :8080 \
        --temp-path /tmp/ \
        --log-file /tmp/transfer.log

### S3 storage backend

    docker run -d \
      --name transfer \
      --restart always \
      -p 8080:8080 \
      -e AWS_ACCESS_KEY=<key> \
      -e AWS_SECRET_KEY=<secret> \
      dutchcoders/transfer.sh:latest \
        --provider s3 \
        --aws-access-key $AWS_ACCESS_KEY \
        --aws-secret-key $AWS_SECRET_KEY \
        --bucket your-bucket-name \
        --s3-region us-east-1 \
        --listener :8080

### Docker Compose (local storage)

    services:
      transfer:
        image: dutchcoders/transfer.sh:latest
        restart: always
        ports:
          - "8080:8080"
        volumes:
          - ./data:/tmp
        command: >
          --provider local
          --basedir /tmp/
          --listener :8080
          --temp-path /tmp/
          --max-upload-size 10737418240
          --purge-days 7

## Key CLI flags

| Flag | Default | Description |
|---|---|---|
| `--provider` | required | Storage backend: `local`, `s3`, `gdrive`, `storj` |
| `--listener` | `:8080` | Listen address and port |
| `--basedir` | — | Base directory for local provider |
| `--temp-path` | `/tmp` | Temp upload directory |
| `--max-upload-size` | unlimited | Max file size in bytes |
| `--purge-days` | 0 (no purge) | Auto-delete files after N days |
| `--upload-token` | — | Require this token header for uploads |
| `--lets-encrypt-hosts` | — | Comma-separated domains for auto TLS |
| `--tls-listener` | — | `host:port` for TLS (with cert/key flags) |
| `--clamav-host` | — | ClamAV host for virus scanning |

Full flag reference: https://github.com/dutchcoders/transfer.sh#usage

## HTTPS

### Option 1 — Built-in Let's Encrypt

    docker run -d \
      --name transfer \
      -p 80:80 -p 443:443 \
      -v /opt/transfersh/data:/tmp \
      dutchcoders/transfer.sh:latest \
        --provider local \
        --basedir /tmp/ \
        --temp-path /tmp/ \
        --lets-encrypt-hosts transfer.example.com \
        --listener :80 \
        --tls-listener :443

### Option 2 — Reverse proxy (Caddy)

    transfer.example.com {
        reverse_proxy localhost:8080
    }

## Using your instance

    # Upload a file
    curl --upload-file ./report.pdf https://transfer.example.com/report.pdf

    # Upload and get URL
    curl --upload-file ./file.txt https://transfer.example.com/file.txt
    # Returns: https://transfer.example.com/aBcDeF/file.txt

    # Encrypt before uploading (GPG)
    gpg --armor --symmetric --output - secret.txt | \
      curl --upload-file - https://transfer.example.com/secret.txt.gpg

    # Download
    curl https://transfer.example.com/aBcDeF/file.txt -o file.txt

    # Shell alias for convenience
    transfer() { curl --upload-file "$1" "https://transfer.example.com/$(basename $1)"; }

## Upgrade

    docker pull dutchcoders/transfer.sh:latest
    docker stop transfer && docker rm transfer
    # Re-run the docker run command from your notes

## Gotchas

- **No built-in auth for downloads** — Anyone with the link can download. Upload tokens only restrict who can upload, not who can download. Use for internal/trusted use.
- **Local storage data loss** — Files stored locally are lost if the container's volume is not mounted. Always mount `/tmp` to a host directory.
- **`purge-days 0` means no deletion** — Files accumulate indefinitely without a purge policy. Set `--purge-days` appropriate to your storage capacity.
- **Temp path must be writable** — The `--temp-path` dir is used during upload. Ensure it exists and is writable by the container.
- **No web UI** — transfer.sh is a headless API server. There is no admin dashboard. Interaction is via `curl` or compatible clients.
- **Public installations** — Do not rely on any third-party public transfer.sh instances for sensitive data. Self-host.

## Links

- GitHub: https://github.com/dutchcoders/transfer.sh
- Docker Hub: https://hub.docker.com/r/dutchcoders/transfer.sh
- Usage reference: https://github.com/dutchcoders/transfer.sh#usage
