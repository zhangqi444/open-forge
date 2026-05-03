# FileFlows

**What it is:** Automated media file processing pipeline — transcode, rename, move, and manage media files using a visual node-based workflow editor.
**Official URL:** https://fileflows.com
**GitHub:** N/A (source at https://github.com/revenz/FileFlows)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal (.NET) | Supported |

## Inputs to Collect

### Deploy phase
- Port (default: 19200)
- Media source/destination paths (mount as volumes)
- Optional: hardware transcoding device (/dev/dri for Intel QSV/VAAPI)

## Software-Layer Concerns

- **Config:** Web UI at http://host:19200
- **Data dir:** /app/Data (flows, database), /app/Logs, /app/Temp
- **Key env vars:** TZ (timezone)

## Upgrade Procedure

Pull latest Docker image and restart. FileFlows backs up its database automatically.

## Gotchas

- Hardware transcoding requires passing GPU device to container
- Temp directory needs sufficient space for in-progress transcoding
- Processing nodes can run separately from server for distributed encoding

## References

- [Official Site](https://fileflows.com)
- [GitHub](https://github.com/revenz/FileFlows)
- [Docs](https://fileflows.com/docs)
