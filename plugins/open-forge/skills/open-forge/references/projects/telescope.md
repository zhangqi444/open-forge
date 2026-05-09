---
name: telescope
description: Telescope recipe for open-forge. Covers Docker Compose (PostgreSQL + Telescope) install for this web-based log viewer UI supporting ClickHouse, StarRocks, Docker, and Kubernetes log sources. Source: https://github.com/iamtelescope/telescope. Latest release: v0.0.27.
---

# Telescope

Web-based log viewer UI for exploring log data from multiple backends: **ClickHouse**, **StarRocks**, **Docker** (via the Docker socket), and **Kubernetes** (via pod log API). Provides a unified query experience with time-range selectors, interactive graphs, RAW SQL filtering, role-based access control (RBAC), and GitHub / Okta OAuth. Built with Django (Python) + React. Upstream: <https://github.com/iamtelescope/telescope>. Docs: <https://docs.iamtelescope.net/>. Live demo: <https://demo.iamtelescope.net/>.

> ⚠️ **Beta software.** Telescope is explicitly labeled beta; some features may be incomplete. Review the release notes before upgrading.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (PostgreSQL) | Recommended for production. Persistent DB, easy upgrades. |
| Docker (SQLite, dev) | Quick local evaluation only — not for production. |
| Kubernetes / Helm | See <https://github.com/iamtelescope/telescope/tree/main/helm>. |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which install method?" | Drives which section below |
| preflight | "Domain / URL Telescope will be accessible at?" | Needed for `CSRF_TRUSTED_ORIGINS` and `ALLOWED_HOSTS` |
| auth | "Use GitHub OAuth for login? (Client ID + secret needed from GitHub OAuth App)" | Optional; enables org-scoped access control |
| auth | "Or use Okta? (Client ID, secret, base URL)" | Optional |
| db | "PostgreSQL password?" | Required for Compose + PostgreSQL method |
| secrets | "Django secret key?" (generate one) | Required; never reuse between environments |

---

## Method — Docker Compose with PostgreSQL (recommended)

> **Source:** Helm `values.yaml` and Dockerfile — <https://github.com/iamtelescope/telescope>. Image: `ghcr.io/iamtelescope/telescope`.

### File layout

```
telescope/
├── docker-compose.yml
├── .env
└── config.yaml
```

### .env

```bash
DJANGO_SECRET_KEY=<generate with: python3 -c "import secrets; print(secrets.token_urlsafe(50))">
POSTGRES_PASSWORD=changeme
```

### config.yaml

```yaml
gunicorn:
  bind: "0.0.0.0:8080"
  workers: 4
  timeout: 120

django:
  SECRET_KEY: "!env DJANGO_SECRET_KEY"       # loaded from env at runtime
  ALLOWED_HOSTS:
    - "localhost"
    - "your-telescope-host.example.com"       # replace with your domain / IP
  CSRF_TRUSTED_ORIGINS:
    - "http://localhost:8080"
    - "https://your-telescope-host.example.com"
  DEBUG: false
  DATABASES:
    default:
      ENGINE: "django.db.backends.postgresql"
      NAME: "telescope"
      HOST: "db"
      PORT: 5432
      USER: "telescope"
      PASSWORD: "!env POSTGRES_PASSWORD"

auth:
  providers:
    github:
      enabled: false      # set to true and provide client_id/key for GitHub OAuth
      client_id: ""
      key: ""
      organizations: []   # restrict to specific GitHub orgs if desired
    okta:
      enabled: false
  enable_testing_auth: false  # NEVER set true in production
```

### docker-compose.yml

```yaml
services:
  db:
    image: postgres:16-alpine
    container_name: telescope-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: telescope
      POSTGRES_USER: telescope
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - telescope_db:/var/lib/postgresql/data

  telescope:
    image: ghcr.io/iamtelescope/telescope:latest
    container_name: telescope
    restart: unless-stopped
    depends_on:
      - db
    environment:
      DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      DJANGO_COLLECTSTATIC: "1"
    volumes:
      - ./config.yaml:/config.yaml:ro
    ports:
      - "8080:8080"
    command: gunicorn telescope.wsgi:application --config /opt/telescope/gunicorn.conf.py

volumes:
  telescope_db:
```

> **Note:** Telescope's Docker image runs gunicorn binding to the port defined in `config.yaml` (default `0.0.0.0:8080`). The entrypoint runs `collectstatic` automatically when `DJANGO_COLLECTSTATIC=1`.

### Deploy

```bash
cd telescope/
docker compose pull
docker compose up -d

# Run DB migrations (required on first start and after upgrades)
docker compose exec telescope python manage.py migrate
```

Visit `http://<host>:8080`.

### Verify

```bash
docker compose ps              # both services should be running
docker compose logs telescope  # check for startup errors
curl -sI http://localhost:8080 # should return 200 or redirect to login
```

### Lifecycle

```bash
# Update
docker compose pull
docker compose up -d
docker compose exec telescope python manage.py migrate   # always run after upgrades

# Logs
docker compose logs -f telescope

# Stop
docker compose down
```

---

## Method — Docker (SQLite, dev/eval only)

> ⚠️ SQLite support in Telescope is explicitly for **testing/development** — not production.

```bash
mkdir -p telescope-data

docker run -d \
  --name telescope \
  -p 8080:9898 \
  -v "$(pwd)/telescope-data:/app/data" \
  -e DJANGO_SECRET_KEY="$(head -c 32 /dev/urandom | base64)" \
  ghcr.io/iamtelescope/telescope:latest
```

On first run, apply migrations:

```bash
docker exec telescope python manage.py migrate
```

Visit `http://localhost:8080`. This uses SQLite at `/app/data/telescope.sqlite3`.

---

## Connecting log sources

After login, navigate to **Sources** to add a connection:

| Source type | What you need |
|---|---|
| **ClickHouse** | Host, port, database, user, password; optionally field config |
| **StarRocks** | Host, port, database, user, password |
| **Docker** | Path to Docker socket (e.g. `/var/run/docker.sock`) |
| **Kubernetes** | Kubeconfig or in-cluster service account |

For Docker source: mount the socket into the Telescope container and configure the socket path in Sources. Add to `docker-compose.yml`:

```yaml
telescope:
  volumes:
    - ./config.yaml:/config.yaml:ro
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

---

## Authentication

Telescope supports local login (password set via admin), GitHub OAuth, and Okta OAuth.

### GitHub OAuth

1. Create a GitHub OAuth App at <https://github.com/settings/applications/new>.
   - Authorization callback URL: `https://<your-host>/auth/complete/github/`
2. Set in `config.yaml`:

```yaml
auth:
  providers:
    github:
      enabled: true
      client_id: "<Client ID>"
      key: "!env GITHUB_SECRET"
      organizations: ["your-org"]   # optional — restrict to org members
```

Add `GITHUB_SECRET=<Client Secret>` to `.env`.

---

## Gotchas

- **Run migrations after every upgrade.** Telescope uses Django migrations; skipping this can break the app on new schema changes (especially after upgrading to a version that adds new data models).
- **`!env` syntax in config.yaml.** Telescope supports `!env VAR_NAME` as a YAML value to inject environment variables at runtime. Use this for secrets (`SECRET_KEY`, `POSTGRES_PASSWORD`, OAuth secrets) rather than putting them in plaintext.
- **`DJANGO_SECRET_KEY` must be unique per environment.** Reusing the same key across dev/prod allows session tokens to be forged cross-environment. Generate a fresh key for each deployment.
- **`enable_testing_auth: true` is for CI only.** It bypasses all authentication and should never be set in production.
- **Renderer syntax changed in v0.0.27.** The `|highlight` / `|hl` renderers now require an `as` alias separator (e.g. `message|json as m|highlight`). Existing saved views using the old flat syntax must be updated.
- **Gunicorn workers and memory.** The default Helm config uses 8 workers; each Django worker holds its own in-memory state. On memory-constrained hosts, reduce `workers` in `config.yaml`.
- **CSRF_TRUSTED_ORIGINS must include your domain.** If you access Telescope from a non-localhost URL without adding it here, all POST requests (login, source creation, etc.) will fail with a 403 CSRF error.
