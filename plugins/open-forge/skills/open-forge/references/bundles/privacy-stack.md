---
name: privacy-stack-bundle
description: Privacy-stack bundle for open-forge — pairs Pi-hole (network-wide ad/tracker blocking) + Vaultwarden (private password vault) + Headscale (self-hosted Tailscale control plane) + wg-easy (WireGuard config UI) into a single home-network privacy + remote-access stack. Designed for low-cost always-on hosts (Raspberry Pi 4/5, low-end VPS, NUC). Targets the "I want to stop leaking data to ad networks AND own my passwords AND reach my home network from anywhere" user.
---

# Privacy-stack bundle

> **Goal:** Stop leaking to ad networks at the DNS layer, own your password vault, and reach your home-network services from anywhere — all on one always-on box.

## What you get

| Service | Port | Role |
|---|---|---|
| **Pi-hole** | `53` (DNS), `80` (web UI) | Network-wide DNS-level ad / tracker / malware blocking. Every device on your network points its DNS at Pi-hole; Pi-hole returns NXDOMAIN for the bad stuff. |
| **Vaultwarden** | `8080` (or your reverse-proxy hostname) | Self-hosted Bitwarden-API-compatible password vault. Bitwarden clients (browser / mobile / desktop) talk to it instead of Bitwarden's cloud. |
| **Headscale** | `8443` (control plane), `3478` (STUN) | Self-hosted Tailscale control server. Tailscale clients on your devices form a mesh VPN coordinated by your Headscale, not Tailscale Inc.'s servers. |
| **wg-easy** | `51820/udp` (WireGuard), `51821` (web UI) | Plain WireGuard alternative for users who'd rather not run a full Tailscale-shaped mesh. Web UI for adding peers + downloading their configs. |

The bundle ships **both** Headscale and wg-easy — they're alternatives, not complements. Pick one based on your needs (see *Choosing Headscale vs wg-easy* below). Most users want one or the other; deploying both adds complexity without value.

## When to pick this bundle

- You have an **always-on host on your home network** — a Raspberry Pi 4/5, a Mini PC / NUC, a NAS, an old laptop, or a low-cost VPS (Hetzner CX11, Oracle Always-Free ARM).
- You want network-wide DNS-level blocking rather than per-device ad blockers.
- You're tired of trusting Bitwarden / 1Password / LastPass with your password vault and want to host it yourself.
- You want to reach your home-network services (Plex, Home Assistant, NAS) from anywhere without exposing them to the public internet.

## When NOT to pick this bundle

- **You can't host a stable always-on box.** Pi-hole and the VPN need 99%+ uptime to be useful — they're not "spin up when you need it" services.
- **You're on a metered home connection.** Pi-hole's DNS traffic is negligible, but the VPN endpoint serves all your remote traffic — bandwidth costs add up.
- **Your home network is behind CGNAT.** Vaultwarden + Headscale + wg-easy all need *something* reachable from the internet (a public IP, a Cloudflare Tunnel, or a relay-equipped Headscale on a VPS). If you only have CGNAT and no tunnel, the bundle's remote-access half doesn't work.

## Recommended infra / runtime

| Choice | Default | Notes |
|---|---|---|
| **Where** | Raspberry Pi 4/5 (4+ GB RAM) | Or low-cost VPS (Hetzner CX11 €4/mo) if you don't have a Pi. The bundle is undemanding — works fine on any 64-bit ARM or x86_64 host. |
| **How** | Docker Compose | All services in one Compose project. Native installs work too (Pi-hole has a one-line installer; Vaultwarden has community Helm charts; etc.) — see per-recipe pages. |
| **Storage** | ~5 GB suffices for years | Pi-hole's query log + Vaultwarden's SQLite + Headscale's PostgreSQL grow slowly |

## Constituent recipes (load in this order)

1. **`references/projects/pi-hole.md`** — DNS-layer foundation. Has to come up first if anything else on the host wants to resolve through it.
2. **`references/projects/vaultwarden.md`** — password vault. Independent of the others; can be added at any time.
3. **`references/projects/headscale.md`** — Tailscale control server. **Pick this OR wg-easy, not both.**
4. **`references/projects/wg-easy.md`** — WireGuard UI. **Pick this OR Headscale.**

Each recipe's own gotchas, config knobs, and TODOs apply.

## Choosing Headscale vs wg-easy

| | Headscale | wg-easy |
|---|---|---|
| **Mental model** | Tailscale-shaped: nodes form a mesh, NAT-traversal mostly automatic, ACLs per-tag | Classic VPN: server with peers, peers route all traffic through server (or split-tunnel) |
| **Client setup** | `tailscale up --login-server=https://headscale.your.domain` on each device | Download config from web UI, import into WireGuard app |
| **Mobile UX** | Tailscale apps are polished | WireGuard apps are functional |
| **NAT traversal** | Built-in DERP relays handle CGNAT-to-CGNAT | None — both ends need at least one to be reachable |
| **Best for** | Many devices, multi-OS, want zero-config-after-setup | A few devices, want simple plain-WireGuard, prefer fewer moving parts |

Default recommendation: **Headscale** if you have 4+ devices and want it to "just work" across mobile + laptop + desktop. **wg-easy** if you have 1-2 laptops and want the simplest possible setup.

## Cross-software wiring

### Pi-hole as network DNS

After install, set Pi-hole as the DNS server for your network:

- **Best**: configure your router's DHCP to hand out `<Pi-hole IP>` as the DNS server. Every device automatically uses it.
- **Per-device fallback**: set DNS manually on each device pointing at Pi-hole. Tedious but works.
- **Bypass for the host running the bundle**: if the host itself uses Pi-hole for DNS, an outage in the Pi-hole container takes down DNS for the whole bundle, which can cascade. Set the host's `/etc/resolv.conf` to a public resolver (`1.1.1.1`, `9.9.9.9`) so the host can always resolve, even if Pi-hole is down.

### Vaultwarden via reverse proxy + TLS

Bitwarden mobile clients **require HTTPS** to connect. Front Vaultwarden with Caddy / Traefik / nginx + Let's Encrypt; bare HTTP works only for development. See `references/modules/tls-letsencrypt.md`.

If your Pi is on a private home network without a public hostname, the cleanest path is **Cloudflare Tunnel** (no port-forwarding required, Cloudflare provides the public hostname + TLS). See `references/modules/tunnels.md`.

### Headscale ⇄ Tailscale clients

When you sign into the Tailscale app, point it at your Headscale instead of the default Tailscale control server:

```bash
# On a Linux client
tailscale up --login-server=https://headscale.your.domain --auth-key=<key from headscale>

# On macOS / Windows / iOS / Android — the official Tailscale apps support custom login servers
# but the UI for setting one is buried; see `headscale.md` for current per-platform instructions
```

### wg-easy peers

wg-easy generates per-peer WireGuard configs through its web UI; download + import to each device. No automation needed.

## Combined inputs

| Phase | Prompt | Source recipe |
|---|---|---|
| preflight | Where? | bundle (default: Raspberry Pi or low-cost VPS) |
| preflight | How? | bundle (default: Docker Compose for all four) |
| preflight | Pick Headscale or wg-easy? | bundle (see decision table above) |
| install (pi-hole) | Admin password? Upstream DNS? | `pi-hole.md` |
| install (vaultwarden) | Admin token? Public hostname for HTTPS? | `vaultwarden.md` |
| install (headscale) | Public domain? Magic-DNS suffix? | `headscale.md` (only if Headscale picked) |
| install (wg-easy) | WireGuard public endpoint (host:port)? Web UI password? | `wg-easy.md` (only if wg-easy picked) |
| network | DHCP DNS update on router? | bundle |

## Verification

| Check | How | Expected |
|---|---|---|
| Pi-hole blocks ads | Browse to `http://doubleclick.net` from a device using Pi-hole | NXDOMAIN / 0.0.0.0 |
| Pi-hole stats populate | Pi-hole web UI → top blocked domains | List grows within ~10 min of network use |
| Vaultwarden mobile login | Bitwarden mobile app → log in to your Vaultwarden URL | Successfully syncs vault |
| Headscale mesh | `tailscale status` from two enrolled devices | Each sees the other as `online` |
| wg-easy peer | Connect from a remote device + `curl ifconfig.me` | Returns the bundle host's public IP, not the remote device's |

## Bundle gotchas

- **Don't enroll the bundle host itself in Pi-hole DNS.** Set the host's `/etc/resolv.conf` to a public resolver — otherwise a Pi-hole container restart cascades into "the host can't resolve anything, including how to talk to Docker Hub to recover."
- **Vaultwarden on plain HTTP works for desktop browser-extension testing only.** Mobile / desktop apps require HTTPS. Don't deploy Vaultwarden without TLS unless you're fine with browser-only access.
- **Headscale and Tailscale's official cloud are mutually exclusive per-device.** A device can be in your Headscale mesh OR Tailscale's cloud, not both. If you previously used Tailscale cloud, log out before joining Headscale.
- **wg-easy stores the WireGuard private keys server-side.** This is convenient (one click → download config) but it means a compromised wg-easy host means all peer keys are compromised. Rotate after any host-compromise event.
- **Pi-hole + Headscale port conflict** — Pi-hole's web UI default is port 80; Headscale's default web UI overlaps in some configs. Check the per-recipe port maps before bringing both up.
- **CGNAT breaks the remote-access half.** If you're behind CGNAT and don't have a public-IP host or Cloudflare Tunnel, neither Headscale nor wg-easy will work for inbound connections. The bundle's Pi-hole and Vaultwarden halves still work locally.
- **DNS-over-HTTPS on devices bypasses Pi-hole.** Newer browsers default to DoH using their own resolvers (Cloudflare, Google), which routes around Pi-hole. Disable per-browser, or use Pi-hole's DoH-block lists, or run Pi-hole + a DoH server like `cloudflared` upstream.

## Backup

Per `references/modules/backups.md`:

| Service | Paths | Notes |
|---|---|---|
| Pi-hole | `/etc/pihole/`, `/etc/dnsmasq.d/` | Mostly regenerable from blocklists, but custom rules + admin password worth preserving |
| Vaultwarden | `/data/db.sqlite3` (SQLite mode) or backed Postgres, `/data/attachments/`, `/data/sends/`, `/data/rsa_key.*` | **Mandatory** — losing the vault loses everyone's passwords. Plus the `rsa_key.*` files are needed to decrypt restored data. |
| Headscale | `/var/lib/headscale/db.sqlite` or backed Postgres, `/etc/headscale/config.yaml`, signing keys | Preserves the mesh; without it, all enrolled clients have to re-enroll |
| wg-easy | `wg-easy_data` volume | Stores all peer keys + configs |

For Vaultwarden specifically, prefer the upstream-recommended `vaultwarden_backup.sh` script (community-maintained but well-trodden) over generic restic — it knows about the `rsa_key.*` decryption-required files.

## Deprovision

```bash
cd /opt/privacy-stack
docker compose down -v
```

⚠️ `-v` drops all volumes — that deletes your vault, blocklists, and mesh-coordination state. Backup first.

Plus: revert your router's DHCP to hand out the previous DNS server (otherwise your network has no DNS until you do).

## TODO — verify on subsequent deployments

- [ ] First end-to-end deploy on a Raspberry Pi 5 — verify Compose memory pressure with all four services running.
- [ ] Document the Cloudflare Tunnel pairing more thoroughly — most home users will need it for the Vaultwarden HTTPS exposure.
- [ ] Add a "Headscale on a VPS, peers at home" deployment shape — sometimes people want the control plane in the cloud and the peers at home.
- [ ] Verify the DoH-bypass mitigation steps work on current Chrome / Firefox / Edge / Safari.
- [ ] First user feedback: is the wg-easy/Headscale either-or framing right, or do some users actually want both for different purposes?
