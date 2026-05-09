---
name: lancommander
description: Recipe for LANCommander — open-source digital game distribution platform for LAN parties and local networks. Docker + SQLite. Based on upstream README at https://github.com/LANCommander/LANCommander and Docker Hub https://hub.docker.com/r/lancommander/lancommander.
---

# LANCommander

Open-source digital game distribution and management platform designed for LAN parties and local closed networks. Self-hostable server built on ASP.NET Blazor + SQLite. Players access games via the official LANCommander launcher (Windows). Supports game archives, scripting (install/uninstall/before-launch hooks), server management, beacons for auto-discovery, and optional SteamCMD + WINE integration. Official site / docs: <https://lancommander.app/>. Upstream: <https://github.com/LANCommander/LANCommander>.

**Platform note**: The server (this recipe) runs on Linux, Windows, or macOS. The official launcher client is **Windows-only** (tested; Linux/macOS builds exist but are not officially supported). Docker image runs the Linux server build.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host / VM (x86_64) | Docker | Recommended for server; supported by upstream |
| Linux host / VM (arm64) | Docker | Supported (multi-arch image) |
| Windows host | Docker or bare binary | Windows Server binary available via GitHub Releases |
| macOS host | Docker or bare binary | Unofficial; not tested by upstream |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| storage | "Path on host to store game archives and app data?" | Mounted to `/app/Data` in container — games can be large (tens of GB+) |
| network | "What port should LANCommander listen on?" | Default `1337`; web interface |
| options | "Enable SteamCMD support?" | Set `STEAMCMD=1` env var; installs SteamCMD at `/app/Data/Steam` |
| options | "Enable WINE support?" | Set `WINE=1` env var; installs WINE for running Windows game scripts |
| timezone | "Server timezone?" | Set `TZ` env var (e.g. `America/New_York`) |

## Software-layer concerns

- **Image**: `lancommander/lancommander:latest` (Docker Hub). Multi-arch: amd64 + arm64.
- **Database**: SQLite — auto-created at `/app/Data`. No external database required.
- **Data directory**: `/app/Data` inside the container. Contains:
  - SQLite database
  - Game archives (uploaded through the web UI)
  - SteamCMD (if `STEAMCMD=1`) at `/app/Data/Steam`
  - WINE environment (if `WINE=1`) at `/home/wine/.wine`
  - All config files (changeable under Settings in the web UI)
- **Ports**:
  - `1337/tcp` — web interface
  - `35891/udp` — beacon broadcast (LAN auto-discovery)
  - `213/udp` — IPX relay (legacy LAN game protocols)
- **SteamCMD**: optional; installed when `STEAMCMD=1`. Cached credentials persist in `/app/Data/Steam/.steam` across restarts.
- **WINE**: optional; installed when `WINE=1`. Provides `wine32`, `wine64`, `winetricks`. Used for running Windows game install/launch scripts on the Linux server.
- **Server management**: features for managing dedicated game servers may be limited on the Linux Docker image.

## Docker Compose

Based on the upstream README:

```yaml
services:
  lancommander:
    image: lancommander/lancommander:latest
    container_name: lancommander
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      # Uncomment to install SteamCMD:
      # - STEAMCMD=1
      # Uncomment to install WINE:
      # - WINE=1
    volumes:
      - /path/to/app/data:/app/Data
    ports:
      - 1337:1337/tcp    # Web interface
      - 35891:35891/udp  # Beacon broadcast
      - 213:213/udp      # IPX relay
    restart: unless-stopped
```

Start:

```bash
docker compose up -d
# Open http://<host>:1337
```

On first start, LANCommander creates the SQLite database and prompts for initial admin setup via the web UI.

## Getting started

1. Open `http://<host>:1337` and complete the initial setup wizard.
2. Upload game archives via the web UI (**Games → Add Game**).
3. Configure scripts (install, uninstall, before-launch hooks) per game as needed.
4. Players install the [LANCommander launcher](https://lancommander.app/) on their Windows machines and connect to your server URL.

**Games**: LANCommander is a distribution/management platform only — it does not bundle any games. Use DRM-free, freeware, shareware, or abandonware games. See the Discord for pre-packaged freeware game libraries.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the [GitHub Releases](https://github.com/LANCommander/LANCommander/releases) for changelog before upgrading across major versions. The SQLite database and game archives in `/app/Data` persist across upgrades.

## Gotchas

- **Launcher is Windows-only.** The server runs on Linux/macOS/Windows via Docker, but the official client launcher that players use has only been tested on Windows. Linux and macOS launcher builds exist but are unofficial.
- **Game storage can be large.** Mount a volume with ample space — game archives can be tens of gigabytes. The host path mapped to `/app/Data` needs to accommodate all uploaded games.
- **SteamCMD and WINE are installed at container start.** Setting `STEAMCMD=1` or `WINE=1` triggers installation the first time the container starts — this adds to initial startup time.
- **Beacon UDP port 35891.** Required for LAN auto-discovery (clients find the server automatically). If deploying on a network with strict UDP filtering, clients will need to connect manually by server IP/hostname.
- **IPX relay port 213.** For legacy LAN game protocols (older games that use IPX). Skip this port mapping if you don't need it.
- **No TLS built-in.** For public-facing access (outside LAN), deploy behind a reverse proxy with TLS. For LAN party use on a closed network, HTTP is typically acceptable.
- **PUID/PGID.** Set to the UID/GID of the user who owns the data directory on the host to avoid permission issues with the mounted volume.
- **All config paths can be changed in Settings.** The web UI allows remapping data directories — useful if you want game archives on a separate volume from the SQLite database.

## References

- Upstream README: https://github.com/LANCommander/LANCommander
- Documentation: https://docs.lancommander.app/
- Docker Hub: https://hub.docker.com/r/lancommander/lancommander
- Discord: https://discord.gg/vDEEWVt8EM
