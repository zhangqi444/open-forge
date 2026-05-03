---
name: hymnoscribe-project
description: Tool for creating church service hymn sheets (Liedblätter) with drag-and-drop interface and PDF export. Docker + MySQL. Upstream: https://github.com/Revisor01/HymnoScribe
---

# HymnoScribe

Comprehensive tool for creating church service hymn sheets (Liedblätter). Provides a drag-and-drop interface for assembling services from hymns, prayers, readings, and other elements, then generates PDF output in multiple formats (A5, DIN Lang, A4, A3). Multi-user with role-based permissions. Upstream: <https://github.com/Revisor01/HymnoScribe>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose + MySQL | [GitHub README](https://github.com/Revisor01/HymnoScribe#docker-compose-setup) | ✅ | Recommended |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| config | App URL (`URL` env var) | URL | All |
| config | Frontend URL (`FRONTEND_URL`) | URL | All |
| config | MySQL root password | string | All |
| config | MySQL user/password for app | string | All |
| config | JWT secret | string | All |
| config | Super admin password (`SUPER_PASSWORD`) | string | All |
| config | Email SMTP settings (optional) | string | Optional |
| config | Port to expose (default 9615) | number | All |

## Docker Compose install

Source: <https://github.com/Revisor01/HymnoScribe>

```yaml
version: '3'
services:
  hymnoscribe:
    image: revisoren/hymnoscribe:latest
    ports:
      - "9615:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=db
      - DB_USER=${DB_USER:-hymnoscribe}
      - DB_PASSWORD=${DB_PASSWORD:-hymnoscribe9715}
      - DB_NAME=${DB_NAME:-hymnoscribe}
      - URL=${URL}
      - SUPER_PASSWORD=${SUPER_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - EMAIL_HOST=${EMAIL_HOST}
      - EMAIL_PORT=${EMAIL_PORT}
      - EMAIL_USER=${EMAIL_USER}
      - EMAIL_PASS=${EMAIL_PASS}
      - EMAIL_FROM=${EMAIL_FROM}
      - FRONTEND_URL=${FRONTEND_URL}
    volumes:
      - ./backend/uploads:/app/backend/uploads
      - ./migrations:/app/migrations
    command: sh -c "/app/run-migrations.sh && node server.js"
    depends_on:
      - db

  db:
    image: mysql:9.0
    volumes:
      - ./hymnoscribe_db:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-hymnoscribe9715}
      MYSQL_DATABASE: ${DB_NAME:-hymnoscribe}
      MYSQL_USER: ${DB_USER:-hymnoscribe}
      MYSQL_PASSWORD: ${DB_PASSWORD:-hymnoscribe9715}

volumes:
  hymnoscribe_db:
```

1. Clone the repository: `git clone https://github.com/Revisor01/HymnoScribe.git && cd HymnoScribe`
2. Create a `.env` file from `example.env` and fill in your values.
3. Run: `docker-compose up -d`
4. App available at `http://localhost:9615`

## Configuration

| Variable | Description |
|---|---|
| `URL` | Backend URL (e.g. `https://hymnoscribe.example.com`) |
| `FRONTEND_URL` | Frontend URL (may differ behind reverse proxy) |
| `SUPER_PASSWORD` | Password for the super-admin account |
| `JWT_SECRET` | Random secret for JWT signing |
| `EMAIL_*` | SMTP settings for email verification and password reset |
| `DB_*` | MySQL connection settings |

Data volumes:
- `./backend/uploads` — uploaded images and logos
- `./hymnoscribe_db` — MySQL data
- `./migrations` — database migration scripts

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Migrations run automatically on startup via `run-migrations.sh`.

## Gotchas

- Requires MySQL 9.0 — PostgreSQL is not supported.
- `init.sql` must exist in the repo root before first launch.
- Set `FRONTEND_URL` correctly when running behind a reverse proxy.
- Email verification and password reset require SMTP configuration.
- Private use is free; church/community use requests a €5/month contribution for hosted plans.

## References

- GitHub: <https://github.com/Revisor01/HymnoScribe>
- Demo: <https://app.hymnoscribe.de> (admin/demoAdmin, user/demoUser)
