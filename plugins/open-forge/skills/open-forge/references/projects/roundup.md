# Roundup

**What it is:** Highly customizable open-source issue tracker and project management tool with web, email, REST, and XMLRPC interfaces.
**Official URL:** https://www.roundup-tracker.org
**GitHub:** https://github.com/roundup-tracker/roundup

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Community images available |
| Any Linux | Bare metal (Python) | pip install roundup |

## Inputs to Collect

### Deploy phase
- Tracker type/template (classic, minimal, etc.)
- Admin username and password
- Backend database (SQLite, PostgreSQL, MySQL)
- Domain/hostname and port (default: 8080)

## Software-Layer Concerns

- **Config:** tracker/config.ini inside the tracker directory
- **Data dir:** Tracker home directory (contains db, html templates, detectors)
- **Key env vars:** None required; configured via config.ini
- Backend database connection defined in config
- Each "tracker" is an independent instance with its own schema

## Upgrade Procedure

1. Back up tracker directory
2. pip install --upgrade roundup
3. Run roundup-admin migrate inside tracker home
4. Restart the server process

See https://www.roundup-tracker.org/docs/upgrading.html

## Gotchas

- Each tracker is a fully independent directory with its own schema
- Template customization requires editing HTML/Python files in tracker dir
- Email integration requires SMTP/IMAP configuration
- No official Docker image; use community images or bare metal

## References

- [Upstream Docs](https://www.roundup-tracker.org/docs/)
- [GitHub](https://github.com/roundup-tracker/roundup)
