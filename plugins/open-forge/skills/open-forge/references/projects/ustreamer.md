---
name: ustreamer
description: µStreamer (ustreamer) recipe for open-forge. Covers build-from-source and package install. µStreamer is a lightweight MJPEG streaming server for V4L2 devices — used in PiKVM for low-latency HDMI/webcam streaming.
---

# µStreamer (ustreamer)

Lightweight and very quick MJPEG video streaming server for V4L2 devices. Written in C. Streams video from webcams, capture cards, Raspberry Pi camera, or any V4L2 source over HTTP as MJPEG. Natively supported by all modern browsers and VLC. Core component of the [PiKVM](https://github.com/pikvm/pikvm) project for HDMI/VGA KVM-over-IP. Supports hardware encoding on Raspberry Pi, multithreaded JPEG encoding, DV-timings for on-the-fly resolution changes, and graceful behavior when a device disconnects. Upstream: <https://github.com/pikvm/ustreamer>.

**License:** GPL-3.0 · **Language:** C · **Default port:** 8080 · **Stars:** ~2,000

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Package (Ubuntu/Debian) | `apt install ustreamer` | Distro | **Easiest** — no build required. |
| Package (Arch) | `yay -S ustreamer` (AUR) | Community | Arch Linux. |
| Build from source | <https://github.com/pikvm/ustreamer> | ✅ | Latest features, Raspberry Pi hardware encoding. |
| Docker | Community images | Community | Containerized — less common due to device passthrough needs. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| device | "V4L2 device path? (e.g. /dev/video0 — find with: v4l2-ctl --list-devices)" | Free-text | Required. |
| resolution | "Stream resolution? (e.g. 1920x1080 or 1280x720)" | Free-text | Optional. |
| fps | "Target framerate? (e.g. 30)" | Free-text | Optional. |
| port | "HTTP port to serve the stream on? (default: 8080)" | Free-text | Optional. |

## Install — Package (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install ustreamer

# Test immediately
ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080
```

Access MJPEG stream at: `http://your-server:8080/stream`

## Install — Build from source

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev

# Optional: GPIO support
# sudo apt install libgpiod-dev

# Optional: systemd socket activation
# sudo apt install libsystemd-dev

# Clone and build
git clone --depth=1 https://github.com/pikvm/ustreamer
cd ustreamer
make

# Test
./ustreamer --help
```

### Raspberry Pi (with hardware encoding)

```bash
# Raspberry OS Bullseye:
sudo apt install libevent-dev libjpeg62-turbo libbsd-dev

# Raspberry OS Bookworm:
sudo apt install libevent-dev libjpeg62-turbo-dev libbsd-dev

# Build with hardware encoding (OMX/V4L2-M2M)
make WITH_V4L2=1
```

## Usage

### Basic MJPEG stream

```bash
# Stream /dev/video0 at default settings
ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080

# Specific resolution and framerate
ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080 \
  --resolution 1280x720 --desired-fps 30

# Multithreaded encoding (faster on multi-core systems)
ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080 \
  --workers 4
```

### Stream endpoints

| URL | Content |
|---|---|
| `http://host:8080/` | Web page with embedded stream |
| `http://host:8080/stream` | Raw MJPEG stream (embed with `<img src="...">`) |
| `http://host:8080/snapshot` | Single JPEG snapshot |
| `http://host:8080/state` | JSON stream state |

Embed in a web page:
```html
<img src="http://your-server:8080/stream">
```

### Drop same frames (bandwidth saving)

Useful for HDMI sources where screen content doesn't change often:

```bash
ustreamer --device /dev/video0 --drop-same-frames 20
```

This skips up to 20 consecutive identical frames, dramatically reducing bandwidth for static screens.

### Systemd service

```ini
# /etc/systemd/system/ustreamer.service
[Unit]
Description=µStreamer MJPEG Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ustreamer --device /dev/video0 --host 0.0.0.0 --port 8080 --workers 4
Restart=unless-stopped
User=www-data
SupplementaryGroups=video

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now ustreamer
```

## Key CLI options

| Option | Description |
|---|---|
| `--device`, `-d` | V4L2 device path (default: `/dev/video0`) |
| `--host`, `-s` | Bind address (default: `localhost`) — use `0.0.0.0` for network access |
| `--port`, `-p` | HTTP port (default: `8080`) |
| `--resolution`, `-r` | Resolution like `1920x1080` |
| `--desired-fps`, `-f` | Target framerate |
| `--workers`, `-k` | JPEG encoding threads (default: 1) |
| `--drop-same-frames` | Drop up to N identical frames in a row |
| `--format`, `-x` | V4L2 pixel format (e.g. `MJPEG`, `YUYV`) |
| `--persistent`, `-z` | Don't exit on device disconnect — show "NO LIVE VIDEO" |

## Software-layer concerns

| Concern | Detail |
|---|---|
| V4L2 device access | The user running ustreamer must be in the `video` group: `sudo usermod -aG video $USER` |
| Hardware encoding (Pi) | On Raspberry Pi, use `--encoder=M2M-VIDEO` for hardware-accelerated encoding via V4L2-M2M. Requires kernel 5.15.32+. |
| MJPEG vs H.264 | µStreamer outputs MJPEG only. For H.264 streaming, consider VDO.Ninja or ffmpeg piped to HLS. |
| Docker + devices | If running in Docker, pass the device: `docker run --device /dev/video0 ...`. |
| Multiple cameras | Run multiple ustreamer instances on different ports for multiple cameras. |
| Firewall | Open the HTTP port (default 8080) if accessing from another host. |

## Upgrade procedure

```bash
# Package
sudo apt update && sudo apt upgrade ustreamer

# From source
cd ustreamer
git pull
make clean
make
sudo systemctl restart ustreamer
```

## Gotchas

- **`--host 0.0.0.0` required for network access:** By default ustreamer binds to `localhost` only. Add `--host 0.0.0.0` to make it accessible from other machines.
- **video group membership:** If you get "permission denied" on `/dev/video0`, your user isn't in the `video` group. Run `sudo usermod -aG video $USER` and log out/in.
- **MJPEG-only:** µStreamer only outputs MJPEG. Some use cases need H.264/H.265 — µStreamer is not the right tool for those.
- **Raspberry Pi hardware encoding:** Older Pi kernels (< 5.15.32) had OpenMAX/MMAL support which is now removed. Use a recent kernel and the V4L2-M2M encoder.
- **mjpg-streamer compatibility:** µStreamer implements a compatible API to mjpg-streamer's output_http plugin — most apps that can embed mjpg-streamer streams can use µStreamer too.
- **High FPS needs fast JPEG encoding:** At 1080p60, software JPEG encoding on a single CPU core may bottleneck. Use `--workers` for multi-core and hardware encoding on supported devices.

## Upstream links

- GitHub: <https://github.com/pikvm/ustreamer>
- PiKVM project: <https://github.com/pikvm/pikvm>
- Releases: <https://github.com/pikvm/ustreamer/releases>
- Ubuntu packages: <https://packages.ubuntu.com/search?keywords=ustreamer>
