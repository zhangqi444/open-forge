# Screego

Screen sharing for developers. Share your screen with high quality and low latency via WebRTC directly in the browser — no plugins, no accounts. Includes an integrated TURN server for NAT traversal. GPL-3.0. 10K+ GitHub stars. Upstream: <https://github.com/screego/server>. Docs: <https://screego.net>.

Screego is a single Go binary / Docker image that serves the web UI and handles WebRTC signaling + TURN on ports `5050` (HTTP), `3478` (TURN/UDP), and `3478` (TURN/TCP).

## Compatible install methods

Verified against upstream docs at <https://screego.net/#/install>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | `docker run -e ... screego/server:1.12.4` | ✅ | Easiest path. |
| Docker Compose | See below | ✅ | Easier env management. |
| Binary (Linux) | Download from GitHub releases | ✅ | No Docker. |
| Reverse proxy (with SSL) | <https://screego.net/#/reverse-proxy> | ✅ | Production — TLS via Caddy/nginx/Traefik. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| external_ip | "Public IP or hostname of this server (for TURN)?" | Free-text | All |
| password | "Password to restrict room creation (optional)?" | Free-text (sensitive) | Optional |
| users | "Add named user accounts? (format: user:hash)" | Free-text | Optional |

## Software-layer concerns

### Docker Compose

```yaml
services:
  screego:
    image: ghcr.io/screego/server:1.12.4
    ports:
      - "5050:5050"
      - "3478:3478/udp"
      - "3478:3478/tcp"
    environment:
      SCREEGO_EXTERNAL_IP: "your.server.ip"
      SCREEGO_SECRET: "change-me-to-a-strong-secret"
      SCREEGO_SERVER_TLS: "false"
      SCREEGO_AUTH_MODE: "none"       # none | all | turn
      # SCREEGO_USERS: "admin:hashed_password"
    restart: unless-stopped
```

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `SCREEGO_EXTERNAL_IP` | Public IP/hostname for TURN server | **Required** |
| `SCREEGO_SECRET` | Secret for signing tokens | **Required in production** |
| `SCREEGO_SERVER_TLS` | Enable built-in TLS | `false` |
| `SCREEGO_TLS_CERT` | Path to TLS certificate | — |
| `SCREEGO_TLS_KEY` | Path to TLS key | — |
| `SCREEGO_AUTH_MODE` | Auth required: `none`, `all`, `turn` | `none` |
| `SCREEGO_USERS` | `user:bcrypt_hash` pairs, space-separated | — |
| `SCREEGO_SERVER_PORT` | HTTP port | `5050` |
| `SCREEGO_TURN_PORT_RANGE` | UDP range for TURN relay | `50000:55000` |
| `SCREEGO_CORS_ALLOWED_ORIGINS` | Allowed CORS origins | `*` |
| `SCREEGO_TRUST_PROXY_HEADERS` | Trust `X-Forwarded-For` headers | `false` |
| `SCREEGO_LOGLEVEL` | Log level: `debug`, `info`, `warn`, `error` | `info` |

### Auth modes

| Mode | Behavior |
|---|---|
| `none` | Anyone can create and join rooms — no login required |
| `turn` | Anonymous browsing OK; creating rooms requires a TURN credential |
| `all` | Login required for all access — room creation and viewing |

Generate a bcrypt password hash for users:
```bash
# Option 1: htpasswd
htpasswd -bnBC 10 "" "mypassword" | tr -d ':\n'

# Option 2: Docker
docker run --rm screego/server:1.12.4 hash --value "mypassword"
```

### NAT traversal / TURN

Screego includes a built-in TURN server. For WebRTC to work through NAT (which is most home/office setups), you **must** set `SCREEGO_EXTERNAL_IP` to the publicly accessible IP or hostname.

If the TURN server ports (`3478/UDP`, `3478/TCP`, `50000-55000/UDP`) are behind a firewall, open them or use the full TURN port range.

For deployments behind a reverse proxy, ensure the proxy passes WebSocket connections through and that TCP TURN (`3478`) is also accessible.

### Reverse proxy (nginx example)

```nginx
server {
    listen 443 ssl;
    server_name screego.example.com;

    location / {
        proxy_pass http://localhost:5050;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Set `SCREEGO_TRUST_PROXY_HEADERS=true` when behind a proxy so users get correct IPs.

### How screen sharing works

1. User visits `https://screego.example.com` → creates or joins a room
2. Server generates a TURN credential and hands it to the browser via WebSocket
3. Browser establishes WebRTC peer connection, using the TURN server if direct P2P fails
4. Screen share stream goes peer-to-peer when possible, via TURN relay otherwise

## Upgrade procedure

```bash
docker pull ghcr.io/screego/server:1.12.4
docker compose up -d
```

Screego has no persistent database — rooms are ephemeral (in-memory). No migrations needed.

## Gotchas

- **`SCREEGO_EXTERNAL_IP` is required.** Without a correct public IP, TURN relay will fail and screen sharing won't work through NAT. Use your server's public IP, not `localhost` or a private IP.
- **Firewall ports must be open.** WebRTC TURN needs `3478/UDP`, `3478/TCP`, and the relay port range (`50000-55000/UDP` by default) accessible from the public internet.
- **Rooms are ephemeral.** No data is persisted — all rooms disappear on restart.
- **HTTPS required for browser screen capture.** Chrome and Firefox only allow `getDisplayMedia()` (screen sharing) on HTTPS origins or `localhost`. A reverse proxy with TLS is mandatory for production.
- **Set `SCREEGO_SECRET` in production.** Default `""` means token signing is disabled — anyone could forge room tokens.
- **Multiple participants**: Screego supports multi-user rooms, but all streams are relayed through WebRTC — high-resolution sharing with many viewers can be bandwidth-intensive.
- **No recording built in.** Screego streams in real-time only; no session recording.

## Links

- Upstream: <https://github.com/screego/server>
- Docs: <https://screego.net>
- Install guide: <https://screego.net/#/install>
- Configuration reference: <https://screego.net/#/config>
- NAT traversal: <https://screego.net/#/nat-traversal>
- Reverse proxy setup: <https://screego.net/#/reverse-proxy>
- Public demo: <https://app.screego.net>
