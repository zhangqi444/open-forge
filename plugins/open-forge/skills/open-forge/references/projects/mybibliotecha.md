---
name: mybibliotecha
description: MyBibliotheca recipe for open-forge. Self-hosted personal library and reading tracker — open-source alternative to Goodreads/StoryGraph. MIT license. Docker Compose deploy with KuzuDB (graph database). Upstream: https://github.com/pickles4evaaaa/mybibliotheca
---

# MyBibliotheca

Self-hosted personal library and reading tracker. Add books by ISBN (auto-fetches metadata via Google Books API), track reading progress and daily sessions, log streaks, and generate monthly reading wrap-ups. Multi-user with admin management, data isolation, and OAuth support. MIT license. Upstream: <https://github.com/pickles4evaaaa/mybibliotheca>.

> **Note:** The project README states it is "Currently NOT Maintained" as of the last upstream update. It remains functional and documented but may not receive active bug fixes. Consider this before deploying for critical use.

## Compatible install methods

| Method | Upstream source | When to use |
|---|---|---|
| Docker Compose (build from source) | <https://github.com/pickles4evaaaa/mybibliotheca/blob/main/docker-compose.yml> | Primary method — builds local image. |
| Docker Hub beta image | <https://hub.docker.com/r/pickles4evaaaa/mybibliotheca> | Use pre-built beta image (tag: `beta-latest`) instead of building. |

## Requirements

- Docker + Docker Compose
- `.env` file with `SECRET_KEY` and `SECURITY_PASSWORD_SALT`

## Method — Docker Compose

> **Source:** <https://github.com/pickles4evaaaa/mybibliotheca/blob/main/docker-compose.yml>

### 1 — Clone repository

```bash
git clone https://github.com/pickles4evaaaa/mybibliotheca.git
cd mybibliotheca
```

### 2 — Create `.env` file

```env
SECRET_KEY=<generate-a-long-random-string>
SECURITY_PASSWORD_SALT=<generate-another-long-random-string>

# Optional settings
SITE_NAME=MyBibliotheca
TIMEZONE=UTC
LOG_LEVEL=INFO
MYBIBLIOTHECA_VERBOSE_INIT=false
```

Generate secrets:
```bash
openssl rand -hex 32   # run twice — once for SECRET_KEY, once for SECURITY_PASSWORD_SALT
```

### 3 — Start (build from source)

```bash
docker compose up -d --build
```

Or use the pre-built beta image — edit `docker-compose.yml` to replace the `build: .` line:
```yaml
services:
  bibliotheca:
    image: pickles4evaaaa/mybibliotheca:beta-latest
```

Then:
```bash
docker compose up -d
```

### 4 — Access

Open `http://<host>:5054`. The setup wizard creates the first admin account.

### Updating

For source builds:
```bash
git pull
docker compose up -d --build
```

For beta image:
```bash
docker compose pull && docker compose up -d
```

## Key environment variables

| Variable | Required | Default | Notes |
|---|---|---|---|
| `SECRET_KEY` | ✅ | — | Flask session signing key. Generate with `openssl rand -hex 32`. |
| `SECURITY_PASSWORD_SALT` | ✅ | — | Password hash salt. Generate separately from `SECRET_KEY`. |
| `SITE_NAME` | ✗ | `MyBibliotheca` | Display name for the app. |
| `TIMEZONE` | ✗ | `UTC` | Used for reading log timestamps. |
| `WORKERS` | ✗ | `1` | **Must stay at `1`** — KuzuDB does not support concurrent writers. |
| `LOG_LEVEL` | ✗ | `INFO` | `DEBUG` / `INFO` / `WARNING` / `ERROR`. |
| `AUTO_MIGRATE` | ✗ | `false` | Set `true` to auto-run DB migrations on startup (risky — back up first). |

## Data volumes

| Mount | Purpose |
|---|---|
| `./data:/app/data` | KuzuDB database files, book covers, and user uploads. Back this up. |

> **macOS note:** Do NOT bind-mount the `static` directory on macOS — Docker Desktop's osxfs can cause deadlocks when Gunicorn serves static files. Static assets are baked into the image.

## Features overview

- **Book catalog** — add by ISBN (Google Books API) or manual entry; bulk import from Goodreads CSV.
- **Reading states** — Currently Reading, Plan to Read, Finished, Library Only.
- **Reading logs** — daily sessions with pages, time, and notes; streaks tracking.
- **Monthly wrap-ups** — shareable image summary of finished books.
- **Multi-user** — user data isolation; admin panel for user management.
- **KuzuDB graph DB** — relationship queries between books, authors, genres.

## Ports

| Port | Service |
|---|---|
| 5054 | MyBibliotheca web UI (HTTP) |

## License

MIT — <https://github.com/pickles4evaaaa/mybibliotheca/blob/main/LICENSE>
