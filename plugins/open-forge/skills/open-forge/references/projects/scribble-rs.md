---
name: Scribble.rs
description: Free, privacy-respecting web-based pictionary/drawing game. No account required, no ads. Alternative to skribbl.io. MIT licensed.
website: https://github.com/scribble-rs/scribble.rs
source: https://github.com/scribble-rs/scribble.rs
license: MIT
stars: 633
tags:
  - game
  - drawing
  - multiplayer
  - party-game
platforms:
  - Go
  - Docker
---

# Scribble.rs

Scribble.rs is a free, open-source, privacy-respecting pictionary game playable in the browser. No account needed, no ads. Players take turns drawing and guessing words. It's a self-hostable alternative to skribbl.io with support for custom word lists.

Source: https://github.com/scribble-rs/scribble.rs  
Official instance: https://scribblers.bios-marcel.link  
Discord: https://discord.gg/cE5BKP2UnE

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended; single-container |
| Any Linux VM / VPS | Go binary | Build from source |

## Inputs to Collect

**Phase: Planning**
- Port to expose (default: `8080`)
- Root path if hosting at a subpath (e.g., `/scribble`)
- CORS allowed origins (default: `*`)
- Lobby cleanup interval (default: `90s`)

## Software-Layer Concerns

**Docker (recommended):**
```bash
docker run -d \
  --name scribble-rs \
  -p 8080:8080 \
  -e PORT=8080 \
  --restart unless-stopped \
  biosmarcel/scribble.rs:latest
```

**Docker with custom config:**
```bash
docker run -d \
  --name scribble-rs \
  -p 8080:8080 \
  -e PORT=8080 \
  -e ROOT_PATH=/scribble \
  -e CORS_ALLOWED_ORIGINS=https://example.com \
  -e LOBBY_CLEANUP_INTERVAL=120s \
  --restart unless-stopped \
  biosmarcel/scribble.rs:latest
```

**Build from source:**
```bash
git clone https://github.com/scribble-rs/scribble.rs
cd scribble.rs
go build -o scribble-rs ./cmd/scribble-rs
PORT=8080 ./scribble-rs
```

**Environment variables:**
| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP port | `8080` |
| `NETWORK_ADDRESS` | TCP bind address | (all interfaces) |
| `ROOT_PATH` | URL subpath | (root) |
| `CORS_ALLOWED_ORIGINS` | CORS origins | `*` |
| `LOBBY_CLEANUP_INTERVAL` | Idle lobby cleanup | `90s` |

**No persistent storage needed** — all game state is in-memory.

**Nginx reverse proxy:**
```nginx
location /scribble/ {
    proxy_pass http://127.0.0.1:8080/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}
```

## Upgrade Procedure

1. `docker pull biosmarcel/scribble.rs:latest`
2. `docker stop scribble-rs && docker rm scribble-rs`
3. Re-run the `docker run` command with new image
4. Check releases: https://github.com/scribble-rs/scribble.rs/releases

## Gotchas

- **Docker images on tagged releases only**: Starting from v0.8.5, Docker images are built only on tagged releases — `latest` always points to the newest release
- **In-memory only**: No persistence — all active lobbies are lost on restart; this is by design for a casual game
- **WebSocket required**: The game uses WebSockets for real-time communication — ensure your reverse proxy passes WebSocket upgrade headers
- **Custom word lists**: Each lobby can use custom word lists entered in the lobby creation UI — no server-side config needed
- **No auth/admin**: Anyone who can reach the URL can create a lobby; consider putting it behind VPN or basic auth if you want private use only
- **Low maintenance**: Repository has occasional commits; the project is feature-stable

## Links

- Upstream README: https://github.com/scribble-rs/scribble.rs/blob/master/README.md
- Releases: https://github.com/scribble-rs/scribble.rs/releases
- Docker Hub: https://hub.docker.com/r/biosmarcel/scribble.rs
- Discord: https://discord.gg/cE5BKP2UnE
