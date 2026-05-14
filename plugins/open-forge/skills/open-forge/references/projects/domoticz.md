# Domoticz

Free, open-source home automation system for Linux, Windows, macOS, and Raspberry Pi. Domoticz monitors and controls lights, switches, and sensors (temperature, rain, wind, UV, energy, gas, water) across 150+ supported hardware types including Z-Wave, Zigbee, MQTT, Philips Hue, RFXCOM, and P1 Smart Meters.

**Official site:** https://www.domoticz.com/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi / ARM | Docker (`linuxserver/domoticz`) | Most common Pi deployment |
| Any Linux host | Docker Compose | `linuxserver/domoticz` image |
| Any Linux host / macOS / Windows | Native binary | Pre-built releases available |
| Raspberry Pi | Native binary | Official ARM builds |

---

## Inputs to Collect

### Phase 1 — Planning
- Hardware devices to integrate (Z-Wave dongle, Zigbee stick, MQTT broker, etc.)
- Serial device paths for USB dongles (e.g. `/dev/ttyUSB0`, `/dev/ttyACM0`)
- Web UI port (default `8080`)
- Whether to use HTTPS (port `1443`)

### Phase 2 — Deployment
- `PUID` / `PGID` — Linux user/group ID for file permissions
- `TZ` — timezone
- Volume path for config and SQLite database

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  domoticz:
    image: lscr.io/linuxserver/domoticz:latest
    container_name: domoticz
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config:/config
    ports:
      - "8080:8080"   # HTTP web UI
      - "1443:1443"   # HTTPS web UI
      - "6144:6144"   # Syslog
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0   # USB dongle (Z-Wave/Zigbee/RFXCOM)
    restart: unless-stopped
```

> **Note:** List each USB hardware device under `devices:`. The `linuxserver/domoticz` image handles PUID/PGID for proper file ownership.

### Environment Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `PUID` | `1000` | User ID for file ownership |
| `PGID` | `1000` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Timezone |
| `WEBROOT` | — | Optional URL subpath (e.g. `domoticz`) |
| `DBASE` | — | Custom database file path |
| `DOMOTICZ_ADMIN_PASSWORD` | — | Auto-provision admin password on first run (Docker) |
| `DOMOTICZ_ADMIN_USERNAME` | `admin` | Auto-provision admin username on first run (Docker, optional) |

### Native Install (Linux)

```bash
# Install via installer script
curl -sSL install.domoticz.com | sudo bash

# Or download from https://releases.domoticz.com/
```

### Config Paths (Docker)
- `/config/` — all Domoticz data including `domoticz.db` (SQLite)
- `/config/plugins/` — Python plugins directory
- `/config/scripts/` — event scripts (dzVents, Lua, Python)

### Web UI
- HTTP: `http://localhost:8080`
- HTTPS: `https://localhost:1443`

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**Native:** Download new release from https://releases.domoticz.com/, stop service, replace binary, restart.

---

## Gotchas

- **USB device passthrough is required** for hardware dongles — list each device in the `devices:` section. The container user must have permission to access the device.
- **`/dev/ttyUSB0` vs `/dev/ttyACM0`** — Z-Wave/RFXCOM typically use ttyUSB0; Arduino-based Zigbee coordinators often use ttyACM0. Run `ls /dev/tty*` before and after plugging in the dongle to find the correct path.
- **Add container user to `dialout` group** on the host for serial device access: `sudo usermod -aG dialout $USER`.
- **Default admin account** is created via the setup wizard on first run. Set a password immediately.
- **MQTT integration:** Domoticz has built-in MQTT support — configure in Settings → Hardware.
- **Python plugins** go in `/config/plugins/` — restart Domoticz after installing new plugins.

---

## References
- GitHub: https://github.com/domoticz/domoticz
- Official site: https://www.domoticz.com/
- Wiki: https://wiki.domoticz.com/
- Forum: https://forum.domoticz.com/
- linuxserver image: https://docs.linuxserver.io/images/docker-domoticz/
- Releases: https://releases.domoticz.com/
