---
name: openttd
description: OpenTTD recipe for open-forge. Transport simulation game with dedicated server support. Covers Linux dedicated server via apt/binary/Docker and openttd.cfg configuration. Upstream: https://github.com/OpenTTD/OpenTTD
---

# OpenTTD

Open-source transport simulation game based on Transport Tycoon Deluxe. Build and manage railways, roads, airports, and shipping networks. Supports multiplayer with a dedicated server mode for persistent hosted games.

7,830 stars · GPL-2.0

Upstream: https://github.com/OpenTTD/OpenTTD
Website: https://www.openttd.org/
Wiki: https://wiki.openttd.org/
Multiplayer docs: https://github.com/OpenTTD/OpenTTD/blob/master/docs/multiplayer.md
Releases: https://github.com/OpenTTD/OpenTTD/releases

**Note**: This recipe covers the **dedicated game server** component. The desktop client (game) is separate and available on Steam, GOG, Microsoft Store, and GitHub releases.

## What it is

OpenTTD dedicated server hosts persistent multiplayer sessions:

- Runs headlessly — no display or GPU required
- Players connect with the desktop client (same version required)
- Configurable map size, starting year, economy, town growth
- Password-protected, invite-only, or public listing
- Admin port for remote management
- Autosave and automatic pause when no players connected

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| apt (Ubuntu/Debian) | Ubuntu/Debian repos | Quick install on Debian-based systems |
| Binary tarball | https://github.com/OpenTTD/OpenTTD/releases | Latest version on any Linux |
| Docker | `openttd/openttd` (official) | Containerized deploy |

## Requirements

- 256 MB RAM (512 MB recommended)
- Default game port: TCP+UDP 3979
- Admin port: TCP 3977 (optional)

## Binary install (recommended for latest version)

Upstream releases: https://github.com/OpenTTD/OpenTTD/releases

    # Download latest Linux generic binary (check releases page for current version)
    VERSION=14.1
    wget "https://cdn.openttd.org/openttd-releases/${VERSION}/openttd-${VERSION}-linux-generic-amd64.tar.xz"
    tar xf openttd-${VERSION}-linux-generic-amd64.tar.xz
    cd openttd-${VERSION}-linux-generic-amd64

    # Run dedicated server
    ./openttd -D

The `-D` flag starts in dedicated (headless) server mode.

## apt install (Debian/Ubuntu)

    sudo add-apt-repository ppa:openttd/ppa   # Ubuntu
    sudo apt update
    sudo apt install -y openttd

    # Run dedicated server
    openttd -D

## Docker (official image)

Docker Hub: https://hub.docker.com/r/openttd/openttd

    docker run -d \
      --name openttd \
      --restart always \
      -p 3979:3979/tcp \
      -p 3979:3979/udp \
      -v /opt/openttd/config:/home/openttd/.openttd \
      -e PUID=1000 \
      -e PGID=1000 \
      openttd/openttd:latest

    # Docker Compose
    services:
      openttd:
        image: openttd/openttd:latest
        restart: always
        ports:
          - "3979:3979/tcp"
          - "3979:3979/udp"
        volumes:
          - ./config:/home/openttd/.openttd
        environment:
          PUID: "1000"
          PGID: "1000"

## Configuration (openttd.cfg)

Config file location: `~/.openttd/openttd.cfg` (or `/home/openttd/.openttd/openttd.cfg` in Docker).

Key settings for a dedicated server:

    [network]
    server_name = My OpenTTD Server
    server_port = 3979
    server_password =
    server_advertise = true          # list on public server browser
    lan_internet = 1                 # 0=LAN only, 1=internet
    max_clients = 25
    pause_on_join = true
    autoclean_companies = true
    autoclean_protected = 60         # kick inactive companies after 60 months

    [difficulty]
    diff_custom = 0

    [gui]
    pause_on_no_clients = true       # pause game when no players connected
    autosave = monthly

Full config reference: https://wiki.openttd.org/en/Archive/Manual/Settings/Openttd.cfg

## Starting a new game via console

When the server is running, press Enter to get the console:

    # Generate a new random map
    new_game

    # Load a saved game
    load <savegame.sav>

    # Server console commands
    players          # list connected players
    kick <id>        # kick a player
    ban <ip>         # ban an IP
    set server_name "New Name"
    set max_clients 20
    save mygame      # save game to file
    exit             # stop server

## Firewall

    ufw allow 3979/tcp
    ufw allow 3979/udp
    # If using admin port:
    # ufw allow 3977/tcp (from trusted IP only)

## systemd service

    cat > /etc/systemd/system/openttd.service << 'SVCEOF'
    [Unit]
    Description=OpenTTD Dedicated Server
    After=network.target

    [Service]
    Type=simple
    User=openttd
    ExecStart=/usr/games/openttd -D -c /etc/openttd/openttd.cfg
    Restart=on-failure
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    useradd -r -s /bin/false openttd
    systemctl daemon-reload
    systemctl enable --now openttd

## Upgrade

    systemctl stop openttd
    # Download new binary, replace old one
    systemctl start openttd

Clients must upgrade to the same version — version mismatches prevent joining.

## Gotchas

- **Client version must match server** — Players on a different game version see a red dot and cannot join. Update server and announce to players simultaneously.
- **NewGRFs** — If you use custom NewGRF content packs, clients need the same NewGRFs installed. Use content from the in-game content downloader (BaNaNaS) to ease distribution.
- **`-D` flag required** — Without `-D`, OpenTTD tries to open a GUI and fails on headless servers.
- **Autosave directory** — Autosaves go to `~/.openttd/save/autosave/`. Mount this directory in Docker to persist saves.
- **Public listing** — `server_advertise = true` registers the server on the public master server list. Players can find it in the multiplayer server browser.
- **Pause on no clients** — `pause_on_no_clients = true` in `[gui]` section prevents the game clock from advancing when nobody is connected, preserving the game state.

## Links

- GitHub: https://github.com/OpenTTD/OpenTTD
- Website: https://www.openttd.org/
- Wiki: https://wiki.openttd.org/
- Multiplayer docs: https://github.com/OpenTTD/OpenTTD/blob/master/docs/multiplayer.md
- openttd.cfg reference: https://wiki.openttd.org/en/Archive/Manual/Settings/Openttd.cfg
- Releases: https://github.com/OpenTTD/OpenTTD/releases
- Docker Hub: https://hub.docker.com/r/openttd/openttd
