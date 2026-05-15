# Redmine

Redmine is a flexible, open-source project management and issue tracking web application written in Ruby on Rails. It supports multiple projects, role-based access control, Gantt charts, calendars, wikis, forums, and integrates with version control systems (Git, SVN, Mercurial).

**Official site:** https://www.redmine.org  
**GitHub:** https://github.com/redmine/redmine  
**Upstream README:** https://github.com/redmine/redmine/blob/master/README.rdoc  
**Docker Hub:** https://hub.docker.com/_/redmine  
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker Compose + PostgreSQL | Recommended |
| Any Linux VM / VPS | Docker Compose + MySQL/MariaDB | Alternative DB |
| Kubernetes | Bitnami Helm chart | `bitnami/redmine` |
| Bare metal | Ruby on Rails / Passenger | Official install guide |

---

## Inputs to Collect

### Before deployment
- Database: PostgreSQL (recommended) or MySQL/MariaDB
- `REDMINE_DB_PASSWORD` — database password
- `REDMINE_DB_DATABASE` — database name (default: `redmine`)
- `REDMINE_DB_USERNAME` — database user (default: `redmine`)
- `REDMINE_SECRET_KEY_BASE` — secret key for sessions (generate with `openssl rand -hex 64`)
- Domain / base URL (for email links and attachments)
- SMTP settings (optional but recommended for notifications)

---

## Software-Layer Concerns

### Docker Compose

```yaml
version: "3.8"
services:
  redmine:
    image: redmine:6.1.2
    container_name: redmine
    environment:
      REDMINE_DB_POSTGRES: db
      REDMINE_DB_USERNAME: redmine
      REDMINE_DB_PASSWORD: ${REDMINE_DB_PASSWORD:-changeme}
      REDMINE_DB_DATABASE: redmine
      REDMINE_SECRET_KEY_BASE: ${REDMINE_SECRET_KEY_BASE}
    volumes:
      - redmine_files:/usr/src/redmine/files
      - redmine_plugins:/usr/src/redmine/plugins
      - redmine_themes:/usr/src/redmine/public/themes
    ports:
      - "3000:3000"
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    container_name: redmine_db
    environment:
      POSTGRES_DB: redmine
      POSTGRES_USER: redmine
      POSTGRES_PASSWORD: ${REDMINE_DB_PASSWORD:-changeme}
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  redmine_files:
  redmine_plugins:
  redmine_themes:
  db_data:
```

### Key directories (in container)
| Path | Purpose |
|------|---------|
| `/usr/src/redmine/files` | Uploaded attachments |
| `/usr/src/redmine/plugins` | Custom plugins |
| `/usr/src/redmine/public/themes` | Custom themes |
| `/usr/src/redmine/config/configuration.yml` | Email / storage config (mount to override) |

### Ports
| Port | Purpose |
|------|---------|
| 3000 | HTTP (proxy with nginx/Caddy) |

### Email configuration
Mount a `configuration.yml` to `/usr/src/redmine/config/configuration.yml`:
```yaml
default:
  email_delivery:
    delivery_method: :smtp
    smtp_settings:
      address: smtp.example.com
      port: 587
      domain: example.com
      user_name: user@example.com
      password: secret
      authentication: :login
      enable_starttls_auto: true
```

### Default admin credentials
- Username: `admin`
- Password: `admin`
- **Change immediately** after first login

---

## Upgrade Procedure

1. Back up the database: `pg_dump redmine > redmine_backup.sql`
2. Back up files volume
3. Pull new image: `docker pull redmine:latest` (or pin to a specific version tag)
4. Stop and restart: `docker compose down && docker compose up -d`
5. Redmine runs database migrations automatically on startup
6. Check logs: `docker logs redmine`

---

## Gotchas

- **Plugin compatibility** — plugins must match the Redmine version; upgrading Redmine may break plugins; test in staging first
- **Attachment storage** — the `files` volume is critical; back it up alongside the database
- **Ruby version constraints** — bare-metal installs are sensitive to Ruby version; use the Docker image to avoid this
- **Email notifications** — without SMTP configured, users won't receive issue updates; set up email early
- **Default `admin/admin`** — change the admin password immediately; Redmine does not force a change on first login
- **Slow on small VPS** — Ruby on Rails apps are memory-hungry; budget at least 1–2 GB RAM for the app

---

## Links

- Redmine guide: https://www.redmine.org/guide
- Docker Hub: https://hub.docker.com/_/redmine
- Plugin directory: https://www.redmine.org/plugins
- Themes: https://www.redmine.org/themes
