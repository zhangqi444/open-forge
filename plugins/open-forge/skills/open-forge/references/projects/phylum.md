# Phylum

**What it is:** Offline-first cloud storage with native clients — a self-hosted alternative to Dropbox/iCloud with sync across devices.
**Official URL:** https://codeberg.org/shroff/phylum
**Repo:** https://codeberg.org/shroff/phylum

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Domain/hostname and port
- Storage path for files
- Admin credentials

## Software-Layer Concerns

- **Config:** Environment variables / config file (see upstream)
- **Data dir:** Persistent volume for stored files
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. Back up data volume first.

## Gotchas

- Offline-first design; clients sync when reconnected
- Native client apps required for desktop/mobile sync
- Check upstream for current client availability

## References

- [Codeberg Repo](https://codeberg.org/shroff/phylum)
