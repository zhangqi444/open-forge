---
name: psono-project
description: Psono recipe for open-forge. Enterprise/team password manager with Docker Compose deployment. Based on upstream docs at https://doc.psono.com/ and GitLab repo at https://gitlab.com/esaqa/psono/psono-server.
---

# Psono

Self-hosted password manager for companies and teams. Django/Python backend, PostgreSQL storage, end-to-end encryption. Apache-2.0. Upstream: https://gitlab.com/esaqa/psono/psono-server. Docs: https://doc.psono.com/.

Psono consists of multiple components: the server (psono-server), a web client (psono-client), and optionally a file server (psono-fileserver) for encrypted file storage. All communicate via REST API. The server handles credentials storage and sharing; encryption happens client-side.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended; all components in one stack |
| Manual / bare-metal Python | Advanced; requires PostgreSQL + Python environment setup |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| config | "Domain name for Psono?" | FQDN (e.g. psono.example.com) | Used in config and TLS setup |
| config | "SECRET_KEY?" | Random 64-char hex string | Generate: openssl rand -hex 32 |
| config | "ACTIVATION_LINK_SECRET?" | Random string | For email activation links |
| config | "DB_SECRET?" | Random string | Used for additional DB encryption |
| database | "PostgreSQL password?" | Free-text (sensitive) | For the psono DB user |
| smtp | "SMTP host, port, user, password?" | Separate values | For account verification emails |
| smtp | "From address?" | email | e.g. no-reply@example.com |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Backend | Django / Python; image: psono/psono-server |
| Config | settings.yaml — mapped into container at /etc/psono/settings.yaml |
| Database | PostgreSQL (required) |
| Cache | Redis (optional but recommended for sessions) |
| Email | Required for user account verification |
| Backup | Back up PostgreSQL database AND settings.yaml (contains secrets needed to decrypt DB) |
| Ports | Web client on 80/443; server API on 10100 internally |
| TLS | Terminate at nginx reverse proxy; Psono itself serves HTTP |

## Install: Docker Compose

Source: https://doc.psono.com/admin/installation/install-server-ce.html

Psono recommends Docker Compose for self-hosted deployments. The stack includes psono-server, psono-client, PostgreSQL, and nginx.

### Minimal docker-compose.yml

```yaml
services:
  psono-server:
    image: psono/psono-server:latest
    restart: unless-stopped
    volumes:
      - ./settings.yaml:/etc/psono/settings.yaml:ro
    depends_on:
      - db

  psono-client:
    image: psono/psono-client:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config.json:/usr/share/nginx/html/config.json:ro
    depends_on:
      - psono-server

  db:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=psono
      - POSTGRES_USER=psono
      - POSTGRES_PASSWORD=changeme
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### settings.yaml

Minimal server config (place in the same directory as docker-compose.yml):

```yaml
DEBUG: False
ALLOWED_HOSTS: ['psono.example.com']
SECRET_KEY: '<your-secret-key>'
ACTIVATION_LINK_SECRET: '<your-activation-secret>'
DB_SECRET: '<your-db-secret>'

DATABASES:
  default:
    ENGINE: django.db.backends.postgresql_psycopg2
    NAME: psono
    USER: psono
    PASSWORD: changeme
    HOST: db
    PORT: 5432

EMAIL_BACKEND: django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST: 'smtp.example.com'
EMAIL_HOST_USER: 'noreply@example.com'
EMAIL_HOST_PASSWORD: 'smtp-password'
EMAIL_PORT: 587
EMAIL_USE_TLS: True
EMAIL_FROM: 'Psono <noreply@example.com>'

MANAGEMENT_ENABLED: True
WEB_CLIENT_URL: 'https://psono.example.com'
```

### Start the stack

```bash
docker compose up -d
# Run initial migrations
docker compose exec psono-server python3 psono/manage.py migrate
# Create admin user
docker compose exec psono-server python3 psono/manage.py createadmin
```

## Upgrade procedure

Source: https://doc.psono.com/admin/maintenance/upgrade-server.html

```bash
docker compose pull
docker compose up -d
docker compose exec psono-server python3 psono/manage.py migrate
```

Always back up the database before upgrading:
```bash
docker compose exec db pg_dump -U psono psono > psono_backup_$(date +%Y%m%d).sql
```

**Critical:** Back up both PostgreSQL AND settings.yaml. The settings.yaml contains cryptographic secrets required to decrypt data in the database. Losing it means losing all stored passwords.

## Backup procedure

Source: https://gitlab.com/esaqa/psono/psono-server/-/blob/master/README.md

```bash
# Database backup
docker compose exec db pg_dump -U psono psono > backup_db_$(date +%Y%m%d).sql
# Settings backup
cp settings.yaml backup_settings_$(date +%Y%m%d).yaml
```

Schedule daily (crontab):
```
30 2 * * * /opt/psono/backup.sh
```

## Gotchas

- settings.yaml is your encryption key: Losing settings.yaml means all stored data is permanently unrecoverable. Store encrypted backups in multiple locations.
- Email is required: Users cannot activate accounts without working SMTP. Test SMTP before inviting anyone.
- Migrations on upgrade: Always run `manage.py migrate` after pulling new images — skipping this can corrupt the database schema.
- ALLOWED_HOSTS must match your domain: If the domain doesn't match, Django will reject all requests with 400 errors.
- File server is optional: psono-fileserver is a separate image for encrypted file attachments. Not needed for basic password storage.

## Links

- Docs: https://doc.psono.com/
- Install guide (CE): https://doc.psono.com/admin/installation/install-server-ce.html
- Upgrade guide: https://doc.psono.com/admin/maintenance/upgrade-server.html
- GitLab (server): https://gitlab.com/esaqa/psono/psono-server
- Docker Hub: https://hub.docker.com/r/psono/psono-server
- Demo: https://www.psono.pw
