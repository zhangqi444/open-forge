---
name: dash. (dashdot)
description: "Modern glassmorphism server dashboard for small VPS + private servers. Live CPU/RAM/disk/network/GPU metrics. React + Node.js backend with system-info collection. MIT. Sole-maintainer project funded via Ko-Fi + GitHub Sponsors. Docker primary; live demo at dash.mauz.dev."
---

# dash. (dashdot)

dash. (also written **dashdot**) is **"the server dashboard that actually looks nice on your desktop"** — a modern, glassmorphism-styled live-metrics dashboard for a single server. Shows CPU / RAM / disk / network / GPU / OS info with real-time charts + a visually-polished UI. Intended for **small VPS + private homelab servers** — display it fullscreen on a monitor, embed it in a homelab-dashboard, show off your server's pretty vitals. Not a monitoring-replacement for Grafana/Prometheus; a beautiful single-server vitals display.

Built + maintained by **Maurice Nino** (MauriceNino) + contributors. **License: MIT**. Active; Discord community; funded via GitHub Sponsors + Ko-Fi.

Use cases: (a) **personal homelab status screen** — put dash. fullscreen on a second monitor (b) **VPS quick-glance** — bookmark to check your server's vitals (c) **embed in Homarr / Homepage / etc. dashboard widgets** — iframe it (d) **demo / showcase** — impress friends with your server's live metrics (e) **kiosk display** — on a wall-mounted tablet in a server room.

NOT a replacement for: Prometheus + Grafana (long-term metrics), Netdata (alerting + multi-server), Zabbix (enterprise monitoring), cAdvisor (container-specific), Uptime Kuma (service availability). dashdot is single-server + glance-at.

Features (from upstream README + docs):

- **Real-time metrics** — CPU / RAM / storage / network / OS info
- **GPU support** — Nvidia / AMD (where drivers accessible)
- **Glassmorphism design** — modern UI with blur/transparency
- **Dark/light mode**
- **Customizable widget layout**
- **Multiple storage disks** — per-disk graphs
- **Network interface** per-NIC display
- **Docker container display** (optional)
- **Configurable refresh rate**
- **Single-server focus** — no multi-host aggregation

## Architecture in one minute

- **React** frontend
- **Node.js + Express** backend
- **systeminformation** library — polls OS for metrics
- **Port 3001** default
- **Optional Docker socket** for container metrics
- **Resource**: light — 100-200MB RAM on the monitored host

- Upstream repo: <https://github.com/MauriceNino/dashdot>
- Live demo: <https://dash.mauz.dev>
- Docker Hub: <https://hub.docker.com/r/mauricenino/dashdot>
- Discord: <https://discord.gg/3teHFBNQ9W>
- Docs: <https://getdashdot.com> (or similar; check latest README)
- GitHub Sponsors: <https://github.com/sponsors/MauriceNino>
- Ko-Fi: <https://ko-fi.com/mauricenino>

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`mauricenino/dashdot:latest`** (multi-arch)                   | **Upstream-primary**                                                               |
| Docker compose     | Sidecar to other services                                                 | Typical                                                                                   |
| Node.js bare-metal | Clone + build + run                                                                   | For customization                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Host mount paths     | Read-only mount host /proc, /sys, /etc/os-release for metrics | Config       | Required for accurate host metrics                                                                                    |
| Network IF name      | `eth0` / `ens3` / whatever                                  | Config       | Specify for network graph                                                                                    |
| Storage paths        | `/mnt/data` etc.                                            | Config       | Per-disk graphs                                                                                    |
| GPU mount            | `/dev/dri` for Intel/AMD; nvidia-docker for Nvidia                                                | Optional     | For GPU widget                                                                                    |
| Refresh rate         | seconds                                                                                                        | Config       | Balance between live + resource usage                                                                                                            |

## Install via Docker

```yaml
services:
  dashdot:
    image: mauricenino/dashdot:latest      # **pin version** in prod
    container_name: dashdot
    restart: unless-stopped
    privileged: true    # some metrics need this; alternatively use specific capabilities
    volumes:
      - /:/mnt/host:ro,rslave    # host filesystem for disk metrics
    environment:
      - DASHDOT_ENABLE_CPU_TEMPS=true
      - DASHDOT_WIDGET_LIST=os,cpu,storage,ram,network
    ports: ["3001:3001"]
```

## First boot

1. Start → browse `http://host:3001`
2. Verify all widgets display correctly
3. Tune widget list + layout
4. Customize theme / glassmorphism settings
5. Put behind TLS reverse proxy if exposing beyond LAN
6. Consider embedding iframe into your homelab dashboard (Homarr / Homepage)

## Data & config layout

- **NO PERSISTENT STATE** — dashdot is stateless
- Config via env vars only
- No DB, no secrets (beyond TLS cert at reverse-proxy layer)

## Backup

- **Nothing to back up** — stateless. Version-control your compose file.

## Upgrade

1. Releases: <https://github.com/MauriceNino/dashdot/releases>. Active.
2. Docker: pull + restart.
3. Read release notes for new widgets + env var changes.

## Gotchas

- **ANOTHER STATELESS-TOOL RARITY** (3rd tool after OpenSpeedTest 91 + Moodist 93): no DB, no secrets, no backup needed. **"Stateless-tool rarity" pattern accumulating** — worth documenting as a recipe category. Pattern applies to: dashdot, Moodist, OpenSpeedTest, many static SPAs, many stateless-utility tools.
- **PRIVILEGED-CONTAINER / HOST-/PROC-/SYS READ = ESCALATION RISK**: system-info libraries need access to host `/proc`, `/sys`, `/dev` to read metrics. Either:
  - `privileged: true` — easy but grants kernel-level container-escape risk
  - Specific capabilities + bind mounts — more secure; per dashdot docs
  - **Trade-off**: metric-coverage vs container-isolation. For trusted LAN + single-user: privileged is fine. For exposed internet instances: use restricted permissions + reverse-proxy auth.
- **EXPOSE-WITH-AUTH**: dashdot has no built-in authentication. If internet-exposed, put behind:
  - Reverse proxy with HTTP basic auth
  - Authelia / Authentik
  - Cloudflare Access (zero-trust)
  - **NEVER expose dashboard publicly without auth** — reveals system info, uptime, CPU model, disks, NICs = recon data for attackers.
  - **Network-recon-risk family** — 1st tool in this sub-family: tools whose public exposure reveals infrastructure info helpful to attackers (uptime, OS version, hardware, network topology). Also applies to: phpMyAdmin, info-disclosure-dashboards, server-status pages (Apache), naked-Node-Exporter.
- **GPU METRICS = NVIDIA-DRIVER-GYMNASTICS**: Nvidia GPU metrics in containers require `nvidia-docker` / `--gpus all`. AMD/Intel typically easier with `/dev/dri`. Dashdot docs cover this; expect some setup friction first time.
- **DISK METRICS WITH BIND MOUNTS**: for multi-disk systems, dashdot needs `/mnt/host` or similar showing the FULL host filesystem. Can feel invasive (container can read ANY file on host, read-only). For high-sensitivity hosts, consider: selective bind mounts only for metric-relevant paths.
- **REFRESH RATE vs RESOURCE USAGE**: high refresh rate (500ms) = smooth animation, more CPU. Default is sensible; only tune if you have specific needs.
- **HUB-OF-CREDENTIALS: 0 TOOLS** — dashdot has no credentials, no accounts, no DB. Pleasant. (Same as Moodist.)
- **IMMUTABILITY-OF-SECRETS: 0 TOOLS** — no secrets to be immutable about.
- **SOLE-MAINTAINER**: MauriceNino + contributors + Discord. **9th tool in sole-maintainer-with-community class.** MIT + active + fork-friendly = manageable risk.
- **PURE-DONATION COMMERCIAL-TIER**: GitHub Sponsors + Ko-Fi. **9th tool in pure-donation family.**
- **AI-AUTONOMY / NO BADGE**: dashdot doesn't carry an AI-autonomy badge (unlike OliveTin 91). No contrary signal; just not explicit.
- **NOT-A-REPLACEMENT-FOR-SERIOUS-MONITORING**: dashdot is a PRETTY dashboard. For actual monitoring:
  - **Netdata** — multi-host + alerts + rich metrics; GPL-3; free tier robust
  - **Prometheus + Grafana** — industry standard time-series + dashboards
  - **InfluxDB + Grafana** — alt time-series stack
  - **Zabbix / Nagios / Icinga** — enterprise monitoring heritage
  - **Uptime Kuma** — service availability (not metrics)
  - **Glances** — terminal-based glances (CLI alt to dashdot's use case)
- **EMBED-IN-HOMELAB-DASHBOARDS**: dashdot works great as an iframe in Homarr / Homepage / Heimdall. Its glassmorphism styling adds visual polish to homelab-pages.
- **COMMERCIAL-TIER / INSTITUTIONAL-STEWARDSHIP**: no company behind it; sole-maintainer funded by donations. Standard pattern for small specialized homelab tools.
- **MIT LICENSE**: fork-friendly; widely-reusable; OK for any use.
- **LIVE DEMO at dash.mauz.dev** — upstream-hosted live demo is a nice "before you install, see if you like it" UX affordance. Relatively rare + generous.
- **TRANSPARENT-MAINTENANCE**: clean MIT + semver + Discord + donation-funded + live demo. **17th tool in transparent-maintenance family.**
- **SIZE-OF-DEPENDENCIES**: uses `systeminformation` npm package (very active, well-maintained) + React + common Node libs. Regular deps audit hygiene.
- **PROJECT HEALTH**: active + MIT + Discord + sponsor-funded + live demo + glassmorphism aesthetic = polished small-tool. Healthy.

## Alternatives worth knowing:

- **Netdata** — comprehensive real-time monitoring; multi-host; alerts; GPL-3
- **Glances** — CLI + web; Python; LGPL; same-niche-text-focused
- **bashtop / btop** — TUI (terminal) alt
- **node_exporter + Grafana** — Prometheus-based alt; multi-host
- **RPi-Monitor** — Raspberry-Pi-specific
- **LibreSpeed** — unrelated but often co-installed
- **Homarr / Homepage** (batch 89) — dashboard-of-dashboards; embed dashdot

**Choose dashdot if:** you want PRETTY + single-server + glance-at + low-config + MIT.
**Choose Netdata if:** you want real monitoring + alerts + multi-host + free-tier.
**Choose Glances if:** you want CLI/web lightweight + scriptable.
**Choose Grafana-based if:** you want time-series + dashboards + serious observability.

## Links

- Repo: <https://github.com/MauriceNino/dashdot>
- Live demo: <https://dash.mauz.dev>
- Docker: <https://hub.docker.com/r/mauricenino/dashdot>
- Discord: <https://discord.gg/3teHFBNQ9W>
- Sponsor: <https://github.com/sponsors/MauriceNino>
- Netdata (alt, serious monitoring): <https://www.netdata.cloud>
- Glances (alt, text-focused): <https://nicolargo.github.io/glances/>
- btop (alt, TUI): <https://github.com/aristocratos/btop>
- Homarr (pairs well): <https://homarr.dev>
