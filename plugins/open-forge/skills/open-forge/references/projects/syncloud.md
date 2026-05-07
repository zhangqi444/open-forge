---
name: syncloud
description: Syncloud recipe for open-forge. Simple self-hosting platform for ARM/x86 devices. Installs and manages popular self-hosted apps (Nextcloud, Syncthing, email, etc.) via a web dashboard using snap packages. Source: https://github.com/syncloud/platform
---

# Syncloud

Simple self-hosting platform that turns a Raspberry Pi, Odroid, or x86/ARM device into a personal cloud server. Installs and manages popular self-hosted applications (Nextcloud, Syncthing, Diaspora, mail server, XMPP, etc.) via a point-and-click web dashboard. Apps are distributed as snap packages. Provides a shared nginx proxy, TLS via Let's Encrypt, and optional dynamic DNS through a free syncloud.it subdomain.

Upstream: <https://github.com/syncloud/platform> | Apps: <https://syncloud.org/apps.html> | Download: <https://github.com/syncloud/platform/wiki>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi 2/3/4/5 (ARM) | Syncloud image (Debian-based) | Flash to SD card |
| Odroid, Pine, Rock Pi (ARM) | Syncloud image | Various board images available |
| amd64 PC/VPS | Syncloud image | x86_64 image available |
| arm64 | Syncloud image | Separate arm64 image |
| Existing Debian/Ubuntu | Snap-based install | Can install platform snap on existing system |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | Target device/architecture | Determines which image to download |
| first-boot | Network setup (DHCP or static IP) | Syncloud configures via web UI on first boot |
| first-boot | Admin username and password | Set on activation wizard |
| config | Domain name | Use free syncloud.it subdomain or custom domain |
| config | TLS/Let's Encrypt | Configured after activation; requires port 80/443 open |
| optional | External storage | USB drive can be added for app data |

## Software-layer concerns

### Architecture

Syncloud is an OS image (Debian-based) that includes:
1. A Debian-based Linux OS (`syncloud/image`)
2. A snap-based app installer (`syncloud/snapd` — modified snapd)
3. Platform snap — shared services: nginx reverse proxy, Let's Encrypt, web dashboard, device settings

Each app (Nextcloud, Syncthing, etc.) is an independent snap package pulled from the Syncloud store.

### Web dashboard

After activation, the web dashboard is available at `http://syncloud.it` (if using syncloud.it DNS) or the device IP. All app installs, updates, storage, and settings are managed from this UI.

### Port requirements

For external access and Let's Encrypt TLS:
- TCP 80 — Let's Encrypt HTTP-01 challenge
- TCP 443 — HTTPS access to your apps

### Data storage

By default, app data is stored on the SD card/internal disk. An external USB drive can be configured as the storage location via the web dashboard (recommended for longevity — SD cards wear out).

## Install — SD card / device image

```bash
# 1. Download the Syncloud image for your device from:
#    https://github.com/syncloud/platform/wiki

# 2. Flash to SD card (or USB drive for x86)
sudo dd if=syncloud-image.img of=/dev/sdX bs=4M status=progress
sync

# 3. Boot device, wait ~2 minutes for first-boot setup

# 4. Open http://<device-ip>:81/ in your browser to access the activation wizard
#    (port 81 is the initial setup wizard port)

# 5. Complete activation: set admin credentials, domain, and optionally link
#    to a free syncloud.it subdomain for external access + TLS
```

## Install — Snap on existing Debian/Ubuntu

Syncloud can run on an existing system via the platform snap. See the wiki for current instructions:
<https://github.com/syncloud/platform/wiki>

```bash
# Install snapd if not present
sudo apt install snapd

# Install Syncloud platform snap (get current URL from the wiki)
sudo snap install syncloud-platform.snap --devmode
```

## Adding apps

From the web dashboard:
1. Navigate to **Store**
2. Browse available apps (Nextcloud, Syncthing, mail, XMPP, etc.)
3. Click **Install** — Syncloud handles dependencies and reverse proxy setup automatically

## Upgrade procedure

All upgrades are managed through the web dashboard:
- **Platform updates**: Dashboard → Settings → Check for Updates
- **App updates**: Dashboard → App → Update

Or via SSH:
```bash
sudo snap refresh
```

## Gotchas

- Syncloud uses its own modified snapd — do not mix with the standard Ubuntu snapd. Install Syncloud from the OS image, not on top of an existing snap-heavy system.
- SD card longevity — store app data on an external USB drive (configurable in dashboard Settings → Storage). SD cards fail faster when used as primary write storage.
- Port 81 for initial setup — the activation wizard listens on port 81, not 80 or 443. Make sure port 81 is reachable from your browser during setup.
- syncloud.it subdomain is optional — you can use any custom domain by setting an A/CNAME record to your device IP. syncloud.it provides free dynamic DNS for devices behind NAT.
- Let's Encrypt requires ports 80 and 443 to be open to the internet — if your ISP blocks these ports, TLS provisioning will fail. Use a VPN tunnel or alternative challenge method.
- Each app runs in its own snap sandbox — apps are isolated from each other and from the host OS.

## Links

- Platform source: https://github.com/syncloud/platform
- Available apps: https://syncloud.org/apps.html
- Device images wiki: https://github.com/syncloud/platform/wiki
- Hardware shop: https://shop.syncloud.org
