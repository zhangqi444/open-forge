---
name: passit
description: Passit recipe for open-forge. Self-hosted password manager with end-to-end client-side encryption, group and user sharing. Django + PostgreSQL backend, Docker Compose. Based on upstream install guide at https://passit.io/install/ and https://gitlab.com/passit.
---

# PassIt

Self-hosted password manager with client-side end-to-end encryption and group/user sharing. No admin UI. The Django backend never sees plaintext credentials — all crypto happens in the browser. In maintenance mode (production-ready, no new features planned). AGPL-3.0. Upstream: https://gitlab.com/passit. Image: passit/passit:stable (Docker Hub).

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose + nginx | Standard self-hosted setup on any Linux server |
| DigitalOcean App Platform | Managed PaaS deployment |
| OpenShift / Kubernetes | Enterprise or existing k8s clusters |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "PostgreSQL host:port?" | host:port | External DB or local PostgreSQL |
| database | "PostgreSQL database name, user, password?" | Strings | Builds DATABASE_URL |
| config | "SECRET_KEY?" | Random string (50+ chars) | Django secret key; generate with openssl rand -base64 50 |
| config | "EMAIL_CONFIRMATION_HOST?" | URL (e.g. https://passit.yourdomain.com) | Used in confirmation emails |
| email | "SMTP URL?" | consolemail:// or smtp:// | consolemail logs to stdout; production needs real SMTP |
| email | "DEFAULT_FROM_EMAIL?" | Email address | Sender address for all emails |
| network | "Domain for Passit?" | FQDN | DNS A record must point here; SSL required |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Python (Django) |
| Database | PostgreSQL (external or self-hosted; hstore extension required) |
| Encryption | All cryptography is client-side; server never sees plaintext |
| Port | 8000 (Docker; proxy via nginx to 80/443) |
| Migrations | Must run manually after deploy: docker compose run --rm web ./manage.py migrate |
| SSL | Required; Passit is not secure without HTTPS. Use certbot or a terminating proxy. |
| Image | passit/passit:stable (Docker Hub) |
| Status | Maintenance mode -- production-ready, no new features |

## Install: Docker Compose + nginx

Source: https://passit.io/install/

**1. Set up PostgreSQL** (external service, Amazon RDS, or local). Enable the hstore extension:

```sql
CREATE EXTENSION hstore;
```

**2. Create compose file** (from https://gitlab.com/passit/passit-frontend/-/blob/master/docker-compose.production.yml):

```yaml
services:
  web:
    image: passit/passit:stable
    command: bin/start.sh
    ports:
      - "8000:8080"
    environment:
      DATABASE_URL: postgres://USER:PASSWORD@HOST:5432/DBNAME
      SECRET_KEY: change_me_use_a_long_random_string
      IS_DEBUG: 'False'
      EMAIL_URL: smtp://user:pass@smtp.example.com:587
      DEFAULT_FROM_EMAIL: "passit@yourdomain.com"
      EMAIL_CONFIRMATION_HOST: "https://passit.yourdomain.com"
```

**3. Run migrations:**

```bash
docker compose up -d
docker compose run --rm web ./manage.py migrate
```

**4. Configure nginx** (proxy to port 8000):

```nginx
server {
    listen 80;
    server_name passit.yourdomain.com;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**5. Set up SSL** with certbot:

```bash
certbot --nginx -d passit.yourdomain.com
```

## Configuration: key environment variables

| Variable | Required | Description |
|---|---|---|
| DATABASE_URL | Yes | postgres://user:pass@host:5432/db |
| SECRET_KEY | Yes | Django secret key (long random string) |
| IS_DEBUG | No (default False) | Leave False in production |
| EMAIL_URL | Yes | SMTP URL or consolemail:// for stdout |
| DEFAULT_FROM_EMAIL | Yes | From address for confirmation emails |
| EMAIL_CONFIRMATION_HOST | Yes | Public URL of Passit instance |
| SECURE_SSL_REDIRECT | No (default False) | Set True to redirect HTTP to HTTPS via Django |
| SECURE_COOKIE | No (default True) | Set False only if not using SSL |
| CORS_ORIGIN_ALLOW_ALL | No (default True) | Required True for browser extensions to work |
| CELERY_USE_FOR_EMAIL | No (default False) | Send email async via Celery |
| CELERY_BROKER_URL | No | Redis URL if using Celery |
| SENTRY_DSN | No | Enable Sentry error reporting |
| DJANGO_LOG_LEVEL | No (default INFO) | DEBUG / INFO / WARNING / ERROR / CRITICAL |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose run --rm web ./manage.py migrate
```

Run migrations after every upgrade.

## Gotchas

- Migrations are not automatic: Unlike some Django apps, PassIt does not auto-migrate on startup. Always run ./manage.py migrate after pulling a new image.
- hstore PostgreSQL extension required: Run CREATE EXTENSION hstore; on the database before first migration, or migrations will fail.
- SSL is not optional: SECURE_COOKIE defaults to True. Without HTTPS, session cookies will not be sent and login will not work. Run certbot or terminate TLS upstream.
- Maintenance mode: PassIt is feature-complete and not accepting new features. It is stable and production-ready, but will only receive security patches.
- No admin interface: There is no Django admin UI for managing users or vault entries. User management is entirely self-service through the web app.
- Web extensions require CORS_ORIGIN_ALLOW_ALL=True: Changing this to False will break the browser extension unless you recompile it with your domain whitelisted.
- Celery is optional: Email sending works synchronously by default. Celery + Redis is only needed for large-scale deployments.

## Links

- Install guide: https://passit.io/install/
- Update guide: https://passit.io/update/
- GitLab (meta): https://gitlab.com/passit/passit
- Backend source: https://gitlab.com/passit/passit-backend
- Frontend source: https://gitlab.com/passit/passit-frontend
- Demo: https://app.passit.io/
