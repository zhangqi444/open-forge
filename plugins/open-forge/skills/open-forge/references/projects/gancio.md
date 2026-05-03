# Gancio

**What it is:** Shared event agenda for local communities — federated event calendar supporting ActivityPub, with RSS/iCal export and embeddable widgets.
**Official URL:** https://gancio.org
**Repo:** https://framagit.org/les/gancio

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Bare metal (Node.js) | npm install -g gancio |

## Inputs to Collect

### Deploy phase
- Domain/hostname (permanent — used in ActivityPub IDs)
- Port (default: 13120)
- Admin email and password
- SMTP settings for notifications
- PostgreSQL credentials (or SQLite for small installs)

## Software-Layer Concerns

- **Config:** config.json or environment variables
- **Data dir:** uploads/ for images; database
- **Key env vars:** DB_TYPE, DB_HOST, DB_NAME, DB_USER, DB_PASS, SMTP_*

## Upgrade Procedure

Pull latest image and restart. For bare metal: npm update -g gancio && gancio migrate

## Gotchas

- ActivityPub federation — your instance connects to the Fediverse
- Domain is permanent; changing it breaks federation
- Supports embedding event lists on other websites via iframe

## References

- [Official Site](https://gancio.org)
- [Docs](https://gancio.org/install/source)
