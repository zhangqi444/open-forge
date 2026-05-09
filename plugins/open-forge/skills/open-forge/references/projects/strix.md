---
name: strix
description: "IP camera stream finder and Frigate config generator. MIT. Eduard256. Docker (host networking, single container). Tests 100,000+ URL patterns against a camera IP in 30 seconds with live screenshots. Generates ready Frigate/go2rtc configs. Supports RTSP, HTTP, RTMP, Bubble, DVRIP, HomeKit. 3,600+ brands in SQLite database."
---

# Strix

**IP camera stream discovery tool and Frigate config generator.** Enter your camera's IP, pick your model from a database of 3,600+ brands and 100,000+ URL patterns — Strix tests every possible stream URL in parallel with live screenshots and generates a ready-to-use Frigate or go2rtc config. MIT license.

Built + maintained by **Eduard256**.

- Upstream repo: <https://github.com/Eduard256/Strix>
- Docker Hub: `eduard256/strix`
- Camera database browser: <https://gostrix.github.io/>
- Live demo: <https://gostrix.github.io/demo.html>

## Architecture in one minute

- Single stateless Go binary / Docker container
- SQLite camera database with 100,000+ URL patterns (embedded in image / binary)
- Uses 20 parallel workers to test stream URLs; ffmpeg (bundled) for live screenshot capture
- Auto-discovers Frigate and go2rtc on the local network
- **Requires host networking** for ARP/OUI discovery and network scanning (needs `NET_RAW` + `NET_ADMIN` capabilities)
- Web UI on port `4567`

## Compatible install methods

| Method | Notes |
|--------|-------|
| **One-line installer** | **Easiest** — auto-detects Linux / Proxmox |
| **Docker / Docker Compose** | Recommended for self-hosted setups |
| Home Assistant add-on | Via `hassio-strix` repository |
| Umbrel | Via Umbrel App Store |
| Binary | Standalone; requires `ffmpeg` |

## Install via one-liner (Linux / Proxmox)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Eduard256/Strix/main/install.sh)
```

Run as root or with `sudo`. Interactive installer guides through setup. Opens at `http://YOUR_IP:4567`.

## Install via Docker

```bash
docker run -d \
  --name strix \
  --network host \
  --restart unless-stopped \
  eduard256/strix:latest
```

> `--network host` is required for ARP/OUI-based device probing and network discovery.

## Docker Compose

### Strix standalone

```bash
curl -O https://raw.githubusercontent.com/Eduard256/Strix/main/docker-compose.yml
docker compose up -d
```

```yaml
services:
  strix:
    container_name: strix
    image: eduard256/strix:latest
    network_mode: host
    restart: unless-stopped
    environment:
      STRIX_LISTEN: ":4567"
      # STRIX_LOG_LEVEL: debug
```

### Strix + Frigate

```bash
curl -O https://raw.githubusercontent.com/Eduard256/Strix/main/docker-compose.frigate.yml
docker compose -f docker-compose.frigate.yml up -d
```

### Strix + go2rtc

```bash
curl -O https://raw.githubusercontent.com/Eduard256/Strix/main/docker-compose.go2rtc.yml
docker compose -f docker-compose.go2rtc.yml up -d
```

## Podman

Podman drops network capabilities by default — add them explicitly:

```bash
podman run -d \
  --name strix \
  --network host \
  --cap-add=NET_RAW \
  --cap-add=NET_ADMIN \
  --restart unless-stopped \
  eduard256/strix:latest
```

## Configuration

| Env var | Default | Description |
|---------|---------|-------------|
| `STRIX_LISTEN` | `:4567` | HTTP listen address |
| `STRIX_DB_PATH` | `cameras.db` | Path to SQLite camera database |
| `STRIX_LOG_LEVEL` | `info` | Log level: `debug`, `info`, `warn`, `error`, `trace` |
| `STRIX_FRIGATE_URL` | auto-discover | Frigate URL, e.g. `http://localhost:5000` |
| `STRIX_GO2RTC_URL` | auto-discover | go2rtc URL, e.g. `http://localhost:1984` |

## How to use

1. Open `http://YOUR_HOST:4567`
2. **Enter camera IP** — Strix probes the device (open ports, MAC vendor, mDNS, HTTP server)
3. **Search camera model** in the database; enter credentials if needed
4. Strix builds all possible stream URLs from database patterns
5. **20 parallel workers** test every URL — live screenshots, codecs, resolution, latency shown
6. **Pick main and sub streams** from results
7. **Generate Frigate config** — copy, download, or push directly to Frigate

## Supported protocols

| Protocol | Port | Description |
|----------|------|-------------|
| RTSP | 554 | Most IP cameras |
| RTSPS | 322 | RTSP over TLS |
| HTTP/HTTPS | 80/443 | MJPEG, JPEG snapshots, HLS, MPEG-TS |
| RTMP | 1935 | Some Chinese NVRs |
| Bubble | 80 | XMeye/NetSurveillance cameras |
| DVRIP | 34567 | Sofia protocol DVR/NVR |
| HomeKit | 51826 | Apple HomeKit cameras via HAP |

## Camera database

- 3,600+ brands, 100,000+ URL patterns in SQLite
- Maintained separately at [StrixCamDB](https://github.com/Eduard256/StrixCamDB)
- Database is embedded in the Docker image (no manual download needed)
- Missing camera? [Contribute via the database browser](https://gostrix.github.io/#/contribute)

## Home Assistant add-on

1. **Settings → Add-ons → Add-on Store**
2. Menu (top right) → **Repositories** → add `https://github.com/eduard256/hassio-strix`
3. Install **Strix**, enable **Start on boot** and **Show in sidebar**

## Updating

```bash
docker compose pull
docker compose up -d
```
