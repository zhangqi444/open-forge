# Crafty Controller

**What it is:** A Python-based web control panel for Minecraft servers. Launch and manage multiple Minecraft server instances (Java and Bedrock) from a single browser interface, with console access, scheduling, backups, and user management.

**Official URL:** https://craftycontrol.com
**Git:** https://gitlab.com/crafty-controller/crafty-4
**Docs:** https://docs.craftycontrol.com
**Docker Hub:** `arcadiatechnology/crafty-4` / `registry.gitlab.com/crafty-controller/crafty-4:latest`
**License:** GPL-3.0
**Stack:** Python + SQLite; multi-arch (amd64/arm64)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Windows | Portable installer | From GitLab releases |
| Homelab (Pi 4+) | Docker Compose | arm64 supported |

---

## Inputs to Collect

### Pre-deployment
- Timezone (`TZ` env var, e.g. `America/New_York`)
- MC server port range to expose (default: `25500–25600`)
- Admin credentials set on first web UI login

### Runtime
- Java version selection per server (Crafty manages Java internally or uses host Java)
- Server JAR files — upload via web UI or place in `./docker/servers/`

---

## Software-Layer Concerns

**Config:** Primarily via the web UI after first launch. Minimal env vars needed (`TZ`).

**Data volumes:**
```
./docker/backups  → /crafty/backups
./docker/logs     → /crafty/logs
./docker/servers  → /crafty/servers
./docker/config   → /crafty/app/config
./docker/import   → /crafty/import
```

**Ports:**
- `8000` — HTTP web UI
- `8443` — HTTPS web UI
- `8123` — Dynmap
- `19132/udp` — Bedrock
- `25500–25600` — Minecraft server port range
- `5520–5550/udp` — Hytale (future)

**Non-root container:** Runs as `crafty:root` internally — no need to match host UID/GID.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Crafty handles config migrations automatically on startup

---

## Docker Compose (Quick Start)

```yaml
services:
  crafty:
    container_name: crafty_container
    image: registry.gitlab.com/crafty-controller/crafty-4:latest
    restart: always
    environment:
      - TZ=Etc/UTC
    ports:
      - "8000:8000"
      - "8443:8443"
      - "8123:8123"
      - "19132:19132/udp"
      - "25500-25600:25500-25600"
    volumes:
      - ./docker/backups:/crafty/backups
      - ./docker/logs:/crafty/logs
      - ./docker/servers:/crafty/servers
      - ./docker/config:/crafty/app/config
      - ./docker/import:/crafty/import
```

```bash
docker compose up -d && docker compose logs -f
```

---

## Gotchas

- **⚠️ WSL2/Windows Docker Desktop warning:** Stopping or restarting a MC server under Docker on WSL2/Windows 11 has a ~90% chance of corrupting world chunks. Use Docker on native Linux only; use the Windows portable installer on Windows.
- **Port range matters:** Expose enough ports for all servers you plan to run (each server needs its own port)
- **First login:** Create admin user on first web UI visit at `http://localhost:8000`
- **Bedrock requires UDP** — ensure UDP ports are open in firewall
- **Java heap tuning** is done per-server in the UI, not in Docker config

---

## Links
- GitLab: https://gitlab.com/crafty-controller/crafty-4
- Docs: https://docs.craftycontrol.com
- Discord: https://discord.gg/9VJPhCE
- Docker Hub: https://hub.docker.com/r/arcadiatechnology/crafty-4
