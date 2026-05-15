---
name: pretalx
description: Recipe for pretalx — a web-based conference management platform covering Call for Papers, submission review, speaker management, and schedule publishing. Python + Docker.
---

# pretalx

Web-based conference management platform. Handles the full conference content lifecycle: configurable Call for Papers, submission review, speaker communication, talk scheduling, and post-event slide/recording management. Upstream: <https://github.com/pretalx/pretalx>. Docs: <https://docs.pretalx.org/>. Website: <https://pretalx.org>.

License: Apache-2.0. Platform: Python, Docker. Latest release: v2026.1.2. Actively developed.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (pretalx-docker) | Recommended for production |
| pip / Python native | For development or custom deployments |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Public URL for pretalx (e.g. `https://cfp.example.com`)?" | Set as `url` in `pretalx.cfg` |
| db | "PostgreSQL password?" | Used in `pretalx.cfg` and `docker-compose.yml` |
| mail | "SMTP host, port, user, password, from address?" | Required for speaker/attendee notifications |
| admin | "Admin email address?" | First superuser created via management command |

## Docker Compose (recommended)

```bash
git clone https://github.com/pretalx/pretalx-docker.git
cd pretalx-docker
```

Create `conf/pretalx.cfg` (based on the bundled example):
```ini
[filesystem]
data = /data
logs = /data/logs
media = /public/media
static = /public/static

[site]
; Set debug = False in production and configure a reverse proxy for /static/ and /media/
debug = False
url = https://cfp.example.com

[database]
backend = postgresql
name = pretalx
user = pretalx
password = strongpassword
host = pretalx-db
port = 5432

[mail]
from = cfp@example.com
host = smtp.example.com
port = 587
user = cfp@example.com
password = smtppassword
tls = True

[redis]
location = redis://pretalx-redis/0
sessions = true

[celery]
backend = redis://pretalx-redis/1
broker = redis://pretalx-redis/2
```

Edit `docker-compose.yml` to set the PostgreSQL password matching `pretalx.cfg`:
```yaml
services:
  pretalx:
    image: pretalx/standalone:v2026.1.2
    container_name: pretalx
    restart: unless-stopped
    depends_on:
      - redis
      - db
    ports:
      - "80:80"
    volumes:
      - ./conf/pretalx.cfg:/etc/pretalx/pretalx.cfg:ro
      - pretalx-data:/data
      - pretalx-public:/public

  db:
    image: docker.io/library/postgres:15-alpine
    container_name: pretalx-db
    restart: unless-stopped
    volumes:
      - pretalx-database:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: strongpassword
      POSTGRES_USER: pretalx
      POSTGRES_DB: pretalx

  redis:
    image: redis:latest
    container_name: pretalx-redis
    restart: unless-stopped
    volumes:
      - pretalx-redis:/data

volumes:
  pretalx-database:
  pretalx-data:
  pretalx-public:
  pretalx-redis:
```

```bash
docker compose up -d

# Run migrations and create admin account
docker compose exec pretalx python -m pretalx migrate
docker compose exec pretalx python -m pretalx createsuperuser
```

Web UI at `https://cfp.example.com`. Log in with the superuser you created.

## Behind a reverse proxy

When `debug = False`, pretalx does **not** serve `/static/` or `/media/` itself. Configure nginx or Caddy to serve those paths directly from the Docker volumes or from the host bind-mount paths.

Example nginx snippet:
```nginx
server {
    listen 443 ssl;
    server_name cfp.example.com;

    location /static/ { alias /path/to/pretalx-public/static/; }
    location /media/  { alias /path/to/pretalx-public/media/; }
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | `conf/pretalx.cfg` (mounted read-only into container) |
| Data dir | `/data` — database migrations, plugin data |
| Media dir | `/public/media` — uploaded files (speaker photos, etc.) |
| Static dir | `/public/static` — compiled CSS/JS (regenerated on upgrade) |
| Default port | `80` (internal); expose via reverse proxy for HTTPS |
| Background tasks | Celery workers (bundled in `standalone` image) |
| Queue/cache | Redis (required) |
| Database | PostgreSQL 15 |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose exec pretalx python -m pretalx migrate
```

Static files are regenerated automatically on container start.

Check the changelog before upgrading: <https://docs.pretalx.org/changelog/>

## Gotchas

- **Static/media files not served in production**: When `debug = False`, you must serve `/static/` and `/media/` via a reverse proxy or they will return 404. This is the most common production issue.
- **Redis is required**: pretalx uses Redis for session storage and Celery task queuing. The app will not start without it.
- **`createsuperuser` must be run once**: pretalx has no seeded admin account. Run `python -m pretalx createsuperuser` after first deploy.
- **`standalone` vs separate images**: The `pretalx/standalone` image includes both the web server and Celery worker. For high-load deployments, run them separately using the `pretalx/pretalx` image.
- **Plugin installation**: pretalx plugins are pip packages. To add plugins, create a custom Dockerfile that installs them, or use the `PRETALX_PLUGINS` env var (check image docs).
- **Organiser vs reviewer roles**: pretalx has a fine-grained permission model. Reviewers cannot see other reviewers' scores by default; configure review settings per event.

## Upstream links

- Source: <https://github.com/pretalx/pretalx>
- Docker deployment repo: <https://github.com/pretalx/pretalx-docker>
- Docs: <https://docs.pretalx.org/>
- Changelog: <https://docs.pretalx.org/changelog/>
