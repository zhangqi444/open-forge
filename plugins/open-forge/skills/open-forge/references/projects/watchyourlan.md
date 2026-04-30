---
name: WatchYourLAN
description: "Lightweight LAN IP scanner with web GUI — detect new hosts, monitor up/down history, send Shoutrrr notifications, export to InfluxDB2/Prometheus for Grafana dashboards. Go-based, SQLite/Postgres. Requires host network mode. MIT."
---

# WatchYourLAN

WatchYourLAN (WYL) is **a minimal network-device tracker** — runs `arp-scan` on your LAN interface on a schedule, keeps a list of every host ever seen (MAC + IP + vendor + hostname), tracks online/offline history, and sends a notification via Shoutrrr (Discord, Email, Gotify, Matrix, Ntfy, Pushover, Slack, Telegram, webhook, etc.) when a new device appears.

Use cases:

- **"Who's on my Wi-Fi?"** — know when a new phone / IoT device / guest joins
- **Neighbor wifi detection** — alert on unknown MACs
- **Presence sensing** — your phone disconnects from Wi-Fi when you leave → Home Assistant trigger
- **Device inventory** — running list of every MAC ever on your LAN
- **Grafana dashboards** — feed InfluxDB2 / Prometheus → visualize device counts + history

Features:

- **ARP scan** per-interface, configurable interval (default 120 s)
- **VLAN support** (see `docs/VLAN_ARP_SCAN.md`)
- **Web GUI** on port 8840 — list hosts, rename, set ignore, view history
- **SQLite** (default) or **Postgres** backend
- **Shoutrrr notifications** — "new host found" / "host went offline/online"
- **InfluxDB2 export** — write device status as time-series
- **Prometheus metrics** endpoint
- **Lightweight** — single Go binary, ~20 MB

- Upstream repo: <https://github.com/aceberg/WatchYourLAN>
- Docker Hub: <https://hub.docker.com/r/aceberg/watchyourlan>
- Discussions: <https://github.com/aceberg/WatchYourLAN/discussions>

## Architecture in one minute

- **Go binary** wrapping `arp-scan` (external dependency)
- **SQLite** file in `/data/WatchYourLAN/` (or Postgres)
- **Web UI** — Go server with Bootswatch themes
- **Shoutrrr URLs** for notifications
- **Needs host network mode** — container must see the LAN to ARP-scan

## Compatible install methods

| Infra          | Runtime                                             | Notes                                                                        |
| -------------- | --------------------------------------------------- | ---------------------------------------------------------------------------- |
| Single VM      | **Docker with `--network=host`**                        | **The default**                                                                      |
| Single VM      | Native `.deb` / `.rpm` / `.apk` / `.tar.gz` package           | For bare-metal LAN servers                                                                 |
| Raspberry Pi   | arm64/armv7 binary or Docker                                    | Perfect match — leave a Pi on your LAN full-time                                                      |
| Kubernetes     | Needs host network; awkward — usually run outside K8s                  | Not recommended                                                                                   |
| Synology/QNAP  | Docker with host network                                                   | Works                                                                                                     |

## Inputs to collect

| Input         | Example                          | Phase     | Notes                                                                   |
| ------------- | -------------------------------- | --------- | ----------------------------------------------------------------------- |
| Interface     | `eth0` / `wlan0` / `bond0` / `br-lan`  | Scan      | Whichever NIC sees your LAN                                                        |
| Timezone      | `America/Los_Angeles`                     | System    | For correct timestamp display                                                              |
| Scan interval | `120` (seconds)                                   | Scan      | Balance scan frequency vs LAN noise                                                                       |
| Notification  | Shoutrrr URL                                              | Alerts    | e.g., `ntfy://ntfy.sh/my-topic` or `telegram://...`                                                                      |
| DB type       | `sqlite` (default) / `postgres`                                         | Storage   | Postgres for multi-instance setups                                                                                                  |
| InfluxDB      | Org, bucket, token, URL                                                           | Metrics   | Optional                                                                                                                                    |
| Auth          | **None built-in — use Authelia/ForAuth/Tailscale**                                            | Security  | WYL is not meant to be public                                                                                                                                              |

## Install via Docker

```sh
docker run -d --name wyl \
  -e "IFACES=eth0" \
  -e "TZ=America/Los_Angeles" \
  -e "TIMEOUT=120" \
  -e "SHOUTRRR_URL=ntfy://ntfy.sh/my-lan-alerts" \
  --network=host \
  -v /srv/wyl:/data/WatchYourLAN \
  --restart unless-stopped \
  aceberg/watchyourlan:2.x          # pin major/minor
```

Or Compose:

```yaml
services:
  wyl:
    image: aceberg/watchyourlan:2.x
    container_name: wyl
    network_mode: host
    environment:
      IFACES: eth0 wlan0                     # space-separated for multiple
      TZ: America/Los_Angeles
      TIMEOUT: "120"
      SHOUTRRR_URL: "telegram://<token>@telegram?chats=<chatid>"
      USE_DB: sqlite
      THEME: sand
      TRIM_HIST: "48"                         # drop history >48h old
    volumes:
      - /srv/wyl:/data/WatchYourLAN
    restart: unless-stopped
```

## Install native (Debian)

```sh
# From releases page
wget https://github.com/aceberg/WatchYourLAN/releases/download/2.x.x/watchyourlan_amd64.deb
sudo apt install ./watchyourlan_amd64.deb
sudo apt install arp-scan
systemctl enable --now watchyourlan
# Edit /etc/watchyourlan/config_v2.yaml; reload with systemctl restart watchyourlan
```

## First boot

1. Browse `http://<host>:8840/`
2. Host list populates after first scan interval (~2 minutes default)
3. Rename hosts (give friendly names: "Alice's iPhone", "living-room-esp32")
4. Set "ignore" on flaky-but-known devices to avoid offline/online notification spam
5. Test notification: disconnect a device → wait for scan → verify Shoutrrr message arrives
6. Optional: configure InfluxDB2 / Prometheus → build Grafana dashboard

## Data & config layout

- `/data/WatchYourLAN/` (or `/etc/watchyourlan/` native)
  - `config_v2.yaml` — main config (also editable via GUI)
  - `watchyourlan.db` — SQLite database of hosts + history
  - Logs

## Backup

```sh
tar czf wyl-$(date +%F).tgz /srv/wyl/
```

Not a backup priority — rebuildable after a few scan cycles. Main loss = friendly names + manual notes.

## Upgrade

1. Releases: <https://github.com/aceberg/WatchYourLAN/releases>. Active.
2. Docker: bump tag → restart.
3. Native: `apt install ./watchyourlan_amd64.deb` (new version).
4. Config migrations happen automatically for minor bumps; major (e.g., `config.yaml` → `config_v2.yaml` for 2.x) may require manual.
5. Read release notes — env var renames happen (e.g., `HIST_IN_DB` deprecated in 2.1.3).

## Gotchas

- **Host network mode is mandatory** — needs to see the LAN for ARP scans. Docker bridge networks won't work.
- **Host network = exposes WYL port on host** — port 8840 is accessible on your LAN by default. **Put WYL behind Authelia/Authentik/ForAuth/Tailscale** or bind it to `127.0.0.1` + reverse-proxy. Upstream warns about this explicitly.
- **No built-in auth.** WYL is NOT designed to be exposed to the internet. Treat like Pi-hole or Home Assistant — LAN-only or behind SSO.
- **ARP-scan on wireless** — some Wi-Fi drivers / APs don't respond to ARP well; may miss devices. `wlan0` often less reliable than wired `eth0`.
- **Multiple VLANs** — scan each via `ARP_ARGS` + multiple interfaces; see `docs/VLAN_ARP_SCAN.md`.
- **MAC randomization** — modern iOS/Android randomize MACs per-SSID, so each reconnection = "new device" alert. Mitigations: add static MAC reservations on your router; tell phones to use permanent MAC for this SSID; use ignore list.
- **Cloud/VPS** — doesn't make sense; WYL is LAN-scoped. Run on-prem only.
- **IPv6** — WYL focuses on ARP (IPv4); IPv6 Neighbor Discovery support varies. Check current state.
- **Host renamed often?** Router DHCP leases time out; hostname field may update to latest. Use friendly-name override.
- **Scan interval too low** = LAN noise + router CPU. 120 s is fine for most; 30 s is aggressive.
- **Postgres backend** — for multi-instance / HA WYL; usually overkill, SQLite is fine.
- **Grafana dashboard** — upstream repo has example dashboards under `/dashboards`.
- **Shoutrrr formatting** — multi-line notifications may truncate in some services; test.
- **Trendshift listing** — WYL is popular in the homelab community.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **NetAlertX (formerly Pi.Alert)** — broader LAN monitor + discovery + presence detection (separate recipe likely)
  - **PiHole Network Overview** — if you run Pi-hole, you already have a device list
  - **Unifi Network Controller** / **OPNSense/pfSense** — router-side device tracking
  - **Home Assistant Nmap/ARP tracker** — if you use HA, built-in presence tracking via same mechanism
  - **Netdisco** — Perl, enterprise LAN discovery
  - **nmap scripts** + cron + custom alerting — DIY
  - **Choose WYL if:** you want "Pi-hole-lite for device tracking" — simple, one service, Shoutrrr-friendly.
  - **Choose NetAlertX if:** you want richer presence + more device info + deeper dashboard.
  - **Choose Home Assistant if:** you already run HA and want device tracking as part of automations.

## Links

- Repo: <https://github.com/aceberg/WatchYourLAN>
- Docker Hub: <https://hub.docker.com/r/aceberg/watchyourlan>
- Releases: <https://github.com/aceberg/WatchYourLAN/releases>
- Compose example (no auth): <https://github.com/aceberg/WatchYourLAN/blob/main/docker-compose.yml>
- Compose example (with auth): <https://github.com/aceberg/WatchYourLAN/blob/main/docker-compose-auth.yml>
- VLAN ARP scan docs: <https://github.com/aceberg/WatchYourLAN/blob/main/docs/VLAN_ARP_SCAN.md>
- Shoutrrr (notification backends): <https://nicholas-fedor.github.io/shoutrrr/>
- Bootswatch themes: <https://bootswatch.com>
- ForAuth (simple auth companion): <https://github.com/aceberg/ForAuth>
- Donate: <https://github.com/aceberg#donate>
- NetAlertX alternative: <https://github.com/jokob-sk/NetAlertX>
