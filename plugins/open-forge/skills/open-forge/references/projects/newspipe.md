---
name: newspipe-project
description: Newspipe recipe for open-forge. Web RSS/Atom news aggregator built on Flask + Python. Covers Poetry-based install with SQLite or PostgreSQL, and production Gunicorn deployment. Based on upstream README at https://github.com/cedricbonhomme/newspipe.
---

# Newspipe

Web-based news aggregator (RSS/Atom) with multi-user support, OPML import/export, bookmarks, and optional LDAP auth. Built on Flask, asyncio, and SQLAlchemy. AGPL-3.0. Upstream: https://github.com/cedricbonhomme/newspipe. Also mirrored at https://git.sr.ht/~cedric/newspipe.

## Compatible install methods

| Method | Database | When to use |
|---|---|---|
| Poetry + Flask (dev/SQLite) | SQLite | Quick local setup; not for production |
| Poetry + Flask (production/PostgreSQL) | PostgreSQL | Multi-user production |
| Production with Gunicorn | PostgreSQL | Recommended for production; WSGI server |

No official Docker image is maintained. Docker support would require building a custom image from the repository.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "SQLite (dev) or PostgreSQL (production)?" | SQLite / PostgreSQL | Drives which config file to use |
| config | "Admin nickname?" | Free-text | Created via flask create_admin |
| config | "Admin password?" | Free-text (sensitive) | Set at first-time setup |
| database | "PostgreSQL connection string?" | postgresql://user:pass@host/db | Only for PostgreSQL path |
| smtp | "SMTP config for notifications?" | host, port, user, pass | Optional; set in instance/config.py |
| cron | "Feed fetch interval (hours)?" | Number (default 3) | Controls cron schedule for fetch_asyncio |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python >= 3.10 |
| Package manager | Poetry (required) |
| Frontend build | npm ci (required before first run) |
| Config file | instance/config.py (copy from instance/config.py example) |
| Env var | NEWSPIPE_CONFIG=<config-filename> (e.g. sqlite.py or postgresql.py) |
| DB migrations | flask db_init on first run; flask db upgrade on upgrades |
| Feed fetching | Manual command: flask fetch_asyncio — schedule via cron |
| WSGI server | Gunicorn or mod_wsgi for production |
| Translations | pybabel compile -d newspipe/translations — required before start |

## Install: SQLite (development)

Source: https://github.com/cedricbonhomme/newspipe/blob/master/README.md#deployment

Prerequisites: git, poetry, npm, Python >= 3.10

```bash
git clone https://github.com/cedricbonhomme/newspipe
cd newspipe/
npm ci
poetry install
poetry shell
pybabel compile -d newspipe/translations
export NEWSPIPE_CONFIG=sqlite.py
flask db_init
flask create_admin --nickname <nickname> --password <password>
flask run --debug
```

Access at http://localhost:5000.

## Install: PostgreSQL (production)

Source: https://github.com/cedricbonhomme/newspipe/blob/master/README.md#deployment

```bash
sudo apt-get install postgresql
git clone https://github.com/cedricbonhomme/newspipe
cd newspipe/
npm ci
poetry install
cp instance/config.py instance/postgresql.py
# Edit instance/postgresql.py — set SQLALCHEMY_DATABASE_URI and other settings
export NEWSPIPE_CONFIG=postgresql.py
pybabel compile -d newspipe/translations
flask db_create
flask db_init
flask create_admin --nickname <nickname> --password <password>
```

Run with Gunicorn:
```bash
poetry run gunicorn -w 4 -b 0.0.0.0:8000 app:app
```

## Feed fetching (cron)

Newspipe requires a scheduled job to fetch RSS/Atom feeds. Add to crontab:

```bash
# Fetch every 3 hours
0 */3 * * * FLASK_APP=app.py /path/to/venv/bin/flask fetch_asyncio
```

The full virtualenv path is needed when running from cron (not from an active poetry shell). Find it with:
```bash
poetry env info --path
```

Then the cron line becomes:
```bash
0 */3 * * * NEWSPIPE_CONFIG=postgresql.py /path/to/.cache/pypoetry/virtualenvs/newspipe-XXX/bin/flask fetch_asyncio
```

## Upgrade procedure

Source: https://github.com/cedricbonhomme/newspipe/blob/master/README.md#updates-and-migrations

```bash
cd newspipe/
git pull origin master
poetry install
poetry run flask db upgrade
poetry run pybabel compile -d newspipe/translations
# Restart gunicorn / web server
```

## Gotchas

- npm ci is required: The frontend assets are built from npm. Skipping it results in a broken UI.
- pybabel compile is required: Missing translations cause startup errors or blank UI strings.
- NEWSPIPE_CONFIG must be set: Without this env var, Newspipe falls back to defaults which may not match your setup.
- Feeds won't update without cron: flask fetch_asyncio is not auto-scheduled. Set up cron or it will only show articles from initial import.
- No Docker image: There is no official Docker image. Running in Docker requires writing a custom Dockerfile.
- LDAP: Optional LDAP authentication is available — see instance/config.py for the configuration options.

## Links

- Upstream README: https://github.com/cedricbonhomme/newspipe/blob/master/README.md
- GitHub: https://github.com/cedricbonhomme/newspipe
- SourceHut mirror: https://git.sr.ht/~cedric/newspipe
- CHANGELOG: https://github.com/cedricbonhomme/newspipe/blob/master/CHANGELOG.md
