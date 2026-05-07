---
name: ustreamer
description: µStreamer recipe for open-forge. Lightweight MJPEG streaming server for V4L2 devices. Based on upstream README at https://github.com/pikvm/ustreamer
---

# µStreamer

Lightweight and very quick server to stream MJPEG video from any V4L2 device to the network. Part of the [PiKVM](https://github.com/pikvm/pikvm) project. Upstream: <https://github.com/pikvm/ustreamer>

µStreamer is primarily designed for Raspberry Pi and V4L2-capable hardware — it streams HDMI/VGA capture cards, webcams, and camera modules as MJPEG over HTTP. It supports multithreaded JPEG encoding, hardware acceleration on Raspberry Pi (M2M/V4L2 H.264), and UNIX domain sockets.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (official image) | <https://github.com/pikvm/ustreamer#docker> | ✅ | Quick start with Docker; requires `--device` passthrough for V4L2 |
| Build from source | <https://github.com/pikvm/ustreamer#building> | ✅ | Recommended for Raspberry Pi with GPIO/hardware encoding support |
| Package manager | <https://github.com/pikvm/ustreamer#preconditions> | ✅ | Arch AUR, Fedora, Ubuntu/Debian, Alpine, OpenWRT, FreeBSD |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion`: Docker / Build from source / Package manager | All |
| hardware | "Which video device (e.g. /dev/video0)?" | Free-text | All |
| hardware | "Is this a Raspberry Pi with HDMI capture?" | `AskUserQuestion`: Yes / No | Determines EDID and encoder flags |
| network | "Which port should µStreamer listen on?" | Free-text, default `8080` | All |

## Software-layer concerns

**Config paths:**
- No config file — all configuration via command-line flags
- Optionally managed via systemd unit with `ExecStart` flags

**Environment:**
- Requires `/dev/video0` (or other V4L2 device) accessible on the host
- For hardware encoding on Raspberry Pi 4: kernel ≥ 5.15.32 (OpenMAX/MMAL deprecated)

**Data dirs:**
- No persistent data — streams are live video only

## Method — Docker (official image)

> **Source:** <https://github.com/pikvm/ustreamer#docker>

The simplest path. Requires Docker 20.10+ and V4L2 device passthrough.

### Basic launch

```bash
# Stream from /dev/video0 on port 8080
docker run --device /dev/video0:/dev/video0 -p 8080:8080 pikvm/ustreamer:latest
```

Then open `http://<host>:8080` in a browser to view the MJPEG stream.

### HDMI capture (Raspberry Pi)

For Raspberry Pi 4 with HDMI-to-CSI bridge (e.g. TC358743):

1. Add to `/boot/firmware/usercfg.txt`:
   ```
   gpu_mem=128
   dtoverlay=tc358743
   ```
2. Ensure CMA is at least 128MB (check with `dmesg | grep cma-reserved`). If not, add `cma=128M` to `/boot/firmware/cmdline.txt` and reboot.

3. Start with EDID support:
   ```bash
   docker run --device /dev/video0:/dev/video0 -e EDID=1 -p 8080:8080 pikvm/ustreamer:latest
   ```

### Custom encoder flags

```bash
docker run --rm pikvm/ustreamer:latest \
    --format=uyvy \
    --workers=3 \
    --persistent \
    --dv-timings \
    --drop-same-frames=30
```

## Method — Build from source

> **Source:** <https://github.com/pikvm/ustreamer#building>

Recommended for Raspberry Pi when you need GPIO, systemd socket activation, or hardware encoding.

### Prerequisites

Install build deps for your distro:

```bash
# Arch
sudo pacman -S libevent libjpeg-turbo libutil-linux libbsd

# Raspberry Pi OS Bullseye
sudo apt install libevent-dev libjpeg62-turbo libbsd-dev
# Optional: libgpiod-dev (GPIO), libsystemd-dev (systemd), libasound2-dev libspeex-dev libspeexdsp-dev libopus-dev (Janus/WebRTC)

# Raspberry Pi OS Bookworm
sudo apt install libevent-dev libjpeg62-turbo-dev libbsd-dev

# Debian / Ubuntu
sudo apt install build-essential libevent-dev libjpeg-dev libbsd-dev

# Alpine
sudo apk add libevent-dev libbsd-dev libjpeg-turbo-dev musl-dev
# Build with: make WITH_PTHREAD_NP=0
```

### Build and run

```bash
git clone --depth=1 https://github.com/pikvm/ustreamer
cd ustreamer
make
./ustreamer --help
```

### Optional build flags

| Flag | Purpose |
|---|---|
| `WITH_GPIO=1` | GPIO signal support via libgpiod |
| `WITH_SYSTEMD=1` | systemd socket activation |
| `WITH_JANUS=1` | WebRTC via Janus gateway |
| `WITH_PTHREAD_NP=0` | Alpine / no `pthread_get_name_np()` |
| `WITH_SETPROCTITLE=0` | No `setproctitle()` available |

```bash
make WITH_GPIO=1 WITH_SYSTEMD=1
```

### Raspberry Pi camera examples

```bash
# RPi v3 camera (libcamera)
sudo modprobe bcm2835-v4l2
libcamerify ./ustreamer --host :: --encoder=m2m-image

# RPi v1 camera (high-res still mode)
sudo modprobe bcm2835-v4l2
./ustreamer --host :: -m jpeg --device-timeout=5 --buffers=3 -r 2592x1944
```

> ⚠️ For RPi camera modules at resolutions > 1280×720, pass `max_video_width` and `max_video_height` module params to `bcm2835-v4l2` to avoid low-framerate photo mode.

## Method — Package manager

```bash
# Arch Linux (AUR)
yay -S ustreamer

# Ubuntu / Debian
sudo apt install ustreamer

# Fedora
sudo dnf install ustreamer

# Alpine
sudo apk add ustreamer

# OpenWRT (via packages feed)
opkg install ustreamer

# FreeBSD (ports)
pkg install ustreamer
```

## Upgrade procedure

**Docker:**
```bash
docker pull pikvm/ustreamer:latest
# Restart container
```

**Source:**
```bash
cd ustreamer
git pull
make clean
make
```

**Package manager:**
```bash
# Debian/Ubuntu
sudo apt update && sudo apt upgrade ustreamer
```

## Gotchas

- **Kernel requirement for Raspberry Pi 4 hardware encoding:** Must have kernel ≥ 5.15.32. OpenMAX and MMAL on older kernels are deprecated and removed.
- **V4L2 device must be accessible:** On Docker, must pass `--device /dev/video0`. On bare metal, user must be in the `video` group (`sudo usermod -aG video $USER`).
- **PTHREAD_NP on Alpine:** Compile with `WITH_PTHREAD_NP=0` or the build will fail with missing function errors.
- **`setproctitle()` on some platforms:** If compile fails on `setproctitle`, add `WITH_SETPROCTITLE=0`.
- **Multiple cameras:** Each µStreamer instance handles one V4L2 device. Run multiple instances on different ports for multiple cameras.
- **High-res still mode on older RPi cameras:** BCM2835-V4L2 switches to low-FPS photo mode above 1280×720; pass `max_video_width`/`max_video_height` module params to override.

## Links

- Upstream README: <https://github.com/pikvm/ustreamer>
- PiKVM project: <https://pikvm.org>
- Docker Hub: <https://hub.docker.com/r/pikvm/ustreamer>
