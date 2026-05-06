---
name: veloren
description: Veloren recipe for open-forge. Covers self-hosted multiplayer server (veloren-server-cli) via Docker and binary. Veloren is an open-source multiplayer voxel RPG inspired by Cube World, Dwarf Fortress, and Minecraft, written in Rust.
---

# Veloren

Open-source multiplayer voxel RPG written in Rust, inspired by Cube World, Dwarf Fortress, and Minecraft. Features procedurally generated open world, diverse biomes, dungeons, crafting, trading, and fluid combat. Self-hosting the dedicated server (`veloren-server-cli`) enables private communities or LAN play. Upstream: <https://gitlab.com/veloren/veloren>. Website: <https://veloren.net>.

**License:** GPL-3.0 · **Language:** Rust · **Default port:** 14004/UDP+TCP · **Stars:** ~2,400

> **Self-hosting note:** This recipe covers self-hosting the Veloren **dedicated server**. The game client is installed separately by players via the Veloren Airshipper launcher.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (veloren-server-cli) | <https://gitlab.com/veloren/veloren/container_registry> | ✅ | **Recommended** — containerized, easy version pinning. |
| Binary release | <https://veloren.net/download/> | ✅ | Bare-metal without Docker. |
| Build from source | <https://book.veloren.net/contributors/compiling.html> | ✅ | Latest dev builds or custom patches. |

## Game client installation (players)

Players install the game client separately:

- **Airshipper launcher (recommended):** <https://veloren.net/download/> — auto-updates, manages versions
- **Direct download:** <https://veloren.net/download/> (Windows, macOS, Linux)
- **AUR (Arch Linux):** `yay -S veloren-bin`
- **Flatpak:** <https://flathub.org/apps/net.veloren.veloren>

## Install — Docker (recommended)

```bash
mkdir veloren-server && cd veloren-server

cat > docker-compose.yml << 'COMPOSE'
services:
  veloren:
    image: registry.gitlab.com/veloren/veloren-server-docker:latest
    restart: unless-stopped
    ports:
      - "14004:14004/tcp"
      - "14004:14004/udp"
    volumes:
      - veloren-data:/opt/server-data
      - veloren-assets:/opt/veloren/assets

volumes:
  veloren-data:
  veloren-assets:
COMPOSE

docker compose up -d
```

Check logs:

```bash
docker compose logs -f
```

### Pinning to a specific version

Veloren uses date-stamped tags. To pin to a specific version:

```yaml
image: registry.gitlab.com/veloren/veloren-server-docker:2024-01-15
```

Check available tags at: <https://gitlab.com/veloren/veloren/container_registry>

> **Important:** Server and client versions **must match exactly**. Players cannot connect with a different version than the server. Pin both to the same release tag.

## Install — Binary

```bash
# Download the server binary from the Veloren website
# Go to https://veloren.net/download/ and get the server-cli archive for your platform

# Example (Linux x86_64):
wget https://veloren.net/releases/nightly/veloren-server-cli-linux-x86_64.tar.gz
tar xzf veloren-server-cli-linux-x86_64.tar.gz
cd veloren-server-cli-linux-x86_64

./veloren-server-cli
```

## Server configuration

Configuration file: `userdata/server-settings.ron` (auto-generated on first run).

Key settings:

```ron
(
    gameserver_address: "0.0.0.0:14004",
    metrics_address: "0.0.0.0:14005",
    auth_server_address: Some("https://auth.veloren.net"),
    max_players: 100,
    // Server name shown in server list
    // server_name: "My Veloren Server",
    // MOTD shown on connect
    // motd: "Welcome to my server!",
    // Whitelist mode — only allow approved players
    // whitelist: [],
)
```

## Firewall rules

Open port 14004 (both TCP and UDP):

```bash
sudo ufw allow 14004/tcp
sudo ufw allow 14004/udp
```

## Connecting players

Players with matching client versions can connect via:
- In-game server list (if your server registers with Veloren's master server)
- **Custom server:** Enter your IP/hostname and port 14004 in the custom server field

## Software-layer concerns

| Concern | Detail |
|---|---|
| Version matching | Server and client **must** be the same version. Veloren releases nightly builds — consider pinning to stable weekly snapshots. |
| Auth | By default, uses Veloren's global authentication server. Players need a Veloren account (<https://account.veloren.net>). Set `auth_server_address: None` for offline/LAN-only play with local accounts. |
| Data persistence | World data, player saves, and settings in `/opt/server-data` volume. Back up this volume. |
| World generation | Server generates world procedurally on first start — this takes several minutes and uses significant CPU. |
| Metrics | Optional Prometheus metrics exposed on port 14005. |
| RAM | Veloren server uses 1–4 GB RAM depending on world chunks loaded and player count. |
| nightly vs stable | Nightly builds are frequent but may have bugs. The `weekly` tag is more stable. |

## Upgrade procedure

```bash
# Update compose to new version tag, then:
docker compose pull
docker compose up -d
```

> ⚠️ Coordinate upgrades with all players — they must update their client to match. Announce in advance.

## Gotchas

- **Version mismatch = cannot connect:** This is the #1 server admin pain point. Client and server must be the exact same build. If you pin the server to `2024-01-15`, players must also use that exact client version via Airshipper.
- **First-start world gen is slow:** On initial launch, the server generates the world — CPU spikes to 100% for 5–15 minutes. Don't restart thinking it's hung.
- **Offline mode:** To allow play without Veloren accounts, set `auth_server_address: None` in `server-settings.ron`. Players use any username with no password.
- **Nightly build stability:** Veloren's nightly builds are auto-generated from the main branch. They can be unstable. For long-running servers, prefer weekly release tags.
- **GitLab container registry:** The Docker image is on GitLab's registry (`registry.gitlab.com`), not Docker Hub. Pull may be slower depending on your region.

## Upstream links

- GitLab: <https://gitlab.com/veloren/veloren>
- Website: <https://veloren.net>
- Download (client + server): <https://veloren.net/download/>
- Veloren Book (admin guide): <https://book.veloren.net>
- Server setup guide: <https://book.veloren.net/players/hosting-a-server.html>
- Container registry: <https://gitlab.com/veloren/veloren/container_registry>
- Account registration: <https://account.veloren.net>
