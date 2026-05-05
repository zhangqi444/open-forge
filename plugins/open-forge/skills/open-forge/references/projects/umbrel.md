---
name: umbrelOS
description: "Home server operating system with a beautiful web UI and one-click app store — install on a Raspberry Pi 5, any x86 system, or VM to self-host apps like Nextcloud, Jellyfin, Bitcoin node, and 200+ others without touching the command line. JavaScript/TypeScript. PolyForm Noncommercial 1.0."
---

# umbrelOS

**What it is:** A full home server OS (not just a Docker manager) that boots to a polished desktop-in-browser experience. Includes a built-in app store with 200+ curated apps, automatic updates, backup/restore, and a Bitcoin/Lightning node stack. Designed for Raspberry Pi and x86 hardware; also runs in a VM.

**Official site:** https://umbrel.com
**Docs/wiki:** https://github.com/getumbrel/umbrel/wiki
**License:** PolyForm Noncommercial 1.0 (free for personal use; commercial use requires a license)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi 5 | umbrelOS image (64-bit) | Best-supported hardware |
| x86 / amd64 bare metal | umbrelOS image | Full feature support |
| Linux VM (VirtualBox, Proxmox, etc.) | umbrelOS ISO | Experimental; some features limited |
| Umbrel Home / Umbrel Pro | umbrelOS (pre-installed) | Commercial hardware; full support + warranty |

> Note: umbrelOS is **not** a standard Docker Compose deployment — it is a full OS image you flash to a drive. There is no "install on existing OS" method for the full OS. For a Docker-only app manager, see alternatives like Runtipi or Cosmos.

---

## Inputs to Collect

### Pre-install
- Target hardware: Raspberry Pi 5, x86 machine, or VM
- Storage: microSD (Pi) or USB/SSD/NVMe (x86) — 16 GB minimum, 64 GB+ recommended
- Static IP or hostname reservation on your router (optional but helpful)

### During first boot
- Username and password (set via browser on first access)
- No `docker-compose.yml` or `.env` — configuration is done entirely through the web UI

---

## Software-Layer Concerns

### Architecture
umbrelOS is a Debian-based OS that runs an `umbreld` daemon (Node.js) which manages app lifecycle via Docker Compose under the hood. Each app in the store is defined by a standard `umbrel-app.yml` manifest.

### App data location (inside umbrelOS)
```
~/umbrel/app-data/<app-id>/    # per-app data and config
~/umbrel/data/                  # shared user data (Files app)
```

### Port convention
- Web UI: port `80` (redirects to HTTPS if configured)
- Each installed app gets its own port; accessible via `http://<umbrel-ip>/<app-name>` or directly on its port

### Updates
- OS and app updates are delivered over-the-air through the umbrelOS update system
- No manual `docker pull` needed

---

## Deployment Steps

### Raspberry Pi 5
```
1. Download umbrelOS image from https://umbrel.com/umbrelos
2. Flash to microSD with Raspberry Pi Imager or Balena Etcher
3. Insert microSD, power on Pi
4. From any browser on the same network: http://umbrel.local
5. Complete setup wizard (set username + password)
6. Install apps from the built-in app store
```

### x86 (bare metal or VM)
```
1. Download umbrelOS x86 ISO from https://umbrel.com/umbrelos
2. Boot from USB or mount ISO in VM
3. Follow installer wizard — installs to local disk
4. Access at http://<assigned-ip> after reboot
```

---

## Upgrade Procedure

umbrelOS updates itself via the web UI:
1. Open umbrelOS → Settings → Updates
2. Click "Update" when a new version is available
3. OS and all installed apps update in sequence

There is no manual upgrade path for a typical user — updates are fully managed.

---

## Gotchas

- **Not a Docker manager for your existing server** — umbrelOS replaces your OS. If you want app management on top of an existing Linux install, use Runtipi, Dockge, or Portainer instead.
- **License is non-commercial** — PolyForm Noncommercial 1.0 means you cannot run umbrelOS commercially (as a hosted service, in a business, etc.) without a license from Umbrel.
- **Raspberry Pi support** — Pi 5 is the supported model; Pi 4 support is best-effort. Earlier models are not supported.
- **VM limitations** — Some hardware-dependent features (USB device passthrough, hardware wallets, etc.) may not work in VMs.
- **Bitcoin node storage** — Running a full Bitcoin node requires 600+ GB of free disk space for the blockchain. Plan storage accordingly.
- **Remote access** — Out of the box, umbrelOS is LAN-only. Remote access requires Tailscale (available as an app in the store) or manual port forwarding.
- **App store apps are curated** — Not all self-hosted software is in the store. Custom apps can be sideloaded but require writing an `umbrel-app.yml` manifest.
- **Data backup** — Use the built-in backup feature (exports encrypted backup to external drive) before any major upgrade.

---

## Links
- Homepage: https://umbrel.com
- GitHub repo: https://github.com/getumbrel/umbrel
- Install on Pi 5: https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-a-Raspberry-Pi-5
- Install on x86: https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-x86-Systems
- Install in VM: https://github.com/getumbrel/umbrel/wiki/Install-umbrelOS-on-a-Linux-VM
- App store: https://apps.umbrel.com
- Community forum: https://community.umbrel.com
