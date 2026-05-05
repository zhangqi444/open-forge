---
name: chiefonboarding-project
description: ChiefOnboarding recipe for open-forge. Employee onboarding platform. Django/Python + PostgreSQL. Docker. Upstream: https://github.com/chiefonboarding/ChiefOnboarding
---

# ChiefOnboarding

Free and open-source employee onboarding platform. Automates new hire workflows via Slack or a web dashboard. Supports pre-boarding pages, to-do items, resource courses, drip sequences, badges, introductions, and admin collaboration. Multilingual (English, Dutch, Portuguese, German, Turkish, French, Spanish, Japanese). Licensed AGPLv3. Upstream: https://github.com/chiefonboarding/ChiefOnboarding. Docs: https://docs.chiefonboarding.com

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Docker (Docker Hub image) | Primary upstream method |
| Heroku | Heroku deploy button | One-click via upstream template |
| Render | Render deploy button | One-click via upstream template |
| Elestio | Elestio managed | One-click managed hosting |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Domain for ChiefOnboarding | Used in email links and Slack callbacks |
| database | PostgreSQL connection string | Django app; requires PostgreSQL |
| smtp | SMTP host / port / user / password | For sending onboarding emails to new hires |
| smtp | From email address | Must match configured SMTP sender |
| slack (optional) | Slack bot token + signing secret | For Slack-based onboarding flow |
| security | SECRET_KEY | Random string for Django; generate with openssl rand -hex 50 |
| security | ALLOWED_HOSTS | Comma-separated list of allowed hostnames |

## Software-layer concerns

### Docker install

See Docker Hub: https://hub.docker.com/r/chiefonboarding/chiefonboarding

```bash
docker run -d \
  -e SECRET_KEY="your-secret-key" \
  -e ALLOWED_HOSTS="yourdomain.com" \
  -e DATABASE_URL="postgresql://user:pass@host:5432/dbname" \
  -e EMAIL_HOST="smtp.example.com" \
  -e EMAIL_PORT=587 \
  -e EMAIL_HOST_USER="user@example.com" \
  -e EMAIL_HOST_PASSWORD="password" \
  -e DEFAULT_FROM_EMAIL="onboarding@example.com" \
  -p 8000:8000 \
  chiefonboarding/chiefonboarding:latest
```

### Key environment variables

- SECRET_KEY — Django secret key (required; keep secret)
- ALLOWED_HOSTS — comma-separated list of valid hostnames
- DATABASE_URL — PostgreSQL connection URL
- EMAIL_HOST / EMAIL_PORT / EMAIL_HOST_USER / EMAIL_HOST_PASSWORD — SMTP config
- DEFAULT_FROM_EMAIL — From address for outgoing emails
- SLACK_BOT_TOKEN / SLACK_SIGNING_SECRET — For Slack integration (optional)

Full environment variable reference: https://docs.chiefonboarding.com

### Database

Requires PostgreSQL. Run migrations on first start:

```bash
docker exec <container> python manage.py migrate
```

Or via Docker Compose the migrate command is typically included as a one-shot service or entrypoint step — check upstream docs.

### Creating the first admin

```bash
docker exec -it <container> python manage.py createsuperuser
```

### Docker Compose example

A typical compose setup pairs ChiefOnboarding with PostgreSQL and a Redis cache. See upstream docs for the full compose file: https://docs.chiefonboarding.com

### Reverse proxy

ChiefOnboarding serves Django on port 8000. Put nginx or Caddy in front for TLS.

```nginx
proxy_pass http://127.0.0.1:8000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

### Data directories

- PostgreSQL database — all application data (users, sequences, to-dos, resources)
- Django media files — uploaded assets (mount a volume for persistence)

## Upgrade procedure

```bash
docker pull chiefonboarding/chiefonboarding:latest
docker stop <container>
docker rm <container>
# Re-run docker run with same env vars
docker exec <container> python manage.py migrate
```

Or with Docker Compose:

```bash
docker compose pull
docker compose up -d
docker exec <container> python manage.py migrate
```

Always run migrate after pulling a new version — Django migrations are required on upgrades.

## Gotchas

- Run migrate after every upgrade — Django migrations are not applied automatically on container start by default; skipping this breaks the app.
- PostgreSQL required — SQLite is not supported for production ChiefOnboarding deployments.
- SECRET_KEY must stay consistent — changing it invalidates all sessions and signed data. Store it in a secrets manager or env file.
- ALLOWED_HOSTS must include the domain — Django will return 400 Bad Request for any host not in ALLOWED_HOSTS.
- Slack setup requires a Slack app — see https://docs.chiefonboarding.com for the Slack app configuration steps (OAuth scopes, event subscriptions, etc.).
- Media file persistence — uploaded files (avatars, resources) live in Django's MEDIA_ROOT; mount a persistent volume or they are lost on container restart.
- Email required for new hire flows — without SMTP configured, new hire notifications and password resets fail silently.

## Links

- Upstream repo: https://github.com/chiefonboarding/ChiefOnboarding
- Documentation: https://docs.chiefonboarding.com
- Docker Hub: https://hub.docker.com/r/chiefonboarding/chiefonboarding
- Integrations: https://integrations.chiefonboarding.com
