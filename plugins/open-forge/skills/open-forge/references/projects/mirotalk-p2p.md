---
name: mirotalk-p2p
description: MiroTalk P2P recipe for open-forge. Self-hosted WebRTC P2P video conferencing — unlimited rooms, no time limits, up to 4K/60fps. Docker Compose install. Upstream: https://github.com/miroslavpejic85/mirotalk
---

# MiroTalk P2P

Self-hosted, open-source WebRTC peer-to-peer video conferencing. Direct P2P connections for fast, private communication. Unlimited rooms, no time limits, works in all modern browsers without plugins.

4,491 stars · AGPLv3

Upstream: https://github.com/miroslavpejic85/mirotalk
Website: https://p2p.mirotalk.com/
Docs: https://docs.mirotalk.com/mirotalk-p2p/self-hosting/
Docker Hub: https://hub.docker.com/r/mirotalk/p2p

## What it is

MiroTalk P2P provides a full video conferencing solution:

- **P2P WebRTC** — Direct browser-to-browser connections; server only handles signaling
- **No registration** — Create a room by URL; share link to invite others
- **Unlimited rooms and participants** — No artificial limits
- **No time limits** — Rooms stay open as long as needed
- **Up to 8K, 60fps** — High-resolution video when bandwidth allows
- **Screen sharing** — Share full screen or individual windows
- **File sharing** — Send files directly to participants
- **Text chat** — In-meeting chat with emoji support
- **Recording** — Client-side recording support
- **Room security** — Optional password protection, lobby, IP whitelist

**P2P note**: Because MiroTalk uses direct P2P, a TURN server is required for participants behind strict firewalls/NAT. Without a TURN server, some participants may fail to connect. See the TURN server section below.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (recommended) | https://docs.mirotalk.com/mirotalk-p2p/self-hosting/ | Simplest production deploy |
| Node.js | https://github.com/miroslavpejic85/mirotalk#npm | Direct install, development |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "Domain for MiroTalk (e.g. meet.example.com)?" | Production |
| port | "Port? (default: 3000)" | All |
| turn | "Use a TURN server? Host/port/user/pass?" | Recommended for public deploys |

## Docker Compose install

Upstream: https://docs.mirotalk.com/mirotalk-p2p/self-hosting/

### 1. Clone repo and prepare config

    git clone https://github.com/miroslavpejic85/mirotalk.git
    cd mirotalk

    cp .env.template .env
    cp docker-compose.template.yml docker-compose.yml

### 2. Configure .env

Edit `.env` — key settings:

    NODE_ENV=production
    PORT=3000
    HOST=https://meet.example.com   # set to your domain

    # TURN server (recommended — see below)
    # TURN_ENABLED=true
    # TURN_URLS=["turn:turn.example.com:3478?transport=udp"]
    # TURN_USERNAME=myuser
    # TURN_PASSWORD=mypassword

    # Optional: password-protect the landing page
    # ADMIN_TOKEN=your-secret-token

### 3. Start

    docker compose up -d

Access at http://localhost:3000 (or your domain).

### 4. Create a room

Navigate to http://your-server:3000, click **Create or Join a Room**, share the URL with participants.

## Node.js install (alternative)

    # Requires Node.js 22+
    git clone https://github.com/miroslavpejic85/mirotalk.git
    cd mirotalk
    cp .env.template .env
    cp app/src/config.template.js app/src/config.js
    npm install
    npm start

## Key .env variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | 3000 | HTTP server port |
| `HOST` | (auto) | Public URL of your instance (needed for CORS/ICE candidates) |
| `NODE_ENV` | development | Set to `production` for deployment |
| `TRUST_PROXY` | false | Set to `true` if behind a reverse proxy |
| `CORS_ORIGIN` | `*` | Restrict origins if needed |
| `IP_WHITELIST_ENABLED` | false | Restrict access to specific IPs |
| `TURN_ENABLED` | false | Enable TURN server integration |
| `TURN_URLS` | — | JSON array of TURN URLs |
| `TURN_USERNAME` / `TURN_PASSWORD` | — | TURN credentials |

Full .env reference: https://github.com/miroslavpejic85/mirotalk/blob/master/.env.template

## Reverse proxy (HTTPS — required for WebRTC)

WebRTC requires HTTPS in modern browsers (camera/mic access blocked over HTTP). Always run MiroTalk behind an HTTPS reverse proxy in production.

Caddy:

    meet.example.com {
        reverse_proxy localhost:3000
    }

Nginx:

    server {
        listen 443 ssl;
        server_name meet.example.com;
        ssl_certificate /etc/ssl/fullchain.pem;
        ssl_certificate_key /etc/ssl/privkey.pem;

        location / {
            proxy_pass http://localhost:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }

Set `TRUST_PROXY=true` in `.env` when behind Nginx/Caddy.

## TURN server

For participants behind strict corporate firewalls or double NAT, a TURN relay is needed. Options:

### Option 1: Use a public TURN service (easiest)

Metered.ca offers a free tier TURN server: https://www.metered.ca/tools/openrelay/

### Option 2: Self-host Coturn

    apt install -y coturn

Edit `/etc/turnserver.conf`:

    listening-port=3478
    fingerprint
    lt-cred-mech
    user=myuser:mypassword
    realm=turn.example.com
    total-quota=100
    bps-capacity=0

    systemctl enable --now coturn

Then set in MiroTalk `.env`:

    TURN_ENABLED=true
    TURN_URLS=["turn:turn.example.com:3478?transport=udp","turn:turn.example.com:3478?transport=tcp"]
    TURN_USERNAME=myuser
    TURN_PASSWORD=mypassword

Full Coturn guide: https://docs.mirotalk.com/coturn/installation/

## Upgrade

    cd mirotalk
    git pull
    docker compose pull
    docker compose up -d

## Gotchas

- **HTTPS required for WebRTC** — Browsers block camera/microphone access on non-HTTPS origins. Deploy behind a TLS reverse proxy (Caddy, Nginx + Let's Encrypt).
- **P2P means TURN matters** — The server only handles signaling (small traffic). Actual video/audio is P2P. Participants behind strict NAT/firewalls need a TURN relay to connect.
- **`HOST` must be set correctly** — Set `HOST=https://your-domain.com` in `.env` for production. Without this, ICE candidates may be wrong and connections fail.
- **`TRUST_PROXY=true` behind reverse proxy** — Without this, rate limiting and IP detection see the proxy's IP, not the real client IP.
- **AGPLv3 license** — If you modify MiroTalk and deploy it publicly, you must publish your modified source code. Commercial branding/white-labeling requires a paid license from CodeCanyon.
- **WebSocket upgrade** — The Nginx config must include `Upgrade` and `Connection` headers for WebSocket support (signaling).

## Links

- GitHub: https://github.com/miroslavpejic85/mirotalk
- Website: https://p2p.mirotalk.com/
- Docs: https://docs.mirotalk.com/mirotalk-p2p/self-hosting/
- Docker Hub: https://hub.docker.com/r/mirotalk/p2p
- Coturn setup: https://docs.mirotalk.com/coturn/installation/
- .env template: https://github.com/miroslavpejic85/mirotalk/blob/master/.env.template
