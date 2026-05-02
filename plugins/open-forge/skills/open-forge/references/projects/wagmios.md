# WagmiOS

**What it is:** A self-hosted Docker management platform built natively for OpenClaw agents. Provides a scoped API key system so AI agents can install apps, manage containers, pull images, and monitor your homelab — with every action visible and auditable. Includes a marketplace of 34+ pre-configured self-hosted apps (Plex, Jellyfin, Ollama, Home Assistant, etc.) deployable in seconds.

**Official URL:** https://github.com/mentholmike/wagmios
**Docker Hub:** `itzmizzle/wagmi` (frontend + backend tags)
**License:** MIT
**Stack:** Go (backend API) + Vite/React (frontend); requires Docker socket access

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; pre-built for x86_64 and ARM64 |
| Homelab (ARM64) | Docker Compose | ARM64 images available; no extra setup |
| Build from source | Docker Compose + build | Clone + `docker compose up -d --build` |

---

## Inputs to Collect

### Pre-deployment
- `WAGMIOS_HOST_PATH` — optional host path for container config data (default: `./data`)

### Runtime (Setup Wizard on first launch)
- API key name (e.g. `openclaw-agent`)
- Permission scopes to grant (see scope system below)

---

## Software-Layer Concerns

**Quick start (pre-built images):**
```bash
curl -O https://raw.githubusercontent.com/mentholmike/wagmios/main/docker-compose.yaml
docker compose up -d
```

**Build from source:**
```bash
git clone https://github.com/mentholmike/wagmios.git
cd wagmios
docker compose up -d --build
```

**Docker Compose:**
```yaml
services:
  frontend:
    image: itzmizzle/wagmi:frontend-latest
    container_name: wagmios-frontend
    ports:
      - "5174:5174"
    environment:
      - VITE_API_URL=http://wagmios-backend:5179
      - VITE_WS_URL=ws://wagmios-backend:5179
    depends_on:
      backend:
        condition: service_healthy

  backend:
    image: itzmizzle/wagmi:backend-latest
    container_name: wagmios-backend
    ports:
      - "5179:5179"
    volumes:
      - wagmios_data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock
      - ${WAGMIOS_HOST_PATH:-./data}/containers:/app/data/containers
    environment:
      - PORT=5179
      - WAGMIOS_DATA_DIR=/app/data
```

**Default ports:**
- Frontend UI: `5174`
- Backend API: `5179`
- Health: `http://localhost:5179/health`

**API scope system — grant exactly what each agent needs:**
- `containers:read` — list containers, view logs
- `containers:write` — start, stop, create containers
- `containers:delete` — remove containers
- `images:read` — list Docker images
- `images:write` — pull and delete images
- `marketplace:read` — browse app marketplace
- `marketplace:write` — install and manage apps

**Real-time activity feed:** WebSocket-powered; shows every action happening in the homelab live.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Docker socket mount required** — the backend needs `/var/run/docker.sock` to manage containers; this grants significant host access, so use the scope system carefully
- **OpenClaw-native** — designed as a management backend for OpenClaw agents; also usable as a standalone homelab dashboard
- **API key is shown once** — save it immediately after the Setup Wizard; it cannot be retrieved later
- **Marketplace installs deploy to the host Docker daemon** — apps installed via the marketplace run as containers on the same Docker host; plan storage and networking accordingly
- **No authentication on UI by default** — the web UI has no login; add a reverse proxy with auth for internet-facing deployments

---

## Links
- GitHub: https://github.com/mentholmike/wagmios
- Wiki: http://wiki.wagmilabs.fun/
