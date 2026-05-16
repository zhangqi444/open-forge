---
name: dietpi-project
description: DietPi recipe for open-forge. Covers image download and flash, first-boot auto-configuration via dietpi.txt, and post-boot management with dietpi-software / dietpi-config / dietpi-update. Not a Docker app — it is a full Debian-based OS for SBCs and VMs.
---

# DietPi

Extremely lightweight Debian-based OS optimised for single-board computers (Raspberry Pi, Odroid, NanoPi, Rock Pi, Orange Pi) and x86 VMs. Includes `dietpi-software` — an interactive menu to install 200+ self-hostable apps with a single command. ~100 MB RAM idle. GPL-2.0.

- **GitHub:** https://github.com/MichaIng/DietPi (6 k stars)
- **Site / download:** https://dietpi.com/
- **Docs:** https://dietpi.com/docs/
- **Forum:** https://dietpi.com/forum/

> **Not a Docker app.** DietPi is a full OS image written to SD card, USB, or a VM disk. Once running it can install Docker and run containers via `dietpi-software install 134`.

## Compatible install methods

| Method | When to use |
|---|---|
| Flash SD / USB image (SBC) | Raspberry Pi, Odroid, NanoPi, Rock Pi, Orange Pi, etc. |
| Flash to x86 VM disk | VirtualBox, VMware, Proxmox — use the x86 image |
| WSL (experimental) | Windows Subsystem for Linux — limited hardware access |
| Convert existing Debian/Ubuntu | `dietpi-PREP` script — converts a running install in-place |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which platform?" (Raspberry Pi / Odroid / NanoPi / x86 VM / other) | Drives image download URL |
| preflight | "Headless automated setup, or interactive first-boot?" | Drives whether to edit `dietpi.txt` before flashing |
| network | "WiFi or Ethernet?" | WiFi requires `dietpi-wifi.txt` credentials pre-filled |
| network | "Static IP or DHCP?" | Static needs `dietpi.txt` entries |
| software | "Which software to auto-install on first boot?" (space-separated IDs, or leave blank for interactive) | List at https://dietpi.com/docs/dietpi_tools/dietpi-software/#software-list |
| user | "Desired hostname?" | |
| user | "Timezone? (e.g. Europe/London)" | |

## Download and flash

1. Go to https://dietpi.com/#download and choose the image for your board/platform.
2. Extract: `7z x DietPi_<platform>.img.7z`
3. Flash to SD/USB:

```bash
# Verify target device first with: lsblk
sudo dd if=DietPi_<platform>.img of=/dev/sdX bs=4M status=progress conv=fsync
```

4. **Do not eject yet** — mount the FAT boot partition to edit config files.

## Automated first-boot via `dietpi.txt`

Edit `dietpi.txt` on the FAT partition before first boot:

```ini
# Hostname
AUTO_SETUP_NET_HOSTNAME=dietpi-server

# Locale / timezone / keyboard
AUTO_SETUP_LOCALE=en_GB.UTF-8
AUTO_SETUP_TIMEZONE=Europe/London
AUTO_SETUP_KEYBOARD_LAYOUT=gb

# Static IP (remove/comment these four lines to use DHCP)
AUTO_SETUP_NET_USESTATIC=1
AUTO_SETUP_NET_STATIC_IP=192.168.1.100
AUTO_SETUP_NET_STATIC_MASK=255.255.255.0
AUTO_SETUP_NET_STATIC_GATEWAY=192.168.1.1
AUTO_SETUP_NET_STATIC_DNS=9.9.9.9 8.8.8.8

# Software IDs to install automatically (space-separated)
# Example: 23=Pi-hole  83=Nextcloud  134=Docker
AUTO_SETUP_INSTALL_SOFTWARE_ID=23 134

# Skip all interactive prompts
AUTO_SETUP_AUTOMATED=1
AUTO_SETUP_GLOBAL_PASSWORD=YourSecurePassword
```

Full reference: https://dietpi.com/docs/dietpi_tools/dietpi-software/#automated-install

### WiFi credentials (`dietpi-wifi.txt` — same FAT partition)

```ini
aWIFI_SSID[0]='YourNetworkName'
aWIFI_KEY[0]='YourWiFiPassword'
```

## First boot

Insert the SD/USB, power on. DietPi will:

1. Resize the partition to fill the card
2. Update itself and packages
3. Run `AUTO_SETUP_INSTALL_SOFTWARE_ID` installs (if set)
4. Drop to a login prompt — default credentials: `root` / `dietpi`

If `AUTO_SETUP_AUTOMATED=1` is **not** set, `dietpi-launcher` opens an interactive first-run wizard.

## Core management tools

### `dietpi-software` — install / uninstall apps

```bash
# Interactive menu
dietpi-software

# Non-interactive install by ID
dietpi-software install 23     # Pi-hole
dietpi-software install 83     # Nextcloud
dietpi-software install 134    # Docker + Docker Compose
dietpi-software install 185    # Home Assistant

# Uninstall
dietpi-software uninstall 23
```

Full software list with IDs: https://dietpi.com/docs/dietpi_tools/dietpi-software/#software-list

### `dietpi-config` — hardware and system settings

```bash
dietpi-config
```

Interactive menu for display/resolution, audio, performance profile, network adapters, SSH server (Dropbear vs OpenSSH), and more.

### `dietpi-update` — update DietPi and managed software

```bash
# Interactive
dietpi-update

# Non-interactive (0=check only, 1=update)
dietpi-update 1
```

### `dietpi-backup` — full system backup

```bash
dietpi-backup 1    # backup to /mnt/dietpi_userdata/dietpi-backup
dietpi-backup 0    # restore
```

## Notable software IDs (selection)

| ID | App |
|---|---|
| 23 | Pi-hole |
| 41 | Sonarr |
| 42 | Radarr |
| 83 | Nextcloud |
| 103 | Gitea |
| 118 | Plex Media Server |
| 134 | Docker + Docker Compose |
| 162 | Portainer |
| 185 | Home Assistant |
| 30 | Transmission |
| 37 | Samba |

## Supported platforms

| Platform | Notes |
|---|---|
| Raspberry Pi 0–5 (all models) | Primary target |
| Odroid C1/C2/C4/N2/XU4 | Official images |
| NanoPi NEO / M4 / R4S | Official images |
| Rock Pi 4 | Official image |
| Orange Pi (various) | Official images |
| x86 / x64 (VM or bare metal) | VirtualBox `.ova` + raw `.img` |
| WSL | Experimental |

## Notes

- Default root password: `dietpi` — change on first login.
- User data lives under `/mnt/dietpi_userdata/` — back up before swapping SD cards.
- DietPi installs apps to `/mnt/dietpi_userdata/<appname>/` by default, placing them on the largest available drive.
- `raspi-config` is not present — use `dietpi-config` instead.
