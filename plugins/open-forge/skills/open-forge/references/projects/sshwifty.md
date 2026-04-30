---
name: Sshwifty
description: "Web-based SSH + Telnet client. Access remote hosts through browser. Go single binary + WebSocket terminal. Authenticates via shared-key or per-session. GPL-3.0 (verify). Lightweight alternative to Guacamole/webssh/Apache Guacamole for SSH-only use case."
---

# Sshwifty

Sshwifty is **"a lightweight browser-based SSH + Telnet client"** — access your servers via a browser without installing an SSH client locally. Single Go binary or Docker; connects to remote hosts via SSH or Telnet, renders xterm-compatible terminal via WebSocket. Simpler + narrower than Apache Guacamole (which does SSH/Telnet + RDP + VNC) — if you only need SSH/Telnet, Sshwifty is the minimal tool.

Built + maintained by **Nirui** + community. License: check repo. Active; Docker Hub image; CI-tested; xterm-compatible rendering.

Use cases: (a) **emergency SSH from a restricted network** (airport WiFi blocks port 22; browser works) (b) **managed-service provider offering SSH-as-a-webapp** to clients (c) **teaching SSH without local client install** (d) **chromebook / iPad / shared workstation** — where installing SSH clients is awkward (e) **quick admin access** from any browser (f) **as-a-browser-gateway-bastion** — users go through Sshwifty, SSH keys stay on Sshwifty host (g) **Telnet for legacy hardware** (rare but sometimes needed — old routers, BBS systems, industrial equipment).

Features (from upstream README):

- **SSH + Telnet** client
- **Web browser access**
- **xterm-compatible** terminal rendering
- **Single binary** deployable
- **Docker image**
- **WebSocket-based** communication
- **Shared-key auth** (per-deployment or per-session)

- Upstream repo: <https://github.com/nirui/sshwifty>
- Docker Hub: <https://hub.docker.com/r/niruix/sshwifty>
- Releases: <https://github.com/nirui/sshwifty/releases>

## Architecture in one minute

- **Go** — single binary
- **WebSocket** frontend + terminal emulator (xterm.js style)
- **In-memory session state** — stateless across restarts
- **Resource**: tiny — 30-80MB RAM
- **Port 8182** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`niruix/sshwifty:latest`** (note `x`)                        | **Primary + recommended**                                                          |
| Binary release     | Prebuilt executables for various platforms                                | Direct                                                                                   |
| Build from source  | Go build                                                                                    | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Shared auth key      | Set via env or config                                       | **CRITICAL** | **Everyone with key can open SSH sessions**                                                                                    |
| Allowed hosts        | Optional allowlist of backend hosts                         | **CRITICAL** | **Without allowlist, Sshwifty = SSRF-gateway**                                                                                    |
| Port 8182            | Exposed via reverse proxy                                                                           | Network      | TLS MANDATORY                                                                                    |
| TLS reverse proxy    | nginx/Caddy/Traefik                                                                                  | **CRITICAL** | **Browser-to-Sshwifty = SSH creds in-flight**                                                                                                            |

## Install via Docker

```sh
docker run --detach \
  --restart unless-stopped \
  --publish 8182:8182 \
  --name sshwifty \
  niruix/sshwifty:latest        # **pin version**; note `niruix` with `x`
```

## First boot

1. Start → browse `http://host:8182`
2. Configure shared key or per-session auth
3. Add a target SSH host; try connecting
4. **MANDATORY**: put behind TLS reverse proxy
5. **HIGHLY RECOMMENDED**: network-layer restriction (VPN-only, IP allowlist)
6. Configure host allowlist to prevent arbitrary-host connection
7. Back up config

## Data & config layout

- Config file (YAML/JSON) — upstream-specific
- **Stateless** — no DB, no session persistence

## Backup

- Config file only.

## Upgrade

1. Releases: <https://github.com/nirui/sshwifty/releases>. Active.
2. Docker: pull + restart.
3. Binary: replace + restart.

## Gotchas

- **CROWN-JEWEL Tier 1 IF EXPOSED AS GATEWAY**:
  - Sshwifty is a **browser-to-SSH/Telnet gateway** — compromise grants attacker access to every SSH host reachable from Sshwifty
  - Functionally equivalent to Guacamole (batch 86) but SSH/Telnet-only
  - **51st tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (11th tool)** — same class as Guacamole
  - **CROWN-JEWEL Tier 1 now 11 TOOLS**: Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar, Dagu, GrowChief, Mixpost, Vito, **Sshwifty** — joins bastion-category (with Guacamole)
  - **Bastion sub-category now 2 tools** (Guacamole SSH/RDP/VNC + Sshwifty SSH/Telnet) — sub-category named
  - **Recipe convention**: SSH-gateway tools are among the most sensitive; require MFA + network-layer-restriction + audit-logging + host-allowlist.
- **TLS NON-NEGOTIABLE**:
  - SSH over WebSocket, WebSocket over HTTP = plaintext
  - **Passwords + SSH private keys typed into the web UI travel unencrypted**
  - **TLS reverse proxy is MANDATORY** — not optional
- **SSRF-GATEWAY RISK**: without host-allowlist, anyone with Sshwifty access can connect to ANY host reachable from Sshwifty's network:
  - Internal IPs (10.x, 192.168.x, 172.16-31.x)
  - Localhost
  - Cloud metadata endpoints (169.254.169.254)
  - **Configure host allowlist** — restrict to specific IPs/hostnames
  - **4th tool in SSRF-via-user-URL family**? (CommaFeed 92, Pinry 94, LinkAce 95) — actually, Sshwifty-SSH is different from HTTP-SSRF. More accurately: **"SSH-gateway-SSRF" is its own flavor**. Recipe convention: note host-allowlist-mandatory.
- **"ALL-USERS-OF-INSTANCE SEE EACH OTHER'S SESSIONS"?** — depends on config. Multi-user sharing same shared-key = everyone can see each other's sessions if not properly isolated. **Per-user auth (if supported)** or isolate Sshwifty per-user.
- **AUDIT LOGGING**: high-value gateway tool should log:
  - Who connected
  - To which host
  - When
  - Session duration
  - (Ideally) session content for compliance
  - **Verify Sshwifty's logging capabilities + configure centralized log shipping**
- **HUB-OF-CREDENTIALS = STATELESS-BUT-PASS-THROUGH**: Sshwifty itself is stateless; no stored credentials. But in-flight = SSH passwords + private keys + session tokens. **7th tool in stateless-tool-rarity** (OpenSpeedTest 91, Moodist 93, dashdot 93, Redlib-no-OAuth 95, Converse 96, Speaches 96, **Sshwifty 99**). Pattern continues solidifying.
- **SESSION HIJACKING VIA WEBSOCKET**: if WebSocket connection is hijacked post-auth (e.g., XSS in Sshwifty UI or weak session token), attacker gets live SSH session. CSP + session-token-validation matter.
- **BROWSER-BASED SSH PROS + CONS**:
  - **Pro**: access from anywhere; no local SSH client install
  - **Pro**: auditable via Sshwifty logs
  - **Con**: keystrokes + output pass through Sshwifty (trust required)
  - **Con**: SSH key handling — if Sshwifty stores keys, it's a key-custodian tool (Tier 2); if not, user types password/key every time
- **TELNET = PLAINTEXT**: Telnet is unencrypted by protocol design. Sshwifty supports it for legacy hardware. Use only over trusted networks (private VPN).
- **LICENSE CHECK**: not explicitly stated in README snippets observed. Follow LICENSE-file-verification-required convention.
- **INSTITUTIONAL-STEWARDSHIP**: Nirui + community. **36th tool in institutional-stewardship — sole-maintainer-with-community (22nd tool in that class).**
- **TRANSPARENT-MAINTENANCE**: active + CI + Docker + binary releases + prebuilt-platform coverage + humorous README-voice (the "Executive Golden Premium Plus+ Platinum Ultimate AD-free version" joke). **43rd tool in transparent-maintenance family.**
- **NOVELTY: EXPLICIT HUMOR in README** — rare; signals human-maintained-not-corporate. Not a security concern; just a tone-signal.
- **DEFAULT-CREDS-RISK status**: verify first-boot enforces auth-setup (shared-key required). If not, flag as default-creds-risk.
- **ALTERNATIVES WORTH KNOWING:**
  - **Apache Guacamole** (batch 86, 87) — broader scope (SSH+RDP+VNC); more complex; CROWN-JEWEL Tier 1
  - **Webssh2** — Node.js simpler SSH-only
  - **ShellHub** — modern device-management + SSH; more-featured
  - **GateOne** — Python; older but functional
  - **Cockpit** (RedHat) — Linux admin via web; broader than just SSH
  - **Tailscale SSH** — commercial/SaaS with OSS client; uses Tailscale ACLs for SSH auth
  - **Teleport** (goteleport) — commercial-OSS; enterprise-grade identity-native access
  - **Boundary** (HashiCorp) — similar to Teleport
  - **Just use a local SSH client** — if browser access isn't strictly required
  - **Choose Sshwifty if:** you want MINIMAL + Go + SSH/Telnet-only + browser + self-host.
  - **Choose Guacamole if:** you want RDP+VNC in addition to SSH.
  - **Choose Teleport if:** you want enterprise-grade + identity-aware + audit-compliance.
  - **Choose Tailscale SSH if:** you already use Tailscale.
- **PROJECT HEALTH**: active + Docker + CI + binary releases. Strong signals for a specialized browser-SSH tool.

## Links

- Repo: <https://github.com/nirui/sshwifty>
- Docker: <https://hub.docker.com/r/niruix/sshwifty>
- Releases: <https://github.com/nirui/sshwifty/releases>
- Apache Guacamole (alt broader): <https://guacamole.apache.org>
- Webssh2 (alt simpler): <https://github.com/billchurch/webssh2>
- Teleport (enterprise alt): <https://goteleport.com>
- Tailscale SSH: <https://tailscale.com/kb/1193/tailscale-ssh/>
- Boundary (HashiCorp): <https://www.boundaryproject.io>
- Cockpit (Linux admin alt): <https://cockpit-project.org>
