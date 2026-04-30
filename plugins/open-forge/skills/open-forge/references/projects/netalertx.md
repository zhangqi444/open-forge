---
name: NetAlertX
description: "LAN network intruder detector + monitoring tool (formerly Pi.Alert/PiAlert). Scans local network, alerts on unknown devices, tracks uptime, session history, names + groups devices. Plugin ecosystem. Python + PHP + SQLite. GPL-3.0."
---

# NetAlertX

NetAlertX (formerly **Pi.Alert** / **PiAlert**) is **a LAN network scanner + intruder-detection system**. It periodically sweeps your network (arp-scan / nmap / pholus / mikrotik / unifi / dhcp-leases / fritzbox / etc.) and maintains a database of every MAC address that has ever connected. New device appears? You get an alert (Email / Telegram / Discord / Pushover / Webhook / MQTT / etc.). Device offline too long? Alert. Device back online? Alert. Great for home labs + "did someone new just join my WiFi?"

**Rename history**: Pi.Alert → PiAlert → NetAlertX. Same project, same lineage; current name is NetAlertX. Old docs + containers reference the old names.

Features:

- **Multi-scanner architecture** (plugins):
  - `arp-scan` (Linux)
  - `nmap`
  - `pholus` (passive)
  - FritzBox / Mikrotik / UniFi / OpenWrt DHCP leases
  - Tailscale peer list
  - DD-WRT
- **Session tracking** — every connect/disconnect per device; history for months/years
- **Device naming + grouping** — iPhone vs NAS vs "unknown intruder"
- **Vendor lookup** — OUI database for MAC → vendor
- **Internet uptime monitor** — pings gateway + configured URLs
- **Alerts**: Email, Telegram, Discord, Slack, Pushover, MQTT, Webhook, ntfy, Apprise
- **Device icons** — custom per-device
- **Presence detection** — "Alice's phone is home/away"
- **Plugin system** — add custom scanners + notifiers in Python
- **Web UI** — dark mode; mobile-friendly
- **REST API**
- **Port scanning** (nmap) for security auditing
- **Speed test integration** (optional plugin)

- Upstream repo: <https://github.com/netalertx/NetAlertX>
- Wiki / Docs: <https://github.com/netalertx/NetAlertX/wiki>
- Docker Hub: <https://hub.docker.com/r/jokobsk/netalertx>
- Discord: <https://discord.gg/netalertx>

## Architecture in one minute

- **Python** daemon for scanning + event processing
- **PHP** web UI
- **SQLite** as DB
- **Apache** or nginx for serving UI
- **Single Docker container** packages it all
- **Requires host network or bridge with elevated privileges** — it's scanning your LAN

## Compatible install methods

| Infra          | Runtime                                                    | Notes                                                                         |
| -------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM      | **Docker (`jokobsk/netalertx:latest`)**                        | **Upstream-recommended**                                                          |
| Single VM      | Native install (Debian/Ubuntu)                                         | Supported; more fiddly                                                                    |
| Raspberry Pi   | Docker or native (arm32/arm64)                                                     | Common — this is "Pi.Alert" origin                                                                  |
| Synology / QNAP | Docker                                                                                | Works; needs host networking                                                                                           |
| Kubernetes     | Possible but atypical (host-scan access complicates)                                              |                                                                                                                                  |

## Inputs to collect

| Input                | Example                                    | Phase      | Notes                                                                        |
| -------------------- | ------------------------------------------ | ---------- | ---------------------------------------------------------------------------- |
| LAN subnet           | `192.168.1.0/24`                                | Config     | What to scan                                                                          |
| Host network mode    | required                                        | Network    | Needs raw network access for arp-scan                                                            |
| Web UI port          | `20211` (container) / map to host                          | UI         | Default                                                                                                    |
| Scanner cron         | every 5 min                                                 | Config     | More frequent = more traffic                                                                                               |
| Notifier tokens      | Discord webhook / Telegram bot / etc.                                | Alerts     | At least one                                                                                                                               |
| Admin password       | set in config                                                                   | Security   | UI-level auth                                                                                                                                          |

## Install via Docker

```yaml
services:
  netalertx:
    image: jokobsk/netalertx:latest               # pin in prod
    container_name: netalertx
    restart: unless-stopped
    network_mode: host                             # required for arp-scan
    volumes:
      - ./config:/app/config
      - ./db:/app/db
      - ./logs:/app/log
    environment:
      TZ: America/Los_Angeles
      PORT: 20211
```

Browse `http://<host>:20211/`.

## First boot

1. UI loads → dashboard shows currently-connected devices (first scan running)
2. **Maintenance → Settings** → configure your LAN subnet + scanners (enable `arp-scan`, optionally `nmap`)
3. Configure notifiers — Discord/Telegram/Email
4. Run a manual scan (menu → Run Scan)
5. Name devices + assign owners + set icons
6. Enable **New device** alerts → test by connecting a guest phone

## Data & config layout

- `config/app.conf` — main config (subnets, scanners, notifiers, thresholds)
- `db/netalertx.db` — SQLite (devices + sessions + events)
- `logs/` — scan logs

## Backup

```sh
tar czf nax-$(date +%F).tgz config/ db/
```

## Upgrade

1. Releases: <https://github.com/netalertx/NetAlertX/releases>. Very active.
2. Docker: bump tag → migrations auto (but back up DB first).
3. Config format changes occasionally — read release notes.

## Gotchas

- **Rename history**: Pi.Alert → PiAlert → NetAlertX. Docker images changed hands: old `jokob-sk/Pi.Alert` → `jokobsk/netalertx`. Old tutorials reference obsolete names.
- **Host networking required** on Linux — arp-scan needs raw sockets. On macOS Docker + Windows Docker Desktop, networking-mode-host has limited support; some features degrade.
- **Scan frequency vs network load**: every 1 min is noisy; every 5-15 min is sane. Devices showing flapping = scan interval too slow vs DHCP reassignment.
- **MAC randomization on modern devices** (iOS 14+, Android 10+, Windows 10+) breaks "one device = one MAC." Devices appear as new each time they connect. Options: (a) disable random MAC per-network in device settings, (b) use DHCP client-ID for stability, (c) accept + curate.
- **False-positive intrusion alerts** from MAC randomization are by far the biggest operational annoyance. Tune thresholds.
- **Privacy**: logs every device on your LAN + session history. Don't expose this UI publicly. Internal + auth.
- **OUI database updates** — run periodically to keep vendor names fresh.
- **Pi.Alert → NetAlertX migration**: DB is compatible; just change container image.
- **UniFi / FritzBox / Mikrotik plugins** require credentials — don't use your admin account; create read-only users on each where possible.
- **Internet uptime monitoring**: the ping/HTTP check plugin is useful for "is my internet actually up" visualization.
- **Port scanning (nmap)** can trigger ISP / enterprise IDS alarms. Use judiciously on LAN only.
- **Tailscale integration**: list Tailscale peers as "devices"; useful for remote-family visualization.
- **Plugin system**: community-authored plugins exist for Home Assistant, Mealie, Shelly, etc. Check `/plugins` directory.
- **Android devices in "doze"** disappear from arp-scan (they drop off network); appear as "offline" even when still physically nearby. Know this.
- **Webhook/MQTT integrations**: NetAlertX can push events into Home Assistant, node-RED, etc. Powerful for automation (e.g., "someone's home → lights on").
- **No auth by default** on some older builds — add reverse proxy auth.
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Fing** — commercial SaaS + mobile app; easier UX; not self-hosted
  - **WatchYourLAN** — similar concept; Go-based; simpler (separate recipe: batch 61)
  - **Home Assistant Device Tracker** — if you run HA, built-in arp/ping/nmap device tracking
  - **nmap + cron + custom script** — DIY route
  - **RUSTDesk / Tailscale** — peer lists (tangential, Tailscale only)
  - **Choose NetAlertX if:** you want rich multi-scanner + notifications + plugin ecosystem.
  - **Choose WatchYourLAN if:** you want lighter-weight arp-scan with a simple UI.
  - **Use Home Assistant device tracker if:** you're deep in HA ecosystem and want native integration.

## Links

- Repo: <https://github.com/netalertx/NetAlertX>
- Wiki / Docs: <https://github.com/netalertx/NetAlertX/wiki>
- Installation: <https://github.com/netalertx/NetAlertX/wiki/Install-NetAlertX>
- Docker Hub: <https://hub.docker.com/r/jokobsk/netalertx>
- Releases: <https://github.com/netalertx/NetAlertX/releases>
- Discord: <https://discord.gg/netalertx>
- Plugins: <https://github.com/netalertx/NetAlertX/tree/main/front/plugins>
- WatchYourLAN (alt): <https://github.com/aceberg/WatchYourLAN>
- Fing (alt commercial): <https://www.fing.com>
