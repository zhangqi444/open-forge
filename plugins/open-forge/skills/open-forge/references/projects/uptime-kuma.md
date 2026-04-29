---
name: uptime-kuma-project
description: Uptime Kuma recipe for open-forge. Self-hosted uptime monitoring (HTTP / TCP / ping / DNS / keyword / JSON / WebSocket / Steam / Docker). Single-container Node.js app with SQLite (bundled). Trivial to deploy — `docker run` or `docker compose up -d` with one volume.
---

# Uptime Kuma (self-hosted uptime monitoring)

MIT-licensed, easy-to-use self-hosted monitoring tool. Fancy UI, 90+ notification integrations (Telegram, Discord, Gotify, Slack, Pushover, SMTP, and more), 20-second intervals, multiple status pages, 2FA.

**Upstream README:** https://github.com/louislam/uptime-kuma/blob/master/README.md
**Upstream wiki:** https://github.com/louislam/uptime-kuma/wiki
**Compose file (in repo):** https://github.com/louislam/uptime-kuma/blob/master/compose.yaml
**Docker Hub:** https://hub.docker.com/r/louislam/uptime-kuma

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | README single-command install |
| localhost | Docker Compose | ✅ | Repo ships `compose.yaml` — drop-in |
| localhost | native (Node.js + pm2) | ✅ | Node.js ≥ 20.4 required; pm2 for background |
| byo-vps | Docker | ✅ | Tiny footprint — ~200 MB RAM |
| raspberry-pi | Docker (arm64) | ✅ | Official arm64 image ships |
| aws/ec2 | Docker | ✅ | `t3.nano` works |
| hetzner/cloud-cx | Docker | ✅ | CX11 is overkill but fine |
| digitalocean/droplet | Docker | ✅ | |
| kubernetes | community Helm | ⚠️ | No official chart; community `k8s-at-home/uptime-kuma`-style charts exist. Flag as community-maintained. |

**Upstream explicitly rejects:**
- NFS for the data volume ("File Systems like NFS are NOT supported. Please map to a local directory or volume.")
- FreeBSD / OpenBSD / NetBSD for native install
- Replit / Heroku for native install

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Uptime Kuma on?" | Free-text | e.g. `uptime.example.com` or `status.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| storage | "Host path for Uptime Kuma data (SQLite DB + config)?" | Free-text | Maps to `/app/data` inside the container. **Must be local disk — no NFS.** |
| exposure | "Expose on all interfaces or localhost-only (front with proxy)?" | AskUserQuestion: all / localhost-only | Default `all` = `:3001` on the internet. Localhost + reverse proxy is safer. |
| notifs | "Set up a default notification channel now?" | AskUserQuestion: Skip / Telegram / Discord / SMTP / Gotify / Other | Can always add later via UI |

## Install methods

### 1. Docker Compose (upstream `compose.yaml`)

Source: https://github.com/louislam/uptime-kuma/blob/master/compose.yaml

```bash
mkdir uptime-kuma && cd uptime-kuma
curl -o compose.yaml https://raw.githubusercontent.com/louislam/uptime-kuma/master/compose.yaml
docker compose up -d
```

Which is equivalent to:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    restart: unless-stopped
    volumes:
      - ./data:/app/data
    ports:
      - "3001:3001"
```

The `./data` bind mount keeps the SQLite DB on the host. **Back up this directory.**

### 2. Docker CLI

```bash
docker run -d --restart=always \
  -p 3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:2
```

Named volume (`uptime-kuma`) instead of bind mount.

For localhost-only exposure (behind a reverse proxy):

```bash
docker run -d --restart=always \
  -p 127.0.0.1:3001:3001 \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:2
```

### 3. Native (Node.js + pm2)

Source: README "Non-Docker"

Requirements:
- Linux (Debian/Ubuntu/Fedora/Arch) or Windows 10+ / Windows Server 2012 R2+
- Node.js ≥ 20.4
- Git
- pm2

```bash
git clone https://github.com/louislam/uptime-kuma.git
cd uptime-kuma
npm run setup

# Background via pm2 (recommended)
npm install pm2 -g && pm2 install pm2-logrotate
pm2 start server/server.js --name uptime-kuma

# Boot persistence
pm2 startup && pm2 save
```

Runs on `:3001` on all interfaces.

## Software-layer concerns

### First-run setup

On first visit to `:3001`, Uptime Kuma's UI walks you through creating an admin account. No env-var-driven bootstrap — you must complete it through the browser on first use.

### Data

Everything in `/app/data/`:
- `kuma.db` — SQLite database (monitors, history, incidents, notification configs, status pages)
- `upload/` — status page logos + attachments
- `screenshots/`, etc.

Back up the whole directory. SQLite + filesystem = trivial backup (stop the container, copy the dir, restart; or hot-copy with SQLite's online backup API if you care about zero downtime).

### Reverse proxy

Uptime Kuma uses **WebSockets** for live updates (Socket.IO). Your reverse proxy needs to upgrade connections. Caddy handles this out of the box:

```caddy
uptime.example.com {
  reverse_proxy 127.0.0.1:3001
}
```

Nginx needs explicit WS upgrade headers — see the upstream wiki's reverse-proxy guide: https://github.com/louislam/uptime-kuma/wiki/Reverse-Proxy

### Ports

- `3001` — HTTP + WebSocket (single port, no separate socket server)

### Image tags

- `louislam/uptime-kuma:2` — latest major v2 (recommended)
- `louislam/uptime-kuma:1` — v1 legacy (don't use for new installs)
- `louislam/uptime-kuma:2.X.Y` — pinned version

Upstream is currently on v2 (v2 was a significant rewrite; v1 is legacy — start on v2).

### Notifications

~90+ built-in channels. Set up via the web UI, per-monitor or as a default. Each has a slightly different config (API key / bot token / webhook URL / SMTP creds). No env-var setup — all UI.

Supported channels (partial list): Telegram, Discord, Gotify, Ntfy, Pushover, Pushbullet, Slack, Matrix, Rocket.Chat, Mattermost, Webhook (generic), SMTP, Apprise (wraps many more), Signal (via signal-cli-rest-api), SMS (Twilio, Clicksend, various regional), Alerta, Alertmanager, Squadcast, PagerDuty, Opsgenie, GoogleChat, Line, Splunk, VictorOps.

### Status pages

Multiple public status pages per instance. Map to specific domains (e.g. `status.example.com` serves one status page while `uptime.example.com` serves the admin UI).

To make a status page public: create in UI → set its slug → visit `/status/<slug>`. Domain mapping is under Settings → Status Pages.

## Upgrade procedure

Upstream "How to Update" wiki: https://github.com/louislam/uptime-kuma/wiki/%F0%9F%86%99-How-to-Update

Docker:

```bash
docker compose pull
docker compose up -d
# Or:
docker pull louislam/uptime-kuma:2
docker stop uptime-kuma && docker rm uptime-kuma
docker run ... (re-run install command)
```

The container auto-migrates the SQLite DB on start. Watch logs:

```bash
docker logs -f uptime-kuma
```

**Before a major version upgrade, back up `/app/data/`.** v1 → v2 required a specific migration path; don't assume future majors will be seamless.

Native (pm2):

```bash
cd uptime-kuma
git fetch origin
git checkout 2.X.Y   # or the tag you want
npm install --production
npm run build
pm2 restart uptime-kuma
```

## Gotchas

- **NFS data volume is explicitly unsupported.** Upstream calls this out in the README. Use local disk (ext4/xfs/zfs/btrfs are all fine).
- **WebSocket passthrough is required.** Nginx without proper `Upgrade`/`Connection` headers shows a "disconnected" banner in the UI on refresh. Caddy just works.
- **First-time setup is UI-only.** No headless bootstrap — you must visit the site in a browser to create the admin user. For automation, you'd have to script the HTTP POSTs against the setup API (fragile; upstream doesn't promise stability).
- **Two-factor auth is a one-way door (kind of).** If you enable 2FA and lose the recovery codes, you have to edit `kuma.db` directly to disable it. Not hard (SQLite) but scary.
- **SQLite backups: stop container OR use SQLite's online backup.** Copying `kuma.db` while it's open can corrupt. Safest: `docker stop uptime-kuma && cp -a data data.bak && docker start uptime-kuma` — takes <5s, monitors notice briefly.
- **Status page domain mapping is DNS + app-side.** Add the domain in the app's "Status Pages" settings *and* point DNS at the instance. The app does host-header-based routing.
- **Docker Hub has `louislam/uptime-kuma` (correct).** Avoid forks — v1 had several unofficial mirrors with outdated builds.
- **No clustering / HA.** Uptime Kuma is single-node by design. If you need HA monitoring, run two instances monitoring each other.
- **Pushover / Apprise / etc. notification sender integrations may rate-limit.** If you have 100 monitors all going down at once (e.g. your ISP blips), you'll send 100 notifications. Configure "notify on N consecutive failures" per monitor to debounce.

## TODO — verify on subsequent deployments

- [ ] Behind Cloudflare Tunnel — WebSocket works via CF Tunnel, verify at next home-server deploy.
- [ ] Nginx reverse-proxy config — distill upstream wiki's WS-upgrade snippet into `references/modules/tls.md`.
- [ ] Backup script — hot-copy via SQLite online backup API for zero-downtime backups.
- [ ] Status page domain mapping — end-to-end test.
- [ ] Community Helm chart — identify most-active option.
