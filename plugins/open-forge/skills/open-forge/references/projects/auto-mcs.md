---
name: auto-mcs-project
description: auto-mcs recipe for open-forge. Automated Minecraft server manager with web UI. Create/manage/update servers, mod/plugin manager (Modrinth), automatic backups, scripting API (amscript), access control, crash detection, remote access (Telepath), playit.gg tunnel (no port forwarding). Docker or native binary. Upstream: https://github.com/macarooni-man/auto-mcs
---

# auto-mcs

A Minecraft server manager that handles installation, updates, backups, mods/plugins, and remote access — all from a web UI. No port forwarding required via built-in playit.gg integration. Supports Paper, Purpur, Fabric, Quilt, NeoForge, Forge, Spigot, CraftBukkit, and Vanilla.

Upstream: <https://github.com/macarooni-man/auto-mcs> | Website: <https://www.auto-mcs.com>

Single container. Native binary also available (Windows/macOS/Linux).

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64) | Docker container with web UI |
| Windows / macOS / Linux | Native binary (no Docker needed) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Web UI port?" | `WEB_PORT`; default `8080` |
| security | "Web UI username?" | `WEB_USERNAME`; default `root` — change this |
| security | "Web UI password?" | `WEB_PASSWORD`; default `auto-mcs` — **change this** |
| preflight | "Minecraft server port(s)?" | Default `25565`; add more ports for additional servers |

## Software-layer concerns

### Image

```
macarooniman/auto-mcs:latest
```

Docker Hub: <https://hub.docker.com/r/macarooniman/auto-mcs>

### Compose

```yaml
services:
  app:
    image: macarooniman/auto-mcs:latest
    container_name: auto-mcs
    stdin_open: true
    tty: true
    restart: unless-stopped
    environment:
      WEB_PORT: "8080"
      WEB_USERNAME: "admin"        # change from default "root"
      WEB_PASSWORD: "changeme"     # change from default "auto-mcs"
    ports:
      - "8080:8080"    # web interface (must match WEB_PORT)
      - "7001:7001"    # Telepath remote access API
      - "25565:25565"  # Minecraft server (add more as needed)
    volumes:
      - auto-mcs-data:/root/.auto-mcs

volumes:
  auto-mcs-data:
```

> Source: upstream docker-compose.yml — <https://hub.docker.com/r/macarooniman/auto-mcs>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `WEB_PORT` | `8080` | Web UI port |
| `WEB_USERNAME` | `root` | Web UI login username |
| `WEB_PASSWORD` | `auto-mcs` | Web UI login password — **change this** |

### Features

- **Server creation** — create a Minecraft server in under a minute; preconfigured instant templates
- **Multi-server** — manage multiple servers from one interface; each on its own port
- **Server distributions** — Paper, Purpur, Fabric, Quilt, NeoForge, Forge, Spigot, CraftBukkit, Vanilla
- **Mod & plugin manager** — browse and install from Modrinth; automatic update checks
- **Modpack support** — import Modrinth modpacks (`.zip`/`.mrpack`) or existing server directories
- **Version switching** — change Minecraft version or modloader on the fly without losing data
- **World management** — switch worlds; automatic backups with configurable retention
- **server.properties editor** — built-in GUI editor for all server settings
- **Scripting (amscript)** — universal scripting API + built-in IDE; compatible with Vanilla and all distributions
- **Access control** — firewall-like menu for operators, bans, and whitelist management
- **Crash detection** — detailed crash reports with accessible UI
- **Telepath** — remote management solution; manage servers from anywhere (port `7001`)
- **playit.gg integration** — built-in tunnel support; share your server without port forwarding
- **No data collection** — auto-mcs does not send any data to external systems unless explicitly requested

### Adding more Minecraft server ports

```yaml
ports:
  - "8080:8080"
  - "7001:7001"
  - "25565:25565"   # server 1
  - "25566:25566"   # server 2
  - "25567:25567"   # server 3
```

### Import an existing server

In the web UI: Import → select the root folder of your existing server. auto-mcs copies it to its data directory and creates a backup; the original is untouched.

### Native binary install (no Docker)

```bash
# Download from https://www.auto-mcs.com/download or GitHub releases
# Linux:
chmod +x auto-mcs
./auto-mcs
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Server data persists in the `auto-mcs-data` named volume.

## Gotchas

- **Change default credentials** — `WEB_USERNAME=root` and `WEB_PASSWORD=auto-mcs` are publicly known defaults. Change them before exposing the web UI.
- **`stdin_open: true` + `tty: true` required** — auto-mcs needs a pseudo-TTY to function properly in Docker. Without these flags it may not start correctly.
- **Expose Minecraft ports per server** — each Minecraft server you create needs its own port exposed in the compose `ports:` section. Plan ahead or update the compose file when adding servers.
- **Port `7001` is Telepath** — this is the remote management API. Only expose it if you want remote access; it should be behind auth or a VPN/tunnel if exposed publicly.
- **Data in named volume** — all server data lives in the `auto-mcs-data` volume at `/root/.auto-mcs` inside the container. Back this up regularly.
- **playit.gg tunnel** — if you use the built-in tunnel, you don't need to forward port `25565` on your router, but you do still need to expose it in Docker (the tunnel runs inside the container).

## Links

- Upstream README: <https://github.com/macarooni-man/auto-mcs>
- Website & guides: <https://www.auto-mcs.com/guides>
- Docker Hub: <https://hub.docker.com/r/macarooniman/auto-mcs>
- amscript API: <https://auto-mcs.com/guides/amscript>
- Telepath guide: <https://www.auto-mcs.com/guides/telepath>
- Releases: <https://github.com/macarooni-man/auto-mcs/releases/latest>
