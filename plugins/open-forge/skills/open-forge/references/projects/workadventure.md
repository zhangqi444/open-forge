---
name: workadventure
description: WorkAdventure recipe for open-forge. Virtual office/conferencing platform as a 16-bit RPG map. Complex self-hosted deploy — requires Docker Compose + Livekit + Coturn. Upstream: https://github.com/workadventure/workadventure
---

# WorkAdventure

Virtual office and conferencing platform presented as a 16-bit RPG video game. Walk your avatar around custom maps, start spontaneous video chats when you approach colleagues, host events, onboarding, and meetings in an immersive 2D world.

5,420 stars · AGPLv3

Upstream: https://github.com/workadventure/workadventure
Website: https://workadventu.re/
Self-hosting docs: https://docs.workadventu.re/self-hosting/
Install guide: https://github.com/workadventure/workadventure/blob/develop/docs/others/self-hosting/install.md

## ⚠️ Self-hosting complexity warning

Self-hosting WorkAdventure is significantly more involved than a typical Docker Compose app. It requires:

- **3+ servers** with public IPs and DNS names (WorkAdventure + Livekit + Coturn)
- **Livekit** — Audio/video server for groups > 4 people
- **Coturn** — TURN server for NAT traversal (required for ~15% of users who can't do P2P)
- **Strong Docker/networking expertise**
- Monthly updates — the project releases frequently

The upstream team explicitly recommends the **SaaS version** (free tier available at https://workadventu.re) for most users. Self-host only if you have specific privacy/compliance requirements or technical capacity.

## What it is

WorkAdventure provides a complete virtual space platform:

- **Custom maps** — Build with Tiled Map Editor; design offices, conference halls, event spaces
- **Proximity video chat** — Approach another avatar to auto-start a WebRTC video call
- **Jitsi/Livekit rooms** — Large meeting rooms embedded in the map
- **Scriptable** — Scripting API for interactive objects, triggers, and integrations
- **Multi-tenant** — Multiple worlds/organizations on one server
- **OIDC authentication** — Integrate your SSO provider
- **Matrix/Synapse chat** (optional) — Persistent chat between users

## Architecture

| Service | Role | Required? |
|---|---|---|
| WorkAdventure | Main app (front + back + pusher) | Yes |
| Livekit | Audio/video for groups > 4 | Yes (recommended) |
| Coturn | TURN relay for NAT traversal | Yes (recommended) |
| OIDC provider | User authentication | Optional |
| Synapse/Matrix | Persistent chat | Optional |

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose | https://github.com/workadventure/workadventure/blob/develop/docs/others/self-hosting/install.md | Standard self-hosted production deploy |
| Helm/Kubernetes | Helm chart available | Large-scale K8s deploys |

## Requirements

- 3 servers minimum:
  1. WorkAdventure server (2+ CPU, 4 GB RAM)
  2. Livekit server (2+ CPU, 4 GB RAM) — must be on a different host
  3. Coturn server (1 CPU, 1 GB RAM)
- All servers need public IPv4 addresses and DNS names
- Ports: 80/443 (HTTP/HTTPS), 3478/5349 (TURN), 7881/7882 (Livekit)

## Docker Compose install

Full guide: https://github.com/workadventure/workadventure/blob/develop/docs/others/self-hosting/install.md

### 1. Clone the repository

    git clone https://github.com/workadventure/workadventure.git
    cd workadventure

### 2. Copy and configure environment

    cp .env.template .env

Edit `.env` — key variables:

    # Domains (replace with your actual domains)
    DOMAIN=workadventure.example.com
    LIVEKIT_URL=https://livekit.example.com
    COTURN_HOST=turn.example.com
    COTURN_PORT=3478
    COTURN_SECRET=<generate: openssl rand -hex 32>

    # Authentication
    SECRET_KEY=<generate: openssl rand -hex 32>
    SECRET_JITSI_KEY=<generate: openssl rand -hex 32>

    # Livekit credentials (set these after setting up Livekit)
    LIVEKIT_API_KEY=<livekit api key>
    LIVEKIT_API_SECRET=<livekit api secret>

Full .env reference: https://github.com/workadventure/workadventure/blob/develop/.env.template

### 3. Set up Coturn (on dedicated server)

    apt install -y coturn

Edit `/etc/turnserver.conf`:

    listening-port=3478
    tls-listening-port=5349
    fingerprint
    lt-cred-mech
    use-auth-secret
    static-auth-secret=<COTURN_SECRET>
    realm=turn.example.com
    total-quota=100

    systemctl enable --now coturn

### 4. Set up Livekit (on dedicated server)

Follow Livekit's Docker deploy guide: https://docs.livekit.io/realtime/self-hosting/deployment/

Quick start:

    curl -sSL https://get.livekit.io | bash
    # Follow prompts to configure with your domain

### 5. Start WorkAdventure

    docker compose up -d

### 6. Configure TLS

Use Traefik (included in the Docker Compose) or configure Nginx/Caddy in front of the stack. Livekit and Coturn also need TLS certificates.

## Map creation

Create custom maps with Tiled Map Editor: https://www.mapeditor.org/

Upload maps via the WorkAdventure back-office admin panel.

Map building docs: https://docs.workadventu.re/map-building/

## Upgrade

The project releases approximately monthly. Before upgrading, check the changelog and migration notes:

    git pull origin develop
    docker compose pull
    docker compose up -d

## Gotchas

- **3+ servers required** — You cannot run Livekit and WorkAdventure on the same server (port conflicts). Coturn also works better isolated.
- **All servers need public IPs** — WorkAdventure, Livekit, and Coturn all need public-facing IPs for WebRTC to work.
- **Monthly updates** — The team releases frequently. Self-hosting means you're responsible for keeping up. Budget time for monthly updates.
- **TLS everywhere** — HTTPS is required for WebRTC camera/microphone. All three services (WorkAdventure, Livekit, Coturn TLS) need valid certificates.
- **COTURN_SECRET must match** — The secret in `.env` must exactly match the `static-auth-secret` in `turnserver.conf`.
- **AGPLv3** — Commercial use/modifications for public deployment require publishing source changes or a commercial license.
- **Consider SaaS first** — The hosted version has a free tier and handles all infrastructure. Self-host only if you have strong reasons.

## Links

- GitHub: https://github.com/workadventure/workadventure
- Website: https://workadventu.re/
- Self-hosting docs: https://docs.workadventu.re/self-hosting/
- Install guide: https://github.com/workadventure/workadventure/blob/develop/docs/others/self-hosting/install.md
- Map building: https://docs.workadventu.re/map-building/
- .env template: https://github.com/workadventure/workadventure/blob/develop/.env.template
