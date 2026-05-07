---
name: Zero-K
description: Open-source real-time strategy (RTS) game built on the Spring/Recoil engine. Features physical projectiles, terrain manipulation, smart units, and competitive balance. GPL-2.0.
website: https://zero-k.info/
source: https://github.com/ZeroK-RTS/Zero-K
license: GPL-2.0
stars: 800
tags:
  - game
  - rts
  - spring-engine
platforms:
  - Lua
---

# Zero-K

Zero-K is a free, open-source real-time strategy game running on the Spring/Recoil engine. It emphasizes player creativity through terrain manipulation (terraforming), physics-based projectiles, and a large roster of unique units. It has an active competitive community and is available on Steam.

Official site: https://zero-k.info/  
Source: https://github.com/ZeroK-RTS/Zero-K  
Steam: https://store.steampowered.com/app/334920/ZeroK/  
Wiki: https://zero-k.info/mediawiki/  
Download: https://zero-k.info/Wiki/Download

> **Self-hosting context**: Zero-K is primarily a **game client**. "Self-hosting" applies to running your own game server/lobby (using the Spring/Recoil dedicated server) or contributing to development. The main game infrastructure is run by the Zero-K team.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Windows / Linux / macOS | Zero-K launcher | Primary play method; auto-updates |
| Steam | Steam client | Available via Steam |
| Linux server | Spring dedicated server binary | For hosting private/LAN game servers |
| Linux development machine | Lua + Spring engine | For modding/contributing |

## Inputs to Collect

**Phase: Planning (server hosting)**
- Linux server with Spring dedicated server binary installed
- Desired game mode / map
- Port to expose (Spring default: `8452` UDP)
- Whether to connect to the main Zero-K lobby or run standalone LAN

## Software-Layer Concerns

**Play the game (client):**
```bash
# Linux: Download Zero-K launcher
wget https://zero-k.info/lobby/Zero-K.exe  # or use Steam
# Run Zero-K launcher — it handles all downloads
```

**Run a dedicated game server:**
```bash
# Install Spring engine dedicated server
# https://springrts.com/wiki/Dedicated_Server

# Download Spring engine
wget https://github.com/beyond-all-reason/spring/releases/latest/download/spring_linux_64-bit.tar.gz
tar -xzf spring_linux_64-bit.tar.gz

# Run dedicated server with Zero-K game
./spring-dedicated --game zero-k --map Quicksilver_v3 --port 8452
```

**Game data paths (Linux):**
- Game files: `~/.spring/games/Zero-K.sdd/`
- Maps: `~/.spring/maps/`
- Config: `~/.springrc`

**Lobby server (Uberserver):** Zero-K uses the Uberserver lobby — source at https://github.com/ZeroK-RTS/Uberserver if you want to run a private lobby.

**Development/modding:**
```bash
git clone https://github.com/ZeroK-RTS/Zero-K
# Edit Lua game files
# Test via Spring engine with --game path
```

## Upgrade Procedure

1. **Client**: Zero-K launcher auto-updates on launch
2. **Steam**: Steam handles updates automatically
3. **Dedicated server**: Update Spring engine binary and re-download latest Zero-K game archive from https://zero-k.info

## Gotchas

- **Game repo ≠ full game**: The GitHub repo contains only game module files (Lua scripts) — artwork, engine, and infrastructure are in separate repositories
- **Spring/Recoil engine required**: Zero-K does not bundle the engine — the launcher or Steam installs it automatically
- **Active development**: ~50-150 commits/month; balance patches and new units added regularly
- **Multiplayer lobby**: The main lobby server is run by the Zero-K team; running a fully private server requires also running the Uberserver lobby
- **LAN play**: LAN games work without the lobby server via direct IP connection
- **Not a web app**: Zero-K is a native desktop game — "self-hosting" means running a dedicated game server, not a web service

## Links

- Upstream README: https://github.com/ZeroK-RTS/Zero-K/blob/master/README.md
- Download: https://zero-k.info/Wiki/Download
- Development guide: https://zero-k.info/mediawiki/Zero-K:Developing
- Spring dedicated server: https://springrts.com/wiki/Dedicated_Server
- Uberserver (lobby): https://github.com/ZeroK-RTS/Uberserver
- Steam page: https://store.steampowered.com/app/334920/ZeroK/
