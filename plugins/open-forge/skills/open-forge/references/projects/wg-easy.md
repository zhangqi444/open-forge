---
name: wg-easy
description: WireGuard Easy (wg-easy) recipe for open-forge. All-in-one WireGuard VPN + web UI in a single Docker container. Easiest way to self-host WireGuard with client management.
---

# WireGuard Easy (wg-easy)

All-in-one WireGuard VPN server + web management UI in a single Docker container. Manage clients, generate QR codes, view connection stats, and download config files — all from a browser. 12M+ Docker image pulls. Upstream: <https://github.com/wg-easy/wg-easy>. Docs: <https://wg-easy.github.io/wg-easy/latest/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Standalone Docker | Quick single-command start |
| Podman | Rootless container alternative |

## Requirements

- Linux host with kernel ≥ 5.6 (WireGuard built-in) or kernel module installed
- Public IP or domain for VPN endpoint
- UDP port 51820 open on firewall

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Public IP or domain for the VPN server?" | Set as `WG_HOST` — clients use this to connect |
| preflight | "Web UI admin password?" | Set as `PASSWORD_HASH` (bcrypt) or `PASSWORD` (plain, deprecated) |
| preflight | "VPN subnet?" | Default `10.8.0.0/24` via `WG_DEFAULT_ADDRESS` |
| preflight | "Default DNS for VPN clients?" | Default `1.1.1.1` via `WG_DEFAULT_DNS` |

## Docker Compose example

```yaml
version: "3.9"
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:latest
    container_name: wg-easy
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    ports:
      - "51820:51820/udp"   # WireGuard
      - "51821:51821/tcp"   # Web UI
    volumes:
      - wg-data:/etc/wireguard
    environment:
      WG_HOST: vpn.example.com          # your public IP or domain
      PASSWORD_HASH: $$2b$$12$$...       # bcrypt hash; generate with: docker run --rm ghcr.io/wg-easy/wg-easy wgpw yourpassword
      WG_DEFAULT_ADDRESS: 10.8.0.x
      WG_DEFAULT_DNS: 1.1.1.1
      WG_MTU: 1420
      UI_TRAFFIC_STATS: "true"

volumes:
  wg-data:
```

> **Generate password hash:**
> ```bash
> docker run --rm ghcr.io/wg-easy/wg-easy wgpw 'your-password'
> ```
> Use the output as `PASSWORD_HASH` — note the `$$` escaping in Docker Compose.

## Software-layer concerns

- Container image: `ghcr.io/wg-easy/wg-easy` (GHCR, not Docker Hub)
- WireGuard UDP port: `51820` — must be open on host firewall and forwarded from router
- Web UI port: `51821` (HTTP) — put behind Caddy/NGINX with TLS for production
- `NET_ADMIN` capability and `ip_forward` sysctl are required for WireGuard routing
- Data dir `/etc/wireguard` — persist this volume; contains server keys and client configs
- Supports 2FA, per-client firewall rules (requires iptables), client expiration

## Upgrade procedure

1. Pull new image: `docker compose pull wg-easy`
2. Restart: `docker compose up -d wg-easy`
3. Client configs don't change on upgrade; server keys persist in volume

> ⚠️ If upgrading from an old version (pre-v14), follow the [migration guide](https://wg-easy.github.io/wg-easy/latest/advanced/migrate/).

## Gotchas

- `WG_HOST` must be the **public** IP or domain — clients need to reach this address from the internet
- `PASSWORD_HASH` uses bcrypt with `$$` escaping in Compose (each `$` → `$$`); plain `PASSWORD` still works but deprecated
- Web UI on port 51821 is plain HTTP — always put behind TLS reverse proxy before exposing
- `ip_forward` sysctl must be set; without it WireGuard traffic won't route between interfaces
- Image is on **GHCR**, not Docker Hub

## Links

- GitHub: <https://github.com/wg-easy/wg-easy>
- Docs: <https://wg-easy.github.io/wg-easy/latest/>
- Basic installation guide: <https://wg-easy.github.io/wg-easy/latest/examples/tutorials/basic-installation/>
- GHCR: <https://github.com/wg-easy/wg-easy/pkgs/container/wg-easy>
