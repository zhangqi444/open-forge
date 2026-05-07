---
name: WeeWX
description: Open-source weather station software written in Python. Collects data from weather stations and sensors, generates HTML pages/plots, and uploads to online weather services. GPL-3.0.
website: https://weewx.com/
source: https://github.com/weewx/weewx
license: GPL-3.0
stars: 1157
tags:
  - weather
  - iot
  - sensors
  - raspberry-pi
platforms:
  - Python
  - deb
---

# WeeWX

WeeWX is open-source weather station software that reads data from hardware weather stations and sensors, stores it in a database (SQLite or MySQL), generates HTML pages and plots, and can upload to dozens of online weather services (Weather Underground, CWOP, Windy, InfluxDB, MQTT, etc.). Runs well on Raspberry Pi.

Official site: https://weewx.com/  
Source: https://github.com/weewx/weewx  
Docs: https://weewx.com/docs/  
Latest release: v5.3.1 (March 2026)  
Hardware list: https://www.weewx.com/hardware.html

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi / Linux ARM | Python 3.7+ + pip | Primary use case; runs as a daemon |
| Any Linux VM / VPS | Python 3.7+ + pip | Works without attached hardware (simulator driver) |
| Debian/Ubuntu | apt (deb package) | Official .deb packages available |
| Docker | Community Docker images | No official image; community-maintained |

## Inputs to Collect

**Phase: Planning**
- Weather station hardware model (see https://www.weewx.com/hardware.html)
- USB/serial port or IP address of station (hardware-dependent)
- Database type: SQLite (default) or MySQL
- MySQL credentials if using MySQL
- Target website/upload destinations (Weather Underground API key, etc.)
- Station latitude, longitude, altitude
- Unit system: US (imperial) or Metric

**Phase: Installation**
- Station location name
- Altitude units (feet or meters)
- Skin/theme preference (default: Seasons)

## Software-Layer Concerns

**Install via pip (recommended for WeeWX v5):**
```bash
pip install weewx
weewxd --gen-config /etc/weewx/weewx.conf
# Edit /etc/weewx/weewx.conf with your station details
weewxd /etc/weewx/weewx.conf
```

**Install via apt (Debian/Ubuntu):**
```bash
# Add WeeWX repository
wget -qO - https://weewx.com/keys.html | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/weewx.gpg
echo "deb [arch=all] https://weewx.com/apt/python3 buster main" | sudo tee /etc/apt/sources.list.d/weewx.list
sudo apt update && sudo apt install weewx
```

**Systemd service:**
```bash
sudo systemctl enable weewx
sudo systemctl start weewx
```

**Key config file:** `/etc/weewx/weewx.conf`

**Important config sections:**
```ini
[Station]
    station_type = Simulator    # or FineOffsetUSB, Vantage, etc.
    latitude = 37.55
    longitude = -122.34
    altitude = 50, foot

[DatabaseTypes]
    [[SQLite]]
        database_name = weewx.sdb
        SQLITE_ROOT = /var/lib/weewx

[StdReport]
    [[SeasonsReport]]
        skin = Seasons
        HTML_ROOT = /var/www/html/weewx
```

**Web output:** Generated HTML pages saved to `HTML_ROOT` — serve with any web server (Nginx, Apache, or serve statically via S3/rsync)

**Data paths:**
- Database: `/var/lib/weewx/weewx.sdb` (SQLite default)
- Config: `/etc/weewx/weewx.conf`
- HTML output: `/var/www/html/weewx/`
- Logs: syslog / `journalctl -u weewx`

## Upgrade Procedure

1. `pip install --upgrade weewx` (or `apt upgrade weewx`)
2. WeeWX applies database schema upgrades automatically on next start
3. Check upgrade notes: https://weewx.com/docs/5.0/upgrading/
4. Back up `weewx.conf` and database before major version upgrades

## Gotchas

- **Hardware required**: WeeWX is designed to work with physical weather station hardware; without it, use the built-in `Simulator` driver for testing
- **v4 → v5 migration**: WeeWX v5 changed the install method significantly (from setup.py to pip/packages); review migration guide carefully
- **USB permissions**: USB-connected stations may require adding the `weewx` user to the `dialout` group: `usermod -a -G dialout weewx`
- **Driver ecosystem**: Many hardware drivers are community-maintained and installed separately; check https://weewx.com/extensions.html
- **Extension system**: Large ecosystem of extensions for additional services, skins, and hardware — install via `wee_extension`
- **Raspberry Pi GPIO**: Some sensors connect via GPIO rather than USB; check driver-specific instructions

## Links

- Upstream README: https://github.com/weewx/weewx/blob/master/README.md
- Documentation: https://weewx.com/docs/
- Quick start: https://weewx.com/docs/5.0/quickstart/
- Hardware list: https://www.weewx.com/hardware.html
- Extensions: https://weewx.com/extensions.html
- Station showcase: https://weewx.com/showcase.html
