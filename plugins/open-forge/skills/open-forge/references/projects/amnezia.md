---
name: Amnezia VPN
description: Desktop/mobile client that auto-deploys VPN server Docker containers to your own VPS via SSH. Multi-protocol (OpenVPN, WireGuard, IKEv2, Shadowsocks, Cloak, XRay, AmneziaWG), traffic obfuscation, split tunneling. Designed for users in censored regions. GPL-3.0.
---

# Amnezia VPN

Amnezia is an unusual VPN project: the **repo you see on GitHub is the CLIENT app** (`amnezia-client`). You run it on your laptop/phone, give it SSH access to a VPS you already own, and the client **installs VPN server Docker containers on the remote host for you** + connects to them.

Target audience: users in censored internet regions (Iran, China, Russia, Myanmar) who need:

- **Obfuscation** — disguise VPN traffic as HTTPS, so DPI-based censors don't block it
- **Multiple protocols** — fall back when one is blocked
- **Easy setup** — can't expect everyone to edit nftables + compile WireGuard

Supported server-side protocols:

- **Classic**: OpenVPN, WireGuard, IKEv2
- **Obfuscated / harder to block**:
  - **OpenVPN over Cloak** — disguises as HTTPS traffic
  - **Shadowsocks** — encrypted proxy originally from China-bypass scene
  - **OpenVPN over Shadowsocks**
  - **AmneziaWG** — WireGuard fork with added obfuscation layer
  - **XRay** — modern multi-protocol proxy (successor to V2Ray)

- Upstream repo (client): <https://github.com/amnezia-vpn/amnezia-client>
- Repo (server scripts — embedded in client app): <https://github.com/amnezia-vpn/amnezia-vpn>
- Website: <https://amnezia.org>
- Docs: <https://docs.amnezia.org>
- AmneziaWG (fork): <https://docs.amnezia.org/documentation/amnezia-wg/>
- Premium: <https://vpnpay.io/en/amnezia-premium/>

## The unusual architecture

You don't "install Amnezia on a server" the traditional way. Instead:

1. You rent any VPS (DigitalOcean, Hetzner, Linode, random-$5-VPS)
2. You install the **Amnezia client** on your laptop
3. In the client: enter the VPS IP + root SSH credentials (password or key)
4. Client SSHes in, installs Docker, pulls the relevant protocol containers, configures them, opens the firewall
5. Client connects to the newly-deployed server and you're VPN'ed

Result: the "install" is done via the client UI. There's no standalone `docker-compose up` for the server.

## Compatible install methods

### Client (what you install manually)

| Platform    | Install                                          |
| ----------- | ------------------------------------------------ |
| Windows     | Installer from <https://amnezia.org>             |
| macOS       | .dmg from <https://amnezia.org>                  |
| Linux       | AppImage / .deb / .rpm / Flathub                 |
| Android     | Google Play / APK / F-Droid (mirror)             |
| iOS / iPadOS | App Store                                       |
| Keenetic    | AmneziaWG native support on beta firmware        |

### Server (deployed BY the client onto your VPS)

Any VPS running Ubuntu 20.04+ / Debian 11+ / CentOS 8+ with:

- Public IPv4 (IPv6 optional, some protocols prefer v4)
- Root SSH access (password or key)
- Docker-capable kernel
- Open outbound connectivity (to download Docker images)

## Inputs to collect

| Input              | Example                           | Phase     | Notes                                                          |
| ------------------ | --------------------------------- | --------- | -------------------------------------------------------------- |
| VPS IP             | `203.0.113.42`                    | Setup     | Public IPv4                                                      |
| SSH username       | `root`                             | Setup     | Must be root (Amnezia installs system packages + Docker)         |
| SSH password or key | password or private key file     | Setup     | Client uses this one-time for deployment                         |
| Protocol choice    | WireGuard / AmneziaWG / OpenVPN+Cloak / XRay / etc. | Runtime | Depends on threat model (see below) |
| Port (per-protocol)| e.g. UDP 51820 for WireGuard       | Network   | Client auto-configures + opens                                  |
| Client OS per user | Windows/Mac/Linux/Android/iOS     | Client    | Each device runs the client                                      |

## Deploy (client-driven)

From your laptop:

1. Install Amnezia client (Windows/macOS/Linux)
2. Launch → **Setup your own server** → enter IP + SSH creds
3. Client SSH probes host, installs Docker if missing
4. Pick a protocol:
   - **For general privacy**: WireGuard (fastest) or OpenVPN
   - **For censored networks**: AmneziaWG (hardest to DPI-block, fastest), OpenVPN+Cloak (looks like HTTPS), XRay+Reality (bleeding-edge obfuscation)
   - **As fallback**: Shadowsocks (when everything else blocked)
5. Client generates config, deploys container on server, saves client config locally
6. Tap Connect

For additional devices: on the first client, generate a **connection file** (`.vpn` format) → share via encrypted channel → import on second device.

## Protocol selection guide

| Use case                                       | Best protocol                                             |
| ---------------------------------------------- | --------------------------------------------------------- |
| General privacy / bypass geo-blocks            | **WireGuard** (fastest, simplest)                          |
| Mild DPI / ISP throttling                      | **WireGuard** / **OpenVPN (TCP 443)**                      |
| Active DPI censorship (Iran, China, Russia)    | **AmneziaWG**, **XRay+Reality**, or **OpenVPN+Cloak**      |
| Last-resort when everything blocked            | **Shadowsocks**                                            |
| Legacy device / needs Windows 10 built-in      | **IKEv2**                                                  |
| Enterprise / corporate network                 | **OpenVPN over TCP 443** blends with web traffic           |

## Data & config layout

- **On server** (deployed by client): Docker containers per protocol; configs in `/opt/amnezia/` or `/etc/wireguard/` etc.; firewall rules via nftables/iptables
- **On client**: local config files (per-server, per-protocol); key material encrypted at rest

## Backup

- **Server**: whatever you back up of your VPS. Reinstalling Amnezia re-creates configs via the client, so server backup isn't strictly required.
- **Client**: export `.vpn` connection files → save securely. Losing client configs = reconnect from scratch (re-SSH + re-deploy, which regenerates keys; existing clients on other devices keep working).
- **Keys rotate** when you re-deploy — if you already shared `.vpn` files with others, redeploying invalidates them.

## Upgrade

- **Client**: auto-update on desktop (check via Help → Check for Updates) OR download new release from amnezia.org.
- **Server**: Amnezia client → Connection settings → "Update server" → client re-deploys containers at latest versions.

Cadence: ~monthly releases.

## Gotchas

- **Requires root SSH to your VPS.** This is how the magic works — Amnezia installs system packages, Docker, firewall rules. If you're uncomfortable giving root access to a desktop app, read the source before running.
- **Russian-origin project** — leadership is Russian activists focused on anti-censorship. If that raises personal threat-model concerns (government pressure on upstream), evaluate against your threat model. Project has been audited publicly; code is GPL-3.0 open.
- **Protocol-specific blocking**: as censors adapt, certain protocols lose effectiveness. **Have multiple protocols deployed** so you can swap when one breaks.
- **AmneziaWG is a fork of WireGuard** with added obfuscation — not upstream WireGuard. Works with standard WireGuard clients that support the AmneziaWG protocol extension, OR the Amnezia client specifically.
- **Keenetic router support** (AmneziaWG native on beta firmware) is notable for routing whole-household VPN without a separate client.
- **Split tunneling** — per-app or per-site routing: only some apps go through VPN, others go direct. Desktop + Android support this; iOS has limits due to Apple's APIs.
- **Shared VPS** (hosting many users' personal VPNs) gets IPs added to public "known VPN" blocklists quickly. Streaming services + some news sites will block.
- **Latency** depends on VPS location. Pick a VPS close to your target country (e.g., Netherlands for EU streaming, Japan for Asia).
- **Premium tier** (paid VPN service by Amnezia team) uses a pool of servers vs your own VPS. Different product — if you don't want to run a server yourself.
- **No self-hosted web admin UI.** All management is via the desktop/mobile client. If you SSH into the server, you're poking at Docker containers directly.
- **Port choice matters for censorship bypass**: OpenVPN on UDP 1194 is fingerprinted; over TCP 443 with Cloak it looks like HTTPS traffic. The client picks sensible defaults; tune if a specific port is blocked.
- **XRay + Reality** is the newest obfuscation layer (2023+) — modeled on legitimate TLS handshakes; highest efficacy against modern DPI in 2024-2026.
- **No audit log on the server by default** — traffic is not logged (privacy feature), but logs won't help you debug connectivity issues. Enable `--verbose` in client for client-side logging.
- **GPL-3.0** license — full copyleft; redistributing modified versions requires publishing source.
- **Donations** via OpenCollective, crypto, Liberapay — <https://amnezia.org>.
- **Alternatives worth knowing:**
  - **V2Ray / XRay** (raw) — more DIY; what's embedded in Amnezia + Outline
  - **Outline VPN (Jigsaw)** — Shadowsocks-based, similar auto-deploy model from Google's Jigsaw; less multi-protocol
  - **AlgoVPN** — Ansible playbook, WireGuard + IKEv2, no DPI-obfuscation focus
  - **Streisand** — multi-protocol auto-deploy (now unmaintained)
  - **PiVPN** — classic home-server VPN on Raspberry Pi
  - **WireGuard-Easy** (`wg-easy`) — simple web UI for WireGuard only
  - **Headscale / Tailscale** — mesh VPN, different use case (personal device network)
  - **Marzban / ShadowSocks-Panel / V2RayNG** — multi-user VPN panels for service operators

## Links

- Client repo: <https://github.com/amnezia-vpn/amnezia-client>
- Server scripts repo: <https://github.com/amnezia-vpn/amnezia-vpn>
- Website: <https://amnezia.org>
- Mirror (often accessible from censored regions): <https://storage.googleapis.com/kldscp/amnezia.org>
- Docs: <https://docs.amnezia.org>
- AmneziaWG: <https://docs.amnezia.org/documentation/amnezia-wg/>
- Releases (client): <https://github.com/amnezia-vpn/amnezia-client/releases>
- Reddit: <https://www.reddit.com/r/AmneziaVPN>
- Telegram (English): <https://t.me/amnezia_vpn_en>
- Telegram (Farsi): <https://t.me/amnezia_vpn_ir>
- Telegram (Myanmar): <https://t.me/amnezia_vpn_mm>
- Telegram (Russian): <https://t.me/amnezia_vpn>
- Premium service: <https://vpnpay.io/en/amnezia-premium/>
- Donate: <https://amnezia.org/donate.html>
