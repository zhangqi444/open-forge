---
name: mirotalk-sfu
description: MiroTalk SFU recipe for open-forge. Self-hosted WebRTC video conferencing platform using mediasoup SFU architecture. Source: https://github.com/miroslavpejic85/mirotalksfu. Website: https://sfu.mirotalk.com.
---

# MiroTalk SFU

Self-hosted, open-source WebRTC video conferencing platform using a Selective Forwarding Unit (SFU) architecture powered by [mediasoup](https://mediasoup.org). Supports video up to 8K @ 60fps, screen sharing, recording, collaborative whiteboard, chat with Markdown, file sharing, OIDC auth, REST API, RTMP/OBS streaming, and 133 languages. License: AGPL-3.0. Upstream: <https://github.com/miroslavpejic85/mirotalksfu>. Live demo: <https://sfu.mirotalk.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose | Primary recommended method |
| VPS / bare metal | Node.js (direct) | Requires Node.js 18+ and npm |
| Home server | Docker Compose | Works on LAN; requires proper STUN/TURN for WAN |
| Cloud | Cloudron | One-click Cloudron install available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Public domain/hostname?" | e.g. sfu.example.com — needed for TLS and TURN |
| port | "HTTPS port?" | Default: 3010 |
| stun_server | "STUN server?" | Default: stun:stun.l.google.com:19302 |
| turn_enabled | "Enable TURN server?" | Needed for NAT traversal behind symmetric NAT |
| turn_host | "TURN server host:port (if enabled)?" | |
| turn_user | "TURN username (if enabled)?" | |
| turn_pass | "TURN password (if enabled)?" | |
| host_protection | "Enable host protection (password for meeting hosts)?" | Prevents unauthorized room creation |
| api_key | "REST API key?" | For programmatic room management |
| rtmp_enabled | "Enable RTMP/OBS streaming?" | Requires additional config |

## Software-layer concerns

- **Node.js 18+** required for non-Docker installs
- mediasoup requires build tools (`gcc`, `python3`) — handled automatically in Docker
- Config files:
  - `app/src/config.js` — main server config (rooms, auth, TURN, API key, etc.)
  - `.env` — environment overrides
  - `docker-compose.yml` — generated from `docker-compose.template.yml`
- **STUN/TURN**: STUN is required for WebRTC peer connectivity. TURN is needed when participants are behind symmetric NAT (common in corporate networks). Use your own Coturn server or a hosted TURN provider.
- **TLS required**: WebRTC and microphone/camera access require HTTPS. Place behind an NGINX/Caddy reverse proxy with a valid TLS cert, or use the built-in TLS support.
- Default port: 3010 (HTTPS)
- No persistent database — room state is in-memory; recordings saved to `public/recordings/` by default

### Docker Compose setup

```bash
git clone https://github.com/miroslavpejic85/mirotalksfu.git
cd mirotalksfu
cp app/src/config.template.js app/src/config.js
cp .env.template .env
cp docker-compose.template.yml docker-compose.yml
# Edit app/src/config.js to set your TURN server, API key, host protection, etc.
docker compose pull
docker compose up -d
# Visit https://localhost:3010
```

### docker-compose.yml (generated from template)

```yaml
services:
  mirotalksfu:
    image: mirotalk/sfu:latest
    container_name: mirotalksfu
    restart: unless-stopped
    ports:
      - "3010:3010"
    volumes:
      - ./app/src/config.js:/src/app/src/config.js:ro
      - ./public/recordings:/src/public/recordings
    environment:
      - NODE_ENV=production
```

### Minimal config.js excerpt (key sections)

```javascript
// app/src/config.js
module.exports = {
    server: {
        listen: { ip: '0.0.0.0', port: 3010 },
        ssl: {
            cert: '/path/to/cert.pem',   // or use reverse proxy
            key: '/path/to/key.pem',
        },
    },
    mediasoup: {
        worker: {
            rtcMinPort: 40000,
            rtcMaxPort: 40100,
        },
    },
    iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        // Add TURN if needed:
        // { urls: 'turn:turn.example.com:3478', username: 'user', credential: 'pass' }
    ],
    hostProtected: false,     // set true + hostCfg.username/password for host auth
    apiKeySecret: 'changeme', // REST API key
};
```

### Reverse proxy (Nginx)

```nginx
server {
    listen 443 ssl;
    server_name sfu.example.com;
    ssl_certificate /etc/letsencrypt/live/sfu.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sfu.example.com/privkey.pem;

    location / {
        proxy_pass https://localhost:3010;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Open required firewall ports

```bash
# WebRTC media ports (UDP) — must match rtcMinPort/rtcMaxPort in config
sudo ufw allow 40000:40100/udp
# HTTPS
sudo ufw allow 3010/tcp
# TURN (if self-hosting Coturn)
sudo ufw allow 3478/udp
sudo ufw allow 3478/tcp
```

## Upgrade procedure

1. `docker compose pull && docker compose up -d`
2. Review `app/src/config.template.js` for new config options introduced in the release
3. Merge new options into your `app/src/config.js` manually
4. Check release notes: https://github.com/miroslavpejic85/mirotalksfu/releases

## Gotchas

- **TURN server is essential for WAN**: Without a TURN server, participants behind symmetric NAT (most corporate networks and some ISPs) cannot connect. Either self-host [Coturn](https://github.com/coturn/coturn) or use a managed TURN service (Metered, Twilio, etc.).
- **mediasoup WebRTC UDP ports**: mediasoup uses a port range for WebRTC media (default 40000–40100 UDP). These ports must be open in your firewall and accessible from the internet for video to flow.
- **TLS is mandatory**: Browsers block camera/microphone access on non-HTTPS origins. You must have a valid TLS cert — either via a reverse proxy (NGINX + Let's Encrypt) or by pointing the built-in TLS config at your certs.
- **Recording disk usage**: Recordings are saved to `public/recordings/`. Monitor this directory — long meetings can produce large files quickly. There is no automatic cleanup.
- **mediasoup build on non-x86**: On ARM64 (Raspberry Pi, Apple Silicon), mediasoup compiles from source during `npm install`. Ensure `gcc`, `python3`, and build tools are installed. The Docker image handles this automatically.
- **config.js not config.json**: The main config is a JS module (`module.exports = {...}`), not JSON. Syntax errors in config.js will prevent the server from starting with no helpful error message — validate the JS syntax first.

## Links

- Upstream repo: https://github.com/miroslavpejic85/mirotalksfu
- Live demo: https://sfu.mirotalk.com
- Documentation: https://docs.mirotalk.com/mirotalk-sfu/
- Self-hosting guide: https://docs.mirotalk.com/mirotalk-sfu/self-hosting/
- Docker Hub: https://hub.docker.com/r/mirotalk/sfu
- REST API docs: https://docs.mirotalk.com/mirotalk-sfu/api/
- Release notes: https://github.com/miroslavpejic85/mirotalksfu/releases
