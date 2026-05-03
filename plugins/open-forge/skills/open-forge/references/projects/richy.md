# Richy

**What it is:** Self-hosted application for managing and tracking investment portfolios — stocks, ETFs, crypto, and more.
**Official URL:** https://gitlab.com/imn1/richy
**Repo:** https://gitlab.com/imn1/richy

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

## Inputs to Collect

### Deploy phase
- Port to expose
- Database credentials
- API keys for price data (see upstream for providers)

## Software-Layer Concerns

- **Config:** Environment variables (see upstream)
- **Data dir:** Persistent volume for database
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. Back up database first.

## Gotchas

- Requires external price feed API keys for live quotes
- Portfolio data is private — ensure reverse proxy with auth if exposed

## References

- [GitLab](https://gitlab.com/imn1/richy)
