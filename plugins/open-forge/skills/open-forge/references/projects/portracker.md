---
name: portracker
description: "Self-hosted real-time port monitoring and discovery tool. Auto-discovers services on hosts with Docker + TrueNAS specialized collectors. Peer-to-peer multi-server dashboard. Embedded SQLite. mostafa-wahied. MIT. Docker-socket access."
---

# portracker

portracker is **"a live map of every open port on every machine in your homelab — no more spreadsheets"** — a self-hosted real-time port-monitoring + discovery tool. Auto-discovers services + ports on each host. **Platform-specific collectors** for Docker + TrueNAS (gets rich contextual info). Internal vs published port distinction. **Peer-to-peer**: add other portracker instances as peers → one dashboard shows all servers/containers/VMs. Hierarchical parent-child grouping (nest VMs under physical hosts).

Built + maintained by **Mostafa Wahied (mostafa-wahied)**. License: check LICENSE. Active; Docker Hub; GH Releases; CI badge; screenshots-v1.3 (actively-versioned).

Use cases: (a) **kill port-conflict spreadsheets** (b) **network-map of homelab** (c) **TrueNAS VM discovery** (d) **auditing what's actually listening** (e) **pre-deploy port-conflict check** (f) **multi-server fleet-view** (g) **catch rogue services** (h) **docker-compose port-planning**.

Features (per README):

- **Automatic port discovery** — scans host
- **Platform-specific collectors**: Docker + TrueNAS
- **Internal vs published port** distinction
- **Embedded SQLite** — no external DB
- **Peer-to-peer multi-instance**
- **Hierarchical grouping**
- **TrueNAS API key** optional for enhanced discovery (VMs, OS version, uptime)
- **Modern responsive UI** — light/dark + list/grid/table views

- Upstream repo: <https://github.com/mostafa-wahied/portracker>
- Docker Hub: <https://hub.docker.com/r/mostafawahied/portracker>

## Architecture in one minute

- **Node.js or Go** single process
- **Embedded SQLite**
- **Docker socket access** — to discover containerized services
- **Resource**: low — ~100-200MB
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`mostafawahied/portracker`**                                  | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Docker socket        | Read-only                                                   | Integration  | **Privilege-escalation risk — see Docker-Socket-Proxy 112**                                                                                    |
| TrueNAS API key      | Optional                                                    | Integration  | Read-only ideal                                                                                    |
| Peer portracker URLs | Optional                                                    | Topology     |                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |

## Install via Docker

```yaml
services:
  portracker:
    image: mostafawahied/portracker:latest        # **pin version**
    network_mode: host        # to see host listening-ports
    volumes:
      - ./portracker-data:/data
      - /var/run/docker.sock:/var/run/docker.sock:ro        # **:ro discipline**
    environment:
      TZ: UTC
    restart: unless-stopped
```

## First boot

1. Start
2. Browse to web UI
3. Set admin password
4. Verify host-ports + container-ports shown
5. If TrueNAS — add API key (read-only!)
6. Add peer servers
7. Create hierarchy grouping
8. Put behind TLS + auth reverse proxy

## Data & config layout

- `/data/` — SQLite DB with discovered-ports + peer configuration

## Backup

```sh
sudo tar czf portracker-$(date +%F).tgz portracker-data/
# Contains peer URLs + possibly TrueNAS keys — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/mostafa-wahied/portracker/releases>. Active (v1.3+).
2. Docker pull + restart

## Gotchas

- **137th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — INFRASTRUCTURE-DISCOVERY-MAP**:
  - Compromise = **map of your entire network** (what runs where)
  - Plus: Docker socket (host-root potential), TrueNAS API key, peer URLs (possibly creds)
  - Attacker's dream reconnaissance-tool
  - **137th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "infrastructure-discovery-map + host-reconnaissance-tool"** (1st — portracker; like Reitti's physical-security-data but for network/infra)
  - **CROWN-JEWEL Tier 1: 41 tools / 38 sub-categories**
- **DOCKER-SOCKET-MOUNT**:
  - Typical pattern; `:ro` reduces but doesn't eliminate risk
  - Consider Docker-Socket-Proxy (112)
  - **Docker-socket-mount-privilege-escalation: 6 tools** (+portracker) 🎯 **6-TOOL MILESTONE**
- **NETWORK-MODE=HOST REQUIRED**:
  - To see host's listening ports, must be on host network
  - Loss of network-isolation
  - **Recipe convention: "host-network-mode-port-visibility-tradeoff callout"**
  - **NEW recipe convention** (portracker 1st formally)
- **PEER-TO-PEER-SELF-DISCLOSURE**:
  - Each peer instance publishes its discovery; chain-of-trust issues
  - Compromise one node = reveals others + their discoveries
  - **Recipe convention: "peer-mesh-chain-of-trust callout"**
  - **NEW recipe convention** (portracker 1st formally)
- **TRUENAS-API-KEY-DISCIPLINE**:
  - Read-only scope preferred
  - **Recipe convention: "read-only-api-key-discipline" positive-signal** — reinforces general pattern
- **HIERARCHICAL-GROUPING**:
  - Parent-child nesting (VM under physical host)
  - **Recipe convention: "hierarchical-infra-topology-representation positive-signal"**
  - **NEW positive-signal convention** (portracker 1st formally)
- **SQLITE-EMBEDDED**:
  - **SQLite-single-file-backup-simplicity: 4 tools** (+portracker) 🎯 **4-TOOL MILESTONE**
- **ACTIVELY-VERSIONED SCREENSHOTS**:
  - Screenshot filenames include version (`v1.3`)
  - Signals screenshot-maintenance discipline
  - **Recipe convention: "versioned-screenshot-maintenance positive-signal"**
  - **NEW positive-signal convention** (portracker 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: mostafa-wahied sole + Docker Hub + releases + CI + screenshots-versioned + multi-platform collectors. **123rd tool — sole-maintainer-with-platform-collectors sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Docker Hub + releases + v1.3-cadence + screenshots. **129th tool in transparent-maintenance family.**
- **PORT/NETWORK-MONITORING-CATEGORY:**
  - **portracker** — homelab-focused; peer-to-peer
  - **Netdata** — metrics + alerts; broader
  - **uptime-kuma** — HTTP uptime (not port-discovery)
  - **nmap** (manual) — CLI scanner
- **ALTERNATIVES WORTH KNOWING:**
  - **nmap + manual tracking** — if CLI
  - **Netdata** — if you want broader-monitoring
  - **Choose portracker if:** you want auto-discovery + multi-server dashboard + homelab focus.
- **PROJECT HEALTH**: active + versioned-screenshots + CI + Docker-Hub + peer-mesh. Strong for niche.

## Links

- Repo: <https://github.com/mostafa-wahied/portracker>
- Docker Hub: <https://hub.docker.com/r/mostafawahied/portracker>
- Docker-Socket-Proxy (recommended companion): <https://github.com/Tecnativa/docker-socket-proxy>
