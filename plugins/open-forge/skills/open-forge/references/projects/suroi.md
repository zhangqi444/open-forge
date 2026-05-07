---
name: Suroi
description: Open-source 2D battle royale game inspired by surviv.io. Self-host your own game server with Bun and serve the client via Nginx. GPL-2.0 licensed.
website: https://suroi.io/
source: https://github.com/HasangerGames/suroi
license: GPL-2.0
stars: 450
tags:
  - game
  - battle-royale
  - multiplayer
  - 2d
platforms:
  - JavaScript
  - Bun
---

# Suroi

Suroi is an open-source 2D battle royale game inspired by the now-defunct surviv.io. Built with TypeScript, PixiJS (client rendering), and Bun (runtime). Play the official instance at https://suroi.io, or self-host your own server. The project is actively developed and accepts contributions.

Source: https://github.com/HasangerGames/suroi
Play: https://suroi.io
Wiki (self-hosting): https://github.com/HasangerGames/suroi/wiki/Self%E2%80%90hosting
Discord: https://discord.suroi.io

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Bun + Nginx | Recommended for production |
| Any Linux / macOS | Bun (dev mode) | For local development |

## Inputs to Collect

**Phase: Planning**
- Server hostname/IP (for connecting clients)
- Port for game server (default: 8000)
- Nginx setup for serving the built client

## Software-Layer Concerns

**Install dependencies:**

```bash
# Install Git and Bun
curl -fsSL https://bun.sh/install | bash
# Reload shell or: source ~/.bashrc

git clone https://github.com/HasangerGames/suroi.git
cd suroi
bun install
```

**Development (local testing):**

```bash
bun dev
# Both server and client start; visit http://127.0.0.1:3000
# Or run separately:
bun dev:server   # terminal 1
bun dev:client   # terminal 2
```

**Production build and serve:**

```bash
# Build the client for production
bun build:client
# Output goes to client/dist/

# Start the game server
bun start
```

**Nginx config for client (production):**

```nginx
server {
    listen 80;
    server_name suroi.example.com;

    root /path/to/suroi/client/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**Systemd service for game server:**

```ini
[Unit]
Description=Suroi Game Server
After=network.target

[Service]
Type=simple
User=games
WorkingDirectory=/opt/suroi
ExecStart=/root/.bun/bin/bun start
Restart=on-failure
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

**Self-hosting wiki:** The official self-hosting wiki covers server configuration options, connecting the client to a custom server URL, and additional setup details:
https://github.com/HasangerGames/suroi/wiki/Self%E2%80%90hosting

## Upgrade Procedure

1. `git pull`
2. `bun install` (update dependencies)
3. `bun build:client` (rebuild client)
4. Restart the server: `systemctl restart suroi`

## Gotchas

- **Bun runtime**: Suroi requires Bun (not Node.js) — install via https://bun.sh
- **Client and server both needed**: The client (Vite/PixiJS SPA) and the game server are separate processes — both must be running and the client must point to the server's WebSocket URL
- **Not a web app**: This is a game server, not a web service — it requires open ports for WebSocket connections between browser clients and the server
- **Active development**: Suroi is a work in progress; breaking changes between releases are expected — check the changelog before upgrading
- **GPL-2.0**: Modifications must be shared under GPL-2.0 if distributed

## Links

- Source: https://github.com/HasangerGames/suroi
- Self-hosting wiki: https://github.com/HasangerGames/suroi/wiki/Self%E2%80%90hosting
- Play the official instance: https://suroi.io
- Discord: https://discord.suroi.io
- Releases: https://github.com/HasangerGames/suroi/releases
