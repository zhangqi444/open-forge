# m3u Editor

**Full-featured IPTV editor — manage M3U/M3U8/Xtream playlists, full EPG (XMLTV + Schedules Direct), Xtream API output, series management, .strm file sync, and post-processing webhooks.**
Docs: https://sparkison.github.io/m3u-editor-docs/
GitHub: https://github.com/m3ue/m3u-editor
Discord: https://discord.gg/rS3abJ5dz7

> License: CC BY-NC-SA 4.0 (non-commercial use only)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose (modular) | ⭐ Recommended — separate m3u-editor, proxy, and Redis containers |
| Any Linux | Docker Compose (all-in-one) | Single container; no hardware acceleration |
| Any Linux | Docker Compose + VPN | Modular + Gluetun VPN |
| Any Linux | Docker Compose + Nginx/Caddy | Fully modular with external reverse proxy |

---

## Inputs to Collect

### Required
- M3U URL/file or Xtream Codes API credentials
- (Optional) EPG XMLTV URL/file or Schedules Direct credentials

---

## Software-Layer Concerns

### Default credentials (first login)
- Username: `admin`
- Password: `admin`

### Ports
- `36400` — web UI (default)

### Docker Compose files (in repo)
| File | Use case |
|------|----------|
| `docker-compose.proxy.yml` | Modular: m3u-editor + proxy + Redis (recommended) |
| `docker-compose.aio.yml` | All-in-one single container |
| `docker-compose.proxy-vpn.yml` | Modular + Gluetun VPN |
| `docker-compose.external-all.yml` | Fully modular with Nginx |
| `docker-compose.external-all-caddy.yml` | Fully modular with Caddy (auto-HTTPS) |

### Key features
- M3U, M3U8, M3U+, and Xtream Codes API input
- EPG: XMLTV files (local/remote), XMLTV URLs, Schedules Direct
- Full Xtream API output (compatible with Kodi, Tivimate, etc.)
- Series management with .strm file storage and sync
- Post-processing: custom scripts, webhooks, email notifications
- Hardware acceleration supported in modular (proxy) deployment

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Hardware acceleration requires the modular (proxy) setup — not available in all-in-one
- Default admin credentials must be changed after first login
- License is CC BY-NC-SA 4.0 — commercial use is not permitted
- Getting started guide: https://sparkison.github.io/m3u-editor-docs/docs/about/getting-started/

---

## References
- Documentation: https://sparkison.github.io/m3u-editor-docs/
- GitHub: https://github.com/m3ue/m3u-editor#readme
- Discord: https://discord.gg/rS3abJ5dz7
