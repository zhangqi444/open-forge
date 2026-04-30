---
name: OctoPrint
description: "The snappy web interface for your 3D printer. Upload, slice, start, monitor, remote-control prints; plugin ecosystem (~400+) for every niche. Runs on a Raspberry Pi connected to the printer via USB. Python + Tornado. AGPL-3.0."
---

# OctoPrint

OctoPrint is *the* web interface for 3D printers — the default way hobbyists and small shops remotely manage FDM printers (Prusa, Ender, Voron, Creality, Anycubic, etc.). Connect a Raspberry Pi (or any Linux box) to your printer's USB port, install OctoPrint, and you have:

- **Web UI** — upload G-code, start/stop/pause prints, monitor temperature, control axes
- **Webcam streaming** — watch the print live + timelapse generation
- **400+ plugin ecosystem** — arc welder, bed visualizer, filament manager, PrettyGCode, Spaghetti Detective (AI failure detection), tailscale, ..., too many to list
- **Access control + multi-user**
- **Remote print queue**
- **GPIO + physical button control** (via plugins)
- **Slicer integration** — via plugins (CuraEngine, PrusaSlicer, Slic3r)
- **REST + JSON-RPC API** for home automation integration

- Upstream repo: <https://github.com/OctoPrint/OctoPrint>
- Website: <https://octoprint.org>
- Docs: <https://docs.octoprint.org>
- Plugin repo: <https://plugins.octoprint.org>
- Community forum: <https://community.octoprint.org>
- OctoPi image (recommended): <https://github.com/guysoft/OctoPi>

## Architecture in one minute

- **Python 3.7+** (older 3.6/3.8 phased out; current supports 3.9-3.13)
- **Tornado web server** + REST + WebSocket
- **Printer connection via USB serial** (or TCP for networked printers)
- **Single-user install common; multi-user for shared shops**
- **Pi-class host** is enough — Pi 3B, 4, Zero 2W all work
- **Webcam** — MJPEG stream (mjpg-streamer or ustreamer)

Crucial: **one printer per OctoPrint instance**. For multi-printer shops, run multiple instances (different ports) or use OctoFarm (meta-controller).

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                           |
| ----------- | ------------------------------------------------------- | --------------------------------------------------------------- |
| Raspberry Pi | **OctoPi image** — burn to SD card                         | **THE recommended path** for 95% of users                         |
| Single VM   | Docker (`octoprint/octoprint`)                               | Official image; USB passthrough tricky                                  |
| Single VM   | pip install in venv                                          | Devs + custom setups                                                     |
| Linux host  | OctoPrint-in-host-venv (systemd service)                          | For existing Pi/server                                                       |
| OctoPrint-docker | `octoprint/octoprint:latest` with `--device=/dev/ttyUSB0`   | Needs explicit USB device mapping                                                |

**Windows / macOS**: supported but uncommon — most people use a dedicated Pi.

## Inputs to collect

| Input            | Example                     | Phase     | Notes                                                          |
| ---------------- | --------------------------- | --------- | -------------------------------------------------------------- |
| Host             | Raspberry Pi 4 / Pi Zero 2W    | Hardware  | Pi 3B minimum; Pi Zero W struggles with webcam + multi-plugin       |
| Printer USB      | `/dev/ttyUSB0` or `/dev/ttyACM0` | Hardware  | `udev` rule for persistent name recommended                               |
| Webcam (opt)     | USB webcam / Pi camera module      | Hardware  | For live view + timelapse                                                          |
| Network          | Wi-Fi or Ethernet                   | Network   | Ethernet stabler for large uploads                                                          |
| Admin user       | first-run wizard                     | Bootstrap | Username/password                                                                                    |
| Remote access    | Tailscale / OctoEverywhere / ngrok      | Remote    | **Do NOT port-forward OctoPrint** publicly without auth/TLS                                                  |

## Install — OctoPi (recommended)

1. Download OctoPi image from <https://octoprint.org/download/>
2. Use Raspberry Pi Imager → pick "OctoPi (64-bit)" from the "OS" menu → advanced options → set Wi-Fi + hostname (`octopi.local`) + enable SSH
3. Flash to SD card → boot Pi with printer connected via USB
4. Browse `http://octopi.local` → first-run wizard creates admin user
5. Configure printer profile (bed size, bed heatable y/n, nozzle count) + connection settings

## Install via Docker

```yaml
services:
  octoprint:
    image: octoprint/octoprint:1.10.x   # pin to minor; check Docker Hub
    container_name: octoprint
    restart: unless-stopped
    ports:
      - "80:80"
    devices:
      - /dev/ttyACM0:/dev/ttyACM0           # adjust for your printer
      - /dev/video0:/dev/video0              # webcam
    volumes:
      - ./octoprint:/octoprint
    environment:
      ENABLE_MJPG_STREAMER: "true"
```

`/dev/ttyACM0` may vary — check `ls /dev/tty*` with printer connected vs disconnected.

## Install via pip (custom Linux host)

```sh
sudo apt install python3-pip python3-venv python3-dev build-essential libyaml-dev
python3 -m venv ~/octoprint
source ~/octoprint/bin/activate
pip install octoprint
~/octoprint/bin/octoprint serve --host=0.0.0.0 --port=5000
# Create systemd unit for production
```

## First boot

1. First-run wizard: welcome → admin user → access control → webcam config → printer profile → done
2. Connect → select serial port + baud rate → Connect button
3. Upload a small test G-code (temperature tower or calibration cube)
4. Click "Print" → verify everything works
5. Install plugins from Settings → Plugin Manager

## Remote access (important!)

**Do NOT directly port-forward OctoPrint to the internet.** It's been known-exploited when exposed (unauthenticated + buggy plugins).

Options:

- **OctoEverywhere** (free tier; paid plans) — upstream-friendly; tunneling
- **The Spaghetti Detective / Obico** — AI + remote access + webcam
- **Tailscale / ZeroTier / WireGuard** — your own VPN
- **Caddy/Nginx + Authelia/Authentik + TLS** — DIY reverse proxy
- **Cloudflare Tunnel + Access** — free; auth in front

## Data & config layout

Inside `~/.octoprint/` (Pi) or `/octoprint/octoprint/` (Docker):

- `config.yaml` — main config
- `users.yaml` — user credentials (hashed)
- `uploads/` — uploaded G-code files
- `timelapse/` + `timelapse/tmp/` — webcam timelapse output
- `logs/` — application + plugin logs
- `plugins/` — installed plugin data (some plugins)
- `printerProfiles/` — per-printer configs
- `.octoprint/data/<plugin>/` — plugin data

## Backup

```sh
# Via OctoPrint UI: Settings → Backup & Restore → Create Backup (zip)
# Or CLI:
tar czf octoprint-backup-$(date +%F).tgz ~/.octoprint
# NOTE: some plugins (e.g., Filament Manager) have separate DBs — include their paths
```

## Upgrade

1. OctoPrint itself: Settings → Software Update → Update button (checks GitHub releases)
2. OctoPi (full OS): `sudo octopi-update` — updates Pi OS + OctoPrint together
3. Docker: `docker compose pull && docker compose up -d`
4. pip install: `pip install --upgrade octoprint`
5. Plugins: Plugin Manager → check for updates → update each (or bulk)
6. **Check release notes** — occasional Python version bumps (e.g., Python 3.7 → 3.9 required) may require OctoPi image re-flash.

## Gotchas

- **One printer per instance.** For multi-printer shops, run multiple OctoPrint instances (different ports) or use OctoFarm as a meta-controller.
- **Pi Zero W struggles** — plugins + webcam + multiple users push it to OOM. Use Pi 3B or Pi 4 for reliability; Pi Zero 2W is fine for basic single-printer no-webcam.
- **USB serial naming** is unreliable — `/dev/ttyUSB0` can become `/dev/ttyUSB1` after reboot. Write a udev rule by USB serial ID for persistent device names, OR pin in OctoPrint to the specific ID: <https://docs.octoprint.org/en/master/plugins/persistent-usb-names.html>.
- **Webcam quality and URL** — OctoPi defaults to mjpg-streamer on port 8080; OctoPrint loads it at `/webcam/?action=stream`. Configure the stream URL in Settings → Webcam.
- **Timelapse disk usage** — each frame is a JPEG; 12-hour prints can produce gigabytes of frames. Auto-delete after render, or mount a larger disk.
- **Plugin quality varies** — some plugins are abandoned, incompatible with OctoPrint 1.10+, or introduce security issues. Check plugin repo date + reviews before installing.
- **DO NOT expose OctoPrint directly to the internet.** Either use Obico/OctoEverywhere/Tailscale, or put it behind a reverse proxy with strong auth + TLS + fail2ban.
- **Access Control enforcement** — the first-run wizard enables it; don't disable. Without, anyone on your LAN can start prints / trigger heating.
- **Anonymous webcam** — Settings → Webcam → embed authenticated snapshot/stream, else your MJPEG stream is world-readable on your LAN by default.
- **PrusaLink** — Prusa's own webUI shipped with MK3S/MK4/Mini — competes with OctoPrint. Some features (live camera, Prusa Connect remote) are PrusaLink-only. OctoPrint still installs alongside for plugin richness.
- **Klipper + Mainsail/Fluidd** — if you run Klipper firmware (common on Voron, custom builds), **use Mainsail or Fluidd instead** — they're purpose-built for Klipper's Moonraker API. OctoPrint works with Klipper via plugins but is not the native choice.
- **Slicing on Pi is slow** — slice on your desktop, upload G-code. Pi-hosted slicers exist but aren't recommended.
- **OctoPrint 1.10+ requires Python 3.9+** — older OctoPi images (< 1.0) shipped Python 3.7 and need a fresh OctoPi burn to upgrade.
- **Filament sensor / runout** via plugin + wiring to Pi GPIO. Powerful but DIY.
- **Printer firmware matters** — Marlin 2.x works well; Klipper better with Mainsail; older RepRap firmwares have quirks.
- **Security-audit your plugins periodically** — plugins have the same privileges as OctoPrint itself.
- **Community forum is active** — <https://community.octoprint.org> for plugin help + troubleshooting.
- **AGPL-3.0 license** — strong copyleft; modifications to your OctoPrint fork deployed over network must be shared if you distribute.
- **OctoPrint Patreon** — creator Gina Häußge maintains it largely alone. If OctoPrint saves your prints, support on Patreon: <https://patreon.com/foosel>.
- **Alternatives worth knowing:**
  - **Mainsail** — Klipper-native web UI; modern Vue.js; excellent if you run Klipper
  - **Fluidd** — Klipper-native; similar to Mainsail; Vue.js
  - **Duet Web Control (DWC)** — for Duet boards
  - **PrusaLink** — Prusa printers only
  - **Repetier-Server** — multi-printer; commercial ($30ish) + free edition
  - **OctoFarm** — meta-controller for many OctoPrint instances
  - **The Spaghetti Detective / Obico** — AI-enhanced remote + print-failure detection; free tier + paid
  - **OctoEverywhere** — free tunneling + remote for OctoPrint
  - **Choose OctoPrint if:** you have a Marlin/RepRap-firmware printer + want the biggest plugin ecosystem + Pi-based local control.
  - **Choose Mainsail/Fluidd if:** you run Klipper firmware.

## Links

- Repo: <https://github.com/OctoPrint/OctoPrint>
- Website: <https://octoprint.org>
- Docs: <https://docs.octoprint.org>
- Community forum: <https://community.octoprint.org>
- Plugin repo: <https://plugins.octoprint.org>
- OctoPi image: <https://github.com/guysoft/OctoPi>
- Download page: <https://octoprint.org/download/>
- Docker Hub: <https://hub.docker.com/r/octoprint/octoprint>
- Releases: <https://github.com/OctoPrint/OctoPrint/releases>
- Security advisories: <https://github.com/OctoPrint/OctoPrint/security/advisories>
- Patreon: <https://patreon.com/foosel>
- Mailing list: <https://octoprint.org/discord>
- Changelog: <https://github.com/OctoPrint/OctoPrint/releases>
