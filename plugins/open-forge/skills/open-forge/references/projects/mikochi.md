---
name: mikochi
description: Mikochi recipe for open-forge. Minimalist remote file browser for self-hosted servers and NAS. Browse folders, upload/download/delete/rename files, stream to VLC/mpv. Go + Preact, Docker/Kubernetes/deb/rpm. Source: https://github.com/zer0tonin/Mikochi
---

# Mikochi

Minimalist remote file browser for self-hosted servers and NAS. Browse folders, fuzzy search, upload files, create folders, rename, delete, download files/directories (as .tar.gz), and stream directly to VLC or mpv. Clean web UI built with Preact; Go/Gin API backend. Single container deploy. Supports Docker, Kubernetes (Helm chart), .deb, and .rpm packages. MIT licensed.

Upstream: <https://github.com/zer0tonin/Mikochi>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (single container) | Recommended |
| Kubernetes | Helm chart | Available on ArtifactHub |
| Debian/Ubuntu/Mint | .deb package | From GitHub Releases |
| Fedora/RHEL/CentOS | .rpm package | From GitHub Releases |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Data directory path | Directory to browse/manage |
| config | Username | Login credential |
| config | Password | Login credential (required — no default in production) |
| config | Port | Default: 80 (HOST=0.0.0.0:80) |
| config (optional) | JWT secret | Auto-generated if not set; set manually if you need stable tokens |
| config (optional) | TLS cert + key paths | For direct HTTPS without a reverse proxy |

## Software-layer concerns

### Env vars

| Var | Description | Default |
|---|---|---|
| HOST | ip:port to listen on | 0.0.0.0:80 |
| DATA_DIR | Directory to expose | /data |
| USERNAME | Login username | root |
| PASSWORD | Login password | pass |
| JWT_SECRET | JWT signing secret | [random on each start] |
| CERT_CA | Path to TLS certificate | (disabled) |
| CERT_KEY | Path to TLS key | (disabled) |
| NO_AUTH | Disable auth (true/false) | false |
| GZIP | Enable gzip compression | false |
| FRONTEND_FILES | Path to static frontend files | /usr/share/mikochi/static |

> **JWT_SECRET note:** Leave unset for auto-random — this invalidates all tokens on restart (forces re-login), which is a useful security property. Set manually only if you need tokens to survive restarts.

## Install — Docker

```bash
docker run -d \
  --name mikochi \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /path/to/your/files:/data \
  -e HOST=0.0.0.0:8080 \
  -e DATA_DIR=/data \
  -e USERNAME=admin \
  -e PASSWORD=yourpassword \
  zer0tonin/mikochi:latest
```

## Install — Docker Compose

```yaml
services:
  mikochi:
    image: zer0tonin/mikochi:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /path/to/your/files:/data
    environment:
      HOST: 0.0.0.0:8080
      DATA_DIR: /data
      USERNAME: admin
      PASSWORD: yourpassword
```

## Install — Kubernetes (Helm)

```bash
helm repo add zer0tonin https://zer0tonin.github.io/helm-charts/
helm install mikochi zer0tonin/mikochi \
  --version 1.10.0 \
  --set mikochi.username=admin \
  --set mikochi.password=yourpassword \
  --set persistence.enabled=true
```

## Install — Debian/Ubuntu .deb

```bash
wget https://github.com/zer0tonin/Mikochi/releases/download/1.10.0/mikochi-1.10.0-linux-amd64.deb
sudo apt install ./mikochi-1.10.0-linux-amd64.deb
sudo mkdir -p /data

# Run with env vars
PASSWORD=yourpassword mikochi

# Or as systemd service (set env vars in /etc/mikochi or override systemd unit)
```

## Upgrade procedure

Docker:
```bash
docker pull zer0tonin/mikochi:latest
docker compose up -d
```

Helm:
```bash
helm upgrade mikochi zer0tonin/mikochi --reuse-values
```

.deb: download new `.deb` from releases and `sudo apt install` to upgrade.

## Gotchas

- `PASSWORD=pass` is the default — **always override it** before exposing Mikochi to any network. The default credentials are widely known.
- `JWT_SECRET` randomizes on each restart by default, invalidating all active sessions and forcing users to log in again. This is intentional — set a stable value only if session persistence across restarts matters.
- `DATA_DIR` must match the container mount point — if you mount `/host/files:/data` but set `DATA_DIR=/files`, Mikochi won't find the files.
- Streaming to VLC/mpv requires the client machine to have VLC or mpv installed and associated with `vlc://` and `mpv://` URL schemes.
- No folder-level permissions — all authenticated users see the entire `DATA_DIR`. Use multiple instances with different mounts for per-user isolation.

## Links

- Source: https://github.com/zer0tonin/Mikochi
- DockerHub: https://hub.docker.com/r/zer0tonin/mikochi
- Helm chart: https://artifacthub.io/packages/helm/zer0tonin/mikochi
- Tutorial (with Traefik): https://alicegg.tech/2024/01/04/mikochi-tutorial
