---
name: Koillection
description: "Self-hosted collection manager for physical items. Docker. PHP/Symfony + PostgreSQL/MySQL/MariaDB. benjaminjonard/koillection. Track books, games, DVDs, stamps — any collection; custom scrapers; multi-language. MIT."
---

# Koillection

**Self-hosted collection manager for physical items.** Track any kind of physical collection — books, DVDs, games, stamps, figures, vinyl records, or anything else. Organize items into collections, add metadata and images, write custom HTML scrapers to populate metadata automatically, and browse with filtering. No pre-built metadata sources (by design) — you control what data to track.

Built + maintained by **benjaminjonard**. MIT license.

- Upstream repo: <https://github.com/benjaminjonard/koillection>
- Install wiki: <https://github.com/koillection/koillection/wiki/Installation>
- Demo: Gitpod ephemeral demo available (see README)
- Docker Hub: <https://hub.docker.com/r/koillection/koillection>

## Architecture in one minute

- **PHP / Symfony** backend
- **PostgreSQL** (recommended), **MySQL 8+**, or **MariaDB 10+**
- Docker Compose: `koillection` + database containers
- Port: configured in Docker (maps to container port 80 or 443)
- Supports **HTTPS** natively (configure cert in env vars)
- Resource: **low-medium** — PHP + DB

## Compatible install methods

| Infra              | Runtime                      | Notes                                                         |
| ------------------ | ---------------------------- | ------------------------------------------------------------- |
| **Docker Compose** | `koillection/koillection`    | **Recommended** — see install wiki                            |
| **FrankenPHP**     | experimental Docker variant  | Docker with FrankenPHP (experimental)                         |
| **Manual**         | PHP + Symfony + web server   | See manual install wiki                                       |

## Inputs to collect

| Input                       | Example               | Phase    | Notes                                                     |
| --------------------------- | --------------------- | -------- | --------------------------------------------------------- |
| `APP_SECRET`                | random string         | Security | Symfony app secret; generate with `openssl rand -hex 32` |
| Database credentials        | user, password, name  | DB       | PostgreSQL/MySQL/MariaDB                                  |
| `APP_TIMEZONE`              | `Europe/Paris`        | Config   | Your timezone                                             |
| `APP_HTTPS`                 | `0` or `1`            | TLS      | Enable HTTPS; set to `1` with cert volume mounts          |
| Upload dir                  | `./uploads:/www/public/uploads` | Storage | Where item images are stored |

## Install via Docker Compose (PostgreSQL)

See full example at: <https://github.com/koillection/koillection/wiki/docker-installation>

Example skeleton:

```yaml
services:
  koillection:
    image: koillection/koillection:latest
    container_name: koillection
    ports:
      - "80:80"
    depends_on:
      - db
    environment:
      - APP_ENV=prod
      - APP_SECRET=change_this_random_secret
      - DB_DRIVER=pdo_pgsql
      - DB_HOST=db
      - DB_PORT=5432
      - DB_NAME=koillection
      - DB_USER=koillection
      - DB_PASSWORD=changeme
      - APP_TIMEZONE=UTC
      - APP_HTTPS=0
      - THUMBNAILS_NATIVELY=0
    volumes:
      - ./uploads:/www/public/uploads
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: koillection
      POSTGRES_USER: koillection
      POSTGRES_PASSWORD: changeme
    volumes:
      - pg_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  pg_data:
```

Refer to the wiki for the complete, up-to-date compose file with all environment variables.

## First boot

1. Set `APP_SECRET` and DB credentials before starting.
2. `docker compose up -d`.
3. Visit `http://localhost`.
4. Register the first user (admin).
5. Create your first **Collection** (e.g. "Games", "Books").
6. Add **Items** to the collection — fill in fields, upload images.
7. Optionally configure a **Scraper** (custom HTML scraper) to auto-populate metadata from a website.
8. Browse, filter, and organize your collections.
9. Put behind TLS.

## Collections and items

- **Collections** — top-level groupings (e.g. "Video Games", "Vinyl Records", "Stamps")
- **Items** — individual entries within a collection; each has configurable metadata fields + images
- **Wishlists** — track items you want to acquire
- **Tags** — cross-collection labels
- **Custom fields** — define your own metadata schema per collection

## Scrapers

Koillection lets you write custom HTML scrapers (XPath/CSS selectors) to pull metadata from any website into your items. Example: scrape a game database website to populate game title, developer, year, and cover automatically.

See scraping wiki: <https://github.com/koillection/koillection/wiki/Scraping>

## Translations

Koillection is translated into 11 languages: English, French, German, Dutch, Spanish, Italian, Portuguese (BR), Portuguese (PT), Polish, Russian, Chinese Simplified.

## Gotchas

- **No pre-built metadata providers.** Koillection doesn't connect to IGDB, Discogs, Open Library, or any metadata service out of the box. This is intentional — you build custom scrapers for the sources you want, or add metadata manually. It keeps the app generic but requires more setup.
- **Back up before every update.** The README explicitly warns: "Please back up your database, especially when updating to a new version." Major versions may include data migrations.
- **`APP_SECRET` required.** Symfony uses this for cryptographic operations (CSRF tokens, cookies). Use a long random string and keep it constant (changing it invalidates sessions and tokens).
- **Uploads volume.** Item images are stored in `./uploads`. This must be a persistent volume — losing it means losing all item images.
- **Default branch is `1.8` (not `main` or `master`).** The GitHub default branch is a version branch. Pull Docker images from Docker Hub rather than building from source unless you need the latest development version.
- **`THUMBNAILS_NATIVELY`** — set to `1` to generate thumbnails using native PHP GD (slower); `0` uses a more performant method if available. For small installs, `0` is fine.
- **Multi-user is personal scope.** Koillection is designed for personal or household use — one admin user managing collections. Multi-user in the sense of separate accounts with separate collections is not the primary use case.

## Backup

```sh
docker compose stop koillection
docker compose exec db pg_dump -U koillection koillection > koillection-$(date +%F).sql
sudo tar czf koillection-uploads-$(date +%F).tgz uploads/
docker compose start koillection
```

## Upgrade

1. **Back up DB first** (see above).
2. `docker compose pull && docker compose up -d`.
3. Koillection runs DB migrations automatically on startup.

## Project health

Active PHP/Symfony development, Docker Hub, 11 languages (Crowdin), custom scrapers, Docker + FrankenPHP + manual install. Solo-maintained by benjaminjonard. MIT license.

## Collection-manager-family comparison

- **Koillection** — PHP+Symfony, any physical item, custom scrapers, 11 languages, no built-in metadata APIs, MIT
- **Grocy** — PHP, household management (food + consumables + tasks); different scope but overlaps for tracking physical items
- **Obsidian** — Markdown notes; can model collections but no purpose-built UI
- **Discogs** — SaaS, vinyl/music records; not self-hosted
- **IGDB** — game metadata API; not self-hosted

**Choose Koillection if:** you want a self-hosted tracker for any physical collection (books, games, stamps, figures) where you control the metadata schema and can build custom scrapers.

## Links

- Repo: <https://github.com/benjaminjonard/koillection>
- Install wiki: <https://github.com/koillection/koillection/wiki/Installation>
- Docker Hub: <https://hub.docker.com/r/koillection/koillection>
- Scraping guide: <https://github.com/koillection/koillection/wiki/Scraping>
