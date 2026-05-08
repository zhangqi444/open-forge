---
name: rygel-project
description: Rygel recipe for open-forge. GNOME UPnP/DLNA MediaServer and MediaRenderer for sharing home media on the local network. Covers apt/package-manager install and basic config. Based on upstream README at https://gitlab.gnome.org/GNOME/rygel.
---

# Rygel

GNOME-based UPnP AV MediaServer and MediaRenderer for sharing audio, video, and pictures on a home network. Supports DLNA, GStreamer-based transcoding, and integration with Tracker, Rhythmbox, VLC, DVB Daemon, and any app implementing the MPRIS2 D-Bus interface. LGPL-2.1. Upstream: https://gitlab.gnome.org/GNOME/rygel.

Rygel runs as a system or user service on Linux. It does not expose a web UI — media is discovered by UPnP/DLNA clients (e.g. smart TVs, Kodi, VLC, DLNA apps). Designed for local network use; not intended for internet-facing deployment.

## Compatible install methods

| Method | Platform | When to use |
|---|---|---|
| apt / package manager | Debian, Ubuntu, Fedora, Arch | Standard; simplest |
| Build from source | Any Linux | Latest features or custom patches |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "Which media directories to share?" | Path(s) | Set in ~/.config/rygel.conf or /etc/rygel.conf |
| config | "Share as which device name?" | Free-text | FriendlyName shown to UPnP clients |
| config | "Enable Tracker plugin (GNOME media index)?" | Yes / No | Uses Tracker3 if installed; MediaExport otherwise |
| config | "Enable transcoding?" | Yes / No | Requires gst-plugins-good / gst-libav |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Network | UPnP/DLNA multicast — requires LAN access; not suitable behind NAT without special config |
| Config file | ~/.config/rygel.conf (user) or /etc/rygel.conf (system) |
| Service | rygel.service (systemd user service) or started manually |
| Plugins | MediaExport (files), Tracker (GNOME library), Playbin (renderer), MPRIS2, DVBDaemon |
| Transcoding | GStreamer pipeline; requires gst-plugins-base, gst-plugins-good; optionally gst-libav, gst-plugins-bad |
| D-Bus | Required for MPRIS2 plugin and Tracker integration |
| Firewall | UPnP uses port 1900 (UDP) for discovery; random TCP ports for streaming — open or allow on LAN |

## Install: apt (Debian / Ubuntu)

```bash
sudo apt-get update
sudo apt-get install rygel rygel-tracker rygel-playbin gstreamer1.0-plugins-good gstreamer1.0-libav
```

For transcoding of more formats:
```bash
sudo apt-get install gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly
```

## Install: Fedora / RPM

```bash
sudo dnf install rygel
```

## Install: Arch Linux

```bash
sudo pacman -S rygel
```

## Configuration

Config file: ~/.config/rygel.conf (create if it doesn't exist)

```ini
[general]
friendlyname=MyHomeServer
interface=eth0        ; NIC to bind to (leave blank for all)

[MediaExport]
enabled=true
uris=@VIDEOS@;@MUSIC@;@PICTURES@;/media/nas/movies

[Tracker]
enabled=false         ; set true if GNOME Tracker3 is running and indexed

[Playbin]
enabled=true          ; UPnP renderer (allows remote control of playback)
```

Path variables: @VIDEOS@, @MUSIC@, @PICTURES@ expand to the XDG user directories.

Full config reference: https://wiki.gnome.org/Projects/Rygel/UserGuide

## Running Rygel

```bash
# Start as user service
rygel

# Or enable autostart via systemd user service
systemctl --user enable --now rygel

# Check status
systemctl --user status rygel
```

## Build from source

Source: https://gitlab.gnome.org/GNOME/rygel/-/blob/master/README.md

```bash
# Install build dependencies
sudo apt-get install valac libgupnp-1.6-dev libgupnp-av-1.0-dev libgstreamer1.0-dev \
  libgee-0.8-dev libsoup-3.0-dev libmediaart-2.0-dev libglib2.0-dev meson ninja-build

git clone https://gitlab.gnome.org/GNOME/rygel.git
cd rygel
meson setup build
ninja -C build
sudo ninja -C build install
```

## Gotchas

- LAN-only by design: UPnP/DLNA is not encrypted and relies on multicast discovery. Do not expose to the internet.
- Firewall must allow UPnP: Port 1900 UDP (SSDP discovery) and the random streaming port must be reachable on the LAN.
- MediaExport vs Tracker: If you don't run GNOME Tracker, use MediaExport and list paths manually in rygel.conf.
- Transcoding requires GStreamer plugins: Without gst-plugins-good and gst-libav, only natively supported formats are served.
- MPRIS2 plugin needs D-Bus: If Rygel can't connect to D-Bus, the MPRIS2 (media player control) plugin won't load.
- interface setting matters: On multi-NIC servers, set the interface to the LAN NIC to avoid broadcasting on the wrong network.

## Links

- Upstream: https://gitlab.gnome.org/GNOME/rygel
- GNOME wiki / user guide: https://wiki.gnome.org/Projects/Rygel/UserGuide
- DLNA spec info: https://wiki.gnome.org/Projects/Rygel
