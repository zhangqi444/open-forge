---
name: GoDoxy
description: "Lightweight Go reverse proxy with WebUI, automatic Docker discovery, ACL (IP/country via Maxmind), idlesleeper, metrics + logs, Proxmox integration. Alternative to Traefik/Caddy for Docker-native setups. License: check repo. Active."
---

# GoDoxy

GoDoxy is **"Traefik / nginx-proxy / Caddy-Docker-Proxy — Go + WebUI-focused + Docker-native"** — automatically creates reverse-proxy routes from Docker container labels OR from a WebUI. Low resource footprint. Built-in ACL (IP/CIDR + country via Maxmind). "idlesleeper" feature puts rarely-accessed containers to sleep + wakes them on request (saves RAM). Proxmox integration for LXC/VM-based setups. WebUI makes it more accessible than pure-YAML/labels tools.

Built + maintained by **yusing** + community + Discord. License: check repo (LICENSE file). Active; demo at demo.godoxy.dev; docs at docs.godoxy.dev; SonarCloud quality-gated; ChatGPT-assistant integration for users; English + Traditional-Chinese (繁中) docs.

Use cases: (a) **homelab reverse proxy** — automatic subdomain-per-container from labels (b) **Traefik-alternative** for users who dislike Traefik's complexity (c) **WebUI-driven** — configure via web, not YAML editing (d) **Docker-native** — tight integration with Docker socket for discovery (e) **idlesleeper for resource-constrained homelab** — saves RAM by sleeping idle containers (f) **Proxmox LXC/VM sites** — integrates with Proxmox (g) **geo-blocked services** — Maxmind country-based ACL (h) **multi-node setups** — GoDoxy supports multi-node agent-based architecture.

Features (per README):

- **Simple label-based config** OR WebUI OR Route Files
- **Multi-node setup** (agents)
- **ACL**: IP/CIDR + Country (Maxmind account required)
- **idlesleeper** — sleep idle containers, wake on request
- **Metrics + logs**
- **Proxmox integration** — LXC/VM discovery + route binding
- **Docker-native** — auto-discover via labels
- **Detailed error messages**

- Upstream repo: <https://github.com/yusing/godoxy>
- Docs: <https://docs.godoxy.dev>
- Wiki: <https://docs.godoxy.dev/Home.html>
- Demo: <https://demo.godoxy.dev>
- Discord: <https://discord.gg/umReR62nRd>

## Architecture in one minute

- **Go** — single binary
- **Docker socket** — for container discovery + label reading
- **Resource**: low — 50-150MB RAM
- **Ports**: 80/443 HTTP/HTTPS + WebUI
- **TLS**: Let's Encrypt + custom cert support

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream Docker image**                                       | **Primary**                                                                        |
| Kubernetes         | Possible but less-native                                        | DIY                                                                                   |
| Bare-metal Go      | Build + run                                                                     | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain(s)            | `*.example.com` wildcard + specifics                        | URL          | Wildcard cert recommended                                                                                    |
| Docker socket mount  | `/var/run/docker.sock`                                      | **CRITICAL** | **host-root-equivalent access** (Gladys 100 convention)                                                                                    |
| ACME email           | Let's Encrypt contact                                       | TLS          |                                                                                    |
| Maxmind account      | (optional) for country ACL                                  | ACL          | Free tier OK                                                                                    |
| Admin creds          | WebUI first-boot                                                                                 | Bootstrap    | Strong                                                                                    |
| Proxmox creds        | (optional) for PVE integration                                                                                                                  | Integration  | If using LXC/VM discovery                                                                                                                            |

## Install via Docker

```yaml
services:
  godoxy:
    image: yusing/godoxy:latest        # **pin version in prod**
    ports:
      - "80:80"
      - "443:443"
      - "8888:8888"      # WebUI
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro   # **host-root risk — read-only mount**
      - ./godoxy-config:/app/config
      - ./godoxy-certs:/app/certs
    restart: unless-stopped
```

Attach target services on the same Docker network with labels like:

```yaml
services:
  myapp:
    # ...
    labels:
      - "proxy.aliases=myapp.example.com"
```

## First boot

1. Start → browse WebUI (port 8888)
2. Configure ACME + domain settings
3. Label a test container; verify GoDoxy creates route
4. Test HTTPS + Let's Encrypt cert issuance
5. Configure ACL (IP allowlist for admin UI)
6. (Optional) Set up Maxmind for country-ACL
7. (Optional) Configure Proxmox integration
8. Back up config + certs

## Data & config layout

- `/app/config/` — route definitions + settings
- `/app/certs/` — TLS cert cache
- Docker socket read-only mount — auto-discovery

## Backup

```sh
sudo tar czf godoxy-$(date +%F).tgz godoxy-config/ godoxy-certs/
```

## Upgrade

1. Releases: <https://github.com/yusing/godoxy/releases>. Active.
2. Docker: pull + restart; config compatible across minor versions.
3. Reverse proxy is infrastructure-critical — test in staging + have rollback plan.

## Gotchas

- **DOCKER SOCKET MOUNT = HOST-ROOT EQUIVALENT** (Gladys 100 convention):
  - GoDoxy mounts `/var/run/docker.sock` to discover containers
  - **READ-ONLY mount** (`:ro`) limits damage but doesn't eliminate: reading can enumerate all containers, images, secrets
  - **Read-write mount** = full host-root via container-creation
  - **Recipe convention reinforced**: "docker-socket-mount-privilege-escalation" family (Gladys 100 1st) — **GoDoxy 2nd tool named**
  - **Family now 2 tools** — solidifying
  - Mitigation: read-only mount + separate networks for sensitive services + container-hardening
- **REVERSE PROXY = NETWORK EDGE + HIGH VALUE**:
  - Handles ALL inbound traffic to hosted services
  - Compromise = attacker becomes MITM for every service behind GoDoxy
  - TLS private keys stored on GoDoxy host
  - **66th tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (14th tool)** — reverse-proxy-at-edge category
  - **CROWN-JEWEL Tier 1 now 14 TOOLS**: ... **GoDoxy 14th — NEW sub-category: "reverse-proxy-at-edge"**
  - Note: Traefik/Caddy/nginx would ALSO be in this sub-category if they were self-host-catalog tools
- **ACL = DEFENSE-IN-DEPTH**:
  - IP/CIDR allowlist for admin UI
  - Country-ACL (Maxmind) for reducing attack-surface (e.g., block non-US for US-focused services)
  - Geo-ACL is NOT security-proof (VPNs, Tor bypass) but reduces automated-scanner traffic
- **MAXMIND ACCOUNT REQUIREMENT**:
  - Free Maxmind GeoLite2 DB available
  - Requires signing up for Maxmind account + license key
  - DB updates weekly; stale DBs = false negatives
  - **Recipe convention: "external-db-dependency" callout** — reliance on external data for operation
- **IDLESLEEPER = INTERESTING TRADE-OFF**:
  - Containers sleep when idle; wake on request
  - **Pro**: saves RAM in resource-constrained setups
  - **Con**: first-request after sleep = cold-start latency (2-10+ seconds)
  - Good for: personal tools you access infrequently
  - Bad for: user-facing services where latency matters
  - **Recipe convention: "cold-start-as-feature"** — specific use-case trade-off
- **WEBUI = NEEDS PROTECTION**:
  - WebUI exposes: all routes, cert status, metrics, logs
  - Must be behind auth (admin password) + ideally IP-allowlist
  - Don't expose WebUI publicly by default
- **PROXMOX INTEGRATION = API ACCESS**:
  - GoDoxy-to-Proxmox requires Proxmox API credentials
  - Credentials have LXC/VM read + potentially write access
  - **Recipe convention: "external-hypervisor-API-token" callout** — Proxmox/vSphere/Xen integration requires API tokens = additional credential-surface
  - **NEW recipe convention**
- **MULTI-NODE AGENT ARCHITECTURE**:
  - Central GoDoxy + agents on other nodes
  - Agent-to-central communication must be encrypted + authenticated
  - Compromise of any agent = potential pivot to central
- **REVERSE-PROXY CATEGORY (crowded):**
  - **Traefik** — most-popular in Docker; label-driven; complex config
  - **Caddy** — minimal config; auto-HTTPS built-in
  - **Caddy-Docker-Proxy** — Caddy + labels
  - **nginx-proxy (jwilder)** — classic; label-driven
  - **SWAG / NGINX Proxy Manager** — nginx + UI
  - **HAProxy** — not-Docker-native; performance-first
  - **Zoraxy** — Go + UI; similar to GoDoxy; different scope
  - **Pangolin** — newer; tunnel-focused
  - **GoDoxy** — Go + UI + Docker-native + idlesleeper
- **TLS-CERT-SENSITIVITY**:
  - Let's Encrypt private keys live on GoDoxy
  - Rotate + back up with encryption
  - **44th tool in immutability-of-secrets family** (TLS cert key continuity)
- **TRANSPARENT-MAINTENANCE**: active + SonarCloud quality-badge + demo + Discord + i18n + ChatGPT-assistant + Wiki. **59th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: yusing + Discord-community + Traditional-Chinese docs (notable — localization signal). **52nd tool — sole-maintainer-with-community sub-tier (26th).**
- **NOVEL SIGNAL: ChatGPT-assistant integration**:
  - README links to "GoDoxy Assistant" on ChatGPT
  - Uses ChatGPT custom-GPT to help users with config
  - **Recipe convention: "ChatGPT-assistant-for-user-support"** — novel support pattern
  - **NEW positive-signal convention** — 1st tool named (GoDoxy)
- **LICENSE CHECK**: verify LICENSE (convention).
- **ALTERNATIVES WORTH KNOWING:**
  - **Traefik** — if you want max-features + massive community
  - **Caddy** — if you want simple-config + auto-HTTPS
  - **NGINX Proxy Manager** — if you want classic-nginx + UI
  - **Zoraxy** — if you want similar-UI-focused + Go
  - **Pangolin** — if you want tunnel-focus
  - **Choose GoDoxy if:** you want Go + WebUI + idlesleeper + Docker-native.
  - **Choose Traefik if:** you want most-popular + label-driven.
  - **Choose Caddy if:** you want simplest config.
  - **Choose NPM if:** you want classic nginx + UI.
- **PROJECT HEALTH**: active + SonarCloud + Discord + i18n + demo + recent-commits + Proxmox-integration-unique. Strong signals.

## Links

- Repo: <https://github.com/yusing/godoxy>
- Docs: <https://docs.godoxy.dev>
- Wiki: <https://docs.godoxy.dev/Home.html>
- Demo: <https://demo.godoxy.dev>
- Discord: <https://discord.gg/umReR62nRd>
- Traefik (alt): <https://traefik.io>
- Caddy (alt): <https://caddyserver.com>
- Caddy-Docker-Proxy (alt): <https://github.com/lucaslorentz/caddy-docker-proxy>
- NGINX Proxy Manager (alt): <https://nginxproxymanager.com>
- Zoraxy (alt): <https://zoraxy.arozos.com>
- Pangolin (alt): <https://pangolin.fossorial.io>
- Maxmind GeoLite2: <https://dev.maxmind.com/geoip/geolite2-free-geolocation-data>
