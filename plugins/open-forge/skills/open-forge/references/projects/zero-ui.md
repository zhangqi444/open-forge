---
name: zero-ui
description: "Web UI for a self-hosted ZeroTier network controller. Lightweight SPA (React + Node.js) compatible with the ZeroTier Central API. Supports network creation, member management, and a rule editor. Bundled with a Caddy reverse proxy for auto-HTTPS. GPL-3.0. Note: project is in maintenance mode; ZTNet is the actively-maintained alternative."
---

# ZeroUI

**A web user interface for a self-hosted ZeroTier network controller.** Manages ZeroTier networks and members from a browser without relying on ZeroTier Central cloud. Compatible with the ZeroTier Central API, so CLI tools built for ZeroTier Central work with ZeroUI. Includes a full rule editor, mobile-friendly SPA, and a bundled Caddy reverse proxy for automatic HTTPS. GPL-3.0.

> **Maintenance status**: The upstream author states ZeroUI is *stable and currently does not need much active development*, but is no longer actively maintained. If you need an actively-maintained alternative, see [ZTNet](https://ztnet.network/) (`sinamics/ztnet`).

- Upstream repo: <https://github.com/dec0dOS/zero-ui>
- Docker Hub: `dec0dos/zero-ui`
- Latest tag: v1.5.8

## Architecture in one minute

- **ZeroTier controller** container (`zyclonite/zerotier`) — runs the ZeroTier daemon and its built-in network controller; exposes port **9993/udp** (ZeroTier protocol)
- **ZeroUI backend** container (Node.js + Express) — REST API proxy between the browser and the ZeroTier controller API; serves the React SPA; exposes port **4000** internally
- **Caddy reverse proxy** container — optional; provides automatic HTTPS via Let's Encrypt for public deployments; listens on ports **80** and **443**
- Persistent volumes: `zerotier-one/` (ZeroTier controller state + authtoken), `data/` (ZeroUI session storage, db.json)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| **Docker Compose** | `docker compose up -d --no-build` | **Primary** — upstream-provided compose file |
| **Manual (Node.js)** | `zerotier-one` package + Node.js app | Advanced; requires ZeroTier installed on the host |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| `ZU_DEFAULT_USERNAME` | `admin` | Auth | Admin username set on first run |
| `ZU_DEFAULT_PASSWORD` | (random string) | Auth | Admin password — **change from default `zero-ui` before exposing publicly** |
| `ZU_CONTROLLER_ENDPOINT` | `http://zerotier:9993/` | Network | ZeroTier controller API endpoint (internal to the Compose network) |
| Domain | `vpn.example.com` | TLS | Replace `YOURDOMAIN.com` in the docker-compose.yml Caddy command |
| Data directory | `/srv/zero-ui` | Storage | Parent directory for `zerotier-one/` and `data/` volumes |
| `9993/udp` firewall | open | Network | ZeroTier protocol port — must be reachable from ZeroTier clients |
| `80/tcp`, `443/tcp` firewall | open | TLS | Required for ACME challenge + HTTPS |

## Install

```bash
# 1. Create project directory
mkdir -p /srv/zero-ui && cd /srv/zero-ui

# 2. Download the upstream docker-compose.yml
curl -L -O https://raw.githubusercontent.com/dec0dOS/zero-ui/main/docker-compose.yml

# 3. Edit docker-compose.yml:
#    - Replace YOURDOMAIN.com with your actual domain in the Caddy command
#    - Set ZU_DEFAULT_PASSWORD to a strong random value (e.g. openssl rand -hex 16)

# 4. Pull images and start
docker compose up -d --no-build

# 5. Check logs
docker compose logs -f
```

Open firewall ports:

```bash
# ufw example
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 9993/udp
```

Visit `https://YOURDOMAIN.com` — log in with your `ZU_DEFAULT_USERNAME` / `ZU_DEFAULT_PASSWORD`.

## Docker Compose reference

```yaml
# docker-compose.yml — from upstream (v1.5.8)
version: "3"

services:
  zerotier:
    image: zyclonite/zerotier:1.16.1
    container_name: zu-controller
    restart: unless-stopped
    volumes:
      - ./zerotier-one:/var/lib/zerotier-one
    environment:
      - ZT_OVERRIDE_LOCAL_CONF=true
      - ZT_ALLOW_MANAGEMENT_FROM=0.0.0.0/0
    expose:
      - "9993/tcp"
    ports:
      - "9993:9993/udp"

  zero-ui:
    image: dec0dos/zero-ui:1.5.8
    container_name: zu-main
    restart: unless-stopped
    depends_on:
      - zerotier
    volumes:
      - ./zerotier-one:/var/lib/zerotier-one
      - ./data:/app/backend/data
    environment:
      - ZU_CONTROLLER_ENDPOINT=http://zerotier:9993/
      - ZU_SECURE_HEADERS=true
      - ZU_DEFAULT_USERNAME=admin
      - ZU_DEFAULT_PASSWORD=zero-ui    # CHANGE THIS
    expose:
      - "4000"

  https-proxy:
    image: caddy:latest
    container_name: zu-https-proxy
    restart: unless-stopped
    depends_on:
      - zero-ui
    command: caddy reverse-proxy --from YOURDOMAIN.com --to zero-ui:4000
    volumes:
      - ./caddy:/data/caddy
    ports:
      - "80:80"
      - "443:443"
```

## Environment variables reference

| Variable | Default | Description |
|---|---|---|
| `ZU_CONTROLLER_ENDPOINT` | `http://localhost:9993/` | ZeroTier controller API URL |
| `ZU_CONTROLLER_TOKEN` | read from `/var/lib/zerotier-one/authtoken.secret` | Auth token for the controller API |
| `ZU_DEFAULT_USERNAME` | unset | Admin username (set on first run) |
| `ZU_DEFAULT_PASSWORD` | unset | Admin password (set on first run) |
| `ZU_SECURE_HEADERS` | `true` | Enables Helmet.js security headers |
| `ZU_SERVE_FRONTEND` | `true` | Set `false` to use ZeroUI as a pure REST API backend |
| `ZU_DISABLE_AUTH` | `false` | Set `true` if auth is handled by an upstream proxy |
| `ZU_DATAPATH` | `data/db.json` | ZeroUI session/metadata storage path |
| `ZU_LOGIN_LIMIT` | `false` | Enable login rate limiting |
| `ZU_LOGIN_LIMIT_WINDOW` | `30` | IP ban duration in minutes |
| `ZU_LOGIN_LIMIT_ATTEMPTS` | `50` | Failed login attempts before IP ban |

## Data & config layout

```
/srv/zero-ui/
├── zerotier-one/        # ZeroTier controller state + authtoken (critical backup)
│   ├── authtoken.secret # Controller API auth token
│   └── controller.d/    # Network and member definitions
├── data/
│   └── db.json          # ZeroUI session data and metadata
└── caddy/               # Caddy TLS certificates and state
```

## Upgrade

```bash
cd /srv/zero-ui
docker compose pull && docker compose up -d --no-build
```

Back up `zerotier-one/` and `data/` before upgrading:

```bash
tar cvf backup-$(date +%Y%m%d).tar zerotier-one/ data/
```

## Without HTTPS (LAN / behind existing proxy)

To run without the Caddy sidecar and expose ZeroUI directly on a port:

1. Remove the `https-proxy` service from `docker-compose.yml`
2. Change `expose: ["4000"]` to `ports: ["4000:4000"]` on the `zero-ui` service
3. Set `ZU_SECURE_HEADERS=false`

## Gotchas

- **Change `ZU_DEFAULT_PASSWORD` before exposing to the internet**: the default is `zero-ui` — trivially guessable. A compromised controller can add arbitrary hosts to your ZeroTier network.
- **`ZT_ALLOW_MANAGEMENT_FROM=0.0.0.0/0` exposes the controller API on all interfaces**: this is intentional (ZeroUI's backend needs it), but only port **4000** (ZeroUI) should be publicly accessible — never expose **9993/tcp** (controller API) to the internet. The Caddy proxy and Docker network isolation handle this in the default setup.
- **ZeroTier controller state is in `zerotier-one/`**: this contains all your network definitions and member configs. Back it up before any upgrade or migration.
- **DNS must resolve before Caddy requests the cert**: Caddy obtains Let's Encrypt certs on first request. Verify `dig +short YOURDOMAIN.com` returns the server IP before starting the stack.
- **`ZU_DEFAULT_USERNAME` / `ZU_DEFAULT_PASSWORD` are only set on first run**: if you need to reset credentials, delete `data/db.json` (ZeroUI session data only — ZeroTier network config is unaffected) and restart.
- **Maintenance mode**: ZeroUI is stable but the author is not actively adding features. For a more actively-maintained option, see [ZTNet](https://github.com/sinamics/ztnet) which has similar functionality plus additional network management features.

## Links

- Upstream README: <https://github.com/dec0dOS/zero-ui/blob/main/README.md>
- ZeroTier controller API docs: <https://github.com/zerotier/ZeroTierOne/tree/master/controller/#readme>
- Ansible role: <https://github.com/dec0dOS/zero-ui-ansible>
