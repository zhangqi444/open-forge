---
name: WGDashboard
description: "WireGuard VPN config + management dashboard. Python + Vue.js web UI for creating peers, QR codes, traffic monitoring, cross-server management. Apache-2.0. Active maintenance with transparent CVE-disclosure (v4.2.x→v4.3.2 security advisory). Replaces `wg show` CLI with a polished web panel."
---

# WGDashboard

WGDashboard is **"the web UI you actually want for WireGuard"** — monitor + manage WireGuard VPN configs without `ssh`-ing into your server + typing `wg show`. Create peers with one click, generate QR codes for mobile clients, view traffic stats per peer, run traceroutes + pings to peers, manage multiple WG servers from one dashboard. Python + Vue.js; dockerized; actively maintained; explicit security-advisory-disclosure culture (v4.3.2 release notes publicly warn of vulnerabilities in 4.2.x — transparent-maintenance signal).

Built + maintained by **Donald Zou** + **WGDashboard team/community**. **Apache-2.0**. Active development + Discord + Reddit + Matrix community; funded via GitHub Sponsors + BuyMeACoffee + Patreon + merch. Supported by DigitalOcean.

Use cases: (a) **personal homelab VPN** — manage peers for family devices (b) **small-business remote access** — replace Meraki / OpenVPN Access Server (c) **road warrior** — generate one-time configs for laptop/phone from web (d) **selfhost VPN for privacy** — combine with own ISP to replace Mullvad / ExpressVPN (e) **multi-server WireGuard mesh** — manage all nodes from one dashboard (f) **teams' tailnet-alternative** — though Tailscale/Headscale arguably better for that.

Features (from upstream README):

- **Dashboard** showing all peers + status + traffic
- **Peer management** — create, revoke, rotate
- **QR code generation** for mobile clients
- **Cross-server management** — one dashboard for multiple WG servers
- **Sign-in system** — web-auth with MFA
- **Traffic monitoring** per peer
- **Traceroute + ping** to peers
- **IPv4 + IPv6** support
- **Email send** (for peer config delivery)
- **Configuration backup + restore**
- **Multilingual UI**
- **Dark/light theme**
- **API** for integrations
- **Docker** image + bare-metal install
- **CodeQL security analysis** badge (CI)

- Upstream repo: <https://github.com/WGDashboard/WGDashboard>
- Homepage: <https://wgdashboard.dev>
- Docker Hub: <https://hub.docker.com/r/donaldzou/wgdashboard>
- Discord: <https://discord.gg/72TwzjeuWm>
- Reddit: <https://reddit.com/r/WGDashboard>
- Matrix: <https://matrix.to/#/#wgd:matrix.org>
- Releases: <https://github.com/WGDashboard/WGDashboard/releases>
- v4.3.2 security advisory: <https://github.com/WGDashboard/WGDashboard/releases/tag/v4.3.2>

## Architecture in one minute

- **Python backend** — Flask-derived; manages WireGuard configs + calls `wg` CLI
- **Vue.js frontend**
- **WireGuard kernel module** or `wireguard-go` userspace — container mode supports both
- **SQLite** for dashboard state
- **Required**: Docker container runs with `--cap-add NET_ADMIN` + WireGuard kernel support on host (or userspace)
- **Ports**: 10086 default dashboard; WireGuard UDP ports as configured (51820+)
- **Resource**: light — 100-200MB RAM

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`donaldzou/wgdashboard:latest`** (multi-arch)                 | **Easiest**                                                                        |
| Bare-metal         | Python + systemd + WireGuard                                              | Traditional install                                                                                   |
| Docker compose     | Upstream provides compose YAMLs                                                         | For stack layout                                                                                               |
| Proxmox LXC / VM   | Community scripts                                                                                 | Common homelab pattern                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `wgd.example.com`                                           | URL          | TLS MANDATORY                                                                                    |
| Server public IP(s)  | For peer configs' `Endpoint = x.x.x.x:51820`                | Network      | DDNS / static; IPv6 if supported                                                                                    |
| WireGuard UDP port(s)| 51820 default; can be multi-tunnel                          | Network      | Forward through firewall/NAT                                                                                    |
| Dashboard port       | 10086                                                       | Network      | Behind reverse proxy                                                                                    |
| Admin password       | First-boot set                                                                           | **CRITICAL** | **Strong pw + enable MFA**                                                                                    |
| WG private keys      | Generated per interface                                                                            | **CRITICAL** | **IMMUTABLE** for existing peers                                                                                                            |
| `--cap-add NET_ADMIN` | Docker capability                                                                                                           | Deployment   | Required — dashboard manipulates network-stack                                                                                                                            |

## Install via Docker

```yaml
services:
  wgdashboard:
    image: donaldzou/wgdashboard:v4.3.2    # **pin to latest SECURITY-PATCHED version**
    container_name: wgdashboard
    restart: unless-stopped
    cap_add: [NET_ADMIN]
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv6.conf.all.forwarding=1
    ports:
      - "10086:10086/tcp"
      - "51820:51820/udp"
    volumes:
      - ./wg-configs:/etc/wireguard
      - ./wg-db:/data
    # ensure host loads kernel WireGuard: modprobe wireguard
```

Behind TLS reverse proxy (SWAG / Caddy / Traefik) — NEVER expose dashboard directly on internet.

## First boot

1. Start → browse `http://host:10086` → set admin password (strong)
2. Enable MFA immediately
3. Create first WireGuard interface → generate peer → download QR code → test on phone
4. Verify traffic routes through VPN (visit ipinfo.io via mobile)
5. Put behind TLS reverse proxy
6. Lock down: firewall rules limit dashboard to admin IPs only
7. Back up `/etc/wireguard` + `/data`

## Data & config layout

- `/etc/wireguard/*.conf` — per-interface WireGuard configs (**server + peer private keys**)
- `/data/` — dashboard SQLite DB + session data
- `wgdashboard.ini` — dashboard config (auth settings, etc.)

## Backup

```sh
sudo tar czf wgd-$(date +%F).tgz ./wg-configs ./wg-db
# Store OFFLINE — these files contain ALL private keys to your VPN
```

## Upgrade

1. Releases: <https://github.com/WGDashboard/WGDashboard/releases>. Active.
2. **SECURITY-CRITICAL: track all security advisories** — v4.3.2 explicitly warned about vulns in 4.2.x → upgrade immediately on advisories.
3. Pull + restart.
4. **Back up wg-configs + wg-db BEFORE major upgrades**.

## Gotchas

- **VPN DASHBOARD = ENTIRE NETWORK BOUNDARY**: compromising WGDashboard = attacker can:
  - Generate new peer configs (invisibly add their own VPN access)
  - Read existing peer configs (learn private keys, impersonate legit peers)
  - Reconfigure routing (send traffic through attacker MITM)
  - Delete logs (cover tracks)
  - **29th tool in hub-of-credentials family — CROWN-JEWEL TIER 1** (joins Octelium, Guacamole, Homarr-by-aggregation, pgAdmin). **Network-boundary control-plane.**
- **v4.2.x → v4.3.2 EXPLICIT UPSTREAM WARNING**: README has a bold `!WARNING` banner advising all public-internet users to upgrade to the latest release immediately. **Transparent-maintenance signal: upstream discloses vulnerabilities + advises upgrades publicly + in README.** **12th tool in transparent-maintenance family.**
  - Implication: whatever version you install today, check for newer security releases at least weekly. Subscribe to release notifications.
- **NEVER EXPOSE DASHBOARD DIRECTLY ON INTERNET**: put behind TLS reverse proxy + authentication layer (Authelia / Authentik / Cloudflare Access) + IP allowlist. Same rule as pgAdmin (batch 90), Guacamole (87).
- **WIREGUARD PRIVATE KEYS IMMUTABILITY**: rotating a WG interface private key means redistributing all peer configs. Same friction as Signal/Matrix identity keys — don't rotate casually. **24th tool in immutability-of-secrets family.**
- **`NET_ADMIN` CAPABILITY = ELEVATED PRIVILEGES**: WG dashboard container runs with `NET_ADMIN` → can manipulate host network stack. Container escape = host-network-compromise. Mitigations: rootless-Docker + user-namespace + drop-other-capabilities + minimize container-content attack surface.
- **IP FORWARDING**: must be enabled on host (`net.ipv4.ip_forward=1`) — WG won't route without it. Often set via sysctls.
- **TRAFFIC MONITORING COLLECTS PER-PEER METADATA**: dashboard stores traffic stats + connection times. **Privacy implications**:
  - For personal use: fine
  - For multi-user VPN (e.g., family/friends): their traffic volumes are visible to you as admin
  - For business VPN: employee privacy laws apply (varies by jurisdiction)
  - **Publish clear user-notice** + limit log retention + consider opt-out
- **MFA ENABLEMENT AT BOOTSTRAP**: WGDashboard supports MFA. **Enable IMMEDIATELY on first login** — VPN dashboard MUST have MFA. Consolidates with **"enable-security-feature-at-bootstrap"** family (Bigcapital master-password batch 90, Mailcow batch <earlier>, 2FA on admin panels generally).
- **CROSS-SERVER MANAGEMENT = MULTIPLIED RADIUS**: if WGDashboard manages multiple WG servers, dashboard compromise = ALL servers compromised. Consider per-site dashboards for blast-radius limitation vs. operational convenience.
- **PEER CONFIG DISTRIBUTION**: QR codes + email send features are convenient but transmit private keys. **Email is unencrypted in transit** typically → prefer:
  - QR code displayed on trusted admin's screen → user scans with their phone (no transit)
  - Signal / encrypted-messenger delivery for remote
  - Short-expiry one-click download links over TLS
  - Never email raw `.conf` files with private keys
- **FIREWALL RULES**: dashboard port (10086) + WireGuard UDP port (51820+) both need firewall rules. Don't leave 10086 exposed to 0.0.0.0; use `iptables`/`ufw` + reverse proxy.
- **WIREGUARD-GO vs KERNEL WIREGUARD**: kernel WG is faster + lower overhead. wireguard-go is userspace fallback (no kernel module needed — useful in VPS with old kernels). WGDashboard supports both via container; prefer kernel WG when possible.
- **DNS WITHIN VPN**: WG peers can use internal DNS (Pi-hole, AdGuard Home, corporate DNS). Configure via `DNS = ...` in peer config. Watch for DNS leaks on clients (they should route DNS through the tunnel).
- **KILL SWITCH CLIENT-SIDE**: for privacy-VPN use-case, configure client-side firewall to drop traffic when WG is down (typical via `PostUp`/`PostDown` scripts or client-app settings). Not a WGDashboard feature per se; OS-side.
- **PROJECT HEALTH**: active + transparent CVE disclosure + Discord/Reddit/Matrix communities + sponsor funding + DigitalOcean support + merch store + CodeQL + Apache-2.0. Strong stewardship signals.
- **MERCH-AS-FUNDING**: WGDashboard sells $17 shirts for support — a unique funding model. Unusual + flag-worthy as OSS sustainability case study.
- **COMMERCIAL-TIER**: no paid SaaS or features; pure-donation (GitHub Sponsors + BMAC + Patreon + merch). **6th tool in pure-donation commercial-tier.**
- **ALTERNATIVES WORTH KNOWING:**
  - **WireGuard + wg-easy** — simpler dashboard; fewer features; Docker-compose-friendly (github.com/wg-easy/wg-easy)
  - **Headscale** — open-source Tailscale control server (different model — tailnet vs. VPN); better for mesh use cases
  - **Tailscale** — commercial SaaS + OSS client; managed control plane
  - **NetBird** — self-hosted mesh VPN; more Tailscale-like
  - **Firezone** — WireGuard-based self-hosted; business-focus; Elixir + Rust
  - **OpenVPN Access Server** — commercial; OpenVPN protocol (vs WG)
  - **PiVPN** — install-script-based WG on Raspberry Pi; no web UI
  - **Algo VPN** — Ansible-driven WG deploy
  - **Choose WGDashboard if:** you want Python + web UI + lots of features + mature + multi-server.
  - **Choose wg-easy if:** you want MINIMAL, single-server, Docker-native.
  - **Choose Headscale/NetBird if:** you want MESH (peer-to-peer) not HUB-AND-SPOKE.
  - **Choose Firezone if:** business use-case + compliance-focused.

## Links

- Repo: <https://github.com/WGDashboard/WGDashboard>
- Homepage: <https://wgdashboard.dev>
- Docker: <https://hub.docker.com/r/donaldzou/wgdashboard>
- Discord: <https://discord.gg/72TwzjeuWm>
- Reddit: <https://reddit.com/r/WGDashboard>
- wg-easy (simpler alt): <https://github.com/wg-easy/wg-easy>
- Headscale (mesh alt): <https://github.com/juanfont/headscale>
- NetBird (mesh alt): <https://netbird.io>
- Firezone (business alt): <https://www.firezone.dev>
- Tailscale (commercial SaaS): <https://tailscale.com>
- PiVPN (simpler alt): <https://www.pivpn.io>
- WireGuard: <https://www.wireguard.com>
