---
name: Technitium DNS Server
description: "Self-hosted DNS server for privacy, security, ad/malware blocking. Authoritative + recursive. DoT / DoH / DoQ / DNSSEC. Web console, one-click blocklists, OIDC SSO, clustering. High performance (100k+ req/s). Windows/Linux/macOS/Raspberry Pi. GPL-3.0."
---

# Technitium DNS Server

Technitium is a **full-featured, self-hosted DNS server** — use it as your home/office resolver (Pi-hole-style ad blocking), an authoritative server for your own domains, a secure DNS forwarder (DoT/DoH/DoQ to Cloudflare/Quad9), or all of the above. It lives in the same niche as Pi-hole + AdGuard Home + BIND + Unbound, but in one package with a polished web UI.

What makes it stand out:

- **All-in-one** — authoritative + recursive + forwarder + stub resolver in one binary
- **High performance** — tested at 100k+ req/s on commodity i7 hardware
- **Encrypted DNS** — run your own DNS-over-TLS / DNS-over-HTTPS / DNS-over-QUIC endpoint
- **Ad + malware blocking** — multiple blocklists (Steven Black, OISD, 1Hosts, easy to add more)
- **Clustering** — manage N servers from one web console (primary + secondaries auto-sync)
- **DNSSEC** — sign zones, validate responses
- **Conditional forwarders** — different upstream per domain (e.g., `.internal.corp` → AD DC, rest → Cloudflare)
- **Apps** — plugin system for custom resolvers, split-horizon, geo-DNS
- **SSO** — OIDC for admin login
- **Web console** — admin via browser; full-featured

- Upstream repo: <https://github.com/TechnitiumSoftware/DnsServer>
- Website: <https://technitium.com/dns/>
- Docs: <https://github.com/TechnitiumSoftware/DnsServer/blob/master/DnsServerSetup.md>
- Docker Hub: <https://hub.docker.com/r/technitium/dns-server>
- Reddit: <https://www.reddit.com/r/technitium/>
- Discord: <https://discord.gg/XgG8JzPuca>

## Architecture in one minute

- **.NET 8+** (cross-platform, async IO)
- **Single binary** with bundled web admin console
- **Storage**: local filesystem (zones, blocklists, stats)
- **Stats database**: embedded (SQLite-like)
- **TLS certificate** — install or generate via built-in Let's Encrypt support
- **Low memory footprint** — <100 MB idle; scales linearly with zone/blocklist size
- **Runs on**: Windows, Linux (systemd service), macOS, Raspberry Pi, Docker

## Compatible install methods

| Infra          | Runtime                                      | Notes                                                       |
| -------------- | -------------------------------------------- | ----------------------------------------------------------- |
| Single VM      | **Docker (`technitium/dns-server`)**             | **Popular for homelabs**                                       |
| Single VM      | Native (install script for Linux)                 | Upstream-provided                                                   |
| Raspberry Pi   | arm64 binary                                        | Popular — replaces Pi-hole, more features                               |
| Windows        | MSI installer                                         | .NET runtime bundled                                                         |
| macOS          | `.dmg` or brew (via unofficial taps)                      | Works; less common                                                                  |
| Kubernetes     | Community manifests                                        | Doable; DNS networking in K8s needs care                                                 |
| pfSense/OPNsense| Package available                                              | Via community ports                                                                           |

## Inputs to collect

| Input                | Example                          | Phase     | Notes                                                             |
| -------------------- | -------------------------------- | --------- | ----------------------------------------------------------------- |
| DNS listen IP        | `0.0.0.0:53`                        | Network   | Bind to all interfaces or specific                                      |
| Admin URL            | `http://host:5380`                    | Admin     | Default 5380 web; change for public exposure                             |
| TLS cert (DoT/DoH)   | Let's Encrypt or self-signed             | Security  | Required if running encrypted DNS                                              |
| Admin password       | set via installer                           | Bootstrap | Change default!                                                                     |
| Upstream DNS         | Cloudflare DoT/DoH/DoQ + Quad9             | Resolver  | Pick at least one trusted encrypted upstream                                               |
| Blocklists           | OISD Full / Steven Black / 1Hosts              | Blocking  | Add via web UI                                                                                  |
| Domains / zones (opt)| Your own domain if running authoritative       | DNS       | e.g., `home.example.com` as internal zone                                                                    |
| Firewall             | 53/udp+tcp, 853/tcp (DoT), 443/tcp (DoH), 443/udp (DoQ) | Network   | Open as needed                                                                                      |

## Install via Docker

```sh
docker run -d --name technitium-dns \
  --restart unless-stopped \
  --network host \
  -v /opt/technitium/config:/etc/dns/config \
  -e DNS_SERVER_DOMAIN=dns.example.com \
  -e DNS_SERVER_ADMIN_PASSWORD=<strong> \
  technitium/dns-server:latest   # pin a specific version tag in prod
```

`--network host` is the usual choice for DNS servers to avoid Docker's NAT for port 53.

## Install via Docker Compose

```yaml
services:
  dns-server:
    image: technitium/dns-server:latest    # pin specific version in prod
    container_name: dns-server
    restart: unless-stopped
    network_mode: host      # easiest; or map ports
    environment:
      DNS_SERVER_DOMAIN: dns.example.com
      DNS_SERVER_ADMIN_PASSWORD: <strong>
      DNS_SERVER_PREFER_IPV6: "false"
      DNS_SERVER_WEB_SERVICE_LOCAL_ADDRESSES: "0.0.0.0,[::]"
      DNS_SERVER_OPTIONAL_PROTOCOL_DNS_OVER_HTTP: "true"
      DNS_SERVER_RECURSION: AllowOnlyForPrivateNetworks   # or UseSpecifiedNetworks / DenyAll
    volumes:
      - ./config:/etc/dns/config
```

Browse `http://<host>:5380` → log in with `admin` / your password.

## Install natively (Linux)

```sh
# Official install script (Ubuntu/Debian/etc.)
curl -sSL https://download.technitium.com/dns/install.sh | sudo bash
# Edits systemd; starts the service.
# Open http://<server>:5380/ in a browser
```

## First boot

1. Browse `http://<host>:5380` → log in
2. Change admin password
3. **Dashboard** → check live queries
4. **Settings → DNS Settings**:
   - Forwarders: enable DoH or DoT; add Cloudflare (`1.1.1.1`/`cloudflare-dns.com`), Quad9 (`9.9.9.9`), etc.
   - Recursion: "Allow Only For Private Networks" (default) prevents being an open resolver (DDoS amplification risk)
5. **Blocking → Block Lists** — add URLs (OISD Full is a great default):
   - <https://big.oisd.nl/>
   - <https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts>
   - <https://badmojr.gitlab.io/1hosts/Lite/dns.txt>
6. **Zones** (if running authoritative) → Add Zone → `home.example.com` → add A/AAAA records for your internal hosts
7. Point your DHCP server to advertise Technitium's IP as the DNS server

## DNS-over-TLS / DoH / DoQ

1. Settings → DNS Settings → Optional Protocols → enable DoT / DoH / DoQ
2. Install TLS cert (built-in Let's Encrypt via ACME) — requires public DNS name + port 80 or DNS challenge
3. Clients config:
   - DoT endpoint: `dns.example.com:853`
   - DoH endpoint: `https://dns.example.com/dns-query`
   - DoQ endpoint: `dns.example.com:853` (QUIC)

## Data & config layout

Under `/etc/dns/config` (Linux Docker) or `%ProgramData%\Technitium\DNS` (Windows):

- `config.config` — primary config
- `zones/` — authoritative zones + signed keys
- `blocked-zones/` — compiled blocked-domain list
- `stats/` — query stats DB
- `dnssec-keys/` — DNSSEC keys

## Backup

```sh
# Everything
tar czf technitium-$(date +%F).tgz /opt/technitium/config/

# Zones only
tar czf technitium-zones-$(date +%F).tgz /opt/technitium/config/zones/
```

Technitium also has a built-in "Backup / Restore" under Settings that exports a zip via the web UI.

## Upgrade

1. Releases: <https://github.com/TechnitiumSoftware/DnsServer/releases>. Very active.
2. **Docker**: pin, pull, up -d.
3. **Native Linux**: re-run install script (it upgrades in place).
4. **Windows**: run the MSI again.
5. Settings → Check for Updates in web UI.
6. Migrations are rare; read release notes for major bumps.

## Gotchas

- **Port 53 conflicts** — on Ubuntu 22.04+, `systemd-resolved` already binds :53. Disable it: `sudo systemctl disable systemd-resolved && sudo systemctl stop systemd-resolved` + edit `/etc/resolv.conf` to avoid loopback. Alternatively, run Technitium on a different port (but client config is easier on 53).
- **NetworkManager on Ubuntu** — also manages DNS; disable DNS management in NM config if hijacking resolv.conf.
- **Recursion = open resolver**: if you set recursion to "Allow All" and expose port 53 publicly, attackers use you for DNS amplification DDoS. Keep it to "Allow Only For Private Networks" unless you explicitly know what you're doing.
- **DNSSEC validation** — enable in Settings; some old + misconfigured zones break. Technitium logs validation failures.
- **Ad-blocking via host file URLs** — the default 1-2 lists cover most ad networks. Combining many (OISD + Steven Black + …) = larger memory footprint + higher false-positive rate. Start minimal.
- **Blocklist updates**: set a refresh interval in Settings → Blocking. Hourly is common.
- **Allowlisted domains**: when a blocked domain breaks something, allowlist it (Settings → Blocking → Allow Custom Domains).
- **Per-client filtering**: Technitium supports "Apps" which include client-based routing (different blocklists per device/IP). Advanced feature; configure via Apps.
- **Logs contain every query** — privacy implication: your DNS server sees every domain every device on the network looks up. Audit who has access to the admin console.
- **Stats persistence** — configurable retention. By default, keeps aggregated stats; detailed logs rotate.
- **Cluster mode** — run two Technitium servers (primary + secondary); zones sync automatically. Great for HA.
- **OIDC SSO** — integrate with Authelia, Authentik, Keycloak for admin login instead of local password.
- **Web console on public internet** — NEVER. Use VPN/Tailscale, or bind to LAN interface only, or reverse-proxy with strong auth.
- **DNS-over-HTTPS from your browser/OS** — Firefox, Chrome, Windows 11, iOS, Android all support DoH. Point them at your Technitium DoH URL for end-to-end encrypted DNS.
- **Apps / plugin system** — C# plugins extend resolution logic (split-horizon, geo-DNS, logging to external stores). Install from Apps section of web UI or upload DLL.
- **Zone transfer security** — authoritative zones with secondaries should use TSIG (shared key); don't allow AXFR from any IP.
- **Recursion cache tuning** — default cache is fine; tune for massive deployments.
- **vs Pi-hole**: Technitium does MORE (authoritative, DoT/DoH/DoQ endpoint, clustering, DNSSEC, OIDC). Pi-hole has a larger community + more guides + Chef/Ansible/etc. roles. Both are excellent; Technitium is the power-user pick.
- **vs AdGuard Home**: AGH is simpler and Go-based; Technitium is .NET and more featureful. AGH has slightly better "normal user" UX; Technitium has better "DNS admin" UX.
- **vs BIND / Unbound / nsd**: Technitium replaces all three for homelab scale. At ISP / top-level scale, BIND/Unbound/NSD/Knot are still the canonical choices.
- **GPL-3.0 license** — strong copyleft.
- **Developer + company based in India**; responsive to GitHub issues; Discord community.
- **Alternatives worth knowing:**
  - **Pi-hole** — ad/malware blocking DNS; PHP + dnsmasq; huge community (separate recipe)
  - **AdGuard Home** — Go; modern; simpler (separate recipe)
  - **Unbound** — recursive resolver; no UI; rock-solid; pair with Pi-hole
  - **BIND9** — authoritative + recursive; industry standard; complex
  - **NSD / Knot DNS** — authoritative-only; high performance
  - **DNSCrypt-proxy** — encrypted DNS client, not a server
  - **Blocky** — Go-based ad-blocker DNS; simpler
  - **Choose Technitium if:** you want the most-featured all-in-one DNS server with authoritative + recursive + encrypted DNS + clustering.
  - **Choose Pi-hole if:** you want the biggest community + best-documented ad-blocking setup.
  - **Choose AdGuard Home if:** you want the simplest modern experience.

## Links

- Repo: <https://github.com/TechnitiumSoftware/DnsServer>
- Website: <https://technitium.com/dns/>
- Setup docs: <https://github.com/TechnitiumSoftware/DnsServer/blob/master/DnsServerSetup.md>
- Docker Hub: <https://hub.docker.com/r/technitium/dns-server>
- Install script: <https://download.technitium.com/dns/install.sh>
- Releases: <https://github.com/TechnitiumSoftware/DnsServer/releases>
- Discord: <https://discord.gg/XgG8JzPuca>
- Reddit: <https://www.reddit.com/r/technitium/>
- Blog: <https://blog.technitium.com>
- Apps (plugin) directory: <https://download.technitium.com/dns/apps.json>
- Blocklist URLs (OISD): <https://oisd.nl>
- Blocklist URLs (Steven Black): <https://github.com/StevenBlack/hosts>
- DoT / DoH / DoQ explained: <https://www.rfc-editor.org/rfc/rfc7858> / <https://www.rfc-editor.org/rfc/rfc8484> / <https://www.rfc-editor.org/rfc/rfc9250>
