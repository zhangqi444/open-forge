---
name: CaddyManager
description: "Web UI for managing Caddy reverse proxy configurations. Docker. MEVN stack (Node.js/Express backend + Vue.js frontend). caddymanager/caddymanager. Multi-server management, SQLite or MongoDB storage, JWT auth, audit logging, Caddy API integration. MIT."
---

# CaddyManager

**Web UI for managing multiple Caddy2 reverse proxy servers.** Create, edit, and manage Caddyfiles and server configurations through a web interface. CaddyManager generates Caddy configurations via the Caddy Admin API. Built on the MEVN stack (Node.js/Express backend, Vue.js frontend); defaults to SQLite for zero-setup.

Built + maintained by **caddymanager team**. MIT license. Early development (pre-v0.1).

- Upstream repo: <https://github.com/caddymanager/caddymanager>
- Docker images: `caddymanager/caddymanager-backend:latest` and `caddymanager/caddymanager-frontend:latest`

> Warning: Early development. Project is gearing up for v0.1. Back up Caddy configurations before testing.

## Architecture in one minute

- **Node.js/Express** backend (API server, Caddy API integration, JWT auth, audit logging)
- **Vue.js** frontend (web UI, proxies `/api/*` requests to backend)
- **SQLite** (default) or **MongoDB** for persistent storage
- Default admin credentials: `admin` / `caddyrocks` -- **change after first login**
- Backend port **3000** (internal only, not exposed directly to host)
- Frontend port **80** (web UI, proxies API calls to backend)

## Compatible install methods

| Infra              | Runtime                                 | Notes                                           |
| ------------------ | --------------------------------------- | ----------------------------------------------- |
| **Docker Compose** | Two containers: backend + frontend      | Primary path -- optional MongoDB via profile    |

## Inputs to collect

| Input | Example | Notes |
|-------|---------|-------|
| `JWT_SECRET` | random string | Change in production -- signs session tokens |
| `DB_ENGINE` | `sqlite` (default) or `mongodb` | SQLite works out of the box |
| `CADDY_SANDBOX_URL` | `http://caddy:2019` | Caddy Admin API URL for config testing |
| `CORS_ORIGIN` | `http://localhost:80` | Set to your frontend URL |
| Admin password | change from `caddyrocks` | Default on first run; change immediately |

## Install via Docker Compose

```yaml
services:
  # Optional MongoDB -- use 'docker compose --profile mongodb up' to include
  mongodb:
    image: mongo:8.0
    container_name: caddymanager-mongodb
    restart: unless-stopped
    environment:
      - MONGO_INITDB_ROOT_USERNAME=mongoadmin
      - MONGO_INITDB_ROOT_PASSWORD=someSecretPassword
    volumes:
      - mongodb_data:/data/db
    networks:
      - caddymanager
    profiles:
      - mongodb

  backend:
    image: caddymanager/caddymanager-backend:latest
    container_name: caddymanager-backend
    restart: unless-stopped
    environment:
      - PORT=3000
      - DB_ENGINE=sqlite
      - SQLITE_DB_PATH=/app/data/caddymanager.sqlite
      - MONGODB_URI=mongodb://mongoadmin:someSecretPassword@mongodb:27017/caddymanager?authSource=admin
      - CORS_ORIGIN=http://localhost:80
      - LOG_LEVEL=debug
      - CADDY_SANDBOX_URL=http://localhost:2019
      - PING_INTERVAL=30000
      - PING_TIMEOUT=2000
      - AUDIT_LOG_MAX_SIZE_MB=100
      - AUDIT_LOG_RETENTION_DAYS=90
      - JWT_SECRET=your_jwt_secret_key_here
      - JWT_EXPIRATION=24h
    volumes:
      - sqlite_data:/app/data
    networks:
      - caddymanager

  frontend:
    image: caddymanager/caddymanager-frontend:latest
    container_name: caddymanager-frontend
    restart: unless-stopped
    depends_on:
      - backend
    environment:
      - BACKEND_HOST=backend:3000
      - APP_NAME=Caddy Manager
      - DARK_MODE=true
    ports:
      - "80:80"
    networks:
      - caddymanager

networks:
  caddymanager:
    driver: bridge

volumes:
  mongodb_data:
  sqlite_data:
```

Visit `http://localhost:80`. Default credentials: `admin` / `caddyrocks` -- change immediately.

## First boot

1. `docker compose up -d`
2. Visit `http://localhost:80`
3. Log in with `admin` / `caddyrocks` -- change password immediately
4. Add a Caddy server (provide its Admin API URL, e.g. `http://caddy:2019`)
5. Create and manage Caddyfiles via the web UI

## Features

| Feature | Details |
|---------|---------|
| Multi-server | Add, remove, monitor multiple Caddy2 servers |
| Config editor | Edit Caddyfiles with syntax highlighting and templates |
| Auth | JWT sessions, RBAC, API key management |
| Audit logging | Track all user and system actions |
| Dual DB | SQLite (default, zero-setup) or MongoDB |
| Swagger docs | Backend API docs at `/api-docs` |

## Gotchas

- **Change default credentials.** Admin `admin`/`caddyrocks` is created on first run. Change immediately.
- **Backend not directly exposed.** All API traffic routes through the frontend proxy (`/api/*` to backend:3000). Do not publish the backend port externally.
- **Caddy Admin API security.** CaddyManager connects to each Caddy server's Admin API (port 2019 by default). Keep on internal Docker networks -- the Admin API gives full config control with no auth.
- **SQLite default.** Zero-config; data in `sqlite_data` volume. Switch to MongoDB with `DB_ENGINE=mongodb` + the mongodb compose profile.
- **JWT_SECRET required for production.** Use a long random secret. Changing it invalidates all active sessions.
- **Early development.** Pre-v0.1. Check issue tracker for known limitations. Back up Caddy config volumes before testing.

## Backup

```sh
docker run --rm -v caddymanager_sqlite_data:/data -v $(pwd):/backup alpine tar czf /backup/caddymanager-$(date +%F).tgz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Links

- Repo: <https://github.com/caddymanager/caddymanager>
- Caddy Admin API: <https://caddyserver.com/docs/api>
