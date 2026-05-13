---
name: Bitpoll
description: Self-hosted scheduling and opinion poll tool. Create polls for dates, times, or general questions. Optional registration, anonymous voting, private polls. Django backend. GPL-3.0 licensed.
website: https://github.com/fsinfuhh/Bitpoll
source: https://github.com/fsinfuhh/Bitpoll
license: GPL-3.0
stars: 303
tags:
  - scheduling
  - polls
  - doodle-alternative
  - django
platforms:
  - Python
  - Docker
---

# Bitpoll

Bitpoll is a self-hosted polling and scheduling tool — a Doodle/Dudle alternative. Create polls for dates, times, or general questions. Supports anonymous or named voting, optional registration requirement, private polls accessible only by invite, and full-day or hourly event scheduling. A live instance runs at https://bitpoll.de.

Source: https://github.com/fsinfuhh/Bitpoll
Live demo: https://bitpoll.de

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended — use upstream GHCR image |
| Any Linux VM / VPS | Python/Django + PostgreSQL | Native install |

## Inputs to Collect

**Phase: Planning**
- Secret key (`SECRET_KEY`) — random string for Django session security
- Database backend (SQLite for simple, PostgreSQL for production)
- Domain/hostname
- Email server credentials (optional, for notifications)
- Whether to enable user registration

## Software-Layer Concerns

**Docker setup (upstream GHCR image — recommended):**

```bash
# Create config directories
mkdir -p run/{log,static,config}

# Get example settings and adapt
wget https://raw.githubusercontent.com/fsinfuhh/Bitpoll/master/bitpoll/settings_local.sample.py \
  -O run/config/settings.py
# Edit run/config/settings.py with your settings (SECRET_KEY, ALLOWED_HOSTS, DB, etc.)

# Run the pre-built image (port 3009 is the HTTP port; 3008 is uwsgi)
docker run -a stdout -a stderr --rm \
  --name bitpoll \
  -p 3009:3009 \
  -p 3008:3008 \
  --volume ./run/static:/opt/static \
  --volume ./run/config:/opt/config \
  ghcr.io/fsinfuhh/bitpoll
```

The web UI is available on **port 3009**. Port 3008 exposes uwsgi for external web servers serving static assets from `run/static` at `/static/`.

**Key `settings.py` settings:**

```python
SECRET_KEY = 'CHANGE_ME_RANDOM_STRING_50_CHARS'

ALLOWED_HOSTS = ['bitpoll.example.com']

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'bitpoll',
        'USER': 'bitpoll',
        'PASSWORD': 'CHANGE_ME',
        'HOST': 'db',
    }
}

# Email (optional)
EMAIL_HOST = 'smtp.example.com'
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'noreply@example.com'
EMAIL_HOST_PASSWORD = 'CHANGE_ME'

# Allow anonymous voting (True/False)
ALLOW_ANONYMOUS = True
```

**Docker Compose (with PostgreSQL):**

```yaml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: bitpoll
      POSTGRES_USER: bitpoll
      POSTGRES_PASSWORD: CHANGE_ME
    volumes:
      - db_data:/var/lib/postgresql/data

  bitpoll:
    image: ghcr.io/fsinfuhh/bitpoll
    ports:
      - "3009:3009"
      - "3008:3008"
    volumes:
      - ./run/static:/opt/static
      - ./run/config:/opt/config
    depends_on:
      - db

volumes:
  db_data:
```

**Nginx reverse proxy:**

```nginx
server {
    listen 443 ssl;
    server_name polls.example.com;

    location /static/ {
        alias /path/to/run/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:3009;
        proxy_set_header Host $host;
    }
}
```

## Upgrade Procedure

```bash
docker pull ghcr.io/fsinfuhh/bitpoll
docker stop bitpoll && docker rm bitpoll
# Re-run docker run with the same volume mounts
```

## Gotchas

- **Pre-built GHCR image**: Upstream publishes `ghcr.io/fsinfuhh/bitpoll` built from master — no local `docker build` required.
- **Ports**: The container exposes port **3009** (HTTP web UI) and **3008** (uwsgi for external server). The previous port 8000 no longer applies.
- **Settings file path**: The config file is mounted at `/opt/config/settings.py`. Use `settings_local.sample.py` from the repo as a template.
- **SECRET_KEY**: Must be a long random string (50+ chars) — never use the default placeholder; keeps sessions and CSRF tokens secure.
- **Static files**: Served from the mounted `run/static` volume — Nginx should serve `/static/` from there.
- **Anonymous voting**: Controlled by `ALLOW_ANONYMOUS` setting — disable if you require all voters to identify themselves.
- **Email optional**: Without email config, invitations and notifications don't work, but polls are still fully functional.
- **URL is the poll access**: Bitpoll polls are shared by URL — treat private poll URLs as secrets.
- **License**: GPL-3.0 (not MIT as previously noted).

## Links

- Upstream README: https://github.com/fsinfuhh/Bitpoll/blob/master/README.md
- Live instance: https://bitpoll.de
- Releases: https://github.com/fsinfuhh/Bitpoll/releases
- GHCR image: https://github.com/fsinfuhh/Bitpoll/pkgs/container/bitpoll
