---
name: tsdproxy-project
description: TSDProxy recipe for open-forge. Automatic Tailscale reverse proxy for Docker containers. Label-based config, zero sidecars, automatic HTTPS, multi-port and TCP proxy support, dynamic lifecycle management, and a real-time dashboard.
---

# TSDProxy

Automatic Tailscale reverse proxy for Docker containers. Add one label to any container and it becomes available on your Tailnet with automatic HTTPS — no Tailscale sidecar containers needed per service. Upstream: https://github.com/almeidapaulopt/tsdproxy. Documentation: https://almeidapaulopt.github.io/tsdproxy.

TSDProxy v2. Language: Go. License: MIT. Multi-arch: amd64, arm64. Image: almeidapaulopt/tsdproxy.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host with Tailscale | Docker Engine + Compose | Single TSDProxy container manages all proxied services |
| NAS / homelab with Tailscale | Docker Engine + Compose | Tested on Synology and common homelab setups |
| Non-Docker services | TSDProxy list provider (YAML) | Expose host services or non-Docker apps via a YAML list file |

Requirement: active Tailscale account and tailnet. TSDProxy uses the tsnet library to create Tailscale machines programmatically.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Tailscale account and tailnet name | Required — TSDProxy creates machines in your tailnet |
| auth | Tailscale auth key or OAuth credentials | For headless/automated setup; interactive browser auth works for testing |
| network | Port for TSDProxy dashboard (default: 8080) | |
| config | Config directory path | TSDProxy creates tsdproxy.yaml here on first run |
| per-container | tsdproxy.name label value | Becomes the Tailscale machine hostname (e.g. myapp.tailnet.ts.net) |

## Software-layer concerns

### Config paths

| Item | Path |
|---|---|
| Config file (auto-created) | /config/tsdproxy.yaml (inside container; bind-mount ./config:/config) |
| Persistent data (TLS certs, state) | tsdproxy-data volume (Docker named volume) |
| Docker socket | /var/run/docker.sock (read to discover labeled containers) |

### Docker Compose (core setup)

  services:
    tsdproxy:
      image: almeidapaulopt/tsdproxy:2
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock
        - tsdproxy-data:/data
        - ./config:/config
      ports:
        - "8080:8080"
      extra_hosts:
        - "host.docker.internal:host-gateway"
      restart: unless-stopped

    myapp:
      image: nginx:alpine
      labels:
        tsdproxy.enable: "true"
        tsdproxy.name: "myapp"

  volumes:
    tsdproxy-data:

### Container labels

| Label | Value | Effect |
|---|---|---|
| tsdproxy.enable | "true" | Registers this container with TSDProxy |
| tsdproxy.name | "myapp" | Tailscale machine hostname (myapp.tailnet.ts.net) |
| tsdproxy.port.1 | "443/https:80/http" | HTTPS on 443 -> container port 80 |
| tsdproxy.port.2 | "80/http:8080/http" | HTTP on 80 -> container port 8080 |
| tsdproxy.port.3 | "22/tcp:22/tcp" | TCP proxy for SSH |

### Tailscale authentication

Interactive (first-run): Open dashboard at http://localhost:8080, click the proxy card, authenticate via browser.

Headless/automated: Configure an AuthKey or OAuth in /config/tsdproxy.yaml before adding services. See: https://almeidapaulopt.github.io/tsdproxy/docs/advanced/tailscale/

### Image tags

| Tag | Description |
|---|---|
| almeidapaulopt/tsdproxy:2 | Latest v2 release (recommended) |
| almeidapaulopt/tsdproxy:latest | Latest stable |
| almeidapaulopt/tsdproxy:dev | Latest development build |
| almeidapaulopt/tsdproxy:v2.x.x | Pinned version |

## Upgrade procedure

  docker compose pull
  docker compose up -d

TSDProxy config is in tsdproxy.yaml and the named volume. Check https://almeidapaulopt.github.io/tsdproxy/docs/upgrading/from-v1/ if upgrading from v1.

## Gotchas

- Tailscale account required — TSDProxy is specifically for Tailscale networks; it does not work with WireGuard or other VPN solutions.
- First-run interactive auth — on fresh install without a pre-configured auth key, you must open the dashboard and authenticate via browser before any proxied services become available; automate with AuthKey for unattended setups.
- v1 to v2 migration — TSDProxy v2 introduced label schema changes; existing v1 label configs need updating. See upstream upgrade guide.
- Docker socket access — TSDProxy needs read access to the Docker socket to discover labeled containers; if using a socket proxy, ensure container listing is permitted.
- extra_hosts required — the host.docker.internal:host-gateway line is needed to proxy services running directly on the host (not in Docker).
- Funnel support — to expose services to the public internet (not just your tailnet), add tailscale_funnel option in labels; this routes through Tailscale's Funnel infrastructure.
- TCP proxying — SSH and database ports can be proxied alongside HTTP/HTTPS using the tcp protocol in port labels.

## Links

- Upstream README: https://github.com/almeidapaulopt/tsdproxy
- Documentation: https://almeidapaulopt.github.io/tsdproxy
- Getting Started: https://almeidapaulopt.github.io/tsdproxy/docs/getting-started/
- Docker Labels reference: https://almeidapaulopt.github.io/tsdproxy/docs/providers/docker/
- Port Configuration: https://almeidapaulopt.github.io/tsdproxy/docs/providers/docker/#port-configuration
- Upgrading from v1: https://almeidapaulopt.github.io/tsdproxy/docs/upgrading/from-v1/
- Docker Hub: https://hub.docker.com/r/almeidapaulopt/tsdproxy
