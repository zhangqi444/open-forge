---
name: startos
description: StartOS recipe for open-forge. Covers bare-metal install via ISO. StartOS is an open-source Linux OS designed for running a personal server with a browser-based GUI — handles app discovery, installation, TLS, backups, and dependency management.
---

# StartOS

Open-source Linux distribution purpose-built for running a personal server. Browser-based graphical interface makes running self-hosted services as intuitive as a personal computer. Handles app discovery, one-click installation, TLS certificate management, automated backups, dependency resolution, health monitoring, and network configuration — all without touching a terminal. Services run in isolated LXC containers packaged as signed S9PKs. Built by Start9 Labs. Upstream: <https://github.com/Start9Labs/start-os>. Website: <https://start9.com>. Docs: <https://docs.start9.com>.

**License:** MIT · **Language:** Rust (backend) / Angular (frontend) · **Stars:** ~1,800

> **Installation note:** StartOS is a full Linux operating system installed onto dedicated hardware (or a VM). It is not a Docker app — you flash an ISO to a device and boot from it. Think of it like Umbrel OS or CasaOS, but with deeper integration and stronger cryptographic guarantees.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| ISO install (x86_64) | <https://docs.start9.com/start-os/installing.html> | ✅ | **Standard** — install to any x86_64 PC, server, or mini-PC. |
| ISO install (Raspberry Pi 4/5) | <https://docs.start9.com/start-os/installing.html> | ✅ | Raspberry Pi homelab. |
| Buy a pre-installed server | <https://store.start9.com> | ✅ | Easiest path — plug in and go. |
| VM (VirtualBox/QEMU) | <https://docs.start9.com/start-os/installing.html> | ✅ | Testing/evaluation. |

## Hardware requirements

| Component | Minimum | Recommended |
|---|---|---|
| CPU | x86_64 or ARM64 | x86_64 (mini-PC, NUC, server) |
| RAM | 2 GB | 4–8 GB |
| Storage | 32 GB SSD | 256 GB+ SSD (apps need space) |
| Network | Ethernet | Ethernet (Wi-Fi supported) |
| Dedicated device | Yes | Yes — StartOS takes over the machine |

## Install

### Step 1: Download the ISO

Download the latest StartOS ISO from: <https://github.com/Start9Labs/start-os/releases>

Choose your architecture:
- `startos-<version>-x86_64.iso` — standard x86_64 PCs, mini-PCs, servers
- `startos-<version>-raspberrypi.img` — Raspberry Pi 4/5

### Step 2: Flash to a drive

```bash
# Flash ISO to USB drive (Linux/macOS)
sudo dd if=startos-*.iso of=/dev/sdX bs=4M status=progress
sync

# Or use Balena Etcher (cross-platform GUI):
# https://www.balena.io/etcher/
```

For Raspberry Pi, flash the `.img` file to a microSD card.

### Step 3: Boot and initialize

1. Insert the USB drive into your target machine and boot from it
2. Follow the on-screen installer
3. After installation, StartOS reboots and shows a setup wizard
4. **Connect from any browser** on your network to the displayed URL (or IP address)
5. Complete initialization — StartOS generates cryptographic keys and sets up your device

### Step 4: Install apps

1. Open the Start9 Marketplace from the StartOS dashboard
2. Browse available services (Bitcoin, Lightning, Nextcloud, Matrix, Vaultwarden, etc.)
3. Click **Install** — StartOS handles downloading, configuring, and running the service

## App marketplace

Available services include:

| Category | Examples |
|---|---|
| Bitcoin & Lightning | Bitcoin Core, LND, CLN, BTCPay Server, Ride the Lightning |
| Communication | Matrix (Synapse), SimpleX Chat |
| Cloud & Productivity | Nextcloud, Vaultwarden, Bitwarden |
| Networking | Tor, WireGuard |
| Media | more being added |

Full marketplace: <https://marketplace.start9.com/>

Community-packaged services: anyone can package apps as S9PKs. <https://github.com/Start9Labs/ai-service-packaging/>

## Networking and TLS

StartOS automatically:
- Assigns your server a `.local` mDNS address for LAN access
- Generates a self-signed root CA and installs it for HTTPS on LAN
- Optionally sets up a Tor hidden service for remote access without port forwarding
- Optionally configures Clearnet (public internet) access with Let's Encrypt TLS

No manual certificate management required.

## Backups

StartOS has built-in backup to:
- External USB drive
- Network attached storage (NFS/SMB)
- S3-compatible storage

Backups are encrypted and include all app data.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Dedicated device required | StartOS takes over the entire machine. Do not install on a PC you also use for other purposes. |
| S9PK app format | Apps are packaged as signed S9PKs. You can only install apps from the official marketplace or verified community sources — not arbitrary Docker containers directly. |
| App catalog scope | Current focus is Bitcoin/Lightning infrastructure, privacy tools, and productivity apps. The catalog is smaller than Umbrel's or Websoft9's. |
| LXC containers | Each app runs in an isolated LXC container. Apps cannot see each other's data. Dependencies are managed explicitly (e.g., BTCPay Server depends on Bitcoin Core). |
| Beta software | As of v0.4.0-beta.7, StartOS is still in beta. Expect occasional breaking changes between major versions. |
| Remote access | Default remote access is via Tor hidden service (no port forwarding needed). Clearnet + Let's Encrypt available but requires port forwarding on your router. |

## Upgrade procedure

StartOS updates itself. From the dashboard:

1. Navigate to **System → Software Update**
2. Click **Update** when an update is available
3. StartOS downloads and applies the update, then restarts

Individual app updates are also managed from the dashboard per-app.

## Gotchas

- **Takes over the entire machine:** StartOS is a full OS installation. Everything on the target disk is erased. Use dedicated hardware.
- **Not traditional Docker:** You can't just `docker run` arbitrary images on StartOS. Apps must be packaged as S9PKs and installed through the marketplace.
- **Bitcoin-centric origins:** StartOS has strong Bitcoin/Lightning support — it was originally built for sovereign Bitcoin node operators. General self-hosting features are improving but the catalog is smaller than alternatives.
- **Self-signed CA:** For LAN HTTPS, StartOS installs a self-signed root CA on your devices. You'll need to trust this CA on each device you use to access StartOS services.
- **Beta caveats:** The current v0.4.x beta may have rough edges. Breaking changes between beta versions have occurred. Check the release notes before upgrading.
- **Tor for remote access:** The default remote access path is through Tor, which adds latency. Clearnet access requires additional network configuration (port forwarding).

## Upstream links

- GitHub: <https://github.com/Start9Labs/start-os>
- Website: <https://start9.com>
- Docs: <https://docs.start9.com>
- Install guide: <https://docs.start9.com/start-os/installing.html>
- App marketplace: <https://marketplace.start9.com/>
- App packaging guide: <https://github.com/Start9Labs/ai-service-packaging/>
- Releases: <https://github.com/Start9Labs/start-os/releases>
- Store (pre-built hardware): <https://store.start9.com>
