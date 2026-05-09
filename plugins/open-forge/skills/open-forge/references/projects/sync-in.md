---
name: sync-in
description: Sync-in is a self-hosted platform for file storage, synchronization, and collaboration — OIDC/LDAP/MFA auth, Collabora/OnlyOffice integration, WebDAV, full-text search, role-based access, and desktop/CLI clients. MariaDB + Node.js Docker stack. Upstream: https://github.com/Sync-in/server
---

# Sync-in

Sync-in is a **self-hosted file storage, synchronization, and collaboration platform** designed for individuals and organizations that want full control over their files. It provides a modern web interface, desktop sync client, WebDAV access, and deep collaborative editing via Collabora Online or OnlyOffice — with enterprise-grade authentication (OIDC, LDAP, MFA).

Upstream: <https://github.com/Sync-in/server>  
Website: <https://sync-in.com>  
Docs: <https://sync-in.com/docs>  
Docker Hub: `syncin/server`  
License: AGPL-3.0  
Supported by the Docker-Sponsored Open Source Program.

## What it does

- **File storage + sync** — upload, organize, and sync files across devices
- **Desktop client** — cross-platform app for background sync (<https://github.com/Sync-in/desktop>)
- **WebDAV** — native support for remote file access from file explorers and third-party tools
- **OIDC / SSO** — federated authentication and Single Sign-On
- **LDAP** — enterprise directory integration
- **MFA** — multi-factor authentication, recovery codes, application passwords
- **Spaces + Shares** — fine-grained permissions and role-based access control
- **Collaborative editing** — Collabora Online and OnlyOffice integration (opt-in via Compose profiles)
- **Full-text search** — deep document content indexing across multiple formats
- **File activity tracking** — comments, notifications, change history
- **Storage quotas + file locking**

## Architecture

- **`syncin/server`** — Node.js backend + web frontend (single image)
- **MariaDB 11** — primary database
- **Port**: `8080`
- **Optional**: nginx reverse proxy, OnlyOffice, Collabora, desktop release server (separate Compose includes)
- **Config**: `environment.yaml` file mounted into the container

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Primary method. MariaDB + app container. |
| Any Linux host | npm | Alternative for non-Docker deployments. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for Sync-in?" | e.g. `files.example.com`. Used in TLS + OIDC callback URLs. |
| database | "MariaDB root password?" | Set in compose env; also referenced in `environment.yaml`. |
| auth | "Encryption key for tokens?" | Strong random string for `auth.encryptionKey` in `environment.yaml`. |
| auth | "Access token secret?" | For `auth.token.access.secret`. |
| auth | "Refresh token secret?" | For `auth.token.refresh.secret`. |
| bootstrap | "Initial admin username / email / password?" | Set via `INIT_ADMIN`, `INIT_ADMIN_LOGIN`, `INIT_ADMIN_PASSWORD` env vars. |
| optional | "Enable Collabora Online?" | Uncomment the collabora include in `docker-compose.yaml`. |
| optional | "Enable OnlyOffice?" | Uncomment the onlyoffice include + set `onlyOfficeSecret` in `environment.yaml`. |

## Setup

### 1. Clone / create config files

```bash
mkdir -p /opt/sync-in && cd /opt/sync-in

# Download compose file
curl -sLO https://raw.githubusercontent.com/Sync-in/server/main/docker/docker-compose.yaml

# Download the environment template
curl -sLO https://raw.githubusercontent.com/Sync-in/server/main/docker/environment.yaml
```

### 2. Edit `environment.yaml`

```yaml
mysql:
  url: mysql://root:${MYSQL_ROOT_PASSWORD}@mariadb:3306/sync_in
auth:
  encryptionKey: <strong-random-key>
  token:
    access:
      secret: <strong-random-access-secret>
    refresh:
      secret: <strong-random-refresh-secret>
applications:
  files:
    dataPath: /app/data
    collabora:
      enabled: false          # set true + uncomment compose include to enable
    onlyoffice:
      enabled: false          # set true + uncomment compose include to enable
      secret: onlyOfficeSecret
```

### 3. Create `.env`

```bash
cat > .env << EOF
MYSQL_ROOT_PASSWORD=your-strong-db-password
INIT_ADMIN=Admin
INIT_ADMIN_LOGIN=admin@example.com
INIT_ADMIN_PASSWORD=your-admin-password
PUID=8888
PGID=8888
EOF
```

### 4. Start

```bash
docker compose up -d
```

Access at `http://<host>:8080`.

## Docker Compose (full reference)

```yaml
# docker-compose.yaml (from upstream docker/docker-compose.yaml)
# Uncomment include lines below to add nginx, OnlyOffice, or Collabora
#include:
#  - ./config/nginx/docker-compose.nginx.yaml
#  - ./config/onlyoffice/docker-compose.onlyoffice.yaml
#  - ./config/collabora/docker-compose.collabora.yaml

name: sync-in
services:
  sync_in:
    image: syncin/server:2
    container_name: sync-in
    restart: always
    environment:
      - INIT_ADMIN
      - INIT_ADMIN_PASSWORD
      - INIT_ADMIN_LOGIN
      - PUID=${PUID:-8888}
      - PGID=${PGID:-8888}
    ports:
      - "8080:8080"
    volumes:
      - ./environment.yaml:/app/environment/environment.yaml
      - data:/app/data
      - desktop_releases:/app/static/releases:ro
    depends_on:
      - mariadb
    networks:
      - sync_in_network

  mariadb:
    image: mariadb:11
    container_name: mariadb
    restart: always
    command: --innodb_ft_cache_size=16000000 --max-allowed-packet=1G
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: sync_in
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - sync_in_network

networks:
  sync_in_network:
    driver: bridge

volumes:
  data:
  mariadb_data:
  desktop_releases:
```

## Reverse proxy

Sync-in serves plain HTTP on port `8080`. For HTTPS, front with Caddy or nginx. Upstream provides a Caddy/nginx include via the `docker/config/nginx/` directory.

**Caddy example:**

```caddyfile
files.example.com {
    reverse_proxy sync-in:8080
}
```

## Upgrade

```bash
cd /opt/sync-in
docker compose pull && docker compose up -d
```

## Backup

```bash
# Database dump
docker exec mariadb mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} sync_in \
  > sync-in-db-$(date +%Y%m%d).sql

# File data volume
docker run --rm -v sync-in_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/sync-in-data-$(date +%Y%m%d).tar.gz -C /data .
```

## Gotchas

- **`environment.yaml` is required** — the app will not start without this file mounted. Copy and edit the upstream template before first `docker compose up`.
- **Encryption / token secrets are write-once** — changing `encryptionKey` or token secrets after users have logged in will invalidate all existing sessions and stored encrypted data. Generate strong values before first start.
- **INIT_ADMIN env vars only apply on first boot** — after the admin account is created they are ignored; changing them does not update the existing account.
- **`--innodb_ft_cache_size` flag on MariaDB** is required for full-text search indexing to work correctly — do not remove the `command:` override.
- **PUID/PGID** — the container runs as a non-root user with these IDs. Ensure the host data volume is writable by this UID.
