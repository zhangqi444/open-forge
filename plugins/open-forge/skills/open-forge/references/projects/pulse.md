---
name: Pulse
description: "Real-time monitoring dashboard for Proxmox (PVE/PBS/PMG) + Docker + Kubernetes — unified single-pane-of-glass with alerts, metrics, backup explorer, and optional AI (BYOK). Built for homelab/MSP scale. Go. License per repo (see repo + Pro tier)."
---

# Pulse

Pulse is **a modern, unified monitoring dashboard for homelab + MSP infrastructure** — the "single pane of glass" for Proxmox VE/PBS/PMG + Docker/Podman + Kubernetes clusters without the weight of Prometheus+Grafana+Loki+Alertmanager. Auto-discovers Proxmox nodes, consolidates metrics/alerts/health across stacks, ships with Slack/Discord/Telegram/email notifications, and offers **optional AI assistant features (BYOK — "bring your own key" — OpenAI/Anthropic/etc.)** for natural-language queries against your fleet.

Developed by **Richard Courtman (rcourtman)**. Active development; strong homelab community traction (especially among Proxmox users).

**Editions**:
- **Pulse (community)** — free + self-host; core monitoring + BYOK AI features
- **Pulse Pro** — paid tier (via <https://pulserelay.pro>) with extras like alert-analysis-AI and one-click cloud relay

Features:

- **Unified monitoring** — Proxmox VE/PBS/PMG + Docker/Podman + Kubernetes + OCI containers (Proxmox 9.1+)
- **Auto-discovery** — finds Proxmox nodes on your LAN
- **Smart alerts** — Discord, Slack, Telegram, email, ntfy, Gotify
- **Metrics history** with configurable retention
- **Backup explorer** — visualize PBS backup jobs + storage
- **AI chat assistant (BYOK)** — ask natural-language questions about your infra
- **Patrol (BYOK)** — scheduled AI-driven health checks + findings
- **OIDC/SSO**
- **Privacy-first** — no telemetry, all data on your server
- **Agent-based K8s + Docker monitoring** — lightweight agents on remote hosts
- **One-click updates** for LXC / Docker deployments

- Upstream repo: <https://github.com/rcourtman/Pulse>
- Documentation: <https://github.com/rcourtman/Pulse/tree/main/docs>
- Live demo: <https://demo.pulserelay.pro>
- Pulse Pro: <https://pulserelay.pro>
- Docker Hub: <https://hub.docker.com/r/rcourtman/pulse>
- Releases: <https://github.com/rcourtman/Pulse/releases>

## Architecture in one minute

- **Go backend** + modern web UI
- **SQLite** for persistent metrics + config (or internal embedded store; check current docs)
- **Agent-based** for Docker/K8s remote monitoring — agent installs on target host, streams metrics to Pulse server
- **Direct API access** for Proxmox (no agent; uses Proxmox API tokens)
- **Credentials encrypted at rest**
- **Resource**: small — 200-400 MB RAM for a typical homelab; scales with node count

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Proxmox LXC        | **One-liner install script** on Proxmox host                       | **Upstream-recommended** — auto-creates LXC, quickest for Proxmox users                |
| Single VM          | **Docker (`rcourtman/pulse`)**                                             | Clean deploy                                                                               |
| Kubernetes         | Community manifests + agent DaemonSet                                                       | Works; agent-based                                                                                     |
| Bare-metal         | Binary + systemd                                                                             | Possible                                                                                                          |
| Raspberry Pi       | arm64 supported                                                                                             | Great for all-Pi homelabs                                                                                                             |

## Inputs to collect

| Input                     | Example                                     | Phase        | Notes                                                                     |
| ------------------------- | ------------------------------------------- | ------------ | ------------------------------------------------------------------------- |
| Domain                    | `pulse.home.lan`                                | URL          | TLS reverse proxy                                                                 |
| Proxmox hosts             | IP + API token per PVE/PBS/PMG node             | Integration  | Generate Proxmox API tokens (read-only when possible)                                         |
| Docker hosts              | install agent on each                                   | Integration  | Agent install command generated in Settings                                                                |
| K8s clusters              | install agent DaemonSet                                             | Integration  | Agent uses serviceaccount                                                                                                     |
| AI provider (optional)    | OpenAI/Anthropic/Gemini key                                                  | AI           | BYOK; Pulse never sees your key except to make calls                                                                                     |
| Notification channels     | Discord/Slack/Telegram/email webhooks                                                     | Alerts       | Configure after install                                                                                                                             |
| Admin creds / OIDC        | first-run wizard / SSO provider                                                                       | Auth         | Strong password + 2FA / SSO                                                                                                                                            |

## Install via Proxmox LXC one-liner (recommended on Proxmox)

On your **Proxmox host** (not inside a VM):

```sh
curl -fsSL https://github.com/rcourtman/Pulse/releases/latest/download/install.sh | bash
```

Creates lightweight LXC, installs Pulse, prints access URL. **Review the script contents before piping to bash** — audit one-liner installers you run with root, always.

## Install via Docker

```yaml
services:
  pulse:
    image: rcourtman/pulse:latest                      # pin exact version in prod
    container_name: pulse
    restart: unless-stopped
    ports:
      - "7655:7655"
    volumes:
      - ./data:/data
```

Browse `http://<host>:7655/` → first-run wizard → create admin.

## First boot

1. Browse → create admin / configure OIDC
2. `Settings → Nodes → Add Proxmox` — enter API URL + token (create read-only token in Proxmox: `Datacenter → Permissions → API Tokens`)
3. Verify metrics appear
4. `Settings → Agents` — grab install command for each Docker/K8s host → run on target hosts
5. `Settings → Notifications` — add channels
6. (Optional) `Settings → AI` — add your OpenAI/Anthropic key if you want BYOK chat
7. Set alert thresholds + test notifications
8. Explore backup explorer for PBS
9. Harden: TLS + reverse proxy + SSO

## Data & config layout

- `/data/` (container) — SQLite + encrypted credential store + metric history
- Agents: minimal state on remote hosts (streaming; not storing)
- Credentials encrypted at rest with a derived key — **backup must include the key material**

## Backup

```sh
# Pulse server state
sudo tar czf pulse-$(date +%F).tgz data/
```

Metric history may be large with long retention; tune retention in settings.

## Upgrade

1. Releases: <https://github.com/rcourtman/Pulse/releases>. Active.
2. Docker: bump tag → restart → migrations auto.
3. LXC: `/opt/pulse/update.sh` or re-run install script.
4. Agents can be updated independently — typically stay forward-compat one version.
5. **Back up `data/` before major version jumps.**

## Gotchas

- **Proxmox API tokens: use read-only scope when possible.** Pulse reads metrics; doesn't need cluster-write access. Scope tokens to `PVEAuditor` role + restrict paths; reduces blast radius.
- **AI features are BYOK** — Pulse makes calls using YOUR API key. Costs accrue to your provider bill. Tune usage + set provider spending caps (see batch 69 Manifest precedent).
- **Cloud AI sees your infra data**: when you use AI chat, Pulse sends infrastructure metadata (node names, VM names, alert context) to the chosen provider. Sensitive? Use local Ollama or skip AI features. Consider what's in your PVE tags/descriptions.
- **Patrol (scheduled AI health checks)**: cool but $$$. Each run = LLM call. For 24/7 patrol on a 100-node fleet, budget accordingly.
- **Credentials encrypted at rest**: good — but **losing the encryption key = losing all stored creds** (need to re-enter Proxmox tokens, Docker connections, AI keys, SMTP creds). Preserve `data/` including key material in backups.
- **One-click installer**: piping to `bash` is convenient but means you didn't audit the script. Download + inspect first when on a production host. (General principle — applies to every `curl | bash` installer.)
- **Proxmox auto-discovery on LAN**: uses mDNS — may not work across VLANs. Add manually if segmented.
- **Docker agent**: runs on each Docker host, needs access to Docker socket (`/var/run/docker.sock`) → **effectively root**. Same sensitivity as Portainer agent / any Docker-API client. Trust your Pulse server accordingly.
- **K8s agent**: uses a ServiceAccount; scope RBAC per least-privilege (metrics + events, not write).
- **Pulse Pro vs community**: Pro adds features + cloud relay convenience. Core monitoring is fully functional in community. Check pulserelay.pro for current delta.
- **Backup Explorer** is a differentiator: visualizing PBS backups + storage usage across datastores is genuinely useful — many Proxmox users adopt Pulse for this alone.
- **Network alerts**: ensure notifications reach you during outages (the thing going down may be the thing sending alerts). Consider out-of-band alerting (separate SMS/push/ntfy instance).
- **Metrics retention**: long retention = large `data/`. Tune per need. 30 days default is sensible for most homelabs.
- **"No telemetry" pledge**: Pulse doesn't phone home. Good default; trust but verify by monitoring outbound traffic if paranoid.
- **License**: check repo LICENSE (community). Pro is commercial.
- **Alternatives worth knowing:**
  - **ProxmoxVE / PVE native UI** — built-in; no dashboard consolidation across hosts
  - **Prometheus + node_exporter + Grafana** — battle-tested ops stack; heavier
  - **Netdata** — real-time per-host monitoring; less fleet-aware
  - **Zabbix** (batch 68) — enterprise, heavyweight
  - **Checkmk** — commercial + community editions
  - **LibreNMS** — network-focused
  - **Uptime Kuma** — simple HTTP/service uptime (separate recipe likely)
  - **Beszel** — lightweight Go-based monitoring for small fleets
  - **Homepage + widgets** — dashboard but not monitoring
  - **Choose Pulse if:** Proxmox-centric homelab/MSP + want unified PVE+Docker+K8s dashboard + optional AI.
  - **Choose Prometheus+Grafana if:** you want the full enterprise observability stack + already have one.
  - **Choose Zabbix/Checkmk if:** enterprise-scale, alert-heavy environment.
  - **Choose Beszel if:** small fleet, simple, no-AI.

## Links

- Repo: <https://github.com/rcourtman/Pulse>
- Docs: <https://github.com/rcourtman/Pulse/tree/main/docs>
- Installation: <https://github.com/rcourtman/Pulse/blob/main/docs/INSTALL.md>
- Configuration: <https://github.com/rcourtman/Pulse/blob/main/docs/CONFIGURATION.md>
- Security: <https://github.com/rcourtman/Pulse/blob/main/SECURITY.md>
- API: <https://github.com/rcourtman/Pulse/blob/main/docs/API.md>
- Releases: <https://github.com/rcourtman/Pulse/releases>
- Docker Hub: <https://hub.docker.com/r/rcourtman/pulse>
- Live demo: <https://demo.pulserelay.pro>
- Pulse Pro: <https://pulserelay.pro>
- Beszel (alt lightweight): <https://github.com/henrygd/beszel>
- Prometheus: <https://prometheus.io>
- Netdata: <https://www.netdata.cloud>
