# ELEMENT.FM

**What it is:** Self-hosted music streaming service.
**Official URL:** https://element.fm
**GitHub:** N/A (GitLab: https://gitlab.com/elementfm/docs)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Port (see upstream docs)
- Storage path for music library
- Admin credentials

## Software-Layer Concerns

- **Config:** See upstream documentation
- **Data dir:** Music library mount path
- **Key env vars:** See upstream docs

## Upgrade Procedure

Pull latest image and restart. Back up configuration first.

## Gotchas

- Limited public documentation; check GitLab repo for setup details

## References

- [GitLab Docs](https://gitlab.com/elementfm/docs)
