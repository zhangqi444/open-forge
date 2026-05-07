---
name: pushbits
description: PushBits recipe for open-forge. Relay push notifications via Matrix. Gotify-compatible send API. Self-hosted alternative to Pushover/Gotify that delivers to your Matrix account without a dedicated app. Go, Docker/Podman. Source: https://github.com/pushbits/server
---

# PushBits

Push notification relay server that delivers notifications to your Matrix account. Send notifications via a simple HTTP API (Gotify-compatible) from scripts, services, or CI/CD pipelines, and receive them as Matrix messages — no additional app needed. Supports multiple users and multiple channels (applications) per user. Written in Go. ISC licensed.

> **Status:** Alpha phase. Looking for maintainers as of 2024.

Upstream: <https://github.com/pushbits/server> | Docs: <https://pushbits.github.io/docs/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (ghcr.io/pushbits/server) | Only supported install method |
| Any | Podman | Also supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Matrix account or homeserver | PushBits sends messages to a Matrix user |
| config | Matrix homeserver URL | e.g. https://matrix.org |
| config | Matrix bot username + password | Dedicated Matrix account for PushBits to send from |
| config | Admin Matrix ID | Your Matrix ID (e.g. @you:matrix.org) — receives bot's messages |
| config | PushBits admin password | Web API admin password |
| config | Database backend | SQLite (default) or MySQL/PostgreSQL |
| config | Port | Default: 8080 |

## Software-layer concerns

### Architecture

- Single Go binary (Docker) — HTTP API server
- SQLite or MySQL/PostgreSQL — stores users, applications, tokens
- Matrix homeserver — delivery channel; PushBits connects as a Matrix bot

### Config file (`config.yml`)

PushBits reads `config.yml` mounted into the container:

```yaml
debug: false

http:
  port: 8080

database:
  dialect: sqlite3
  connection: pushbits.db   # or mysql/postgres DSN

matrix:
  homeserver: https://matrix.org
  username: "@pushbits-bot:matrix.org"
  password: "bot-account-password"

admin:
  matrix_id: "@you:matrix.org"
  name: admin
  password: "admin-api-password"

crypto:
  # Use HIBP to check for weak passwords (optional)
  hibp: false
```

See full config sample at https://github.com/pushbits/server/blob/master/config.sample.yml

## Install — Docker

```bash
mkdir pushbits && cd pushbits

# Create config file
cat > config.yml << 'EOF'
http:
  port: 8080

database:
  dialect: sqlite3
  connection: /data/pushbits.db

matrix:
  homeserver: https://matrix.org
  username: "@your-bot:matrix.org"
  password: "bot-password"

admin:
  matrix_id: "@you:matrix.org"
  name: admin
  password: "your-admin-password"
EOF

docker run -d \
  --name pushbits \
  --restart unless-stopped \
  -p 8080:8080 \
  -v $(pwd)/config.yml:/config.yml \
  -v $(pwd)/data:/data \
  ghcr.io/pushbits/server:latest
```

> Deploy behind a reverse proxy with TLS — PushBits docs recommend HTTPS.

## Usage

```bash
# Create an application (channel) via the admin API
curl -u admin:your-admin-password \
  -X POST http://localhost:8080/application \
  -H "Content-Type: application/json" \
  -d '{"name": "My App"}'
# Returns: { "token": "app-token-here", ... }

# Send a notification (Gotify-compatible API)
curl -X POST http://localhost:8080/message?token=app-token-here \
  -H "Content-Type: application/json" \
  -d '{"title": "Alert", "message": "Something happened!", "priority": 5}'
```

The message appears as a Matrix message from your bot to your admin Matrix ID.

## Upgrade procedure

```bash
docker pull ghcr.io/pushbits/server:latest
docker rm -f pushbits
# Re-run docker run command
```

## Gotchas

- PushBits requires a dedicated Matrix account (bot account) separate from your personal Matrix account. Create one at your homeserver before setup.
- Deploy behind HTTPS — the PushBits docs explicitly recommend a reverse proxy with TLS; HTTP only is not recommended for production.
- Alpha software — the project is looking for maintainers. It's functional but may not receive active updates.
- Gotify API compatibility means existing Gotify integrations (Watchtower, Jellyfin, etc.) can send to PushBits without modification — just point them at your PushBits URL with the app token.
- SQLite default is fine for personal use. For multi-user or high-traffic setups, configure MySQL or PostgreSQL.

## Links

- Source: https://github.com/pushbits/server
- Documentation: https://pushbits.github.io/docs/
- API docs: https://pushbits.github.io/api/
- Config sample: https://github.com/pushbits/server/blob/master/config.sample.yml
