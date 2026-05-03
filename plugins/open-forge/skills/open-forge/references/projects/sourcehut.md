# SourceHut

**What it is:** Suite of open-source software development tools — git hosting, CI/CD, mailing lists, bug tracking, and more. Minimalist and fast.
**Official URL:** https://sourcehut.org
**GitHub:** N/A (sr.ht: https://sr.ht/~sircmpwn/sourcehut)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux server | Bare metal (Alpine/Arch/Debian) | Recommended by upstream |
| Linux server | Docker (unofficial) | Community only |

## Inputs to Collect

### Deploy phase
- Domain/hostname (each service gets a subdomain: git.*, builds.*, lists.*, etc.)
- PostgreSQL and Redis instances
- SMTP settings
- S3-compatible storage (for builds artifacts)
- SSH server configuration

## Software-Layer Concerns

- **Config:** /etc/sr.ht/*.ini per service
- **Data dir:** PostgreSQL; object storage for artifacts
- **Key env vars:** Configured in INI files, not env vars

## Upgrade Procedure

Follow upstream guides per service. Update packages, run database migrations.
See: https://man.sr.ht/installation.md

## Gotchas

- Complex multi-service setup; not beginner-friendly
- No official Docker support from upstream
- Requires multiple subdomains (git.domain, builds.domain, lists.domain, etc.)
- Significant initial configuration effort

## References

- [Installation Guide](https://man.sr.ht/installation.md)
- [Sourcehut](https://sr.ht/~sircmpwn/sourcehut)
