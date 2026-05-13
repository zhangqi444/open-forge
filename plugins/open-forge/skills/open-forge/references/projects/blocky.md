---
name: Blocky
description: "Fast, lightweight DNS proxy + ad-blocker for local networks. YAML config, regex rules, per-client-group allowlists/denylists, DoH/DoT/DoQ, DNSSEC, query logging to MySQL/Postgres, Prometheus metrics, Grafana dashboards. Single Go binary. Apache-2.0."
---

# Blocky

Blocky is **a fast, single-binary DNS proxy and ad-blocker** written in Go — a lighter-weight alternative to **Pi-hole** / **AdGuard Home**. Configure via a single YAML file; no database required (stateless); supports DNS over UDP/TCP/HTTPS/TLS; blocks via external lists (ad-block, malware); allows per-client-group policies (e.g., kids' devices get a stricter blocklist); caches smartly for speed.

Features:

- **Blocking** via external allow/denylists (StevenBlack, OISD, etc.)
- **Per-client groups** — different blocklists for kids, IoT, guest devices
- **Regex rules** in lists
- **Deep CNAME inspection** + response-IP blocking
- **Custom DNS** — per-domain override (e.g., `home.lan → 192.168.1.1`)
- **Conditional forwarding** — e.g., `*.corp → 10.0.0.53`
- **Per-group upstream resolvers** (e.g., kids → Cloudflare for Families 1.1.1.3)
- **Caching + prefetching** — warm the cache for popular queries
- **Multi-upstream** — hit multiple resolvers simultaneously; first-response wins
- **Protocols**: DNS-over-UDP, DNS-over-TCP, **DoH** (DNS-over-HTTPS — both as client and as endpoint), **DoT** (DNS-over-TLS), **DoQ** (DNS-over-QUIC, RFC 9250)
- **DNSSEC** validation
- **Privacy** — random upstream rotation; no telemetry
- **Query logging** — CSV files or MySQL/MariaDB/Postgres/Timescale
- **Metrics** — Prometheus exporter with prepared Grafana dashboards
- **REST API** + CLI
- **YAML config** — single/multi-file
- **Small** — low RAM, ARM + x86-64, Pi-friendly

- Upstream repo: <https://github.com/0xERR0R/blocky>
- Docs: <https://0xerr0r.github.io/blocky>
- Docker Hub: <https://hub.docker.com/r/spx01/blocky>

## Architecture in one minute

- **Single Go binary** (`blocky`)
- **Stateless**: no DB for operation; optional DB for query logs
- **Resolves via YAML-defined rules** → caches → prefetches → forwards to configured upstreams
- **Resource**: 50-100 MB RAM; low CPU even at thousands of QPS

## Compatible install methods

| Infra         | Runtime                                           | Notes                                                              |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM     | **Docker (`spx01/blocky`)**                           | **Simplest**                                                            |
| Single VM     | Native binary + systemd                                     | Also great; no Docker overhead                                                 |
| Raspberry Pi  | Native or Docker (arm64, armv7, armv6)                                 | Common homelab deployment                                                                 |
| Kubernetes    | Community Helm chart                                                          | Production-grade                                                                                       |
| OpenWrt router | Binary in package; runs on router                                                     | Advanced but nice                                                                                                   |
| Managed       | — (not SaaS)                                                                                  |                                                                                                                              |

## Inputs to collect

| Input              | Example                              | Phase     | Notes                                                              |
| ------------------ | ------------------------------------ | --------- | ------------------------------------------------------------------ |
| Listen IPs/ports   | `0.0.0.0:53` (UDP+TCP) / `0.0.0.0:443` (DoH)   | Network   | Port 53 + optionally DoH/DoT ports                                        |
| Upstream resolvers | `1.1.1.1`, `9.9.9.9`, `https://dns.quad9.net/dns-query` | Config    | Multiple; random/parallel                                                              |
| Blocklists         | StevenBlack, OISD, etc.                                    | Config    | URLs in YAML; periodic reload                                                                        |
| Client groups      | `kids`, `adults`, `iot`                                             | Config    | Match by client IP/subnet                                                                                      |
| Custom DNS         | `home.lan → 192.168.1.100`                                               | Config    | Local resolution                                                                                                         |
| Cache              | TTL min/max; prefetch                                                                | Config    | Tune for latency vs freshness                                                                                                        |
| Query log          | file / DB                                                                                    | Config    | Off by default; on = forensic + privacy trade-off                                                                                                                |
| Prometheus         | `:4000/metrics`                                                                                          | Metrics   | Optional                                                                                                                                            |

## Install via Docker

```yaml
services:
  blocky:
    image: spx01/blocky:v0.29.0                 # pin version
    container_name: blocky
    restart: unless-stopped
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "4000:4000"                              # HTTP: metrics + API
    volumes:
      - ./config.yml:/app/config.yml:ro
      - ./logs:/logs
```

### Minimal `config.yml`

```yaml
upstreams:
  init:
    strategy: blocking              # or "fast" or "random"
  groups:
    default:
      - https://one.one.one.one/dns-query
      - https://dns.quad9.net/dns-query

blocking:
  denylists:
    ads:
      - https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
    malware:
      - https://urlhaus.abuse.ch/downloads/hostfile/
  allowlists:
    ads:
      - /app/allowlist.txt
  clientGroupsBlock:
    default:
      - ads
      - malware
    kids:
      - ads
      - malware
      - adult                        # extra group for kid devices

ports:
  dns: 53
  http: 4000
  https: 443                         # DoH endpoint

log:
  level: info

queryLog:
  type: csv
  target: /logs

prometheus:
  enable: true
  path: /metrics

customDNS:
  customTTL: 1h
  mapping:
    router.lan: 192.168.1.1

conditional:
  mapping:
    corp.example.com: 10.0.0.53      # forward corp queries to internal DNS
```

Reference: <https://0xerr0r.github.io/blocky/latest/configuration/>.

## First boot

1. `docker compose up -d`
2. Test: `dig @<blocky-host> ads.google.com` → should return `0.0.0.0` (blocked) or NXDOMAIN
3. Test non-blocked: `dig @<blocky-host> example.com` → real answer
4. Point one client's DNS at Blocky → browse → notice ad-free pages
5. **Change router DHCP to hand out Blocky as DNS for all clients** — now LAN-wide ad-blocking
6. Import Grafana dashboard (from blocky repo `docs/grafana/`) → point at Prometheus → pretty graphs

## Data & config layout

- `config.yml` — everything
- `/logs/` (if enabled) — query logs as CSV
- Optional DB — query logs
- No stateful files needed for operation

## Backup

```sh
# Config only
cp config.yml blocky-config-$(date +%F).bak
```

Stateless = trivially rebuildable from config.

## Upgrade

1. Releases: <https://github.com/0xERR0R/blocky/releases>. Active; `0.x` series.
2. Docker: bump tag.
3. Binary: replace + restart systemd.
4. Config: occasional YAML schema changes; upstream migration notes.

## Gotchas

- **Don't run Blocky + Pi-hole + AdGuard Home on the same host on port 53.** Only one can bind. Pick one.
- **Port 53 is privileged** on Linux — Docker needs the bind permission (usually fine; setcap for native binary: `sudo setcap cap_net_bind_service=+ep $(which blocky)`).
- **DNS outages = network outage perception.** Users will complain that "the internet is broken" when Blocky is down; browsing fails before anything else. Run a secondary (unbound/AGH/Pi-hole/router built-in) and hand out both in DHCP — one will respond.
- **Router DHCP DNS override** — ISP routers often ignore custom DNS. Check; may require `dnsmasq` config on OpenWrt or switching your gateway.
- **DNS leaks** — only clients pointed at Blocky are protected. Mobile hotspots, VPNs, some apps use hardcoded DNS (Chromecast → Google DNS). Blocklist-based protection doesn't extend to those.
- **Android Private DNS** — Android uses DoT to `dns.google` by default if user sets "private DNS." To force through Blocky: set your Blocky's DoT hostname in "Private DNS" per device, or block :853 egress at router.
- **Deep CNAME inspection** — works but slow if lists have many CNAME-based trackers; expect some CPU on heavy browse.
- **Blocklist updates** — fetched periodically; configure `refreshPeriod`. Default is 4h; balance freshness vs upstream load.
- **Upstream DoH/DoT** — recommended for privacy + bypass ISP DNS hijack. Mix of providers (Cloudflare + Quad9 + NextDNS) gives resilience.
- **DNSSEC validation** — optional; some upstream providers don't return DNSSEC records; match upstream capabilities.
- **Query logging privacy** — logs *every DNS query from every client*. Extremely sensitive data (browsing behavior). Rotate + encrypt + restrict access. Consider only logging blocked queries.
- **Per-client groups** — match by IP or CIDR; beware of DHCP reassignment. For strong grouping, use static IPs or client hostnames (if your upstream provides PTR).
- **IPv6** — Blocky supports AAAA; configure `ipv6Disabled: false` in upstream groups for modern networks.
- **Cache poisoning** — DNSSEC validation protects; disabling it opens risk. Know what you're turning off.
- **HTTPS ports**: if you want to provide DoH to clients, port 443 conflicts with any webserver. Dedicate a sub-host or use a different port.
- **API** — `/api/*` endpoints for flush cache, refresh lists, list groups. Useful for automation.
- **CSV query log format**: easy to `awk`/`grep` — great for quick incident response.
- **Comparison to Pi-hole**: Blocky is lighter, config-file-first, no SQLite bloat, no PHP web UI. Pi-hole has a nicer management UI + broader community + integrations.
- **Comparison to AdGuard Home**: AGH has a nicer UI + parental controls UI; Blocky is smaller + more performant.
- **License**: Apache-2.0.
- **Alternatives worth knowing:**
  - **Pi-hole** — the classic; PHP web UI + SQLite; larger community (separate recipe likely)
  - **AdGuard Home** — modern UI + parental controls + encrypted DNS; polished (separate recipe likely)
  - **Technitium DNS** — Windows-friendly; rich UI
  - **CoreDNS** — general-purpose DNS; needs plugins for ad-blocking
  - **dnsmasq** + blocklists — minimal DIY
  - **Unbound** + RPZ — enterprise-grade
  - **NextDNS** (SaaS) — commercial hosted blocker
  - **Cloudflare 1.1.1.3 for Families** — free SaaS blocker
  - **Choose Blocky if:** you want a performant, lightweight, config-driven blocker with Prometheus + per-group.
  - **Choose Pi-hole if:** you want the UI-rich UX + plugin ecosystem.
  - **Choose AdGuard Home if:** you want a polished UI + kids controls out of the box.
  - **Choose NextDNS if:** you don't want to host DNS.

## Links

- Repo: <https://github.com/0xERR0R/blocky>
- Docs: <https://0xerr0r.github.io/blocky/>
- Installation: <https://0xerr0r.github.io/blocky/latest/installation/>
- Configuration: <https://0xerr0r.github.io/blocky/latest/configuration/>
- Releases: <https://github.com/0xERR0R/blocky/releases>
- Docker Hub: <https://hub.docker.com/r/spx01/blocky>
- Grafana dashboards: <https://github.com/0xERR0R/blocky/tree/main/docs/grafana>
- Pi-hole (alt): <https://pi-hole.net>
- AdGuard Home (alt): <https://github.com/AdguardTeam/AdGuardHome>
- StevenBlack/hosts (blocklist): <https://github.com/StevenBlack/hosts>
- OISD (blocklist): <https://oisd.nl>
- Donate (ko-fi): <https://ko-fi.com/0xerr0r>
