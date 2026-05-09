---
name: mirotalksfu
description: MiroTalk SFU recipe for open-forge. Self-hosted open-source WebRTC video conferencing platform using mediasoup SFU architecture. Alternative to Zoom/Google Meet. Docker-deployable. Upstream: https://github.com/miroslavpejic85/mirotalksfu
---

# MiroTalk SFU

Self-hosted, open-source WebRTC video conferencing platform built on [mediasoup](https://mediasoup.org) SFU (Selective Forwarding Unit) architecture. Supports video up to 8K @ 60fps, screen sharing, recording, chat, collaborative whiteboard, OIDC auth, REST API, and 133 languages. A modern alternative to Zoom, Google Meet, and Microsoft Teams. Upstream: <https://github.com/miroslavpejic85/mirotalksfu>. License: AGPLv3.

MiroTalk SFU ships as a Node.js application and Docker image (`mirotalk/sfu`). Configuration is split between `app/src/config.js` (defaults and documentation) and `.env` (secrets and environment overrides — never commit).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — template `docker-compose.template.yml` in-repo. |
| Any Linux host | Node.js direct | Requires Node 22.x, build-essential, Python 3.8+, ffmpeg. |
| Linux host | `network_mode: host` | Simplifies WebRTC NAT traversal; all ports on the host. |
| VPS / cloud VM | Docker Compose + reverse proxy | HTTPS termination via Nginx/Caddy; `SFU_ANNOUNCED_IP` must be set. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What is the public IP address or domain of the server?" | IP or hostname | Required for `SFU_ANNOUNCED_IP` — mediasoup must announce the reachable address to WebRTC clients. |
| preflight | "Use `network_mode: host` or explicit port mappings?" | `AskUserQuestion`: `host` / `explicit ports` | Host mode simplifies NAT; explicit ports (3010 TCP + 40000–40100 TCP/UDP) required if host mode unavailable. |
| tls | "Domain for HTTPS (if not using network_mode host)?" | hostname | Required for TLS termination via reverse proxy or built-in SSL. |
| auth (optional) | "Enable OIDC authentication?" | `AskUserQuestion`: `Yes` / `No` | Configured in `config.js` under OIDC block. |
| recording (optional) | "Enable recording?" | `AskUserQuestion`: `Yes` / `No` | Requires `RECORDING_ENABLED=true` in `.env` and mounting `./app/rec:/src/app/rec`. |
| ai (optional) | "OpenAI API key for ChatGPT integration?" | Secret string | Optional — configured in `config.js`. |

## Software-layer concerns

### Key environment variables (`.env`)

| Variable | Purpose | Notes |
|---|---|---|
| `NODE_ENV` | Runtime mode | `production` for deployed instances |
| `SFU_ANNOUNCED_IP` | Public IP/domain for WebRTC announcements | **Critical** — must be the external IP clients can reach |
| `SFU_LISTEN_IP` | Interface to bind | `0.0.0.0` for all interfaces |
| `SFU_MIN_PORT` / `SFU_MAX_PORT` | WebRTC port range | Default `40000`–`40100` (TCP + UDP) |
| `SERVER_HOST_URL` | Public server URL | E.g. `https://sfu.example.com` |
| `SERVER_LISTEN_PORT` | HTTP port | Default `3010` |
| `TRUST_PROXY` | Trust reverse proxy headers | `true` when behind Nginx/Caddy |

Full annotated template: <https://github.com/miroslavpejic85/mirotalksfu/blob/main/.env.template>

### docker-compose setup (from upstream template)

```yaml
services:
  mirotalksfu:
    image: mirotalk/sfu:latest
    container_name: mirotalksfu
    hostname: mirotalksfu
    restart: unless-stopped
    # network_mode: 'host'  # uncomment for host networking (simplifies NAT)
    ports:
      - '3010:3010/tcp'
      - '40000-40100:40000-40100/tcp'
      - '40000-40100:40000-40100/udp'
    volumes:
      - ./app/src/config.js:/src/app/src/config.js:ro
      - ./.env:/src/.env:ro
      # Uncomment if RECORDING_ENABLED=true:
      # - ./app/rec:/src/app/rec
```

Source: <https://github.com/miroslavpejic85/mirotalksfu/blob/main/docker-compose.template.yml>

### Quick start

```bash
git clone https://github.com/miroslavpejic85/mirotalksfu.git
cd mirotalksfu
cp app/src/config.template.js app/src/config.js
cp .env.template .env
cp docker-compose.template.yml docker-compose.yml
# Edit .env: set SFU_ANNOUNCED_IP, SERVER_HOST_URL, NODE_ENV=production, TRUST_PROXY=true
docker compose pull
docker compose up -d
```

Open `https://<your-domain>:3010` (or configure a reverse proxy for port 443).

### Direct Node.js install (Ubuntu 24.04)

```bash
apt-get update && apt-get install -y build-essential ffmpeg
# Install Python 3.8 (required for mediasoup native build)
add-apt-repository -y ppa:deadsnakes/ppa && apt update
apt install -y python3.8 python3-pip
# Install Node 22 via nvm or nodesource
npm install
npm start
```

### Firewall requirements

MiroTalk SFU requires the following ports to be open for WebRTC to work:

| Port | Protocol | Purpose |
|---|---|---|
| `3010` | TCP | Web UI and API |
| `40000–40100` | TCP + UDP | mediasoup WebRTC media ports |

If using `network_mode: host`, all ports are directly on the host interface.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

Review the [CHANGELOG](https://github.com/miroslavpejic85/mirotalksfu/blob/main/CHANGELOG.md) before upgrading — mediasoup version bumps sometimes require re-running `npm install` and rebuilding native modules.

## Gotchas

- **`SFU_ANNOUNCED_IP` is critical** — if this is not set to your server's publicly reachable IP (or domain), WebRTC clients will fail to connect for audio/video. This is the most common misconfiguration.
- **WebRTC port range must be open on both TCP and UDP** — most firewalls need explicit rules for `40000–40100/tcp` AND `40000–40100/udp`. Missing UDP will cause video to fail while signaling works.
- **`network_mode: host` vs explicit ports** — host mode is simpler for NAT traversal but requires that all ports are free on the host. Explicit port mapping works behind a reverse proxy but requires `TRUST_PROXY=true` and correct `SFU_ANNOUNCED_IP`.
- **config.js is the main config file, not .env** — `.env` is for secrets and environment-specific overrides only. All feature flags, room settings, OIDC config, etc. live in `config.js`. The file is self-documenting with inline comments.
- **HTTPS required for WebRTC in browsers** — modern browsers require a secure context (HTTPS) to access cameras and microphones. Use a reverse proxy with a valid TLS cert or configure `SERVER_SSL_CERT`/`SERVER_SSL_KEY` in `.env`.
- **Recording requires a volume mount** — if `RECORDING_ENABLED=true`, you must mount `./app/rec:/src/app/rec` or recordings will fail. The directory must be writable.
- **AGPLv3 license** — commercial use requires compliance with AGPLv3 (source disclosure for networked services) unless a commercial license is purchased from the maintainer.

## Upstream docs

- GitHub: <https://github.com/miroslavpejic85/mirotalksfu>
- Documentation: <https://docs.mirotalk.com/mirotalk-sfu/>
- Self-hosting guide: <https://docs.mirotalk.com/mirotalk-sfu/self-hosting/>
- Docker Hub: <https://hub.docker.com/r/mirotalk/sfu>
- Live demo: <https://sfu.mirotalk.com>
- .env template: <https://github.com/miroslavpejic85/mirotalksfu/blob/main/.env.template>
