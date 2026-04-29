---
name: adguard-home-project
description: AdGuard Home recipe for open-forge. GPL-3.0 network-wide ads and trackers blocking DNS server — the Pi-hole alternative from AdGuard. Single Go binary + web UI. Acts as a recursive / forwarding DNS server with blocklists, DHCP server, parental controls, per-client settings, DoH/DoT/DoQ upstream AND downstream (so your phones can use encrypted DNS to your home server). Covers the official Docker image, bare-metal install via upstream's `install.sh`, Snap, network-level deployment (router vs per-device), DHCP integration, and the security-sensitive port 53 binding considerations.
---

# AdGuard Home

GPL-3.0 network-wide ads + trackers blocking DNS server. Upstream: <https://github.com/AdguardTeam/AdGuardHome>. Docs: <https://adguard-dns.io/kb/adguard-home/getting-started/>. Docker Hub: <https://hub.docker.com/r/adguard/adguardhome>.

Single Go binary (~30MB) + browser UI. Operates as a DNS server that re-routes tracking / ad / malware domains to a "black hole" (NXDOMAIN or a null IP), so devices on your network cannot connect to those hosts at all. Plus:

- **Blocklist management:** subscribe to hosts-format lists (EasyList, OISD, StevenBlack, etc.) with auto-update
- **Per-client rules:** different blocking profiles for kids' devices vs adults vs IoT
- **Encrypted DNS for clients:** serve DoH, DoT, DoQ to your devices (so "what you're browsing" is hidden from your ISP even without a VPN)
- **DNSSEC validation**
- **DHCP server** (optional replacement for your router's)
- **Safe Browsing, Safe Search, Parental Control** (Google/YouTube/Bing etc.)
- **Stats + query log UI**

## AdGuard Home vs Pi-hole

| | AdGuard Home | Pi-hole |
|---|---|---|
| Language | Go (single binary) | PHP + dnsmasq |
| DoH/DoT/DoQ server | ✅ Built-in | ❌ Needs extras |
| DoH/DoT upstream | ✅ Built-in | ❌ Needs extras |
| Blocklist UI | ✅ | ✅ |
| DHCP | ✅ Optional | ✅ Optional |
| Parental / Safe Search | ✅ Built-in | ❌ Needs extras |
| Per-client rules | ✅ | Limited |
| Query log | ✅ | ✅ |
| Hardware | Any (Pi / VPS / any Linux) | Any |
| Maturity | Newer (2018+) | Older (2014+) |

Both are excellent. AdGuard Home wins on out-of-box encrypted DNS + per-client rules; Pi-hole has a more mature ecosystem and a bit more community tooling. For a new deploy, AdGuard Home is the simpler path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`adguard/adguardhome`) | Docker Hub | ✅ Recommended | Most self-hosters. |
| `install.sh` (bare metal) | <https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh> | ✅ | Native systemd on Linux/FreeBSD. Handy on a Raspberry Pi. |
| Snap Store | `snap install adguard-home` | ✅ | Ubuntu / Snap-friendly distros. |
| Precompiled binary | <https://github.com/AdguardTeam/AdGuardHome/releases> | ✅ | Manual install. |
| Build from source (Go) | `make build` | ✅ | Contributors / custom. |
| Home Assistant Add-on | <https://github.com/hassio-addons/addon-adguard-home> | ⚠️ Community | HA users. Not first-party but well-maintained. |
| Proxmox VE helper script | community-scripts.github.io | ⚠️ 3rd party | Quick LXC on Proxmox. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `install-script` / `snap` | Drives section. |
| preflight | "Is port 53 already used on this host? (common culprits: systemd-resolved, dnsmasq, existing DNS server)" | `AskUserQuestion` | **CRITICAL** — port 53 MUST be free or AdGuard cannot bind. |
| network | "Serve which network?" | Free-text (e.g. `192.168.1.0/24`) | Informational for docs; AdGuard will bind `0.0.0.0:53` by default. |
| network | "Use DHCP integration?" | `AskUserQuestion` | If yes, **disable your router's DHCP first** OR enable only on a test subnet. Two DHCP servers on the same LAN = broken network. |
| admin | "Initial admin username + password?" | Free-text (sensitive) | Set on first-run wizard via the web UI (no bootstrap env var). |
| ports | "Web UI port?" | Default `3000` (setup) / `80` (production). | `:3000` is the setup wizard port; after first config, can switch to `:80` or any other port. |
| dns | "Public hostname for DoH/DoT?" | Free-text, optional | Only if you want encrypted DNS from outside your LAN. Needs a valid cert (Let's Encrypt). |
| tls | "Cert source?" | `AskUserQuestion`: `letsencrypt-via-proxy` / `upload-cert` / `none-lan-only` | AdGuard has built-in TLS but managing renewal manually is painful — use a reverse proxy for anything public. |

## Install — Docker (recommended)

```yaml
# compose.yaml
services:
  adguardhome:
    image: adguard/adguardhome:latest    # pin to a specific tag in prod, e.g. v0.107.60
    container_name: adguardhome
    restart: unless-stopped
    network_mode: host                   # simplest — binds port 53 on the host directly
    volumes:
      - ./work:/opt/adguardhome/work
      - ./conf:/opt/adguardhome/conf
    # If you prefer explicit port mapping instead of host networking,
    # replace network_mode: host with:
    # ports:
    #   - "53:53/tcp"
    #   - "53:53/udp"
    #   - "3000:3000/tcp"   # setup wizard
    #   - "80:80/tcp"        # web UI after setup
    #   - "443:443/tcp"      # DoH
    #   - "853:853/tcp"      # DoT
    #   - "784:784/udp"      # DoQ
    #   - "67:67/udp"        # DHCP (only if you're running DHCP here)
```

**Host networking is strongly recommended** unless you specifically want port isolation — AdGuard wants real client IP addresses for per-client rules, and `network_mode: bridge` masks all clients as the Docker bridge gateway IP. Use `host` and all clients show up correctly.

### First-run setup

1. Start the container: `docker compose up -d`.
2. Open `http://<host>:3000/` → you get the setup wizard.
3. Pick:
   - Web UI port (default 80, or keep 3000, or any other)
   - DNS server port (default 53)
   - Admin username + password
4. Finish the wizard. UI moves to the new port.
5. Point clients / router at this host's IP as their DNS.

## Install — `install.sh` (bare metal Linux)

```bash
# One-line upstream install
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v
```

Flags:

- `-v` — verbose
- `-r` — reinstall (re-download latest, preserve config)
- `-u` — uninstall
- `-c stable` / `-c beta` / `-c edge` — pick a channel

Installs to `/opt/AdGuardHome/` + systemd unit `AdGuardHome`.

Before running, **stop anything using port 53:**

```bash
# Common culprit on Ubuntu/Debian: systemd-resolved binds 127.0.0.53:53
sudo systemctl disable --now systemd-resolved
sudo sed -i 's/^#DNS=.*/DNS=1.1.1.1 9.9.9.9/' /etc/systemd/resolved.conf || true
sudo ln -sfn /run/systemd/resolve/resolv.conf /etc/resolv.conf    # if you're NOT keeping resolved
# Alternative: keep resolved, just turn OFF its stub listener:
# sudo sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf
# sudo systemctl restart systemd-resolved
```

Verify port 53 is free:

```bash
sudo ss -tulpn | grep ':53 '     # should show nothing before installing
```

Start/stop:

```bash
sudo /opt/AdGuardHome/AdGuardHome -s start
sudo /opt/AdGuardHome/AdGuardHome -s status
sudo /opt/AdGuardHome/AdGuardHome -s stop
```

Config lives at `/opt/AdGuardHome/AdGuardHome.yaml`.

## Install — Snap

```bash
sudo snap install adguard-home
# UI: http://<host>:3000/
```

Note: Snap may conflict with the Ubuntu stub resolver; see the systemd-resolved tweak above.

## Pointing clients at AdGuard Home

Three approaches, from best to worst:

1. **Router DHCP → advertise AdGuard's IP as DNS.** Every device on the LAN automatically uses AdGuard. Requires admin on the router.
2. **AdGuard's built-in DHCP.** Disable your router's DHCP, let AdGuard hand out leases + DNS. More control (per-client rules via IP reservation), but the AdGuard host becomes a single point of failure.
3. **Per-device DNS.** Manually set DNS on each device. Okay for a couple of devices but doesn't scale and doesn't help IoT devices that ignore DHCP-provided DNS.

### Phones / laptops on the go

Enable DoH/DoT/DoQ in AdGuard + open the relevant ports to the internet (behind a reverse proxy for 443/DoH, direct for 853/DoT if you want). Then in iOS/Android/Firefox/Chrome set your encrypted DNS resolver to `https://dns.yourdomain.com/dns-query`. Your phone's DNS queries now go through AdGuard from anywhere.

## Configuration (`AdGuardHome.yaml`)

After first-run wizard, everything lives in a single YAML file (Docker: `./conf/AdGuardHome.yaml`). Rough structure:

```yaml
bind_host: 0.0.0.0
bind_port: 80
beta_bind_port: 0
users:
  - name: admin
    password: <bcrypted>
dns:
  bind_hosts: [0.0.0.0]
  port: 53
  upstream_dns:
    - https://dns.quad9.net/dns-query      # DoH upstream
    - https://dns.cloudflare.com/dns-query
  bootstrap_dns: [9.9.9.10, 1.1.1.1]
  filtering_enabled: true
  parental_enabled: false
  safebrowsing_enabled: true
  enable_dnssec: true
filters:
  - url: https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt
    name: AdGuard DNS filter
    enabled: true
  - url: https://someonewhocares.org/hosts/zero/hosts
    name: Dan Pollock
    enabled: true
tls:
  enabled: false
  port_https: 443
  port_dns_over_tls: 853
  port_dns_over_quic: 784
  certificate_path: /opt/adguardhome/conf/cert.pem
  private_key_path: /opt/adguardhome/conf/key.pem
dhcp:
  enabled: false
```

**Editing by hand:** safe while AdGuard is stopped. While running, use the web UI (it re-writes the YAML).

## Data layout

| Path | Content |
|---|---|
| `./work/` (Docker) or `/opt/AdGuardHome/data/` (bare metal) | Query log, stats, blocklists cache. Can be GB-scale. |
| `./conf/AdGuardHome.yaml` | Config file (users, upstreams, filters, DHCP). |
| `./conf/cert.pem` + `key.pem` | TLS cert (if you uploaded one). |

**Backup** = `conf/AdGuardHome.yaml`. That's 95% of your work. `work/` is regenerable (blocklists re-download, stats restart).

## Upgrade procedure

### Docker

```bash
docker compose pull
docker compose up -d
docker compose logs -f adguardhome
```

### `install.sh`

```bash
sudo /opt/AdGuardHome/AdGuardHome -s stop
curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -r
```

Or via the web UI: **Settings → General Settings → Check for updates → Update now.** Safest path — handles migrations.

### Snap

```bash
sudo snap refresh adguard-home
```

## Reverse proxy (Caddy) for DoH

```caddy
dns.example.com {
    reverse_proxy 127.0.0.1:443 {
        transport http {
            tls
            tls_insecure_skip_verify      # AdGuard's internal cert is self-signed if no uploaded cert
        }
    }
}
```

Simpler: disable TLS inside AdGuard (port 443 off), let Caddy terminate TLS and proxy `/dns-query` to AdGuard's HTTP interface. See <https://adguard-dns.io/kb/adguard-home/encryption/> for upstream guidance.

## Gotchas

- **Port 53 conflicts.** The #1 failure. systemd-resolved, dnsmasq, libvirt's dnsmasq, Docker's embedded DNS — all can own port 53. Check `ss -tulpn | grep ':53 '` before installing. If systemd-resolved is the issue, set `DNSStubListener=no` in `/etc/systemd/resolved.conf` and restart it rather than disabling resolved entirely (disabling breaks name resolution for services that use it).
- **Docker `bridge` networking loses client IPs.** All queries appear to come from the Docker bridge gateway (e.g. 172.17.0.1), breaking per-client rules. Use `network_mode: host` OR configure `macvlan` so the container has its own LAN IP.
- **DHCP conflict.** Two DHCP servers on one LAN = randomly broken devices. If enabling AdGuard's DHCP, turn off your router's FIRST. Test on a small subnet before committing.
- **First-run wizard is un-authenticated.** Between container start and finishing the setup wizard, ANYONE who reaches port 3000 can claim your instance. Firewall that port until you've completed setup, or do the setup immediately.
- **Blocklist ambiguity = wrongly blocked sites.** Aggressive lists (e.g. StevenBlack's "gambling + porn" unified) will false-positive on legit services. Start with one or two moderate lists (AdGuard's own default + OISD), add more gradually.
- **Query log contains PII.** Every DNS query from every device is logged by default, retained 90 days. This is a surveillance-of-your-household dataset. Review retention in **Settings → General Settings → Statistics retention** and **Query log retention**. For shared households, consider turning off query log or shortening retention.
- **Safe Browsing sends hashes of domains to AdGuard's SB service.** Opt-in; disabled by default on many installs. Don't enable if you object to any queries leaving your network. The parental control check does the same.
- **`upstream_dns` default = AdGuard's own DNS.** Out of the box, your queries go to AdGuard Software (the company). Review + change if you don't want that. Common alternatives: Quad9 (`https://dns.quad9.net/dns-query`), Cloudflare (`1.1.1.1`), Google (`8.8.8.8`).
- **DoH behind a reverse proxy requires passing the full URL path + no path rewriting.** `/dns-query` is the standard endpoint. Don't strip it.
- **DNSSEC can break things.** Some domains have broken DNSSEC signatures. Enabling `enable_dnssec: true` can make these unreachable. Most users can leave it on; if you see weird "no such name" errors, try disabling to rule it out.
- **"Apply to all clients" scope confusion.** Blocking rules can be global OR per-client (by IP, MAC, or device name). Verify the scope before saving — it's easy to accidentally create a global rule that blocks one device's issue for everyone.
- **No HA / no clustering.** Single instance. If it dies, your LAN loses DNS. Options: run a secondary instance as a warm standby (via `rsync` of config); or configure clients with 2 DNS servers (primary: AdGuard, secondary: fallback like `1.1.1.1`) — but the OS will use cached results from the failing resolver briefly, causing intermittent issues.
- **Arm64 / Pi version is identical in features** but old Pi Zero W with SD card can fill query log storage within weeks. Set short retention if using a Pi with small storage.

## Links

- Upstream repo: <https://github.com/AdguardTeam/AdGuardHome>
- Docs wiki: <https://adguard-dns.io/kb/adguard-home/>
- Getting started: <https://adguard-dns.io/kb/adguard-home/getting-started/>
- Encryption setup: <https://adguard-dns.io/kb/adguard-home/encryption/>
- Docker Hub: <https://hub.docker.com/r/adguard/adguardhome>
- Releases: <https://github.com/AdguardTeam/AdGuardHome/releases>
- Install script: <https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh>
- Blocklist registry: <https://adguard-dns.io/kb/general/dns-filtering-syntax/>
- API reference: <https://github.com/AdguardTeam/AdGuardHome/tree/master/openapi>
- Subreddit: <https://www.reddit.com/r/Adguard/>
