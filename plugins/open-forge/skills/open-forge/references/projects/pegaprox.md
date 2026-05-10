---
name: pegaprox
description: Recipe for self-hosting PegaProx, a modern multi-cluster management dashboard for Proxmox VE and XCP-ng — unified control, VM management, live monitoring, and cross-cluster migrations. Based on upstream documentation at https://github.com/PegaProx/project-pegaprox.
---

# PegaProx

Modern web-based management interface for Proxmox VE and XCP-ng hypervisor clusters. Manage multiple clusters from a single dashboard: live monitoring, VM management, automated tasks, VNC/SSH console, and cross-cluster VM migrations. Upstream: <https://github.com/PegaProx/project-pegaprox>. Docs: <https://docs.pegaprox.com>. Stars: 1.2k+. License: AGPL-3.0.

**Requires existing Proxmox VE or XCP-ng clusters** — PegaProx is a management layer, not the hypervisor itself.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker (single run) | Quick start |
| Debian/Ubuntu | APT repository | Stable versioned releases; production recommended |
| Any Linux host | Source / Python | Development or advanced use |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Proxmox VE or XCP-ng cluster IP(s) | Added in the web UI after deploy |
| preflight | Cluster API credentials | Proxmox: user@realm + API token or password; XCP-ng: XAPI credentials |
| optional | PEGAPROX_BEHIND_PROXY | Set to `true` if running behind a reverse proxy |
| optional | PEGAPROX_TRUSTED_PROXIES | CIDR range of trusted proxies (e.g. 172.16.0.0/12) |
| optional | PEGAPROX_ALLOWED_ORIGINS | CORS origin for reverse proxy setups |

## Docker Compose deployment

```bash
curl -O https://raw.githubusercontent.com/PegaProx/project-pegaprox/refs/heads/main/docker-compose.yml
docker compose up -d
```

Web UI: http://localhost:5000

## docker-compose.yml

```yaml
services:
  pegaprox:
    image: ghcr.io/pegaprox/pegaprox:latest
    container_name: pegaprox
    ports:
      - "5000:5000"   # web UI + API
      - "5001:5001"   # VNC websocket (noVNC console)
      - "5002:5002"   # SSH websocket (xterm.js)
    volumes:
      - pegaprox-config:/app/config
      - pegaprox-logs:/app/logs
    restart: unless-stopped
    # Reverse proxy settings (uncomment if needed):
    # environment:
    #   PEGAPROX_BEHIND_PROXY: "true"
    #   PEGAPROX_TRUSTED_PROXIES: "172.16.0.0/12"
    #   PEGAPROX_ALLOWED_ORIGINS: "https://pegaprox.example.com"

volumes:
  pegaprox-config:
  pegaprox-logs:
```

## APT repository (Debian — production recommended)

```bash
curl https://git.gyptazy.com/api/packages/gyptazy/debian/repository.key \
  -o /etc/apt/keyrings/gyptazy.asc
echo "deb [signed-by=/etc/apt/keyrings/gyptazy.asc] https://packages.gyptazy.com/api/packages/gyptazy/debian trixie main" \
  | sudo tee /etc/apt/sources.list.d/gyptazy.list
apt-get update && apt-get install -y pegaprox
```

## Ports

| Port | Purpose |
|---|---|
| 5000 | Web UI and REST API |
| 5001 | VNC WebSocket (noVNC in-browser console) |
| 5002 | SSH WebSocket (xterm.js terminal) |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# APT
apt-get update && apt-get upgrade pegaprox
```

Config and data in `pegaprox-config` and `pegaprox-logs` volumes are preserved across upgrades.

## Gotchas

- PegaProx is a **management layer** — it connects to existing Proxmox VE or XCP-ng APIs. It does not run the hypervisor itself.
- All three ports (5000, 5001, 5002) should be reachable from your browser for full functionality. VNC and SSH console features will not work if ports 5001/5002 are blocked by a firewall.
- When running behind a reverse proxy, set `PEGAPROX_BEHIND_PROXY=true` and `PEGAPROX_TRUSTED_PROXIES` to your proxy CIDR to preserve correct client IP logging and CORS behavior.
- Beta software (v0.9.9.x as of writing) — API and config format may change between versions.
- The automated install script pulls from HEAD (latest unreleased code). For production, use the APT repository for versioned stable releases.

## Upstream docs

- README: https://github.com/PegaProx/project-pegaprox/blob/main/README.md
- Documentation: https://docs.pegaprox.com
