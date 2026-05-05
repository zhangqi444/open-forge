---
name: SFTPGo Community Edition
description: "Fully featured, event-driven file transfer server — SFTP, FTP/S, WebDAV, and HTTP/S with local, S3, GCS, and Azure Blob storage backends, a web admin/client UI, and extensive hook support. Go. AGPL-3.0."
---

# SFTPGo Community Edition

SFTPGo is a full-featured, highly configurable, event-driven file transfer server supporting SFTP, FTP/S, WebDAV, and HTTP/S protocols. It can store files on local disk, encrypted local disk, S3-compatible object storage, Google Cloud Storage, Azure Blob Storage, or other SFTP servers — all configurable per virtual user.

Maintained by Nicola Murino (drakkan). Widely adopted in production; used by large organizations for secure file exchange. An Enterprise edition provides commercial licensing, professional support, advanced HA, and additional features.

Use cases: (a) SFTP server for secure file exchange with partners (b) S3-backed SFTP gateway (expose S3 buckets via SFTP to legacy clients) (c) managed file transfer (MFT) replacement (d) FTPS server for compliance-regulated industries (e) WebDAV access to cloud storage (f) web-based file upload portal for non-technical users.

Features:

- **Protocols** — SFTP, SCP, FTP/S, WebDAV, HTTP/S REST API
- **Storage backends** — local filesystem, encrypted local, S3 (and compatible: MinIO, Wasabi, etc.), Google Cloud Storage, Azure Blob, other SFTP servers
- **Virtual users** — each user has independent home directory, quota, permissions, and storage backend
- **Web admin UI** — full management interface for users, groups, folders, events
- **Web client UI** — browser-based file manager for end users
- **Event system** — hooks on upload, download, delete, rename, login; HTTP, command, S3/GCS notifications
- **Two-factor authentication** — TOTP support for web admin and users
- **IP filtering** — allowlist/denylist per user
- **Quota management** — per-user file count and size limits
- **Bandwidth throttling** — per-user upload/download limits
- **Password hashing** — bcrypt, argon2id, PBKDF2; LDAP auth integration
- **REST API** — full management API; Swagger docs included
- **Plugins** — auth, notifier, kv store, metadata plugins
- **Cross-platform** — Linux, macOS, Windows, FreeBSD; ARM and x86

- Upstream repo: https://github.com/drakkan/sftpgo
- Docs: https://docs.sftpgo.com/
- Docker Hub: https://hub.docker.com/r/drakkan/sftpgo

## Architecture

- **Single Go binary** — all protocols in one process
- **Database** — SQLite (default/embedded), PostgreSQL, MySQL, CockroachDB for user/config store
- **No message broker required** — event system is built-in
- **TLS** — configure via cert files or ACME
- **Ports** (defaults):
  - `22` — SFTP (or custom port)
  - `21` — FTP
  - `443/8080` — WebDAV + HTTP API + web UI
  - `8090` — Telemetry/metrics

## Compatible install methods

| Infra       | Runtime               | Notes                                                          |
|-------------|-----------------------|----------------------------------------------------------------|
| Linux       | Binary + systemd      | Download release binary; systemd unit included                 |
| Docker      | `drakkan/sftpgo`      | Official image; quick start                                    |
| Docker Compose | with PostgreSQL     | Production setup with persistent DB                            |
| Kubernetes  | Helm chart            | https://github.com/drakkan/sftpgo/tree/main/helm              |
| deb/rpm     | Package repo          | Native packages for Ubuntu/Debian/RHEL                         |
| Windows     | MSI installer         | Runs as Windows service                                        |

## Inputs to collect

| Input          | Example                        | Phase    | Notes                                                      |
|----------------|--------------------------------|----------|------------------------------------------------------------|
| Admin password | strong password                | Install  | First admin user                                           |
| Port           | `2022` (SFTP)                  | Config   | Port 22 requires root; common to run on 2022               |
| Storage        | local / s3 / gcs / azure       | Config   | Default backend for new users                              |
| DB type        | sqlite / postgres              | Config   | SQLite fine for small deployments; Postgres for HA         |
| Domain         | `sftp.example.com`             | TLS      | For FTPS and WebDAV TLS certificates                       |

## Quick start (Docker)

```sh
docker run --name sftpgo \
  -p 2022:2022 \
  -p 8080:8080 \
  -e SFTPGO_HTTPD__BINDINGS__0__PORT=8080 \
  -v sftpgo-data:/var/lib/sftpgo \
  -d drakkan/sftpgo:latest

# Admin UI: http://localhost:8080/web/admin/
# First visit creates the admin account
```

## Docker Compose (with PostgreSQL)

```yaml
services:
  sftpgo:
    image: drakkan/sftpgo:latest
    restart: unless-stopped
    ports:
      - "2022:2022"   # SFTP
      - "8080:8080"   # Web UI + REST API
      - "2121:2121"   # FTP (optional)
    environment:
      - SFTPGO_DATA_PROVIDER__DRIVER=postgresql
      - SFTPGO_DATA_PROVIDER__NAME=sftpgo
      - SFTPGO_DATA_PROVIDER__HOST=db
      - SFTPGO_DATA_PROVIDER__USERNAME=sftpgo
      - SFTPGO_DATA_PROVIDER__PASSWORD=sftpgopass
    volumes:
      - sftpgo-data:/var/lib/sftpgo
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: sftpgo
      POSTGRES_USER: sftpgo
      POSTGRES_PASSWORD: sftpgopass
    volumes:
      - pg-data:/var/lib/postgresql/data

volumes:
  sftpgo-data:
  pg-data:
```

## S3 backend example (per user)

In the web admin, when creating a user:
- Filesystem: S3 Compatible
- Bucket: `my-sftp-bucket`
- Region: `us-east-1`
- Access Key: `AKIA...`
- Secret Key: `...`
- Key Prefix: `users/username/` (optional; isolates each user to a prefix)

Users then see the S3 bucket as their SFTP home directory.

## Data & config layout

- **`/etc/sftpgo/`** or `/var/lib/sftpgo/` — config + data directory
- **`sftpgo.json`** — main configuration file
- **Database** — SQLite at `sftpgo.db` or external PostgreSQL/MySQL
- **Uploaded files** — wherever each user's storage backend points (local path or cloud)

## Upgrade

```sh
# Docker
docker pull drakkan/sftpgo:latest
docker compose up -d

# Binary
systemctl stop sftpgo
# Replace binary
systemctl start sftpgo  # runs DB migrations automatically
```

## Gotchas

- **AGPL-3.0 + proprietary dual license** — the Community edition is AGPL-3.0. If you modify SFTPGo and deploy it as a service, you must open-source modifications. The dual-license notation (`⊘ Proprietary`) in awesome-selfhosted refers to the Enterprise edition, not the community one.
- **Port 22 conflict with SSH** — if your server uses port 22 for SSH, run SFTPGo on a different port (e.g., 2022). You can configure SSH to a non-standard port, or use SFTPGo's port override.
- **S3 key prefix isolation** — when mapping multiple users to the same S3 bucket with different prefixes, ensure prefix configurations don't overlap. A misconfigured prefix could give a user access to another user's files.
- **Event hooks are powerful but need care** — HTTP hooks for upload events make SFTPGo excellent for automation pipelines. Test hooks thoroughly; a failing hook can delay file transfers.
- **FTP is insecure without TLS** — if you enable FTP (not FTPS), credentials and files are transmitted in plaintext. Only enable plain FTP on trusted internal networks; use FTPS for any external access.
- **Quota enforcement is approximate** — quota checks happen at upload time; concurrent uploads may slightly exceed quota before enforcement kicks in.
- **Web client UI requires users to have HTTP access** — users accessing files via the web browser need the HTTP/WebDAV port open to their clients, in addition to SFTP port.
- **Alternatives:** Pure-FTPd (FTP only, simpler), ProFTPD (FTP, mature), OpenSSH (SFTP only, no web UI), FileBrowser (web UI, no SFTP), Nextcloud (full collaboration platform, not just file transfer).

## Links

- Repo: https://github.com/drakkan/sftpgo
- Documentation: https://docs.sftpgo.com/
- Docker Hub: https://hub.docker.com/r/drakkan/sftpgo
- Releases: https://github.com/drakkan/sftpgo/releases
- Helm chart: https://github.com/drakkan/sftpgo/tree/main/helm
- REST API (Swagger): included at `/openapi/` on running instance
