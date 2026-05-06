---
name: osem
description: Recipe for OSEM (Open Source Event Manager) — event management platform tailored to free software conferences. Call for Papers, scheduling, registration, and speaker management.
---

# OSEM — Open Source Event Manager

Event management platform designed for open source and free software conferences. Handles call for papers (CfP), talk submissions, speaker management, scheduling, and attendee registration. Upstream: <https://github.com/openSUSE/osem>. Website: <https://osem.io/>.

License: MIT. Platform: Ruby on Rails + PostgreSQL + Docker. Default port: `3000`.

Used by openSUSE, FOSDEM, and many other open source conferences.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended for evaluation and production |
| Ruby on Rails native | For development and customisation |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "PostgreSQL password?" | Replace the default `mysecretpassword` |
| network | "Public URL for OSEM (e.g. `https://osem.example.com`)?" | Used in Rails config |
| mail | "SMTP host, port, user, password for outgoing email?" | Required for CfP notifications and speaker comms |
| admin | "Admin email and initial password?" | Created on first run |

## Docker Compose

```bash
git clone https://github.com/openSUSE/osem.git
cd osem
```

Create `docker-compose.yml` (or use the one in the repo):
```yaml
services:
  database:
    image: postgres:16-alpine
    environment:
      PGDATA: /var/lib/postgresql/data/pgdata
      POSTGRES_PASSWORD: strongpassword
      POSTGRES_USER: osem
      POSTGRES_DB: osem_production
    volumes:
      - osem_db:/var/lib/postgresql/data

  osem:
    image: ghcr.io/opensuse/osem:latest
    command: foreman start -p 3000
    depends_on:
      - database
    ports:
      - "3000:3000"
    environment:
      OSEM_DB_HOST: database
      OSEM_DB_USER: osem
      OSEM_DB_PASSWORD: strongpassword
      OSEM_DB_NAME: osem_production
      SECRET_KEY_BASE: "$(openssl rand -hex 64)"
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
    volumes:
      - osem_uploads:/osem/public/uploads

volumes:
  osem_db:
  osem_uploads:
```

```bash
docker compose up -d

# Run database migrations
docker compose exec osem bundle exec rake db:migrate

# Seed initial data (creates admin account)
docker compose exec osem bundle exec rake db:seed
```

Web UI at `http://your-host:3000`. Log in with the seeded admin credentials.

## Building from source (development)

```bash
git clone https://github.com/openSUSE/osem.git
cd osem

# Install dependencies
bundle install

# Setup database (requires PostgreSQL running locally)
cp config/database.yml.example config/database.yml
# Edit database.yml with your credentials
bundle exec rake db:create db:migrate db:seed

# Start development server
bundle exec rails server -b 0.0.0.0
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | Environment variables + `config/` YAML files |
| Uploads | `public/uploads/` — persist this volume |
| Database | PostgreSQL 16 |
| Default port | `3000` |
| Rails env | Set `RAILS_ENV=production` for production |
| Secret key | `SECRET_KEY_BASE` must be set in production (use `bundle exec rake secret`) |
| Email | Configure via `config/environments/production.rb` or env vars |

## Upgrade procedure

```bash
git pull
docker compose pull
docker compose up -d
docker compose exec osem bundle exec rake db:migrate
```

## Gotchas

- **`SECRET_KEY_BASE` is required in production**: If not set, Rails will refuse to start with a security error. Generate with `openssl rand -hex 64`.
- **Static files**: In production without a CDN/webserver in front, set `RAILS_SERVE_STATIC_FILES=true` or configure nginx to serve `/public/`.
- **Database migrations required after upgrade**: Run `rake db:migrate` after every update.
- **v1.0 is from 2016**: The v1.0 release tag is old; track the `master` branch for current features. The project is actively maintained despite the old release tag.
- **Conference workflow**: OSEM has a multi-step workflow: create conference → open CfP → review submissions → schedule → publish. Familiarise yourself with the admin flow before running a real event.

## Upstream links

- Source: <https://github.com/openSUSE/osem>
- Demo: <https://osem.copyleft.dev>
- Install guide: <https://github.com/openSUSE/osem/blob/master/INSTALL.md>
