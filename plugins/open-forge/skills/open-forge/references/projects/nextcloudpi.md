---
name: nextcloudpi
description: NextCloudPi recipe for open-forge. Ready-to-use Nextcloud image and installer optimized for Raspberry Pi, Odroid, Rock64, LXC/LXD, and any Debian-based system. Source: https://github.com/nextcloud/nextcloudpi. Website: https://nextcloudpi.com.
---

# NextCloudPi

Ready-to-use Nextcloud deployment optimized for single-board computers (Raspberry Pi, Odroid HC1, Rock64) and any Debian-based system. Bundles Nextcloud with Apache, PHP, MariaDB, Redis, and a TUI/web configuration panel (`ncp-config`) for easy setup. Includes Let's Encrypt, Fail2Ban, UFW, SAMBA/NFS sharing, dynamic DNS, and automatic security updates out of the box. License: GPL-2.0. Upstream: <https://github.com/nextcloud/nextcloudpi>. Website: <https://nextcloudpi.com>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi (3/4/5) | Pre-built image (Raspberry Pi OS) | Flash and boot — fastest setup |
| Odroid HC1/HC2, Rock64 | Pre-built image | Board-specific images on releases page |
| Any Debian 12 (Bookworm) VPS / bare metal | Install script (`curl | bash`) | Works on x86_64 and ARM64 |
| Proxmox / any LXC host | LXC container | Official LXC template available |
| Any LXD host | LXD container | Official LXD image available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install_method | "Install method? (image / script / lxc / lxd)" | |
| hostname | "Hostname for Nextcloud?" | e.g. cloud.example.com or local IP |
| external_access | "Need external access (Let's Encrypt TLS)?" | Requires port 80/443 forwarding |
| domain | "Domain name (if Let's Encrypt)?" | e.g. cloud.example.com |
| data_dir | "Data directory for Nextcloud files?" | Default: /var/www/nextcloud/data |
| usb_drive | "Use USB drive for storage?" | ncp-config can auto-mount and move data dir |
| timezone | "Timezone?" | e.g. Europe/Berlin, America/Chicago |

## Software-layer concerns

- Stack: Nextcloud + Apache + PHP 8.1 + MariaDB + Redis (all configured automatically)
- Config panel: `ncp-config` — text-based UI accessible via SSH or locally; also available as a web panel at `https://your-pi:4443`
- **First-time setup wizard** runs at `https://your-pi/` after booting the image (generates admin password)
- Key ncp-config options:
  - `nc-letsencrypt` — generate TLS cert for external domain
  - `nc-datadir` — move Nextcloud data to a USB drive
  - `nc-automount` — auto-mount USB drives on boot
  - `nc-backup` / `nc-restore` — backup/restore Nextcloud data
  - `nc-update` — update Nextcloud and NCP
  - `nc-ramlogs` — redirect logs to RAM (reduces SD card wear)
  - `nc-fail2ban` — configure brute-force protection
- Admin Nextcloud credentials shown once during first-boot wizard — save them
- MariaDB credentials stored in `/root/.my.cnf`
- All Nextcloud config at `/var/www/nextcloud/config/config.php`

### Install: Flash image (Raspberry Pi)

```bash
# 1. Download the latest Pi image from releases
# https://github.com/nextcloud/nextcloudpi/releases
# Look for: NextcloudPi_RPi_<date>.img.zip

# 2. Flash to SD card
# macOS/Linux:
unzip NextcloudPi_RPi_*.img.zip
sudo dd if=NextcloudPi_RPi_*.img of=/dev/sdX bs=4M status=progress conv=fsync

# Or use Raspberry Pi Imager (https://www.raspberrypi.com/software/)

# 3. Insert SD, boot Pi, find its IP
# 4. Visit https://<pi-ip>/ (accept self-signed cert)
# 5. Complete the activation wizard
```

### Install: Script (Debian 12 VPS or bare metal)

```bash
# Run as root on a fresh Debian 12 system
curl -sSL https://raw.githubusercontent.com/nextcloud/nextcloudpi/master/install.sh | bash
# Follow the prompts — takes 10–15 minutes
# Admin credentials displayed at end of install
```

### Post-install: configure with ncp-config

```bash
# Via SSH on the Pi:
sudo ncp-config
# Or visit the NCP web panel: https://<your-pi>:4443
```

### Key ncp-config actions

```bash
# Move data to USB drive (reduce SD wear)
# In ncp-config → nc-datadir → set path to /media/USBdrive/ncdata

# Enable Let's Encrypt (requires port 80/443 open, valid domain)
# In ncp-config → nc-letsencrypt → enter domain

# Enable automatic Nextcloud updates
# In ncp-config → nc-autoupdate-nc

# Enable RAM-based logging (reduces SD card writes)
# In ncp-config → nc-ramlogs
```

### Router/firewall for external access

```
Port 80  → Pi IP (for Let's Encrypt HTTP challenge)
Port 443 → Pi IP (for Nextcloud HTTPS)
```

### Backup and restore

```bash
# Create backup
sudo ncp-config → nc-backup → set destination path

# Restore from backup
sudo ncp-config → nc-restore → point to backup archive
```

## Upgrade procedure

1. **NCP + Nextcloud**: via `ncp-config → nc-update` or from the NCP web panel
2. **System updates**: `sudo apt update && sudo apt upgrade` (automatic security updates enabled by default)
3. **Major Nextcloud upgrades**: handled by `nc-update` — it respects Nextcloud's version-skip restrictions
4. Full upgrade notes: https://docs.nextcloudpi.com/en/nc-update/

## Gotchas

- **SD card wear**: Running a database on an SD card causes wear. Enable `nc-ramlogs` to move logs to RAM, and ideally move the data directory (`nc-datadir`) to a USB drive or SSD via USB adapter. Use a high-endurance SD card.
- **First-boot admin password shown once**: The activation wizard at `https://<ip>/` generates and displays the admin password once. If you miss it, you can reset it: `sudo -u www-data php /var/www/nextcloud/occ user:resetpassword admin`
- **Self-signed cert on first boot**: The Pi uses a self-signed TLS cert until Let's Encrypt is configured. Accept the browser warning to complete initial setup.
- **Port 4443 for NCP panel vs 443 for Nextcloud**: NCP uses port 4443 for its own admin panel and 443 for Nextcloud. Both are HTTPS. Don't confuse them.
- **USB drive must be ext4**: The `nc-datadir` feature works best with ext4-formatted drives. FAT32/exFAT lack the file permission support Nextcloud requires.
- **Let's Encrypt requires a public domain**: Dynamic DNS (DuckDNS, no-ip, etc.) works — NCP has built-in support for both. The domain must resolve publicly for the HTTP-01 ACME challenge to succeed.
- **Not the same as Nextcloud All-in-One**: NextCloudPi is optimized for Pi/single-board computers. For a Docker-based all-in-one on a server, consider [Nextcloud AIO](https://github.com/nextcloud/all-in-one) instead.

## Links

- Upstream repo: https://github.com/nextcloud/nextcloudpi
- Website: https://nextcloudpi.com
- Documentation: https://docs.nextcloudpi.com
- Release downloads (images): https://github.com/nextcloud/nextcloudpi/releases
- Forum support: https://help.nextcloud.com/c/support/appliances-docker-snappy-vm/
- Matrix chat: https://matrix.to/#/#nextcloudpi:matrix.org
