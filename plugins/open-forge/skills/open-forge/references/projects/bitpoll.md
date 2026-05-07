---
name: Bitpoll
description: Self-hosted scheduling and opinion poll tool. Create polls for dates, times, or general questions. Optional registration, anonymous voting, private polls. Django backend. MIT licensed.
website: https://github.com/fsinfuhh/Bitpoll
source: https://github.com/fsinfuhh/Bitpoll
license: MIT
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
| Any Linux VM / VPS | Docker | Recommended |
| Any Linux VM / VPS | Python/Django + PostgreSQL | Native install |

## Inputs to Collect

**Phase: Planning**
- Secret key (`SECRET_KEY`) — random string for Django session security
- Database backend (SQLite for simple, PostgreSQL for production)
- Domain/hostname
- Email server credentials (optional, for notifications)
- Whether to enable user registration

## Software-Layer Concerns

**Docker setup:**

```bash
git clone https://github.com/fsinfuhh/Bitpoll
cd Bitpoll

# Create config directories
mkdir -p run/{log,static,config}

# Get example settings and adapt
cp bitpoll/settings/local.py.example run/config/local.py
# Edit run/config/local.py with your settings

docker build -t bitpoll .
docker run -d \
  --name bitpoll \
  -p 8000:8000 \
  -v $(pwd)/run:/app/run \
  bitpoll
```

**Key `local.py` settings:**

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
    build: .
    ports:
      - "8000:8000"
    volumes:
      - ./run:/app/run
    depends_on:
      - db

volumes:
  db_data:
```

**Run database migrations:**

```bash
docker exec bitpoll python manage.py migrate
docker exec bitpoll python manage.py collectstatic --noinput
docker exec bitpoll python manage.py createsuperuser
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
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
    }
}
```

## Upgrade Procedure

1. `git pull`
2. `docker build -t bitpoll .`
3. `docker stop bitpoll && docker rm bitpoll`
4. Re-run `docker run` with the same volume mounts
5. `docker exec bitpoll python manage.py migrate`

## Gotchas

- **SECRET_KEY**: Must be a long random string (50+ chars) — never use the default placeholder; keeps sessions and CSRF tokens secure
- **Static files**: Run `collectstatic` after each update — Django doesn't serve static files in production; Nginx must serve them from the `run/static/` directory
- **Anonymous voting**: Controlled by `ALLOW_ANONYMOUS` setting — disable if you require all voters to identify themselves
- **Email optional**: Without email config, invitations and notifications don't work, but polls are still fully functional
- **URL is the poll access**: Bitpoll polls are shared by URL — treat private poll URLs as secrets

## Links

- Upstream README: https://github.com/fsinfuhh/Bitpoll/blob/master/README.md
- Live instance: https://bitpoll.de
- Releases: https://github.com/fsinfuhh/Bitpoll/releases
