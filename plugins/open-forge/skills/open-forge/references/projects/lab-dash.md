---
name: lab-dash-project
description: Lab Dash recipe for open-forge. Customizable homelab homepage/dashboard with service shortcuts, system info widgets, health checks, and Docker monitoring. AES-256-CBC encrypted config, admin auth, PWA, drag-and-drop layout. Single container. Upstream: https://github.com/AnthonyGress/lab-dash
---

# Lab Dash

A customizable homelab homepage and dashboard. Add shortcuts to your services, system information widgets, service health checks, and custom widgets. Drag-and-drop layout, AES-256-CBC encrypted local config storage, admin-only write access, and PWA support. Single container.

Upstream: <https://github.com/AnthonyGress/lab-dash>

Image: `ghcr.io/anthonygress/lab-dash:latest`

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; privileged for sys stats; Docker socket for container monitoring |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `2022` |
| security | "SECRET key?" | Any random string used for AES-256-CBC encryption of config; generate with `openssl rand -base64 32` |

## Software-layer concerns

### Image

```
ghcr.io/anthonygress/lab-dash:latest
```

### Compose

```yaml
services:
  lab-dash:
    container_name: lab-dash
    image: ghcr.io/anthonygress/lab-dash:latest
    privileged: true
    # network_mode: host  # uncomment for network usage stats monitoring
    #                     # on Ubuntu: sudo ufw allow 2022/tcp
    ports:
      - 2022:2022
    environment:
      - SECRET=YOUR_SECRET_KEY   # generate: openssl rand -base64 32
    volumes:
      - /sys:/sys:ro
      - ./config:/config
      - ./uploads:/app/public/uploads
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

> Source: upstream README / docker-compose.yml — <https://github.com/AnthonyGress/lab-dash>

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `SECRET` | ✅ | Random string for AES-256-CBC config encryption — generate with `openssl rand -base64 32` |

### Widgets available

- **Service shortcuts** — links with icons to your self-hosted services
- **System information** — CPU, RAM, disk usage (requires `/sys` mount + `privileged: true`)
- **Service health checks** — HTTP health polling for your services
- **Custom widgets** — additional configurable components
- **Network usage stats** — requires `network_mode: host` (and firewall rule on Ubuntu: `sudo ufw allow 2022/tcp`)

### Admin access

Only administrator accounts can add/edit/rearrange widgets. Read-only users see the dashboard but cannot modify it.

### Data

- Config stored in `/config` (bind-mount `./config`)
- User uploads (background images, custom icons) in `/app/public/uploads` (bind-mount `./uploads`)
- Config is AES-256-CBC encrypted using the `SECRET` key

### Access

- Local: `http://localhost:2022`
- LAN: `http://192.168.x.x:2022`
- Custom domain: configure reverse proxy + DNS

### PWA

Lab Dash can be installed as a Progressive Web App:
- Chrome (Mac/Windows/Android/Linux): install via browser menu
- Safari (iOS/iPadOS): Share → Add to Home Screen

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Config and uploads persist in bind-mounts across upgrades.

## Gotchas

- **`privileged: true` is required for system stats** — without it, CPU/RAM/disk widgets fail to read `/sys`. If you don't need system stats, you can drop `privileged: true` and the `/sys` mount.
- **Docker socket mount required for container monitoring** — `/var/run/docker.sock:/var/run/docker.sock` gives Lab Dash visibility into running containers. Remove if not needed.
- **`network_mode: host` vs port mapping** — for network usage statistics, use `network_mode: host` (comment out the `ports:` section). On Ubuntu, open the port manually: `sudo ufw allow 2022/tcp`.
- **`SECRET` must be set and stable** — changing `SECRET` after initial setup invalidates the encrypted config. Store it somewhere safe.
- **No multi-user management UI** — admin vs read-only is a simple distinction; there is no full user management interface.

## Links

- Upstream README: <https://github.com/AnthonyGress/lab-dash>
