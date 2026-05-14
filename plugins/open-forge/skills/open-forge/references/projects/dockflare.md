---
name: DockFlare
description: "Automate Cloudflare Tunnels via Docker labels. Container-to-public-URL in seconds. Python. DNS + tunnel ingress + Cloudflare Access rules reconciled from labels + UI. ChrispyBacon-dev. GPL-3.0. Swiss-made. dockflare.app."
---

# DockFlare

DockFlare is **"Traefik-like ingress controller — but for Cloudflare Tunnels, driven by Docker labels"** — a self-hosted ingress + access-control plane for Cloudflare Tunnel. **Continuously reconciles** Docker labels + UI rules into Cloudflare DNS, tunnel ingress, and Access applications. Removes dashboard-click-work.

Built + maintained by **ChrispyBacon-dev**. GPL-3.0. Swiss-made. v3.1.2 as of README. Python. Docker Hub (`alplat/dockflare`). GitHub Sponsors.

Use cases: (a) **expose homelab containers** via CF Tunnel without port-forwarding (b) **label-driven ingress** — add label, get URL (c) **Access-rules-as-code** via labels (d) **fast-changing dev environments** (e) **no-dashboard-clicks ops** (f) **multi-container reverse-proxy to Cloudflare** (g) **remote-agent architecture** (h) **Zero-Trust-friendly homelab exposure**.

Features (per README):

- **Docker-label-driven** ingress
- **Cloudflare Tunnel** automation
- **DNS record** management
- **Cloudflare Access** rules
- **Web UI** for manual rules
- **Optional remote agents**
- **Reconcile-loop** (desired state)
- **Swiss-made**

- Upstream repo: <https://github.com/ChrispyBacon-dev/DockFlare>
- Website: <https://dockflare.app>
- Docs: <https://dockflare.app/docs>
- Sponsor: <https://github.com/sponsors/ChrispyBacon-dev>

## Architecture in one minute

- **Python** Flask likely
- **Cloudflare API** client
- **Docker socket** for label-reading
- **cloudflared** daemon (tunnel client)
- **Resource**: light
- Reconcile-loop pattern

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `alplat/dockflare`                                              | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Cloudflare API token | **Scoped** (Zone:Edit, DNS:Edit, Tunnels)                   | Secret       | Restrict to 1 zone                                                                                    |
| Account ID           | CF account                                                  | Config       |                                                                                    |
| Tunnel credentials   | `cert.pem` or token                                         | Secret       |                                                                                    |
| Docker socket        | Label-reading                                               | Mount        | **RO mount**                                                                                    |
| Domain               | Your CF-managed domain                                      | URL          |                                                                                    |

## Install via Docker

Per docs at <https://dockflare.app/docs>. Typical:
```yaml
services:
  dockflare:
    image: alplat/dockflare:v3.1.2        # **pin**
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./dockflare-data:/data
    environment:
      - CF_API_TOKEN=${CF_API_TOKEN}
      - CF_ACCOUNT_ID=${CF_ACCOUNT_ID}
      - CF_TUNNEL_TOKEN=${CF_TUNNEL_TOKEN}
      - CF_ZONE_ID=${CF_ZONE_ID}
    ports: ["5000:5000"]
    restart: unless-stopped
```

Label a container:
```yaml
services:
  myapp:
    image: myapp:latest
    labels:
      - "dockflare.subdomain=app"
      - "dockflare.service=http://myapp:3000"
```

## First boot

1. Create CF API token (scoped minimally)
2. Create Cloudflare Tunnel via dashboard; get cert
3. Set envs; deploy DockFlare
4. Label your first container
5. Watch DockFlare reconcile → DNS + tunnel + Access rule
6. Put DockFlare UI behind auth (or internal-only)
7. Back up `/data`

## Data & config layout

- `/data/` — state (reconciled rules, manual UI rules)

## Backup

```sh
sudo tar czf dockflare-$(date +%F).tgz dockflare-data/
# Plus record your CF API token + tunnel token securely
```

## Upgrade

1. Releases: <https://github.com/ChrispyBacon-dev/DockFlare/releases>
2. Read release notes — reconcile-behavior changes matter
3. Docker pull + restart

## Gotchas

- **161st HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — CLOUDFLARE-ACCOUNT-ADMIN**:
  - Holds: Cloudflare API token (Zone:Edit, DNS:Edit, Tunnels) — can **rewrite all DNS for zone**, redirect traffic
  - Docker socket (RO but privilege-adjacent — label-reading)
  - Tunnel token = tunnel-impersonation
  - **161st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "Cloudflare-tunnel-controller + DNS-ingress-automation"** (1st — DockFlare; critical-infra-tier)
  - **CROWN-JEWEL Tier 1: 55 tools / 50 sub-categories** 🎯 **50-SUB-CATEGORY CROWN-JEWEL MILESTONE at DockFlare**
- **CLOUDFLARE-API-TOKEN-SCOPE-DISCIPLINE**:
  - Token should be minimally scoped
  - Zone:Edit + DNS:Edit only for the specific zone
  - **Recipe convention: "Cloudflare-API-token-minimal-scope-discipline callout"**
  - **NEW recipe convention** (DockFlare 1st formally)
- **DNS-REWRITE-ATTACK-SURFACE**:
  - Compromise = redirect ALL subdomains to attacker
  - **Recipe convention: "DNS-rewrite-compromise-blast-radius callout"**
  - **NEW recipe convention** (DockFlare 1st formally)
- **CLOUDFLARE-LOCK-IN-RISK**:
  - Tight coupling to CF
  - Tunnel + Access + DNS = vendor-dependent
  - **Recipe convention: "platform-vendor-lock-in-neutral-signal callout"**
  - **NEW neutral-signal convention** (DockFlare 1st formally)
- **DOCKER-SOCKET-MOUNT (RO)**:
  - Read-only mount — less risky than RW
  - Still privilege-adjacent
  - **Docker-socket-mount-privilege-escalation: 8 tools** (+DockFlare, RO-variant) 🎯 **8-TOOL MILESTONE**
  - **Recipe convention: "docker-socket-RO-variant-safer-than-RW positive-signal"**
  - **NEW positive-signal convention** (DockFlare 1st formally)
- **RECONCILE-LOOP-PATTERN**:
  - K8s-style declarative reconciliation
  - **Recipe convention: "declarative-reconcile-loop-architecture positive-signal"**
  - **NEW positive-signal convention** (DockFlare 1st formally)
- **REMOTE-AGENT-ARCHITECTURE**:
  - Optional remote agents for multi-host
  - Agent tokens need careful management
  - **Recipe convention: "remote-agent-token-scope-discipline callout"**
  - **NEW recipe convention** (DockFlare 1st formally)
- **SWISS-MADE-BRANDING**:
  - Swiss-made badge
  - Playful + specific
  - **Recipe convention: "country-of-origin-branding neutral-signal"**
  - **NEW neutral-signal convention** (DockFlare 1st formally)
- **GITHUB-SPONSORS-FUNDING**:
  - GitHub Sponsors for sole-dev
  - **GitHub-Sponsors-funding: 1 tool** 🎯 **NEW FAMILY** (DockFlare; distinct from Ko-Fi + Patreon + Open-Collective)
- **VERSIONED-RELEASE-BADGE (v3.1.2)**:
  - Visible release-version in README badge
  - Stable release-labeling
  - **Recipe convention: "README-release-version-badge positive-signal"**
  - **NEW positive-signal convention** (DockFlare 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: ChrispyBacon-dev + website + docs + Sponsor + GPL-3.0 + active (v3.1.2) + label-discipline + Swiss-branding. **147th tool — sole-dev-with-full-product-site sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + versioned-releases + docs + website + Sponsor + Docker-Hub-published. **153rd tool in transparent-maintenance family.**
- **CF-TUNNEL-AUTOMATION-CATEGORY:**
  - **DockFlare** — label-driven; Python; full-ingress-plane
  - **Cloudflared** (official) — manual tunnel-config
  - **cloudflare-autoconfigure** (various)
  - **Traefik + cloudflared** — manual assembly
- **ALTERNATIVES WORTH KNOWING:**
  - **cloudflared** (official) — if you want manual + Cloudflare-supported
  - **Traefik direct + cloudflared** — if you want decoupled
  - **Choose DockFlare if:** you want label-driven + Swiss-made + full-automation.
- **PROJECT HEALTH**: active + v3.1.2 + docs + Sponsor + website. Strong for single-maintainer tool.

## Links

- Repo: <https://github.com/ChrispyBacon-dev/DockFlare>
- Website: <https://dockflare.app>
- Docs: <https://dockflare.app/docs>
- cloudflared (alt): <https://github.com/cloudflare/cloudflared>
- Traefik (alt): <https://github.com/traefik/traefik>
