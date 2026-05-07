---
name: Red Eclipse 2
description: Free arena first-person shooter (FPS) inspired by Unreal Tournament. Features parkour movement, various game modes, and a dedicated server for self-hosting. Zlib licensed.
website: https://www.redeclipse.net/
source: https://github.com/redeclipse/base
license: Zlib
stars: 511
tags:
  - game
  - fps
  - arena-shooter
  - multiplayer
platforms:
  - C++
  - Docker
---

# Red Eclipse 2

Red Eclipse 2 is a free, open-source arena first-person shooter inspired by Unreal Tournament. It features fast parkour movement, classic arena modes (Deathmatch, Capture the Flag, Defend and Control, Bomber Ball), and a dedicated server for self-hosting multiplayer games. Available on Linux, macOS, and Windows.

Official site: https://www.redeclipse.net/
Source: https://github.com/redeclipse/base
Downloads: https://www.redeclipse.net/download
Wiki: https://www.redeclipse.net/wiki/
Latest: check https://github.com/redeclipse/base/releases

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS | Dedicated server binary | Headless server for multiplayer |
| Linux / macOS / Windows | Full client | For playing the game |
| Linux | Steam | Available on Steam |

## Inputs to Collect

**Phase: Planning (dedicated server)**
- Server port (default: 28801)
- Server name and description
- Admin password
- Max players
- Map rotation and game modes
- Whether to list on the public master server

## Software-Layer Concerns

**Download and run dedicated server (Linux):**

```bash
# Download the latest Linux release
wget https://github.com/redeclipse/base/releases/latest/download/redeclipse-linux.tar.bz2
tar -xjf redeclipse-linux.tar.bz2
cd redeclipse-linux

# Run dedicated server (headless)
./redeclipse_server
```

**Systemd service example:**

```ini
[Unit]
Description=Red Eclipse 2 Dedicated Server
After=network.target

[Service]
Type=simple
User=games
WorkingDirectory=/opt/redeclipse
ExecStart=/opt/redeclipse/redeclipse_server
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Server config (`config/servinit.cfg`):**

```
// Server settings
serverdesc "My Red Eclipse Server"
serverpass ""
adminpass "CHANGE_ME"
maxplayers 16
serverport 28801
servermasterport 28800

// Public listing (set to 0 to hide from public master server)
updatemaster 1

// Map rotation (optional custom list)
// add map entries here
```

**Firewall ports:**

- 28801/udp — game traffic
- 28800/udp — master server communication (if public listing enabled)

**Game modes available:**
- Deathmatch, Team Deathmatch
- Capture the Flag
- Defend and Control
- Bomber Ball
- Race

## Upgrade Procedure

1. Download new release from https://github.com/redeclipse/base/releases
2. Stop the server: `systemctl stop redeclipse`
3. Extract new version, preserving your `config/servinit.cfg`
4. Start: `systemctl start redeclipse`

## Gotchas

- **Headless server**: `redeclipse_server` binary runs without a display; the full client binary requires a GPU/display
- **UDP ports**: Red Eclipse uses UDP, not TCP — ensure your firewall opens UDP, not just TCP
- **Public master server**: Set `updatemaster 1` to list on the public server browser; set to `0` for private/LAN use
- **Admin password**: Set `adminpass` in config — remote admin via in-game console requires `/setpriv <adminpass>`
- **Game is client-side**: Players download maps and content from the server during first connection; initial join may be slow for custom maps
- **Not a web app**: Self-hosting means running a game server, not a web service

## Links

- Official site: https://www.redeclipse.net/
- Source: https://github.com/redeclipse/base
- Downloads: https://www.redeclipse.net/download
- Wiki: https://www.redeclipse.net/wiki/
- Server setup wiki: https://www.redeclipse.net/wiki/Server_Setup
- Steam: https://store.steampowered.com/app/488080/Red_Eclipse_2/
