# Postorius

**Web UI for GNU Mailman 3 mailing list management** — Django app that provides a browser-based interface to create and manage mailing lists, subscriptions, and settings on a GNU Mailman 3 server. Part of the official Mailman Suite.

**Official site:** https://docs.mailman3.org/projects/postorius/en/latest/
**Source:** https://gitlab.com/mailman/postorius
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Mailman Suite (Docker Compose) | Recommended; deploys Postorius + HyperKitty + Mailman core together |
| Any VPS / bare metal | Python / pip | Manual install alongside existing Mailman 3 setup |

---

## Inputs to Collect

### Phase 1 — Planning
- Whether deploying full Mailman Suite (recommended) or adding Postorius to existing Mailman 3 install
- Domain / hostname for the web UI
- Email domain for mailing lists

### Phase 2 — Deploy
- GNU Mailman 3 REST API credentials (Postorius connects via Mailman's REST API)
- Django `SECRET_KEY`
- Database credentials (PostgreSQL or SQLite for small installs)
- SMTP config for Django email

---

## Software-Layer Concerns

- **Requires GNU Mailman 3.3.10+** — Postorius is the web UI only; Mailman core handles the actual list processing
- **Django app** — Python 3.9+, Django 4.2+ minimum
- **Connects via REST API** — Postorius talks to Mailman core over its REST API; configure `MAILMAN_REST_API_URL`, `MAILMAN_REST_API_USER`, `MAILMAN_REST_API_PASS`
- **Usually deployed as part of Mailman Suite** — the suite bundles Postorius (web UI) + HyperKitty (list archives) + Mailman core in one Docker Compose stack

---

## Deployment

**Recommended: Deploy full Mailman Suite**

Follow the official Mailman Suite installation guide:
https://docs.mailman3.org/

The suite Docker Compose setup includes Postorius, HyperKitty (archiver), Mailman core, PostgreSQL, and a reverse proxy config.

**Manual pip install (existing Mailman 3 setup):**
```bash
pip install postorius
# Add 'postorius' to INSTALLED_APPS in Django settings
# Configure MAILMAN_REST_API_URL, credentials, and URLs
```

---

## Upgrade Procedure

```bash
# Via Mailman Suite Docker
docker compose pull
docker compose up -d

# Via pip
pip install --upgrade postorius
python manage.py migrate
python manage.py collectstatic
```

---

## Gotchas

- **Postorius alone is not a complete install** — you must also run GNU Mailman 3 core; Postorius is just the web UI
- **Mailman Suite is the easiest path** — deploying all components via the official Docker Compose setup avoids manual wiring
- **REST API must be reachable** — if Postorius can't reach Mailman core's REST API, the UI will fail entirely
- **HyperKitty for archives** — Postorius handles list management; HyperKitty is the separate component for public list archives
- **Version pinning** — Postorius releases must match compatible Mailman 3 core versions; check release notes

---

## Links

- Upstream README: https://gitlab.com/mailman/postorius/-/blob/master/README.rst
- Documentation: https://postorius.readthedocs.io
- Mailman Suite install guide: https://docs.mailman3.org/
- Read the Docs: https://docs.mailman3.org/projects/postorius/en/latest/
