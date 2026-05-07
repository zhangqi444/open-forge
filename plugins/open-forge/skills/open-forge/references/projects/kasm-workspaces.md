---
name: kasm-workspaces
description: Kasm Workspaces recipe for open-forge. Containerized desktop and application streaming platform — access full desktops and apps via browser. GPL-3.0 licensed. Source: https://github.com/kasmtech
---

# Kasm Workspaces

A Docker container streaming platform that provides browser-based access to full Linux desktops, applications, and web services. Each session is an isolated, disposable container streamed via KasmVNC over HTTPS. Use cases: remote dev environments, browser isolation, VDI, secure browsing. GPL-3.0 licensed (Community Edition). Source: <https://github.com/kasmtech>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Ubuntu 20.04/22.04 (x86_64/ARM64) | Shell installer | Recommended — single-server install |
| Docker (DinD) | Shell installer | For isolated testing |
| Multi-server | Manual / installer | Separate agent/manager/db nodes |

> Kasm has its own installer — do not deploy via plain docker-compose. The installer sets up Postgres, agents, and a reverse proxy internally.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Server IP or domain?" | IP or FQDN | Used for SSL cert and access URL |
| "Admin password?" | String | Set during install |
| "User password?" | String | Default non-admin user password |
| "Swap size (GB)?" | Integer | 4 GB+ recommended |
| "Kasm version?" | e.g. 1.18.1 | Check kasmweb.com/downloads |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Port?" | 443 (default) | Kasm listens on HTTPS |
| "Multi-server?" | Yes / No | Multi-server = separate installer roles |

## Software-Layer Concerns

- **Self-contained install**: The Kasm installer deploys Postgres, Nginx (with self-signed cert), agent daemon, and manager — no external docker-compose needed.
- **Docker-in-Docker pattern**: Kasm's agent runs Docker containers for each session; the host needs Docker installed.
- **Minimum Docker version**: v25.0.5+ required as of Kasm 1.18.1.
- **Self-signed cert by default**: Replace with Let's Encrypt or your CA cert post-install.
- **Persistent data**: `/opt/kasm/` — contains configs, database, and container profiles.
- **Swap**: Kasm recommends swap space for stability; sessions can spike memory.
- **Workspace images**: Pre-built images on Docker Hub (e.g. `kasmweb/ubuntu-noble-desktop`). Pull on demand or pre-stage.
- **CE vs Workspaces**: Community Edition (free) has seat limits and no enterprise SSO. Paid plans remove limits.
- **Ports**: Default is HTTPS on 443. SSH access separate. Agent uses internal Docker networking.
- **ARM64 support**: Available for all major releases.

## Deployment

### 1. System preparation

```bash
# Ubuntu 22.04 recommended
apt update && apt upgrade -y
apt install -y curl docker.io

# Add swap (if not already present)
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
```

### 2. Download and run installer

```bash
# Replace 1.18.1 with latest from https://kasmweb.com/downloads
cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.18.1.tar.gz
tar -xf kasm_release_1.18.1.tar.gz
cd kasm_release_1.18.1/

# Single-server install
sudo bash install.sh
# Prompts for admin password, user password, and swap confirmation
```

### 3. Access

```
https://<SERVER_IP>
Default admin: admin@kasm.local / <admin_password_set_during_install>
```

### 4. Replace self-signed certificate

```bash
# Copy your cert + key into place
cp /path/to/fullchain.pem /opt/kasm/current/certs/kasm_nginx.crt
cp /path/to/privkey.pem   /opt/kasm/current/certs/kasm_nginx.key
/opt/kasm/bin/stop
/opt/kasm/bin/start
```

### 5. Add workspace images

In the admin UI: **Workspaces → Add Workspace** → pick from the Kasm registry or enter a custom `kasmweb/<image>:<tag>`.

Popular images:
- `kasmweb/ubuntu-noble-desktop:latest` — full Ubuntu 24.04 desktop
- `kasmweb/chrome:latest` — isolated Chrome browser
- `kasmweb/firefox:latest` — isolated Firefox
- `kasmweb/vs-code:latest` — VS Code in browser

## Upgrade Procedure

1. Download the new release tarball
2. `sudo bash upgrade.sh` in the extracted directory
3. Verify Docker is ≥ v25.0.5 before upgrading to 1.18.1+
4. Check release notes for breaking changes

## Gotchas

- **Docker v25.0.5 minimum**: Kasm 1.18.1+ refuses to install on older Docker. Upgrade Docker first.
- **Don't run plain docker-compose**: Kasm's architecture requires its own installer/manager. Direct docker-compose won't replicate the full stack.
- **Self-signed cert on LAN**: Browsers will warn — replace cert for production use.
- **Session containers are ephemeral by default**: Files in workspace are lost when session ends unless persistent profile storage is configured.
- **Port 443 conflict**: If another service uses 443, either move it or run Kasm on a different port with `--proxy-listening-port`.
- **CE seat limit**: Community Edition limits concurrent sessions; Workspaces paid tier removes this.
- **ARM64 workspace images**: Not all `kasmweb/` images have ARM64 variants — check tags before deploying on ARM hosts.

## Links

- Website: https://kasmweb.com/
- Source: https://github.com/kasmtech
- Downloads: https://kasmweb.com/downloads
- Documentation: https://kasmweb.com/docs/latest/
- Install guide: https://kasmweb.com/docs/latest/install/single_server_install.html
- Workspace images: https://hub.docker.com/u/kasmweb
