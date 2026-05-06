---
name: ihatemoney
description: IHateMoney recipe for open-forge. Covers self-hosting the simple shared expense tracking web app. Upstream: https://github.com/spiral-project/ihatemoney
---

# IHateMoney

Simple, no-login shared expense tracking web app. Create a project, add expenses, and see who owes whom — perfect for splitting bills among friends, roommates, or travel groups. No user accounts required; projects are identified by a shared ID and password. Upstream: <https://github.com/spiral-project/ihatemoney>. Docs: <https://ihatemoney.readthedocs.io>.

**License:** BSD-3-Clause

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (ihatemoney/ihatemoney) | https://github.com/spiral-project/ihatemoney/blob/master/docs/installation.rst | ✅ | Recommended; official image |
| pip (Python package) | https://ihatemoney.readthedocs.io/en/latest/installation.html | ✅ | Bare-metal Python environments |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secrets | "SECRET_KEY?" | Random string | Required for session security |
| app | "Allow public project creation?" | True/False | `ALLOW_PUBLIC_PROJECT_CREATION` |
| app | "Activate demo project?" | True/False | `ACTIVATE_DEMO_PROJECT` |
| database | "SQLite or PostgreSQL?" | SQLite (default) or Postgres URI | `SQLALCHEMY_DATABASE_URI` |
| email | "SMTP settings?" | host/port/user/pass | Optional; for expense notifications |
| admin | "Enable admin dashboard?" | True/False | `ACTIVATE_ADMIN_DASHBOARD` |
| admin | "Admin password hash?" | `docker run ... generate_password_hash` | Required if admin enabled |

## Docker Compose

```yaml
services:
  ihatemoney:
    image: ihatemoney/ihatemoney:latest
    restart: unless-stopped
    ports:
      - 8000:8000
    volumes:
      - ./database:/database
    environment:
      - SECRET_KEY=change-me-to-a-random-string
      - SQLALCHEMY_DATABASE_URI=sqlite:////database/ihatemoney.db
      - ALLOW_PUBLIC_PROJECT_CREATION=True
      - ACTIVATE_DEMO_PROJECT=False
      - ACTIVATE_ADMIN_DASHBOARD=False
      - ADMIN_PASSWORD=
      - SESSION_COOKIE_SECURE=True
      - MAIL_SERVER=localhost
      - MAIL_PORT=25
      - MAIL_DEFAULT_SENDER=Budget manager <admin@example.com>
```

```bash
docker compose up -d
```

> **Generate admin password hash:**
> ```bash
> docker run -it --rm --entrypoint ihatemoney ihatemoney/ihatemoney:latest generate_password_hash
> ```
> Replace every `$` in the result with `$$` in the compose environment value.

## Software-layer concerns

### Key env vars

| Variable | Default | Purpose |
|---|---|---|
| `SECRET_KEY` | (none) | **Required** — Flask session secret; use a long random string |
| `SQLALCHEMY_DATABASE_URI` | sqlite in container | Database; use a volume-mounted path for SQLite |
| `ALLOW_PUBLIC_PROJECT_CREATION` | `True` | Allow anyone to create a new project |
| `ACTIVATE_DEMO_PROJECT` | `True` | Show a demo project on the front page |
| `SESSION_COOKIE_SECURE` | `True` | Set to True when serving over HTTPS |
| `ACTIVATE_ADMIN_DASHBOARD` | `False` | Enable admin UI |
| `ADMIN_PASSWORD` | (empty) | Bcrypt hash; disable with empty string |

### Data directory

| Path (container) | Purpose |
|---|---|
| `/database` | SQLite database file (`ihatemoney.db`) |

Mount a host directory here to persist data across container restarts.

### Dollar signs in ADMIN_PASSWORD

The `generate_password_hash` output contains `$` characters. In Docker Compose environment values, each `$` must be doubled (`$` → `$$`) to prevent shell variable interpolation.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- **SECRET_KEY must be set and stable.** Changing it invalidates all existing sessions. Use a long random string and persist it.
- **Dollar signs in password hash.** When setting `ADMIN_PASSWORD` in docker-compose.yml, every `$` must become `$$`.
- **`SESSION_COOKIE_SECURE=True` requires HTTPS.** If serving over plain HTTP (local network), set this to `False` or sessions will break.
- **No user accounts.** IHateMoney is intentionally account-free. Project access is controlled by a shared project password. Don't use it for sensitive financial data.
- **SQLite concurrency.** SQLite works well for personal/small-group use. For high-traffic deployments, use PostgreSQL (`SQLALCHEMY_DATABASE_URI=postgresql://...`).
- **Public project creation.** With `ALLOW_PUBLIC_PROJECT_CREATION=True`, anyone can create projects on your instance. Restrict to `False` if running a private instance.

## Upstream docs

- Documentation: https://ihatemoney.readthedocs.io
- Installation guide: https://ihatemoney.readthedocs.io/en/latest/installation.html
- Configuration reference: https://ihatemoney.readthedocs.io/en/latest/configuration.html
- GitHub README: https://github.com/spiral-project/ihatemoney
