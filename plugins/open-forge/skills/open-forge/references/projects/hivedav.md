# HiveDAV

**What it is:** Simple, self-hosted CalDAV and CardDAV server for calendar and contact synchronization.
**Official URL:** https://code.in0rdr.ch/hivedav/
**GitHub:** N/A (self-hosted git: https://code.in0rdr.ch/hivedav/)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal | See upstream docs |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Port (see upstream for default)
- User credentials
- Data storage path

## Software-Layer Concerns

- **Config:** Configuration file (see upstream docs)
- **Data dir:** Persistent volume for calendars and contacts
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. Back up data directory first.

## Gotchas

- Lightweight alternative to Radicale or Baikal
- No web UI for managing calendars; use CalDAV/CardDAV clients

## References

- [Upstream Repo](https://code.in0rdr.ch/hivedav/)
