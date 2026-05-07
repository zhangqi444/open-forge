---
name: relate
description: RELATE recipe for open-forge. Web-based courseware platform for universities. Flexible grading rules, code execution sandbox, git-versioned content, multi-course support, class calendar, and grade book. Django/Python. Source: https://github.com/inducer/relate
---

# RELATE

Web-based courseware package for universities and academic courses. RELATE = "an Environment for Learning And TEaching." Features: text/YAML/Markdown-based course content with git versioning, flexible rules for participation/access/grading, sandboxed code question execution (via Docker), automatic grading, multi-course support, class calendar, grade book, live quizzes, SAML2/social auth, and in-class instant messaging via XMPP. Built with Django/Python.

Upstream: <https://github.com/inducer/relate> | Docs: <https://documen.tician.de/relate/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | Python 3 + uv + RabbitMQ + PostgreSQL | Production-recommended stack |
| Linux (dev) | Python 3 + uv + SQLite + RabbitMQ | Development/testing |
| Any | Docker (for code execution sandbox only) | Docker is a dependency for sandboxed code questions, not for RELATE itself |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Python 3 and Node.js installed | Required for install |
| preflight | uv (Python package manager) installed | Install: curl -LsSf https://astral.sh/uv/install.sh | sh |
| config | Database backend | PostgreSQL for production; SQLite for dev |
| config | PostgreSQL credentials (production) | DB name, user, password |
| config | Celery broker URL | RabbitMQ (amqp://) or Redis |
| config | GIT_ROOT path | Where RELATE stores course git repos |
| config | SECRET_KEY | Django secret key |
| config | Superuser username | Created on first run |

## Software-layer concerns

### Architecture

- Django web app — serves UI and API
- Celery worker — background task queue (grading, long-running operations)
- RabbitMQ (default) or Redis — Celery message broker
- PostgreSQL (production) or SQLite (development) — database
- Docker (optional) — sandboxed execution of code questions (`inducer/relate-runpy-amd64` image)

### Config file

Copy `local_settings_example.py` to `local_settings.py` and configure:

```python
# local_settings.py (key settings)
SECRET_KEY = "your-secret-key-here"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "relate",
        "USER": "relate",
        "PASSWORD": "yourpassword",
        "HOST": "localhost",
        "PORT": "5432",
    }
}

# Path where RELATE stores course git repositories
GIT_ROOT = "/var/relate/repos"

# Celery broker
CELERY_BROKER_URL = "amqp://"  # RabbitMQ default

# Email backend for notifications
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = "smtp.example.com"
```

### Data dirs

- `GIT_ROOT` — course git repositories (must be owned by the relate user)
- Static files — collected to `STATIC_ROOT` via `./collectstatic.sh`
- Media/uploads — configured in `local_settings.py`

## Install — Development

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Clone
git clone https://github.com/inducer/relate.git
cd relate

# Install Python dependencies
uv sync --all-extras --all-groups --no-group mypy --frozen

# Configure
cp local_settings_example.py local_settings.py
$EDITOR local_settings.py   # set SECRET_KEY, DB, etc.

# Initialize DB
uv run python manage.py migrate
uv run python manage.py createsuperuser --username=$(whoami)

# Install and build frontend assets
npm install
npm run build

# Start dev server
uv run python manage.py runserver

# In a separate terminal — start Celery worker
sudo apt install rabbitmq-server  # or configure alternate broker
celery worker -A relate
```

Open http://localhost:8000, sign in, select "Set up new course."

## Install — Production

Additional steps for production (Ubuntu/Debian):

```bash
# Install PostgreSQL and system deps
sudo apt install postgresql libpq-dev nginx rabbitmq-server

# Create DB and user
sudo -u postgres psql <<SQL
CREATE DATABASE relate;
CREATE USER relate WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE relate TO relate;
SQL

# Add PostgreSQL extra
uv sync --extra postgres

# Collect static files
./collectstatic.sh   # do NOT use manage.py collectstatic directly

# Systemd service — create /etc/systemd/system/relate.service
# (see upstream docs for full service file)
sudo systemctl enable --now relate
sudo systemctl enable --now relate-celery
```

For the code execution sandbox (code questions), install Docker and add the relate user to the `docker` group, then pull the sandbox image:
```bash
docker pull inducer/relate-runpy-amd64
```

See full deployment guide at https://documen.tician.de/relate/misc.html#deployment

## Upgrade procedure

```bash
git pull
uv sync --frozen
uv run python manage.py migrate
npm install
npm run build
./collectstatic.sh
sudo systemctl restart relate relate-celery
```

## Gotchas

- Celery + RabbitMQ are required for long-running tasks — without the Celery worker, grading and other async operations will appear stuck in "PENDING" forever.
- `./collectstatic.sh` not `manage.py collectstatic` — the wrapper script resolves MathJax source map URLs that would otherwise cause `manage.py collectstatic` to fail.
- Git repo open file limit — after many course updates, RELATE may hit `Too many open files` from dulwich (the git library). Run `git repack -a -d` periodically on course repos (every few hundred update cycles). See upstream `repack-repositories.sh`.
- Docker for code questions — Docker is needed only if you use code questions with sandboxed execution. Without Docker, code questions can still be created but execution will fail.
- cgroup memory accounting (if using Docker code execution) — add `cgroup_enable=memory swapaccount=1` to the kernel command line and set `--ip-forward=false` in Docker config.
- GIT_ROOT directory must be owned by the user running RELATE — check permissions if course import fails.

## Links

- Upstream: https://github.com/inducer/relate
- Documentation: https://documen.tician.de/relate/
- Installation guide: https://documen.tician.de/relate/misc.html#installation
- Sample course content: https://github.com/inducer/relate-sample
