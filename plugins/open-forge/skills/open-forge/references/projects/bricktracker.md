# BrickTracker

**What it is:** Self-hosted web app to organize and track your LEGO sets, parts, and minifigures — integrates with Rebrickable for set data.
**Official URL:** https://gitea.baerentsen.space/FrederikBaerentsen/BrickTracker
**Repo:** https://gitea.baerentsen.space/FrederikBaerentsen/BrickTracker

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Port to expose
- Rebrickable API key (for set/part data)
- Data storage path

## Software-Layer Concerns

- **Config:** Environment variables (see upstream)
- **Data dir:** Persistent volume for database and images
- **Key env vars:** REBRICKABLE_API_KEY, and others per upstream

## Upgrade Procedure

Pull latest image and restart. Back up data volume first.

## Gotchas

- Rebrickable API key required for full functionality
- Set images downloaded from Rebrickable; large collections use significant storage

## References

- [Gitea Repo](https://gitea.baerentsen.space/FrederikBaerentsen/BrickTracker)
