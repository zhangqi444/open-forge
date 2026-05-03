# Elysian

**What it is:** Self-hosted bookmark sync and backup tool for browsers — preserves and syncs browser bookmarks across devices.
**Official URL:** https://github.com/Aadityajoshi151/Elysian
**GitHub:** https://github.com/Aadityajoshi151/Elysian

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | See upstream |

## Inputs to Collect

### Deploy phase
- Port to expose
- Storage path for bookmark data
- Admin credentials (if applicable)

## Software-Layer Concerns

- **Config:** See upstream README
- **Data dir:** Persistent volume for bookmark storage
- **Key env vars:** See upstream docs

## Upgrade Procedure

Pull latest image and restart. Back up data first.

## Gotchas

- Browser extension may be required for sync
- Check upstream for current development status

## References

- [GitHub](https://github.com/Aadityajoshi151/Elysian)
