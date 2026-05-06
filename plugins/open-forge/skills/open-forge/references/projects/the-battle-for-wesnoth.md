---
name: the-battle-for-wesnoth
description: The Battle for Wesnoth recipe for open-forge. Covers package install (Linux) and multiplayer server (wesnothd) Docker/source deploy. The Battle for Wesnoth is an open-source turn-based tactical strategy game with singleplayer campaigns and online multiplayer.
---

# The Battle for Wesnoth

Open-source, turn-based tactical strategy game set in a high-fantasy world. Features singleplayer campaigns, online and local hotseat multiplayer, a built-in map editor, and an active modding community. The multiplayer server (`wesnothd`) is self-hostable for LAN or private online play. Upstream: <https://github.com/wesnoth/wesnoth>. Website: <https://www.wesnoth.org>.

**License:** GPL-2.0 · **Language:** C++ · **Stars:** ~6,600

> **Self-hosting note:** This recipe covers self-hosting the **Wesnoth multiplayer server** (`wesnothd`). The game client itself is installed separately by players via Steam, package managers, or the official installers.

## Compatible install methods (multiplayer server)

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Package (Ubuntu/Debian) | `apt install wesnoth-server` | Distro-packaged | Easy LAN/private server setup. |
| Docker | Community images on Docker Hub | Community | Containerized deploy — convenient for VPS. |
| Build from source | <https://github.com/wesnoth/wesnoth/blob/master/INSTALL> | ✅ | Latest version or custom patches. |

## Game client installation (players)

Players install the game client separately — they do not need to build from source:

- **Steam:** <https://store.steampowered.com/app/599390/Battle_for_Wesnoth/>
- **itch.io:** <https://wesnoth.itch.io/battle-for-wesnoth> (Windows and macOS)
- **macOS App Store:** <https://apps.apple.com/us/app/the-battle-for-wesnoth/id1450738104>
- **Linux (Ubuntu/Debian):** `sudo apt install wesnoth`
- **SourceForge:** <https://sourceforge.net/projects/wesnoth/files/> (Windows/macOS installers)

## Multiplayer server — wesnothd

### Install via package (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install wesnoth-server
```

Start and enable:

```bash
sudo systemctl enable --now wesnothd
```

Default port: **15000/TCP**.

### Install via Docker

```bash
docker run -d \
  --name wesnothd \
  -p 15000:15000 \
  wesnoth/wesnothd:latest
```

Or with Docker Compose:

```yaml
services:
  wesnothd:
    image: wesnoth/wesnothd:latest
    restart: unless-stopped
    ports:
      - "15000:15000"
    volumes:
      - wesnoth-data:/var/lib/wesnothd

volumes:
  wesnoth-data:
```

### Build from source

```bash
# Install build dependencies (Ubuntu/Debian)
sudo apt install -y build-essential cmake libboost-all-dev libsdl2-dev \
  libssl-dev gettext pkg-config

git clone https://github.com/wesnoth/wesnoth.git
cd wesnoth

mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_SERVER=ON -DENABLE_GAME=OFF
make -j$(nproc) wesnothd
sudo make install
```

## Server configuration

Configuration file location: `/etc/wesnoth/wesnothd.cfg` (package install) or `~/.wesnoth/wesnothd.cfg`.

Example minimal config:

```ini
[server]
    port = 15000
    motd = "Welcome to my Wesnoth server"
    max_messages = 4
    message_time_period = 10
    disallow_names = "official"

[deny_auth]
    message = "Your client version is too old."
    version = "< 1.10"
[/deny_auth]
[/server]
```

## Connecting players to your server

Players connecting to your private server must:
1. Open the game client
2. Go to **Multiplayer → Connect to Server**
3. Enter your server's IP or hostname and port (default 15000)

Port 15000/TCP must be open in your firewall.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Port | 15000/TCP — open in firewall/security group. |
| Version matching | Server and clients must run compatible versions. The package manager version may lag the latest release — consider building from source for the latest. |
| Saves/replays | Multiplayer replays and saves stored in the `wesnoth-data` volume. |
| TLS | wesnothd does not use TLS — traffic is unencrypted. For private LAN play this is typically acceptable. |
| Mods/UMC | Player-installed add-ons (Unit Make Content) from the in-game add-on manager work with the server without server-side changes. |
| Admin | wesnothd has an admin interface (telnet to control socket). Configure in wesnothd.cfg with `control_socket`. |

## Upgrade procedure

```bash
# Package
sudo apt update && sudo apt upgrade wesnoth-server
sudo systemctl restart wesnothd

# Docker
docker pull wesnoth/wesnothd:latest
docker compose up -d
```

## Gotchas

- **Version mismatch:** Clients on a different minor version than the server cannot join. All players and the server must be on the same version. Coordinate upgrades with players.
- **Port 15000 must be open:** The default port must be reachable from the internet (or LAN). Don't forget firewall and cloud security group rules.
- **No built-in auth:** wesnothd uses a simple username/registration system but no strong authentication. Any player can join with any username that isn't reserved.
- **Official server for public play:** For public internet multiplayer, players typically use the official Wesnoth server (`server.wesnoth.org`). Self-hosting is primarily for private LAN parties or controlled communities.

## Upstream links

- GitHub: <https://github.com/wesnoth/wesnoth>
- Website: <https://www.wesnoth.org>
- Forums: <https://forums.wesnoth.org>
- Discord: <https://discord.gg/battleforwesnoth>
- Install guide: <https://www.wesnoth.org/downloads/>
- Steam: <https://store.steampowered.com/app/599390/Battle_for_Wesnoth/>
