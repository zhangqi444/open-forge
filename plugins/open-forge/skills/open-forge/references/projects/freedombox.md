# FreedomBox

**What it is:** Self-hosting platform and personal server that makes it easy to install and configure privacy-friendly web apps with just a few clicks — designed for non-technical users.
**Official URL:** https://freedombox.org
**Repo:** https://salsa.debian.org/freedombox-team/freedombox

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Debian Linux | APT package | Official: apt install freedombox |
| Raspberry Pi / SBC | Disk image | Pre-built images available |
| VirtualBox/QEMU | VM image | For testing |

## Inputs to Collect

### Deploy phase
- Fresh Debian install (stable recommended)
- Domain/hostname or dynamic DNS service
- Admin password (set during first-run wizard)

## Software-Layer Concerns

- **Config:** Web UI (Plinth) at http://host/plinth
- **Data dir:** Managed by FreedomBox; /var/lib/freedombox
- **Key env vars:** N/A — all configuration via web UI

## Upgrade Procedure

FreedomBox auto-updates via apt. Manual: apt update && apt upgrade
Security updates applied automatically by default.

## Gotchas

- Must run on Debian stable; not compatible with Ubuntu or other distros
- The web UI (Plinth) manages app installs — do not install apps manually
- Designed for home/SBC use; resource requirements vary by installed apps
- Full-system approach — install on a dedicated device

## References

- [Official Site](https://freedombox.org)
- [Manual](https://wiki.debian.org/FreedomBox/Manual)
