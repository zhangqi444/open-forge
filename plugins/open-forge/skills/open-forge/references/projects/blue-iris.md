# Blue Iris

**What it is:** Windows-based video security and webcam software supporting hundreds of cameras with recording, motion detection, alerts, and remote viewing.
**Official URL:** https://blueirissoftware.com
**GitHub:** N/A (commercial)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Windows 10/11 or Server | Native application | Windows only |

## Inputs to Collect

### Deploy phase
- Windows machine/VM with adequate CPU (hardware decoding recommended)
- License key (trial available; full license ~$70)
- Camera RTSP/HTTP stream URLs or IP camera credentials
- Storage path for recordings

## Software-Layer Concerns

- **Config:** Blue Iris GUI settings
- **Data dir:** Defined in Blue Iris settings; typically D:\BlueIris\
- **Key env vars:** N/A — Windows app

## Upgrade Procedure

Download latest installer from blueirissoftware.com and run.

## Gotchas

- Windows-only; no Linux or Docker support
- CPU-intensive without hardware (GPU/QSV) decoding — enable hardware decode
- Web server and mobile app built-in for remote access
- Use UPS — unexpected shutdowns can corrupt the database

## References

- [Official Site](https://blueirissoftware.com)
- [Forum/Docs](https://ipcamtalk.com/wiki/blue-iris-tech-tips/)
