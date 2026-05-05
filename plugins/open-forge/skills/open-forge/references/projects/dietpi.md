---
name: dietpi-project
description: DietPi recipe for open-forge. Covers installation as an OS image on bare metal, SBCs (Raspberry Pi, Odroid, NanoPi, Rock Pi, Orange Pi), x86/x64 VMs, and WSL. Not a Docker app — DietPi is the operating system itself. Covers image flashing, first-boot automation via dietpi.txt, the dietpi-software app installer, and post-boot configuration tools.
---

# DietPi

Extremely lightweight Debian-based OS optimised for single-board computers (Raspberry Pi, Odroid, NanoPi, Rock Pi, Orange Pi) and x86/x64. Ships a curated `dietpi-software` installer tool covering 200+ self-hostable apps. ~100 MB RAM at idle. Designed for headless servers. GPL-2.0. Upstream: <https://github.com/MichaIng/DietPi>. Downloads and docs: <https://dietpi.com/>.

DietPi is the OS itself — there is no Docker image of DietPi and no `docker run dietpi/...` command. It is flashed onto storage media (SD card, USB, eMMC) and boots on target hardware. The `dietpi-software` tool then installs any self-hosted apps on top of DietPi.

## Supported platforms

| Platform | Notes |
|---|---|
| Raspberry Pi (all models, Zero–5) | Best-supported SBC |
| Odroid (C4, N2, XU4, …) | Multiple images |
| NanoPi (R5S, NEO3, M4V2, …) | Multiple images |
| Rock Pi / Radxa (4, 5B, …) | Multiple images |
| Orange Pi (5, 3B, …) | Multiple images |
| x86/x64 PC, VM (VirtualBox, VMware, Proxmox, QEMU) | Native ISO / VMDK / OVA |
| WSL 2 | Separate WSL image |

## Install methods

| Method | When to use |
|---|---|
| Flash SD/USB then boot | SBCs and bare-metal x86 |
| Import OVA/VMDK | VirtualBox / VMware / Proxmox |
| WSL image | Windows Subsystem for Linux |

All methods result in the same DietPi environment once booted.

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which hardware platform are you installing DietPi on?" | Drives which image to download |
| preflight | "What is the storage medium?" (SD card / USB / eMMC / VM disk) | All physical installs |
| automation | "Do you want to automate the first boot? (hostname, WiFi, locale, initial software)" | Drives whether to edit `dietpi.txt` before flashing |
| automation | "Desired hostname?" | Used in `dietpi.txt` |
| automation | "WiFi SSID + password?" (leave blank for wired) | Used in `dietpi.txt` → `dietpi-wifi.txt` |
| automation | "Timezone?" (e.g. `Europe/London`, `America/New_York`) | Used in `dietpi.txt` |
| automation | "Which software IDs to pre-install on first boot?" (e.g. `17` = Pi-hole, `185` = Home Assistant) | `AUTO_SETUP_INSTALL_SOFTWARE_ID` in `dietpi.txt` |
| software | "Which apps to install via dietpi-software after boot?" | Interactive menu or `dietpi-software install <ID>` |

After each prompt, record the value in the state file under `inputs.*`.

---

## Phase 1 — Download the image

Browse <https://dietpi.com/#download> and select the image matching the target platform. Direct links follow the pattern:

```
https://dietpi.com/downloads/images/DietPi_<Platform>-ARMv8-<DebianCodename>.img.xz
```

Example (Raspberry Pi 5):

```bash
wget -O dietpi.img.xz \
  "https://dietpi.com/downloads/images/DietPi_RPi-ARMv8-Bookworm.img.xz"
xz -d dietpi.img.xz
# → dietpi.img
```

For x86/x64 VMs, download the OVA or ISO — no flashing step needed; import directly into the hypervisor.

---

## Phase 2 — Flash the image

### Option A — Raspberry Pi Imager (GUI, easiest)

1. Install Raspberry Pi Imager (<https://www.raspberrypi.com/software/>).
2. Click **Use custom** → select `dietpi.img`.
3. Target: the SD card / USB drive.
4. **Do not** enable the Imager's built-in customisation popup — DietPi's own `dietpi.txt` handles this. Click **No** when prompted.
5. Write.

### Option B — `dd` (Linux / macOS)

```bash
# Find the device (e.g. /dev/sdb or /dev/rdisk2)
lsblk          # Linux
diskutil list  # macOS

# Unmount (macOS only)
diskutil unmountDisk /dev/disk2

# Write
sudo dd if=dietpi.img of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Replace `/dev/sdX` with the actual device. **Do not** use a partition number (e.g. `/dev/sdb1`) — write to the whole device.

### Option C — balenaEtcher (cross-platform GUI)

1. Install balenaEtcher (<https://www.balena.io/etcher/>).
2. Flash from file → select `dietpi.img` → select target → Flash.

---

## Phase 3 — Pre-boot automation via `dietpi.txt` (optional but recommended)

After flashing, a small FAT partition named `DietPi` (or `boot`) is readable on any OS. It contains two key files:

| File | Purpose |
|---|---|
| `dietpi.txt` | Main automation config — hardware settings, locale, first-boot software install |
| `dietpi-wifi.txt` | WiFi credentials |

Edit them **before the first boot** to fully automate setup.

### `dietpi.txt` — critical options

```ini
# Hostname
AUTO_SETUP_NET_HOSTNAME=my-dietpi-server

# Locale and timezone
AUTO_SETUP_LOCALE=en_GB.UTF-8
AUTO_SETUP_KEYBOARD_LAYOUT=gb
AUTO_SETUP_TIMEZONE=Europe/London

# Skip interactive prompts on first boot (1 = fully automated)
AUTO_SETUP_AUTOMATED=1

# Root password (change this!)
AUTO_SETUP_GLOBAL_PASSWORD=supersecret

# Network — 0 = Ethernet, 1 = WiFi, 2 = USB OTG
AUTO_SETUP_NET_ETHERNET_ENABLED=1
AUTO_SETUP_NET_WIFI_ENABLED=0

# Software IDs to install automatically on first boot
# Find IDs at: https://dietpi.com/docs/software/
# Multiple: one per line
AUTO_SETUP_INSTALL_SOFTWARE_ID=17
# AUTO_SETUP_INSTALL_SOFTWARE_ID=185

# Reboot when first-boot setup is complete
AUTO_SETUP_REBOOT_GLOBAL_TARGET=1
```

### `dietpi-wifi.txt` — WiFi credentials (if using WiFi)

```ini
aWIFI_SSID[0]='MyNetwork'
aWIFI_KEY[0]='MyPassword'
aWIFI_KEYMGR[0]='WPA-PSK'
```

Enable WiFi in `dietpi.txt`:

```ini
AUTO_SETUP_NET_WIFI_ENABLED=1
AUTO_SETUP_NET_ETHERNET_ENABLED=0
```

---

## Phase 4 — First boot

Insert the SD/USB into the target device and power on. DietPi:

1. Expands the root partition to fill the storage.
2. Applies all `dietpi.txt` settings.
3. Installs any `AUTO_SETUP_INSTALL_SOFTWARE_ID` packages.
4. Reboots (if `AUTO_SETUP_REBOOT_GLOBAL_TARGET=1`).

First boot can take several minutes. Connect a monitor or wait for the device to appear on the network (`arp-scan`, `nmap -sn`, or the router's DHCP table) then SSH in:

```bash
ssh root@<DIETPI_IP>
# Default credentials if NOT using dietpi.txt automation:
# user: root  password: dietpi
```

---

## Phase 5 — Post-boot configuration

### `dietpi-config` — hardware, network, locale, audio

```bash
dietpi-config
```

Interactive menu. Key sections:

| Section | Use for |
|---|---|
| Display Options | Resolution, GPU memory |
| Network Options | Static IP, hostname, WiFi |
| Audio Options | Sound card, volume |
| Performance Options | CPU governor, overclocking (Pi) |
| Security Options | Change root password, SSH |
| Advanced Options | Swap, logs to RAM, filesystem tuning |

### `dietpi-software` — install self-hosted apps

```bash
# Interactive menu (browse by category)
dietpi-software

# Install by ID (non-interactive)
dietpi-software install 17     # Pi-hole
dietpi-software install 185    # Home Assistant
dietpi-software install 42     # Nextcloud
dietpi-software install 33     # Plex Media Server
```

Full software catalogue: <https://dietpi.com/docs/software/>. Common popular IDs:

| ID | App |
|---|---|
| 17 | Pi-hole (DNS ad blocker) |
| 42 | Nextcloud |
| 33 | Plex Media Server |
| 181 | Home Assistant |
| 185 | Home Assistant (supervised) |
| 121 | OpenVPN |
| 200 | WireGuard |
| 158 | Portainer (Docker UI) |
| 162 | Docker + Docker Compose |
| 111 | Gitea |

### `dietpi-update` — update DietPi and installed software

```bash
dietpi-update
```

Checks for DietPi system updates and updates installed `dietpi-software` packages. Equivalent to `apt upgrade` for the base OS plus DietPi-managed app updates.

---

## Common workflows

### Install Docker + Portainer

```bash
dietpi-software install 162    # Docker + Docker Compose
dietpi-software install 158    # Portainer
```

Portainer UI is then available at `http://<DIETPI_IP>:9000`.

### Install Pi-hole (DNS ad blocker)

```bash
dietpi-software install 17
# Web UI: http://<DIETPI_IP>/admin
```

### Install Nextcloud

```bash
dietpi-software install 42
# Web UI: http://<DIETPI_IP>/nextcloud
```

Credentials are printed at the end of the install. Note them.

### Static IP (post-boot)

```bash
dietpi-config
# → Network Options: Adapters → eth0 → Static
```

Or edit `/etc/network/interfaces` / `/etc/dhcpcd.conf` directly.

---

## Verify

```bash
# Check DietPi version
cat /boot/dietpi/.version

# Check installed software
dietpi-software list | grep -i installed

# System info
htop

# Network
ip addr show
ping -c 3 google.com
```

---

## Lifecycle

```bash
# Update DietPi and all managed software
dietpi-update

# Install additional apps
dietpi-software install <ID>

# Uninstall an app
dietpi-software uninstall <ID>

# Reinstall an app (reset to clean state)
dietpi-software reinstall <ID>

# Reconfigure hardware/network/locale
dietpi-config

# Reboot
reboot

# Power off
poweroff
```

---

## Gotchas

- **Not a Docker image.** There is no `docker run dietpi/...` command. DietPi IS the OS — it must be flashed and booted on target hardware or a VM. For a Docker-based self-hosting setup on existing Linux, skip DietPi and install Docker directly; or install DietPi and then use `dietpi-software install 162` to add Docker on top.
- **Root password.** If you don't set `AUTO_SETUP_GLOBAL_PASSWORD` in `dietpi.txt`, the default root password is `dietpi`. Change it immediately on first login (`passwd`).
- **Raspberry Pi Imager customisation popup.** Click **No** when Imager offers to apply OS customisation — DietPi's own `dietpi.txt` handles this and the Imager settings will interfere.
- **First boot is slow.** Partition expansion + package installation can take 5–20 minutes depending on hardware and `AUTO_SETUP_INSTALL_SOFTWARE_ID` list. Wait for the SSH port to open before concluding something failed.
- **WiFi country code.** For Raspberry Pi, WiFi may not work without setting `AUTO_SETUP_NET_WIFI_COUNTRY_CODE` in `dietpi.txt` (e.g. `GB`, `US`). Regulatory requirement from the Pi firmware.
- **SD card quality matters.** DietPi is disk-write heavy on setup. Use a Class 10 / A1-rated card; cheap cards corrupt under sustained write load.
- **dietpi-software IDs change between major DietPi versions.** Always verify the ID at <https://dietpi.com/docs/software/> before scripting an install.
- **Headless-first design.** DietPi deliberately ships without a desktop environment to minimise RAM usage. If you need a GUI, install one via `dietpi-software` (e.g. LXDE is available in the desktop category).

---

## Resources

- Downloads: <https://dietpi.com/#download>
- Docs: <https://dietpi.com/docs/>
- Software catalogue: <https://dietpi.com/docs/software/>
- Community forum: <https://dietpi.com/forum/>
- GitHub: <https://github.com/MichaIng/DietPi> (~6k stars)
- License: GPL-2.0
