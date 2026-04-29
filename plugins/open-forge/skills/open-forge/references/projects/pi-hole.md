---
name: pi-hole-project
description: Pi-hole recipe for open-forge. EUPL-1.2-licensed network-wide ad blocker — a recursive DNS server (FTL) plus a web admin UI. Installs as a Linux daemon (the classic `curl | bash` installer) or as a Docker container (`pi-hole/docker-pi-hole`). Primary use case is as the DHCP-advertised DNS server on a home LAN — cloud/VPS deploys are uncommon and require DoH-or-WireGuard for client reachability. This recipe covers Docker Compose (upstream-recommended for self-host) and native install.
---

# Pi-hole

EUPL-1.2 network-wide ad blocker. A recursive DNS server (FTL) that filters queries against a blocklist + a web admin UI. Upstream core: <https://github.com/pi-hole/pi-hole>. Docker repo: <https://github.com/pi-hole/docker-pi-hole>. Docs: <https://docs.pi-hole.net/>.

Pi-hole is **v6+ currently** (as of late 2024 / 2025). The v5 → v6 jump rewrote the web UI into FTL's embedded webserver, consolidated config under `/etc/pihole/pihole.toml`, and changed a LOT of env-var names for the Docker image. This recipe targets v6.

**Primary deployment shape = LAN gateway, not cloud.** Pi-hole is designed to be the DNS server your router advertises via DHCP. Cloud/VPS deploys work only if clients reach it via WireGuard/Tailscale/DoT/DoH — exposing port 53 directly to the internet turns the Pi-hole into an open resolver (bad).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`pihole/pihole:latest`) | <https://github.com/pi-hole/docker-pi-hole> · <https://hub.docker.com/r/pihole/pihole> | ✅ Recommended for self-host | Upstream-maintained official image. Most open-forge deploys land here. |
| `docker run` | Same image, no compose | ✅ | Quick test / one-liner. Prefer Compose for persistence + readability. |
| Native install (`curl | bash` AIO) | <https://install.pi-hole.net> (<https://github.com/pi-hole/pi-hole/blob/master/automated%20install/basic-install.sh>) | ✅ | Raspberry Pi / dedicated Linux box. Installs as systemd services. |
| Build from source | `pi-hole/pi-hole` + `pi-hole/FTL` | ✅ | Dev. Not a user-facing install method. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `native` | Drives section used. |
| preflight | "Where will Pi-hole run?" | `AskUserQuestion`: `LAN (home/lab)` / `VPS (WireGuard/Tailscale)` / `Cloud (public)` | The `Cloud (public)` path triggers warnings + requires DoH/DoT or port-53 firewall restrictions. |
| network | "What's the host/LAN IP of the Pi-hole?" | Free-text | Needed for router DHCP settings. |
| admin | "Web admin password?" | Free-text (sensitive) | Set via `FTLCONF_webserver_api_password` env var on Docker, or prompted during native install. Omit on Docker = random password printed to container logs. |
| admin | "Timezone?" (e.g. `Europe/London`, `America/New_York`) | Free-text | `TZ` env. Affects log timestamps + scheduled blocklist refresh. |
| dns | "Upstream DNS resolvers?" | `AskUserQuestion`: `Cloudflare (1.1.1.1)` / `Google (8.8.8.8)` / `Quad9 (9.9.9.9)` / `Unbound (recursive, advanced)` / `Custom` | Configured in admin UI or via `FTLCONF_dns_upstreams`. |
| dhcp | "Use Pi-hole as DHCP server?" | `AskUserQuestion` | If `Yes`, Pi-hole needs `NET_ADMIN` cap + port `67/udp` exposed, and the LAN router's DHCP must be disabled to avoid conflicts. |
| ports | "Is port 53 already in use on the host?" | Boolean | `systemd-resolved` listens on `:53` on Ubuntu by default — must be disabled or reconfigured before the Docker container can bind. |

## Install — Docker Compose (upstream-recommended)

From upstream's README (`pi-hole/docker-pi-hole` on `master`):

```yaml
# compose.yaml — from pi-hole/docker-pi-hole README
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "80:80/tcp"
      - "443:443/tcp"     # FTL generates a self-signed cert
      # - "67:67/udp"     # Uncomment if using Pi-hole as DHCP server
      # - "123:123/udp"   # Uncomment if using Pi-hole as NTP server
    environment:
      TZ: 'Europe/London'
      FTLCONF_webserver_api_password: 'correct horse battery staple'
      # Required when using Docker's default `bridge` network
      FTLCONF_dns_listeningMode: 'ALL'
    volumes:
      - './etc-pihole:/etc/pihole'
      # Optional — legacy dnsmasq config dir; needed only if migrating from v5
      # - './etc-dnsmasq.d:/etc/dnsmasq.d'
    cap_add:
      - NET_ADMIN       # Required for DHCP server role; safe to leave on
      - SYS_TIME        # Required for NTP server role
      - SYS_NICE        # Optional; better scheduling
    restart: unless-stopped
```

Bring up:

```bash
docker compose up -d
docker compose logs -f pihole
# Initial admin password is printed once on first boot if you didn't set
# FTLCONF_webserver_api_password. Get it with:
docker exec pihole pihole setpassword
# ^ also lets you reset the password anytime.
```

Visit `http://<host-ip>/admin` to open the admin UI.

### Host port 53 conflict

On modern Ubuntu/Debian, `systemd-resolved` binds `127.0.0.53:53` — that does NOT conflict with the container binding `0.0.0.0:53`, BUT any process listening on `*:53` will conflict. Check:

```bash
sudo ss -tulpn | grep ':53 '
```

If something binds `*:53`, disable it. For `systemd-resolved`:

```bash
sudo systemctl disable --now systemd-resolved
# Point /etc/resolv.conf at a real resolver (or at Pi-hole after it's up)
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

### ⚠️ Don't use `--privileged`

Upstream explicitly warns against this on 2022.04+ images (<https://github.com/pi-hole/docker-pi-hole/issues/963#issuecomment-1095602502>). Use the explicit `cap_add` list above.

## Install — Native (`curl | bash` AIO)

Upstream installer lands on a Debian/Ubuntu/Raspbian host:

```bash
# Review the script before running. Upstream repo:
# https://github.com/pi-hole/pi-hole/blob/master/automated%20install/basic-install.sh
curl -sSL https://install.pi-hole.net | bash
```

Interactive TUI prompts for:

- Static IP assignment (Pi-hole STRONGLY recommends a static IP — DHCP lease changes break the LAN's DNS pointer).
- Upstream DNS (Cloudflare / Google / Quad9 / Unbound / custom).
- Blocklist selection (StevenBlack hosts by default).
- Web admin + web server install (yes/yes).
- Logging level.

After install:

```bash
sudo pihole -a -p                  # Set admin password
sudo systemctl status pihole-FTL   # Main DNS+web daemon
sudo pihole -up                    # Update Pi-hole core + FTL + web
sudo pihole status                 # Health check
sudo pihole tailLog                # Live query log
```

## Router configuration (required for LAN-wide ad blocking)

After Pi-hole is reachable at `<host-ip>:53`, point clients at it. Two options:

1. **DHCP option 6 (recommended).** In the router admin UI, change the DHCP "Primary DNS" (and ideally also Secondary DNS) to the Pi-hole's IP. Wait for DHCP lease renewal (or force via `ipconfig /renew` / `sudo dhclient -r` on each client).
2. **Per-device.** Manually set DNS on each device's Wi-Fi settings. Fine for a small deploy; doesn't cover IoT devices that ignore per-device DNS overrides (many "smart" TVs hard-code 8.8.8.8 and bypass Pi-hole entirely).

Power users: use `iptables`/`nftables` DNAT on the router to force-redirect all outbound `:53` traffic through Pi-hole, defeating the hard-coded-DNS IoT evasion. This requires router-OS support (OpenWrt / pfSense / OPNsense) and is out of scope for this recipe.

## Data layout

### Docker

| Path | Content |
|---|---|
| `etc-pihole/` (host) → `/etc/pihole/` (container) | `pihole.toml` (v6 config), `gravity.db` (blocklist DB), `pihole-FTL.db` (query history), TLS certs |
| `etc-dnsmasq.d/` (optional) | Legacy v5 dnsmasq config. Not needed for fresh v6; keep for migrations. |

### Native

| Path | Content |
|---|---|
| `/etc/pihole/` | Same as Docker. |
| `/var/log/pihole/` | FTL and lighttpd logs. |
| `/etc/systemd/system/pihole-FTL.service` | Installed by `basic-install.sh`. |

## Upgrade procedure

### Docker Compose

```bash
docker compose pull
docker compose up -d
docker compose logs -f pihole
```

**v5 → v6 is a major migration.** Read the release notes at <https://github.com/pi-hole/pi-hole/releases> first. All `WEB_*` / `DNSMASQ_*` env vars were renamed to `FTLCONF_*` in v6 — update the compose file BEFORE pulling the new image or the container will boot with default config.

### Native

```bash
sudo pihole -up
```

Updates Pi-hole core, FTL, and the web admin in place. Blocklists are kept. Handles upgrade path across v5 → v6 with prompts.

## Backup & restore

### Docker

```bash
# Backup: stop the container + archive the data volumes
docker compose stop
sudo tar -czf pihole-backup-$(date +%F).tar.gz etc-pihole etc-dnsmasq.d
docker compose start
```

### Native

Use the Teleporter feature in the admin UI (**Settings → Teleporter**) — exports a zip with all settings, blocklists, local DNS records, DHCP leases. Also scriptable via `pihole-FTL --teleporter` from the CLI.

## Gotchas

- **Don't expose port 53 to the public internet.** An open DNS resolver on the internet is used for DNS amplification DDoS attacks — you'll either get abuse complaints from your VPS host or have your IP blackholed. Either keep Pi-hole on a private network (LAN / VPN) or restrict `:53` at the firewall to allowed client IPs.
- **`systemd-resolved` / `named` / `dnsmasq` on host port 53** — check with `ss -tulpn | grep ':53'` before `docker compose up`. Disable the host resolver if it's binding `*:53`.
- **v5 → v6 env-var rename.** `WEB_*` → `FTLCONF_webserver_*`; `DNSMASQ_*` → `FTLCONF_dns_*`. Old compose files silently use defaults after the image update. See <https://docs.pi-hole.net/docker/v6-upgrade/> before pulling v6.
- **DHCP server role = cap `NET_ADMIN` + port 67/udp + router's own DHCP OFF.** Two DHCP servers on one LAN is a bad time — expect IP conflicts, laptops getting random IPs.
- **Static IP is mandatory, not optional.** If the Pi-hole host gets a new IP via DHCP, every client loses DNS until you update the router. Reserve a static lease for the Pi-hole's MAC, or assign a true static IP.
- **Hard-coded DNS evasion.** Chromecasts, smart TVs, IoT devices often hard-code `8.8.8.8` — they bypass Pi-hole even if you change router DNS. Router-level `:53` DNAT is the fix.
- **`--privileged` is NOT supported on 2022.04+ images.** Use explicit `cap_add` (NET_ADMIN, SYS_TIME, SYS_NICE).
- **FTL's self-signed TLS cert.** The admin UI at `:443` ships with a self-signed cert — browsers will warn. Either accept-and-remember, or front with a reverse proxy holding a real Let's Encrypt cert.
- **cron baked into the container.** Blocklists refresh weekly on Sunday morning automatically (per upstream README). No user action needed.
- **Ad-blocking breaks some sites.** When a user complains about a broken site, check Query Log in admin UI — often a tracker-domain on an allow-per-domain basis fixes it. Disabling Pi-hole wholesale for 10 minutes via the UI is the triage tool.

## Links

- Core repo: <https://github.com/pi-hole/pi-hole>
- Docker repo: <https://github.com/pi-hole/docker-pi-hole>
- FTL (the DNS+webserver daemon): <https://github.com/pi-hole/FTL>
- Docs: <https://docs.pi-hole.net/>
- Docker config guide: <https://docs.pi-hole.net/docker/configuration/>
- DHCP guide: <https://docs.pi-hole.net/docker/DHCP/>
- Discourse forums: <https://discourse.pi-hole.net/>
- Releases: <https://github.com/pi-hole/pi-hole/releases>
