# ViniPlay

**What it is:** Self-hosted IPTV player with a modern web interface. Streams M3U playlists with EPG (electronic program guide) data. Features multi-user management, TV guide, multi-view (watch multiple channels simultaneously), Chromecast support, DVR/recording, push notifications, FFMPEG transcoding (including GPU), and admin activity monitoring.

**GitHub:** https://github.com/ardoviniandrea/ViniPlay  
**Docker Hub:** `ardovini/viniplay:latest`  
**License:** CC BY-NC-SA 4.0 (non-commercial)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single container |
| GPU host | Docker Compose | GPU transcoding via Nvidia/IntelQSV/VAAPI passthrough |

---

## Inputs to Collect

### Phase: Deploy (`.env` file)

| Variable | Description |
|----------|-------------|
| `SESSION_SECRET` | Secret for session signing — generate a strong random string |

All other configuration (M3U sources, EPG sources, user management, stream profiles) is done via the web UI after deployment.

---

## Software-Layer Concerns

- **FFMPEG bundled** — handles stream transcoding and DVR recording; no separate install needed
- **Data volume** `./viniplay-data:/data` — app settings, M3U/EPG cache, database
- **DVR volume** `./viniplay-dvr:/dvr` — recorded TS files
- **First-time setup** — on first launch, navigate to `http://localhost:8998` and create the initial admin account
- **Configuration is all web-UI based** — add M3U/EPG sources in Settings; click "Process Sources & View Guide" to parse data
- **GPU transcoding** — requires exposing GPU to the container (Nvidia runtime, IntelQSV, or VAAPI); configured via Compose overrides

### Feature summary

| Feature | Notes |
|---------|-------|
| M3U + EPG support | Remote URLs, XC Codes, or uploaded files |
| TV Guide | High-performance virtualized EPG grid |
| Multi-view | Drag/resize multiple streams; save layouts |
| Chromecast | Cast to Google Cast devices on the network |
| DVR / Recording | Record streams; TS files seekable after recording |
| Push notifications | Browser push for upcoming programs |
| GPU transcoding | Nvidia, IntelQSV, VAAPI supported |
| Multi-user | Admin + standard user accounts |

---

## Example Docker Compose

```yaml
services:
  viniplay:
    image: ardovini/viniplay:latest
    container_name: viniplay
    ports:
      - "8998:8998"
    volumes:
      - ./viniplay-data:/data
      - ./viniplay-dvr:/dvr
    env_file:
      - ./.env
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Settings and data persist in `./viniplay-data`

---

## Gotchas

- **CC BY-NC-SA 4.0 license** — non-commercial use only; commercial use requires separate arrangement
- **DVR TS files are not seekable during active recording** — seeking works only after recording completes (roadmap item)
- **Chromecast** requires the source stream to be clean and well-formed — broken/lossy streams may fail to cast
- **SESSION_SECRET must be set** before first run — without it the app may generate an insecure default
- GPU transcoding passthrough requires additional Docker runtime configuration (e.g., `nvidia-container-toolkit`)
- M3U/EPG sources must be processed via the web UI after adding them — not automatic on startup

---

## Links

- GitHub: https://github.com/ardoviniandrea/ViniPlay
- License: https://creativecommons.org/licenses/by-nc-sa/4.0/
