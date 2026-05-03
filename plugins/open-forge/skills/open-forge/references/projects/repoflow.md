# RepoFlow

**What it is:** Self-hosted Git repository management tool for teams.
**Official URL:** N/A
**GitHub:** N/A

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | See upstream for details |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- Port
- Admin credentials

## Software-Layer Concerns

- **Config:** See upstream documentation
- **Data dir:** Persistent volume for repositories
- **Key env vars:** See upstream docs

## Upgrade Procedure

Pull latest image and restart. Back up repository data first.

## Gotchas

- Limited public documentation; check upstream for current status

## References

- See selfh.st listing for current upstream URL
