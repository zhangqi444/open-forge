---
name: inboxen
description: Inboxen recipe for open-forge. Provides an infinite number of unique email inboxes without needing a real email address. Django + PostgreSQL + Celery. ARCHIVED — Inboxen.org shut down in April 2026. Source at https://codeberg.org/Inboxen/Inboxen.
---

# Inboxen

Provides an infinite number of unique, disposable email inboxes under your own domain — without needing to sign up with an email address. Self-host to give yourself (and optionally others) unlimited unique inboxes. Built with Django, PostgreSQL, Celery, and RabbitMQ. GPL-3.0. Source: https://codeberg.org/Inboxen/Inboxen.

> **⚠️ Project status:** The upstream service Inboxen.org shut down in April 2026. The source code repository remains available and accepts pull requests, but active development has slowed significantly. The code is deployable for personal use.

## Compatible install methods

| Method | When to use |
|---|---|
| Source / virtualenv | Standard; official install method |
| Docker Compose | Community; check upstream for any available compose files |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "PostgreSQL host, database, user, password?" | Strings | |
| email | "Mail domain?" | FQDN | Inboxes will be user@THISDOMAIN |
| email | "Postfix / MTA config?" | Config | MTA must deliver incoming mail to Inboxen |
| config | "SECRET_KEY?" | Random string | Django secret key |
| queue | "RabbitMQ or Celery broker URL?" | URL | Celery is used for async email processing |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python (Django) |
| Database | PostgreSQL |
| Task queue | Celery + RabbitMQ (or Redis) |
| MTA | Postfix or other MTA must deliver incoming mail to Inboxen |
| Node.js | Required for frontend asset build |
| Build | GNU Make used for setup |

## Install: Source

Source: https://codeberg.org/Inboxen/Inboxen

```bash
git clone https://codeberg.org/Inboxen/Inboxen.git
cd Inboxen

# Create virtualenv
python3 -m venv venv
source venv/bin/activate

# Install dependencies and run setup
make
```

Configure `inboxen/settings/local.py` (or environment variables):
- `DATABASE_URL` — PostgreSQL connection
- `SECRET_KEY` — Django secret key
- `CELERY_BROKER_URL` — RabbitMQ/Redis
- `INBOXEN_DOMAIN` — your mail domain

Run migrations:
```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic
```

Start services:
```bash
gunicorn inboxen.wsgi &
celery -A inboxen worker &
```

## Upgrade procedure

```bash
git pull
source venv/bin/activate
make
python manage.py migrate
python manage.py collectstatic
# Restart gunicorn and celery
```

## Gotchas

- MTA integration required: Inboxen does not receive email itself — you need Postfix (or equivalent) configured to pipe incoming mail to Inboxen. This is the most complex part of the setup.
- Project status: Inboxen.org shut down April 2026. The codebase is usable for personal self-hosting but is no longer actively maintained. Evaluate alternatives (SimpleLogin, AnonAddy) for long-term use.
- RabbitMQ/Celery required: Async email processing via Celery is not optional — mail delivery won't work without the task queue running.
- Node.js for asset build: The frontend uses Node.js for asset compilation. Install before running `make`.
- No sign-up email required: This is the feature — users register without providing an existing email address.

## Links

- Source: https://codeberg.org/Inboxen/Inboxen
- Documentation: https://inboxen.readthedocs.io/
- Alternatives: https://github.com/anonaddy/anonaddy (AnonAddy), https://github.com/simple-login/app (SimpleLogin)
