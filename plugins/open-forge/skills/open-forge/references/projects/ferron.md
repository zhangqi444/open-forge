---
name: Ferron
description: "Fast, memory-safe modern web server in Rust. Automatic TLS via Let's Encrypt. Modular architecture. Load-balancing reverse-proxy + health checks. ferronweb org. Matrix chat. Docker Hub."
---

# Ferron

Ferron is **"Caddy-competitor in Rust — automatic TLS + memory-safe + high-performance + modular reverse-proxy"** — a fast, modern, easily configurable web server with automatic TLS. Written in **Rust** (memory safety). Advanced reverse-proxy with load-balancing + health checks. Modular extensibility.

Built + maintained by **ferronweb** org. Website: ferron.sh. Matrix chat. X/Twitter. Docker Hub. Active.

Use cases: (a) **Caddy-alternative in Rust** (b) **static-site server with auto-TLS** (c) **high-performance reverse proxy** (d) **memory-safe edge-server** (e) **modular extensible server** (f) **Rust-preferring ops teams** (g) **simple config with sensible defaults** (h) **reverse-proxy with load-balancing + health**.

Features (per README):

- **High performance** + high-concurrency
- **Memory-safe** (Rust)
- **Automatic TLS** (Let's Encrypt)
- **Simple configuration** with sensible defaults
- **Modular extensibility**
- **Reverse proxy** with load-balancing + health checks

- Upstream repo: <https://github.com/ferronweb/ferron>
- Website: <https://ferron.sh>
- Docs: <https://ferron.sh/docs>
- Matrix: <https://matrix.to/#/#ferronweb:matrix.org>
- Docker Hub: <https://hub.docker.com/r/ferronserver/ferron>

## Architecture in one minute

- **Rust** single binary
- **Let's Encrypt** integrated
- **Resource**: low — Rust-typical
- **Port**: 80 + 443

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | Pre-built binaries                                              | **Primary**                                                                        |
| **Docker**         | `ferronserver/ferron`                                                                                                  | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | Multiple supported                                          | URL          | DNS-pointed                                                                                    |
| Ports                | 80, 443                                                     | Network      | Exposed for ACME                                                                                    |
| Backend servers      | For reverse proxy                                           | Config       |                                                                                    |
| Static root          | Or reverse-proxy-only                                       | Config       |                                                                                    |

## Install (binary)

See <https://ferron.sh/docs>. Typical:
```sh
# Download from releases
curl -L https://github.com/ferronweb/ferron/releases/latest/download/ferron-linux-x86_64 -o ferron
chmod +x ferron
# Configure ferron.toml / ferron.yaml / whatever format
./ferron run
```

## Install (Docker)

```yaml
services:
  ferron:
    image: ferronserver/ferron:latest        # **pin version**
    ports: ["80:80", "443:443"]
    volumes:
      - ./ferron-config:/etc/ferron
      - ./ferron-data:/var/lib/ferron        # for LE certs
    restart: unless-stopped
```

## First boot

1. Write config pointing at your upstream/backend
2. Start
3. ACME issues certs automatically
4. Test HTTPS
5. Add more sites / upstreams
6. Configure health checks on upstreams

## Data & config layout

- `/etc/ferron/` — config
- `/var/lib/ferron/` — ACME certs + state

## Backup

```sh
sudo tar czf ferron-$(date +%F).tgz ferron-config/ ferron-data/
# Contains ACME private keys — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/ferronweb/ferron/releases>
2. Binary replacement or Docker pull
3. Config format stability depends on pre-1.0 status

## Gotchas

- **156th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — EDGE-PROXY CREDS**:
  - Let's Encrypt private keys for ALL domains
  - Backend server credentials (if basic-auth etc.)
  - **156th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Reverse-proxy-edge-credential-hub: 2 tools** (NPMplus+Ferron) 🎯 **2-TOOL MILESTONE**
- **RUST-MEMORY-SAFETY POSITIVE-SIGNAL**:
  - Rust-built reduces memory-bug CVE class
  - **Rust-built-high-throughput-tool: 4 tools** (+Ferron) 🎯 **4-TOOL MILESTONE**
- **AUTOMATIC-TLS-BUILT-IN**:
  - No separate reverse proxy + certbot
  - **Automatic-TLS-built-in: 3 tools** (Caddy-ref+Vince+Ferron) 🎯 **3-TOOL MILESTONE**
- **MODULAR-EXTENSIBILITY**:
  - Plugins/modules expected
  - **Recipe convention: "modular-extension-architecture positive-signal"**
  - **NEW positive-signal convention** (Ferron 1st formally)
- **HEALTH-CHECK-BUILT-IN**:
  - Upstream health-checks in LB
  - **Recipe convention: "built-in-upstream-health-checks positive-signal"**
  - **NEW positive-signal convention** (Ferron 1st formally)
- **MATRIX-CHAT-COMMUNITY**:
  - matrix.to/#/#ferronweb:matrix.org
  - Decentralized chat community
  - **Matrix-chat-community: 1 tool** 🎯 **NEW FAMILY** (Ferron; decentralized-alternative to Discord/Gitter)
- **PRE-1.0-RISK**:
  - Likely still pre-1.0
  - Config format may change
  - **Recipe convention: "pre-1.0-operational-discipline"** — reinforces Stump (115)
- **SENSIBLE-SECURE-DEFAULTS**:
  - Explicit "sensible, secure defaults"
  - **Recipe convention: "secure-defaults-declared positive-signal"**
  - **NEW positive-signal convention** (Ferron 1st formally)
- **MULTI-CHANNEL-PRESENCE (Matrix + Twitter/X)**:
  - Decentralized-Matrix + centralized-X
  - Broad reach
- **INSTITUTIONAL-STEWARDSHIP**: ferronweb org + website + docs + Matrix + X + Docker Hub + Rust-safety. **142nd tool — modern-Rust-infra-tool-org sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + website + docs + Matrix + Docker + releases + X. **148th tool in transparent-maintenance family.**
- **WEB-SERVER-CATEGORY:**
  - **Ferron** — Rust; auto-TLS; memory-safe; modular
  - **Caddy** — Go; auto-TLS; dominant in the niche
  - **Nginx** — C; mature; dominant overall
  - **Traefik** — Go; container-native
  - **HAProxy** — C; low-level; high-perf
  - **Apache httpd** — C; legacy
- **ALTERNATIVES WORTH KNOWING:**
  - **Caddy** — if you want Go + mature + Caddyfile
  - **Traefik** — if you want K8s/Docker-native
  - **nginx** — if you want battle-tested + large-community
  - **Choose Ferron if:** you want Rust + memory-safe + auto-TLS + modular.
- **PROJECT HEALTH**: active + modern + multi-community-channels. Strong for emerging Rust infra tool.

## Links

- Repo: <https://github.com/ferronweb/ferron>
- Website: <https://ferron.sh>
- Matrix: <https://matrix.to/#/#ferronweb:matrix.org>
- Caddy (alt): <https://github.com/caddyserver/caddy>
- Traefik (alt): <https://github.com/traefik/traefik>
