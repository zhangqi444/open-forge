---
name: Docker Socket Proxy
description: "Security-enhanced HAProxy-based proxy for the Docker socket. Block dangerous endpoints via env vars. Tecnativa org. Alpine + HAProxy. Docker Hub + GHCR."
---

# Docker Socket Proxy (Tecnativa)

Docker Socket Proxy is **"reverse-proxy-with-ACL for the Docker socket — so your Traefik, Portainer, container-monitor can mount a proxy, not the raw socket"**. Solves the critical security problem: many services need to hook into Docker events (Traefik for dynamic routing, Portainer, Watchtower, container-monitors), but **the Docker socket = root on host, often = root on entire swarm**. This proxy acts as a firewall — you specify which API endpoints to allow (e.g., `CONTAINERS=1` but `POST=0`); everything else returns `HTTP 403`.

Built + maintained by **Tecnativa** (Spanish open-source tech consultancy; Odoo/ERP specialists). License: check LICENSE. Active; GHCR + Docker Hub; Alpine + HAProxy base.

Use cases: (a) **Traefik + Docker swarm** — Traefik needs event-stream; socket exposes too much (b) **Portainer** — UI access without raw socket (c) **Watchtower** — auto-update containers without full-root (d) **Prometheus cAdvisor** — metrics without admin-write (e) **Diun** (image-update notifier) — read-only container inventory (f) **homelab security-hardening** — reduce blast radius (g) **Kubernetes-transition** — enforce Docker-API discipline (h) **compliance** — PCI/SOC2 needs least-privilege.

Features (per README):

- **HAProxy-based** ACL proxy
- **Per-endpoint enable/disable** via env vars (CONTAINERS, EVENTS, IMAGES, NETWORKS, SERVICES, TASKS, POST, etc.)
- **Return HTTP 403** for blocked
- **Alpine base** (tiny; fewer CVEs)
- **Supports API version pinning**
- **Privileged container** required (SELinux/AppArmor reasons)

- Upstream repo: <https://github.com/Tecnativa/docker-socket-proxy>
- Docker Hub: <https://hub.docker.com/r/tecnativa/docker-socket-proxy>
- GHCR: <https://github.com/orgs/Tecnativa/packages/container/package/docker-socket-proxy>

## Architecture in one minute

- **HAProxy** (Alpine base)
- **Mounts** `/var/run/docker.sock` read from host
- **Exposes** TCP 2375 (HTTP-only; NO TLS — by design)
- **Resource**: tiny — <50MB RAM
- **Privileged**: YES (SELinux/AppArmor required)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`tecnativa/docker-socket-proxy`**                             | **Primary**                                                                        |
| **Docker Swarm**   | Global deploy                                                                                                          | Yes                                                                                   |
| **Kubernetes**     | Not quite fit (Kubernetes has its own RBAC model)                                                                     | Rare                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Consumer service     | Traefik / Portainer / Watchtower / etc.                     | Plan         | What needs Docker socket                                                                                    |
| Endpoints allowed    | CONTAINERS=1 / EVENTS=1 / POST=0 / etc.                     | **CRITICAL** | **Least-privilege by endpoint**                                                                                    |
| Docker network       | Isolated network between proxy + consumer                   | Network      | Must NOT expose publicly                                                                                    |
| Bind address         | 127.0.0.1:2375                                              | Network      | Never 0.0.0.0:2375                                                                                    |

## Install via Docker (example for Traefik)

```yaml
services:
  dockerproxy:
    image: tecnativa/docker-socket-proxy:0.2        # **pin version**
    environment:
      CONTAINERS: 1
      SERVICES: 1
      TASKS: 1
      NETWORKS: 1
      # Keep POST=0 (default) so nothing can create/destroy
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro        # **:ro is belt-and-suspenders**
    privileged: true
    restart: unless-stopped
    networks: [internal]

  traefik:
    image: traefik:v3
    command:
      - --providers.docker.endpoint=tcp://dockerproxy:2375
      - --providers.docker=true
    networks: [internal, public]
    # **Traefik no longer mounts docker.sock directly**

networks:
  internal:
    internal: true        # No egress — proxy ↔ Traefik only
  public:
```

## First boot

1. Decide endpoint policy per consumer (read ⮕ CONTAINERS, EVENTS, SERVICES; avoid POST unless truly needed)
2. Create isolated Docker network
3. Deploy proxy first
4. Reconfigure consumer to use `tcp://dockerproxy:2375` instead of `/var/run/docker.sock`
5. Remove `/var/run/docker.sock` mount from consumer
6. Test consumer functionality
7. If fails → loosen policy incrementally (don't just enable everything)

## Data & config layout

- Stateless — no persistent data

## Backup

No data to back up. Config is in compose file — version control it.

## Upgrade

1. Releases: <https://github.com/Tecnativa/docker-socket-proxy/releases>. Active.
2. Docker pull + restart
3. No DB migrations
4. Watch API-version pinning if host Docker upgrades

## Gotchas

- **113th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — DOCKER-API-GATEKEEPER**:
  - This proxy IS the least-privilege gatekeeper for Docker socket
  - BUT: if misconfigured (e.g., `POST=1`), grants container-creation = host-root
  - Also: privileged container itself = significant blast-radius if compromised
  - **113th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "Docker-API-proxy-gatekeeper"** (1st — Tecnativa socket-proxy)
  - **CROWN-JEWEL Tier 1: 31 tools / 28 sub-categories**
- **DOCKER-SOCKET = HOST-ROOT — KNOW WHAT YOU'RE DOING**:
  - POST endpoints (create containers, exec in containers, etc.) = host-root
  - This tool blocks them via env-vars, not filesystem permissions
  - **Recipe convention: "Docker-socket-is-host-root callout — universal"** — critical reminder
  - **NEW recipe convention** (Docker-Socket-Proxy 1st formally; applies to ALL tools that need Docker socket)
- **DOCKER-SOCKET-MOUNT-PRIVILEGE-ESCALATION FAMILY EXTENDED**:
  - **4 tools: Kite+Sablier+Traefik-in-compose+Docker-Socket-Proxy** (consumers) + **this is the mitigation**
  - Paradox: this container mounts the socket (PRIVILEGED), so other containers don't have to
  - **Docker-socket-mount-privilege-escalation: 4 tools** 🎯 **4-TOOL MILESTONE**
- **PRIVILEGED CONTAINER REQUIRED**:
  - `--privileged` flag needed (SELinux/AppArmor contexts)
  - **Recipe convention: "privileged-flag-required callout"** — important for ops-operators
- **NO TLS BY DESIGN**:
  - HTTP-only; rely on Docker network isolation
  - NEVER expose proxy port to public/host
  - `127.0.0.1:2375` or docker-network-only
  - **Recipe convention: "plain-HTTP-with-network-isolation-only positive-signal"** — when used correctly
  - **NEW positive-signal convention** (Docker-Socket-Proxy 1st formally)
- **RO MOUNT BELT-AND-SUSPENDERS**:
  - Even though proxy blocks POST via env, add `:ro` on the socket mount
  - Defense in depth
  - **Recipe convention: "belt-and-suspenders-socket-mount :ro" positive-signal**
  - **NEW positive-signal convention**
- **INTERNAL-NETWORK DISCIPLINE**:
  - Docker network with `internal: true` = no egress
  - Forces proxy to only talk to intended consumers
  - **Recipe convention: "Docker-internal-network-no-egress positive-signal"**
- **STATELESS-TOOL-RARITY**:
  - No DB, no persistent state — just HAProxy config + env
  - **Stateless-tool-rarity: 10 tools** (+Docker-Socket-Proxy) 🎯 **10-TOOL MILESTONE**
- **TECNATIVA ORG**:
  - Spanish open-source tech consultancy (Odoo/ERP specialists)
  - **Recipe convention: "commercial-consultancy-maintained-OSS-tool positive-signal"**
  - **NEW positive-signal convention** (Tecnativa 1st formally)
- **SECURITY-POSITIVE TOOL**:
  - Unlike many tools (which INCREASE attack surface), this tool DECREASES it
  - **Recipe convention: "security-hardening-tool positive-signal"** — rare tool category
  - **NEW positive-signal convention** (Docker-Socket-Proxy 1st formally)
- **API-VERSION PINNING**:
  - Docker API evolves; some versions have more/fewer endpoints
  - **Recipe convention: "Docker-API-version-pinning-discipline"** — standard
- **ALTERNATIVES / ADJACENT:**
  - **Run-as-non-root**: Traefik/Portainer/Watchtower alternatives that don't need socket
  - **Kubernetes** — uses API with RBAC instead of Docker socket
  - **DOAS** / **rootless Docker** — more fundamental mitigation
  - **Podman socket + Podman-API-proxy** — different ecosystem
- **INSTITUTIONAL-STEWARDSHIP**: Tecnativa org + active + GHCR + Docker Hub + image-template. **99th tool — commercial-consultancy-OSS-arm sub-tier** (NEW soft-tier — aligns with Zerodha Tech 111).
- **TRANSPARENT-MAINTENANCE**: active + GHCR + Docker Hub + template-versioned + enterprise-backer. **107th tool in transparent-maintenance family.**
- **PROJECT HEALTH**: active + stable-scope + enterprise-maintained + widely-adopted-in-homelab. EXCELLENT. Near-standard-practice tool.

## Links

- Repo: <https://github.com/Tecnativa/docker-socket-proxy>
- Docker Hub: <https://hub.docker.com/r/tecnativa/docker-socket-proxy>
- GHCR: <https://github.com/orgs/Tecnativa/packages/container/package/docker-socket-proxy>
- Rootless Docker (alt): <https://docs.docker.com/engine/security/rootless/>
- Tecnativa: <https://www.tecnativa.com>
