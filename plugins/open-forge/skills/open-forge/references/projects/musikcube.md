---
name: musikcube
description: musikcube recipe for open-forge. Terminal-based cross-platform audio player, library, and streaming server written in C++. Covers Debian/Ubuntu install, Raspberry Pi headless audio server setup. Upstream: https://github.com/clangen/musikcube
---

# musikcube

Cross-platform, terminal-based audio engine, library, player, and streaming server written in C++. Runs on Windows, macOS, Linux, and Raspberry Pi. Can operate as a headless audio streaming server with Android remote control via musikdroid.

4,762 stars · BSD-3-Clause

Upstream: https://github.com/clangen/musikcube
Wiki: https://github.com/clangen/musikcube/wiki
Install guide: https://github.com/clangen/musikcube/wiki/installing
Releases: https://github.com/clangen/musikcube/releases

## What it is

musikcube provides a complete terminal-based music solution:

- **Terminal UI player** — Full-featured ncurses-based music player with keyboard navigation
- **Audio library** — Local music library with browsing by artist/album/genre/playlist
- **Streaming server** — `musikcubed` daemon serves audio over HTTP to remote clients
- **Android remote** — `musikdroid` Android app for remote control and streaming
- **Cross-platform** — Linux, macOS, Windows (console), Raspberry Pi
- **Audio formats** — MP3, FLAC, AAC, OGG, WMA, WAV, and more via GStreamer/ALSA/PulseAudio

Common use: Raspberry Pi connected to a home stereo, running `musikcubed` as a streaming server.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Debian/Ubuntu .deb package | https://github.com/clangen/musikcube/releases | Debian, Ubuntu, Raspberry Pi OS |
| Homebrew | `brew install musikcube` | macOS |
| FreeBSD | `pkg install musikcube` | FreeBSD |
| OpenBSD | `pkg_add musikcube` | OpenBSD |
| Chocolatey | `choco install musikcube` | Windows |
| Build from source | https://github.com/clangen/musikcube/wiki/building | Other platforms |

## Debian/Ubuntu/Raspberry Pi install

Upstream: https://github.com/clangen/musikcube/wiki/installing

### 1. Install dependencies

    apt install -y libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
      libgstreamer-plugins-good1.0-0 gstreamer1.0-plugins-bad \
      gstreamer1.0-plugins-ugly gstreamer1.0-libav \
      libcurl4 libmicrohttpd12 libtag1v5 libssl3

### 2. Download and install .deb package

Check current version at https://github.com/clangen/musikcube/releases

    VERSION=3.0.4
    ARCH=amd64   # or armhf for Raspberry Pi 32-bit, arm64 for Pi 64-bit

    wget "https://github.com/clangen/musikcube/releases/download/${VERSION}/musikcube_${VERSION}_linux_${ARCH}.deb"
    sudo dpkg -i musikcube_${VERSION}_linux_${ARCH}.deb
    sudo apt-get -f install   # fix any missing dependencies

### 3. Run the interactive player

    musikcube

Navigation:
- Arrow keys to navigate
- `Enter` to select/play
- `Space` to toggle play/pause
- `m` to open the main menu
- `?` to show key bindings

### 4. Running as a headless streaming server (Raspberry Pi)

For a Pi audio server, run `musikcubed` (the daemon):

    musikcubed start

Or as a systemd service:

    cat > /etc/systemd/system/musikcubed.service << 'SVCEOF'
    [Unit]
    Description=musikcube Audio Server
    After=network.target sound.target

    [Service]
    Type=simple
    User=pi
    ExecStart=/usr/bin/musikcubed start --foreground
    Restart=on-failure
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now musikcubed

### 5. Configure the server

On first run, musikcube creates config at `~/.musikcube/` (or `/home/<user>/.musikcube/`).

Key settings (in the app under `Preferences > Server`):

- **Library directory** — Point to your music folder
- **Server port** — Default: 7905 (HTTP streaming)
- **Password** — Set a password for remote access

Or edit `~/.musikcube/prefs/musikcore_preferences.json` directly.

### 6. musikdroid Android app

Download musikdroid from the Releases page: https://github.com/clangen/musikcube/releases

Configure in the app:
- Server: `http://your-pi-ip:7905`
- Password: (as set above)

## Scanning your music library

In the interactive UI:
1. Press `m` for menu
2. Go to `Preferences > Library`
3. Set `music_scan_path` to your music directory
4. Save and wait for scan

Or in headless mode, set the path in `musikcore_preferences.json`:

    {
      "music_library_path": "/music"
    }

## Raspberry Pi audio output

Ensure the `pi` user has audio access:

    usermod -aG audio pi

For USB DAC or HDMI audio, check available ALSA devices:

    aplay -l

Set the output device in musikcube preferences if the default isn't correct.

## Upgrade

    # Download new .deb from releases page
    sudo dpkg -i musikcube_<new_version>_linux_${ARCH}.deb
    systemctl restart musikcubed

## Gotchas

- **GStreamer plugins required** — musikcube uses GStreamer for audio decoding. If certain formats don't play, install `gstreamer1.0-plugins-ugly` (MP3) and `gstreamer1.0-libav` (AAC/M4A). These may have codec licensing implications on some systems.
- **User must be in `audio` group** — On headless servers, the service user must be in the `audio` group to access ALSA/PulseAudio: `usermod -aG audio <user>`.
- **Headless vs interactive** — `musikcubed` is the headless daemon; `musikcube` is the interactive terminal UI. For server-only use, just run `musikcubed`.
- **Config path** — Config lives in `~/.musikcube/` relative to the user running the process. For systemd services, this is the service `User`'s home directory.
- **Port 7905** — The streaming server binds to 7905 by default. Open this port if accessing from other devices: `ufw allow 7905/tcp`.

## Links

- GitHub: https://github.com/clangen/musikcube
- Wiki: https://github.com/clangen/musikcube/wiki
- Install guide: https://github.com/clangen/musikcube/wiki/installing
- Raspberry Pi setup: https://github.com/clangen/musikcube/wiki/raspberry-pi
- User guide: https://github.com/clangen/musikcube/wiki/user-guide
- Releases: https://github.com/clangen/musikcube/releases
