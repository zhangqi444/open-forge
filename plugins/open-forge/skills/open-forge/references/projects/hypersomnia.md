---
name: hypersomnia
description: Hypersomnia recipe for open-forge. Community-driven, free and open source competitive top-down multiplayer shooter inspired by Counter-Strike and Hotline Miami. Written in C++ without a game engine. Supports self-hosted dedicated servers via Docker or AppImage. Source: https://github.com/TeamHypersomnia/Hypersomnia
---

# Hypersomnia

Free and open source competitive top-down multiplayer shooter written in modern C++ without a game engine. Combines Counter-Strike-style bomb defusal gameplay with Hotline Miami's visual style. Playable in-browser (WebAssembly), on Steam, and via native binaries. Supports self-hosted dedicated servers — run your own server via Docker or a headless AppImage. Ships with an in-game map editor. Upstream: https://github.com/TeamHypersomnia/Hypersomnia. Play: https://play.hypersomnia.io/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker / Docker Compose | Linux | Recommended for dedicated servers |
| Headless AppImage | Linux (Ubuntu 22.04+) | Standalone binary, no dependencies |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| server | "Server name?" | Displayed in server browser |
| server | "Max player slots?" | Default: 10 |
| server | "Default arena?" | e.g. de_cyberaqua, de_silo, de_metro |
| server | "RCON (master) password?" | Required for admin access via in-game panel |
| server | "Map rotation list?" | Comma-separated arena names for cycle |
| optional | "Discord webhook URL?" | Posts match results and connect events to Discord |

## Software-layer concerns

### Method 1: Docker Compose (recommended)

  # Download official compose file:
  wget https://raw.githubusercontent.com/TeamHypersomnia/Hypersomnia/refs/heads/master/docker-compose.yaml
  docker compose up -d

  # Default docker-compose.yaml:
  # services:
  #   hypersomnia-server:
  #     image: ghcr.io/teamhypersomnia/hypersomnia-server:latest
  #     pull_policy: daily   # auto-updates daily
  #     volumes:
  #       - /opt/hypersomnia:/home/hypersomniac/.config/Hypersomnia/user
  #     ports:
  #       - '8412:8412/udp'
  #       - '9000:9000/udp'
  #     restart: unless-stopped

### Method 2: docker run

  SERVER_DIR=/opt/hypersomnia
  mkdir -p $SERVER_DIR
  chown 999:999 $SERVER_DIR

  docker run \
    --restart unless-stopped \
    --volume $SERVER_DIR:/home/hypersomniac/.config/Hypersomnia/user \
    -p 8412:8412/udp \
    -p 9000:9000/udp \
    ghcr.io/teamhypersomnia/hypersomnia-server:latest

### Method 3: Headless AppImage (Ubuntu 22.04+)

  wget https://hypersomnia.io/builds/latest/Hypersomnia-Headless.AppImage
  chmod +x Hypersomnia-Headless.AppImage

  # Run in background with daily auto-update:
  nohup ./Hypersomnia-Headless.AppImage --appimage-extract-and-run --daily-autoupdate > /dev/null 2>&1 &

  # Or without fuse (extraction step):
  nohup ./Hypersomnia-Headless.AppImage --appimage-extract-and-run --daily-autoupdate > server.log 2>&1 &

  # Optionally download all community maps (<100 MB):
  ./Hypersomnia-Headless.AppImage --appimage-extract-and-run --sync-external-arenas-and-quit

### Configuration

  # Config dir (Docker): /opt/hypersomnia/conf.d/
  # Config dir (AppImage): ~/.config/Hypersomnia/user/conf.d/

  # Create server.json:
  mkdir -p /opt/hypersomnia/conf.d/
  cat > /opt/hypersomnia/conf.d/server.json << 'CONF'
  {
    "server_start": {
      "slots": 10
    },
    "server": {
      "server_name": "My Hypersomnia Server",
      "arena": "de_cyberaqua",
      "cycle": "LIST",
      "cycle_list": [
        "de_cyberaqua",
        "de_silo",
        "de_metro",
        "de_duel_practice"
      ],
      "sync_all_external_arenas_on_startup": true,
      "daily_autoupdate": false
    },
    "server_private": {
      "master_rcon_password": "your_rcon_password_here"
    }
  }
  CONF

  # Multiple .json files in conf.d/ are merged in lexicographic order.
  # runtime_prefs.json is auto-created and will override conf.d/ values
  # for vars changed at runtime (e.g. current arena, RCON-tweaked settings).

### Ports

  8412/udp   # Main game port (clients connect here)
  9000/udp   # Community server list registration

### RCON administration

  # In your game client: Settings → Client → set RCON password
  # Join your server, press Esc to open the admin panel

## Upgrade procedure

  # Docker (if using pull_policy: daily — automatic):
  docker compose pull && docker compose up -d

  # Docker (manual):
  docker pull ghcr.io/teamhypersomnia/hypersomnia-server:latest
  docker compose up -d --force-recreate

  # AppImage (if --daily-autoupdate is set — automatic on restart):
  # Or re-download the AppImage manually:
  wget -O Hypersomnia-Headless.AppImage https://hypersomnia.io/builds/latest/Hypersomnia-Headless.AppImage

## Gotchas

- **pull_policy: daily**: the official docker-compose.yaml sets `pull_policy: daily`, meaning Docker will auto-pull the latest image on compose up. Set to `if_not_present` if you want pinned versions.
- **daily_autoupdate**: set `server.daily_autoupdate: false` in Docker — image updates are managed by Docker. Set it to `true` only for AppImage deployments.
- **runtime_prefs.json overrides conf.d/**: the server writes runtime changes to `runtime_prefs.json`. If your conf.d/ settings aren't sticking, check `runtime_prefs.json` — it takes precedence.
- **Firewall UDP ports**: game traffic is UDP. Ensure ports 8412 and 9000 are open and port-forwarded if behind NAT.
- **Community map downloads**: players automatically download custom maps from the Hypersomnia map catalogue over HTTPS, or directly from your server via UDP if the catalogue is offline.
- **UID 999**: the Docker container runs as UID 999. Ensure the host directory is owned by UID 999 (`chown 999:999 /opt/hypersomnia`).

## References

- Upstream GitHub: https://github.com/TeamHypersomnia/Hypersomnia
- Server setup guide: https://github.com/TeamHypersomnia/Hypersomnia/blob/master/README_SERVER.md
- Default config reference: https://github.com/TeamHypersomnia/Hypersomnia/blob/master/hypersomnia/default_config.json
- Docker image: https://github.com/TeamHypersomnia/Hypersomnia/pkgs/container/hypersomnia-server
- Play in browser: https://play.hypersomnia.io/
