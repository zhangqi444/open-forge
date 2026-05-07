---
name: jami
description: Jami recipe for open-forge. Distributed, serverless communication platform — voice, video, messaging, and screen sharing with end-to-end encryption and no central server. GPL-3.0. Source: https://jami.net
---

# Jami

A free, distributed, and privacy-preserving communication platform. Provides voice calls, video calls, instant messaging, file sharing, and screen sharing with end-to-end encryption. Uses a distributed hash table (DHT) for peer discovery — no central server required for communication. Optional rendezvous/server nodes can improve connectivity. GPL-3.0 licensed. Source: <https://jami.net> / <https://git.jami.net/savoirfairelinux>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Native packages (APT/DNF) | Full client + optional headless daemon |
| Any Linux | Docker | `jamid` daemon with REST API |
| Android / iOS / macOS / Windows | Native app | Official apps from respective stores |
| Any Linux | Headless (`jamid` daemon) | For server-side bots or group rendezvous |

> Jami is primarily a **client application** — there is no "server to deploy" for basic use. The optional server-side components (rendezvous, TURN, STUN) improve connectivity but are not required.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Use case?" | client / rendezvous-server / bot-daemon | Personal client, group rendezvous node, or headless daemon |
| "Domain?" | FQDN | If hosting a rendezvous or management server |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Enable TURN?" | Yes / No | For NAT traversal; coturn recommended |
| "Enable STUN?" | Yes / No | For peer-to-peer connection establishment |
| "Admin REST API?" | Yes / No | `jami-restdaemon` exposes REST API for programmatic control |

## Software-Layer Concerns

- **Distributed by design**: Jami accounts are cryptographic key pairs stored locally — no account registration with a central server. Accounts are portable via export.
- **DHT network**: Uses OpenDHT for peer discovery — connects to the global Jami DHT or a private one.
- **`jamid` daemon**: The Jami daemon (`jamid`) is the core — clients (GUI or REST) connect to it via D-Bus (Linux) or a socket.
- **Rendezvous mode**: A Jami account can be set to rendezvous mode — others join it like a conference room. Useful for persistent group meeting rooms on a server.
- **NAT traversal**: Works over NAT via DHT + STUN/TURN, but a dedicated TURN server (coturn) significantly improves call reliability.
- **File paths**: Account data stored in `~/.local/share/jami/` (Linux). Back up this directory to preserve accounts and conversation history.
- **REST daemon**: `jami-restdaemon` (or `jami-daemon --rest`) exposes a REST API on localhost for building bots or headless integrations.

## Deployment

### Client install (Debian/Ubuntu)

```bash
# Add official Jami repo
curl -s https://dl.jami.net/public-key.gpg | gpg --dearmor | \
  tee /usr/share/keyrings/jami-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jami-archive-keyring.gpg] https://dl.jami.net/nightly/ubuntu_22.04/ jami main" | \
  tee /etc/apt/sources.list.d/jami.list
apt update && apt install jami
```

### Headless daemon (for rendezvous / bot server)

```bash
# Install daemon only
apt install jami-daemon

# Start the daemon
systemctl enable --now jami

# Control via command-line or REST API
# jami-cli (if available) or jami-restdaemon
```

### Docker (headless daemon with REST API)

```yaml
services:
  jami:
    image: registry.jami.net/infra/jami-daemon:latest
    container_name: jami-daemon
    restart: unless-stopped
    volumes:
      - jami-data:/root/.local/share/jami
    ports:
      - "8080:8080"   # REST API
    command: ["--rest", "--http-port", "8080"]

volumes:
  jami-data:
```

```bash
docker compose up -d
# Interact via REST API at http://localhost:8080
# API docs: https://git.jami.net/savoirfairelinux/jami-daemon/-/wikis/REST-API
```

### TURN server (coturn, for improved call quality)

```bash
apt install coturn
# Configure /etc/turnserver.conf
# Add TURN server details to Jami account settings
```

## Upgrade Procedure

```bash
# APT
apt update && apt upgrade jami jami-daemon

# Docker
docker compose pull && docker compose up -d
```

## Gotchas

- **No central server — no account recovery**: Jami accounts are local key pairs. If you lose the device and haven't exported your account, the account is gone forever. Export accounts and back up `~/.local/share/jami/`.
- **DHT connectivity**: In restrictive network environments (corporate firewalls), DHT peer discovery may be blocked — TURN/STUN or a bootstrap node may help.
- **Rendezvous node persistence**: A rendezvous server needs to run continuously and be reachable — if it goes offline, group conversations hosted on it become unavailable.
- **NAT traversal reliability**: Without a TURN server, calls between strict-NAT endpoints may fail. Deploy coturn for production use.
- **D-Bus dependency**: On Linux desktops, the GUI client communicates with `jamid` via D-Bus — headless/server deployments should use the REST API instead.
- **Account export before reinstall**: Before upgrading the OS or reinstalling, export your Jami account via the GUI or REST API — the account cannot be recovered otherwise.
- **Federation**: Jami is its own network — it does not federate with SIP, XMPP, or Matrix natively.

## Links

- Homepage: https://jami.net
- Source: https://git.jami.net/savoirfairelinux?sort=latest_activity_desc&filter=jami
- Downloads: https://jami.net/download/
- Documentation: https://git.jami.net/savoirfairelinux/jami-project/-/wikis/home
- REST API: https://git.jami.net/savoirfairelinux/jami-daemon/-/wikis/REST-API
