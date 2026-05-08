---
name: onloc
description: Onloc recipe for open-forge. Self-hosted real-time device location tracking with Android companion app. Docker Compose (API + UI + PostgreSQL + Caddy). Based on upstream deployment repo at https://github.com/onloc-app/onloc-deployment.
---

# Onloc

Self-hosted real-time location tracking and device management service. Track and share location from Android devices; remotely lock or wipe lost/stolen phones. Multi-service stack: Express API, React UI, PostgreSQL, Caddy reverse proxy. AGPL-3.0. Upstream: https://github.com/onloc-app. Images: calvicii/onloc-api and calvicii/onloc-ui (Docker Hub).

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (official stack) | Standard; all components including Caddy |
| Podman Compose | Drop-in alternative to Docker Compose |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "PostgreSQL password?" | String | Replace default onloc password |
| database | "PostgreSQL database name?" | String (default onloc) | |
| network | "Port to expose the UI on?" | Number (default 6144) | Caddy listens here; proxy behind nginx/Caddy as needed |
| storage | "Directory for uploads?" | Host path (default ./uploads) | Mounted to /app/uploads in API container |
| storage | "Directory for PostgreSQL data?" | Host path (default ./data) | Mounted to /var/lib/postgresql/data |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Node.js (Express) API, React UI |
| Database | PostgreSQL 16 (managed by the compose stack) |
| Reverse proxy | Caddy 2 (included in compose stack, handles routing between API and UI) |
| Data dirs | ./uploads (API file uploads), ./data (PostgreSQL data volume) |
| Port | 6144 (Caddy, configurable) |
| Companion apps | Android: https://github.com/onloc-app/onloc-android |
| API health | GET /api/health |
| UI health | GET /health (port 3000 internal) |
| Architectures | Check Docker Hub for available tags |

## Install: Docker Compose

Source: https://github.com/onloc-app/onloc-deployment and https://github.com/onloc-app/onloc-website/blob/main/docs/self-host/installation.mdx

```bash
mkdir ./onloc-app && cd ./onloc-app
curl -L -O https://github.com/onloc-app/onloc-deployment/releases/latest/download/docker-compose.yml
docker compose pull && docker compose up -d
```

The downloaded compose file looks like:

```yaml
services:
  api:
    image: calvicii/onloc-api:latest
    container_name: onloc-api
    environment:
      - DATABASE_URL=postgresql://onloc:onloc@db:5432/onloc?schema=public
      - PORT=4000
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://api:4000/api/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    volumes:
      - ./uploads:/app/uploads:Z

  ui:
    image: calvicii/onloc-ui:latest
    container_name: onloc-ui
    environment:
      - PORT=3000
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://ui:3000/health || exit 1"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s
    depends_on:
      - api
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    container_name: onloc-db
    environment:
      POSTGRES_DB: onloc
      POSTGRES_USER: onloc
      POSTGRES_PASSWORD: onloc
    volumes:
      - ./data:/var/lib/postgresql/data:Z
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U onloc -d onloc"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    restart: unless-stopped

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "6144:80"
    configs:
      - source: caddyfile
        target: /etc/caddy/Caddyfile
    healthcheck:
      test: ["CMD-SHELL", "wget -qO- http://caddy:80 || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    depends_on:
      api:
        condition: service_healthy
```

**Change the default PostgreSQL password** before first run: edit DATABASE_URL in the api service and POSTGRES_PASSWORD in the db service to match.

## Install: Podman Compose

```bash
mkdir ./onloc-app && cd ./onloc-app
curl -L -O https://github.com/onloc-app/onloc-deployment/releases/latest/download/docker-compose.yml
podman compose pull && podman compose up -d
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No manual migration step — Prisma migrations run automatically on API startup.

## Gotchas

- Change the default PostgreSQL password: The default compose file uses onloc:onloc for both user and password. Change both DATABASE_URL and POSTGRES_PASSWORD to a strong secret before first run.
- Android companion required: Onloc is not useful without the Android app to report location. iOS is not currently supported. App: https://github.com/onloc-app/onloc-android
- Caddy handles routing: The compose stack includes Caddy as the internal reverse proxy routing between the API (port 4000) and UI (port 3000). Port 6144 is the single external entry point. Put your own nginx/Caddy/Traefik in front of 6144 for HTTPS.
- :Z volume flag for SELinux: The :Z flag on volume mounts is for SELinux-enabled hosts (Fedora, RHEL). On non-SELinux systems it is harmless but can be removed.
- Fetch compose from releases, not main branch: The official install guide downloads from /releases/latest; this is the tested version. Using the main branch directly may include unreleased changes.

## Links

- Deployment repo: https://github.com/onloc-app/onloc-deployment
- API repo: https://github.com/onloc-app/onloc-api
- UI repo: https://github.com/onloc-app/onloc-ui
- Android app: https://github.com/onloc-app/onloc-android
- Installation guide: https://onloc.app/docs/self-host/installation
- Docker Hub: https://hub.docker.com/u/calvicii/
