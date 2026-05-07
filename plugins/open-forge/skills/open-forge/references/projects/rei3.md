---
name: REI3
description: Free and open low-code platform to build and host powerful business applications. Task management, Gantt charts, workflows, E2EE, REST integration. PostgreSQL backend. MIT licensed.
website: https://rei3.de/home_en/
source: https://github.com/r3-team/r3
license: MIT
stars: 560
tags:
  - low-code
  - business-apps
  - workflow
  - productivity
platforms:
  - Go
  - Docker
---

# REI3

REI3 is a free, open-source low-code platform for building and hosting business applications. Replace spreadsheet workarounds with proper multi-user apps: task boards, Gantt charts, asset tracking, time management, and more. Features built-in E2EE, role-based access control, PDF export, REST endpoints, and a growing marketplace of pre-built applications.

Official site: https://rei3.de/home_en/
Source: https://github.com/r3-team/r3
Docs: https://rei3.de/en/docs
Downloads: https://rei3.de/en/downloads
App marketplace: https://rei3.de/en/applications
Live demo: https://demo.rei3.de/

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS | Docker Compose (x64 or arm64) | Recommended for self-hosting |
| Linux VM / VPS | Native binary + PostgreSQL | For bare-metal deployments |
| Windows Server | Installer + bundled PostgreSQL | Official Windows installer |
| Raspberry Pi / ARM | Docker Compose (arm64 image) | Supported |

## Inputs to Collect

**Phase: Planning**
- Architecture: x64 or arm64
- Deploy method: Docker Compose or native binary
- Admin password (default: admin, change on first login)
- Port to expose (default: 443 HTTPS)
- Whether to use a reverse proxy (Nginx, Caddy) or REI3's built-in TLS

**Phase: First Boot**
- Login at https://localhost with admin/admin
- Change admin password immediately
- Install applications from the marketplace or build your own

## Software-Layer Concerns

**Docker Compose (x64) — fetch official compose file:**

```bash
# Download official Docker Compose file
curl -o docker-compose.yml https://rei3.de/docker_x64
# For arm64:
# curl -o docker-compose.yml https://rei3.de/docker_arm64

docker compose up -d
# Access at https://localhost (self-signed cert by default)
# Default login: admin / admin
```

The official compose file bundles REI3 + PostgreSQL in a single stack.

**Native binary install (Linux x64):**

```bash
# Download binary
curl -L https://rei3.de/latest/x64_linux -o r3.tar.gz
tar -xzf r3.tar.gz

# Optional: image thumbnails and PDF support
sudo apt install imagemagick ghostscript

# Optional: integrated backups
sudo apt install postgresql-client

# Register as systemd service and start
sudo ./r3 -install
sudo systemctl start rei3
# Access at https://localhost
```

**Key data paths (Docker):**
- Database: PostgreSQL volume (managed by compose)
- Application data: REI3 data volume
- Config: managed internally; modify via admin UI

**Reverse proxy (Nginx) — disable REI3 built-in TLS first:**

```nginx
server {
    listen 443 ssl;
    server_name rei3.example.com;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        # Do NOT set client_max_body_size too low — file uploads
        client_max_body_size 100M;
        # Disable proxy read timeout for websockets
        proxy_read_timeout 3600;
    }
}
```

Note: REI3 uses persistent WebSocket connections — disable client timeouts on your proxy.

## Upgrade Procedure

1. **Docker**: `docker compose pull && docker compose up -d`
2. **Native**: Download new binary, stop service, replace binary, restart: `sudo systemctl restart rei3`
3. REI3 handles database migrations automatically on startup
4. Changelog: https://rei3.de/en/news

## Gotchas

- **Default credentials**: Admin login is admin/admin — change immediately after first boot
- **WebSocket timeouts**: If using a reverse proxy, disable client read timeouts for WebSocket connections or users will get disconnected; see https://rei3.de/en/docs/admin#proxies
- **HTTPS by default**: REI3 listens on port 443 with a self-signed cert by default; configure your own cert or use a reverse proxy for production
- **Low-code builder**: REI3 is a platform for building apps, not a pre-built suite; out-of-the-box functionality comes from the app marketplace
- **App marketplace**: Pre-built applications (task management, CRM, inventory, etc.) available at https://rei3.de/en/applications — free to install
- **PostgreSQL required**: REI3 uses PostgreSQL exclusively; the Docker Compose file includes it
- **E2EE**: End-to-end encryption is built-in with integrated key management; enable per-application as needed

## Links

- Upstream README: https://github.com/r3-team/r3/blob/main/README.md
- Documentation: https://rei3.de/en/docs
- Downloads: https://rei3.de/en/downloads
- App marketplace: https://rei3.de/en/applications
- Live demo: https://demo.rei3.de/
- Community forum: https://community.rei3.de
- YouTube tutorials: https://www.youtube.com/channel/UCKb1YPyUV-O4GxcCdHc4Csw
