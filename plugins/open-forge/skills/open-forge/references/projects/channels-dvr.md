# Channels DVR

**What it is:** DVR server for recording live TV from cable, antenna, or streaming sources (HDHomeRun, TVE, etc.) with a polished client app.
**Official URL:** https://getchannels.com/dvr-server/
**GitHub:** N/A (commercial product)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/macOS/Windows | Docker Compose | Official Docker image available |
| NAS (Synology, QNAP) | Docker | Supported platforms |

## Inputs to Collect

### Deploy phase
- Storage path for recordings
- Port (default: 8089)
- TV source: HDHomeRun tuner or TV Everywhere credentials

## Software-Layer Concerns

- **Config:** Web UI at http://host:8089
- **Data dir:** Mount recording storage volume
- **Key env vars:** None required; configured via web UI

## Upgrade Procedure

Pull latest Docker image and restart, or use auto-update if enabled in settings.

## Gotchas

- Requires a Channels DVR subscription ($8/month or $80/year)
- TV Everywhere channels require pay-TV provider credentials
- Large recordings — plan storage carefully

## References

- [Official Site](https://getchannels.com/dvr-server/)
- [Setup Docs](https://getchannels.com/docs/channels-dvr-server/)
