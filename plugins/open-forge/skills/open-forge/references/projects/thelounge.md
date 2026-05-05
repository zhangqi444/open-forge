# The Lounge

Modern web-based IRC client designed for self-hosting. The Lounge stays persistently connected to IRC servers so you never miss a message. It provides push notifications, link previews, message history, and a synchronized experience across all your devices.

**Official site:** https://thelounge.chat

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker | Official image; recommended |
| Any Linux host | npm (Node.js) | Direct install via `npm install -g thelounge` |
| Kubernetes | Helm (community) | Community charts available |

---

## Inputs to Collect

### Phase 1 — Planning
- Public or LAN hostname / port
- Auth mode: `public` (no login) or `private` (user accounts required)
- IRC networks to pre-configure (optional)

### Phase 2 — Deployment
- Persistent volume path for config and logs
- Port mapping (default `9000`)

---

## Software-Layer Concerns

### Docker Run

```bash
docker run --detach \
  --name thelounge \
  --publish 9000:9000 \
  --volume thelounge:/var/opt/thelounge \
  --restart always \
  ghcr.io/thelounge/thelounge:latest
```

### Docker Compose

```yaml
services:
  thelounge:
    image: ghcr.io/thelounge/thelounge:latest
    container_name: thelounge
    ports:
      - "9000:9000"
    volumes:
      - thelounge:/var/opt/thelounge
    restart: unless-stopped

volumes:
  thelounge:
```

### User Management

```bash
# Add a user (interactive password prompt)
docker exec -it thelounge thelounge add <username>

# List users
docker exec -it thelounge thelounge list

# Remove a user
docker exec -it thelounge thelounge remove <username>
```

### Key Config (`/var/opt/thelounge/config.js`)
| Option | Default | Description |
|--------|---------|-------------|
| `auth.type` | `"local"` | `"local"` (users file) or `"ldap"` |
| `public` | `false` | `true` = no login required (public mode) |
| `port` | `9000` | Listening port |
| `reverseProxy` | `false` | Set `true` when behind nginx/Traefik |
| `theme` | `"default"` | Built-in themes or custom |
| `prefetch` | `false` | Enable link preview fetching |

### Data Paths
- Config: `/var/opt/thelounge/config.js`
- Users: `/var/opt/thelounge/users/`
- Logs: `/var/opt/thelounge/logs/`
- Packages: `/var/opt/thelounge/packages/` (themes/plugins)

---

## Upgrade Procedure

```bash
docker pull ghcr.io/thelounge/thelounge:latest
docker compose up -d
```

No database migrations; config format is stable across minor versions. Check release notes before major version upgrades.

---

## Gotchas

- **Registry**: Official image is on **GHCR** (`ghcr.io/thelounge/thelounge`), not Docker Hub.
- **Public mode**: Setting `public: true` in config disables authentication entirely — anyone can connect.
- **Reverse proxy**: Set `reverseProxy: true` in config.js and trust the `X-Forwarded-For` header when behind a proxy.
- **Identd port 113**: Default identd port is privileged; use a higher port and NAT it to 113 on the host (or disable identd).
- **Themes/plugins**: Installed via `thelounge install <package>` inside the container; persisted in the volume.
- **IRC bouncer vs client**: The Lounge is a web IRC client that stays connected on the server — it is not a ZNC/WeeChat-style bouncer proxy; it manages its own connections.

---

## References
- GitHub: https://github.com/thelounge/thelounge
- Docker repo: https://github.com/thelounge/thelounge-docker
- Docs: https://thelounge.chat/docs
- GHCR: https://github.com/thelounge/thelounge-docker/pkgs/container/thelounge
