---
name: CaddyManager
description: "Web UI for managing Caddy reverse proxy configurations. Docker. Rust + React. caddymanager/caddymanager. CRUD for domains/upstreams/routes, real-time config preview, Caddy API integration, no config file editing. MIT."
---

# CaddyManager

**Web UI for managing Caddy reverse proxy configurations.** Create, edit, and delete reverse proxy routes through a clean React interface — no manual JSON/Caddyfile editing. CaddyManager generates Caddy configurations via the Caddy Admin API, handles automatic TLS (Let's Encrypt), and shows a real-time preview of the generated config. Rust backend + React frontend.

Built + maintained by **caddymanager team**. MIT license.

- Upstream repo: <https://github.com/caddymanager/caddymanager>
- Docker Hub: `ghcr.io/caddymanager/caddymanager` (check repo for image location)

## Architecture in one minute

- **Rust** backend (lightweight API)
- **React** frontend
- Communicates with **Caddy's Admin API** (`http://caddy:2019`) to manage config
- Port **3000** (CaddyManager web UI)
- Caddy ports **80/443** (actual reverse proxy traffic)
- Both run in Docker Compose (CaddyManager + Caddy)
- Resource: **very low** — Rust backend + static React frontend

## Compatible install methods

| Infra              | Runtime                           | Notes                                           |
| ------------------ | --------------------------------- | ----------------------------------------------- |
| **Docker Compose** | `ghcr.io/caddymanager/caddymanager` | **Primary** — runs alongside Caddy              |

## Install via Docker Compose

```yaml
services:
  caddymanager:
    image: ghcr.io/caddymanager/caddymanager:latest
    container_name: caddymanager
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - CADDY_ADMIN_URL=http://caddy:2019
    depends_on:
      - caddy

  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
```

Visit `http://localhost:3000` for the CaddyManager UI.

> **Note:** Check the repo's `docker-compose.yml` for the current canonical example — the compose file in the repo is the authoritative reference.

## First boot

1. Deploy both CaddyManager and Caddy via Docker Compose.
2. Visit `http://localhost:3000`.
3. Add your first **domain** (e.g. `app.example.com`).
4. Set the **upstream** (e.g. `http://myapp:8080`).
5. CaddyManager pushes the config to Caddy via Admin API.
6. Caddy automatically provisions a Let's Encrypt certificate for the domain.
7. Test that the domain routes correctly.
8. Manage all your reverse proxy routes from the web UI.

## Features overview

| Feature | Details |
|---------|---------|
| Route management | Add, edit, delete reverse proxy routes via web UI |
| Domain config | Set domain → upstream per route |
| Auto TLS | Caddy handles Let's Encrypt automatically |
| Config preview | Real-time JSON preview of generated Caddy config |
| Caddy Admin API | Push changes to live Caddy without restarts |
| No file editing | Never touch Caddy JSON or Caddyfile manually |

## Gotchas

- **Caddy Admin API must be accessible.** CaddyManager talks to Caddy on port 2019 (the Caddy Admin API). The Caddy container must be on the same Docker network as CaddyManager, and the Admin API must not be blocked. By default, Caddy's Admin API is `http://localhost:2019` — not HTTPS, and not protected by auth. Keep it on an internal Docker network only.
- **Don't expose Caddy's Admin API externally.** Port 2019 gives full control over Caddy config. Keep it on the internal Docker network; don't publish it to the host.
- **Caddy manages TLS automatically.** As long as your domain DNS points to the server's IP and port 80/443 are open, Caddy provisions Let's Encrypt certs without any configuration. This is Caddy's killer feature — CaddyManager just wires up the routing.
- **Single Caddy instance.** CaddyManager manages one Caddy instance. For multiple servers or a Caddy cluster, this won't work as-is.
- **Early-stage project.** CaddyManager is newer and simpler than alternatives. Check the issue tracker for known limitations before relying on it for production.

## Backup

CaddyManager's configuration is pushed to Caddy via the Admin API and persisted in Caddy's `caddy_config` volume. Back up:
```sh
docker run --rm -v caddy_config:/data -v $(pwd):/backup alpine tar czf /backup/caddy-config-$(date +%F).tgz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Rust + React development, Caddy Admin API integration, real-time config preview. MIT license.

## Caddy-management-family comparison

- **CaddyManager** — Rust+React, web UI for Caddy Admin API, route management, MIT
- **Caddy** (native) — ACME automation + Caddyfile/JSON; powerful without a UI; hard to manage at scale
- **Nginx Proxy Manager** — Node.js, nginx-based, mature, larger community; no Caddy
- **Traefik** — Go, Docker-native auto-discovery; different paradigm; no manual UI needed
- **Zoraxy** — Go, multi-protocol proxy + web UI; more features than CaddyManager

**Choose CaddyManager if:** you already use Caddy and want a simple web UI to manage reverse proxy routes without editing JSON/Caddyfile manually.

## Links

- Repo: <https://github.com/caddymanager/caddymanager>
- Caddy Admin API: <https://caddyserver.com/docs/api>
