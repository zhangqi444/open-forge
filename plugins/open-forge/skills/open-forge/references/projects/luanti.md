---
name: Luanti
description: "Free open-source voxel game engine with easy modding and multiplayer game server support — build and run voxel-world games with a Lua modding API, content library, and cross-platform clients. Formerly known as Minetest. C++. LGPL-2.1+."
---

# Luanti

Luanti (formerly **Minetest**) is a **free, open-source voxel game engine** — think Minecraft, but the engine itself is open source, the game rules are swappable, and modding is a first-class citizen via a clean Lua API. The engine ships with a default "Minetest Game" sandbox, but the real power is that it's an **engine**: dozens of independent games have been built on top of it (survival, creative, RPG, puzzles, minigames) and thousands of community mods extend any game.

Key distinction: Luanti is not just a game, it is an **engine that runs games**. When you self-host a Luanti server, you pick which game to run (and which mods to load), then players with the Luanti client on any platform can connect and play.

Use cases: (a) self-hosted multiplayer voxel game server for friends/family/communities (b) educational environments — teaching programming via Lua mods (c) creative sandbox / collaborative building (d) hosting a game server for a specific community game (Mineclonia, Nodecore, etc.) (e) building your own voxel game using the engine (f) lightweight alternative to Minecraft Java Edition servers (no JVM required).

Features:

- **Voxel game engine** — infinite procedurally generated worlds; block-based building and interaction
- **Multiplayer server mode** — built-in server; no separate server binary required
- **Lua modding API** — powerful, well-documented API; create items, nodes, entities, NPCs, biomes, world generation, HUD elements, and more
- **Content library** — ContentDB (<https://content.luanti.org>) hosts 1,000+ games, mods, and texture packs; installable from within the client
- **Cross-platform** — Linux, macOS, Windows, Android clients
- **Low hardware requirements** — runs on Raspberry Pi, older hardware; no GPU required for server mode
- **Formerly Minetest** — renamed to Luanti in 2024; full backward compatibility with Minetest mods + games

- Upstream repo: <https://github.com/luanti-org/luanti>
- Homepage: <https://www.luanti.org>
- Docs: <https://docs.luanti.org>
- ContentDB (mods/games): <https://content.luanti.org>

## Architecture in one minute

- **C++ engine** — handles rendering (client), physics, networking, world storage
- **Lua scripting layer** — game logic lives entirely in Lua; engine exposes a rich API
- **SQLite** — default world storage (per-world `.sqlite` files); PostgreSQL backend available for large servers
- **MapBlock system** — world stored in 16x16x16 "mapblocks"; loaded on demand; supports effectively infinite worlds
- **Server/client split** — server is headless (no rendering); clients connect over TCP (default port 30000)
- **Resource**: very lean — 100–500 MB RAM for a modest server; CPU scales with player count + world generation activity

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Package manager    | `apt install luanti` / `flatpak install luanti`                | Convenient; may not be latest version                                          |
| Docker             | Community images (e.g., `ghcr.io/luanti-org/luanti-server`)   | Good for server-only headless deployment                                       |
| Binary release     | Download from GitHub releases                                  | Latest version; good for servers                                               |
| Build from source  | CMake + C++17 toolchain                                        | For development or custom patches                                              |
| Hosted services    | Various community game hosts                                   | Managed hosting; easy for non-technical server admins                          |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Game selection       | `mineclonia`, `minetest_game`, `nodecore`                   | Config       | Which game to run on the server                                          |
| World name           | `my_world`                                                  | Config       | Directory name under `worlds/`                                           |
| Server port          | `30000` (default UDP)                                       | Networking   | Open in firewall                                                         |
| Admin username       | `admin`                                                     | Auth         | Set `name = admin` in `minetest.conf`; that player gets server_priv      |
| Password policy      | per-player passwords or open server                         | Auth         | Public servers should require passwords                                  |
| Mods list            | from ContentDB or manual                                    | Content      | Installed per-world or globally                                          |
| Max players          | `20`                                                        | Config       | `max_users` in config                                                    |

## Install (Docker server path)

```yaml
# docker-compose.yml — Luanti headless server
version: "3.8"
services:
  luanti:
    image: ghcr.io/luanti-org/luanti-server:latest
    ports:
      - "30000:30000/udp"
    volumes:
      - ./data:/data/.minetest    # worlds, config, mods
    environment:
      - CLI_ARGS=--world /data/.minetest/worlds/my_world --config /data/.minetest/minetest.conf
    restart: unless-stopped
```

Note: Check the specific Docker image's documentation for volume paths and environment variable conventions, as community images vary.

## Install (binary / systemd path)

```sh
# Ubuntu/Debian — from PPA for latest release
sudo add-apt-repository ppa:minetestdevs/stable
sudo apt update
sudo apt install minetest   # binary still named 'minetest' in many distros

# Or download binary tarball from GitHub releases
wget https://github.com/luanti-org/luanti/releases/latest/download/luanti-*.tar.gz

# Run headless server
luanti --server \
  --world ~/.minetest/worlds/my_world \
  --config ~/.minetest/minetest.conf \
  --port 30000 \
  --logfile /var/log/luanti/server.log
```

```ini
# /etc/systemd/system/luanti.service
[Unit]
Description=Luanti Game Server
After=network.target

[Service]
Type=simple
User=luanti
ExecStart=/usr/bin/luanti --server \
  --world /opt/luanti/worlds/main \
  --config /opt/luanti/minetest.conf
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Key configuration (minetest.conf)

```ini
# minetest.conf — server configuration

# Server identity
server_name = My Luanti Server
server_description = A voxel adventure
server_url = https://my-server.example.com
motd = Welcome! Be excellent to each other.

# Network
port = 30000
bind_address = 0.0.0.0
max_users = 20

# Admin (gets all privileges)
name = youradminname

# Security
default_privs = interact, shout
enable_rollback_recording = true    # for /rollback griefing recovery

# World generation
mg_name = v7                        # mapgen algorithm: v5, v6, v7, valleys, fractal, etc.
seed = 12345                        # specific seed for reproducible worlds

# Performance
active_block_range = 2              # lower = less CPU/RAM on busy servers
max_block_generate_distance = 5
server_map_save_interval = 60       # save world to disk every N seconds

# PostgreSQL backend (optional — for large servers)
# pgsql_connection_info = host=db user=luanti password=secret dbname=luanti_world
```

## Game and mod installation

Games and mods go in specific directories:

```
~/.minetest/
  games/          # game packages (each is a directory)
    mineclonia/
    minetest_game/
  mods/           # global mods (available to all worlds)
    technic/
    mesecons/
  worlds/         # world data
    my_world/
      world.mt    # world metadata (which game, which mods enabled)
      map.sqlite  # the world database
      worldmods/  # world-specific mods
```

Installing a game from ContentDB:
```sh
# Via client UI: Games tab → Browse online content → Install
# Or manually:
cd ~/.minetest/games/
git clone https://github.com/mineclonia/mineclonia.git mineclonia
```

Enabling mods per-world in `world.mt`:
```
gameid = mineclonia
load_mod_technic = true
load_mod_mesecons = true
```

## Lua modding quick reference

```lua
-- Register a new craftitem
minetest.register_craftitem("mymod:magic_dust", {
    description = "Magic Dust",
    inventory_image = "mymod_magic_dust.png",
    on_use = function(itemstack, user, pointed_thing)
        minetest.chat_send_player(user:get_player_name(), "You used magic dust!")
        return itemstack
    end,
})

-- Register a new node (block)
minetest.register_node("mymod:glowstone", {
    description = "Glowstone",
    tiles = {"mymod_glowstone.png"},
    light_source = minetest.LIGHT_MAX,
    groups = {cracky = 3},
})

-- Register a craft recipe
minetest.register_craft({
    output = "mymod:glowstone 1",
    recipe = {
        {"default:glass", "default:torch", "default:glass"},
        {"default:torch", "default:diamond", "default:torch"},
        {"default:glass", "default:torch", "default:glass"},
    },
})
```

## First boot

1. Start the server: `luanti --server --world worlds/main --config minetest.conf`
2. Connect with Luanti client: "Add Server" → enter IP:30000
3. Log in as admin (your configured `name =` username)
4. Grant yourself all privileges: `/grant yourusername all`
5. Test world generation is working: explore, build
6. Install and enable desired mods/games
7. Set appropriate `default_privs` for regular players
8. Configure firewall: open UDP 30000

## Backup

```sh
# World backup — worlds are self-contained directories
tar czf luanti-world-$(date +%F).tgz ~/.minetest/worlds/my_world/

# Full backup including games + mods + config
tar czf luanti-full-$(date +%F).tgz ~/.minetest/

# For PostgreSQL backend
pg_dump luanti_world | gzip > luanti-pg-$(date +%F).sql.gz
```

The SQLite `map.sqlite` file is the most critical artifact — it is the entire world. Back it up regularly. For busy servers, stop the server before copying SQLite files to avoid partial writes.

## Upgrade

1. Check releases: <https://github.com/luanti-org/luanti/releases>
2. Back up worlds directory FIRST
3. Review release notes — mod API changes noted; mods may need updates for engine API changes
4. Replace binary or update package
5. Update games + mods from ContentDB if needed for compatibility
6. Start server; watch logs for deprecation warnings

## Gotchas

- **Port is UDP, not TCP.** Luanti uses UDP port 30000. Many guides/firewalls assume TCP — open UDP specifically. `ufw allow 30000/udp` not `30000/tcp`.
- **World save timing.** Default `server_map_save_interval = 60` seconds. If server crashes, up to 60 seconds of changes can be lost. Lower this on important worlds. Also: SQLite is not safe to copy while server is running without stopping first.
- **Griefing on public servers.** `enable_rollback_recording = true` enables `/rollback` to undo node changes by a player. Essential for public servers. Performance cost: enable only if needed.
- **Mod API version compatibility.** Mods written for older Minetest versions may use deprecated API calls. The engine logs deprecation warnings — review them. Most mods are updated quickly for new engine versions, but check ContentDB for updated packages.
- **The rename (Minetest → Luanti).** Renamed in October 2024. Many existing mods, docs, Docker images, tutorials, config files still say "minetest" — this is the same software. Paths like `~/.minetest/` are still in use; the binary may be named `minetest` on some distros.
- **"Minetest Game" vs other games.** The default "Minetest Game" is a minimalist sandbox — not a survival experience like Minecraft. For survival gameplay, use **Mineclonia** (Minecraft-inspired) or **Voxelgarden** instead. New users often expect Minecraft-like gameplay and are confused by the default.
- **ContentDB security.** ContentDB mods are community-submitted; quality varies. Review mod code before running on production servers — Lua mods run with full server access.
- **Large worlds + SQLite.** SQLite performance degrades on very large worlds (10+ million mapblocks) or high player counts (30+). Switch to PostgreSQL backend for serious servers. Enable WAL mode: `pragma journal_mode = WAL` is applied automatically by recent versions.
- **Server-side vs client-side mods.** Some mods require installation on both server AND client (those that add custom textures/models clients need to render). Clients auto-download media from servers; ensure `server_announce` and media serving are configured correctly.
- **Memory and CPU.** Server RAM scales with active areas. 500 MB is fine for a handful of players; 2+ GB for busy public servers with many active chunks. CPU spikes during world generation (new players exploring).
- **Alternatives worth knowing:**
  - **Minecraft Java Edition** — the original; more polished vanilla gameplay; JVM required; paid
  - **Minecraft Bedrock** — cross-platform; different modding ecosystem; paid
  - **Veloren** — open-source voxel RPG; very different feel; no modding API yet
  - **Hytale** — upcoming voxel game from Hypixel; commercial; not yet released
  - **Choose Luanti if:** you want free, zero-cost voxel gaming; you want a moddable platform; you want light hardware requirements; you want total control over the server.
  - **Choose Minecraft if:** you want the polished vanilla experience + the vast Java modpack ecosystem (Forge/Fabric mods).

## Links

- Repo: <https://github.com/luanti-org/luanti>
- Homepage: <https://www.luanti.org>
- Docs: <https://docs.luanti.org>
- ContentDB (mods/games): <https://content.luanti.org>
- Forums: <https://forum.luanti.org>
- Wiki: <https://wiki.luanti.org>
- Releases: <https://github.com/luanti-org/luanti/releases>
- Mineclonia (popular game): <https://github.com/mineclonia/mineclonia>
