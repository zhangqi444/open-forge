# RSS (danb)

**What it is:** Minimal self-hosted web RSS reader with no accounts or databases required.
**Official URL:** https://codeberg.org/danb/rss
**GitHub:** N/A (Codeberg: https://codeberg.org/danb/rss)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Simple single-container setup |
| Any Linux | Bare metal | Static PHP/Python app |

## Inputs to Collect

### Deploy phase
- Port to expose (see upstream for default)
- Path to feeds config file

## Software-Layer Concerns

- **Config:** Feed list defined in a config/OPML file
- **Data dir:** Minimal; no persistent database needed
- **Key env vars:** See upstream README

## Upgrade Procedure

Pull latest image and restart. No database migrations needed.

## Gotchas

- No user accounts — single-user design
- No built-in HTTPS; use a reverse proxy

## References

- [Upstream Repo](https://codeberg.org/danb/rss)
