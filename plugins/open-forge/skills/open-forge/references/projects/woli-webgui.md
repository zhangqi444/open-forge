# WoLi WebGUI

**What it is:** Extremely lightweight web UI for sending Wake-on-LAN (WoL) magic packets to devices on your local network.
**Official URL:** https://github.com/RemyFV/WoLi-webgui
**GitHub:** https://github.com/RemyFV/WoLi-webgui

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Tiny image |
| Any Linux | Bare metal | Single binary/script |

## Inputs to Collect

### Deploy phase
- Port to expose (default: see upstream)
- MAC addresses and device names to configure
- Network broadcast address

## Software-Layer Concerns

- **Config:** JSON/YAML config file listing devices and MAC addresses
- **Data dir:** Minimal; config file only
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart.

## Gotchas

- Must run on the same network segment as target devices (for broadcast)
- Use host networking (--network=host) in Docker to reach local network
- Device must have WoL enabled in BIOS/UEFI and network adapter settings

## References

- [GitHub](https://github.com/RemyFV/WoLi-webgui)
