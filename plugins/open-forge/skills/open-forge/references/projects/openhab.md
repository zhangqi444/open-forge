# openHAB

openHAB (open Home Automation Bus) is a vendor-neutral, hardware/protocol-agnostic home automation platform written in Java/OSGi. It integrates hundreds of smart home devices and services through a binding system, with rule-based automation, persistent data, and multiple UI options.

**Website:** https://www.openhab.org
**Source:** https://github.com/openhab/openhab-core
**License:** EPL-2.0
**Stars:** ~1,108

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi / ARM | openHABian (recommended) | Turnkey Pi image |
| Any Linux | Docker / Docker Compose | Official image |
| Any Linux | Manual DEB/RPM packages | Debian/Ubuntu/RHEL |
| Any | openHAB Cloud | Requires openHAB Cloud connector add-on |
| Windows / macOS | Manual install | Development/testing |

---

## Inputs to Collect

### Phase 1 — Planning
- Hardware: Raspberry Pi (use openHABian) or generic Linux server
- Smart home protocols: Z-Wave (USB stick), Zigbee, MQTT, KNX, Philips Hue, etc.
- Storage: local or NFS/NAS for persistence
- Remote access: openHAB Cloud account (free, for remote/app access)

### Phase 2 — Deployment
- `OPENHAB_HTTP_PORT` (default: 8080)
- `OPENHAB_HTTPS_PORT` (default: 8443)
- USB device path (e.g. `/dev/ttyUSB0`) for Z-Wave/Zigbee dongles
- Timezone

---

## Software-Layer Concerns

### Method 1: openHABian (Raspberry Pi — Recommended)

openHABian is a purpose-built OS image for Raspberry Pi:
1. Download from https://github.com/openhab/openhabian/releases
2. Flash to microSD with Raspberry Pi Imager or balenaEtcher
3. Boot the Pi — first-boot setup takes ~15-30 minutes
4. Access web UI at `http://openhabian:8080`

### Method 2: Docker Compose
```yaml
services:
  openhab:
    image: openhab/openhab:latest
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./openhab_addons:/openhab/addons
      - ./openhab_conf:/openhab/conf
      - ./openhab_userdata:/openhab/userdata
    environment:
      - OPENHAB_HTTP_PORT=8080
      - OPENHAB_HTTPS_PORT=8443
      - USER_ID=1000
      - GROUP_ID=1000
      - TZ=America/New_York
    # Uncomment to pass USB dongle (Z-Wave, Zigbee)
    # devices:
    #   - /dev/ttyUSB0:/dev/ttyUSB0
```

```bash
docker compose up -d
# Access at http://localhost:8080
```

> **Note:** `network_mode: host` is recommended for full mDNS/UPnP device discovery.

### Method 3: Debian/Ubuntu Packages
```bash
# Add openHAB repository
curl -fsSL "https://openhab.jfrog.io/artifactory/api/gpg/key/public" | sudo gpg --dearmor -o /usr/share/keyrings/openhab.gpg
echo 'deb [signed-by=/usr/share/keyrings/openhab.gpg] https://openhab.jfrog.io/artifactory/openhab-linuxpkg stable main' | sudo tee /etc/apt/sources.list.d/openhab.list

sudo apt-get update
sudo apt-get install openhab

sudo systemctl enable --now openhab
```

### Key Directories
| Path | Purpose |
|------|---------|
| `/etc/openhab/` or `openhab_conf/` | Items, rules, sitemaps, persistence config |
| `conf/items/` | Thing/item definitions |
| `conf/rules/` | Automation rules (DSL or scripts) |
| `conf/sitemaps/` | UI layout definitions |
| `userdata/` | Runtime data, logs, cached persistence |

### First-Time Setup
1. Browse to `http://localhost:8080`
2. Choose between Standard (recommended bindings pre-selected) or Expert setup
3. Create admin account
4. Go to **Settings → Add-on Store** to install bindings for your devices

### Installing Bindings (Add-ons)
Via the web UI: **Settings → Add-on Store → Bindings**
- Search for your protocol/device (e.g. "Z-Wave", "Philips Hue", "MQTT")
- Click Install

Or via config file (`conf/services/addons.cfg`):
```
binding = zwave,mqtt,hue
```

### Z-Wave / USB Dongle Access (Docker)
```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0
# or
  - /dev/ttyACM0:/dev/ttyACM0
```
Also add the container user to the `dialout` group.

---

## Upgrade Procedure

**Docker:**
```bash
docker compose pull
docker compose down && docker compose up -d
```

**Package:**
```bash
sudo apt-get update && sudo apt-get upgrade openhab
sudo systemctl restart openhab
```

**openHABian:**
- Menu → openHABian Configuration → openHAB related → Upgrade openHAB

---

## Gotchas

- **`network_mode: host` for device discovery**: Without host networking, mDNS/UPnP auto-discovery (for Hue, Sonos, etc.) won't work in Docker.
- **USB dongle passthrough in Docker**: Must explicitly map the device (`/dev/ttyUSB0`) and ensure correct permissions/group (`dialout`).
- **Java memory**: openHAB is Java/OSGi-based and starts slowly on low-RAM devices. Minimum 1 GB RAM; 2 GB+ recommended.
- **openHAB Cloud for remote access**: The official mobile apps and remote access work best with an openHAB Cloud account (free tier available). Alternatively, expose via reverse proxy.
- **Rule languages**: Rules can be written in openHAB DSL (classic), JRuby, JavaScript, or Jython. Choose one and be consistent.
- **Breaking changes between major versions**: Check the migration guide when upgrading across major versions (e.g., 3.x → 4.x).
- **Persistence setup needed**: Historical data (for dashboards/charts) requires a persistence add-on (InfluxDB, RRD4J, MapDB). Configure before collecting data.

---

## Links
- Docs: https://www.openhab.org/docs/
- Getting Started Tutorial: https://www.openhab.org/docs/tutorial/
- openHABian: https://github.com/openhab/openhabian
- Add-on Marketplace: https://www.openhab.org/addons/
- Community Forum: https://community.openhab.org/
- Docker Hub: https://hub.docker.com/r/openhab/openhab
