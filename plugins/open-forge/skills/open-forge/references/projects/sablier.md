---
name: Sablier
description: "On-demand container starter + idle-shutdown. Integrates with reverse proxies (Traefik/Caddy/Nginx/Envoy/Apache APISIX/Istio) to intercept requests, wake sleeping workloads, show waiting page. Go. OpenSSF Scorecard badge. Sablier-app org. Active."
---

# Sablier

Sablier is **"Serverless-for-self-hosters — for any container workload"** — FOSS that starts container workloads **on demand** and stops them after a period of **inactivity**. Integrates with reverse proxies (Traefik / Caddy / Nginx / Envoy / Apache APISIX / Istio) to intercept incoming requests, wake sleeping workloads, and display a waiting page until they're ready. **Providers**: Docker / Docker Swarm / Podman / Kubernetes.

Built + maintained by **sablierapp** org + Discord + DigitalOcean sponsorship. License: check LICENSE. Active; Go Report Card; **OpenSSF Scorecard badge**; artwork repo; documented integration guides per-reverse-proxy.

Use cases: (a) **Raspberry Pi / low-resource host** — don't keep all containers running (b) **QA/staging environments** — used 1 hour/week; stop otherwise (c) **dev-local-previews** — wake container on first browser visit (d) **low-traffic apps** — e.g., infrequent dashboards (e) **cost-reduction on cloud VMs** — pause-to-zero workloads (f) **demo environments** — auto-stop after visitor leaves (g) **resource-bound Kubernetes namespaces** — shrink-when-idle (h) **multi-tenant dev platforms** — scale-to-zero inactive tenants.

Features (per README):

- **On-demand workload start** (wakes containers on request)
- **Idle-shutdown** (stops containers after inactivity)
- **Reverse-proxy integration**: Traefik, Caddy, Nginx, Envoy, Apache APISIX, Istio
- **Provider support**: Docker, Docker Swarm, Podman, Kubernetes
- **Waiting page** during cold-start
- **Go** single binary
- **Helm Chart** for Kubernetes
- **OpenSSF Scorecard** badge

- Upstream repo: <https://github.com/sablierapp/sablier>
- Discord: <https://discord.gg/WXYp59KeK9>
- OpenSSF Scorecard: <https://scorecard.dev/viewer/?uri=github.com/sablierapp/sablier>

## Architecture in one minute

- **Go** single binary
- **Connects to**: Docker socket OR Podman OR Kubernetes API
- **Reverse-proxy plugin** intercepts request → asks Sablier → Sablier starts → responds
- **Resource**: low — 50-100MB RAM
- **HTTP control API**

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |
| **Binary**         | **Multi-arch**                                                  | Bare-metal                                                                                   |
| **Helm Chart**     | **Kubernetes**                                                  | K8s                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Reverse proxy        | Traefik / Caddy / Nginx / Envoy / APISIX / Istio            | Infra        |                                                                                    |
| Container provider   | Docker / Podman / K8s                                       | Infra        |                                                                                    |
| Docker socket / K8s API access | Required                                          | **CRITICAL** | **DOCKER-SOCKET = host-compromise**                                                                                    |
| Workloads list       | Which containers to manage                                  | Config       |                                                                                    |
| Inactivity timeout   | e.g., 30 minutes                                            | Config       |                                                                                    |
| Waiting page         | Custom HTML/themes                                                                                                     | UX           |                                                                                    |

## Install via Docker

```yaml
services:
  sablier:
    image: sablierapp/sablier:latest        # **pin version**
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports: ["10000:10000"]
    restart: unless-stopped

  # Your container to manage (example)
  my-app:
    image: my-app:latest
    labels:
      sablier.enable: "true"
      sablier.group: "my-group"

  # Traefik with Sablier plugin (example)
  traefik:
    image: traefik:v3
    command:
      - --experimental.plugins.sablier.modulename=github.com/sablierapp/sablier
    # ... Traefik config referring Sablier middleware
```

## First boot

1. Choose reverse-proxy (Traefik is most-documented)
2. Install Sablier + reverse-proxy plugin/middleware
3. Tag containers for management
4. Set inactivity timeout
5. Test: stop → request → wake → response
6. Tune waiting-page for UX
7. Monitor: cold-start time is critical

## Data & config layout

- Sablier itself is stateless
- Relies on container orchestration state (Docker/Podman/K8s)

## Backup

Stateless — no backup needed.

## Upgrade

1. Releases: <https://github.com/sablierapp/sablier/releases>. Active.
2. Docker pull + restart
3. Watch reverse-proxy-plugin compatibility

## Gotchas

- **98th HUB-OF-CREDENTIALS TIER 2 + DOCKER-SOCKET COMPROMISE RISK**:
  - Docker socket mounted → **FULL HOST COMPROMISE** if Sablier compromised
  - K8s mode: has API-server creds to start/stop pods
  - Reinforces "Docker-socket-mount-privilege-escalation" META-FAMILY
  - **Docker-socket-mount-privilege-escalation: now 3 tools** (prior Vito 104 + Canine 104 + **Sablier**)
  - **98th tool in hub-of-credentials family — Tier 2**
- **COLD-START LATENCY = UX TRADE-OFF**:
  - First request waits for container-boot (5s-60s depending on image)
  - Waiting page helps UX
  - **Recipe convention: "cold-start-latency-UX-tradeoff" callout**
  - **NEW recipe convention** (Sablier 1st)
- **STATELESS TOOL (POSITIVE-SIGNAL)**:
  - No DB — no backup burden
  - **Stateless-tool-rarity: now 7 tools** (prior 6 + **Sablier**)
  - **Recipe convention: "stateless-tool-simpler-ops positive-signal"** — reinforces
- **OPENSSF SCORECARD BADGE = SUPPLY-CHAIN TRANSPARENCY**:
  - OpenSSF Scorecard scores supply-chain-security
  - Public score = signal of commitment
  - **Recipe convention: "OpenSSF-Scorecard-badge positive-signal"** — important
  - **NEW positive-signal convention** (Sablier 1st formally)
- **SCALE-TO-ZERO PATTERN**:
  - Standard serverless-like pattern (AWS Lambda / Knative)
  - Sablier brings this to self-hosted
  - **Recipe convention: "scale-to-zero-for-self-hosted positive-signal"**
  - **NEW positive-signal convention** (Sablier 1st)
- **REVERSE-PROXY-PLUGIN-COMPATIBILITY-MATRIX**:
  - 6 supported proxies — requires version-match per proxy
  - Breaking-change in proxy-plugin = Sablier must update
  - **Recipe convention: "reverse-proxy-plugin-version-matrix" callout**
- **WORKLOAD DEFINITION**:
  - Labels on containers OR explicit groups
  - Incorrect labels = containers that shouldn't sleep get shut down
  - **Recipe convention: "workload-label-discipline" callout**
  - **NEW recipe convention** (Sablier)
- **DIGITALOCEAN SPONSORSHIP**:
  - Corporate sponsorship = funding signal
  - **Recipe convention: "corporate-sponsor-for-OSS-tool positive-signal"**
- **INSTITUTIONAL-STEWARDSHIP**: sablierapp org + Discord + DigitalOcean-sponsor + community. **84th tool — org-with-corporate-sponsor sub-tier** (**NEW sub-tier**).
  - **NEW sub-tier: "org-with-corporate-OSS-sponsor"** (1st formally — Sablier; prior implicit for some tools)
- **TRANSPARENT-MAINTENANCE**: active + Go-Report-Card + OpenSSF-Scorecard + Discord + Helm-Chart + artwork-repo + multi-integration-docs. **92nd tool in transparent-maintenance family.**
- **SCALE-TO-ZERO-CATEGORY (adjacent):**
  - **Sablier** — generic + self-hosted
  - **Knative** — Kubernetes-native
  - **OpenFaaS** — functions-as-a-service
  - **AWS Lambda / Cloud Functions** — commercial
  - **Fission** — Kubernetes functions
- **ALTERNATIVES WORTH KNOWING:**
  - **Knative** — if Kubernetes + full serverless
  - **None** — for self-hosted + multi-reverse-proxy + non-Kubernetes, Sablier is unique
  - **Choose Sablier if:** self-hosted + reverse-proxy-native + Docker/Podman/K8s + resource-constrained host.
- **PROJECT HEALTH**: active + Go + OpenSSF + Discord + Helm + corporate-sponsor. Strong.

## Links

- Repo: <https://github.com/sablierapp/sablier>
- OpenSSF Scorecard: <https://scorecard.dev/viewer/?uri=github.com/sablierapp/sablier>
- Knative (alt): <https://knative.dev>
- OpenFaaS (alt): <https://www.openfaas.com>
