---
name: django-crm
description: Django-CRM recipe for open-forge. Free open-source Python CRM with task management, email marketing, CRM analytics, IMAP/SMTP integration, and lead/deal pipeline. Built on Django Admin with no proprietary UI layer. Source: https://github.com/DjangoCRM/django-crm
---

# Django-CRM

Free, open-source customer relationship management application built with Python and Django. Manages leads, deals, contacts, tasks, projects, email campaigns, and analytics in one platform. Built entirely on the Django Admin interface — no proprietary UI framework. Supports IMAP/SMTP email integration, VoIP telephony hooks, and OAuth 2.0 for Google/Microsoft. Suitable for small businesses, teams, and freelancers needing a self-hosted CRM. Upstream: https://github.com/DjangoCRM/django-crm. Docs: https://django-crm-admin.readthedocs.io/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Python virtualenv | Linux / macOS / Windows | Recommended. Standard Django deployment. |
| Docker Compose | Linux / macOS | Community compose files available in repo. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Database type?" | PostgreSQL recommended for production; SQLite for dev |
| install | "Database credentials?" | Host, port, user, password, db name (if not SQLite) |
| email | "SMTP server + credentials?" | For outbound email from CRM |
| email | "IMAP server + credentials?" | For importing incoming email into CRM |
| auth | "Django SECRET_KEY?" | Generate with: `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"` |
| admin | "Admin username + email + password?" | For Django superuser |

## Software-layer concerns

### Clone and set up virtualenv

  git clone https://github.com/DjangoCRM/django-crm.git
  cd django-crm

  # Create and activate virtualenv
  python3 -m venv myvenv
  source myvenv/bin/activate          # Linux/macOS
  # myvenv\Scripts\activate           # Windows

  pip install -r requirements.txt

### Configure settings

  # Copy the example settings:
  cp crm/settings/base.py.example crm/settings/local.py  # if exists
  # Or edit crm/settings/prod_config.py for production

  # Key settings to configure in your settings file:
  SECRET_KEY = 'your-generated-secret-key'

  DATABASES = {
      'default': {
          'ENGINE': 'django.db.backends.postgresql',
          'NAME': 'djangocrm',
          'USER': 'crm_user',
          'PASSWORD': 'your_password',
          'HOST': '127.0.0.1',
          'PORT': '5432',
      }
  }

  # PostgreSQL: set timezone=UTC, default_transaction_isolation=read committed
  # Install psycopg: pip install psycopg[binary]

  ALLOWED_HOSTS = ['crm.example.com', '127.0.0.1']

  # Email outbound (SMTP)
  EMAIL_HOST = 'smtp.example.com'
  EMAIL_PORT = 587
  EMAIL_HOST_USER = 'noreply@example.com'
  EMAIL_HOST_PASSWORD = 'password'
  EMAIL_USE_TLS = True

### Initialize database and admin

  python manage.py migrate
  python manage.py setupdata     # load initial CRM data
  python manage.py createsuperuser

### Run tests

  python manage.py test tests/ --noinput

### Run development server

  python manage.py runserver 0.0.0.0:8000

### Production deployment (Apache + mod_wsgi or Nginx + Gunicorn)

  pip install gunicorn

  # Run gunicorn:
  gunicorn crm.wsgi:application --bind 0.0.0.0:8000 --workers 3

  # Collect static files:
  python manage.py collectstatic --noinput

  # Nginx proxies to gunicorn; serve /static/ and /media/ directly from disk.

  # Nginx snippet:
  location /static/ { alias /path/to/django-crm/staticfiles/; }
  location /media/  { alias /path/to/django-crm/media/; }
  location / { proxy_pass http://127.0.0.1:8000; }

### Key paths

  crm/settings/        # Django settings
  media/               # User-uploaded files
  staticfiles/         # Collected static assets (after collectstatic)
  templates/           # HTML templates (customizable)

## Upgrade procedure

  git pull origin main
  source myvenv/bin/activate
  pip install -r requirements.txt
  python manage.py migrate
  python manage.py collectstatic --noinput

## Gotchas

- **Django Admin UI**: the entire CRM interface is Django Admin. Customization means editing Django templates/views, not a separate front-end.
- **PostgreSQL recommended**: SQLite works for development/testing but is not suitable for multi-user production use. Use PostgreSQL with `default_transaction_isolation=read committed`.
- **IMAP integration**: to import incoming email into CRM records, configure IMAP account credentials in the CRM's admin UI under "Email accounts", not just settings.py.
- **setupdata command**: run `python manage.py setupdata` once after migration to populate initial lookup data (currencies, countries, etc.). Skipping this leaves the CRM with empty dropdowns.
- **Permissions model**: Django-CRM uses Django's built-in group/permission system. Create groups (Sales, Support, etc.) and assign users to control access to CRM modules.
- **OAuth 2.0**: to use Gmail/Outlook SMTP/IMAP via OAuth, configure credentials in Django admin under OAuth settings. Requires registering a Google/Microsoft app.

## References

- Upstream GitHub: https://github.com/DjangoCRM/django-crm
- Documentation: https://django-crm-admin.readthedocs.io/
- Installation guide: https://github.com/DjangoCRM/django-crm/blob/main/docs/installation_and_configuration_guide.md
- User guide: https://github.com/DjangoCRM/django-crm/blob/main/docs/django-crm_user_guide.md
