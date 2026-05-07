---
name: minus-games
description: Minus Games recipe for open-forge. Game distribution and save-sync suite for home servers — Rust-based server + client/GUI apps. Source: https://github.com/Accessory/minus_games
---

# Minus Games

A self-hosted game distribution and save-file sync suite. The server hosts game files; clients (CLI or GUI) download and run games and sync save files across devices. Written in Rust. Upstream: <https://github.com/Accessory/minus_games>. Docs: <https://accessory.github.io/minus_games_user_guide/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare metal | Docker Compose | Easiest; official image available |
| Any Linux VPS / bare metal | Rust binary (native) | Build from source or download release binary |
| Home server (Linux/macOS/Windows) | Native binary | Primary use case — LAN game server |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Where will game files be stored on the server?" | Directory path | e.g. /data/games; must be readable/writable by the server process |
| "What port should the server listen on?" | Number | Default 8080 |
| "Do you want the server accessible only on LAN or also via internet?" | LAN / Internet | Internet requires reverse proxy + auth |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Reverse proxy in front? (NGINX / Caddy / none)" | Choice | Needed for HTTPS if internet-facing |
| "Set an API token/password for the server?" | String (sensitive) | Protects game downloads from unauthenticated clients |

## Software-Layer Concerns

- **Five components**: minus_games_server, minus_games_client (CLI), minus_games_gui (desktop GUI), minus_games_finder (scans installed games), minus_games_updater (auto-updates). Only the server runs on the host; clients run on player machines.
- **Game files**: Server serves files from the configured games directory. Directory structure must match what Minus Games Finder detects.
- **Save sync**: Clients push/pull save files from the server. Save directory path is configured per-game.
- **Config**: Server configured via environment variables or CLI flags.
- **No built-in auth UI**: Access control is token-based.
- **Data persistence**: Games directory must be mounted as a persistent volume.

## Deployment

### Docker Compose

```yaml
services:
  minus-games-server:
    image: accessory/minus_games_server:latest
    ports:
      - "8080:8080"
    volumes:
      - /data/games:/games
    environment:
      GAMES_DIR: /games
      # SERVER_TOKEN: your-secret-token
    restart: unless-stopped
```

Point clients at http://<server-ip>:8080. Configure each client with the server URL and token.

### Native Binary

Download latest release from https://github.com/Accessory/minus_games/releases, chmod +x, and run with GAMES_DIR env var set.

## Upgrade Procedure

1. Pull new Docker image: docker compose pull && docker compose up -d
2. Or download new release binary, stop service, replace binary, restart.
3. Clients update themselves via minus_games_updater if configured.

## Gotchas

- **Client/server version mismatch**: Keep server and clients on the same release tag.
- **Game directory structure**: Must be organized as Minus Games Finder expects — check upstream docs before pointing at an existing folder.
- **Save sync conflicts**: Last-write wins; no conflict resolution.
- **Cross-platform saves**: Some games store saves in OS-specific paths; configure carefully for cross-platform sync.

## Links

- Source: https://github.com/Accessory/minus_games
- Docs: https://accessory.github.io/minus_games_user_guide/
- Releases: https://github.com/Accessory/minus_games/releases
