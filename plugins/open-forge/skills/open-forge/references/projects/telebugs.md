# Telebugs

**What it is:** Lightweight self-hosted error and exception tracking service — a simpler alternative to Sentry.
**Official URL:** https://telebugs.com
**GitHub:** N/A (commercial/proprietary)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | See upstream docs |

## Inputs to Collect

### Deploy phase
- Domain/hostname
- PostgreSQL credentials
- License/subscription info

## Software-Layer Concerns

- **Config:** Environment variables (see upstream)
- **Data dir:** PostgreSQL volume
- **Key env vars:** DATABASE_URL, SECRET_KEY_BASE

## Upgrade Procedure

Pull latest image and restart. Back up database first.

## Gotchas

- Commercial product — check licensing on telebugs.com
- Designed as a simpler/cheaper Sentry alternative

## References

- [Official Site](https://telebugs.com)
