# Emby

**What it is:** Personal media server for streaming your movies, TV, music, and photos to any device — similar to Plex or Jellyfin.
**Official URL:** https://emby.media
**GitHub:** N/A (partially open source; core is proprietary)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Official image available |
| Linux/macOS/Windows | Native installer | .deb/.rpm/msi packages |
| NAS (Synology, QNAP) | Docker | Supported |

## Inputs to Collect

### Deploy phase
- Port (default: 8096 HTTP, 8920 HTTPS)
- Media library paths (mount as volumes)
- Optional: GPU device for hardware transcoding (/dev/dri)
- Emby account (for Emby Connect remote access)

## Software-Layer Concerns

- **Config:** Web UI at http://host:8096
- **Data dir:** /config (database, metadata cache)
- **Key env vars:** TZ, UID, GID

## Upgrade Procedure

Pull latest Docker image and restart. Emby auto-notifies of updates in the UI.

## Gotchas

- Emby Premiere subscription required for some features (hardware transcoding, mobile downloads)
- Jellyfin is the fully-open-source fork if you prefer no subscription
- Hardware transcoding requires GPU passthrough to container
- Large metadata cache — allocate sufficient disk for /config

## References

- [Official Site](https://emby.media)
- [Docker Hub](https://hub.docker.com/r/emby/embyserver)
- [Docs](https://support.emby.media)
