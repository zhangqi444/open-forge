---
name: mindustry
description: Mindustry recipe for open-forge. Factorio-like automation tower-defense game server. Covers running a dedicated server via Java JAR, Docker, or compiled from source. Upstream: https://github.com/Anuken/Mindustry
---

# Mindustry

Automation tower defense RTS game written in Java. Build production chains to gather resources and defend against waves of enemies. Self-hosted dedicated servers allow persistent multiplayer worlds.

27,432 stars · GPL-3.0

Upstream: https://github.com/Anuken/Mindustry
Wiki: https://mindustrygame.github.io/wiki
Releases: https://github.com/Anuken/Mindustry/releases
Pre-built bleeding-edge builds: https://github.com/Anuken/MindustryBuilds/releases

**Note**: This recipe covers the **dedicated game server** component. The desktop client (game itself) is separate and available on Steam, itch.io, F-Droid, and GitHub releases.

## What it is

Mindustry dedicated server allows hosting:

- Persistent multiplayer maps
- Custom game modes (attack, pvp, survival)
- Community-hosted servers listed in the in-game server browser
- Private LAN/VPN servers for friends

The server is a headless JVM application — no desktop/GPU required.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Java JAR (pre-built release) | https://github.com/Anuken/Mindustry/releases | Recommended — simplest, no Docker needed |
| Docker image | Community-maintained (not official) | Containerized deploys |
| Build from source | https://github.com/Anuken/Mindustry#building | Development or bleeding-edge |

## Requirements

- Java 17 (JDK/JRE). **Other JDK versions will not work.** Use Eclipse Temurin 17: https://adoptium.net/
- 512 MB RAM minimum; 1 GB recommended
- Default game port: UDP 6567

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| version | "Which Mindustry version? (latest release, or bleeding-edge build)" | All |
| port | "Server port? (default: 6567)" | All |
| map | "Start with a specific map, or let the server pick default?" | Optional |
| mode | "Game mode: survival, attack, pvp, or sandbox?" | Optional |

## Java JAR install (recommended)

Upstream releases: https://github.com/Anuken/Mindustry/releases

### 1. Install Java 17

    # Debian/Ubuntu
    apt install -y wget apt-transport-https
    wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
    echo "deb https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" >> /etc/apt/sources.list.d/adoptium.list
    apt update && apt install -y temurin-17-jdk

    # Verify
    java -version

### 2. Download the server JAR

    mkdir -p /opt/mindustry && cd /opt/mindustry

    # Download latest server release (check GitHub releases for current version)
    wget https://github.com/Anuken/Mindustry/releases/latest/download/server-release.jar

### 3. Run the server

    java -jar server-release.jar

The server starts interactively. Type `help` in the console for available commands.

### Key in-console commands

| Command | Description |
|---|---|
| `host [map] [mode]` | Start hosting a game |
| `say <message>` | Broadcast a message to all players |
| `status` | Show current game status |
| `stop` | Stop the current game |
| `exit` | Shut down the server |
| `maps` | List available maps |
| `add-map <url>` | Download and add a map from URL |
| `config <key> <value>` | Set server config (name, description, etc.) |
| `whitelist-add <id>` | Add player to whitelist |
| `ban <id/name>` | Ban a player |

### Server configuration

Server settings are stored in the `config/` directory created on first run.

Set server name and other options via the config command or by editing `config/settings.bin`:

    # In the server console:
    config name "My Mindustry Server"
    config description "A community server"
    config port 6567
    config maxPlayers 16

### Running as a systemd service

    cat > /etc/systemd/system/mindustry.service << 'EOF'
    [Unit]
    Description=Mindustry Game Server
    After=network.target

    [Service]
    Type=simple
    User=mindustry
    WorkingDirectory=/opt/mindustry
    ExecStart=/usr/bin/java -jar /opt/mindustry/server-release.jar
    Restart=on-failure
    RestartSec=10
    StandardInput=null

    [Install]
    WantedBy=multi-user.target
    EOF

    useradd -r -s /bin/false mindustry
    chown -R mindustry:mindustry /opt/mindustry
    systemctl daemon-reload
    systemctl enable --now mindustry

**Note**: Standard input is set to `null` for non-interactive systemd operation. Server commands must be issued via other means (RCON or restart).

## Firewall

Open UDP port 6567 (default):

    # UFW
    ufw allow 6567/udp

    # iptables
    iptables -A INPUT -p udp --dport 6567 -j ACCEPT

## Bleeding-edge builds

If you want the latest unreleased features: https://github.com/Anuken/MindustryBuilds/releases

These are auto-generated from every commit. Use the same JAR invocation.

## Upgrade

    cd /opt/mindustry
    systemctl stop mindustry
    wget -O server-release.jar https://github.com/Anuken/Mindustry/releases/latest/download/server-release.jar
    systemctl start mindustry

## Gotchas

- **Java 17 only** — JDK 8, 11, 21 etc. will not work. Must be exactly JDK 17. Use Eclipse Temurin 17.
- **UDP not TCP** — The game uses UDP 6567. Ensure your firewall opens UDP, not just TCP.
- **Interactive console** — The server expects interactive input by default. For systemd, use `StandardInput=null` or wrap in a tmux/screen session.
- **Map management** — Maps go in `config/maps/`. Use `add-map <url>` in the console or drop `.msav` files directly.
- **Game data format** — Map saves use `.msav` binary format. Back up the `config/` directory to preserve your world.
- **Server browser listing** — The server registers itself on the public Mindustry server list automatically unless `publicHost false` is set. Set to `false` for private servers.
- **Version matching** — Clients must be on the same version as the server. Update both simultaneously.

## Links

- GitHub: https://github.com/Anuken/Mindustry
- Releases: https://github.com/Anuken/Mindustry/releases
- Bleeding-edge builds: https://github.com/Anuken/MindustryBuilds/releases
- Wiki: https://mindustrygame.github.io/wiki
- Discord: https://discord.gg/mindustry
