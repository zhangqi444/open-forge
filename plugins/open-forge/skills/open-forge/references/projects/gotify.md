---
name: Gotify
description: Simple self-hosted push notification server. Send messages via REST API, receive via WebSocket or Android app. Single-binary Go service, tiny footprint, plugin system for extensions. MIT.
---

# Gotify

Gotify is a minimal push-notification backend — think "ntfy but simpler, with a proper Android app and admin UI". You POST a message to `/message?token=X`, and any connected client (Android app, WebSocket, third-party bridge) receives it in real time.

- Upstream repo: <https://github.com/gotify/server>
- Docs: <https://gotify.net/docs>
- Install docs: <https://gotify.net/docs/install>
- Android app: <https://github.com/gotify/android> (Play Store + F-Droid)
- CLI: <https://github.com/gotify/cli>

## Architecture in one minute

One binary, one sqlite file (or external DB). Inside:

- **REST API** on `/message` (send) and `/application`, `/client`, `/user` (manage)
- **WebSocket** on `/stream` (receive) — clients hold persistent connections
- **Web UI** serving the embedded frontend + admin panel
- **Plugin runtime** — plugins are Go-plugin `.so` files loaded at startup (push bridges for Matrix, Telegram, etc.)

Database can be SQLite (default, single file), MySQL, or PostgreSQL. For most deployments, SQLite is perfect.

## Compatible install methods

| Infra     | Runtime                                            | Notes                                                              |
| --------- | -------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM | Docker (`gotify/server` or `ghcr.io/gotify/server`) | **Recommended.** Multi-arch: amd64, i386, arm64, armv7, riscv64     |
| Single VM | Binary release (Linux/Windows)                     | Tiny (<20 MB), runs under systemd directly                          |
| Raspberry Pi | Docker or binary (armv7)                       | Great use case — low-power always-on notifications                  |
| Kubernetes | Community manifests / plain Deployment            | Single-replica + PVC for SQLite; or external DB for HA             |
| Windows   | `.zip` with `.exe`                                 | Works, less common                                                  |

## Inputs to collect

| Input                       | Example                                      | Phase    | Notes                                                               |
| --------------------------- | -------------------------------------------- | -------- | ------------------------------------------------------------------- |
| Public URL                  | `https://gotify.example.com`                 | Runtime  | Used for Android app server URL + WebSocket auth                    |
| Port                        | `80` internal, `8080` external               | Network  | Internal binds to `:80`; map to any external port                   |
| Data volume                 | `./gotify_data:/app/data`                    | Data     | Contains `gotify.db` (SQLite), plugins, uploaded app icons          |
| `GOTIFY_DEFAULTUSER_PASS`   | strong password                              | Bootstrap | Password for first-boot admin user (`admin`); change after login    |
| `TZ`                        | `Europe/Berlin`                              | Runtime  | Log timestamps                                                      |
| TLS                         | reverse proxy OR built-in Let's Encrypt     | Security | Built-in LE works; reverse proxy is more flexible                   |
| Database                    | SQLite (default) / MySQL / Postgres          | DB       | SQLite is fine for 99% of use cases                                 |

## Install via Docker (upstream-documented)

From <https://gotify.net/docs/install>:

```yaml
# docker-compose.yml
services:
  gotify:
    image: gotify/server:2               # pin major; current is 2.x
    container_name: gotify
    restart: unless-stopped
    ports:
      - 8080:80
    environment:
      TZ: Europe/Berlin
      GOTIFY_DEFAULTUSER_PASS: 'REPLACE_WITH_STRONG_PASSWORD'
      # Optional: external DB
      # GOTIFY_DATABASE_DIALECT: postgres
      # GOTIFY_DATABASE_CONNECTION: 'host=postgres port=5432 user=gotify dbname=gotify password=... sslmode=disable'
    volumes:
      - ./gotify_data:/app/data
    # For dedicated user:
    # user: "1234:1234"
```

First boot: browse `http://<host>:8080`, log in as `admin` with the password you set. Dashboard → Users → Edit admin → change password (even if you set via env, rotating it is good practice).

### Minimal `docker run`

```sh
docker run -d --name gotify \
  -p 8080:80 \
  -e TZ=Europe/Berlin \
  -e GOTIFY_DEFAULTUSER_PASS='REPLACE_ME' \
  -v /var/gotify/data:/app/data \
  --restart unless-stopped \
  gotify/server:2
```

### Binary install (systemd)

From <https://gotify.net/docs/install>:

```sh
cd /opt
sudo wget https://github.com/gotify/server/releases/download/v2.X.Y/gotify-linux-amd64.zip
sudo unzip gotify-linux-amd64.zip -d gotify && cd gotify
sudo chmod +x gotify-linux-amd64

# Drop a config.yml next to the binary (see upstream config docs)
sudo tee /etc/systemd/system/gotify.service > /dev/null <<EOF
[Unit]
Description=Gotify
After=network.target

[Service]
ExecStart=/opt/gotify/gotify-linux-amd64
WorkingDirectory=/opt/gotify
User=gotify
Group=gotify
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable --now gotify
```

## Sending a message

```sh
curl -X POST "https://gotify.example.com/message?token=APP_TOKEN" \
  -F "title=Deploy finished" \
  -F "message=Production is live" \
  -F "priority=5"
```

App tokens are created in Dashboard → Apps. Each app = one notification stream you can delete/revoke independently.

## Receiving on Android

1. Install Gotify Android from Play Store or F-Droid.
2. Open app → Settings → server URL = `https://gotify.example.com`.
3. Log in as your user — the app creates a "client" token automatically.
4. Push notifications arrive in real time via WebSocket.

## Database backends

From <https://gotify.net/docs/config>:

```yaml
# config.yml options:
database:
  dialect: sqlite3              # default; or 'mysql' / 'postgres'
  connection: data/gotify.db    # SQLite path; or connection string
```

Via env:

```
GOTIFY_DATABASE_DIALECT=postgres
GOTIFY_DATABASE_CONNECTION='host=db port=5432 user=gotify dbname=gotify password=... sslmode=disable'
```

## Data & config layout

Inside `/app/data`:

- `gotify.db` — SQLite database (users, apps, clients, messages, plugin state)
- `images/` — uploaded app icons
- `certs/` — Let's Encrypt certs (if built-in TLS is enabled)
- `plugins/` — loaded plugin `.so` files

`config.yml` (optional; most config goes via env) lives next to the binary or at `/etc/gotify/config.yml`.

## Backup

```sh
# Dead-simple: stop, tar data, start
docker compose stop gotify
tar czf gotify-$(date +%F).tgz ./gotify_data
docker compose start gotify

# SQLite is file-based; hot backup with sqlite3 CLI also works:
docker run --rm -v "$PWD/gotify_data:/data" alpine \
  sh -c 'apk add sqlite && sqlite3 /data/gotify.db ".backup /data/backup.db"'
```

## Upgrade

1. Releases: <https://github.com/gotify/server/releases>.
2. Docker: `docker compose pull && docker compose up -d`. Gotify runs migrations on startup.
3. Binary: download new zip, replace binary, `sudo systemctl restart gotify`.
4. **Minor versions are safe**; major versions (1 → 2) have migration steps documented per release.
5. Plugin compatibility may break across majors — rebuild or re-download plugin `.so` files.

## Gotchas

- **Default admin password is `admin` if you don't set `GOTIFY_DEFAULTUSER_PASS`.** Set the env on first boot. Don't rely on "I'll change it later" — Gotify is often exposed to push automation; leaked default = spam spammer.
- **App tokens are authentication.** Anyone with the token can push — treat them like API keys. Revoke in dashboard when a consumer is decommissioned.
- **WebSocket requires reverse-proxy `Upgrade`/`Connection` headers.** Nginx default config drops them; add `proxy_http_version 1.1; proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";` in the location block. Caddy/Traefik work out of the box.
- **Built-in Let's Encrypt works but requires ports 80 + 443 exposed to the internet.** If you're already reverse-proxying, disable Gotify's internal TLS (`server.ssl.enabled: false`) and terminate at your proxy.
- **No push-notification service (FCM/APNS) by default.** The Android app uses direct WebSocket — battery-friendly on Android but drops connections occasionally (WiFi transitions, doze mode). A background "service" in the app keeps it alive. iOS has no supported Gotify app (APNS needs developer cert).
- **Plugin system requires Go plugin `.so` compatibility.** Plugins compiled for Gotify 2.0 won't load in 2.5 if Go compiler versions differ. Keep plugins up to date or expect startup errors.
- **SQLite is fine until it isn't.** Heavy traffic (>10 msg/s) will hit SQLite's single-writer bottleneck. Switch to Postgres if you see lock contention.
- **No clustering.** Gotify is single-instance. If you need HA, run two instances behind a LB with sticky sessions + shared Postgres — but WebSocket clients will disconnect on failover.
- **Message history is unbounded by default.** Gotify keeps every message ever sent in the DB. Large deployments should set up periodic cleanup via admin API (DELETE `/message?token=...&since=...`).
- **Message extras (images, click URLs) are markdown-rendered.** The Android app renders formatting; the CLI and webhooks get raw text. Style accordingly.
- **CORS is strict by default** — cross-origin browser clients need `server.cors.alloworigins` configured in `config.yml`.
- **Trusted-proxies config matters behind a reverse proxy.** Set `server.trustedproxies: ["127.0.0.1", "172.16.0.0/12"]` so Gotify honors `X-Forwarded-For` for rate-limit / logging purposes.
- **Client tokens (for receive) vs Application tokens (for send) are distinct.** Both are created in the dashboard; don't confuse them when debugging auth failures.
- **Alternatives worth knowing:**
  - **ntfy** (<https://ntfy.sh>) — similar but topic-subscription model, APNS + FCM supported, bigger feature set
  - **Apprise** — multi-backend notification router (use Gotify as one of many targets)
  - **Pushover** — SaaS equivalent, not self-hosted
- **Matrix bot?** Check the plugin ecosystem: <https://github.com/gotify/contrib/> lists community plugins and bridges.

## Links

- Repo: <https://github.com/gotify/server>
- Docs: <https://gotify.net/docs>
- Install: <https://gotify.net/docs/install>
- Configuration: <https://gotify.net/docs/config>
- REST API: <https://gotify.net/api-docs>
- Plugins: <https://gotify.net/docs/plugin>
- Contrib plugins: <https://github.com/gotify/contrib>
- Android app: <https://github.com/gotify/android>
- CLI: <https://github.com/gotify/cli>
- Releases: <https://github.com/gotify/server/releases>
- Docker Hub: <https://hub.docker.com/r/gotify/server>
