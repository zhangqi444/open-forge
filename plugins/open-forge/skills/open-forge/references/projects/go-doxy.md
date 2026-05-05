---
name: GoDoxy
description: "Lightweight, performant reverse proxy with WebUI. Auto-configures routes from Docker/Podman labels, manages Let's Encrypt certs, supports OIDC/ForwardAuth SSO, idle-sleep for containers, Proxmox LXC integration, and TCP/UDP forwarding. Written in Go. MIT."
---

# GoDoxy

**What it is:** A simple but feature-rich reverse proxy designed for self-hosters. Automatically discovers Docker/Podman containers via labels, handles SSL cert renewal via DNS-01 challenge, supports idle-sleep (stop containers when idle, wake on request), and provides a WebUI for management and metrics.

**Official site:** https://docs.godoxy.dev  
**GitHub:** https://github.com/yusing/godoxy  
**Docs:** https://docs.godoxy.dev/Home.html  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker host | docker compose | Recommended; uses host network mode |
| Podman host | docker compose | Podman runtime supported |
| Proxmox host | docker compose | LXC container lifecycle integration available |
| Linux (amd64/arm64) | docker compose | Both architectures supported |

---

## Inputs to Collect

### Pre-install
- Domain(s) for proxied services
- DNS provider credentials (for DNS-01 ACME challenge - Let's Encrypt)
- Whether Proxmox integration is needed
- OIDC provider details (if using SSO)

### Runtime
- Docker socket path (default: /var/run/docker.sock)
- GoDoxy UID/GID (default: 1000:1000)
- WebUI hostname/alias
- Listen address for socket proxy (default: 127.0.0.1:2375)

---

## Software-Layer Concerns

### Config paths (relative to compose directory)
- ./config/config.yml - main config file
- ./config/ - all configuration (routes, providers, middleware)
- ./logs/ - access and error logs
- ./certs/ - TLS certificates (Let's Encrypt + agent TLS)
- ./data/ - persistent data
- ./error_pages/ - custom error pages (read-only mount)

### Key env vars
- DOCKER_SOCKET - path to Docker socket (default: /var/run/docker.sock)
- LISTEN_ADDR - socket proxy listen address (default: 127.0.0.1:2375)
- GODOXY_UID / GODOXY_GID - run as specific user (default: 1000)
- TAG - image tag to use (default: latest)

### Ports
- 80 TCP - HTTP (via host network mode)
- 443 TCP - HTTPS (via host network mode)
- WebUI port - configured in config.yml via webui.aliases

---

## docker-compose.yml

```yaml
services:
  socket-proxy:
    container_name: socket-proxy
    image: ghcr.io/yusing/socket-proxy:latest
    environment:
      - ALLOW_START=1
      - ALLOW_STOP=1
      - ALLOW_RESTARTS=1
      - CONTAINERS=1
      - EVENTS=1
      - INFO=1
      - PING=1
      - POST=1
      - VERSION=1
    volumes:
      - ${DOCKER_SOCKET:-/var/run/docker.sock}:/var/run/docker.sock
    restart: unless-stopped
    tmpfs:
      - /run
    ports:
      - ${LISTEN_ADDR:-127.0.0.1:2375}:2375

  app:
    image: ghcr.io/yusing/godoxy:${TAG:-latest}
    container_name: godoxy-proxy
    restart: always
    network_mode: host
    env_file: .env
    user: ${GODOXY_UID:-1000}:${GODOXY_GID:-1000}
    depends_on:
      - socket-proxy
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - all
    cap_add:
      - NET_BIND_SERVICE
    environment:
      - DOCKER_HOST=tcp://${LISTEN_ADDR:-127.0.0.1:2375}
    volumes:
      - ./config:/app/config
      - ./logs:/app/logs
      - ./error_pages:/app/error_pages:ro
      - ./data:/app/data
      - ./certs:/app/certs
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Config hot-reloads automatically when files change - no restart needed for most config changes.

---

## Gotchas

- network_mode: host is required and non-negotiable - GoDoxy binds directly to host ports 80/443
- DNS-01 challenge is required for Let's Encrypt (no HTTP-01 support); needs DNS provider API credentials
- Socket proxy (ghcr.io/yusing/socket-proxy) is strongly recommended over mounting Docker socket directly
- Maxmind account required for IP geolocation / country-based ACL features
- Multi-node setups use agent TLS certs stored in ./certs/

---

## Upstream Docs

- Setup guide: https://docs.godoxy.dev/Home.html
- Docker labels reference: https://docs.godoxy.dev/Docker-labels-and-Route-Files
- DNS-01 providers: https://docs.godoxy.dev/DNS-01-Providers
- Middlewares: https://docs.godoxy.dev/Middlewares
- Multi-node setup: https://docs.godoxy.dev/Configurations#multi-docker-nodes-setup
