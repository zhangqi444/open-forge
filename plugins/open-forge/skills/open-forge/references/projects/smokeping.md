---
name: SmokePing
description: "Latency logging, graphing, alerting system. RRDtool frontend. Perl. Plugin-module extensible. Web templates. Authors Tobias Oetiker (RRDtool) + Niko Tyni. Decade-plus (2003+) OSS. oetiker/SmokePing."
---

# SmokePing

SmokePing is **"ping -c ... with graphs-over-time and alerting"** — a latency logging + graphing + alerting system. Classic network-monitoring tool built on **RRDtool**. Daemon collects latency measurements; CGI presents graphs. Written in Perl. Extensible via plug-in modules.

Built + maintained by **Tobias Oetiker** (also RRDtool author) + Niko Tyni. Decade-plus OSS (circa 2003+). Active CI.

Use cases: (a) **network latency monitoring** home/office (b) **ISP SLA tracking** (c) **inter-datacenter RTT monitoring** (d) **packet-loss detection** (e) **alerting on latency anomalies** (f) **historical latency graphs** (g) **WAN-link health** (h) **classic sysadmin NetMon workflow**.

Features (per README):

- **Latency logging + graphing + alerting**
- **Extensible** via plugins
- **Customizable** via web-template + config
- **Perl** — portable to any Unix
- **RRDtool frontend**

- Upstream repo: <https://github.com/oetiker/SmokePing>
- RRDtool: <https://oss.oetiker.ch/rrdtool/>

## Architecture in one minute

- **Perl** daemon + CGI (or FastCGI)
- **RRDtool** for storage
- Web server (Apache/nginx) serves CGI + graphs
- Ping probes (ICMP, HTTP, DNS, etc.)
- **Resource**: very low

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Distribution package** | `apt install smokeping` on Debian/Ubuntu                                                                                | **Primary**                                                                                   |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |
| **Source build**   | From repo                                                                                                              | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `smokeping.example.com`                                     | URL          |                                                                                    |
| Targets config       | Hosts to ping                                               | Config       | `/etc/smokeping/config.d/Targets`                                                                                    |
| Alerts config        | Threshold + email                                           | Config       | `/etc/smokeping/config.d/Alerts`                                                                                    |
| SMTP                 | For alerts                                                  | Email        |                                                                                    |
| Web server           | Apache with CGI or nginx+fcgi                               | Infra        |                                                                                    |

## Install (Debian/Ubuntu)

```sh
sudo apt install smokeping apache2
# Config in /etc/smokeping/
sudo systemctl enable --now smokeping
# Browse to https://smokeping.example.com/smokeping/
```

## Install via Docker

```yaml
services:
  smokeping:
    image: linuxserver/smokeping:latest        # **pin**
    environment:
      - PUID=1000
      - PGID=1000
    volumes:
      - ./smokeping-config:/config
      - ./smokeping-data:/data
    ports: ["80:80"]
    cap_add:
      - NET_RAW        # for ICMP
```

## First boot

1. Install
2. Edit Targets config for your hosts
3. Edit Alerts config for thresholds
4. Restart daemon
5. Browse to web UI; watch graphs build up (RRD takes a few cycles)
6. Put behind TLS
7. Back up RRD data + config

## Data & config layout

- `/etc/smokeping/` — config
- `/var/lib/smokeping/` — RRD data (or `/data/` in Docker)

## Backup

```sh
sudo tar czf smokeping-$(date +%F).tgz /etc/smokeping/ /var/lib/smokeping/
```

## Upgrade

1. Distro package: `apt upgrade smokeping`
2. Config-format stability is excellent (decade-plus)
3. Release notes at <https://github.com/oetiker/SmokePing/releases>

## Gotchas

- **175th HUB-OF-CREDENTIALS Tier 2 — NETWORK-MONITORING-CONFIG**:
  - Holds: target network-topology (hosts you ping = internal-network disclosure), SMTP alert creds
  - **175th tool in hub-of-credentials family — Tier 2**
- **NET_RAW-CAPABILITY-NEEDED**:
  - ICMP requires NET_RAW (Docker) or setuid (bare metal)
  - Privilege-adjacent
  - **Recipe convention: "NET_RAW-capability-for-ICMP-discipline callout"**
  - **NEW recipe convention** (SmokePing 1st formally)
- **CGI-LEGACY-PATTERN**:
  - Apache+CGI pattern is legacy
  - Still works; some ops don't like CGI
  - **Recipe convention: "legacy-CGI-deployment-pattern neutral-signal"**
  - **NEW neutral-signal convention** (SmokePing 1st formally)
- **DECADE-PLUS-OSS-CLASSIC**:
  - Since ~2003
  - Longest-running in this catalog alongside Ampache/LaTeX-family
  - **Decade-plus-OSS: 12 tools** (+SmokePing) 🎯 **12-TOOL MILESTONE**
- **RRDTOOL-AUTHOR-PEDIGREE**:
  - Same author as RRDtool itself
  - Unusual provenance-signal
  - **Recipe convention: "author-wrote-underlying-tool positive-signal"**
  - **NEW positive-signal convention** (SmokePing 1st formally)
- **PLUGIN-MODULE-EXTENSIBILITY**:
  - **Plugin-API-architecture: 5 tools** 🎯 **5-TOOL MILESTONE** (+SmokePing)
- **PERL-ECOSYSTEM**:
  - Perl backend
  - Unusual in modern catalog
  - **Perl-backend: 1 tool** 🎯 **NEW FAMILY** (SmokePing)
- **INSTITUTIONAL-STEWARDSHIP**: Tobias Oetiker (renowned OSS author) + Niko Tyni + decade-plus-since-2003 + distro-packaged-broadly. **161st tool — renowned-author-decade-plus-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + releases + distro-ubiquity. **167th tool in transparent-maintenance family.**
- **LATENCY-MONITORING-CATEGORY:**
  - **SmokePing** — classic; RRD; Perl
  - **Uptime Kuma** — modern; more than ping
  - **Gatus** — YAML-config
  - **Prometheus + blackbox-exporter** — cloud-native
- **ALTERNATIVES WORTH KNOWING:**
  - **Uptime Kuma** — if you want modern UX
  - **Prometheus + blackbox** — if you want cloud-native stack
  - **Choose SmokePing if:** you want classic + RRD + packet-loss-detail-graphs + proven-decade-plus.
- **PROJECT HEALTH**: active + decade-plus + renowned-author. Legendary.

## Links

- Repo: <https://github.com/oetiker/SmokePing>
- RRDtool: <https://oss.oetiker.ch/rrdtool/>
- Uptime Kuma (alt): <https://github.com/louislam/uptime-kuma>
