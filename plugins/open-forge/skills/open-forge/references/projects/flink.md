# Flink

**What it is:** Zero-config URL shortener with QR code generation and analytics.
**Official URL:** https://gitlab.com/rtraceio/web/flink
**Repo:** https://gitlab.com/rtraceio/web/flink

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Domain/hostname (used in shortened URLs)
- Port (see upstream for default)
- Database credentials (if required)

## Software-Layer Concerns

- **Config:** Environment variables
- **Data dir:** Persistent volume for database/links
- **Key env vars:** BASE_URL, DATABASE_URL (see upstream)

## Upgrade Procedure

Pull latest image and restart.

## Gotchas

- Base URL cannot easily be changed after links are created
- Keep analytics data private if running for personal use

## References

- [GitLab](https://gitlab.com/rtraceio/web/flink)
