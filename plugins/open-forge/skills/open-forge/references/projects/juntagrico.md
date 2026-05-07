# juntagrico

**Management platform for community gardens and vegetable cooperatives** — Django-based web app for CSA (Community-Supported Agriculture) organizations. Manages subscriptions, deliveries, job scheduling, member accounts, and cooperative operations. Actively maintained with regular releases.

**Official site:** https://juntagrico.org
**Source:** https://github.com/juntagrico/juntagrico
**License:** LGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Python / Django + PostgreSQL | Recommended production setup |
| Any VPS / bare metal | Docker | Community Docker setups available |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Database type (PostgreSQL recommended)
- Organization name and subscription model

### Phase 2 — Deploy
- PostgreSQL credentials
- Django `SECRET_KEY`
- SMTP config for member notifications and subscription management
- Admin account credentials

---

## Software-Layer Concerns

- **Stack:** Django (Python), PostgreSQL (recommended), Celery for background tasks
- **Django app:** juntagrico is a Django application; it requires a Django project wrapper to deploy
- **Features:** Subscription management, delivery lists, job/task scheduling, member management, cooperative shares, email notifications
- **Extensible:** Plugin system for custom features
- **i18n:** Multilingual support (German-first; English and other languages available)

---

## Deployment

Follow the official installation guide:
https://juntagrico.readthedocs.io/en/latest/intro/installation.html

Key steps:
1. Create a Django project and install juntagrico: `pip install juntagrico`
2. Add `juntagrico` and dependencies to `INSTALLED_APPS`
3. Configure database, email, and static files in Django settings
4. Run migrations: `python manage.py migrate`
5. Create superuser: `python manage.py createsuperuser`
6. Collect static files and serve with Gunicorn + Nginx

---

## Upgrade Procedure

```bash
pip install --upgrade juntagrico
python manage.py migrate
python manage.py collectstatic
# Restart Gunicorn/application server
```

---

## Gotchas

- **Django project wrapper required** — juntagrico is a Django app, not a standalone server; you need a Django project to host it
- **German-first** — primary community and documentation is in German (Swiss German context); English translation exists
- **Email configuration critical** — the platform sends many automated emails (subscription confirmations, job reminders, invoices); SMTP must be correctly configured before going live
- **Celery recommended** for background tasks (scheduled emails, periodic jobs); without it, some automation won't run

---

## Links

- Upstream source: https://github.com/juntagrico/juntagrico
- Documentation: https://juntagrico.readthedocs.io
- Installation guide: https://juntagrico.readthedocs.io/en/latest/intro/installation.html
- Official site: https://juntagrico.org
