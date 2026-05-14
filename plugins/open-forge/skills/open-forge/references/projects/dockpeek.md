---
name: Dockpeek
description: "Lightweight self-hosted Docker dashboard. Quick access to containers, live logs, port mapping, image update checks, Traefik-label detection, multi-host. dockpeek/dockpeek. Buy Me a Coffee."
---

# Dockpeek

Dockpeek is **"Portainer but lighter + faster + Traefik-aware"** — a lightweight self-hosted Docker dashboard for quick access to containers. **One-click web access**, **automatic port mapping**, **live container logs**, **Traefik label auto-detection**, **multi-host** (control multiple Docker daemons from one UI), **image update checks**. Zero config.

Built + maintained by **dockpeek** org. Python+Flask likely. ghcr.io + Docker Hub. Buy Me a Coffee funded.

Use cases: (a) **homelab docker container dashboard** (b) **Traefik auto-discovery of service URLs** (c) **multi-Docker-host unified UI** (d) **quick-log viewer** (e) **image update tracking** (f) **Portainer-lite alternative** (g) **docker-compose-stack launcher** (h) **container web-app quicklinks**.

Features (per README):

- **One-click web access**
- **Automatic port mapping**
- **Live container logs**
- **Traefik integration** (auto-extract service URLs)
- **Multi-host management**
- **Image update checks**
- **Container labels support** (tag, customize, control)
- **Zero config** default

- Upstream repo: <https://github.com/dockpeek/dockpeek>
- Docker Hub: <https://hub.docker.com/r/dockpeek/dockpeek>
- Buy Me a Coffee: <https://buymeacoffee.com/dockpeek>

## Architecture in one minute

- Python/Flask likely
- Docker socket (mounted RO)
- Polls Docker API for containers + images
- **Resource**: low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | ghcr.io + Docker Hub                                                                                                   | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Docker socket        | `/var/run/docker.sock:ro`                                   | Volume       | **RO strongly recommended**                                                                                    |
| Multi-host URLs      | tcp://other-host:2375                                       | Config       | **Secure Docker-over-TCP**                                                                                    |
| Admin auth           | Password/SSO                                                | Auth         |                                                                                    |

## Install via Docker

Per README:
```yaml
services:
  dockpeek:
    image: dockpeek/dockpeek:latest
    container_name: dockpeek
    environment:
      - SECRET_KEY=your_secure_secret_key  # Required
      - USERNAME=admin
      - PASSWORD=changeme
    ports:
      - "3420:8000"   # host:container
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro        # **RO**
    restart: unless-stopped
```

## First boot

1. Deploy w/ docker socket RO-mounted
2. Open UI
3. Verify containers listed
4. Add Traefik labels to containers
5. Watch URLs auto-appear
6. (Optional) add additional Docker hosts (configure TLS)
7. Put behind TLS + auth
8. Enable image-update checks

## Data & config layout

- Stateless? — check upstream. Some config likely on disk

## Backup

```sh
sudo tar czf dockpeek-$(date +%F).tgz dockpeek-config/
# Contents: multi-host-creds (if any) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/dockpeek/dockpeek/releases>
2. Docker pull + restart

## Gotchas

- **186th HUB-OF-CREDENTIALS Tier 2 — DOCKER-SOCKET-DASHBOARD**:
  - Holds: Docker socket access (RO), multi-host credentials if configured
  - Traefik labels parsing = service-URL-disclosure
  - **186th tool in hub-of-credentials family — Tier 2**
- **DOCKER-SOCKET-MOUNT-PRIV-ESC**:
  - Even RO socket can leak secrets via container-inspect
  - RW socket = host-root
  - **Docker-socket-mount-privilege-escalation: 9 tools** 🎯 **9-TOOL MILESTONE** (+Dockpeek)
  - README promotes RO-mount (responsible)
- **RO-SOCKET-SAFER-THAN-RW**:
  - Reinforces DockFlare (121) RO-variant pattern
- **MULTI-HOST-DOCKER-OVER-TCP**:
  - Multi-host = Docker-over-TCP (authenticated TLS mandatory)
  - Unauthenticated 2375 = ROOT-ON-ALL-HOSTS
  - **Recipe convention: "Docker-over-TCP-mutual-TLS-mandatory callout"**
  - **NEW recipe convention** (Dockpeek 1st formally; HIGH-severity)
- **TRAEFIK-LABEL-PARSING**:
  - Auto-detection of labels
  - Service-URL disclosure if exposed
  - **Recipe convention: "Traefik-label-scraping-auto-discovery positive-signal"**
  - **NEW positive-signal convention** (Dockpeek 1st formally)
- **IMAGE-UPDATE-CHECKS**:
  - Similar to WUD / Diun
  - **Recipe convention: "image-update-check-functionality positive-signal"**
  - **NEW positive-signal convention** (Dockpeek 1st formally)
- **DOCKER-DASHBOARD-FAMILY**:
  - Now formally: Portainer + Dozzle + Yacht + Komodo + Homepage + Beszel + Dockpeek
  - **Docker-dashboard-tool family: 7 tools** 🎯 **7-TOOL MILESTONE at Dockpeek**
- **BUYMEACOFFEE-FUNDING**:
  - **BuyMeACoffee-funding: 2 tools** (Mail-Archiver+Dockpeek) 🎯 **2-TOOL MILESTONE**
- **ZERO-CONFIG-DEFAULT**:
  - Easy-deploy emphasis
  - **Recipe convention: "zero-config-default-easy-deploy positive-signal"**
  - **NEW positive-signal convention** (Dockpeek 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: dockpeek org + ghcr + Docker Hub + Buy Me a Coffee + active. **172nd tool — sole-dev-docker-dashboard sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + GHCR + Docker Hub. **178th tool in transparent-maintenance family.**
- **DOCKER-DASHBOARD-CATEGORY:**
  - **Dockpeek** — lightweight; Traefik-aware; multi-host
  - **Portainer** — mature; Business-edition parallel
  - **Dozzle** — logs-focused
  - **Yacht** — docker-compose-focused
  - **Komodo** — newer; multi-server
  - **Beszel** — metrics-focused
- **ALTERNATIVES WORTH KNOWING:**
  - **Portainer** — if you want mature + full-featured
  - **Dozzle** — if you just want logs
  - **Choose Dockpeek if:** you want lightweight + Traefik-aware + multi-host + zero-config.
- **PROJECT HEALTH**: active + docker-first + funding. Strong for niche.

## Links

- Repo: <https://github.com/dockpeek/dockpeek>
- Portainer (alt): <https://github.com/portainer/portainer>
- Dozzle (alt): <https://github.com/amir20/dozzle>
