---
name: uptime-kuma-project
description: Uptime Kuma recipe for open-forge. Easy-to-use self-hosted monitoring tool. Covers Docker Compose and Docker command deployment, persistent data, reverse proxy setup, and upgrade procedure. Derived from https://github.com/louislam/uptime-kuma.
---

# Uptime Kuma

Easy-to-use self-hosted monitoring tool. Upstream: <https://github.com/louislam/uptime-kuma>. License: MIT.

Uptime Kuma monitors HTTP(s), TCP, DNS, Ping, WebSocket, Docker containers, Steam game servers, and more. It supports 90+ notification services (Telegram, Discord, Slack, SMTP, Pushover, etc.), status pages, proxy support, and 2FA.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/louislam/uptime-kuma#docker-compose> | yes | Recommended. Persistent data, easy upgrades. |
| Docker command | <https://github.com/louislam/uptime-kuma#-how-to-install> | yes | Quick single-command deploy. |
| Non-Docker (Node.js) | <https://github.com/louislam/uptime-kuma/wiki/%F0%9F%94%A7-How-to-Install> | yes | Bare-metal install. Requires Node.js 18+. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should Uptime Kuma run on?" | Integer default 3001 | Maps to 3001:3001 in compose. |
| preflight | "Where should monitoring data be stored?" | Path default ./data | Mounted to /app/data inside container. |

## Docker Compose install

Upstream: <https://github.com/louislam/uptime-kuma>

```bash
mkdir uptime-kuma && cd uptime-kuma
curl -o compose.yaml https://raw.githubusercontent.com/louislam/uptime-kuma/master/compose.yaml
docker compose up -d
```

### compose.yaml

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    restart: unless-stopped
    volumes:
      - ./data:/app/data
    ports:
      - "3001:3001"
```

Access at http://localhost:3001. On first visit, create an admin account.

### Docker command

```bash
docker run -d --restart=always -p 3001:3001 \
    -v uptime-kuma:/app/data \
    --name uptime-kuma \
    louislam/uptime-kuma:2
```

## Software-layer concerns

### Ports

| Port | Use |
|---|---|
| 3001 | Web UI and API (HTTP) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /app/data | SQLite database, uploaded files, config |

### Storage warning

NFS (Network File System) storage is NOT supported for /app/data. Always map to a local directory or Docker volume.

## Upgrade procedure

1. Pull new image:
```bash
docker compose pull
docker compose up -d
```

Or use the built-in update button in the Uptime Kuma web UI (Settings -> About -> Update).

2. The SQLite database in /app/data is preserved across upgrades.

## Gotchas

- **NFS not supported**: The /app/data directory must be on a local filesystem. NFS mounts cause database corruption.
- **Tag version**: Use louislam/uptime-kuma:2 (major version tag) rather than :latest for more predictable upgrades.
- **Reverse proxy**: For HTTPS, place behind NGINX or Caddy. Uptime Kuma has WebSocket support — ensure your proxy passes WebSocket upgrade headers. See <https://github.com/louislam/uptime-kuma/wiki/Reverse-Proxy>.
- **Push monitors**: Uptime Kuma supports passive "push" monitors where your service sends a heartbeat URL. Useful for monitoring cron jobs.
- **Status pages**: Multiple public status pages can be created and mapped to custom domains.
- **2FA**: Two-factor authentication is available under Settings -> Security.

## Links

- GitHub: <https://github.com/louislam/uptime-kuma>
- Docker Hub: <https://hub.docker.com/r/louislam/uptime-kuma>
- Wiki / reverse proxy setup: <https://github.com/louislam/uptime-kuma/wiki>
- Live demo: <https://demo.kuma.pet/start-demo>
