---
name: hyperkitty
description: HyperKitty recipe for open-forge. Web archiver and interface for GNU Mailman v3 mailing lists. Django. Python. GPL-3.0. Source: https://gitlab.com/mailman/hyperkitty
---

# HyperKitty

Web archive viewer for GNU Mailman v3 mailing lists. Provides a searchable, threaded web interface to browse mailing list archives. Typically deployed alongside Postorius (the Mailman 3 web UI) as part of the Mailman 3 suite. Django application. PostgreSQL or MySQL backend. GPL-3.0 licensed. Developed as part of the GNU Mailman project.

HyperKitty is almost always deployed as part of the full Mailman 3 suite (Mailman Core + HyperKitty + Postorius), not standalone. The recommended deployment is via the mailman3-full Debian/Ubuntu package or the official Docker Compose stack.

Upstream: https://gitlab.com/mailman/hyperkitty | Docs: https://hyperkitty.readthedocs.io | Demo: https://lists.mailman3.org

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian/Ubuntu | mailman3-full package | Recommended; installs everything |
| Any | Docker Compose (mailman3) | Official mailman3 compose stack |
| Any | pip + Django | Manual install; see docs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | DATABASE_URL | PostgreSQL or MySQL connection string |
| config | SECRET_KEY | Django secret key (strong random string) |
| config | MAILMAN_REST_API_URL | URL to Mailman Core REST API (default: http://mailman-core:8001) |
| config | MAILMAN_REST_API_USER | Mailman Core API admin user |
| config | MAILMAN_REST_API_PASS | Mailman Core API admin password |
| config | ALLOWED_HOSTS | Django ALLOWED_HOSTS (your domain) |
| config (optional) | EMAIL_HOST | SMTP server for outgoing mail |
| config (optional) | SERVE_FROM_DOMAIN | Primary domain for the Mailman suite |

## Software-layer concerns

- Part of the Mailman 3 suite: HyperKitty works together with Mailman Core (the MTA-facing daemon) and Postorius (the list management UI). All three are needed for a full deployment.
- Django app: HyperKitty is a Django application; it needs a WSGI server (gunicorn/uwsgi) + static file serving (Nginx).
- Haystack + Whoosh: full-text search is powered by Django Haystack with a Whoosh backend by default; ElasticSearch can be used for larger installations.
- Cron/celery: periodic tasks (index rebuilds, digests) run via cron or Celery.

## Install -- Debian/Ubuntu (mailman3-full, recommended)

```bash
sudo apt install mailman3-full
# Configuration at /etc/mailman3/
# Edit /etc/mailman3/mailman-hyperkitty.cfg and /etc/mailman3/mailman-web.py
sudo systemctl enable --now mailman3 mailman3-web
```

## Install -- Docker Compose (mailman3)

Use the official mailman3 Docker Compose stack from https://github.com/maxking/docker-mailman:

```bash
git clone https://github.com/maxking/docker-mailman.git
cd docker-mailman
# Edit docker-compose.yaml with your domain, secrets, and DB settings
docker compose up -d
```

This stack deploys Mailman Core, HyperKitty, Postorius, PostgreSQL, and a task queue together.

## Upgrade procedure

Via Debian package:

```bash
sudo apt update && sudo apt upgrade mailman3-full
sudo python3 /usr/lib/mailman3/bin/mailman-web migrate
sudo systemctl restart mailman3-web
```

Via Docker:

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Not a standalone app: HyperKitty without Mailman Core and Postorius is like a car without an engine. Deploy the full suite.
- Mailing list email must be routed to Mailman Core: your MTA (Postfix/Exim) must be configured to pipe incoming list mail to Mailman. The Docker Compose stack handles this for Postfix automatically.
- Static files: in production, Django static files must be collected (manage.py collectstatic) and served by Nginx; the WSGI process should not serve them.
- Search index rebuild: after initial setup or a large import, run the search index rebuild: manage.py update_index.

## Links

- Source: https://gitlab.com/mailman/hyperkitty
- Documentation: https://hyperkitty.readthedocs.io
- Full Mailman 3 docs: http://docs.mailman3.org
- Docker Mailman: https://github.com/maxking/docker-mailman
- Demo: https://lists.mailman3.org
