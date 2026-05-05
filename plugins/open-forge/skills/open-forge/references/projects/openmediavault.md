---
name: openmediavault
description: OpenMediaVault recipe for open-forge. Open-source NAS solution based on Debian Linux. Install on bare metal or VM — NOT inside a container. Covers automated install script on Debian, core services, plugin system. Upstream: https://www.openmediavault.org
---

# OpenMediaVault

Next-generation network attached storage (NAS) solution based on Debian Linux. Provides a web-based admin panel to manage shared storage (SMB/CIFS, NFS, FTP, SFTP), user accounts, Docker containers, and more via a plugin system.

6,683 stars · GPL-3.0 (core)

Upstream: https://github.com/openmediavault/openmediavault
Website: https://www.openmediavault.org/
Docs: https://docs.openmediavault.org/
Forum: https://forum.openmediavault.org/

## Critical constraint

**OpenMediaVault (like other NAS solutions) expects full, exclusive control over the OS configuration. It CANNOT be installed inside a container (Docker, LXC, etc.), and no graphical desktop can be installed alongside it.** Install on bare metal or a dedicated VM only.

## What it is

OpenMediaVault provides a complete NAS management stack:

- **File sharing** — SMB/CIFS (Windows shares), NFS (Linux/Mac), FTP, SFTP/SCP
- **User management** — Local users, groups, and access control lists (ACLs)
- **Storage management** — Disk monitoring (S.M.A.R.T.), RAID, filesystems, quotas
- **Services** — SSH, rsync, BitTorrent client (via plugin), DAAP media server
- **Docker (via omv-extras plugin)** — Full Docker + Portainer management
- **Plugin ecosystem** — `omv-extras` plugin adds third-party functionality including ZFS, Tailscale, WireGuard, etc.
- **Scheduled tasks** — Cron, scheduled S.M.A.R.T. tests, email reports
- **Notifications** — Email alerts for disk failures, temperature, RAID events

Designed for home environments and small home offices; suitable up to small business NAS with modest storage needs.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Automated script on existing Debian | https://docs.openmediavault.org/en/stable/installation/on_debian.html | Primary — install on Debian 12 Bookworm |
| Pre-built ISO (OMV image) | https://www.openmediavault.org/?page_id=77 | Fresh install on bare metal — sets up Debian + OMV in one step |
| Raspberry Pi | https://docs.openmediavault.org/en/stable/installation/raspberry_pi.html | Raspberry Pi 4/5 NAS builds |

## Requirements

- Debian 12 (Bookworm) — latest stable (Debian 11 Bullseye supported for older OMV 6)
- Dedicated system — not a container, not alongside a desktop environment
- Physical or virtual disks for storage (the OS disk should be separate from data disks)
- 1 GB RAM minimum; 2 GB+ recommended
- Wired Ethernet (Wi-Fi is unreliable for a NAS)

## Install on Debian 12 (recommended)

Upstream: https://docs.openmediavault.org/en/stable/installation/on_debian.html

### 1. Start with a minimal Debian 12 install

Install Debian Bookworm with no desktop environment selected. SSH server is recommended. Ensure the system is up to date:

    apt update && apt upgrade -y

### 2. Run the OMV install script (as root)

    wget -O - https://get.openmediavault.io | bash

This script:
- Adds the OMV repository
- Installs `openmediavault` and all dependencies
- Enables all required services
- Configures the web interface

The script takes 10–20 minutes depending on internet speed.

### 3. Access the web UI

After the script completes, navigate to `http://<server-ip>` in a browser.

Default credentials:

| Field | Value |
|---|---|
| Username | admin |
| Password | openmediavault |

**Change the admin password immediately.**

## Post-install setup workflow

1. **Change admin password** — System → Workbench → Change Password
2. **Configure email notifications** — System → Notification → Configure SMTP
3. **Add storage** — Storage → Disks (view detected disks) → File Systems → Create/Mount → Shared Folders → Create
4. **Enable SMB sharing** — Services → SMB/CIFS → Enable, add shares pointing to your shared folders
5. **Create users** — Users → Users → Add (for SMB/NFS access)
6. **Enable S.M.A.R.T. monitoring** — Storage → S.M.A.R.T. → Enable, schedule tests

## Installing omv-extras (Docker and extra plugins)

`omv-extras` is the most important plugin — it adds Docker/Portainer, ZFS, and many third-party plugins.

In the OMV web UI:
1. System → Plugins → Click the Extras icon (if not shown, install `openmediavault-omvextrasorg` manually)

Or via command line:

    wget -O - https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install | bash

Once installed, plugins become available at System → Plugins.

## Useful plugins (via omv-extras)

| Plugin | Purpose |
|---|---|
| `openmediavault-compose` | Docker Compose management |
| `openmediavault-sharerootfs` | Share the root filesystem |
| `openmediavault-zfs` | ZFS pool support |
| `openmediavault-wireguard` | WireGuard VPN |
| `openmediavault-flashmemory` | Optimize for flash/SD storage |

## RAID management

OpenMediaVault uses Linux Software RAID (mdadm):

1. Storage → RAID Management → Create
2. Select disks, RAID level (1, 5, 6, 10)
3. Wait for synchronization to complete before creating file systems

## Upgrade

From within the web UI: System → Update Management → Check for Updates → Apply.

Or via command line:

    apt update && apt upgrade -y

Major version upgrades (e.g. OMV 6 → OMV 7) require following the upgrade guide at https://docs.openmediavault.org/en/stable/various/omvupgrade.html.

## Backup

Back up the OMV configuration database periodically:

    omv-confdbadm export > omv-config-backup-$(date +%F).json

Restore with:

    omv-confdbadm import < omv-config-backup.json
    omv-salt deploy run --no-color

## Gotchas

- **No containers** — Do not try to run OMV inside Docker or LXC. It must own the OS.
- **No desktop GUI** — Installing a desktop environment (GNOME, KDE, etc.) will conflict with OMV. The web UI is the only interface.
- **Separate OS disk** — Keep the OS on a small dedicated disk (SSD, USB, SD). Data disks should be separate. OMV will not use the OS disk for shares by default.
- **Default admin password is public** — Change `openmediavault` → your password immediately after first login.
- **Plugin compatibility** — Not all plugins are compatible with all OMV versions. Check the plugin page on the forum before installing.
- **Raspberry Pi** — Works well on Pi 4/5. Use `openmediavault-flashmemory` plugin to reduce SD card wear. See Pi-specific install guide: https://docs.openmediavault.org/en/stable/installation/raspberry_pi.html
- **OMV 7 uses Debian 12** — OMV 6 uses Debian 11. Ensure you're installing the correct version for your Debian base.

## Links

- GitHub: https://github.com/openmediavault/openmediavault
- Website: https://www.openmediavault.org/
- Docs: https://docs.openmediavault.org/
- Install on Debian: https://docs.openmediavault.org/en/stable/installation/on_debian.html
- Raspberry Pi install: https://docs.openmediavault.org/en/stable/installation/raspberry_pi.html
- Forum: https://forum.openmediavault.org/
- omv-extras: https://github.com/OpenMediaVault-Plugin-Developers/packages
- Upgrade guide: https://docs.openmediavault.org/en/stable/various/omvupgrade.html
