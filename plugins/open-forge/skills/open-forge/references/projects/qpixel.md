---
name: qpixel
description: QPixel recipe for open-forge. Community Q&A and knowledge-sharing platform built with Ruby on Rails. Powers codidact.com. Supports multiple communities, categories, post types, voting, abilities, Markdown with MathJax, and image uploads. Source: https://github.com/codidact/qpixel
---

# QPixel

Community Q&A and knowledge-sharing software built with Ruby on Rails. Powers [codidact.com](https://codidact.com). Supports multiple communities and categories in one install, multiple post types (Q&A, articles, etc.), community-moderated abilities system, voting with controversy-aware scoring, Markdown + MathJax, image uploads, and custom content licenses. AGPL-licensed.

Upstream: <https://github.com/codidact/qpixel> | Docker README: <https://github.com/codidact/qpixel/blob/main/docker/README.md>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended path; upstream provides docker-compose.yml |
| Linux/macOS | Ruby on Rails (manual) | Ruby 3.1/3.2, MySQL, Redis, ImageMagick, libvips |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | SECRET_KEY_BASE | Generate: rake secret or openssl rand -hex 64 |
| config | Community name | Your site's community name (e.g. "My Stack Exchange") |
| config | Admin username, password, email | First admin account; password must be 6+ chars |
| config | MySQL root password, DB name, user, password | For the DB container |
| config | Port mapping | Default: 3000 |

## Software-layer concerns

### Architecture

- Rails app (`uwsgi` container) — serves the web UI + API
- MySQL (`db` container) — primary database
- Redis (`redis` container) — Action Cable (WebSocket), caching, background jobs

### Required env and config files

QPixel uses two files:

1. `.env` (project root) — Docker Compose variables (ports, community name, `CLIENT_DOCKERFILE`)
2. `docker/env` — container environment variables (DB credentials, admin user, `SECRET_KEY_BASE`)

Both are gitignored. The setup script creates them from templates.

Key `docker/env` variables:

| Var | Description |
|---|---|
| SECRET_KEY_BASE | Rails secret key (mandatory) |
| MYSQL_DATABASE | Database name |
| MYSQL_USER | DB user |
| MYSQL_PASSWORD | DB password |
| MYSQL_ROOT_PASSWORD | DB root password |
| COMMUNITY_ADMIN_USERNAME | First admin username |
| COMMUNITY_ADMIN_PASSWORD | First admin password (6+ chars) |
| COMMUNITY_ADMIN_EMAIL | First admin email |

Key `.env` variables:

| Var | Description |
|---|---|
| COMMUNITY_NAME | Display name for the initial community |
| PORT | Host port to map to container port 3000 |

## Install — Docker Compose (recommended)

```bash
git clone https://github.com/codidact/qpixel
cd qpixel

# Run setup script to create .env and docker/env from templates
chmod +x docker/local-setup.sh
docker/local-setup.sh

# Edit docker/env — set credentials and SECRET_KEY_BASE
# Edit .env — set COMMUNITY_NAME and PORT

# Build images
docker compose build

# Start (first run sets up DB + seeds)
docker compose up -d
```

App available at http://localhost:3000 (or your configured PORT).

Sign in with the `COMMUNITY_ADMIN_EMAIL` / `COMMUNITY_ADMIN_PASSWORD` you configured.

## Install — Manual (Rails)

Prerequisites (Debian/Ubuntu):
```bash
sudo apt update
sudo apt install gcc make pkg-config autoconf bison build-essential \
  libssl-dev libyaml-dev libreadline-dev zlib1g-dev libncurses5-dev \
  libffi-dev libgdbm-dev mysql-server libmysqlclient-dev \
  nodejs redis-server imagemagick libmagickwand-dev libvips
```

```bash
# Install Ruby 3.1 or 3.2 via RVM or rbenv
rvm install 3.2

git clone https://github.com/codidact/qpixel
cd qpixel

bundle install
yarn install

# Copy and configure database.yml
cp config/database.yml.example config/database.yml
# Edit config/database.yml with MySQL credentials

# Set SECRET_KEY_BASE in env
export SECRET_KEY_BASE=$(rails secret)
export RAILS_ENV=production

# Set up DB
rails db:create db:schema:load db:seed

# Start server
rails server -p 3000
```

## Upgrade procedure

Docker:
```bash
git pull
docker compose build
docker compose run --rm uwsgi rails db:migrate
docker compose up -d
```

Manual:
```bash
git pull
bundle install
yarn install
RAILS_ENV=production rails db:migrate
sudo systemctl restart qpixel
```

## Gotchas

- Admin password must be 6+ characters — shorter passwords silently prevent account creation on first-run seed.
- `docker/env` vs `.env` are separate files with separate purposes — `docker/env` sets container env vars; `.env` sets Docker Compose interpolation variables. Edit both to customize your deployment.
- The upstream docker-compose.yml is configured for development mode by default (`RAILS_ENV=development`). For production, set `CLIENT_DOCKERFILE=docker/Dockerfile` (production Dockerfile) in `.env` and ensure `SECRET_KEY_BASE` is set.
- Redis is required — Action Cable (real-time features) and background jobs will not work without it.
- Image uploads require ImageMagick and libvips — both must be installed in the container environment.
- Multiple communities in one install — the seeded initial community is created on first run. Additional communities are added via the admin panel.

## Links

- Upstream: https://github.com/codidact/qpixel
- Installation guide: https://github.com/codidact/qpixel/blob/main/INSTALLATION.md
- Docker setup: https://github.com/codidact/qpixel/blob/main/docker/README.md
- Live instance: https://codidact.com
