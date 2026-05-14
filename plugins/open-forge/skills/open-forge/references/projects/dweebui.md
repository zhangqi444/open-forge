---
name: DweebUI
description: "Simple web UI for managing Docker containers. Docker. Node.js. lllllllillllllillll/DweebUI. Start/stop/pause/restart containers, logs, real-time metrics dashboard, multi-user, templates (Portainer-compatible), Docker Compose support. Beta."
---

# DweebUI

**Free and open-source web UI for managing Docker containers.** A lightweight Portainer alternative: start, stop, pause, restart containers; view logs and details; monitor real-time server and container metrics; multi-user with permissions; install apps from a template library; manage networks/images/volumes; Docker Compose support. Windows/Linux/macOS compatible.

Built + maintained by **lllllllillllllillll**. See repo license. **Beta v0.60.**

- Upstream repo: <https://github.com/lllllllillllllillll/DweebUI>
- Docker Hub: <https://hub.docker.com/r/lllllllillllllillll/dweebui>
- Reddit: <https://www.reddit.com/r/dweebui>

## Architecture in one minute

- **Node.js** (JavaScript) backend + web frontend
- **Tabler** CSS framework for UI
- Connects to Docker via mounted socket (`/var/run/docker.sock`)
- Port **8000** (configurable via `PORT` env var)
- Data in named Docker volume `dweebui`
- Optionally connects to **Podman** socket
- Resource: **low** — Node.js; minimal overhead

## Compatible install methods

| Infra      | Runtime                              | Notes                                         |
| ---------- | ------------------------------------ | --------------------------------------------- |
| **Docker** | `lllllllillllllillll/dweebui`        | **Primary** — Docker Hub                      |

Windows and macOS: see the [wiki setup guide](https://github.com/lllllllillllllillll/DweebUI/wiki/Setup).

## Install via Docker Compose

```yaml
version: "3.9"
services:
  dweebui:
    container_name: dweebui
    image: lllllllillllllillll/dweebui:latest
    environment:
      PORT: 8000
      SECRET: change_this_secret   # CHANGE THIS
    restart: unless-stopped
    ports:
      - 8000:8000
    volumes:
      - dweebui:/app
      - /var/run/docker.sock:/var/run/docker.sock
      # Podman (optional):
      # - /run/podman/podman.sock:/var/run/docker.sock

volumes:
  dweebui:
```

Visit `http://localhost:8000`.

## First boot

1. **Change `SECRET`** before starting (it's the registration shared secret).
2. `docker compose up -d`.
3. Visit `http://localhost:8000`.
4. Click Register → enter the `SECRET` value to create the first (admin) account.
5. Additional users register using the same `SECRET` (or you can gate it).
6. Browse your running containers on the dashboard.
7. Put behind TLS — DweebUI should not be directly exposed to the internet.

## Features overview

| Feature | Details |
|---------|---------|
| Dashboard | Real-time server CPU/RAM/network + per-container metrics |
| Container actions | Start, stop, pause, restart per container |
| Container details | View environment variables, ports, volumes, networks |
| Logs | Live container log streaming |
| Templates | One-click app templates (Portainer-compatible JSON format) |
| Docker Compose | Deploy and manage stacks via Compose |
| Networks | List, create, delete Docker networks |
| Images | List, pull, remove Docker images |
| Volumes | List, create, remove Docker volumes |
| Multi-user | User accounts with permissions system |
| Light/dark mode | Theme toggle |
| Mobile friendly | Responsive UI |
| Podman support | Use Podman socket instead of Docker socket |

## Template compatibility

DweebUI's templates.json format is compatible with Portainer's app template format. You can use any Portainer-compatible template collection, including Lissy93's popular portainer-templates.

## Gotchas

- **Change `SECRET` before starting.** The default `MrWiskers` (in older examples) / `SECRET` placeholder is the registration key. Anyone who knows it can create an account. Change it to a random string.
- **Docker socket = full Docker control.** Mounting `/var/run/docker.sock` gives DweebUI the same level of access as running commands as root. Only trusted users should have access. Don't expose DweebUI directly to the internet.
- **Beta status.** DweebUI is v0.60 — beta. The author notes it started as a learning project and "there may be some rough edges and spaghetti code." Test before relying on it for critical container management.
- **No automatic container updates.** Container update functionality is planned but not yet implemented. Manually pull new images and recreate containers.
- **Volume mount path:** The upstream README mounts the volume at `/app` (not `/app/config`). The compose example in this recipe reflects the current upstream.
- **Wait for v1.0 before contributing.** The author recommends waiting for v1.0 before submitting PRs to avoid wasted effort on features that may be refactored.

## Backup

```sh
# Named volume backup
docker run --rm -v dweebui:/data -v $(pwd):/backup alpine tar czf /backup/dweebui-$(date +%F).tgz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, Docker Hub, multi-user, Portainer-compatible templates, Docker Compose, Podman support. Solo personal project. Beta v0.60. Reddit community.

## Docker-management-family comparison

- **DweebUI** — Node.js, lightweight, multi-user, Portainer templates, Compose, Podman; beta
- **Portainer** — Go, polished, enterprise features, Kubernetes support; heavier
- **Yacht** — Python, simple, templates; less maintained
- **Dockge** — Bun, stack-focused (Compose-centric); different philosophy
- **Lazydocker** — Go, terminal TUI; no web UI

**Choose DweebUI if:** you want a simple web UI for Docker container management with real-time metrics, multi-user, and Portainer-compatible templates — without Portainer's complexity.

## Links

- Repo: <https://github.com/lllllllillllllillll/DweebUI>
- Docker Hub: <https://hub.docker.com/r/lllllllillllllillll/dweebui>
- Reddit: <https://www.reddit.com/r/dweebui>
- Wiki: <https://github.com/lllllllillllllillll/DweebUI/wiki>
