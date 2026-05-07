---
name: shhh
description: Shhh recipe for open-forge. Tiny Flask app to share encrypted secrets via one-time links with passphrase and expiration. Secrets auto-delete after viewing or expiry. Python/PostgreSQL/Docker. Source: https://github.com/smallwat3r/shhh
---

# Shhh

Tiny Flask web app for sharing secrets securely. Create an encrypted secret, set a passphrase and expiration date, and share the generated link. The secret is automatically and permanently deleted as soon as it's viewed once, the expiry date passes, or the attempt limit is exceeded. Secrets are encrypted at rest (Fernet with password + random salt); passphrases are never stored. MIT licensed.

> Note: The upstream author is sunsetting Shhh in favor of [secretapi](https://github.com/smallwat3r/secretapi). Shhh remains functional and is still available.

Upstream: <https://github.com/smallwat3r/shhh>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose (PostgreSQL) | Recommended — official compose file provided |
| Any | Docker Compose (MySQL) | Alternate compose target |
| Linux | Manual Python + PostgreSQL | Flask + Gunicorn + Nginx |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | PostgreSQL user, password, DB name | Used by Flask app and DB container |
| config | Port mapping | Default: 8081 |
| config | SHHH_HOST (optional) | Custom domain for generated secret links; defaults to request URL |
| config | SHHH_SECRET_MAX_LENGTH (optional) | Max characters per secret |

## Software-layer concerns

### Architecture

- Flask app (Python) — web UI + API
- PostgreSQL or MySQL — stores encrypted secrets until deletion
- Gunicorn — WSGI server (in production)

### Key env vars

| Var | Description | Required |
|---|---|---|
| FLASK_ENV | Environment (dev-docker / production) | Yes |
| FLASK_APP | Entry point: wsgi.py | Yes |
| POSTGRES_USER / DB_USER | Database user | Yes |
| POSTGRES_PASSWORD / DB_PASSWORD | Database password | Yes |
| POSTGRES_DB / DB_NAME | Database name | Yes |
| DB_HOST | Database host | Yes |
| DB_PORT | Database port (default 5432) | Yes |
| DB_ENGINE | SQLAlchemy engine string | Yes |
| SHHH_HOST | Override hostname in generated links | No |
| SHHH_SECRET_MAX_LENGTH | Max secret length in characters | No |
| SHHH_DB_LIVENESS_RETRY_COUNT | DB retries before R/W (default 5) | No |
| SHHH_DB_LIVENESS_SLEEP_INTERVAL | Seconds between DB retries (default 1) | No |

## Install — Docker Compose (recommended)

```bash
git clone https://github.com/smallwat3r/shhh.git
cd shhh

# Review/edit environment file for dev-postgres
# (for production, copy and edit with real credentials)
cat environments/dev-docker-postgres.env

# Start with PostgreSQL
make dc-start
# Or with MySQL:
make dc-start-mysql

# Access at http://localhost:8081
```

To customize credentials before starting, edit `environments/dev-docker-postgres.env`:
```env
POSTGRES_USER=shhh
POSTGRES_PASSWORD=yourpassword
POSTGRES_DB=shhh
DB_USER=shhh
DB_PASSWORD=yourpassword
DB_NAME=shhh
DB_HOST=db
DB_PORT=5432
DB_ENGINE=postgresql+psycopg2
SHHH_HOST=https://secrets.example.com
```

Then:
```bash
make dc-start
```

## DB migrations

```bash
# After first start (or after upgrades)
make db c='upgrade'
```

## Install — manual (production)

```bash
sudo apt install python3 python3-venv postgresql nginx

# Clone and set up virtualenv
git clone https://github.com/smallwat3r/shhh.git
cd shhh
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Configure env vars (copy from environments/dev-docker-postgres.env, edit for production)
# Set FLASK_ENV=production

# Run DB migrations
flask db upgrade

# Start with Gunicorn
gunicorn wsgi:app --bind 0.0.0.0:8000 --workers 4

# Configure nginx as reverse proxy to 127.0.0.1:8000
```

## Upgrade procedure

```bash
git pull
make dc-stop
make dc-start
# Run migrations if needed:
make db c='upgrade'
```

## Gotchas

- Secrets are truly one-time — once read, they are permanently deleted from the database. There is no recovery. This is by design.
- Encryption note: secrets are encrypted with Fernet using the passphrase + a random salt (100,000 iterations). The passphrase is never stored — if a user forgets the passphrase, the secret cannot be decrypted.
- `SHHH_HOST` should be set to your public HTTPS URL in production so generated links point to the right place. Without it, links use the request's URL root which may be `localhost` or an internal address.
- The project is being sunset upstream — consider [secretapi](https://github.com/smallwat3r/secretapi) for new deployments if long-term maintenance matters.
- Run DB migrations after every upgrade — `make db c='upgrade'` (or `flask db upgrade` in the container).

## Links

- Source: https://github.com/smallwat3r/shhh
- Successor project: https://github.com/smallwat3r/secretapi
