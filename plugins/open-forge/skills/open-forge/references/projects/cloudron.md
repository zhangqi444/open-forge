# Cloudron

**What it is:** Complete self-hosting platform — install and manage 100+ web apps (Nextcloud, WordPress, Gitea, etc.) with automated backups, SSL, and email via a polished dashboard.
**Official URL:** https://cloudron.io
**GitHub:** N/A (closed source, but apps are open)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 22.04 / 24.04 | Bare metal / VPS | Official supported platforms |

## Inputs to Collect

### Deploy phase
- Fresh Ubuntu server (minimum 1GB RAM; 2GB+ recommended)
- Domain/hostname with DNS control (for per-app subdomains)
- Email: admin email address
- License (free tier: 2 apps; paid for more)

## Software-Layer Concerns

- **Config:** Cloudron web dashboard manages everything
- **Data dir:** /home/cloudron/ (managed internally)
- **Key env vars:** N/A — dashboard-driven

## Upgrade Procedure

Updates managed through Cloudron dashboard. Click "Update" for platform and per-app updates.

## Gotchas

- Free tier limited to 2 installed apps; subscription needed for more
- Requires root access on a fresh Ubuntu server — cannot share with other workloads
- DNS wildcard or per-subdomain records needed for each app
- Cloudron manages its own Docker; avoid manual Docker interference

## References

- [Official Site](https://cloudron.io)
- [Docs](https://docs.cloudron.io)
- [App Library](https://cloudron.io/store/index.html)
