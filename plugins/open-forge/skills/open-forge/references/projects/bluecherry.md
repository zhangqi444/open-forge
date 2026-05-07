---
name: Bluecherry
description: Self-hosted network video recorder (NVR) and video surveillance software. Supports IP cameras and analog capture cards, RTSP streams, motion detection, and web UI. GPL-2.0 licensed.
website: https://www.bluecherrydvr.com/
source: https://github.com/bluecherrydvr/bluecherry-apps
license: GPL-2.0
stars: 269
tags:
  - nvr
  - surveillance
  - cameras
  - cctv
  - video-recording
platforms:
  - C++
  - Linux
---

# Bluecherry

Bluecherry is a self-hosted network video recorder (NVR) and video surveillance system. It supports IP cameras via RTSP streams, analog capture cards, motion detection, and live viewing through a web interface. Available as a Debian/Ubuntu package. Suitable for small businesses and home installations.

Official site: https://www.bluecherrydvr.com/
Source: https://github.com/bluecherrydvr/bluecherry-apps
Docs: https://www.bluecherrydvr.com/documentation/
Discord: https://discord.gg/64xADw6vuC

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 20.04 / 22.04 LTS | Debian package (apt) | Recommended; official packages available |
| Debian 11 / 12 | Debian package (apt) | Supported |

## Inputs to Collect

**Phase: Planning**
- Number and type of cameras (IP/RTSP vs analog capture cards)
- RTSP stream URLs for IP cameras
- Storage path for recordings (plan for significant disk space)
- Admin username and password
- Port for web UI (default: 7001 HTTPS)

## Software-Layer Concerns

**Install (Ubuntu/Debian):**

```bash
# Add Bluecherry repository
wget -q -O - https://apt.bluecherrydvr.com/bluecherry.gpg.key | sudo apt-key add -
echo "deb https://apt.bluecherrydvr.com/ $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/bluecherry.list

sudo apt update
sudo apt install bluecherry

# Installer prompts for MySQL root password and Bluecherry admin credentials
```

**Web UI access:** `https://your-server:7001/`

**Add an IP camera (RTSP):**

1. Log into web UI at `https://your-server:7001/`
2. Navigate to Admin → Devices → Add Device
3. Enter RTSP URL: `rtsp://camera-ip:554/stream`
4. Set camera name and recording schedule
5. Save — live preview appears in the web UI

**Storage configuration:**

Recordings default to `/var/lib/bluecherry/recordings/` — ensure sufficient disk space. Configure retention policies in Admin → Storage to auto-delete old recordings.

**Firewall ports:**

- 7001/tcp — HTTPS web UI
- 7002/tcp — Live streaming (optional)
- 554/tcp — RTSP (if proxying external cameras)

**Services:**

```bash
sudo systemctl status bluecherry
sudo systemctl restart bluecherry
```

**Analog capture cards:**

Bluecherry supports its own PCI/PCIe capture cards (BC-4H, BC-16H). Plug-in support requires the corresponding kernel driver; see hardware compatibility list at https://www.bluecherrydvr.com/products/.

## Upgrade Procedure

```bash
sudo apt update && sudo apt upgrade bluecherry
sudo systemctl restart bluecherry
```

## Gotchas

- **Disk space**: Video surveillance generates enormous amounts of data — plan for TB-scale storage and configure retention/overwrite policies
- **RTSP compatibility**: Not all cameras expose clean RTSP streams; some require specific URL formats or authentication — check your camera's manual
- **Analog cards**: Bluecherry hardware capture cards require Bluecherry's proprietary kernel module — generic V4L2 cards are not supported
- **HTTPS self-signed cert**: Default install uses a self-signed certificate — browser will warn; replace with a proper cert or add an exception
- **MySQL dependency**: Bluecherry uses MySQL/MariaDB for its database — installed automatically with the package
- **Build from source**: Building from source is complex (uses custom scripts to generate version.h and Debian control files) — use the apt package unless you need to modify the code

## Links

- Official site: https://www.bluecherrydvr.com/
- Documentation: https://www.bluecherrydvr.com/documentation/
- Source: https://github.com/bluecherrydvr/bluecherry-apps
- Discord support: https://discord.gg/64xADw6vuC
