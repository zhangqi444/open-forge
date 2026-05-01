---
name: Self-hosted Gateway (RPoVPN)
description: "Self-hosted Docker-native tunnel to localhost — Cloudflare Tunnels / Tailscale Funnel / ngrok alternative. WireGuard + Nginx + Caddy. TLS auto via Let's Encrypt. Proxy-protocol real IPs. hintjen/selfhosted-gateway."
---

# Self-hosted Gateway (RPoVPN)

Self-hosted Gateway is **"Cloudflare Tunnel / Tailscale Funnel / ngrok — but fully self-hosted + open-source"** — a Docker-native **Reverse-Proxy-over-VPN (RPoVPN)** solution using WireGuard + Nginx (gateway side) + Caddy (client side). **Automatic HTTPS** via Caddy (Let's Encrypt / ZeroSSL). **Real client IP** passed via proxy protocol. Basic-auth support. Generic TCP/UDP via socat. **No custom code** — leverages battle-tested FOSS components.

Built + maintained by **hintjen**. Video setup guide on YouTube. Compose-based deployment.

Use cases: (a) **expose self-hosted services behind CGNAT/double-NAT** (Starlink, mobile) (b) **fully self-hosted tunnel** without Cloudflare/Tailscale dependency (c) **static-IP workaround** for dynamic-IP home connection (d) **network-isolation via Docker netns** for exposed services (e) **Cloudflare Tunnel replacement** (f) **ngrok alternative** (g) **home-lab public exposure without port-forward** (h) **multi-VPS-gateway for redundancy**.

Features (per README):

- **Self-hosted** — fully your infra
- **WireGuard** tunnel
- **Nginx (gateway side) + Caddy (client side)**
- **Auto-HTTPS** (Caddy Let's Encrypt / ZeroSSL)
- **Proxy-protocol** — real client IP
- **Basic auth** via env var
- **Generic TCP/UDP** via socat
- **Docker-native**
- **No custom code** — FOSS components only

- Upstream repo: <https://github.com/hintjen/selfhosted-gateway>
- Setup video: <https://youtu.be/VCH8-XOikQc>

## Architecture in one minute

- **Gateway side** (VPS with public IP): Nginx + WireGuard peer
- **Client side** (your home LAN): Caddy + WireGuard peer
- WireGuard tunnel connects them
- Nginx on gateway proxies to client over tunnel
- Caddy on client terminates TLS + proxies to localhost services
- **Resource**: low both sides
- **Port**: Public 80/443 on gateway; WireGuard UDP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Two compose files (gateway + client)                                                                                   | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| VPS                  | Any cloud                                                   | Infra        | Public IP                                                                                    |
| Domain               | `app.example.com`                                           | URL          | Managed DNS → VPS IP                                                                                    |
| WireGuard keys       | Generated                                                   | Secret       | **Critical — tunnel auth**                                                                                    |
| Caddy TLS email      | Let's Encrypt                                               | Email        |                                                                                    |
| Basic auth           | Optional                                                    | Auth         | Env var                                                                                    |
| Target services      | Docker-compose services on client                           | Config       |                                                                                    |

## Install via Docker Compose

Two sides:

**Gateway (VPS)**: Nginx + WireGuard peer  
**Client (home)**: Caddy + WireGuard peer  

Follow the repo's compose examples + setup script. Non-trivial — video guide recommended.

## First boot

1. Provision VPS w/ Docker
2. Generate WireGuard keypairs for both sides
3. Deploy gateway side with Nginx + WG
4. Deploy client side with Caddy + WG
5. Verify tunnel up
6. Point DNS at gateway IP
7. Start backend services on client
8. Verify end-to-end HTTPS
9. Configure proxy-protocol for real-IP logging

## Data & config layout

- WireGuard configs (both sides)
- Caddy config (client)
- Nginx config (gateway)

## Backup

```sh
# WireGuard keys — **BACKUP + ENCRYPT**
# Nginx + Caddy configs
# Lose keys = re-provision tunnel
```

## Upgrade

1. Pin image versions in compose
2. Periodically update Caddy + Nginx + WireGuard images
3. Test tunnel reconnect

## Gotchas

- **199th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — TUNNEL-INFRA-KEYS-ALL-EXPOSED-SERVICES**:
  - Holds: WireGuard private keys (both sides), Caddy-Let's-Encrypt account, Nginx proxy config, **keys that control public exposure of every service you route through it**
  - Compromise = full takeover of public exposure
  - **199th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Matures sub-cat: **"tunnel-ingress-controller": 2 tools** (DockFlare Cloudflare + Self-hosted Gateway WireGuard) 🎯 **2-TOOL MILESTONE — MATURED** (distinct underlying tunnel types; DockFlare is CF, SHG is WG)
- **SELF-HOSTED-ALT-TO-SAAS-TUNNELS**:
  - Cloudflare Tunnel / Tailscale Funnel / ngrok alternatives
  - **Alternative-to-commercial-tools-explicit-list: 4 tools** (Usertour+Bugsink+Litlyx+SHG) 🎯 **4-MILESTONE**
- **VPS-REQUIRED-WITH-PUBLIC-IP**:
  - Needs a public VPS
  - Not a zero-infra solution
  - **Recipe convention: "VPS-with-public-IP-prerequisite neutral-signal"**
  - **NEW neutral-signal convention** (Self-hosted Gateway 1st formally)
- **WIREGUARD-KEY-LOSS-RE-PROVISION**:
  - Lose private keys = must re-deploy both sides
  - **Recipe convention: "tunnel-key-loss-full-re-provision-discipline callout"**
  - **NEW recipe convention** (Self-hosted Gateway 1st formally)
- **FOSS-ONLY-NO-CUSTOM-CODE**:
  - Glue-layer only; all components are battle-tested
  - **Recipe convention: "glue-layer-only-no-custom-code positive-signal"**
  - **NEW positive-signal convention** (Self-hosted Gateway 1st formally — exemplary)
- **AUTO-HTTPS-CADDY**:
  - Caddy's automatic-HTTPS feature
  - **Recipe convention: "Caddy-automatic-HTTPS-configuration positive-signal"**
  - **NEW positive-signal convention** (Self-hosted Gateway 1st formally)
- **PROXY-PROTOCOL-REAL-IP**:
  - Real client IP passed-through
  - **Recipe convention: "proxy-protocol-real-IP-discipline positive-signal"**
  - **NEW positive-signal convention** (Self-hosted Gateway 1st formally)
- **DOCKER-NETNS-ISOLATION**:
  - Uses Linux netns via Docker for isolation
  - **Recipe convention: "Docker-netns-isolation-for-exposed-services positive-signal"**
  - **NEW positive-signal convention** (Self-hosted Gateway 1st formally)
- **YOUTUBE-SETUP-VIDEO**:
  - Video guide for complex setup
  - **Demo-video-in-README: 2 tools** (SecureAI+SHG) 🎯 **2-MILESTONE**
- **CGNAT-STARLINK-USE-CASE**:
  - Explicit ISP/CGNAT use-case
  - **Recipe convention: "CGNAT-mobile-ISP-use-case-callout positive-signal"**
  - **NEW positive-signal convention** (Self-hosted Gateway 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: hintjen sole-dev + video guide + compose-based + FOSS-only. **185th tool — sole-dev-infra-glue-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + video + FOSS-only + compose + documented use-cases. **191st tool in transparent-maintenance family.**
- **TUNNEL-INGRESS-CATEGORY:**
  - **Self-hosted Gateway** — WireGuard + Caddy + Nginx; self-hosted
  - **DockFlare** — Cloudflare Tunnel orchestrator (b121)
  - **Tailscale Funnel** — commercial
  - **ngrok** — commercial
  - **bore** — Rust; simpler; less featured
  - **frp** — older; mature
- **ALTERNATIVES WORTH KNOWING:**
  - **DockFlare + Cloudflare Tunnel** — if you trust Cloudflare
  - **Tailscale Funnel** — if you already use Tailscale
  - **frp** — if you want mature + simpler glue
  - **Choose SHG if:** you want fully-self-hosted + WireGuard + FOSS-only + auto-HTTPS.
- **PROJECT HEALTH**: active + documented + video + FOSS-only. Strong.

## Links

- Repo: <https://github.com/hintjen/selfhosted-gateway>
- DockFlare (alt, Cloudflare): <https://github.com/ChrispyBacon-dev/DockFlare>
- frp (alt): <https://github.com/fatedier/frp>
- bore (alt): <https://github.com/ekzhang/bore>
