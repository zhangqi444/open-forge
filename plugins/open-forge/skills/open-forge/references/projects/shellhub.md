---
name: ShellHub
description: "Centralized SSH gateway for remotely managing servers/devices. Agent on each device; web/mobile access; no public IP / port forwarding / jump hosts required. Go. shellhub-io org. Commercial cloud option."
---

# ShellHub

ShellHub is **"Teleport / Tailscale SSH — but OSS + web-console + device-agent-based"** — a centralized SSH gateway. Install agent on each device; access from web browser or mobile app **without public IP, port forwarding, VPN, firewall changes, or jump hosts**. All connections go through ShellHub server.

Built + maintained by **shellhub-io** org. Commercial-parallel: **ShellHub Cloud**. QA CI; Gitter community; all-contributors 23+. License: check LICENSE.

Use cases: (a) **remote-access to edge devices** — no public IP (b) **IoT fleet-SSH** (c) **multi-customer server-access for consultants** (d) **zero-trust-ish SSH** via web auth (e) **mobile-SSH** (f) **centralized audit-log of SSH sessions** (g) **bastion-replacement** (h) **edge-gateway without VPN**.

Features (per README):

- **Centralized SSH gateway**
- **Device-agent** on each server/device
- **Web + mobile client**
- **No public-IP needed** on devices
- **ShellHub Cloud** commercial option

- Upstream repo: <https://github.com/shellhub-io/shellhub>
- Docs: <http://docs.shellhub.io>
- Cloud: <https://cloud.shellhub.io>

## Architecture in one minute

- **Server** (Go) — central gateway
- **Agent** (Go) — runs on each device; outbound-connection to server
- **API** — web frontend
- **MongoDB** — data
- **Redis** — session/cache
- **Nginx** — reverse proxy
- **Resource**: server = 500MB-1GB; agent = tiny

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Server stack                                                   | Primary                                                                                    |
| **ShellHub Cloud** | SaaS                                                                                                                   | Alt                                                                                   |
| **Agent install**  | Per-device                                                                                                             | Required on each                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `shellhub.example.com`                                      | URL          | **TLS MANDATORY**                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| MongoDB              | Data                                                        | DB           |                                                                                    |
| Redis                | Cache                                                       | Infra        |                                                                                    |
| Device tokens        | Per-agent                                                   | Onboarding   |                                                                                    |

## Install via Docker

See <http://docs.shellhub.io>. Typical structure:
```yaml
services:
  mongo:
    image: mongo:6
  redis:
    image: redis:7
  api:
    image: shellhubio/api:latest        # **pin**
    depends_on: [mongo, redis]
  ssh:
    image: shellhubio/ssh:latest        # **pin**
  gateway:
    image: shellhubio/gateway:latest        # **pin**
    ports: ["80:80", "443:443"]
  ui:
    image: shellhubio/ui:latest        # **pin**
```

Install agent on devices: see docs for one-liner install.

## First boot

1. Start stack
2. Create admin user
3. Generate device-token for first server
4. Install agent on device
5. Watch device appear in dashboard
6. SSH via web console
7. Put behind TLS
8. Back up MongoDB + Redis

## Data & config layout

- **MongoDB** — users, devices, session-logs
- **Redis** — session cache

## Backup

```sh
docker compose exec mongo mongodump --archive | gzip > shellhub-$(date +%F).gz
# **Contains device-tokens + session-history — ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/shellhub-io/shellhub/releases>
2. Docker pull + restart
3. Agent version ≈ server version recommended

## Gotchas

- **152nd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — CENTRAL SSH-CHOKEPOINT**:
  - Compromised server = SSH to ALL enrolled devices
  - Session logs = everything typed in sessions
  - Device tokens = device-impersonation
  - **152nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "centralized-SSH-gateway + session-log-aggregator"** (1st — ShellHub; infrastructure-tier)
  - **CROWN-JEWEL Tier 1: 48 tools / 45 sub-categories**
- **SERVER-COMPROMISE = FLEET-COMPROMISE**:
  - All enrolled devices reachable from compromised server
  - Separating control-plane from data-plane helps
  - **Recipe convention: "central-SSH-gateway-compromise-fleet-risk callout"**
  - **NEW recipe convention** (ShellHub 1st formally)
- **SESSION-LOG-DATA-RETENTION**:
  - Session recordings include sensitive output
  - Retention policy critical
  - **Recipe convention: "session-recording-retention-policy callout"**
  - **NEW recipe convention** (ShellHub 1st formally)
- **AGENT-SECURITY**:
  - Agent process on devices — compromise = device RCE
  - Agent updates critical
  - **Recipe convention: "agent-based-architecture-patch-discipline callout"**
  - **NEW recipe convention** (ShellHub 1st formally)
- **OUTBOUND-CONNECTION-DESIGN**:
  - Agent initiates outbound — no inbound needed on device
  - Good for NAT'd devices
  - **Recipe convention: "outbound-agent-connection-NAT-friendly positive-signal"**
  - **NEW positive-signal convention** (ShellHub 1st formally)
- **COMMERCIAL-PARALLEL (ShellHub Cloud)**:
  - **Commercial-parallel-with-OSS-core: 13 tools** 🎯 **13-TOOL MILESTONE**
- **GITTER-LEGACY**:
  - **Gitter-legacy-community-channel: 3 tools** (Docspell+Cloud Commander+ShellHub) 🎯 **3-TOOL MILESTONE**
- **ALL-CONTRIBUTORS-BADGE**:
  - 23+ contributors documented
  - **Recipe convention: "all-contributors-badge positive-signal"**
  - **NEW positive-signal convention** (ShellHub 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: shellhub-io org + commercial-parallel + Gitter + 23+ contributors + docs-site + CI + all-contributors-badge. **138th tool — corporate-backed-OSS-with-cloud sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + CI + Gitter + docs + releases + all-contributors + cloud-parallel. **144th tool in transparent-maintenance family.**
- **SSH-GATEWAY-CATEGORY:**
  - **ShellHub** — OSS; device-agent; web-SSH
  - **Teleport** — dominant; K8s + DB + SSH + web; commercial + OSS
  - **Apache Guacamole** — HTML5 RDP/SSH
  - **Bastillion** — older; Java SSH-gateway
  - **Tailscale SSH** — mesh-overlay; commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Teleport** — if you want K8s + DB + SSH unified
  - **Apache Guacamole** — if you want RDP+SSH
  - **Tailscale SSH** — if you're already on Tailscale
  - **Choose ShellHub if:** you want OSS + agent-based + web/mobile + lightweight.
- **PROJECT HEALTH**: active + commercial-parallel + 23+ contributors + docs + Gitter. Strong.

## Links

- Repo: <https://github.com/shellhub-io/shellhub>
- Docs: <http://docs.shellhub.io>
- Teleport (alt): <https://github.com/gravitational/teleport>
- Apache Guacamole (alt): <https://github.com/apache/guacamole-server>
