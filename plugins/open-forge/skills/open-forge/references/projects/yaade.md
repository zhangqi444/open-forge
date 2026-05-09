---
name: yaade
description: Yaade is an open-source, self-hosted, collaborative API development environment — a Postman/Hoppscotch alternative with multi-user support, CORS-proxy browser extension, persistent storage, and no Firebase dependency. Upstream: https://github.com/EsperoTech/yaade
---

# Yaade

Yaade ("Yet Another API Development Environment") is a **self-hosted, collaborative API client** built for teams that need to share API collections without relying on cloud sync or external authentication. Unlike Hoppscotch's self-hosted variant (which requires Firebase for persistence), Yaade is developed from the ground up for self-hosting — sensitive API keys and request data stay entirely on your server.

Upstream: <https://github.com/EsperoTech/yaade>  
Docs: <https://docs.yaade.io>  
Docker Hub: `esperotech/yaade`  
License: MIT

## What it does

- **Collaborative collections** — share API request collections across team members with per-user permissions
- **Multi-user management** — create users, manage roles, restrict collection access
- **Persistent storage** — all requests, environments, and variables in an H2 file-based database on the server; no Firebase required
- **REST and WebSocket support** — test both HTTP REST APIs and WebSocket endpoints
- **Markdown documentation** — add human-readable docs alongside API calls
- **Scripts** — run JavaScript scripts as cron jobs or via the API; execute requests or run automated tests
- **Import / export** — import from OpenAPI specs or Postman collections; export to multiple languages and frameworks
- **CORS-proxy extension** — Chrome + Firefox browser extensions proxy requests through the browser to work around CORS restrictions
- **Dark mode default**

## Architecture

- **Single container** — Kotlin backend + React/TypeScript/Vite SPA bundled together
- **H2 embedded file database** — stored in a mounted Docker volume; no separate database container required
- **Port**: `9339`
- **Resource footprint**: low (single JVM process)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker (single container) | Primary method. Volume for persistence. |
| Any Linux host | Docker Compose | Convenience wrapper; same single image. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain or IP to expose Yaade on?" | e.g. `yaade.example.com`. Front with a reverse proxy for TLS. |
| bootstrap | "Admin username?" | Set via `YAADE_ADMIN_USERNAME` env var. Default password is `password` — must change on first login. |
| storage | "Data volume path on host?" | e.g. `/opt/yaade/data`. Mounted at `/app/data` inside the container. |

## Quick-start (Docker run)

```bash
docker volume create yaade

docker run -d \
  --name yaade \
  --restart always \
  -p 9339:9339 \
  -e YAADE_ADMIN_USERNAME=admin \
  -v yaade:/app/data \
  esperotech/yaade:latest
```

Access at `http://<host>:9339`. Default password: `password`.  
**Change the password immediately** at Settings (⚙️) → Account.

## Docker Compose

```yaml
# compose.yaml
services:
  yaade:
    image: esperotech/yaade:latest
    container_name: yaade
    restart: always
    ports:
      - "${YAADE_PORT:-9339}:9339"
    environment:
      YAADE_ADMIN_USERNAME: ${YAADE_ADMIN_USERNAME:-admin}
    volumes:
      - yaade_data:/app/data

volumes:
  yaade_data:
```

```bash
docker compose up -d
```

## Reverse proxy

Yaade serves plain HTTP. For production, front it with Caddy, Traefik, or nginx for TLS termination.

**Caddy example:**

```caddyfile
yaade.example.com {
    reverse_proxy localhost:9339
}
```

## CORS proxy extension

Yaade uses a browser extension to proxy requests and bypass browser CORS restrictions. Install on each team member's browser:

- Chrome: <https://chrome.google.com/webstore/detail/yaade-extension/mddoackclclnbkmofficmmepfnadolfa>
- Firefox: <https://addons.mozilla.org/en-US/firefox/addon/yaade-extension/>

Open the extension and enter your Yaade server URL (e.g. `https://yaade.example.com/`). All requests from Yaade browser tabs will be proxied through it.

Alternatively, proxy requests **through the server** directly — toggle the proxy mode in the request panel.

## Upgrade

```bash
# Docker Compose style (recommended)
docker compose pull && docker compose up -d

# Docker run style
docker rm -f yaade
docker pull esperotech/yaade:latest
docker run -d --name yaade --restart always \
  -p 9339:9339 -e YAADE_ADMIN_USERNAME=admin \
  -v yaade:/app/data esperotech/yaade:latest
```

The H2 database in the volume is preserved across upgrades.

## Backup

```bash
# Dump the named volume to a tar archive
docker run --rm -v yaade:/data -v $(pwd):/backup alpine \
  tar czf /backup/yaade-backup-$(date +%Y%m%d).tar.gz -C /data .
```

## Gotchas

- **Default password is `password`** — change it immediately after first login before exposing the instance publicly.
- **Admin username is set at container start** — changing `YAADE_ADMIN_USERNAME` after first boot does not rename the existing account; recreate the container with the desired username before the first login.
- **CORS extension is per-browser** — each team member installs it locally; it is not deployed server-side.
- **H2 is a single-process embedded DB** — do not run multiple container instances against the same volume; no concurrent-write support.
