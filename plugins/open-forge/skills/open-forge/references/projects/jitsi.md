---
name: jitsi
description: Jitsi Meet recipe for open-forge. Free, open-source, self-hostable video conferencing. No account required. Docker Compose deployment with JVB, Jicofo, and Prosody.
---

# Jitsi Meet

Free, fully encrypted, open-source video conferencing. No account needed for participants. Self-host using Docker Compose with the official `docker-jitsi-meet` stack (JVB video bridge, Jicofo focus, Prosody XMPP). Supports amd64 and arm64. Upstream: <https://github.com/jitsi/docker-jitsi-meet>. Docs: <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (official, recommended) | Standard self-hosted deployment |
| Kubernetes (jitsi-contrib) | K8s; community-maintained |
| Debian/Ubuntu package | Bare-metal; official packages at packages.jitsi.org |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Public domain for Jitsi?" | Required; JVB uses it for STUN/TURN; must have DNS |
| preflight | "Admin password (Jicofo / JVB auth)?" | Set as `JICOFO_AUTH_PASSWORD` and `JVB_AUTH_PASSWORD` |
| preflight | "Enable TURN server?" | Needed for clients behind strict NAT; Jitsi includes coturn option |
| preflight | "HTTP port for web UI?" | Default 80/443 |

## Docker Compose setup

```bash
# Clone official repo
git clone https://github.com/jitsi/docker-jitsi-meet.git
cd docker-jitsi-meet

# Copy env template
cp env.example .env

# Edit .env — minimum required:
# PUBLIC_URL=https://meet.example.com
# JICOFO_AUTH_PASSWORD=<strong-password>
# JVB_AUTH_PASSWORD=<strong-password>
# JIBRI_RECORDER_PASSWORD=<strong-password>   # only if using recording
# JIBRI_XMPP_PASSWORD=<strong-password>        # only if using recording

# Generate secrets
./gen-passwords.sh

# Create required directories
mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jibri,jigasi}

# Start
docker compose up -d
```

Full quickstart: <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>

## Services in the stack

| Service | Role |
|---|---|
| `web` | Nginx + Jitsi Meet web app |
| `prosody` | XMPP server (signaling) |
| `jicofo` | Conference focus component |
| `jvb` | Jitsi Video Bridge (media routing) |

## Software-layer concerns

- Ports: `80`/`443` (web), `10000/udp` (JVB media — **must be open on firewall**)
- UDP port 10000 is critical — without it, video/audio won't work for most clients
- `PUBLIC_URL` must be set to your actual public HTTPS URL — JVB uses it to tell clients where to send media
- Docker images: `jitsi/web`, `jitsi/jicofo`, `jitsi/jvb`, `jitsi/prosody` (Docker Hub)
- Tags: use `stable` (e.g. `stable-9646`) for production; avoid `latest` which tracks unstable

## Upgrade procedure

1. `git pull` in docker-jitsi-meet directory
2. `docker compose pull`
3. `docker compose up -d`
4. Check `.env` for any new required variables in the updated `env.example`

## Gotchas

- **UDP 10000 must be open** — most failed deployments are caused by a firewall blocking this port
- `PUBLIC_URL` must use HTTPS with a valid cert — use Let's Encrypt via Caddy/NGINX in front
- `gen-passwords.sh` should be run once on first setup; re-running regenerates passwords and breaks existing tokens
- arm64 images available since stable-7439
- Jibri (recording/streaming) requires a separate VM with a real GPU/display — complex to set up

## Links

- GitHub: <https://github.com/jitsi/docker-jitsi-meet>
- DevOps Docker guide: <https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker>
- Handbook: <https://jitsi.github.io/handbook/>
- Docker Hub: <https://hub.docker.com/u/jitsi/>
