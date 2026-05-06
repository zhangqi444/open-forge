# moOde Audio Player

moOde is an audiophile-quality music player for Raspberry Pi single-board computers. Built on MPD (Music Player Daemon) and a custom PHP/WebUI, it provides a responsive web interface for high-quality local audio playback with extensive DSP, hardware DAC support, and network streaming.

**Website:** https://moodeaudio.org/
**Source:** https://github.com/moode-player/moode
**License:** GPL-3.0
**Stars:** ~1,331

> ⚠️ **Raspberry Pi only**: moOde is specifically designed for Raspberry Pi hardware. It ships as a complete OS image (not a Docker container or generic Linux package). General-purpose Linux servers are not a supported target.

---

## Compatible Combos

| Hardware | Method | Notes |
|----------|--------|-------|
| Raspberry Pi 4/5 | Pre-built SD card image | Recommended |
| Raspberry Pi 3B+ | Pre-built SD card image | Supported |
| Raspberry Pi Zero 2W | Pre-built SD card image | Lightweight use |
| Raspberry Pi with USB DAC | Image + DAC config | Wide DAC support |
| Raspberry Pi with HAT DAC | Image + device tree overlay | Requires correct overlay name |

---

## Inputs to Collect

### Phase 1 — Planning
- Raspberry Pi model
- DAC/audio interface: built-in 3.5mm, USB DAC, or I²S HAT DAC
- Music source: local USB drive/NAS, Spotify, AirPlay, Bluetooth, UPnP
- Network connection: Wi-Fi or Ethernet

### Phase 2 — First Boot
- Wi-Fi SSID/password (if not using Ethernet)
- Hostname (default: `moode`)
- Music library location (USB drive or NFS/SMB mount path)
- NAS credentials (if using network storage)

---

## Software-Layer Concerns

### Installation
moOde ships as a complete Raspberry Pi OS image:

1. Download the latest `.img.zip` from https://moodeaudio.org
2. Flash to microSD card using Raspberry Pi Imager or balenaEtcher
3. Insert SD, connect to network, power on
4. Access the web UI at: `http://moode.local` (or `http://<IP>:80`)

```bash
# Flash via CLI (Linux/macOS)
unzip moode_*.img.zip
sudo dd if=moode_*.img of=/dev/sdX bs=4M status=progress conv=fsync
```

### First Configuration (Web UI)
- Navigate to `http://moode.local`
- Go to **Menu → Configure → System** to set hostname, timezone, locale
- Go to **Menu → Configure → Audio** to configure DAC/audio output
- Go to **Menu → Sources** to add music sources (USB, NAS, Spotify, etc.)

### Audio Output Configuration
```
# I²S HAT DAC (e.g. HifiBerry DAC+):
Menu → Configure → Audio → Audio Interface: I2S audio device
Select DAC from dropdown → Save → Reboot

# USB DAC:
Menu → Configure → Audio → Audio Interface: USB audio device
Select device from list → Save

# HDMI/3.5mm (built-in):
Menu → Configure → Audio → Audio Interface: ALSA
```

### Network Music Sources (NAS/NFS)
```
# In web UI:
Menu → Sources → NAS Drive
Enter NAS IP, share name, credentials

# Or via SMB directly (config file):
# /etc/fstab entry added automatically by moOde UI
```

### SSH Access
SSH is available by default:
```bash
ssh pi@moode.local
# Default password: moodeaudio
```

### MPD Configuration
moOde manages MPD config via its UI. Direct config at `/etc/mpd.conf`.
Restart MPD:
```bash
sudo systemctl restart mpd
```

### Key Features
- **MPD-based**: Full MPD backend with extensive format support (FLAC, DSD, WAV, MP3, AAC, etc.)
- **DSP processing**: CamillaDSP integration for EQ, crossfeed, convolution filters
- **Streaming protocols**: AirPlay, Spotify Connect, Bluetooth, UPnP/DLNA renderer
- **Renderer modes**: Can act as MPD client, AirPlay target, Spotify Connect device
- **Hardware volume**: Supports hardware volume control on compatible DACs

---

## Upgrade Procedure

moOde upgrades are delivered as new SD card images (full OS refresh):

```bash
# Option 1: Re-flash with new image (safest, fresh start)
# - Export settings backup from UI: Menu → Configure → Backup/Restore
# - Flash new image to SD
# - Restore settings from backup

# Option 2: In-place package update (when available)
# Check: Menu → System → Software Update
# Not all releases support in-place update
```

---

## Gotchas

- **Pi-only**: moOde is not a generic Linux app. It won't run on x86 or other ARM hardware meaningfully; it's tightly integrated with Pi hardware.
- **Full OS image**: It replaces your entire SD card OS — don't install on an SD card with other data.
- **SSH password**: Change the default `moodeaudio` SSH password immediately if network-accessible.
- **DAC configuration**: Using the wrong I²S overlay for your HAT DAC causes no audio output or system instability. Match the overlay to your exact DAC model.
- **USB drive formatting**: Supported filesystems are FAT32, exFAT, and ext4. NTFS has limited support.
- **DSD playback**: Requires a DSD-capable DAC and the correct MPD DSD output mode (native DSD or DoP).
- **No Docker/VM support**: Cannot be run inside a container or VM — it requires bare-metal Pi GPIO and audio hardware access.

---

## Links
- Setup Guide: https://github.com/moode-player/docs/blob/main/setup_guide.md
- Download Images: https://moodeaudio.org/ (main site downloads page)
- Forum / Support: https://moodeaudio.org/forum
- Changelog: https://github.com/moode-player/moode/blob/master/www/relnotes.txt
- GitHub: https://github.com/moode-player/moode
