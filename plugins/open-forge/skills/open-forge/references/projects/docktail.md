# DockTail

**Exposes Docker containers as Tailscale Services automatically — watches container labels and proxies traffic via Tailscale without needing published Docker ports. HTTP, HTTPS, TCP, and Funnel support.**
Official site: https://docktail.org
GitHub: https://github.com/marvinvr/docktail

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux with Tailscale | Docker Compose | Docker host must be connected to Tailscale |

---

## Inputs to Collect

### Required
- Docker host connected to Tailscale — `tailscaled` running on the host
- `TAILSCALE_OAUTH_CLIENT_ID` + `TAILSCALE_OAUTH_CLIENT_SECRET` — for automatic service creation (from Tailscale admin panel)

### Alternative
- Tailscale API key — instead of OAuth client

---

## Software-Layer Concerns

### Docker Compose (DockTail + app example)
```yaml
services:
  docktail:
    image: ghcr.io/marvinvr/docktail:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/run/tailscale:/var/run/tailscale
    environment:
      - TAILSCALE_OAUTH_CLIENT_ID=${TAILSCALE_OAUTH_CLIENT_ID}
      - TAILSCALE_OAUTH_CLIENT_SECRET=${TAILSCALE_OAUTH_CLIENT_SECRET}

  myapp:
    image: nginx:latest
    # No ports: needed — DockTail proxies directly to container IP
    labels:
      - "docktail.service.enable=true"
      - "docktail.service.name=myapp"
      - "docktail.service.port=80"
```

### Common label examples

Expose with Tailscale HTTPS (auto-cert):
```yaml
labels:
  - "docktail.service.enable=true"
  - "docktail.service.name=api"
  - "docktail.service.port=3000"
  - "docktail.service.service-port=443"
```

Expose a database over TCP:
```yaml
labels:
  - "docktail.service.enable=true"
  - "docktail.service.name=db"
  - "docktail.service.port=5432"
  - "docktail.service.protocol=tcp"
  - "docktail.service.service-port=5432"
```

Expose publicly via Tailscale Funnel:
```yaml
labels:
  - "docktail.funnel.enable=true"
  - "docktail.funnel.port=3000"
  - "docktail.funnel.funnel-port=8443"
```

### How it works
- DockTail watches Docker events and reads `docktail.*` labels
- Creates Tailscale Services pointing to the container's Docker network IP
- No need for `ports:` on app containers
- Automatically reconciles when containers restart or IPs change

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Docker host must have `tailscaled` running and be enrolled in your Tailscale network
- DockTail mounts the Tailscale socket at `/var/run/tailscale` — must be accessible on the host
- OAuth client must have permission to create Services in your Tailscale ACLs
- License: AGPL v3

---

## References
- Documentation: https://docktail.org/docs/
- GitHub: https://github.com/marvinvr/docktail#readme
