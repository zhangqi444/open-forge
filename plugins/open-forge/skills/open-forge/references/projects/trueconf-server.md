# TrueConf Server

**What it is:** Self-hosted enterprise video conferencing and team messaging server supporting up to thousands of users.
**Official URL:** https://trueconf.com/products/server/
**GitHub:** N/A (commercial/proprietary)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Ubuntu/CentOS) | Bare metal / VM | Official .deb/.rpm packages |
| Windows Server | Native installer | Also supported |

## Inputs to Collect

### Deploy phase
- License key (free tier: up to 1000 users, 25 concurrent)
- Domain/hostname
- SMTP settings for notifications
- Admin account credentials

## Software-Layer Concerns

- **Config:** Web admin interface at https://host/admin
- **Data dir:** Managed by installer; see TrueConf docs for paths
- **Key env vars:** N/A — configured via web UI

## Upgrade Procedure

Download new package from trueconf.com, run installer over existing install.

## Gotchas

- Free tier has user/concurrent call limits; enterprise license required for more
- Proprietary protocol; clients must use TrueConf apps
- Windows and Linux clients/apps available

## References

- [Official Site](https://trueconf.com/products/server/)
- [Docs](https://trueconf.com/docs/)
