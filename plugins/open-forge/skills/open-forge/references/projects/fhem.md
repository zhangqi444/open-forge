---
name: fhem
description: FHEM recipe for open-forge. Home automation server for controlling smart devices, logging sensor data, and automation rules. Runs on Raspberry Pi and Linux. GPL-3.0, Perl. Source: https://svn.fhem.de/trac
---

# FHEM

A mature Perl-based home automation server for controlling smart home devices, logging sensor data (temperature, power, humidity), and running automation rules. Supports a huge range of protocols and device types: Z-Wave, ZigBee, KNX, HomeMatic, 433 MHz RF, MQTT, Modbus, LAN, and more. Browser and smartphone frontends included. Runs well on Raspberry Pi. GPL-3.0, written in Perl. Website: <https://fhem.de/>. Forum: <https://forum.fhem.de/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi | Debian package | Ideal platform — GPIO and USB device access |
| Debian / Ubuntu | Debian package | Official fhem.de APT repository |
| Any Linux | Tarball install | Manual Perl dependency management |
| Docker | Docker image | Community image available; USB pass-through required for hardware devices |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Smart home protocols to use?" | Z-Wave / ZigBee / HomeMatic / 433MHz / MQTT / etc. | Drives hardware USB dongle requirements |
| "Host machine?" | Raspberry Pi / Linux server | Affects USB device access and GPIO availability |
| "Reverse proxy for remote access?" | Yes / No | FHEM runs on port 8083 by default |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "USB devices?" | Device paths e.g. /dev/ttyUSB0 | RF stick, Z-Wave controller, etc. |
| "MQTT broker?" | host:port | If using MQTT for device communication |
| "Log storage location?" | Path | Sensor data logs stored as text files |

## Software-Layer Concerns

- **Perl runtime**: FHEM is a Perl application — requires Perl and various CPAN modules (installed automatically via the Debian package).
- **Single config file**: `fhem.cfg` defines all devices, rooms, groups, and automation rules as a flat text file. Edit via the web interface or directly.
- **USB hardware access**: Most real devices require a USB dongle (CUL stick for 433MHz/868MHz, CC2531 for ZigBee, Aeotec for Z-Wave) — FHEM must have access to `/dev/ttyUSBx`.
- **Modules**: FHEM functionality is modular — hundreds of community-written Perl modules for different devices. Installable via `update` command in FHEM.
- **Log format**: Sensor readings logged as time-stamped text files — easily graphed with FHEM's built-in SVG plotter.
- **Web frontends**: Built-in "FLOORPLAN" and "FHEMweb" interfaces; also compatible with myFHEM and other community UIs.
- **Automation**: `at` (time-based) and `notify` (event-based) built-in commands for automation rules.

## Deployment

### Raspberry Pi / Debian (recommended)

```bash
# Add FHEM repository
wget -q -O - https://debian.fhem.de/repo.key | sudo apt-key add -
echo "deb https://debian.fhem.de/nightly/ /" | sudo tee /etc/apt/sources.list.d/fhem.list

# Install
sudo apt update && sudo apt install fhem

# FHEM starts automatically; web interface at:
# http://<your-ip>:8083/fhem
```

### Add USB device access

```bash
# Add fhem user to dialout group for USB serial access
sudo usermod -a -G dialout fhem
sudo systemctl restart fhem

# Define device in FHEM web console:
define myCUL CUL /dev/ttyUSB0@9600 0000
```

### Docker (with USB)

```yaml
services:
  fhem:
    image: fhem/fhem:latest
    ports:
      - "8083:8083"
    volumes:
      - ./fhem-data:/opt/fhem
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
    restart: unless-stopped
```

### Basic fhem.cfg example

```
attr global logfile /opt/fhem/log/fhem-%Y-%m.log
attr global statefile /opt/fhem/fhem.save
define WEB FHEMWEB 8083 global
define myMQTT MQTT2_SERVER 1883 global
```

## Upgrade Procedure

1. In FHEM web interface: `update` → review changes → `update all`.
2. APT: `sudo apt update && sudo apt upgrade fhem`.
3. Back up `fhem.cfg` and `log/` before major version upgrades.
4. Check the FHEM forum (forum.fhem.de) for release-specific migration notes.

## Gotchas

- **USB dongles are essential**: Without hardware, FHEM can only use LAN/IP devices and MQTT. Protocol support requires corresponding USB sticks.
- **`fhem.cfg` is the source of truth**: All devices and rules are in this file. Direct file edits take effect after `reload` in FHEM; web edits auto-save.
- **Perl module dependencies**: Complex setups may need `cpanm` to install missing Perl modules not covered by the Debian package.
- **Learning curve**: FHEM's flexibility comes with a steep learning curve — the forum and wiki are essential resources.
- **Docker + USB**: USB serial devices must be explicitly passed through with `devices:` — container won't auto-detect hardware.
- **Port 8083 not protected by default**: FHEM's built-in web server has no auth by default — add `basicAuth` or restrict to LAN/VPN only.

## Links

- Website: https://fhem.de/
- Documentation (HOWTO): https://fhem.de/HOWTO_EN.html
- Wiki: https://wiki.fhem.de/wiki/Hauptseite
- Forum: https://forum.fhem.de/
- Source (SVN/Trac): https://svn.fhem.de/trac
- Docker image: https://hub.docker.com/r/fhem/fhem
