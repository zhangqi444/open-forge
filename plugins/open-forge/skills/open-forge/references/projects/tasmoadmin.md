---
name: TasmoAdmin
description: "Self-hosted admin platform for Tasmota IoT devices. Docker/PHP. TasmoAdmin/TasmoAdmin. Auto-scan network for Tasmota devices, mass OTA firmware updates, remote config, command sending, sensor monitoring, Home Assistant addon. MIT."
---

# TasmoAdmin

**Self-hosted admin platform for Tasmota-flashed IoT devices.** Auto-scan your network to discover all devices running [Tasmota](https://tasmota.github.io/), update firmware in bulk, configure remotely, send commands, and monitor sensor data — all from a web UI. Runs as a Docker container, standalone web server, or Home Assistant addon.

Built + maintained by **TasmoAdmin team**. MIT license.

- Upstream repo: <https://github.com/TasmoAdmin/TasmoAdmin>
- Docker image: `ghcr.io/tasmoadmin/tasmoadmin`
- Home Assistant addon: <https://github.com/hassio-addons/addon-tasmoadmin>
- Discord: <https://discord.gg/gG2VDsSKWt>

## Architecture in one minute

- **PHP 8.2** + Nginx (Alpine-based Docker image)
- Port **80** (or custom)
- Data stored in `TASMO_DATADIR` volume
- Multi-arch: **amd64** (Synology DSM), **arm** (Raspberry Pi 3), **arm64** (Pine64)
- Resource: **very low** — PHP + Nginx; runs on a Pi Zero

## Compatible install methods

| Infra              | Runtime                        | Notes                                                    |
| ------------------ | ------------------------------ | -------------------------------------------------------- |
| **Docker**         | `ghcr.io/tasmoadmin/tasmoadmin` | **Primary** — multi-arch; see compose in repo            |
| **Home Assistant** | HA addon                        | Install from Home Assistant community add-ons store      |
| **Web server**     | PHP 8.1+ + Apache/Nginx        | Any PHP web server                                       |

## Install via Docker

```yaml
services:
  tasmoadmin:
    image: ghcr.io/tasmoadmin/tasmoadmin:latest
    restart: unless-stopped
    ports:
      - "9541:80"
    environment:
      - TASMO_DATADIR=/data/tasmoadmin
    volumes:
      - tasmoadmin_data:/data/tasmoadmin

volumes:
  tasmoadmin_data:
```

```bash
docker compose up -d
```

Visit `http://localhost:9541`.

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `TASMO_DATADIR` | `./tasmoadmin/data` | Path to store TasmoAdmin data |
| `TASMO_BASEURL` | (none) | Set if running behind a reverse proxy with a base path |

## Features overview

| Feature | Details |
|---------|---------|
| Device auto-scan | Network scan to discover all Tasmota devices automatically |
| Device list | View all devices with IP, hostname, firmware version, sensors |
| Bulk firmware update | Select devices → download latest from Tasmota OTA server → update |
| OTA update modes | Automatic (latest) or manual firmware URL |
| Device configuration | Edit Tasmota settings remotely from the web UI |
| Command sending | Send Tasmota commands to selected devices |
| Sensor support | Display data from multiple sensor types |
| Night mode | Auto/manual dark mode |
| Mobile responsive | Bootstrap 4; works on phones and tablets |
| Login protection | Username/password login |
| Self-update | TasmoAdmin can update itself (disabled in Docker installs) |

## First boot

1. Start TasmoAdmin via Docker.
2. Visit `http://localhost:9541` → log in with default credentials (check the wiki).
3. Go to **Settings → AutoScan** → configure your network range (e.g. `192.168.1.0/24`).
4. Run **AutoScan** — TasmoAdmin discovers all Tasmota devices on the network.
5. Devices appear in the dashboard with IP, firmware version, and sensor data.
6. Select devices → **Update** to perform a bulk OTA firmware update.
7. Click a device → **Config** to remotely change Tasmota settings.
8. Send Tasmota commands from the **Commands** tab.

## Tasmota compatibility

TasmoAdmin works with any device running [Tasmota firmware](https://tasmota.github.io/) — typically ESP8266/ESP32-based devices like:
- Sonoff switches, sockets, relays
- Shelly devices flashed with Tasmota
- WLED-compatible LED controllers flashed with Tasmota
- Generic ESP8266/ESP32 smart home devices

## Gotchas

- **Network scan requires same subnet.** AutoScan works by IP range scan. TasmoAdmin must be on the same network segment as the Tasmota devices (or have routing to them). VLANs/subnets require network-level access.
- **Self-update disabled in Docker.** The built-in self-update feature is disabled when running as a Docker container. Update by pulling a new image.
- **Login credentials.** Check the wiki/docs for default credentials on first run, then change them immediately.
- **Tasmota devices must have the HTTP API enabled.** TasmoAdmin communicates with Tasmota via its HTTP API. Ensure Tasmota's web server (HTTP API) is enabled on each device (enabled by default on most Tasmota builds).
- **Firmware URL must be reachable by the device.** For OTA updates, Tasmota downloads the firmware from the URL TasmoAdmin provides. Ensure the firmware URL is reachable from the Tasmota device (not from the TasmoAdmin server). The default is the Tasmota public OTA server.

## Backup

```sh
docker run --rm -v tasmoadmin_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/tasmoadmin-$(date +%F).tgz /data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Home Assistant addon

TasmoAdmin is also available as a Home Assistant Community Add-on for users who prefer to manage it within Home Assistant Supervisor:

```
Settings → Add-ons → Add-on Store → Community Add-ons → TasmoAdmin
```

## Project health

Active PHP development, multi-arch Docker, Home Assistant addon, Discord community. MIT license.

## Tasmota-management-family comparison

- **TasmoAdmin** — PHP, web UI, bulk OTA, config, commands, auto-scan, MIT
- **Tasmota native web UI** — each device has its own per-device UI; no central management
- **Home Assistant** — can manage Tasmota via MQTT discovery; much broader scope
- **Node-RED** — flow-based automation; can call Tasmota HTTP API; not a device manager

**Choose TasmoAdmin if:** you have multiple Tasmota devices and want a centralized web UI for bulk firmware updates, remote configuration, and command execution — without pulling in a full Home Assistant stack.

## Links

- Repo: <https://github.com/TasmoAdmin/TasmoAdmin>
- Docker guide wiki: <https://github.com/reloxx13/TasmoAdmin/wiki/Guide-for-TasmoAdmin-on-Docker>
- Home Assistant addon: <https://github.com/hassio-addons/addon-tasmoadmin>
- Discord: <https://discord.gg/gG2VDsSKWt>
