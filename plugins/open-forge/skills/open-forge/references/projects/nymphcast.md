---
name: nymphcast
description: NymphCast recipe for open-forge. Covers self-hosting the open-source media casting server (Chromecast alternative). Upstream: https://github.com/MayaPosch/NymphCast
---

# NymphCast

Open-source Chromecast-alternative that turns any hardware into an audio/video receiver. A NymphCast Server runs on the receiver device (connected to display/speakers); clients stream content to it over the local network, or the server streams directly from URLs. Supports multi-room synchronised playback, all codecs supported by ffmpeg, DLNA, and NymphCast Apps (AngelScript). Upstream: <https://github.com/MayaPosch/NymphCast>.

**License:** BSD-3-Clause

## NymphCast ecosystem

| Component | Purpose |
|---|---|
| NymphCast Server | Receiver — runs on the display/speaker device |
| NymphCast Player | Qt-based graphical client (Windows/macOS/Linux/Android) |
| NymphCast CLI Client | Command-line client |
| LibNymphCast | SDK for building custom clients |
| NymphCast MediaServer | Optional media library server (separate repo) |

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Build from source (C++17) | https://github.com/MayaPosch/NymphCast#id-bfs | ✅ | All supported platforms (Linux/Win/macOS/BSD/ARM) |
| Pre-built binaries (releases page) | https://github.com/MayaPosch/NymphCast/releases | ✅ | Faster setup on supported platforms |

> There is no official Docker image for NymphCast Server. It is designed as a native system service connected directly to hardware (display/audio output).

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| server | "Usage scenario?" | Audio / Video / ScreenSaver / GUI (Smart TV) | Server config |
| server | "Display/audio output device?" | Device path or name | Server INI config |
| network | "Firewall allows UDP+TCP port 4004?" | Yes/No | Required for all clients |
| media-server | "Running NymphCast MediaServer too?" | Yes/No | Also open UDP+TCP 4005 if yes |

## Usage scenarios and config profiles

| Scenario | Config profile | Use case |
|---|---|---|
| Audio-only | `nymphcast_audio_config.ini` | Speakers, headless devices |
| Audio + Video | `nymphcast_video_config.ini` | TV-connected device (Pi 4, PC) |
| Video + ScreenSaver | `nymphcast_screensaver_config.ini` | Like Video but shows image slideshow when idle |
| Smart TV (GUI) | `nymphcast_gui_config.ini` | Stand-alone GUI mode (experimental) |

## Build from source (Linux/Debian)

```bash
# Install dependencies (Debian/Ubuntu)
sudo apt-get install -y build-essential cmake libpoco-dev libsdl2-dev \
    libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libswresample-dev

# Clone and build
git clone https://github.com/MayaPosch/NymphCast.git
cd NymphCast
mkdir build && cd build
cmake ..
make -j$(nproc)
```

See the [build guide](https://github.com/MayaPosch/NymphCast#id-bfs) for platform-specific instructions.

## Running NymphCast Server

```bash
# Copy and edit the config for your scenario
cp nymphcast_video_config.ini my_config.ini
# Edit my_config.ini: set audio/video output device, buffer size, etc.

# Run the server
./nymphcast_server -c my_config.ini
```

## Software-layer concerns

### Network ports

| Port | Protocol | Purpose |
|---|---|---|
| 4004 | UDP | Server discovery (broadcast) |
| 4004 | TCP | Media streaming/playback |
| 4005 | UDP+TCP | NymphCast MediaServer (if used) |

Both UDP and TCP 4004 must be reachable by clients. Open these in your firewall.

### Config file keys (INI)

Key settings in the INI config:
- Audio output device name
- Video output (SDL display)
- Buffer size (`server_buffer_size`, default 20 MB — tune for your hardware)
- NymphCast Apps path
- Log level

### Hardware requirements

- **Audio-only:** very low — runs on Raspberry Pi 0/2/3
- **Video (h.264 1080p@24fps):** Raspberry Pi 4 is minimum tested; Pi 0/2/3 lack hardware-accelerated ffmpeg decoding
- **x86_64 Linux/Windows/macOS/BSD:** full video capability

## Upgrade procedure

```bash
cd NymphCast
git pull
cd build && make -j$(nproc)
```

## Gotchas

- **No Docker image.** NymphCast Server needs direct access to display/audio hardware; containerisation is not currently supported upstream.
- **Client required for most modes.** The server alone does nothing without a client issuing commands, except in Smart TV (GUI) mode.
- **Raspberry Pi video:** Pi 4 is the minimum for hardware-accelerated video. Pi 0/2/3 lack working hardware ffmpeg decoding via NymphCast.
- **Subsonic/Chromecast protocol:** NymphCast uses its own NymphRPC protocol — you need the NymphCast client apps, not Chromecast or DLNA remotes.
- **Firewall UDP 4004 required.** Discovery uses UDP broadcast on port 4004. If the client cannot discover the server, check firewall and network broadcast rules.
- **v0.2 in development.** The current stable is v0.1; several features (subtitles, apps) are still in progress.

## Upstream docs

- GitHub README: https://github.com/MayaPosch/NymphCast
- Audio setup guide: https://github.com/MayaPosch/NymphCast/blob/master/doc/nymphcast_audio_setup_guide.md
- Video setup guide: https://github.com/MayaPosch/NymphCast/blob/master/doc/nymphcast_video_setup_guide.md
- NymphCast MediaServer: https://github.com/MayaPosch/NymphCast-MediaServer
- Releases: https://github.com/MayaPosch/NymphCast/releases
