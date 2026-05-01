# Shinobi

**Open source CCTV and IP camera recording solution — multi-account, WebSocket streams, MP4 recording, ONVIF/RTSP support, written in Node.js.**
Official site: https://shinobi.video
Docs: https://shinobi.video/docs/start
GitLab: https://gitlab.com/Shinobi-Systems/Shinobi

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal (Node.js) | See official install guide |

---

## Inputs to Collect

### Required
- Camera RTSP or ONVIF stream URLs
- Storage path for recordings

---

## Software-Layer Concerns

### Docker
Docker setup and compose files are in the `Docker/` directory of the repo:
https://gitlab.com/Shinobi-Systems/Shinobi/-/tree/dev/Docker

Full installation guide: https://shinobi.video/docs/start

### Camera compatibility
Shinobi works with cameras that support:
- **ONVIF** (H.264/H.265 streaming)
- **RTSP** protocol — use the same URL that works in VLC
- **MJPEG** streaming (works but not ideal — use RTSP/ONVIF if available)

### Key features
- Multi-account system with role management
- WebSocket-based live streams in the browser
- Direct MP4 recording
- Local and IP camera support
- Motion detection

---

## Upgrade Procedure

Follow release notes at https://shinobi.video — upgrade procedures vary by version.

---

## Gotchas

- RTSP stream URL from VLC can be used directly in Shinobi
- MJPEG is supported but significantly heavier on resources than H.264/H.265
- Community support via Discord: https://discordapp.com/invite/mdhmvuH
- Mobile app available; extended features require a Mobile License

---

## References
- Installation guide: https://shinobi.video/docs/start
- Configuration guides: https://shinobi.video/docs/configure
- Camera configs: https://shinobi.video/docs/cameras
- GitLab: https://gitlab.com/Shinobi-Systems/Shinobi
