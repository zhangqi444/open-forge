# Obskurnee

**What it is:** Self-hosted book club management app for reading groups — track books, voting, and discussions.
**Official URL:** https://github.com/zblesk/obskurnee
**GitHub:** https://github.com/zblesk/obskurnee

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Port to expose (see upstream for default)
- Admin credentials
- Email/SMTP settings (for notifications)

## Software-Layer Concerns

- **Config:** Environment variables / config file (see upstream docs)
- **Data dir:** Persistent volume for database and uploads
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image, restart. Back up data volume first.

## Gotchas

- Designed for small reading groups; no federation
- Requires email configuration for invites

## References

- [GitHub](https://github.com/zblesk/obskurnee)
