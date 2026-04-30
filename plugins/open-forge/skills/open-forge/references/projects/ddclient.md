---
name: ddclient
description: "Perl client for updating dynamic DNS. Supports 40+ DDNS providers (Cloudflare, DuckDNS, DynDNS, Namecheap, Google Domains, GoDaddy, OVH, Porkbun, many more). 25-year-old protocol tool. GPL-2.0. Still the de-facto DDNS updater on Linux."
---

# ddclient

ddclient is **"the canonical Perl-based dynamic-DNS-updater that's been in every Linux distro for two decades"** — a small daemon that periodically checks your public IP (from router, from `ifconfig`-style query, from STUN, or from the interface) + pushes updates to your DDNS provider's API when it changes. Supports 40+ DDNS services including Cloudflare, Duck DNS, DynDNS, Namecheap, Google Domains / Squarespace DNS, GoDaddy, Njalla, Porkbun, OVH, Hurricane Electric, and many more. Keeps your home server reachable at `myhomelab.duckdns.org` even when your ISP rotates your IP.

Built + maintained by **ddclient team** (currently). Originally by Paul Burry (1999); now community-maintained under github.com/ddclient/ddclient. **License: GPL-2.0**. 25-year-old project; still active; recent active releases; fundamental Linux infrastructure.

Use cases: (a) **home VPN endpoint** — `myvpn.duckdns.org` reachable despite ISP IP rotation (b) **self-hosted services behind residential ISP** — web server / Plex / Nextcloud at home (c) **remote backup target** at home (d) **home router → your custom domain** (Cloudflare DNS, Namecheap, etc.) (e) **IPv6 support** — many providers + ddclient handle v6 (f) **IoT devices calling home** to a reachable endpoint.

Features (from upstream README):

- **40+ DDNS providers** — huge list (Cloudflare, DuckDNS, DynDNS, Namecheap, Google Domains, Gandi, Porkbun, OVH, Hurricane Electric, Mythic Beasts, Njalla, Infomaniak, Loopia, Yandex, Zoneedit, EasyDNS, Enom, Freedns, many more)
- **Multiple IP-detection methods** — router-probe, web-service, interface, STUN
- **Support for many routers** — cable/DSL box integration to read WAN IP
- **IPv4 + IPv6**
- **Systemd + traditional init integration**
- **Perl single binary** — minimal deps; ubiquitous language
- **Config file driven** — declarative per-domain configs

- Upstream repo: <https://github.com/ddclient/ddclient>
- Releases: <https://github.com/ddclient/ddclient/releases>
- Support matrix (in README): long list of supported services
- Alternatives mentioned by upstream: <https://github.com/troglobit/inadyn> + <https://github.com/lopsided98/dnsupdate>

## Architecture in one minute

- **Perl script** — single-file daemon
- **Config file** `/etc/ddclient/ddclient.conf`
- **Cron-style execution** — daemon mode with `daemon=` interval or periodic cron
- **Resource**: negligible — ~10MB RAM, runs briefly every N minutes
- **No web UI** — config-file driven

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Debian/Ubuntu package** | **`apt install ddclient`**                                | **Easiest on Debian-family**                                                       |
| RPM                | `yum/dnf install ddclient`                                                | RHEL-family                                                                                   |
| Alpine             | `apk add ddclient`                                                                                   | For Alpine-based containers                                                                                               |
| Docker (LSIO, community) | `linuxserver/ddclient` + others                                                                                   | For containerized homelab                                                                                                 |
| Source             | `make install` after Perl deps                                                                                               | For custom builds                                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| DDNS provider        | duckdns / cloudflare / namecheap / etc.                     | Config       | Determines protocol block                                                                                    |
| Domain(s)            | `myvpn.duckdns.org` or `home.example.com`                   | Config       | Domains to update                                                                                    |
| Provider API token   | Per-provider (token / login+password)                       | **CRITICAL** | **Secret — file perms 600**                                                                                    |
| IP discovery method  | Web / router / interface                                                               | Config       | Pick reliable method for your setup                                                                                    |
| Update interval      | 300s (5min) typical                                                                                  | Config       | Don't hammer provider APIs                                                                                                            |

## Install + configure (Debian example)

```sh
sudo apt install ddclient
sudo $EDITOR /etc/ddclient/ddclient.conf
# Example config for Cloudflare:
# protocol=cloudflare,  \
# zone=example.com,     \
# ttl=1,                \
# login=you@example.com,\
# password='<API_TOKEN>'\
# home.example.com
sudo systemctl enable --now ddclient
sudo systemctl status ddclient
sudo journalctl -u ddclient -f   # watch for updates
```

## Data & config layout

- `/etc/ddclient/ddclient.conf` — config + **API secrets** (chmod 600)
- `/var/cache/ddclient/ddclient.cache` — last-known-IP cache (avoids redundant updates)
- `/var/log/ddclient.log` or journal — update history

## Backup

- **Back up ddclient.conf** — contains API tokens + config
- Cache file is regenerable

## Upgrade

1. Distro package manager handles it.
2. For Docker: `docker pull + restart`.
3. Check release notes for provider-protocol changes (APIs evolve; ddclient adapts).

## Gotchas

- **API TOKEN HYGIENE = THE #1 ddclient ISSUE**: ddclient.conf contains API tokens in plaintext. Configure:
  - **File perms 0600** — readable only by root (or ddclient user)
  - **ddclient user** (not root) to run the daemon + own the config
  - **Rotate tokens** if leaked or compromised
  - **Backup-encryption** for config (if backed up to cloud, encrypt first)
- **PROVIDER API SCOPE**: many providers issue "full-access" API tokens by default. Use LEAST-PRIVILEGE:
  - **Cloudflare**: create token with scope `Zone:DNS:Edit` for the specific zone only (not Global API Key)
  - **Namecheap**: limit IP-allowlist for API access
  - **DuckDNS**: per-domain token; easier to scope
  - **Leaked ddclient.conf with global-scope token = entire DNS account compromised**.
- **RATE-LIMITING**: DDNS providers rate-limit API calls. ddclient's default interval (300s typical) is safe. Don't configure aggressive intervals — ddclient is smart enough to only call the API when IP changes (uses cache). Don't override that.
- **IP DETECTION METHOD CHOICE**:
  - **Router probe** — reads WAN IP from router's admin page; accurate but router-specific
  - **Web query** (e.g., `icanhazip.com`, `ifconfig.me`, `ipify.org`) — typical + reliable; beware third-party dependency
  - **Interface** — use local interface IP; DOES NOT WORK if behind NAT (reports private IP)
  - **STUN** — UDP-based; works through NAT; not all ddclient configs support
  - **For CGNAT** (carrier-grade NAT): your public IP isn't yours; DDNS can't help. You need IPv6 or a VPS tunnel.
- **CGNAT PROBLEM**: mobile ISPs + some rural ISPs use CGNAT → you share a public IP with many others → cannot port-forward → DDNS updates are meaningless. Solutions: IPv6 + AAAA records, Cloudflare Tunnel, Tailscale, a VPS tunnel.
- **IPv6 + IPv4 DUAL STACK**: modern setups have both. ddclient can update A + AAAA records. Configure both protocols in config file; test both paths.
- **DNS TTL TUNING**: DDNS records should have LOW TTL (60-300s) so IP changes propagate quickly. Many providers support TTL=1 (60s). ddclient's `ttl=` config honors this.
- **SECURITY: DNS HIJACKING RISK**: if your ddclient config's API token is compromised, attacker can:
  - Point your domain to their phishing server
  - MITM your traffic (if no TLS pinning)
  - Steal cookies + sessions for your legitimate services
  - **Detection**: set up DNS monitoring (uptime robot checking correct IP, domain-expiry alerts, DNS-change alerts). Many providers offer DNS-change-email-alerts.
- **HUB-OF-CREDENTIALS LIGHT**: stores provider API tokens. **35th tool in hub-of-credentials family — LIGHT tier.** (But compromise = DNS-hijack; so "light" understates risk if token is broad-scope. Prefer scoped tokens.)
- **OLDEST-TOOL-IN-CATALOG territory**: ddclient dates to 1999 — 27 years old at time of writing. **Age-as-maturity-signal** — most bugs found long ago; protocol coverage broad; documentation mature. Small + simple enough to stay maintainable.
- **INSTITUTIONAL-STEWARDSHIP — community-maintained-long-lived-tool**: after Paul Burry, ddclient went through various maintainers + eventually github.com/ddclient community org. Pattern: **"community-steward-of-legacy-tool"** — critical infrastructure tool adopted by volunteer community after original author moves on. **16th tool in institutional-stewardship family** (community-sub-tier, joining Deuxfleurs / Garage 90).
- **PROVIDER DEPRECATION**: DDNS providers change/deprecate APIs occasionally. Watch upstream releases for protocol updates; subscribe to your provider's API changelog.
- **MODERN ALTERNATIVES WORTH KNOWING:**
  - **inadyn** (troglobit) — similar C-based alternative; upstream explicitly mentions
  - **dnsupdate** (lopsided98) — Python alternative
  - **Cloudflare-ddns** — provider-specific script from Cloudflare
  - **Duck DNS official script** — provider-specific
  - **Terraform** with DNS provider + cron — overkill but doable
  - **Direct API calls from cron** — for one-off single-provider setups
  - **UniFi / OPNsense / pfSense built-in DDNS** — router-integrated
  - **Cloudflare Tunnel / Tailscale Funnel** — BYPASS ddns entirely; tunnel-based public access
  - **Choose ddclient if:** you want MATURE + many-providers + Perl-standard + Linux-package-installable.
  - **Choose inadyn if:** you want C-based + Linux-embedded-friendly + similar featureset.
  - **Choose Cloudflare Tunnel if:** you want to BYPASS residential-ISP-IP-rotation entirely with a tunnel.
  - **Choose Tailscale if:** you want mesh + magic-dns + zero DNS-config.
- **COMMERCIAL-TIER**: none. Pure OSS + volunteer-maintained.
- **LICENSE GPL-2.0**: not copyleft-onerous for typical use; fine for self-host + distro inclusion.
- **PROJECT HEALTH**: active (despite being old) + GPL-2 + wide-protocol-support + Linux-distro-included. Bedrock homelab tool.

## Links

- Repo: <https://github.com/ddclient/ddclient>
- Homepage (historical): <https://ddclient.net>
- inadyn (alt): <https://github.com/troglobit/inadyn>
- dnsupdate (alt): <https://github.com/lopsided98/dnsupdate>
- Duck DNS: <https://www.duckdns.org>
- Cloudflare Tunnel (alt approach): <https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/>
- Tailscale (alt approach): <https://tailscale.com>
- No-IP (DDNS provider): <https://www.noip.com>
- FreeDNS by Afraid: <https://freedns.afraid.org>
