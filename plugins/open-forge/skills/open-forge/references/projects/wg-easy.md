---
name: wg-easy-project
description: WireGuard Easy (wg-easy) recipe for open-forge. AGPL-3.0 all-in-one WireGuard VPN server + web UI. Install, create clients, show QR codes, download .conf files — everything through a browser. Upstream image `ghcr.io/wg-easy/wg-easy:15` (12M+ pulls). Major v15 rewrite (vs v14 and older) — new config format + web UI + 2FA + OIDC + one-time share links + client expiration + per-client firewall filtering + Prometheus metrics + IPv6 support + multi-language UI + Gravatar. Single-container: one container brings up the WireGuard kernel module (cap_add NET_ADMIN + SYS_MODULE) and serves the web UI. Needs IP forwarding sysctls + UDP 51820 open on host + NAT rules. Covers the single-container compose, reverse proxy patterns (Caddy/Traefik), podman caveats (NET_RAW), v14→v15 migration, and why it's NOT meant for enterprise (single-admin, no RBAC).
---

# WireGuard Easy (wg-easy)

AGPL-3.0 WireGuard VPN + Web UI in one container. Upstream: <https://github.com/wg-easy/wg-easy>. Docs: <https://wg-easy.github.io/wg-easy/latest/>. Image: `ghcr.io/wg-easy/wg-easy`.

The easiest way to run WireGuard on any Linux host. One container does everything — installs WireGuard, exposes the tunnel on UDP :51820, and runs a web UI (default TCP :51821) where you create clients, show QR codes, download `.conf` files, and see real-time Tx/Rx charts.

## ⚠️ v14 → v15 is a rewrite

wg-easy v15 (`ghcr.io/wg-easy/wg-easy:15`) is a **major rewrite** — different config format, different env vars, new features (OIDC, 2FA, one-time links, per-client firewall, multi-language UI, IPv6). If you're running v14, migrate via: <https://wg-easy.github.io/wg-easy/latest/advanced/migrate/>. Don't blindly change the tag.

Anything below describes v15.

## Features (v15)

- **Full web UI** for WireGuard — list / create / edit / delete clients.
- **QR code display + .conf download** per client.
- **Tx/Rx charts** per connected client.
- **Client expiration** (temporary access).
- **One-time links** (share a config once; it invalidates after download).
- **Per-client firewall filtering** (requires iptables).
- **Prometheus metrics endpoint**.
- **IPv6 + CIDR support**.
- **2FA (TOTP)** for the web UI login.
- **OIDC / SSO** for web UI login (via Authelia/Authentik/Pocket ID).
- **Automatic light / dark mode**.
- **Multilanguage UI**.
- **Gravatar** integration for user avatars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/basic-installation/> | ✅ Recommended | Standard. |
| Docker run | <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/docker-run/> | ✅ | Same image, direct run. |
| Podman | <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/podman-nft/> | ✅ | Rootless requires NET_RAW. |
| Build from source | standard Node+WG build | ✅ | Contributors. |

**NOT supported:**

- `uDocker` / `docker-rootless` (per upstream — WireGuard kernel module requires root).
- Running inside unprivileged LXC without kernel WG support.
- Synology DSM without WG kernel module loaded.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Host OS?" | `AskUserQuestion`: `linux (kernel >=5.6 native WG)` / `other` | WG kernel module required. |
| preflight | "Existing v14 install?" | Boolean | Follow migration guide first if yes. |
| ports | "WireGuard port?" | Default `51820/udp` | Must be open on host firewall + forwarded in NAT. |
| ports | "Web UI port?" | Default `51821/tcp` | Usually behind reverse proxy. |
| dns | "Public host or IP?" | e.g. `vpn.example.com` | Baked into client configs. |
| network | "Client subnet (IPv4)?" | Default `10.8.0.0/24` (v14) — v15 uses `10.42.42.0/24` | Don't overlap with LAN. |
| network | "IPv6?" | `AskUserQuestion`: `enabled (default compose)` / `disabled` | v15 default compose has IPv6 on. |
| auth | "Web UI auth method?" | `AskUserQuestion`: `password (local)` / `oidc (SSO)` | Set during first-run wizard. |
| secrets | "Admin password?" | Strong random | Set in the web UI on first visit. |
| security | "Require 2FA for web UI?" | Boolean | Recommended. TOTP in v15. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none-localhost` | For public Web UI, mandatory. |
| metrics | "Expose Prometheus metrics?" | Boolean | `/metrics` endpoint. |

## Install — Docker Compose (v15, verbatim upstream `docker-compose.yml`)

```yaml
volumes:
  etc_wireguard:

services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:15                # pin major version
    container_name: wg-easy
    networks:
      wg:
        ipv4_address: 10.42.42.42
        ipv6_address: fdcc:ad94:bacf:61a3::2a
    volumes:
      - etc_wireguard:/etc/wireguard
      - /lib/modules:/lib/modules:ro
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
      # - NET_RAW        # ⚠️ Uncomment if using Podman
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=0
      - net.ipv6.conf.all.forwarding=1
      - net.ipv6.conf.default.forwarding=1

networks:
  wg:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 10.42.42.0/24
        - subnet: fdcc:ad94:bacf:61a3::/64
```

Bring up:

```bash
mkdir ~/wg-easy && cd ~/wg-easy
curl -fsSLO https://raw.githubusercontent.com/wg-easy/wg-easy/production/docker-compose.yml
docker compose up -d
# → http://<host>:51821/   (run through setup wizard on first visit)
```

## First-run setup

1. Open `http://<host>:51821/` in a browser.
2. **Setup wizard**:
   - Set admin username + password.
   - Optionally enable OIDC (Authelia / Authentik / Keycloak / Google / etc.).
   - Configure VPN network (CIDR, DNS servers for clients, public endpoint host).
3. Create your first client: Clients → **+ New Client** → name it → download `.conf` or scan QR.
4. Import into your WireGuard client (iOS / Android / macOS / Windows / Linux).
5. Connect.

## Host-level requirements

Regardless of container, the HOST needs:

1. **WireGuard kernel module** — native on Linux kernel 5.6+.
   - Check: `modprobe wireguard && lsmod | grep wireguard`.
   - If missing: `apt install wireguard-dkms` (Debian) / `dnf install kmod-wireguard` (RHEL).
2. **UDP :51820 open on firewall** — `ufw allow 51820/udp`.
3. **UDP :51820 port-forwarded** on your router (if behind NAT) to the wg-easy host.
4. **TCP :51821** should NOT be exposed to the internet without a reverse proxy + TLS (password travels in cleartext otherwise).
5. **IP forwarding** enabled on host — usually the container handles this via sysctls, but `net.ipv4.ip_forward=1` in `/etc/sysctl.conf` as defense-in-depth.

## Reverse proxy (Caddy example)

```caddy
vpn.example.com {
    reverse_proxy wg-easy:51821
}
```

**DON'T proxy UDP :51820** — it's raw WireGuard, goes directly to the container via port mapping. Caddy/Traefik do TCP + HTTP, not UDP.

Traefik example: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/traefik/>.

## OIDC / SSO setup

In web UI → **Admin** → **OIDC** → fill in issuer URL, client ID, client secret. Supported providers: any OIDC-compliant — Authelia / Authentik / Pocket ID / Keycloak / Google / GitHub / Microsoft Entra.

After OIDC is on, password login can be disabled. Great for homelab + corporate setups.

## Podman gotcha

Podman rootful works. For rootless or nftables-based hosts, add `NET_RAW` capability:

```yaml
cap_add:
  - NET_ADMIN
  - SYS_MODULE
  - NET_RAW        # Podman only
```

See <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/podman-nft/>.

## Data layout

| Volume | Content |
|---|---|
| `etc_wireguard:/etc/wireguard` | WireGuard config, server private key, **all client private keys** (v15 stores them to enable QR regeneration), wg-easy's SQLite DB (users, 2FA, OIDC config) |
| `/lib/modules:/lib/modules:ro` | Host's kernel modules (needed to load WG) |

**Backup priority:**

1. **`etc_wireguard` volume** — single source of truth. Losing it = all clients broken (server private key changes → all keypairs need to be regenerated).
2. Consider **snapshotting on every config change** (new client / deleted client) via a `docker exec` hook.
3. Client `.conf` files — users should save their own copies too.

Backup command:

```bash
docker run --rm -v wg-easy_etc_wireguard:/src:ro -v "$PWD":/dst alpine tar czf /dst/wg-easy-backup-$(date +%F).tar.gz -C /src .
```

## Upgrade procedure

**Within v15 (patch releases)**:

```bash
docker compose pull
docker compose up -d
docker compose logs -f wg-easy
```

**v14 → v15**: STOP. Read <https://wg-easy.github.io/wg-easy/latest/advanced/migrate/> — config format changed; requires manual migration. Breaking.

## Gotchas

- **AGPL-3.0 license.** If you modify wg-easy and offer it as a network service, you must provide source to users.
- **v15 is a rewrite — not backward-compatible with v14 configs.** Don't bump the image tag blindly.
- **Web UI password defaults to no auth** until first-run wizard. DON'T expose :51821 to internet before setup wizard is complete.
- **All client private keys are stored on the server** (v15 stores them to regenerate QR codes / share links). If wg-easy is compromised, all clients' tunnels are compromised. By design — this is the UX trade-off. For higher security, use vanilla WireGuard + manual key distribution.
- **UDP :51820 NAT traversal** — most ISPs allow outbound UDP; inbound UDP requires port-forward on your router. Home setups without port-forward will need alternatives (WireGuard on a VPS + host as "client" → relay).
- **`SYS_MODULE` capability is unusual** for containers — it lets the container load kernel modules. Required because the container must ensure the WG module is loaded. If host has it pre-loaded, you could in theory drop `SYS_MODULE`, but the compose default includes it.
- **IPv6 enabled by default in v15 compose** — if your host doesn't have IPv6 networking, drop the IPv6 sysctls + network subnet, or clients will see noise.
- **Default subnet `10.42.42.0/24`** in v15 — if this overlaps your LAN or Tailscale/Headscale subnet, change in setup wizard.
- **Only one admin user in local-auth mode.** Multi-admin needs OIDC + group mapping.
- **OIDC setup** requires re-reading your provider's docs for the exact claim names (email, groups). wg-easy's admin-group mapping is optional but useful.
- **Per-client firewall filtering** requires iptables on the HOST (not just inside container). RouterOS/nftables may not honor all rules.
- **Client expiration** silently revokes — no email/webhook notification yet. You'll see them drop off.
- **One-time links** expire on first download. If the user's download fails mid-way, they'll ask for another — easy to generate in the UI.
- **Mobile WireGuard app** on iOS doesn't support IPv6-only VPNs on some iOS versions — stick to dual-stack.
- **NAT on the wg-easy host**: the container uses iptables NAT to masquerade client traffic. Verify with `iptables -t nat -L` inside container.
- **Prometheus `/metrics`** requires an auth header in v15 — check docs for the token header name.
- **Synology / unRAID users** — host kernel often LACKS WireGuard module. Install wg module via community package before running wg-easy.
- **Raspberry Pi 4 / 5** — stock Raspberry Pi OS kernel has wireguard module since 2021. Works fine.
- **Running wg-easy inside an LXC container in Proxmox** — LXC often blocks loading kernel modules; either load `wireguard` on the Proxmox host OR use a VM instead.
- **`legacy-iptables` vs `nftables`** mismatch between host + container is a common bug source — mount `/etc/iptables:/etc/iptables` or align.
- **Client DNS** — wg-easy clients route DNS through the VPN. Default DNS = `1.1.1.1` + `1.0.0.1`; change in setup wizard if you want clients to use your local Pi-hole / AdGuard Home.
- **AdGuard + wg-easy** is a classic combo — clients VPN in, DNS goes to AdGuard, ads blocked network-wide.
- **Comparison**: wg-easy = user-friendly WG UI. `wg-quick` CLI = barebones official. Tailscale/Headscale = mesh VPN with more features (relay, ACLs, MagicDNS) but not pure WireGuard. Netbird/FireZone = enterprise-grade WG meshes.
- **Not suitable for large deployments** — single-admin, no RBAC, no audit log. For 100+ users, use FireZone or Netbird.

## Links

- Upstream repo: <https://github.com/wg-easy/wg-easy>
- Docs site: <https://wg-easy.github.io/wg-easy/latest/>
- Getting started: <https://wg-easy.github.io/wg-easy/latest/getting-started/>
- Basic installation: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/basic-installation/>
- Caddy reverse proxy: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/caddy/>
- Traefik reverse proxy: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/traefik/>
- Podman: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/podman-nft/>
- AdGuard Home integration: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/adguard/>
- v14 → v15 migration: <https://wg-easy.github.io/wg-easy/latest/advanced/migrate/>
- Docker image: <https://github.com/wg-easy/wg-easy/pkgs/container/wg-easy>
- Releases: <https://github.com/wg-easy/wg-easy/releases>
- Compose file (latest): <https://github.com/wg-easy/wg-easy/blob/production/docker-compose.yml>
- WireGuard upstream: <https://www.wireguard.com>
- Comparison: FireZone <https://www.firezone.dev>, Netbird <https://netbird.io>, Tailscale <https://tailscale.com>
