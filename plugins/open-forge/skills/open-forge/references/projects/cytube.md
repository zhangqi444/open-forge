---
name: cytube-project
description: CyTube recipe for open-forge. Synchronized media playback and chat server. Node.js + MySQL. Upstream: https://github.com/calzoneman/sync
---

# CyTube

Synchronized media playback and chat web application supporting an arbitrary number of channels. Supports YouTube, Vimeo, Dailymotion, raw video/audio files, and live stream embeds (Twitch, RTMP, Icecast). Upstream: <https://github.com/calzoneman/sync>. Install wiki: <https://github.com/calzoneman/sync/wiki/Installing>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Node.js (bare) + MySQL | Official method — clone + npm install + config |
| Any Linux VPS/bare-metal | Node.js (bare) + SQLite | Lighter; suitable for small/personal instances |
| Docker host | Docker Compose | Community-assembled compose stack; not officially published by upstream |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain or IP for the CyTube instance | Needed for config.yaml host |
| preflight | Port to listen on (default: 8080) | Ensure firewall allows this port |
| preflight | Admin password | Set in config.yaml admins list |
| database | MySQL or SQLite? | MySQL recommended for multi-user |
| database | MySQL host / port / user / password / database name | If MySQL chosen |
| smtp (optional) | SMTP credentials for password reset emails | Optional but recommended |
| tls (optional) | TLS certificate + key paths or use reverse proxy? | Upstream supports optional SSL on socket.io |

## Software-layer concerns

### Installation

```bash
# Clone the repo
git clone https://github.com/calzoneman/sync.git cytube
cd cytube
npm install

# Copy and edit the config
cp config.template.yaml config.yaml
# Edit config.yaml with your domain, DB credentials, admin passwords
```

Full config reference: https://github.com/calzoneman/sync/wiki/Configuration

### Config file

Main config is config.yaml. Key fields:

- http.host — Bind hostname/IP
- http.port — HTTP listen port (default: 8080)
- mysql.* — MySQL connection settings
- admins — List of admin usernames
- mail.* — SMTP settings for password reset
- ssl.* — Optional TLS for socket.io

### Running

```bash
node index.js
```

For production, use a process manager (pm2 recommended):

```bash
npm install -g pm2
pm2 start index.js --name cytube
pm2 save
pm2 startup
```

### Data directories

- config.yaml — Main configuration
- logs/ — Application logs
- MySQL DB — User accounts, channel data, media cache

### Reverse proxy (recommended)

Put nginx or Caddy in front to handle TLS and expose on port 80/443. Socket.io websocket connections require upgrade headers in the nginx config:

```nginx
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

## Upgrade procedure

```bash
cd cytube
git pull
npm install
pm2 restart cytube
```

Review the changelog before upgrading — config format occasionally changes between versions.

## Gotchas

- Node.js version matters — check the repo's .nvmrc or README for the supported Node version.
- Socket.io upgrade headers required — if using a reverse proxy, websocket upgrade headers are mandatory or real-time sync breaks silently.
- Channel state persists across restarts — channel state is saved/loaded automatically.
- YouTube API quota — CyTube uses the YouTube Data API for metadata. Set up an API key in config or searches/embeds degrade. See https://github.com/calzoneman/sync/wiki/Google-API-Key-Setup
- Media depends on third-party APIs — YouTube, Twitch, etc. require external connectivity and valid API keys.

## Links

- Upstream repo: https://github.com/calzoneman/sync
- Install wiki: https://github.com/calzoneman/sync/wiki/Installing
- Configuration reference: https://github.com/calzoneman/sync/wiki/Configuration
- Reporting issues: https://github.com/calzoneman/sync/wiki/Reporting-an-Issue
