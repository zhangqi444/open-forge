---
name: Lodestone
description: "Self-hosted game server management tool. Docker or binary. Rust + React/TypeScript. Lodestone-Team/lodestone. Minecraft + other games, web UI, file manager, user permissions, macro extensions, playit.gg tunneling. AGPL."
---

# Lodestone

**Free, open-source game server hosting and management tool.** One-click install and setup for Minecraft (and other multiplayer games) via a clean React web UI. Real-time server status, file manager (upload/download/unzip/copy), user permission management, macro extensions for automation, and optional playit.gg integration for NAT traversal without port forwarding. Rust backend, TypeScript frontend.

Built + maintained by **Lodestone-Team** (university students). AGPL-3.0 license.

- Upstream repo: <https://github.com/Lodestone-Team/lodestone>
- Website + docs: <https://www.lodestone.cc>
- Wiki: <https://github.com/Lodestone-Team/lodestone/wiki>
- Discord: <https://discord.gg/PkHXRQXkf6>
- Hosted dashboard: <https://www.lodestone.cc>

## Architecture in one minute

- **Rust** backend (Lodestone Core) — written in safe Rust (`#![forbid(unsafe_code)]`)
- **React + TypeScript** web dashboard (hosted at lodestone.cc or self-hosted)
- **Lodestone CLI** — manages installation and updates of Core
- **Lodestone Desktop** — Windows-only app that bundles Core + dashboard
- Dashboard ↔ Core communicate over HTTP/WebSocket
- Lodestone Core manages game server processes on the host
- Resource: **low** (Rust) + game server RAM (varies by game)

## Compatible install methods

| Infra          | Runtime                        | Notes                                                              |
| -------------- | ------------------------------ | ------------------------------------------------------------------ |
| **Docker**     | see wiki Docker support        | <https://github.com/Lodestone-Team/lodestone/wiki/Docker-Support>  |
| **Lodestone CLI** | Linux x64, macOS (Apple Silicon) | Recommended for Linux/Mac; manages Core updates                 |
| **Desktop app** | Windows binary                | Bundles Core + dashboard; Windows only; not stable yet             |

## Install via CLI (Linux/macOS)

Download and run [Lodestone CLI](https://github.com/Lodestone-Team/lodestone_cli):

```bash
# Download Lodestone CLI for your platform (see releases)
chmod +x lodestone
./lodestone
```

CLI handles: downloading Lodestone Core, keeping it updated, and starting the backend service.

## Install via Docker

See: <https://github.com/Lodestone-Team/lodestone/wiki/Docker-Support>

## Dashboard access

Three options:
1. **Hosted dashboard** at <https://www.lodestone.cc> — connects to your local Core instance
2. **Self-hosted dashboard** — host the React app yourself
3. **Desktop app** (Windows) — integrated dashboard

> **Note:** If using the hosted dashboard over HTTP, browsers may block mixed content (HTTPS site → HTTP Core). Follow the [mixed content guide](https://github.com/Lodestone-Team/lodestone/wiki/FAQ#why-do-i-need-to-enable-mixedinsecure-content-and-disable-https-is-this-safe) or put Core behind TLS.

## First boot

1. Install and start Lodestone Core via CLI or Docker.
2. Open the dashboard (lodestone.cc or self-hosted).
3. Connect to your Core instance (enter your server IP + port).
4. Create the admin account.
5. Add a game server instance:
   - Select game (Minecraft, etc.)
   - Choose version and settings
   - Click install → Lodestone downloads and configures the server
6. Start the server — view console output in real time.
7. Configure user permissions for collaborators.
8. (Optional) Enable playit.gg integration for NAT tunneling.

## Features overview

| Feature | Details |
|---------|---------|
| Game servers | One-click install for Minecraft (+ other games) |
| Real-time console | Live server output + command input |
| File manager | Upload, download, unzip, copy, paste in web UI |
| User management | Role-based permissions; collaborative hosting |
| Macros | Extension system for automation (scripts that run on events) |
| playit.gg | NAT traversal tunnel — expose servers without port forwarding |
| Resource monitoring | CPU + RAM usage per server instance |
| Multi-instance | Run multiple game servers from one Lodestone Core |

## playit.gg integration

playit.gg provides free TCP/UDP tunnels that make game servers publicly accessible without port forwarding or a static IP. Ideal for home hosters behind CG-NAT or strict firewalls. Lodestone integrates this directly in the UI.

Full details: <https://github.com/Lodestone-Team/lodestone/wiki/Playit.gg-Integration>

## Macros

Lodestone's macro system lets you run scripts on server events (startup, player join, scheduled time, etc.). Automate backups, notifications, commands, and more.

Full docs: <https://github.com/Lodestone-Team/lodestone/wiki/Intro-to-Macro-and-Task>

## Gotchas

- **Mixed content if using hosted dashboard.** The lodestone.cc dashboard is served over HTTPS; your local Lodestone Core runs over HTTP. Browsers block mixed content by default. Either: put Core behind TLS, disable mixed content for lodestone.cc, or self-host the dashboard. See the FAQ.
- **Lodestone CLI vs Desktop.** For Linux/macOS, use the CLI — it manages Core updates automatically. Desktop is Windows-only and not yet stable.
- **Docker install is in the wiki.** The main README links to the wiki for Docker install. Steps may differ from standard Docker Compose patterns — follow the wiki carefully.
- **Game server RAM is on you.** Lodestone Core itself is lightweight (Rust), but the Minecraft/other game servers it manages need RAM. A vanilla Minecraft server needs 1–2 GB; modded packs need 4–8 GB+. Plan your host accordingly.
- **No formal security audit.** The README explicitly states no formal security audit has been performed. Core is written in safe Rust, but dependencies may use unsafe code. Use on a trusted network; don't expose Core directly to the internet without TLS.
- **AGPL license.** Modifications to Lodestone that are deployed as a network service must be open-sourced. Contact the team for commercial licensing.
- **University student team.** Development pace may be irregular during exam periods. Check the Discord for current status.

## Backup

Game server data lives in Lodestone's data directory (configured during setup). Back up:
- Server world files (e.g. `world/` for Minecraft)
- Lodestone config
- Macro scripts

## Upgrade

Use Lodestone CLI — it handles Core updates:
```bash
./lodestone update
```

## Project health

Active Rust + TypeScript development, Docker support, CLI, playit.gg integration, macro system, file manager, Discord community. University student team. AGPL-3.0.

## Game-server-management-family comparison

- **Lodestone** — Rust+React, Minecraft + games, file manager, macros, playit.gg, AGPL, active
- **Crafty Controller** — Python, Minecraft-focused, Docker, comprehensive panel
- **Pterodactyl** — PHP+Go, multi-game panel, Docker-based isolation, production-grade
- **PufferPanel** — Go, multi-game, lightweight; similar to Pterodactyl but simpler
- **MCSManager** — Node.js, Minecraft + games, cross-platform

**Choose Lodestone if:** you want a clean, Rust-powered game server management panel with playit.gg NAT tunneling, a file manager, and a macro system — especially for Minecraft on a home server.

## Links

- Repo: <https://github.com/Lodestone-Team/lodestone>
- Website: <https://www.lodestone.cc>
- Wiki: <https://github.com/Lodestone-Team/lodestone/wiki>
- Docker support: <https://github.com/Lodestone-Team/lodestone/wiki/Docker-Support>
- Discord: <https://discord.gg/PkHXRQXkf6>
