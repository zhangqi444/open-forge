---
name: shynet
description: Shynet recipe for open-forge. Modern, privacy-friendly, cookie-free web analytics that you self-host. Built on Django + Postgres. Upstream: https://github.com/milesmcc/shynet
---

# Shynet

Modern, privacy-friendly, cookie-free web analytics. Tracks page views, sessions, bounce rates, referrers, OS/browser/device data, and geographic location — without cookies or PII collection. Upstream: <https://github.com/milesmcc/shynet>. License: Apache 2.0.

Shynet is a Django application backed by PostgreSQL (or SQLite for single-instance hobby use). It supports multi-user / multi-site operation on a single deployment, a DNT-respecting tracking script under 1 KB, and optional Redis + Celery for high-traffic parallelism.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (with Postgres) | Recommended for production — `docker-compose.yml` ships in-repo. |
| Any Linux host | Docker single container + SQLite | Simplest setup; acceptable for low-traffic personal sites. |
| Any Linux host | Docker single container + external Postgres | Production-grade without the full Compose stack. |
| Kubernetes | Deployment + Service | Upstream documents a Kubernetes directory in-repo (`kubernetes/`). |
| Heroku | Heroku Deploy button | Quick demo only — free Postgres tier fills up quickly. |
| Render | Render Deploy button | Community-supported quick deploy. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Use SQLite (simple, single-instance) or PostgreSQL (recommended for production)?" | `AskUserQuestion`: `SQLite` / `PostgreSQL` | Drives DB config block in `.env`. |
| preflight (Postgres) | "Postgres database name, user, password, host, port?" | Free-text | Shynet uses `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`. |
| preflight | "What domain will Shynet be served from?" | Free-text | Required for `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS`; leaving as `localhost` breaks public deploys. |
| preflight | "Port to expose Shynet on?" | Integer | Default Compose example maps `8080:80`. |
| auth | "Admin email address?" | Email | Used with `registeradmin` management command to create the first superuser. |
| auth | "Whitelabel name for this Shynet instance?" | Free-text | E.g. `My Analytics`. Set via `whitelabel` management command. |
| smtp (optional) | "SMTP host, user, password, port for outbound email?" | Free-text | Optional — Shynet uses email for password reset and account verification. |
| smtp (optional) | "Server email from address?" | Free-text | E.g. `Shynet <noreply@example.com>`. Maps to `SERVER_EMAIL`. |

## Software-layer concerns

### Environment variables (key ones from `TEMPLATE.env`)

| Variable | Purpose | Example |
|---|---|---|
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` / `DB_HOST` / `DB_PORT` | PostgreSQL connection | `shynet_db` / `shynet_db_user` / `...` / `db` / `5432` |
| `SQLITE=True` | Use SQLite instead of Postgres | Also set `DB_NAME=/var/local/shynet/db/db.sqlite3`; add volume |
| `DJANGO_SECRET_KEY` | Django secret — generate with `python3 -c "import secrets; print(secrets.token_urlsafe())"` | Long random string |
| `ALLOWED_HOSTS` | Comma-separated list of valid hostnames | `example.com` |
| `CSRF_TRUSTED_ORIGINS` | Comma-separated with scheme | `https://example.com` |
| `ACCOUNT_SIGNUPS_ENABLED` | Allow public registration | `False` (recommended) |
| `SCRIPT_USE_HTTPS` | Whether tracking script uses HTTPS | `True` |
| `SCRIPT_HEARTBEAT_FREQUENCY` | How often the tracking script phones home (ms) | `5000` |
| `SESSION_MEMORY_TIMEOUT` | Seconds before a new session is started | `1800` |
| `TIME_ZONE` | Admin panel timezone (IANA tz name) | `America/New_York` |
| `EMAIL_HOST` / `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD` / `EMAIL_PORT` / `EMAIL_USE_SSL` | SMTP settings | Optional |
| `BLOCK_ALL_IPS` | Globally disable IP collection | `False` |
| `AGGRESSIVE_HASH_SALTING` | Prevents cross-site tracking; hashes user by date+site | `True` |

Full template: <https://github.com/milesmcc/shynet/blob/master/TEMPLATE.env>

### docker-compose.yml (from upstream, trimmed)

```yaml
version: '3'
services:
  shynet:
    container_name: shynet_main
    image: milesmcc/shynet:latest
    restart: unless-stopped
    expose:
      - 8080
    env_file:
      - .env
    environment:
      - DB_HOST=db
    networks:
      - internal
    depends_on:
      - db
  db:
    container_name: shynet_database
    image: postgres
    restart: always
    environment:
      - "POSTGRES_USER=${DB_USER}"
      - "POSTGRES_PASSWORD=${DB_PASSWORD}"
      - "POSTGRES_DB=${DB_NAME}"
    volumes:
      - shynet_db:/var/lib/postgresql/data
    networks:
      - internal
  webserver:
    container_name: shynet_webserver
    image: nginx
    restart: always
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    ports:
      - 8080:80
    depends_on:
      - shynet
    networks:
      - internal
volumes:
  shynet_db:
networks:
  internal:
```

Source: <https://github.com/milesmcc/shynet/blob/master/docker-compose.yml>

The Compose stack includes Nginx as a reverse proxy in front of Shynet. Edit `nginx.conf` line 2 to set the hostname (replace `example.com`). Change `8080:80` in the webserver service to your desired public port.

### First-run after `docker compose up -d`

```bash
# Create admin user (prints a temporary password)
docker exec -it shynet_main ./manage.py registeradmin your@email.com

# Set the instance whitelabel
docker exec -it shynet_main ./manage.py whitelabel "My Analytics"
```

Then visit `http://<host>:8080`, log in with the printed credentials, and change the password.

### Adding tracking to a site

1. In the Shynet admin UI, click **+ Create Service** and fill in the site name and URL.
2. On the service page, click **Manage** to get the tracking script embed code.
3. Inject the `<script>` tag on all pages you want tracked.
4. The script is under 1 KB and works without JavaScript (falls back to a 1×1 pixel).

## Upgrade procedure

```bash
# Pull latest image
docker compose pull

# Recreate containers (data persists in named volume shynet_db)
docker compose up -d --force-recreate

# Run any pending Django migrations
docker exec -it shynet_main ./manage.py migrate
```

Check the release notes before upgrading — some versions (e.g. 0.13.1) require additional configuration steps.

## Gotchas

- **`ALLOWED_HOSTS` must be set to your real domain** — the default `localhost` causes Django to reject requests from any other hostname. `ALLOWED_HOSTS=*` works but opens Host-header injection attacks against the password-reset flow.
- **`CSRF_TRUSTED_ORIGINS` requires the scheme** — must be `https://example.com`, not just `example.com`.
- **`nginx.conf` hostname** — line 2 of the upstream `nginx.conf` contains `example.com` and must be replaced before the stack starts, or Nginx will reject requests.
- **Shynet respects DNT** — users with Do Not Track enabled will not be tracked (configurable per-service). This is by design.
- **High-traffic scaling** — single-container Shynet is fine for personal sites. For higher traffic, enable Redis + Celery: set `CELERY_BROKER_URL`, `CELERY_TASK_ALWAYS_EAGER=False`, and run a separate Celery worker container. See the Kubernetes directory for a scaling reference.
- **Password reset requires email** — if SMTP is not configured, password resets are printed to the container logs only.
- **SQLite with Docker volume** — when using SQLite, add `-v shynet_db:/var/local/shynet/db:rw` and set `DB_NAME=/var/local/shynet/db/db.sqlite3`; a named volume is required for persistence.

## Upstream docs

- GitHub: <https://github.com/milesmcc/shynet>
- Usage guide (installation, reverse proxy, troubleshooting): <https://github.com/milesmcc/shynet/blob/master/GUIDE.md>
- Environment template: <https://github.com/milesmcc/shynet/blob/master/TEMPLATE.env>
- Docker Hub: <https://hub.docker.com/r/milesmcc/shynet>
