---
name: motioneye
description: motionEye recipe for open-forge. Web interface for the motion video surveillance daemon. Adds a browser UI, camera management, motion detection alerts, and recording to motion. Self-hosted via pip or Docker. Source: https://github.com/motioneye-project/motioneye. Wiki: https://github.com/motioneye-project/motioneye/wiki.
---

# motionEye

Web-based front-end for [motion](https://motion-project.github.io/), the open-source video surveillance and motion-detection daemon. motionEye adds camera management, a browser UI for live streams, motion detection configuration, scheduled recording, and email/webhook alerts on top of motion's core capabilities. Upstream: <https://github.com/motioneye-project/motioneye>. Wiki: <https://github.com/motioneye-project/motioneye/wiki>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Raspberry Pi (ARM) | Python 3.7+ (pip) | Primary use case; lightweight enough for Pi Zero 2W+ |
| Linux VPS / bare metal | Python 3.7+ (pip) | Any Debian/Ubuntu/Raspberry Pi OS host |
| Linux server | Docker | Official Docker image; recommended for x86_64 |
| Linux ARM | Docker | Multi-arch image supports armv7/arm64 |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker or native Python install?" | Docker for x86; pip for Raspberry Pi |
| cameras | "USB camera, IP camera (RTSP/HTTP), or Pi Camera module?" | Drives camera config in motionEye admin |
| port | "Port for motionEye web interface?" | Default: 8765 |
| auth | "Admin password?" | Set in web UI on first access; default is no password |
| storage | "Where to store recordings?" | Path for media files; mount external drive for long retention |

## Software-layer concerns

- Config: /etc/motioneye/motioneye.conf (native) or /etc/motioneye/ volume (Docker)
- Default port: 8765
- Media storage: /var/lib/motioneye/ (native); configure in web UI or conf file
- motion daemon: motionEye manages motion processes per camera; motion must be installed alongside (handled automatically by pip/Docker)
- Camera types supported: USB (/dev/video*), network cameras (RTSP, MJPEG HTTP), Raspberry Pi Camera Module v1/v2/v3

### Docker (x86_64)

```bash
docker run -d --name motioneye \
  -p 8765:8765 \
  --hostname motioneye \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/motioneye:/etc/motioneye \
  -v /var/lib/motioneye:/var/lib/motioneye \
  ccrisan/motioneye:master-amd64
```

For USB cameras, add `--device /dev/video0:/dev/video0` (or appropriate device path).

### Docker Compose

```yaml
services:
  motioneye:
    image: ccrisan/motioneye:master-amd64
    hostname: motioneye
    ports:
      - "8765:8765"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - motioneye-config:/etc/motioneye
      - motioneye-media:/var/lib/motioneye
    devices:
      - /dev/video0:/dev/video0   # remove if no USB camera
    restart: unless-stopped

volumes:
  motioneye-config:
  motioneye-media:
```

### Native install (Debian/Ubuntu)

```bash
sudo apt update && sudo apt install --no-install-recommends ca-certificates curl python3
curl -sSfO https://bootstrap.pypa.io/get-pip.py && sudo python3 get-pip.py
sudo pip install motioneye
sudo motioneye_init
sudo systemctl enable --now motioneye
```

## Upgrade procedure

1. pip: `sudo pip install --upgrade motioneye && sudo systemctl restart motioneye`
2. Docker: `docker pull ccrisan/motioneye:master-amd64 && docker compose up -d`
3. Check release notes: https://github.com/motioneye-project/motioneye/releases

## Gotchas

- **motion must be installed**: On native setups, the motion package must be installed separately (`sudo apt install motion`). The pip installer usually handles this, but verify.
- **Pi Camera Module**: Requires enabling the camera interface (`raspi-config`) and may need `libcamera` or legacy camera stack depending on Pi model and OS version. Check the wiki for Pi-specific setup.
- **USB camera permissions**: The web server / motioneye process must have access to /dev/video* (add user to `video` group, or use Docker `--device`).
- **Storage fills up fast**: Motion detection + recording generates large files quickly. Set storage limits and cleanup schedules in the motionEye admin UI.
- **Debian 12 / Ubuntu 23+ pip isolation**: The upstream README documents a workaround for `EXTERNALLY-MANAGED` pip blocks — add `break-system-packages=true` to /etc/pip.conf.
- **Network cameras**: RTSP streams may need ffmpeg; install with `sudo apt install ffmpeg`.
- **Remote access**: motionEye has no built-in HTTPS. Use NGINX/Caddy reverse proxy with TLS for remote access. Do NOT expose port 8765 directly to the internet.

## Links

- Upstream repo: https://github.com/motioneye-project/motioneye
- Wiki (install, config, camera setup): https://github.com/motioneye-project/motioneye/wiki
- Docker Hub: https://hub.docker.com/r/ccrisan/motioneye
- Release notes: https://github.com/motioneye-project/motioneye/releases
- motion (underlying daemon): https://motion-project.github.io
