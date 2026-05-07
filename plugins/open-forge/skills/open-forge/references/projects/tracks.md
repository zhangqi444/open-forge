---
name: Tracks
description: Web-based Getting Things Done (GTD™) task management application built with Ruby on Rails. GPL-2.0.
website: https://www.getontracks.org/
source: https://github.com/TracksApp/tracks
license: GPL-2.0
stars: 1227
tags:
  - task-management
  - gtd
  - productivity
  - todo
platforms:
  - Ruby
---

# Tracks

Tracks is a web application implementing David Allen's Getting Things Done™ (GTD) methodology. It helps you capture tasks, organize them into projects and contexts, and work through them systematically. Built with Ruby on Rails, it's been continuously maintained since its creation.

Official site: https://www.getontracks.org/  
Source: https://github.com/TracksApp/tracks  
Manual: https://www.getontracks.org/manual/  
Latest release: v2.7.1 (July 2024)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker | Recommended; Docker Hub image available |
| Any Linux VM / VPS | Ruby 3.x + MySQL/PostgreSQL/SQLite | Native install via bundler |
| Shared hosting (limited) | Ruby-capable host | Possible but complex |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname
- Database type: MySQL, PostgreSQL, or SQLite
- Database credentials (host, user, password, database name) if not SQLite
- Secret key base (generate with `rails secret` or `openssl rand -hex 64`)
- Port to expose (default: `3000`)

**Phase: First Boot**
- Admin account: username, password, email (created via signup on first visit or `rake db:seed`)

## Software-Layer Concerns

**Docker (recommended):**
```bash
docker run -d \
  --name tracks \
  -p 3000:3000 \
  -e SECRET_TOKEN=$(openssl rand -hex 64) \
  -e DATABASE_URL=sqlite3:///db/tracks_production.db \
  -v tracks_data:/app/db \
  tracksapp/tracks:latest
```

**Docker with MySQL:**
```yaml
services:
  tracks:
    image: tracksapp/tracks:latest
    ports:
      - 3000:3000
    environment:
      SECRET_TOKEN: CHANGE_ME_64_HEX_CHARS
      DATABASE_URL: mysql2://tracks:CHANGE_ME@db/tracks
    volumes:
      - tracks_attachments:/app/public/system
    depends_on:
      - db

  db:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: tracks
      MYSQL_USER: tracks
      MYSQL_PASSWORD: CHANGE_ME
      MYSQL_ROOT_PASSWORD: CHANGE_ME_ROOT
    volumes:
      - tracks_db:/var/lib/mysql

volumes:
  tracks_db:
  tracks_attachments:
```

**Key environment variables:**
- `SECRET_TOKEN` — Rails secret key base (required; generate with `openssl rand -hex 64`)
- `DATABASE_URL` — Full DB connection URL (sqlite3, mysql2, or postgresql adapter)
- `RAILS_ENV` — Set to `production` (default in Docker image)

**Config files (native install):**
- `config/database.yml` — Database connection
- `config/site.yml` — Application settings (email, locale, etc.)

**Data paths:**
- SQLite DB: `db/` directory
- File attachments: `public/system/`

## Upgrade Procedure

1. Back up database and `public/system/` attachments
2. Pull new image: `docker pull tracksapp/tracks:latest`
3. `docker-compose down && docker-compose up -d`
4. Tracks runs `db:migrate` automatically on startup in Docker
5. For native installs: `bundle exec rake db:migrate RAILS_ENV=production`
6. Check release notes: https://github.com/TracksApp/tracks/releases

## Gotchas

- **GTD-specific**: Tracks is purpose-built for GTD methodology — if you want a general-purpose task manager, consider alternatives (Vikunja, Planka, etc.)
- **Ruby 3.x required**: Older Ruby versions not supported in recent releases
- **Email integration**: Tracks can receive tasks via email — requires configuring SMTP and IMAP settings in `config/site.yml`
- **Tickler system**: Tracks implements GTD's "tickler" (deferred tasks) — understand GTD concepts to use it effectively
- **REST API**: Tracks exposes a REST API for third-party integrations and mobile clients
- **Hosted option**: A hosted version (Taskitin.fi) is available from the principal maintainer if you prefer SaaS

## Links

- Upstream README: https://github.com/TracksApp/tracks/blob/master/README.md
- Installation wiki: https://github.com/TracksApp/tracks/wiki/Installation
- Manual: https://www.getontracks.org/manual/
- Releases: https://github.com/TracksApp/tracks/releases
