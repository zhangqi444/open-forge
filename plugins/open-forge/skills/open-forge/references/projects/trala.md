---
name: trala
description: Recipe for TraLa — modern dynamic dashboard for Traefik services. Auto-discovers HTTP routers from the Traefik API, auto-detects icons, supports manual services, grouping, and light/dark mode. Single Docker image, no DB.
---

# TraLa

Modern dynamic dashboard for Traefik services. Upstream: https://github.com/dannybouwers/trala

Auto-discovers all HTTP routers from the Traefik API, auto-detects service icons via selfh.st/icons, supports manual services and tag-based grouping, light/dark mode (follows OS), multi-language (EN/DE/NL), multi-arch (amd64/arm64). No database required.

Full documentation: https://www.trala.fyi

## Prerequisites

- Traefik running with `--api.insecure=true` to expose the Traefik API on port 8080
- TraLa must be able to reach the Traefik API host (same Docker network or resolvable hostname)

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose (with Traefik) | Primary method — add TraLa to your existing Traefik compose stack |
| Docker run | Supported; compose preferred |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Traefik API URL | e.g. http://traefik:8080 — must be reachable from the TraLa container |
| optional | Public hostname for TraLa | e.g. trala.your-domain.com — for Traefik label routing |

## Software-layer concerns

**Config:** Single environment variable: `TRAEFIK_API_HOST`. No config file, no database, no volume required for basic use.

**Port:** Container on 8080.

**Traefik API requirement:** Traefik must be started with `--api.insecure=true`. Without this, TraLa cannot query the router list.

**Same network:** TraLa and Traefik must share a Docker network for the container hostname (`http://traefik:8080`) to resolve. Use a named network in compose.

**Manual services:** Services not managed by Traefik can be added manually through the TraLa UI.

**Icons:** Icon auto-detection uses selfh.st/icons database. No configuration needed.

**Image tags:**
- `latest` — latest stable release (recommended)
- `major.minor.patch` — pinned specific version
- `major.minor` — latest patch for a minor version

## Docker Compose (minimal — add to existing Traefik stack)

```yaml
services:
  trala:
    image: ghcr.io/dannybouwers/trala:latest
    restart: unless-stopped
    environment:
      - TRAEFIK_API_HOST=http://traefik:8080
    networks:
      - traefik-net

networks:
  traefik-net:
    external: true
```

## Docker Compose (full example with Traefik)

```yaml
services:
  traefik:
    image: traefik:v3.6
    restart: unless-stopped
    networks:
      - traefik-net
    ports:
      - "80:80"
      - "443:443"
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  trala:
    image: ghcr.io/dannybouwers/trala:latest
    restart: unless-stopped
    networks:
      - traefik-net
    environment:
      - TRAEFIK_API_HOST=http://traefik:8080
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.trala.rule=Host(`trala.your-domain.com`)"
      - "traefik.http.services.trala.loadbalancer.server.port=8080"

networks:
  traefik-net:
    driver: bridge
```

## Upgrade procedure

```bash
docker compose pull trala
docker compose up -d trala
```

No state to migrate — TraLa is stateless. Manual services added via UI may be stored in a browser-local config; check release notes.

## Gotchas

- **Traefik API must be insecure** — `--api.insecure=true` is required. If your Traefik setup has the API locked down, TraLa cannot auto-discover routers.
- **Network isolation** — if Traefik and TraLa are on different Docker networks, `http://traefik:8080` won't resolve. Use the host's LAN IP instead, or put both on a shared network.
- **Only HTTP routers are shown** — TraLa reads Traefik's HTTP router list. TCP/UDP routers are not displayed.
- **Docker Hub as fallback** — primary image is on GitHub Container Registry (`ghcr.io/dannybouwers/trala`); Docker Hub (`dannybouwers/trala`) is a secondary mirror.

## Links

- Upstream repository: https://github.com/dannybouwers/trala
- Full documentation: https://www.trala.fyi
- GitHub Container Registry: https://ghcr.io/dannybouwers/trala
- Docker Hub: https://hub.docker.com/r/dannybouwers/trala
