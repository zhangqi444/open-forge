# django-wiki

A pluggable, full-featured wiki engine for Django. django-wiki is designed to be embedded into existing Django applications — providing versioned wiki pages, nested article trees, plugin support, Markdown editing, search, and per-article permission controls.

**Official site:** https://django-wiki.readthedocs.io/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (custom image) | No official image; build from Dockerfile |
| Any Linux host | pip + Gunicorn | Embed into a Django project |
| PaaS (Heroku, Fly.io) | Python buildpack | Standard Django deployment |
| Shared hosting | wsgi | Any Python 3.10+ WSGI host |

---

## Inputs to Collect

### Phase 1 — Planning
- Whether to integrate into an existing Django project or deploy standalone
- Database: PostgreSQL (recommended), MySQL, or SQLite
- Media storage for attachments: local or S3
- Auth: Django built-in, LDAP, or OAuth (via `django-allauth`)

### Phase 2 — Deployment
- `DJANGO_SECRET_KEY` — random secret key
- Database connection string (`DATABASE_URL` or settings)
- `ALLOWED_HOSTS` — hostname(s) for the Django app
- `MEDIA_ROOT` — file upload directory

---

## Software-Layer Concerns

### pip Install

```bash
pip install wiki

# Or with optional dependencies
pip install "wiki[pygments]"    # syntax highlighting
```

### Django Settings Integration

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'django.contrib.humanize',
    'django_nyt',       # notification app (required)
    'mptt',             # tree structure (required)
    'sekizai',          # template context (required)
    'sorl.thumbnail',   # image thumbnails (required)
    'wiki',
    'wiki.plugins.attachments',
    'wiki.plugins.notifications',
    'wiki.plugins.images',
    'wiki.plugins.macros',
    # ...
]
```

### URL Configuration

```python
# urls.py
from django.urls import include, path

urlpatterns = [
    path('wiki/', include('wiki.urls')),
    # ...
]
```

### Docker Compose (Standalone)

```yaml
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: wiki
      POSTGRES_USER: wiki
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data

  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    environment:
      - DATABASE_URL=postgres://wiki:secret@db:5432/wiki
      - DJANGO_SECRET_KEY=change-me
      - ALLOWED_HOSTS=wiki.example.com
    ports:
      - "8000:8000"
    volumes:
      - media:/app/media
    depends_on:
      - db

volumes:
  db-data:
  media:
```

> **Note:** django-wiki is a Django app, not a standalone server. You must create a Django project, install `wiki`, add it to `INSTALLED_APPS`, wire up URLs, and run `manage.py migrate`.

### Django Management Commands

```bash
# Create tables
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Run development server
python manage.py runserver
```

### Key Settings
| Setting | Purpose |
|---------|---------|
| `WIKI_ACCOUNT_HANDLING` | Control user signup (True = wiki handles it) |
| `WIKI_ACCOUNT_SIGNUP_ALLOWED` | Allow public registration |
| `WIKI_CAN_READ` | Default read permission function |
| `WIKI_CAN_WRITE` | Default write permission function |

---

## Upgrade Procedure

```bash
pip install --upgrade wiki
python manage.py migrate
```

Refer to [Release Notes](https://django-wiki.readthedocs.io/en/latest/release_notes.html) for breaking changes between versions.

---

## Gotchas

- **Not a standalone app** — django-wiki is a Django app library. You need a Django project to host it; it cannot run on its own.
- **`django_nyt`, `mptt`, `sekizai`, `sorl-thumbnail` are all required** — missing any will cause import errors.
- **Media files need persistent storage** — article attachments and images are stored in `MEDIA_ROOT`; back it up.
- **Permissions are per-article** — access control can be configured globally via settings or overridden per-article.
- **Demo available:** https://demo.django-wiki.org — login: `admin` / `admin`

---

## References
- GitHub: https://github.com/django-wiki/django-wiki
- Docs: https://django-wiki.readthedocs.io/
- PyPI: https://pypi.org/project/wiki/
- Demo: https://demo.django-wiki.org
