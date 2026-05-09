---
name: call-me
description: "WebRTC click-to-call video/audio platform. AGPL-3.0. miroslavpejic85 / MiroTalk. Persistent shared room, unlimited participants, no signup. End-to-end encrypted. Docker Compose. Screen share, file share, REST API."
---

# Call-me (MiroTalk CME)

**Instant click-to-call video communication in the browser — no signup, no setup for end users.** Users join a persistent shared room with a username, then click to call any other connected participant. All calls are WebRTC peer-to-peer with end-to-end encryption. Self-host on any Linux server with Docker. AGPL-3.0.

Built + maintained by **Miroslav Pejic** (MiroTalk project).

- Upstream repo: <https://github.com/miroslavpejic85/call-me>
- Docs: <https://docs.mirotalk.com/mirotalk-cme/self-hosting/>
- Docker Hub: `mirotalk/cme`
- Demo: <https://cme.mirotalk.com>
- Latest release: v1.x (actively maintained)

## Architecture in one minute

- Single Node.js container, port **8000**
- Config via `.env` file (no database required)
- Optional: `config.js` for advanced UI customisation
- Resource: very low — Node.js process + WebRTC signalling only; media streams are peer-to-peer and do not transit the server
- Pairs with a STUN/TURN server for NAT traversal (default: public Google STUN; add TURN for restrictive networks)

## Compatible install methods

| Infra        | Runtime                             | Notes                                         |
| ------------ | ----------------------------------- | --------------------------------------------- |
| **Docker Compose** | `mirotalk/cme:latest`          | **Primary**                                   |
| **Script (Ubuntu 22/24)** | `cme-install.sh`        | One-liner for bare Ubuntu; handles NGINX + SSL |
| **Node.js** | `npm start`                          | Dev / bare-metal, no container                |

## Inputs to collect

| Input                     | Example                    | Phase    | Notes                                                                     |
| ------------------------- | -------------------------- | -------- | ------------------------------------------------------------------------- |
| `PORT`                    | `8000`                     | Network  | Host port mapped to the app                                               |
| `HOST`                    | `https://call.example.com` | Network  | Public URL (used in share links); leave empty for `localhost` dev use     |
| `HOST_PASSWORD_ENABLED`   | `true`                     | Auth     | Protect the room with a host password                                     |
| `HOST_PASSWORD`           | `<secure password>`        | Auth     | Required if `HOST_PASSWORD_ENABLED=true`                                  |
| `CORS_ORIGIN`             | `*` or `https://call.example.com` | Security | Restrict CORS to your domain in production                      |
| TURN server (optional)    | `coturn` or hosted         | Network  | Required for participants behind symmetric NAT; public STUN works for most |

## Install via upstream script (simplest for Ubuntu)

```bash
# Ubuntu 22.04 / 24.04 — handles NGINX, SSL, and systemd automatically
wget -qO cme-install.sh https://docs.mirotalk.com/scripts/cme/cme-install.sh \
  && chmod +x cme-install.sh \
  && ./cme-install.sh
```

When prompted, enter your domain or subdomain. The script installs Docker, clones the repo, configures NGINX with Let's Encrypt TLS, and starts the container.

To uninstall: `wget -qO cme-uninstall.sh https://docs.mirotalk.com/scripts/cme/cme-uninstall.sh && chmod +x cme-uninstall.sh && ./cme-uninstall.sh`
To update: `wget -qO cme-update.sh https://docs.mirotalk.com/scripts/cme/cme-update.sh && chmod +x cme-update.sh && ./cme-update.sh`

## Install via Docker Compose (manual)

```bash
git clone https://github.com/miroslavpejic85/call-me.git
cd call-me
cp public/config.template.js public/config.js
cp .env.template .env
cp docker-compose.template.yml docker-compose.yml
# Edit .env for your domain + password settings
docker compose pull
docker compose up -d
```

Generated `docker-compose.yml` (from template):

```yaml
services:
  callme:
    image: mirotalk/cme:latest
    container_name: callme
    hostname: callme
    restart: unless-stopped
    ports:
      - "${PORT}:${PORT}"
    volumes:
      - .env:/src/.env:ro
      - ./app/:/src/app/:ro
      - ./public/:/src/public/:ro
```

The `.env` file is bind-mounted read-only into the container — edit `.env` on the host, then `docker compose restart callme` to apply.

Key `.env` settings:

```env
NODE_ENV=production

# Server
HOST=https://call.example.com
PORT=8000

# Host protection (optional)
HOST_PASSWORD_ENABLED=false
HOST_PASSWORD=changeme

# CORS
CORS_ORIGIN=*
CORS_METHODS=["GET", "POST"]

# Logging
LOGS_DEBUG=false
LOGS_JSON=false
```

## First boot

1. Visit `http://localhost:8000` (or your domain after setting up a reverse proxy / using the install script).
2. Enter a username and click **Join** to enter the shared room.
3. Other participants join the same room; click the call button next to any username to initiate a call.
4. No accounts, no database — the room is ephemeral per session.

## Click-to-call URL API

Pre-fill the username and auto-call a recipient via URL parameters:

```
# User1 joins
https://call.example.com/join?user=user1

# User2 joins and immediately calls user1
https://call.example.com/join?user=user2&call=user1
```

Useful for embedding a call button in a website (see `integration/widget.html` in the repo).

## REST API

Retrieve connected users or initiate calls programmatically:

```bash
# List connected users
curl https://call.example.com/api/users

# Initiate call (see docs for full endpoint list)
curl -X POST https://call.example.com/api/call ...
```

## Upgrade

```bash
cd call-me
docker compose pull
docker compose up -d
```

Or use the update script if installed via the one-liner: `./cme-update.sh`.

## Gotchas

- **No persistent user database.** Call-me is sessionless — usernames are ephemeral per connection. There is no account system.
- **TURN server required for restrictive NAT.** Public STUN (Google) works for most home/office setups; symmetric NAT (common on carrier-grade NAT or corporate firewalls) requires a TURN server (e.g. coturn). Without TURN, calls fail silently for these users.
- **`config.js` customises the UI.** Copy `public/config.template.js` to `public/config.js` and edit it to change branding, room name, feature flags, etc. The file is bind-mounted into the container.
- **Port must match in `.env` and `docker-compose.yml`.** The container exposes `${PORT}:${PORT}` — both sides of the mapping use the same value from `.env`.
- **CORS in production.** Change `CORS_ORIGIN=*` to your actual domain in production to prevent cross-origin abuse.
- **Host password protects room joining.** With `HOST_PASSWORD_ENABLED=true`, anyone joining must enter the password — useful to prevent uninvited guests in the shared room.
