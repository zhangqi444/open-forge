---
name: mopidy
description: Mopidy recipe for open-forge. Extensible Python music server with MPD API compatibility and streaming service extensions. Covers Debian/Ubuntu apt install and Docker. Upstream: https://github.com/mopidy/mopidy
---

# Mopidy

Extensible music server written in Python. Plays music from local disk, Spotify, SoundCloud, internet radio, and more. Controlled from any MPD or web client on your phone, tablet, or computer. Acts as a drop-in MPD replacement.

8,499 stars · Apache-2.0

Upstream: https://github.com/mopidy/mopidy
Website: https://mopidy.com/
Docs: https://docs.mopidy.com/

## What it is

Mopidy provides a modular music server:

- **MPD API** — Full superset of the MPD protocol; works with all MPD clients (ncmpcpp, Cantata, M.A.L.P., etc.)
- **HTTP API** — JSON-RPC over WebSocket for web-based clients (Iris, Mopidy-MusicBox-Webclient)
- **Extensions** — Plugin architecture for music sources and frontends
- **Local library** — Plays music from local filesystem (Mopidy-Local)
- **Streaming** — Spotify (Mopidy-Spotify), SoundCloud, TuneIn radio, YouTube, and many others via extensions
- **Headless** — No GUI required; runs as a background service

### Popular extensions

| Extension | Purpose |
|---|---|
| Mopidy-Local | Play music from local filesystem |
| Mopidy-Iris | Full-featured web UI |
| Mopidy-Spotify | Spotify (requires Spotify Premium) |
| Mopidy-SoundCloud | SoundCloud streaming |
| Mopidy-TuneIn | Internet radio |
| Mopidy-YouTube | YouTube audio |
| Mopidy-MPD | MPD protocol server (bundled) |
| Mopidy-HTTP | HTTP/WebSocket API (bundled) |

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Debian/Ubuntu apt (recommended) | https://docs.mopidy.com/stable/installation/debian/ | Raspberry Pi, Ubuntu, Debian — clean package install |
| pip | https://docs.mopidy.com/stable/installation/ | Other Linux distros, macOS |
| Arch Linux (AUR) | https://docs.mopidy.com/stable/installation/arch/ | Arch Linux |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| music_dir | "Where is your local music library? (e.g. /music)" | If using local playback |
| spotify | "Use Spotify? (requires Premium account)" | Optional |
| web_ui | "Install Iris web UI?" | Optional |
| mpd_port | "MPD port? (default: 6600)" | All |
| http_port | "HTTP API port? (default: 6680)" | If using web UI or HTTP API |

## Debian/Ubuntu apt install (recommended)

Upstream: https://docs.mopidy.com/stable/installation/debian/

### 1. Add the Mopidy APT repository

    sudo mkdir -p /usr/local/share/keyrings
    sudo wget -q -O /usr/local/share/keyrings/mopidy-archive-keyring.gpg \
      https://apt.mopidy.com/mopidy.gpg

    sudo wget -q -O /etc/apt/sources.list.d/mopidy.list \
      https://apt.mopidy.com/mopidy.list

    sudo apt update

### 2. Install Mopidy

    sudo apt install -y mopidy

### 3. Install extensions

    # Mopidy-Local (local music library)
    sudo apt install -y mopidy-local

    # Mopidy-Iris web UI
    sudo pip3 install mopidy-iris

    # Or install multiple extensions at once
    sudo pip3 install mopidy-iris mopidy-youtube mopidy-soundcloud

### 4. Configure

Edit `/etc/mopidy/mopidy.conf` (system service) or `~/.config/mopidy/mopidy.conf` (user):

    [core]
    cache_dir = /var/cache/mopidy
    config_dir = /etc/mopidy
    data_dir = /var/lib/mopidy

    [logging]
    color = true
    console_format = %(levelname)-8s %(message)s
    debug_format = %(levelname)-8s %(asctime)s %(name)s %(message)s

    [mpd]
    enabled = true
    hostname = ::
    port = 6600
    password =
    max_connections = 20

    [http]
    enabled = true
    hostname = ::
    port = 6680
    zeroconf = Mopidy HTTP server on $hostname

    [local]
    enabled = true
    media_dir = /music

    [iris]
    enabled = true

### 5. Scan local music library

    sudo mopidyctl local scan
    # Or as a user service:
    mopidy local scan

### 6. Enable and start

    sudo systemctl enable mopidy
    sudo systemctl start mopidy

### 7. Access

- **Iris web UI**: http://your-server:6680/iris/
- **MPD**: Connect your MPD client to port 6600
- **HTTP API**: http://your-server:6680/mopidy/rpc

## Raspberry Pi notes

Mopidy is popular for Pi-based music players:

    # Enable the mopidy user to access audio devices
    sudo adduser mopidy audio

    # For USB/HDMI audio, configure ALSA in mopidy.conf:
    [audio]
    output = alsasink

    # For Bluetooth speakers (via PulseAudio):
    [audio]
    output = pulsesink

## User vs system service

| Mode | Config file | Run as |
|---|---|---|
| System service | `/etc/mopidy/mopidy.conf` | `mopidy` system user |
| User service | `~/.config/mopidy/mopidy.conf` | Your user account |

For Raspberry Pi/NAS setups, the system service is typical. For desktop setups, run as a user service (`systemctl --user enable mopidy`).

## Upgrade

    sudo apt update && sudo apt upgrade mopidy
    # Pip-installed extensions:
    sudo pip3 install --upgrade mopidy-iris mopidy-local

## Gotchas

- **`hostname = ::`** — Listens on all interfaces (IPv4 + IPv6). For local-only access, use `hostname = 127.0.0.1`. Exposing MPD/HTTP on 0.0.0.0 without a firewall is a security risk.
- **Extension compatibility** — Not all extensions support all Mopidy versions. Check each extension's changelog when upgrading.
- **Spotify requires Premium** — Mopidy-Spotify only works with a Spotify Premium account. Spotify has also changed its API policies; check Mopidy-Spotify's README for current status before assuming it works.
- **Local scan must be re-run** — When you add new music to your library, run `mopidy local scan` to index it. This isn't automatic.
- **Audio output** — By default, Mopidy uses GStreamer auto-detection. On headless servers, you may need to explicitly configure `[audio] output = alsasink` or `pulsesink`.
- **Iris vs other web UIs** — Iris is the most actively maintained web UI. Mopidy-MusicBox-Webclient and others exist but may be less maintained.

## Links

- GitHub: https://github.com/mopidy/mopidy
- Website: https://mopidy.com/
- Docs: https://docs.mopidy.com/
- Debian install: https://docs.mopidy.com/stable/installation/debian/
- Extensions list: https://mopidy.com/ext/
- Iris web UI: https://github.com/jaedb/Iris
- Discourse forum: https://discourse.mopidy.com/
