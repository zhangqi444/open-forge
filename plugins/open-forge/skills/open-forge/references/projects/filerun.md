# FileRun

**What it is:** Self-hosted file management and sharing solution — cloud storage with WebDAV, sharing links, and a clean web UI. Compatible with desktop sync clients.
**Official URL:** https://filerun.com
**GitHub:** N/A (commercial)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Official image available |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Port (default: 80 in container; map to host port)
- MySQL/MariaDB credentials
- File storage path (mount as volume: /user-files)

## Software-Layer Concerns

- **Config:** Web UI setup wizard on first run
- **Data dir:** /user-files for file storage; MySQL for metadata
- **Key env vars:** FR_DB_HOST, FR_DB_NAME, FR_DB_USER, FR_DB_PASS

## Upgrade Procedure

Pull latest image and restart. Check filerun.com for upgrade notes.

## Gotchas

- License required for use beyond trial (free trial available)
- MySQL/MariaDB required (no SQLite/PostgreSQL)
- WebDAV support allows desktop clients (Cyberduck, Mountain Duck, etc.)
- Compatible with Nextcloud desktop apps for file sync

## References

- [Official Site](https://filerun.com)
- [Docker Setup](https://filerun.com/docker)
- [Docs](https://docs.filerun.com)
