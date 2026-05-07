---
name: MistServer
description: Open source, public domain, full-featured streaming media server for OTT/internet streaming. Supports any device and any format. Built for developers and system integrators.
website: https://mistserver.org/
source: https://github.com/DDVTECH/mistserver
license: Public Domain
stars: 492
tags:
  - streaming
  - media-server
  - video
  - ott
  - live-streaming
platforms:
  - C++
  - Docker
---

# MistServer

MistServer is a public domain, open-source streaming media toolkit designed for OTT (internet streaming) deployments. It supports HLS, DASH, RTMP, WebRTC, and many other protocols, serving any device and format. The architecture is modular — each input, output, and process is a separate binary that the controller discovers automatically.

Official site: https://mistserver.org/
Source: https://github.com/DDVTECH/mistserver
Docs: https://docs.mistserver.org
Downloads: https://mistserver.org/download
Latest: check https://github.com/DDVTECH/mistserver/releases

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Pre-compiled binary | Recommended; installer from mistserver.org |
| Any Linux | Build from source (Meson/Ninja) | For custom builds |
| Any Linux | Docker | Official/community images available |

## Inputs to Collect

**Phase: Planning**
- Stream sources (RTMP ingest, file-based VOD, live capture)
- Output formats needed (HLS, DASH, RTMP, WebRTC, etc.)
- Port for API/web UI (default: 4242)
- HTTP output port (default: 8080)
- RTMP ingest port (default: 1935)
- Whether to run behind a reverse proxy

## Software-Layer Concerns

**Install via official installer (recommended):**

```bash
# Visit https://mistserver.org/download
# Use "Copy install cmd" button on the download page for your OS
# Example (verify the URL on the download page):
curl -fsSL https://releases.mistserver.org/is/mistserver_64Vaapi.tar.gz | sh
# Installs binaries and registers a systemd service
```

**Build from source:**

```bash
# Dependencies
sudo apt install meson ninja-build build-essential libssl-dev

git clone https://github.com/DDVTECH/mistserver
cd mistserver
meson setup build
cd build
ninja
# Run directly
./MistController
```

**Start MistController:**

```bash
# The controller binary discovers all Mist* binaries in the same directory
./MistController
# First run walks through setup wizard
# Web UI available at http://localhost:4242
```

**Key ports:**

| Port | Protocol | Purpose |
|------|----------|---------|
| 4242 | TCP | Web UI and JSON API |
| 8080 | TCP | HTTP output (HLS, DASH, etc.) |
| 1935 | TCP | RTMP ingest |
| 4200 | UDP | WebRTC (configurable) |

**Stream via RTMP ingest:**

```
rtmp://your-server:1935/live/stream-key
```

**HLS playback URL:**

```
http://your-server:8080/hls/stream-key/index.m3u8
```

**Nginx reverse proxy (optional):**

```nginx
server {
    listen 80;
    server_name stream.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_buffering off;
    }

    location /api {
        proxy_pass http://127.0.0.1:4242;
    }
}
```

**Modular architecture:** Remove any `Mist*` binary you don't need — the controller only loads what's present. This keeps the footprint minimal.

## Upgrade Procedure

1. Stop MistServer: `systemctl stop mistserver`
2. Download new binaries from https://mistserver.org/download
3. Replace binaries in the install directory
4. `systemctl start mistserver`
5. Check changelog: https://docs.mistserver.org/category/changelog

## Gotchas

- **Public domain license**: MistServer is explicitly placed in the public domain — no copyleft restrictions
- **Binary discovery**: All `Mist*` binaries must be in the same directory as `MistController` — the controller won't find modules installed elsewhere
- **Web UI on port 4242**: The API and web interface share port 4242; restrict this port with a firewall or reverse proxy — do not expose publicly without authentication
- **Format support**: Supported input/output formats depend on which binaries are installed; check https://docs.mistserver.org for the full matrix
- **RTMP deprecated in browsers**: RTMP ingest from OBS works fine, but playback in modern browsers requires HLS or DASH output — configure the appropriate output protocol
- **Commercial support**: Datavideo/DDVTECH offer commercial support plans via mistserver.org for production deployments

## Links

- Upstream README: https://github.com/DDVTECH/mistserver/blob/master/README.md
- Documentation: https://docs.mistserver.org
- Downloads: https://mistserver.org/download
- Releases: https://github.com/DDVTECH/mistserver/releases
