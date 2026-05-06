---
name: jitsi-video-bridge
description: Jitsi Video Bridge recipe for open-forge. WebRTC-compatible Selective Forwarding Unit (SFU) for multiuser video — core component of Jitsi Meet stack. Debian/Ubuntu package or Docker. Upstream: https://github.com/jitsi/jitsi-videobridge
---

# Jitsi Video Bridge

WebRTC-compatible Selective Forwarding Unit (SFU) — the multimedia routing backbone of Jitsi Meet. Routes video streams between participants without transcoding, enabling scalable multiuser video conferencing.

3,073 stars · Apache-2.0

Upstream: https://github.com/jitsi/jitsi-videobridge
Website: https://jitsi.org
Docs: https://jitsi.github.io/handbook/
Handbook: https://jitsi.github.io/handbook/docs/devops-guide/

## What it is

Jitsi Video Bridge (JVB) is the media routing layer of the Jitsi stack:

- **SFU architecture** — Routes RTP streams without transcoding; each participant sends one stream, JVB forwards to others
- **WebRTC compatible** — Full WebRTC support (ICE, DTLS-SRTP, VP8/VP9/H.264, Opus)
- **Scalable** — Multiple JVB instances behind an Octo bridge for horizontal scaling
- **Simulcast** — Adaptive quality based on network conditions
- **Bandwidth estimation** — Dynamic bandwidth management per participant
- **Statistics** — REST API for real-time bridge statistics
- **Colibri** — XMPP-based control protocol for bridge configuration

JVB is typically deployed as part of the full Jitsi Meet stack, which includes:
- **jitsi-meet** — Web frontend (React)
- **jicofo** — Conference focus component (orchestrates bridges)
- **prosody** — XMPP server (signaling)
- **jitsi-videobridge** — This component (media routing)

For a complete self-hosted Jitsi Meet deployment, use the Jitsi Meet quick-install guide, not just JVB alone.

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | jitsi/jvb + full stack | Official jitsi/docker-jitsi-meet repo |
| Debian/Ubuntu | .deb package | Official Jitsi apt repo; recommended for production |
| Bare metal | Java + Maven | Build from source for development |

## Inputs to collect

### Phase 1 — Pre-install (full Jitsi stack via Docker)
- Domain name for Jitsi Meet (PUBLIC_URL)
- HTTPS certificate setup (Let's Encrypt or custom)
- Ports to open: 80, 443 (TCP), 10000 (UDP for media)
- JVB secret (shared between jicofo and JVB)
- XMPP credentials

### Phase 2 — JVB-specific config (/etc/jitsi/videobridge/jvb.conf)
- videobridge.ice.harvest.stun-mapping-harvester.addresses — STUN servers
- videobridge.apis.xmpp-client.configs — XMPP connection to prosody
- JVB_SECRET — shared secret for XMPP auth

## Software-layer concerns

### Full stack Docker Compose (recommended approach)
Use the official docker-jitsi-meet repository for a complete turnkey deploy:

  git clone https://github.com/jitsi/docker-jitsi-meet
  cd docker-jitsi-meet
  cp env.example .env
  # Edit .env: set PUBLIC_URL, generate secrets with ./gen-passwords.sh
  bash gen-passwords.sh
  mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
  docker compose up -d

Access at https://<PUBLIC_URL>

### Required open ports
- TCP 80/443 — Web interface and Let's Encrypt
- UDP 10000 — RTP media traffic (critical; must be reachable from internet)
- TCP 4443 — Fallback media (when UDP blocked)

### Config paths (bare metal Debian install)
- /etc/jitsi/videobridge/jvb.conf — main JVB config
- /etc/jitsi/videobridge/sip-communicator.properties — legacy config
- /etc/jitsi/videobridge/config — JVM flags (heap size, etc.)
- /etc/jitsi/jicofo/ — jicofo config
- /etc/prosody/conf.d/jitsi-meet.cfg.lua — prosody XMPP config

### JVM heap tuning (/etc/jitsi/videobridge/config)
  # Increase heap for large conferences (many participants)
  VIDEOBRIDGE_MAX_MEMORY=8192m

## Debian/Ubuntu install (bare metal, single-server)
  curl https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmor | tee /usr/share/keyrings/jitsi-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" > /etc/apt/sources.list.d/jitsi-stable.list
  apt update && apt install -y jitsi-meet
  # Follow the interactive installer (domain, TLS, etc.)

Full guide: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/

## Upgrade procedure

### Docker
  docker compose pull && docker compose up -d

### Debian
  apt update && apt upgrade jitsi-videobridge2 jicofo jitsi-meet-web

## Gotchas

- UDP 10000 is critical — most WebRTC media flows over UDP 10000; if blocked, calls fail or fall back to TCP with high latency; check cloud firewall/security groups
- Public IP mapping — JVB must know its public IP for ICE; in cloud/NAT environments set NAT_PUBLIC_IP in .env or configure STUN harvester
- JVB is one part — deploying JVB alone without jicofo/prosody/jitsi-meet is for advanced integrations; for a full video conferencing install use docker-jitsi-meet
- Memory scaling — each video participant adds ~1-3MB/s of forwarded media; plan CPU and bandwidth accordingly (not just RAM)
- Octo bridge — for conferences >100 participants, deploy multiple JVB instances using the Octo cascading feature
- HTTPS required — modern browsers enforce secure contexts for WebRTC; must use HTTPS
- Certificate renewal — if using Let's Encrypt, certbot must be set up for auto-renewal; Jitsi installer handles this on Debian

## Links

- Upstream README: https://github.com/jitsi/jitsi-videobridge/blob/master/README.md
- Jitsi Handbook: https://jitsi.github.io/handbook/
- Docker install guide: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker/
- Debian quick install: https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/
- docker-jitsi-meet repo: https://github.com/jitsi/docker-jitsi-meet
