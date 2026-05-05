---
name: snapcast
description: Snapcast recipe for open-forge. Synchronous multiroom audio server — all clients play audio in perfect sync. Covers server (snapserver) and client (snapclient) install on Debian/Raspberry Pi, and integration with MPD/Mopidy. Upstream: https://github.com/badaix/snapcast
---

# Snapcast

Synchronous multiroom audio player. The server captures audio from a source (MPD, Mopidy, pipe) and streams it to all connected clients, synchronized to within ~0.2ms. Turns any Linux devices (Raspberry Pis, laptops, NAS boxes) into a Sonos-like multiroom audio system.

7,608 stars · GPL-3.0

Upstream: https://github.com/badaix/snapcast
Releases: https://github.com/badaix/snapcast/releases
Install docs: https://github.com/badaix/snapcast/blob/master/doc/install.md

## What it is

Snapcast is a client-server audio system:

- **Snapserver** — Captures audio from a source (named pipe, ALSA, TCP, process stdout) and streams encoded PCM to clients
- **Snapclient** — Receives the stream and plays it through the local sound system, synchronized with all other clients
- **Multiple streams** — Server can serve multiple audio sources simultaneously; clients subscribe to a stream
- **Codecs** — FLAC (lossless, default), PCM, Vorbis, Opus
- **Control API** — JSON-RPC over WebSocket for remote control and status
- **Web UI** — Optional browser-based control interface

**Common setup**: Mopidy (or MPD) on the server writes audio to a named pipe; Snapserver reads that pipe and streams to Raspberry Pi clients around the house.

## Components

| Component | Role | Install where |
|---|---|---|
| `snapserver` | Audio source server | Central server/NAS |
| `snapclient` | Audio player | Each room device (Pi, laptop, etc.) |

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Debian .deb package (recommended) | https://github.com/badaix/snapcast/releases | Debian/Ubuntu/Raspberry Pi OS |
| Alpine Linux apk | `apk add snapcast` | Alpine |
| Arch Linux AUR | AUR: snapcast | Arch |
| Homebrew | `brew install snapcast` | macOS |
| Build from source | https://github.com/badaix/snapcast/blob/master/doc/build.md | Other platforms |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| audio_source | "Where does audio come from? MPD, Mopidy, or other?" | Server setup |
| pipe_path | "Named pipe path? (default: /tmp/snapfifo)" | MPD/Mopidy integration |
| server_ip | "IP of the snapserver?" | Client setup |

## Debian/Ubuntu/Raspberry Pi OS install

Upstream: https://github.com/badaix/snapcast/releases

Download the latest `.deb` packages from the releases page. Replace `0.x.x` with the current version and choose the right arch (`armhf` for Pi 3/4, `arm64` for Pi 4/5 64-bit, `amd64` for x86_64).

### Server install

    # Check current version at: https://github.com/badaix/snapcast/releases
    VERSION=0.31.0
    ARCH=amd64  # or armhf / arm64

    wget "https://github.com/badaix/snapcast/releases/download/v${VERSION}/snapserver_${VERSION}-1_${ARCH}.deb"
    sudo apt install ./snapserver_${VERSION}-1_${ARCH}.deb

    sudo systemctl enable --now snapserver

### Client install (on each room device)

    VERSION=0.31.0
    ARCH=armhf  # Raspberry Pi 3/4 32-bit

    wget "https://github.com/badaix/snapcast/releases/download/v${VERSION}/snapclient_${VERSION}-1_${ARCH}.deb"
    sudo apt install ./snapclient_${VERSION}-1_${ARCH}.deb

    sudo systemctl enable --now snapclient

## Server configuration

Config file: `/etc/snapserver.conf`

    [server]
    # The server binds to all interfaces by default

    [stream]
    # Named pipe source (for MPD/Mopidy integration)
    source = pipe:///tmp/snapfifo?name=default

    # Multiple streams example:
    # source = pipe:///tmp/snapfifo?name=MPD
    # source = tcp://0.0.0.0:4953?name=Radio

    [http]
    enabled = true
    bind_to_address = 0.0.0.0
    port = 1780
    # Web UI available at http://server-ip:1780/

Full config reference: https://github.com/badaix/snapcast/blob/master/doc/configuration.md

## Client configuration

Config file: `/etc/default/snapclient`

    SNAPCLIENT_OPTS="--host <SERVER_IP>"

Or edit the systemd unit / config:

    # /etc/snapclient.conf
    [client]
    server = 192.168.1.10

## MPD integration

Configure MPD to output audio to a named pipe that Snapserver reads.

Add to `/etc/mpd.conf`:

    audio_output {
        type            "fifo"
        name            "Snapcast"
        path            "/tmp/snapfifo"
        format          "48000:16:2"
        mixer_type      "software"
    }

Restart MPD: `systemctl restart mpd`

The pipe at `/tmp/snapfifo` must exist and be writable by both MPD and snapserver.

    mkfifo /tmp/snapfifo
    chmod 777 /tmp/snapfifo

## Mopidy integration

Add to `/etc/mopidy/mopidy.conf`:

    [audio]
    output = audioresample ! audioconvert ! audio/x-raw,rate=48000,channels=2,format=S16LE ! filesink location=/tmp/snapfifo

Restart Mopidy: `systemctl restart mopidy`

## Web UI and JSON-RPC API

Snapserver includes a built-in web UI at `http://server-ip:1780/` when HTTP is enabled.

JSON-RPC WebSocket API for programmatic control: `ws://server-ip:1705/jsonrpc`

Third-party control apps:
- **Snapdroid** — Android client with stream switching
- **Snipaste** — iOS client

## Firewall

    ufw allow 1704/tcp   # snapserver stream port
    ufw allow 1705/tcp   # snapserver control port (JSON-RPC)
    ufw allow 1780/tcp   # HTTP web UI (optional)

## Upgrade

    # Download new .deb from releases page and reinstall:
    sudo apt install ./snapserver_<new_version>.deb
    sudo apt install ./snapclient_<new_version>.deb

## Gotchas

- **Named pipe must exist before services start** — Create `/tmp/snapfifo` with `mkfifo` before starting snapserver and MPD/Mopidy. The pipe is not created automatically. Consider creating it in a systemd `ExecStartPre` or `/etc/rc.local`.
- **Audio format must match** — The pipe format in MPD/Mopidy config (`48000:16:2`) must match what Snapserver expects. Mismatched formats cause distorted/silent audio.
- **`/tmp/snapfifo` is lost on reboot** — `/tmp` is cleared on boot. Use a persistent path like `/var/lib/snapcast/snapfifo` and create it in the service or on boot.
- **Client and server versions should match** — Protocol changes between versions can cause incompatibility. Keep server and all clients on the same release.
- **Latency vs. compression** — FLAC (default) is lossless but adds ~100ms latency. Opus adds less latency for similar bandwidth. Configure `codec` in snapserver.conf if latency matters.
- **Raspberry Pi audio** — On Pi, specify the output device if the default isn't what you want: `snapclient --soundcard <device>`. List devices with `snapclient --list`.

## Links

- GitHub: https://github.com/badaix/snapcast
- Releases: https://github.com/badaix/snapcast/releases
- Install guide: https://github.com/badaix/snapcast/blob/master/doc/install.md
- Configuration reference: https://github.com/badaix/snapcast/blob/master/doc/configuration.md
- Build from source: https://github.com/badaix/snapcast/blob/master/doc/build.md
