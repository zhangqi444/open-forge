---
name: hamsterbase-tasks
description: HamsterBase Tasks recipe for open-forge. Local-first task management app with end-to-end encrypted sync via self-hosted server. All features free, no data collection. AGPL-3.0, Docker. Source: https://github.com/hamsterbase/tasks
---

# HamsterBase Tasks

A local-first task management application for planning, organizing, and tracking work. Data is stored on the user's device by default — no spinners, instant access, offline ready. A self-hosted sync server enables multi-device synchronization with end-to-end encryption. All features free, no paywall, no data collection. AGPL-3.0 licensed. Source: <https://github.com/hamsterbase/tasks>. Self-hosted guide: <https://tasks.hamsterbase.com/guide/download/selfhosted.html>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker (single container) | Official image: `hamsterbase/tasks` |
| Any Linux | Docker Compose | Recommended for persistent data management |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Port to expose?" | Number | Default 3000 |
| "Data directory?" | Path | Persisted via Docker volume — e.g. `./data` |
| "Auth token?" | String | Fixed token for client sync; if not set, a random one is generated each restart |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Reverse proxy for HTTPS?" | Yes / No | Recommended for access outside localhost |

## Software-Layer Concerns

- **Local-first**: The app stores data in the browser/device by default. The self-hosted server is only needed for multi-device sync — not for basic use.
- **Auth token**: Clients authenticate to the sync server with a token. Set `AUTH_TOKEN` env var to a fixed value — otherwise a new random token is generated each restart, breaking existing client connections.
- **End-to-end encryption**: Sync data is encrypted client-side before sending to the server — the server cannot read your tasks.
- **Data volume**: Persist `/app/data` in the container to survive restarts.
- **No built-in HTTPS**: Serve behind NGINX or Caddy for TLS — required for mobile clients connecting from outside the LAN.
- **Client apps**: Mobile apps available on Play Store; web app at tasks.hamsterbase.com (can point to your server) or self-hosted.

## Deployment

### Docker run

```bash
mkdir -p ./data

docker run -d \
  --name hamsterbase-tasks \
  -p 3000:3000 \
  -v ./data:/app/data \
  -e AUTH_TOKEN=your-secret-token-here \
  hamsterbase/tasks
```

### Docker Compose

```yaml
services:
  hamsterbase-tasks:
    image: hamsterbase/tasks
    container_name: hamsterbase-tasks
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      - AUTH_TOKEN=your-secret-token-here
```

```bash
docker compose up -d
# Access at http://localhost:3000
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name tasks.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Connect a client to your server

1. In the app, go to **Settings → Self-hosted Settings**
2. Click **Add Self-hosted Server**
3. Enter:
   - **Endpoint**: `https://tasks.example.com` (or `http://localhost:3000` for local)
   - **Auth token**: the value from `AUTH_TOKEN`
   - **Folder**: any name (all syncing clients must use the same folder name)

## Upgrade Procedure

1. `docker compose pull && docker compose up -d`
2. Data in the mounted volume persists across upgrades.

## Gotchas

- **Set AUTH_TOKEN or sync breaks on restart**: Without a fixed `AUTH_TOKEN`, a new random token is generated every container restart — all clients lose sync until reconfigured.
- **Folder name must match**: All devices syncing together must use identical folder names in client settings.
- **HTTPS for mobile**: iOS and Android apps may refuse to connect to plain HTTP servers — use HTTPS with a valid cert for remote access.
- **Local-first = no central data**: If you lose the device and don't have sync configured, your data is gone. Set up the sync server before you need it.

## Links

- Source: https://github.com/hamsterbase/tasks
- Self-hosted guide: https://tasks.hamsterbase.com/guide/download/selfhosted.html
- Website: https://tasks.hamsterbase.com
- Docker Hub: https://hub.docker.com/r/hamsterbase/tasks
