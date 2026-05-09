---
name: anyappstart
description: Recipe for AnyAppStart — a lightweight control panel to Start/Stop/Restart/View Logs for Docker containers, Systemd services, VMs, and anything else (via user scripts). Supports SSH for remote machines.
---

# AnyAppStart

Lightweight web control panel for managing Docker containers, Systemd services, VMs, and custom processes via user-defined YAML "type" definitions. Supports remote machines over SSH. Built with Go (backend) + React/TypeScript (frontend). No database — config stored in YAML files. Upstream: <https://github.com/aceberg/AnyAppStart>. Official site: <https://github.com/aceberg/AnyAppStart>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker | Recommended. Images: `aceberg/anyappstart` (Docker Hub) or `ghcr.io/aceberg/anyappstart` (GHCR). Web UI on port 8855. Mount Docker socket for Docker management. Optional: add `aceberg/node-bootstrap` container for local Bootstrap themes/icons. |
| Any Linux host | Binary | `.deb`, `.rpm`, `.apk` (Alpine), `.tar.gz`. Architectures: amd64, i386, arm_v5, arm_v6, arm_v7, arm64. amd64 users have a `deb` PPA available. Run as Systemd user service: `systemctl enable --now AnyAppStart@$USER.service`. |
| Docker Compose | Docker Compose | Uses upstream docker-compose.yml — AnyAppStart + optional node-bootstrap for local themes. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which host port should AnyAppStart listen on?" | Integer, default 8855 | Maps to container port 8855. |
| preflight | "What is your timezone?" | TZ string, e.g. `America/New_York` | Required — `TZ` env var. |
| preflight | "Should AnyAppStart manage Docker containers on this host?" | Yes/No | If yes, mount `/var/run/docker.sock`. |
| preflight | "Should AnyAppStart control remote machines over SSH?" | Yes/No | If yes, place SSH private key + known_hosts file in config dir. |
| preflight | "Which config directory should be used for YAML files?" | Path, default `~/.dockerdata/AnyAppStart` | Mounted as volume at `/data/AnyAppStart` inside the container. |

## Software-layer concerns

AnyAppStart stores all its configuration in YAML files inside the config directory (`/data/AnyAppStart` in Docker). There is no database.

### Key environment variables / flags

| Variable / Flag | Default | Purpose |
|---|---|---|
| `TZ` | (required) | Timezone, e.g. `America/New_York` |
| `-d` | `/data/AnyAppStart` (Docker) | Path to config directory |
| `-n` | (empty) | Path to local node-bootstrap (for offline Bootstrap themes/icons) |

### Config directory contents

- `types.yaml` — defines the command types (Docker, Systemd, VM, custom scripts). Must be created/configured after first start. Copy the [example types.yaml](https://github.com/aceberg/AnyAppStart/blob/main/example/types.yaml) as a starting point.
- SSH key + `known_hosts` — only needed if controlling remote machines over SSH. Place in config dir and reference in `types.yaml` SSH entries.

### Ports

- Container port `8855` → host port (configurable): web UI

### Security warning

AnyAppStart has **no built-in authentication**. Restrict access with a firewall, reverse proxy with auth (e.g. Authelia, nginx basic auth, Cloudflare Access), or use [ForAuth](https://github.com/aceberg/ForAuth) (another aceberg app).

## Deploy (Docker Compose)

Based on upstream [docker-compose.yml](https://github.com/aceberg/AnyAppStart/blob/main/docker-compose.yml):

```yaml
services:
  node-bootstrap:       # optional — provides local Bootstrap themes and icons
    image: aceberg/node-bootstrap
    # image: ghcr.io/aceberg/node-bootstrap
    restart: unless-stopped
    ports:
      - "8850:8850"

  anyappstart:
    image: aceberg/anyappstart
    # image: ghcr.io/aceberg/anyappstart
    restart: unless-stopped
    ports:
      - "8855:8855"
    volumes:
      - ~/.dockerdata/AnyAppStart:/data/AnyAppStart
      - /var/run/docker.sock:/var/run/docker.sock   # mount if managing Docker
    command: "-n http://YOUR-ADDRESS:8850"           # optional: point to node-bootstrap
    environment:
      TZ: America/New_York
```

```bash
docker compose up -d
```

Open `http://<host>:8855` to access the UI.

**After first start:** configure `types.yaml` in the config dir. Click "Add Type" in the GUI, or copy the [example types.yaml](https://github.com/aceberg/AnyAppStart/blob/main/example/types.yaml) to the config directory.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Configuration files in the volume are preserved across upgrades. No database migrations needed.

## Gotchas

- **No built-in auth** — AnyAppStart has no login system. Do not expose to the public internet without a reverse proxy authentication layer.
- **types.yaml required** — The app is useless without a `types.yaml` defining what commands to run. Copy the upstream example to get started.
- **Docker socket access** — Mounting `/var/run/docker.sock` gives the container full Docker control on the host. Only do this if you trust AnyAppStart and have network access restricted.
- **SSH from container** — To control remote machines via SSH from inside the Docker container, place the SSH private key and `known_hosts` file inside the config dir (`/data/AnyAppStart/`). Reference them with full paths in `types.yaml` SSH entries.
- **node-bootstrap is optional** — The `node-bootstrap` sidecar provides locally-hosted Bootstrap CSS/JS/icons so the UI works fully offline. Without it, Bootstrap assets are loaded from CDN.
- **`$ITEMNAME` variable** — In `types.yaml`, the placeholder `$ITEMNAME` is dynamically replaced by the actual item name from the `items.yaml`. All Start/Stop/Restart/State/Logs/CPU/Mem commands use this.

## Links

- GitHub README: <https://github.com/aceberg/AnyAppStart>
- Example types.yaml: <https://github.com/aceberg/AnyAppStart/blob/main/example/types.yaml>
- Docker Hub: <https://hub.docker.com/r/aceberg/anyappstart>
- GHCR: <https://ghcr.io/aceberg/anyappstart>
