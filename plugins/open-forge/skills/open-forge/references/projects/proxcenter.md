---
name: proxcenter
description: ProxCenter recipe for open-forge. Enterprise-grade web UI for managing Proxmox VE clusters — multi-cluster, cross-hypervisor migration, workload balancing, and Proxmox Backup Server support. AGPL-3.0 (Community Edition). Install via official curl installer (deploys as Docker Compose). Upstream: https://github.com/adminsyspro/proxcenter-ui
---

# ProxCenter

Modern web management platform for Proxmox Virtual Environment (PVE). Provides a single pane of glass for multiple Proxmox VE clusters and Proxmox Backup Server instances — alternative to VMware vCenter for Proxmox environments. AGPL-3.0 (Community Edition). Upstream: <https://github.com/adminsyspro/proxcenter-ui>. Docs: <https://docs.proxcenter.io/>.

Community Edition is free and AGPL-licensed. An Enterprise Edition adds DRS (Dynamic Resource Scheduler), advanced alerting, and reporting — requires a paid token.

## Compatible install methods

| Method | Upstream source | When to use |
|---|---|---|
| Official install script (Community) | <https://github.com/adminsyspro/proxcenter-ui#quick-start> | Recommended. Single `curl | bash` deploys via Docker Compose. |
| Enterprise install script | <https://proxcenter.io/install/enterprise> | Paid — requires `--token YOUR_TOKEN`. |

## Requirements

- Docker + Docker Compose
- A server with network access to Proxmox API port **8006**
- Proxmox VE 8.x or 9.x (PVE cluster or standalone node)

ProxCenter runs on a **separate host** from Proxmox — it connects to Proxmox over its API. Do not install ProxCenter on the Proxmox node itself.

## Method — Community Edition install script

> **Source:** <https://github.com/adminsyspro/proxcenter-ui#quick-start>

### 1 — Run the install script

```bash
curl -fsSL https://proxcenter.io/install/community | sudo bash
```

The script:
- Installs Docker and Docker Compose if not present
- Downloads and starts the ProxCenter Docker Compose stack
- Places files in `/opt/proxcenter/`

### 2 — Access the UI

ProxCenter listens on port **3000** by default:

```
http://<your-server-ip>:3000
```

Complete the setup wizard to add your first Proxmox VE connection (host, port 8006, API token or username/password).

### 3 — Managing the service

```bash
cd /opt/proxcenter

# View logs
docker compose logs -f

# Update to latest
docker compose pull && docker compose up -d

# Restart
docker compose restart
```

## Configuration

Files in `/opt/proxcenter/`:

| File | Purpose |
|---|---|
| `.env` | Environment variables (port, secrets, feature flags) |
| `config/orchestrator.yaml` | Backend config (Enterprise only) |

### Reverse proxy

If ProxCenter sits behind NGINX or Traefik, enable the **"Behind reverse proxy"** toggle in Connection Settings. This prevents automatic failover from switching to internal Proxmox node IPs that your proxy can't reach.

Example NGINX snippet:
```nginx
server {
    listen 443 ssl;
    server_name proxcenter.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Architecture

- Single process on port 3000 serving both HTTP and WebSocket (live Proxmox stats)
- Connects to Proxmox REST API on port 8006 — requires line-of-sight network access
- NGINX is optional — for SSL termination and reverse proxy only

## Ports

| Port | Service |
|---|---|
| 3000 | ProxCenter web UI (HTTP + WebSocket) |
| 8006 | Proxmox API (outbound from ProxCenter to PVE — not opened by ProxCenter) |

## License

AGPL-3.0 (Community Edition) — <https://github.com/adminsyspro/proxcenter-ui/blob/main/LICENSE>

Enterprise Edition is separately licensed; see <https://proxcenter.io/#comparison> for feature comparison.
