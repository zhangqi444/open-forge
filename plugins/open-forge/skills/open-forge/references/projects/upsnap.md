---
name: UpSnap
description: "Simple Wake-on-LAN web app — one-click device wake-up dashboard, scheduled wakeups via cron, ping + port checks, network scan to discover devices (nmap), custom shutdown commands, user management. SvelteKit + Go + PocketBase. Single binary. MIT."
---

# UpSnap

UpSnap is **a beautifully simple Wake-on-LAN (WoL) web app** — add your devices, hit a big button, they wake up. Plus: scheduled wake/shutdown via cron-style schedules, per-device ping/port probes to show "is it online?", **nmap-powered network discovery** to bulk-add devices, custom shutdown commands (SSH/winrm/API), user management with RBAC, 35 themes. Built with **SvelteKit + Go + PocketBase** — a single binary + SQLite; *extremely* easy to deploy on a homelab Pi/NAS.

Author: **seriousm4x**. Active development, friendly community.

> **🛡️ Upstream anti-scam notice (verbatim from README):**
>
> *"UpSnap is, and always will be, free and open source software. If someone is asking you to pay money for access to UpSnap binaries, source code, or licenses, you are being scammed. The official and only trusted source for UpSnap is this repository (and its linked releases)."*
>
> Quoting this directly because: (a) upstream wants it said, (b) scam variants exist for popular FOSS homelab tools.

Features:

- **🚀 One-click wake-up dashboard** — prettiest WoL UX in the genre
- **⏰ Scheduled events** (cron) — wake the NAS at 7 AM weekdays, shut it down at midnight
- **🔌 Per-device ping + port probes** — green/red status at a glance
- **🔍 Network scan** (via nmap) — auto-discover devices to add
- **❎ Shutdown command** — custom command per device (SSH/PowerShell/REST)
- **👤 User management** + RBAC (admin / user)
- **🌐 i18n** — many community-translated languages
- **🎨 35 themes** (DaisyUI)
- **🐳 Docker images** — amd64, arm64, arm/v7, arm/v6 (covers every Pi)

- Upstream repo: <https://github.com/seriousm4x/UpSnap>
- Docker images (GHCR): <https://github.com/seriousm4x/UpSnap/pkgs/container/upsnap>
- Docker Hub: <https://hub.docker.com/r/seriousm4x/upsnap>
- Wiki: <https://github.com/seriousm4x/UpSnap/wiki>
- Releases: <https://github.com/seriousm4x/UpSnap/releases>

## Architecture in one minute

- **Single statically-linked Go binary** embedding PocketBase + SvelteKit frontend
- **SQLite** via PocketBase — all state
- **Sends magic packets** (UDP :9) to device MAC addresses on local broadcast
- **nmap** (optional) for network scan
- **Host networking** or bridge with port mapping — host networking preferred so WoL magic packets reach the right broadcast domain
- **Resource**: tiny — <100 MB RAM, minuscule CPU

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                         |
| ------------------ | --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Raspberry Pi / NAS | **Docker with `--network=host`**                                    | **Upstream-recommended; #1 homelab fit**                                         |
| Single VM          | **Docker with host networking**                                             | Same                                                                                       |
| Any Linux          | **Binary + systemd**                                                                         | Also supported                                                                                            |
| Windows / macOS    | Binaries available; less common                                                                                | Works                                                                                                                 |
| Kubernetes         | Needs hostNetwork=true; niche                                                                                              |                                                                                                                                           |

## Inputs to collect

| Input              | Example                             | Phase       | Notes                                                                    |
| ------------------ | ----------------------------------- | ----------- | ------------------------------------------------------------------------ |
| Domain             | `upsnap.home.lan`                       | URL         | Optional — many just use IP:port                                                 |
| Port               | `8090` default                                  | Network     | Change via `UPSNAP_HTTP_LISTEN`                                                          |
| Devices            | Name, MAC address, IP, broadcast IP          | Setup       | **MAC is the critical field** for WoL                                                                    |
| Admin account      | first user via setup                                      | Bootstrap   | Strong password                                                                                                |
| nmap (opt)         | for network scan                                                 | Features    | Apt/yum; container image includes it                                                                                                    |
| Shutdown commands  | SSH key or script per device                                              | Optional    | For "turn off" as well as "turn on"                                                                                                              |

## Install via Docker (host networking)

```yaml
services:
  upsnap:
    image: ghcr.io/seriousm4x/upsnap:5                # pin major version
    container_name: upsnap
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./data:/app/pb_data
    environment:
      UPSNAP_HTTP_LISTEN: "0.0.0.0:8090"
      TZ: Europe/Berlin
```

Browse `http://<host>:8090/` → create admin → add devices.

## Install via binary

```sh
wget https://github.com/seriousm4x/UpSnap/releases/download/v5.x.x/upsnap_linux_amd64
chmod +x upsnap_linux_amd64
sudo ./upsnap_linux_amd64 serve --http=0.0.0.0:8090
```

Systemd unit per Wiki.

## First boot

1. Browse `http://<host>:8090/` → **first-visit** wizard creates admin user
2. **Devices → Add** → name, **MAC address** (critical), IP (for ping), broadcast IP (usually subnet `.255`), port (for probe)
3. Test: click wake button → device wakes (verify physically or via ping)
4. (Optional) **Network scan** → nmap sweep of subnet → bulk-add discovered devices
5. Schedule events: `Devices → <device> → Schedules → Add` → cron expression → wake or shutdown
6. Configure shutdown command (SSH): `ssh -i /app/pb_data/ssh_key user@192.168.1.x sudo shutdown -h now`
7. Invite other users if needed

## Data & config layout

- `/app/pb_data/` (container) — PocketBase SQLite + attachments + SSH keys
- Backup = tar this directory

## Backup

```sh
sudo tar czf upsnap-$(date +%F).tgz data/
```

Small, fast, easy.

## Upgrade

1. Releases: <https://github.com/seriousm4x/UpSnap/releases>. Active.
2. Docker: bump tag; PocketBase migrations automatic.
3. **Back up `pb_data/` before major version jumps** (5.x etc.).
4. **Read release notes for breaking changes** in major versions.

## Gotchas

- **Host networking (`--network=host`) strongly recommended.** Magic-packet broadcasts need to reach the device's broadcast domain; Docker bridge NAT typically breaks this. On macOS/Windows Docker Desktop, host networking is emulated — WoL may not work correctly; run UpSnap on Linux directly.
- **WoL enablement on target device**: WoL-over-LAN must be **enabled in BIOS/UEFI + OS network adapter settings**. Many consumer PCs ship with WoL disabled or tied to specific adapters. Test with `wakeonlan` CLI before blaming UpSnap.
- **Broadcast IP**: must match the device's subnet. For `192.168.1.0/24` use `192.168.1.255`. Getting this wrong = magic packet goes nowhere.
- **Cross-VLAN WoL**: by default, routers don't forward broadcast → WoL across VLANs fails. Solutions:
  - Configure router to forward directed broadcast (`ip directed-broadcast` on Cisco) — **security caution**
  - Run UpSnap instance on each VLAN
  - WoL-over-UDP proxy/relay
- **Wi-Fi WoL (WoWLAN)**: flaky on many devices. Wired Ethernet is reliable; Wi-Fi often isn't. Tell users up front.
- **Shutdown command security**: storing SSH keys in UpSnap means compromise of the host = compromise of those keys. Use dedicated low-privilege SSH users + scoped `sudoers` for `shutdown`. (Principle-of-least-privilege extends across batches.)
- **Scheduled events + time-zone**: set `TZ` in container; cron expressions interpreted per container time.
- **Port scanning**: nmap's network scan is useful but your users/IDS may flag it. Fine on personal homelab; ask-first on work networks.
- **Authentication mandatory**: UpSnap supports user management — enable it. Exposing an unauthenticated WoL+shutdown tool to the internet = bad. Keep behind VPN / reverse proxy with auth.
- **Anti-scam notice matters**: as quoted above, upstream explicitly warns against paid resellers. If you see "UpSnap Pro" or similar paid variants on random sites — it's not official. Always grab from GitHub.
- **PocketBase under the hood**: UpSnap is built on PocketBase (Go-based Firebase-alike). If you know PocketBase, the `/_/` admin UI gives raw DB access (change `PB_DATA` to migrate).
- **Browser notifications** for event completion (cron wake succeeded): supported via web push.
- **API**: PocketBase exposes a full REST API; can trigger wakes programmatically from Home Assistant / n8n / scripts.
- **Home Assistant integration**: use HA's native WoL service OR UpSnap's API. UpSnap dashboard often better than HA's wake-only.
- **Audio alerts in UI**: some users find them helpful; configurable.
- **License**: **MIT**.
- **Alternatives worth knowing:**
  - **Home Assistant** — broader home automation; has WoL service (separate recipe)
  - **WOL Magic Packet CLI** — `wakeonlan` / `etherwake` — simplest, no UI
  - **GOTIFY / ntfy + scripts** — roll-your-own
  - **SupaLaunch / Wakey** — niche alternatives
  - **Proxmox VE** — if you're running Proxmox, it has built-in WoL for managed hosts
  - **UniFi Network app** — if on UniFi, it can WoL
  - **Choose UpSnap if:** you want a dedicated, beautiful, scheduled WoL tool + shutdown + network-scan. Best-in-class for this specific niche.
  - **Choose Home Assistant if:** WoL is one of many automations.
  - **Choose CLI `wakeonlan` if:** no UI needed.

## Links

- Repo: <https://github.com/seriousm4x/UpSnap>
- Wiki: <https://github.com/seriousm4x/UpSnap/wiki>
- Docker (GHCR): <https://github.com/seriousm4x/UpSnap/pkgs/container/upsnap>
- Docker Hub: <https://hub.docker.com/r/seriousm4x/upsnap>
- Releases: <https://github.com/seriousm4x/UpSnap/releases>
- Non-root user guide: <https://github.com/seriousm4x/UpSnap/wiki/Use-non%E2%80%90root-user>
- Shutdown guide: <https://github.com/seriousm4x/UpSnap/wiki/How-to-use-shutdowns>
- PocketBase (underlying fw): <https://pocketbase.io>
- Home Assistant WoL: <https://www.home-assistant.io/integrations/wake_on_lan/>
