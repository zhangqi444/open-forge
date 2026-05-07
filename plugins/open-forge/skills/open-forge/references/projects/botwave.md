---
name: botwave
description: BotWave recipe for open-forge. FM broadcasting system for Raspberry Pi with server-client architecture for managing multiple Pi transmitters remotely. Python, GPL-3.0. Source: https://github.com/dpipstudio/botwave
---

# BotWave

An FM broadcasting system for Raspberry Pi that lets you broadcast audio over FM radio. Supports single-Pi standalone operation and multi-Pi networks managed from a central server. Features remote control, live streaming, automated playback, file upload, and authentication. GPL-3.0 licensed, written in Python. Upstream: <https://github.com/dpipstudio/botwave>. Website: <https://botwave.dpip.lol>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi (client) | BotWave client | Transmits FM radio; Pi 1/2/3/4/Zero supported |
| Any Linux (server) | BotWave server | Manages one or more Pi clients remotely |
| Raspberry Pi (both) | BotWave client + server | Single Pi running both roles |

> ⚠️ **Legal notice**: FM transmission may be regulated or restricted in your country. Check local laws before transmitting. Low-power personal use is legal in many jurisdictions; transmitting on occupied frequencies or exceeding power limits may not be.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Raspberry Pi model(s) for FM transmission?" | Pi 1/2/3/4/Zero | Client role — must be a Pi with GPIO |
| "Central server IP/hostname?" | IP or hostname | If using multi-Pi server-client mode |
| "Passkey for client-server auth?" | string | Shared secret for client ↔ server auth |
| "Enable ALSA loopback for live streaming?" | Yes / No | Only needed for real-time live broadcasting |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Audio files to broadcast?" | file paths | MP3/WAV/FLAC/AAC supported — auto-converted |
| "FM frequency?" | MHz | e.g. 100.1 — check locally unoccupied frequency |

## Software-Layer Concerns

- **Raspberry Pi GPIO required for transmission**: The FM transmitter uses the Pi's GPIO pins — standard Linux servers cannot transmit, only act as BotWave server.
- **PiFM / rpitx**: BotWave uses the Pi's clock signal to generate FM — no external hardware needed beyond a short antenna wire on GPIO4.
- **Audio conversion**: Audio files are auto-converted to the required format — supports MP3, WAV, FLAC, AAC, and more.
- **Server role**: The server component runs on any Linux machine (including a Pi) and manages remote Pi clients over the network.
- **Live streaming**: Requires ALSA loopback card (`--alsa` flag during install) — for real-time audio from microphone or line-in.
- **Installer script**: Official installer at `https://botwave.dpip.lol/install` handles all dependencies.
- **Install path**: BotWave installs to `/opt/BotWave` with binaries symlinked in `/usr/local/bin`.

## Deployment

### Install (Debian-based / Raspberry Pi OS)

```bash
# Review install script first (recommended)
curl -sSL https://botwave.dpip.lol/install -o bw_install.sh
cat bw_install.sh
sudo bash bw_install.sh
# Choose: client / server / both during interactive prompt

# Non-interactive (client + ALSA loopback):
curl -sSL https://botwave.dpip.lol/install | sudo bash -s -- client --alsa

# Non-interactive (server only):
curl -sSL https://botwave.dpip.lol/install | sudo bash -s -- server
```

### Single Pi usage (local client)

```bash
# Start local client
botwave-client

# Upload audio file
botwave-client upload mytrack.mp3

# Start broadcasting on 100.1 MHz
botwave-client broadcast --freq 100.1

# Stop broadcast
botwave-client stop
```

### Multi-Pi setup

```bash
# On the server machine:
botwave-server

# On each Pi client — connect to server:
botwave-client --server 192.168.1.100 --passkey yourpasskey

# From server CLI — manage all connected clients:
# upload, broadcast, stop, list clients, etc.
```

## Upgrade Procedure

1. Re-run the install script — it detects existing installations and upgrades in place.
2. Check release notes at https://github.com/dpipstudio/botwave/releases.

## Gotchas

- **FM transmission is hardware-specific**: Only works on Raspberry Pi — the GPIO clock signal is the transmitter. Not a virtual/software-only setup.
- **Short wire antenna on GPIO4**: For better range, attach a ~75cm wire to GPIO pin 4. Transmit power is very low by design.
- **Legal compliance**: FM broadcasting regulations vary by country. Low-power personal use in the home is typically fine; check before transmitting at any significant power level.
- **ALSA loopback for live streaming**: The `--alsa` install option sets up a loopback audio device. If skipped, you can re-run with `--alsa` later.
- **Passkey for multi-Pi**: Server and client must share the same passkey — set this consistently during install or config.
- **Not a network/internet radio server**: BotWave is purely FM radio over the air — it does not stream over the internet like Icecast/Navidrome.

## Links

- Source: https://github.com/dpipstudio/botwave
- Website: https://botwave.dpip.lol
- Wiki: https://github.com/dpipstudio/botwave/wiki
- Releases: https://github.com/dpipstudio/botwave/releases
