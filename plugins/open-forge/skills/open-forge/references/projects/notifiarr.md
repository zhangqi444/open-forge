# Notifiarr

**Unified client for Notifiarr.com — notifications, media request management, and service health checks integrated with Discord and *arr apps.**
Official site: https://notifiarr.com
Wiki: https://notifiarr.wiki
GitHub: https://github.com/Notifiarr/notifiarr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / macOS / Windows | Native binary | Go binary; no container needed |
| Any Linux | Docker | Image available |

---

## Inputs to Collect

### All phases
- `DOMAIN` — local/public hostname if proxying the UI
- `DN_API_KEY` — Notifiarr.com account API key (required; create account at notifiarr.com)
- Media app URLs and API keys (Radarr, Sonarr, Plex, Tautulli, etc.) — configured in the web UI

---

## Software-Layer Concerns

### Config
- Config file and web UI; initial setup via the web interface
- Full configuration reference: https://notifiarr.wiki/pages/client/configuration/

### Data
- Lightweight; config file stored locally (path depends on OS)
- No database — all persistent state on Notifiarr.com's cloud

### Ports
- Default web UI port: `5454` (configurable)

### Install
See the official wiki for platform-specific install steps:
https://notifiarr.wiki/pages/client/install/

---

## Upgrade Procedure

Per platform — see https://notifiarr.wiki/pages/client/install/ for upgrade instructions.

For Docker:
1. `docker pull golift/notifiarr:latest`
2. `docker compose up -d`

---

## Gotchas

- A Notifiarr.com account and API key are required — the client connects to Notifiarr's cloud service
- Supports triggering scripts from Discord, syncing TRaSH profiles to Radarr/Sonarr, media requests from Discord
- Backup corruption checks and scheduled snapshot notifications for *arr apps
- Troubleshooting guide: https://notifiarr.wiki/pages/client/troubleshooting/

---

## References
- [Install Wiki](https://notifiarr.wiki/pages/client/install/)
- [Configuration Wiki](https://notifiarr.wiki/pages/client/configuration/)
- [GitHub README](https://github.com/Notifiarr/notifiarr#readme)
