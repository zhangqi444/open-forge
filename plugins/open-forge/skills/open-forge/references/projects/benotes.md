---
name: Benotes
description: Open source self-hosted web app for notes and URL bookmarks side by side. Auto-fetches title, thumbnail, and description for saved URLs; supports Markdown and rich text; installable as a PWA. PHP/Lumen backend, PostgreSQL storage, Docker Compose deploy. MIT-licensed.
---

# Benotes

Benotes is a self-hosted notes-and-bookmarks app that treats links like first-class content. When you save a URL, Benotes automatically fetches the page title, description, and a thumbnail — so your bookmark collection looks like a content feed rather than a flat link list.

What makes Benotes distinctive:

- **Bookmarks with previews** — titles, descriptions, and images fetched from saved URLs automatically
- **Notes + bookmarks side by side** — mix quick notes and web links in the same workspace
- **Markdown + rich text editor** — choose your editing style per note
- **PWA installable** — install on mobile or desktop from any modern browser; supports native share target
- **Collections with public links** — share a curated list via a public URL without exposing the whole app
- **One-click paste-to-post** — paste a URL and it immediately becomes a new post
- **Daily backups** — automatic backup support built in
- **S3 or filesystem storage** — thumbnail storage is configurable

- Upstream repo: <https://github.com/fr0tt/benotes>
- Docker Hub: <https://hub.docker.com/r/fr0tt/benotes>
- Docker Compose repo: <https://github.com/fr0tt/benotes_docker-compose>
- Latest release: 2.8.2

## Architecture in one minute

- **PHP/Lumen app** — served by nginx inside a single container on port `80`
- **PostgreSQL** (default) or **MySQL** for the database
- Config via a `.env` file mounted into the container at `/var/www/.env`
- Named volume for storage (thumbnails, backups, logs)

## Compatible install methods

| Infra     | Runtime         | Notes                                              |
| --------- | --------------- | -------------------------------------------------- |
| Single VM | Docker Compose  | **Recommended** — prebuilt images on Docker Hub   |
| Any Linux | Classic PHP     | Composer + PHP 7.4+, documented on benotes.org     |

## Inputs to collect

| Input            | Example                | Phase       | Notes                                          |
| ---------------- | ---------------------- | ----------- | ---------------------------------------------- |
| App URL          | `http://192.168.1.10:8000` | Config  | Used to generate links; must be reachable URL  |
| App port         | `8000`                 | Network     | Host port for the web UI                       |
| DB password      | `strongpassword`       | Security    | Postgres password                              |
| APP_KEY          | 32-char random string  | Security    | Laravel app key — generate once, keep stable   |
| JWT_SECRET       | random string          | Security    | JWT signing secret                             |

## Install via Docker Compose

```bash
# 1. Download the compose files
wget https://raw.githubusercontent.com/fr0tt/benotes_docker-compose/master/docker-compose.yml
wget https://raw.githubusercontent.com/fr0tt/benotes_docker-compose/master/.env.example

# 2. Copy and edit the env file
cp .env.example .env
```

Edit `.env` — at minimum set these values:

```bash
APP_PORT=8000
APP_URL=http://YOUR_SERVER_IP:8000

APP_KEY=your_32_char_random_key_here
JWT_SECRET=another_random_secret_here

DB_PASSWORD=your_strong_db_password
```

```yaml
# docker-compose.yml (from benotes_docker-compose repo)
services:
  app:
    container_name: benotes_app
    image: fr0tt/benotes:latest
    restart: unless-stopped
    environment:
      DB_CONNECTION: ${DB_CONNECTION}
    ports:
      - ${APP_PORT}:80
    volumes:
      - .env:/var/www/.env
      - benotes_storage:/var/www/storage
    networks:
      - benotes

  db:
    container_name: benotes_db
    image: postgres:15.2-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DATABASE: ${DB_DATABASE}
      POSTGRES_USER: ${DB_USERNAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - benotes_postgres:/var/lib/postgresql/data
    networks:
      - benotes

networks:
  benotes:
    driver: bridge

volumes:
  benotes_storage:
  benotes_postgres:
```

```bash
# 3. Start the stack
docker compose up -d

# 4. Initialize the database and create admin account
docker compose exec --user application app sh
php artisan install
# Follow the prompts; type 'yes' when asked
exit
```

Open `http://localhost:8000` (or your `APP_PORT`).

## Upgrading

```bash
docker compose pull && docker compose up -d
```

## Key .env settings

| Variable                      | Description                                            |
| ----------------------------- | ------------------------------------------------------ |
| `APP_URL`                     | Public URL of the app (used for link generation)       |
| `APP_KEY`                     | Laravel encryption key — generate once, never change   |
| `JWT_SECRET`                  | JWT signing secret                                     |
| `GENERATE_MISSING_THUMBNAILS` | `true` to auto-fetch thumbnails when saving URLs       |
| `USE_FILESYSTEM`              | `true` to store thumbnails on disk (vs. S3)            |
| `RUN_BACKUP`                  | `true` to enable daily automated backups               |
| `DB_CONNECTION`               | `pgsql` (default) or `mysql`                           |

## Notes

- `APP_KEY` must be set before first run — once set, never rotate it (it's used to encrypt data in the database)
- The `.env` file is mounted into the container; editing it and restarting applies changes
- Data lives in the named Docker volumes — use `docker volume inspect` to find their location for backups
