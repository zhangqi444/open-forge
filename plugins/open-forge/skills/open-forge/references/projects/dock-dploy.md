---
name: dock-dploy
description: Recipe for Dock-Dploy — a web-based visual builder and manager for Docker Compose files.
---

# Dock-Dploy

Web-based tool for visually building, managing, and converting Docker Compose files, Docker run commands, systemd service files, and more. Includes a marketplace of popular self-hosted services and built-in VPN integration templates. Upstream: https://github.com/hhftechnology/Dock-Dploy. Official site: https://docker-compose.hhf.technology

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux/macOS/Windows host | Docker Compose | Recommended. Pre-built image on Docker Hub: hhftechnology/dock-dploy:latest. Web UI on port 3000. Stateless — no persistent volumes required. |
| Any host with Node.js 18+ | Local/bare-metal | Clone repo, npm install, npm run build, npm run serve. Not recommended for production. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which host port should Dock-Dploy listen on?" | Integer, default 3000 | Maps to container port 3000. |

No persistent storage, authentication, or database is required. Dock-Dploy is a stateless frontend tool — all state lives in the browser session.

## Software-layer concerns

Dock-Dploy is a pure frontend application (React 19 + TypeScript + Vite) served as a static build inside a Node container. There are no server-side secrets, no database, and no persistent volumes needed.

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| NODE_ENV | production | Runtime mode. |

### Resource limits (upstream defaults)

- CPU: 1.0 (limit) / 0.5 (reservation)
- Memory: 512 MiB (limit) / 256 MiB (reservation)

### Ports

- Container port 3000 → host port (default 3000): web UI

## Deploy (Docker Compose)

Using the upstream docker-compose.yml:

```yaml
services:
  dock-dploy:
    image: hhftechnology/dock-dploy:latest
    container_name: dock-dploy
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      resources:
        limits:
          cpus: '1'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
```

```bash
docker compose up -d
```

Open http://<host>:3000 to access the UI.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No database migrations or state to preserve — the application is stateless.

## Gotchas

- Stateless — no login, no saved state between sessions. Compose files must be downloaded/copied from the browser. There is no server-side persistence.
- Docker Hub image tag — the README uses hhftechnology/dock-dploy:latest; the upstream docker-compose.yml defaults to building from source. Use the Docker Hub image for a quick deploy; clone the repo and build locally only if modifying the source.
- No authentication — Dock-Dploy has no built-in access control. If exposing beyond localhost, place behind a reverse proxy with authentication (e.g. nginx basic auth, Authelia, Cloudflare Access).
- Marketplace integration — the "Browse Marketplace" feature fetches templates from https://github.com/hhftechnology/Marketplace. Requires outbound internet access from the user's browser; the container itself does not fetch marketplace data.
- VPN integration templates — Tailscale, WireGuard, Cloudflared, ZeroTier, and Netbird configuration blocks are available via the visual builder. These generate compose YAML; they do not configure the VPN services themselves.

## Links

- GitHub README: https://github.com/hhftechnology/Dock-Dploy
- Docker Hub image: https://hub.docker.com/r/hhftechnology/dock-dploy
- Marketplace templates: https://github.com/hhftechnology/Marketplace
