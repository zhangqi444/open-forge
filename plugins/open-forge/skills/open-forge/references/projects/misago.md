---
name: misago-project
description: Misago recipe for open-forge. Covers the Python/Django forum software. Upstream: https://github.com/rafalp/Misago. Docs: https://misago.gitbook.io/docs/
---

# Misago

Modern Python/Django-powered forum software. Upstream: <https://github.com/rafalp/Misago>. Documentation: <https://misago.gitbook.io/docs/>. Homepage: <http://misago-project.org/>.

> **License:** GPL-2.0. Development status: perpetual beta ("Bananas").

Misago is a Django application backed by PostgreSQL and Redis, with a React.js frontend served via webpack. The preferred way to run a production Misago instance is via Docker Compose. The upstream repository ships a dev-compose.yml for development and a separate production setup documented at https://misago.gitbook.io/docs/.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (production) | https://misago.gitbook.io/docs/ | ✅ | Recommended production path |
| Docker Compose (development) | dev-compose.yml in repo | ✅ | Local development only — runs Django dev server |
| Manual (bare metal) | https://misago.gitbook.io/docs/ | ✅ | Advanced; not recommended for beginners |

## Dev Docker Compose services (dev-compose.yml)

The development compose file included in the repo:

```yaml
services:
  postgres:       # postgres:15 — port 5432
  redis:          # redis:6
  misago:         # Django dev server on port 8000
  celery-worker:  # Celery async task worker
```

Environment variables for dev:

| Variable | Dev default |
|---|---|
| POSTGRES_HOST | postgres |
| POSTGRES_DB | misago |
| POSTGRES_USER | misago |
| POSTGRES_PASSWORD | misago |
| POSTGRES_TEST_DB | misago_test |
| SUPERUSER_USERNAME | Admin |
| SUPERUSER_EMAIL | admin@example.com |
| SUPERUSER_PASSWORD | password |
| MISAGO_DEVSERVER_PORT | 8000 |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Production or development install?" | Options: production / development | Drives path |
| app | "Forum hostname / domain?" | Free-text | Production |
| db | "PostgreSQL password?" | Generated secret | All |
| db | "PostgreSQL database name?" | Free-text | All |
| cache | "Redis URL?" | e.g. redis://redis:6379/0 | All |
| email | "SMTP host + port + user + password?" | Free-text | Production (forum sends email for account activation, password reset, etc.) |
| admin | "Initial superuser email + password?" | Free-text | All |
| storage | "Media files directory path?" | Host path | Production |

## Software-layer concerns

### Key settings

Misago stores its configuration in Django settings files. For Docker-based production deploys, settings are typically passed as environment variables or via a settings override file. Refer to https://misago.gitbook.io/docs/ for the canonical list of production settings.

### Data directories

| Data | Location (typical) |
|---|---|
| PostgreSQL data | docker volume or bind-mount |
| Media uploads | /app/media or configured MEDIA_ROOT |
| Static files | Collected via manage.py collectstatic |

### Quick dev start

```bash
git clone https://github.com/rafalp/Misago
cd Misago

# Preferred: use the ./dev helper script
./dev init          # builds containers, installs deps, initialises DB
docker compose up   # starts dev server at http://localhost:8000
```

Or manually:

```bash
docker compose build
docker compose run --rm misago python manage.py migrate
docker compose run --rm misago python manage.py createsuperuser
docker compose up
```

Dev URLs:
- Forum: http://localhost:8000/
- Admin panel: http://localhost:8000/admincp/ (credentials: Admin / password)
- Email capture (Mailpit): http://localhost:8025

## Upgrade procedure

```bash
git pull origin master
docker compose build misago
docker compose run --rm misago python manage.py migrate
docker compose up -d
```

Always check the upstream changelog / releases before upgrading: https://github.com/rafalp/Misago/releases

## Gotchas

- **Development status is perpetual beta.** Misago labels itself "Bananas" — features are production-ready, but the API and plugin system are still evolving.
- **Windows line endings.** Cloning on Windows converts LF to CRLF in the ./dev script, causing `/bin/sh: ./dev: not found` in Docker. Disable git autocrlf before cloning or re-clone after disabling it.
- **No plugin system yet.** The plugin system is on the roadmap but not shipped. Customisation requires forking.
- **OAuth providers.** Sign-in with Facebook, Google, GitHub, Steam, Blizzard.net, and 50+ other OAuth2 providers is supported out of the box via social-django.
- **Celery required for async tasks.** Email sending, notifications, and some moderation tasks run via Celery workers — the celery-worker service in docker compose must be running.
- **Python 3.12 required.** See the badge in the README; earlier Python 3 versions are not supported.

## Upstream docs

- Documentation: https://misago.gitbook.io/docs/
- GitHub README: https://github.com/rafalp/Misago
- Community forums (bug reports): https://misago-project.org/c/bug-reports/29/
- Discord: https://discord.gg/fwvrZgB
