---
name: dpaste
description: dpaste recipe for open-forge. Simple Python/Django pastebin with syntax highlighting, multiple text/code modes, expiry, and a short URL system. Source: https://github.com/DarrenOfficial/dpaste
---

# dpaste

Simple, open-source pastebin written in Python using the Django framework. Features syntax highlighting for many languages, plain text mode, configurable expiry, and short memorable URLs. Can run standalone or be embedded into an existing Django project. Official public instance at dpaste.org. Upstream: https://github.com/DarrenOfficial/dpaste. Docs: https://docs.dpaste.org.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (official image) | Docker | Recommended for standalone deployment. darrenofficial/dpaste. |
| pip install | Python 3.9+ | Install as a Django app — standalone or embed in existing project. |
| Source | Python 3.9+ | Clone and run with uWSGI/gunicorn. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Port?" | Default: 8000 |
| database | "Database?" | Default: SQLite. Set DATABASE_URL for PostgreSQL/MySQL in production. |
| storage | "Static files path?" | Set STATIC_ROOT for collectstatic (production only) |

## Software-layer concerns

### Docker run (simplest)

  docker run -d \
    --name dpaste \
    -p 8000:8000 \
    darrenofficial/dpaste

  # Access at http://localhost:8000

### Docker with environment config

  docker run -d \
    --name dpaste \
    -p 8000:8000 \
    -e DATABASE_URL=sqlite:////data/dpaste.sqlite \
    -e STATIC_ROOT=/collectstatic \
    -v dpaste-data:/data \
    darrenofficial/dpaste

### Docker Compose (with PostgreSQL)

  services:
    dpaste:
      image: darrenofficial/dpaste
      ports:
        - "8000:8000"
      environment:
        - DATABASE_URL=postgres://dpaste:changeme@db:5432/dpaste
        - STATIC_ROOT=/collectstatic
      depends_on:
        - db
    db:
      image: postgres:15
      environment:
        - POSTGRES_DB=dpaste
        - POSTGRES_USER=dpaste
        - POSTGRES_PASSWORD=changeme
      volumes:
        - db-data:/var/lib/postgresql/data
  volumes:
    db-data:

### pip install (standalone Django)

  pip install dpaste
  # Create a Django project with dpaste as an installed app
  # See: https://docs.dpaste.org/installation/

### Key environment variables

  DATABASE_URL=sqlite:////path/to/dpaste.sqlite   # or postgres://...
  STATIC_ROOT=/path/to/staticfiles
  DPASTE_SLUG_LENGTH=6                            # short URL slug length (default: 6)
  DPASTE_EXPIRE_DEFAULT=3600                      # default expiry in seconds (1 hour)
  DPASTE_MAX_CONTENT_LENGTH=250000               # max paste size in bytes
  DPASTE_LEXER_DEFAULT=text                       # default syntax mode

### nginx reverse proxy

  location / {
    proxy_pass http://127.0.0.1:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
  location /static/ {
    alias /path/to/staticfiles/;
  }

## Upgrade procedure

  # Docker:
  docker pull darrenofficial/dpaste
  docker stop dpaste && docker rm dpaste
  # Re-run with same volume mounts

  # pip:
  pip install --upgrade dpaste
  python manage.py migrate

## Gotchas

- **Python 3.9+ required**: older Python versions are not supported.
- **Static files in production**: must run `python manage.py collectstatic` and serve the STATIC_ROOT directory. The Docker image handles this internally.
- **SQLite for dev, PostgreSQL for production**: SQLite works fine for low traffic but PostgreSQL is recommended for production.
- **ALLOWED_HOSTS**: in production set the DJANGO_ALLOWED_HOSTS environment variable to your domain to avoid Django's security check errors.
- **No auth by default**: anyone can create pastes. If public access is undesirable, add nginx basic auth or IP restriction in front.
- **Expiry**: pastes can be configured to expire. The cleanup of expired pastes requires a cron job or the Docker image's built-in scheduler.

## References

- Upstream GitHub: https://github.com/DarrenOfficial/dpaste
- Documentation: https://docs.dpaste.org
- Docker Hub: https://hub.docker.com/r/darrenofficial/dpaste
- Live instance: https://dpaste.org
