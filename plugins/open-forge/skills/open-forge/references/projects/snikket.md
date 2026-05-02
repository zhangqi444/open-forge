---
name: snikket-project
description: Snikket recipe for open-forge. Self-hosted personal XMPP messaging service. End-to-end encryption, push notifications, file sharing, voice/video calls, invite-based onboarding, automatic TLS via Let's Encrypt, iOS/Android apps. 4-container stack (proxy, cert-manager, portal, server). Requires a real domain + ports 80/443/5222/5269. Upstream: https://github.com/snikket-im/snikket-server
---

# Snikket

A self-hosted personal messaging service built on XMPP. End-to-end encrypted messages, file sharing, voice/video calls, push notifications, and invite-based onboarding for friends/family. Comes with official iOS and Android apps. Automatic TLS certificate management via Let's Encrypt. Designed for small groups — invite people by generating invite links from the web portal.

Upstream: <https://github.com/snikket-im/snikket-server> | Website: <https://snikket.org> | Quickstart: <https://snikket.org/service/quickstart/>

4-container stack: proxy + cert-manager + web portal + XMPP server. All use `network_mode: host`. **Requires a real public domain name** and open ports 80, 443, 5222, 5269.

## Compatible combos

| Infra | Notes |
|---|---|
| Public VPS (AMD64) | Requires public IP + DNS; ports 80, 443, 5222, 5269 must be open |
| ARM (Raspberry Pi) | Build from source; `make` required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Your domain?" | e.g. `chat.example.com` — must have DNS A record pointing to server; used for TLS and XMPP federation |
| preflight | "Admin email?" | `SNIKKET_ADMIN_EMAIL` — for Let's Encrypt cert notifications |
| preflight | "Admin account?" | `SNIKKET_ADMIN_USER` — your XMPP username (e.g. `you@chat.example.com`) |

## Software-layer concerns

### Images

```
snikket/snikket-web-proxy:stable
snikket/snikket-cert-manager:stable
snikket/snikket-web-portal:stable
snikket/snikket-server:stable
```

Use `:stable` tag for production. Upstream uses `:dev` in source compose — **change to `:stable`** for deployment.

### Config file: `snikket.conf`

All configuration is in a single `snikket.conf` file (env-file format):

```ini
SNIKKET_DOMAIN=chat.example.com
SNIKKET_ADMIN_EMAIL=admin@example.com
```

Copy `snikket.conf.example` from the repo and fill in these values.

### Compose

```yaml
version: "3.3"

services:
  snikket_proxy:
    container_name: snikket-proxy
    image: snikket/snikket-web-proxy:stable
    env_file: snikket.conf
    network_mode: host
    volumes:
      - snikket_data:/snikket
      - acme_challenges:/var/www/html/.well-known/acme-challenge
    restart: unless-stopped

  snikket_certs:
    container_name: snikket-certs
    image: snikket/snikket-cert-manager:stable
    network_mode: host
    env_file: snikket.conf
    volumes:
      - snikket_data:/snikket
      - acme_challenges:/var/www/.well-known/acme-challenge
    restart: unless-stopped

  snikket_portal:
    container_name: snikket-portal
    image: snikket/snikket-web-portal:stable
    network_mode: host
    env_file: snikket.conf
    restart: unless-stopped

  snikket_server:
    container_name: snikket
    image: snikket/snikket-server:stable
    network_mode: host
    volumes:
      - snikket_data:/snikket
    env_file: snikket.conf
    restart: unless-stopped

volumes:
  acme_challenges:
  snikket_data:
```

> Source: upstream docker-compose.yml — <https://github.com/snikket-im/snikket-server>

### Required ports

| Port | Protocol | Purpose |
|---|---|---|
| 80 | TCP | HTTP (ACME challenge for Let's Encrypt) |
| 443 | TCP | HTTPS (web portal) |
| 5222 | TCP | XMPP client connections |
| 5269 | TCP | XMPP server-to-server federation |
| 5000 | TCP | XMPP file transfer proxy (optional) |
| 3478, 5349 | TCP/UDP | TURN server for voice/video (optional) |

All containers use `network_mode: host` — they bind directly to the host's network interfaces.

### Key config variables (`snikket.conf`)

| Variable | Required | Purpose |
|---|---|---|
| `SNIKKET_DOMAIN` | ✅ | Your domain name (e.g. `chat.example.com`) |
| `SNIKKET_ADMIN_EMAIL` | ✅ | Email for Let's Encrypt cert notifications |

### First-run: create admin account

After `docker compose up -d`:

```bash
docker exec snikket create-account you@chat.example.com --admin
```

Then log into the web portal at `https://chat.example.com` to create invite links for others.

### Adding users

Generate invite links from the portal or via CLI:

```bash
docker exec snikket create-invite
```

Share the invite link — new users install the Snikket app and tap the link to join.

### Mobile apps

- Android: [Google Play](https://play.google.com/store/apps/details?id=org.snikket.android) / [F-Droid](https://f-droid.org/packages/org.snikket.android/)
- iOS: [App Store](https://apps.apple.com/app/snikket/id1545164189)

### Building from source (ARM / custom)

```bash
git clone https://github.com/snikket-im/snikket-server.git
cd snikket-server
make
```

Requires GNU make, Docker, and Ansible.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in the `snikket_data` named volume.

## Gotchas

- **Real public domain required** — Let's Encrypt needs to reach your server on port 80 to issue a certificate. Snikket will not work on a LAN-only or private IP setup without significant customization.
- **`network_mode: host`** — all 4 containers bind directly to the host network. This means no port mapping and no conflicts with other services on the same ports (80, 443, 5222, 5269). If you're running other web services on the same host, you'll need to route via a different approach.
- **Use `:stable` not `:dev`** — the upstream compose uses `:dev` image tags (for development). Use `:stable` for production deployments.
- **DNS must be set before first run** — Let's Encrypt cert issuance happens on startup. If DNS isn't pointing to your server, cert issuance fails and the proxy won't start cleanly.
- **Firewall** — ensure ports 5222 and 5269 are open in your host firewall AND any cloud security group. Many VPS providers block non-standard ports by default.
- **XMPP federation (port 5269)** — open this if you want to exchange messages with users on other XMPP servers (Matrix bridge, other Snikket instances, etc.).

## Links

- Upstream README: <https://github.com/snikket-im/snikket-server>
- Installation quickstart: <https://snikket.org/service/quickstart/>
- Snikket website: <https://snikket.org>
