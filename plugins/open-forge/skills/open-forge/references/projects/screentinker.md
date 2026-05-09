---
name: ScreenTinker
description: "Open-source digital signage management software. Manage playlists and content on TVs, displays, and kiosks from a web dashboard. Supports Android TV, Fire TV, Raspberry Pi, Windows, ChromeOS, LG webOS, Samsung Tizen. Multi-zone layouts, scheduling, video walls, device groups. Node.js, SQLite. Self-hosted mode unlocks all features for free."
---

# ScreenTinker

ScreenTinker is **open-source digital signage management software** — deploy it on your own server and manage content on any number of displays (TVs, kiosks, digital boards) from a centralised web dashboard. Supports Android TV, Fire TV, Raspberry Pi, Windows, ChromeOS, LG webOS, Samsung Tizen, and any device with a web browser.

In **self-hosted mode** (`SELF_HOSTED=true`), the first registered user gets full access with all features unlocked — no subscription required.

- Upstream repo: <https://github.com/screentinker/screentinker>
- Hosted version: <https://screentinker.com> (free tier available)
- Community: Discord <https://discord.gg/JHWQRPaG>

## Architecture

- **Server**: Node.js 20+, listens on port 3001 (HTTP) or 3443 (HTTPS if SSL certs present)
- **Database**: SQLite (embedded)
- **Players**: Web-based PWA (any browser) or Android TV app
- **Content delivery**: WebSocket-based real-time sync; offline resilience (Service Worker / ContentCache)

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Direct (Node.js) | node server.js | Primary — Node.js 20+ required |
| systemd service | node server.js | Production deployment |
| Behind reverse proxy | nginx / Caddy | Recommended for HTTPS + WebSocket upgrade |

No official Docker image at time of writing — install via Node.js directly.

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| Domain | signage.example.com | dns | |
| PORT | 3001 | preflight | Default HTTP port |
| SELF_HOSTED | true | preflight | First user gets Enterprise features free |
| APP_URL | https://signage.example.com | preflight | Required for Stripe callbacks only |
| JWT_SECRET | openssl rand -hex 32 | preflight | Auto-generated if not set; set explicitly for stability |
| SSL cert + key | /etc/ssl/certs/... | tls | If exposing HTTPS directly (no reverse proxy) |
| Email webhook URL (optional) | POST endpoint | integration | For device-offline alerts |
| Google / Microsoft OAuth (optional) | Client ID | auth | For SSO login |
| Stripe keys (optional) | sk_live_... | billing | For charging users in multi-tenant setup |

## Install (Node.js + systemd)

From upstream README: <https://github.com/screentinker/screentinker#self-hosting>

### Quick start

```bash
git clone https://github.com/screentinker/screentinker.git
cd screentinker/server
npm install
SELF_HOSTED=true node server.js
```

Server starts on port 3001. Open the URL shown in the startup banner.

### Production (systemd)

```bash
sudo useradd -r -s /bin/false screentinker
sudo cp -r . /opt/screentinker
sudo chown -R screentinker:screentinker /opt/screentinker
cd /opt/screentinker/server && sudo npm install --production

sudo tee /etc/systemd/system/screentinker.service << 'EOF'
[Unit]
Description=ScreenTinker
After=network.target

[Service]
Type=simple
User=screentinker
WorkingDirectory=/opt/screentinker/server
ExecStart=/usr/bin/node server.js
Restart=always
Environment=PORT=3001
Environment=NODE_ENV=production
Environment=SELF_HOSTED=true
# Environment=APP_URL=https://signage.yourcompany.com
# Environment=JWT_SECRET=your-stable-secret

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now screentinker
```

### Reverse proxy (nginx example)

```nginx
server {
    listen 80;
    server_name signage.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name signage.example.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    client_max_body_size 500M;

    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

WebSocket upgrade headers are required for real-time device sync.

## Environment variables

| Variable | Default | Notes |
|---|---|---|
| PORT | 3001 | HTTP listen port |
| HTTPS_PORT | 3443 | HTTPS port (used when SSL certs present) |
| SELF_HOSTED | false | Set true — first user gets all features unlocked |
| DISABLE_REGISTRATION | false | Block new signups (first-user setup still allowed) |
| APP_URL | (none) | Your public URL — required for Stripe callbacks |
| JWT_SECRET | (auto-generated) | Set explicitly for stable sessions across restarts |
| SSL_CERT | server/certs/cert.pem | Path to SSL certificate |
| SSL_KEY | server/certs/key.pem | Path to SSL private key |
| EMAIL_WEBHOOK_URL | (none) | POST endpoint for device-offline email alerts |
| GOOGLE_CLIENT_ID | (none) | Google OAuth client ID |
| MICROSOFT_CLIENT_ID | (none) | Azure AD application client ID |
| MICROSOFT_TENANT_ID | (none) | Azure AD tenant ID (common for multi-tenant) |
| STRIPE_SECRET_KEY | (none) | Optional billing; not needed for self-hosted |
| STRIPE_WEBHOOK_SECRET | (none) | Optional Stripe webhook signing secret |

## Features summary

- **Playlists**: create, reorder, set per-item duration, draft/publish workflow
- **Device groups**: assign playlist to group, bulk commands (reboot, screen on/off, update)
- **Multi-zone layouts**: drag-and-drop editor, 7 built-in templates (fullscreen, split, L-bar, PiP, grid)
- **Video walls**: combine multiple displays, bezel compensation, leader-based sync
- **Scheduling**: weekly calendar with recurrence, timezone support, priority-based conflict resolution
- **Widgets**: clocks, weather, RSS tickers, text/HTML, webpages, social feeds, Directory Board
- **Kiosk mode**: interactive touchscreen interfaces
- **Proof-of-play**: per-content and per-device analytics, CSV export
- **Device telemetry**: battery, storage, RAM, CPU, WiFi signal
- **Offline resilience**: cached content during outages (Android ContentCache + Service Worker)
- **Teams**: multi-user with owner/editor/viewer roles
- **White-label**: custom branding, colors, logo, CSS, domain
- **Auto-update**: OTA updates pushed to Android players
- **Activity log**: full audit trail

## Upgrade procedure

```bash
cd /opt/screentinker
git pull
cd server && npm install --production
sudo systemctl restart screentinker
```

No database migration steps documented — SQLite schema managed automatically.

## Gotchas

- WebSocket upgrade headers required in reverse proxy — without them, devices won't sync in real time
- `SELF_HOSTED=true` only triggers for the **first** registered user; set it before first signup
- `JWT_SECRET` auto-generates on start — if not explicitly set, sessions are invalidated on restart
- SSL direct (no proxy) — place cert at `server/certs/cert.pem` and key at `server/certs/key.pem`; server auto-detects and starts HTTPS on 3443
- Email alerts use a webhook URL (POST endpoint accepting JSON `{to, subject, body}`) — not direct SMTP; wire up a small adapter or use a service like Make/Zapier if needed
- Stripe is optional — without it, all features are free for all users in self-hosted mode
- `client_max_body_size` in nginx must be high enough for video uploads (default 500M or higher)
- Android players support OTA update push from the dashboard; web players update on page refresh

## TODO — verify on subsequent deployments

- Confirm Docker image availability (not present at time of writing)
- Validate Android TV player app download location from dashboard
- Confirm SQLite data file location for backup purposes
