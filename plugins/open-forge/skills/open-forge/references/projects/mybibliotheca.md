# MyBibliotheca

**What it is:** Self-hosted personal library and reading tracker — open-source alternative to Goodreads, StoryGraph, and Fable. Log books by ISBN (auto-fetches cover and metadata), track reading progress, log daily reading sessions, generate monthly reading wrap-up images, and bulk import from Goodreads CSV. Multi-user with admin management. Powered by KuzuDB graph database.

**Docs:** https://mybibliotheca.org  
**GitHub:** https://github.com/pickles4evaaaa/mybibliotheca  
**Docker Hub:** `pickles4evaaaa/mybibliotheca`

> ⚠️ **Maintenance status:** Currently not actively maintained. Back up data before upgrading. API/data stability not guaranteed.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; build from source or use beta image |
| Bare metal | Python | Flask/Gunicorn app |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Flask secret key — generate a random string |
| `SECURITY_PASSWORD_SALT` | Salt for password hashing — generate a random string |
| `SITE_NAME` | Display name for the instance (default `MyBibliotheca`) |
| `TIMEZONE` | Timezone string (default `UTC`) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `LOG_LEVEL` | Logging verbosity |
| `MYBIBLIOTHECA_VERBOSE_INIT` | Verbose startup logging (default `false`) |

---

## Software-Layer Concerns

- **KuzuDB graph database** — stores all data at `KUZU_DB_PATH` (`/app/data/kuzu`); persists in `./data` volume
- **CRITICAL: `WORKERS` must be `"1"`** — KuzuDB requires single-worker mode; multiple Gunicorn workers will corrupt the database
- **Data volume `./data`** — contains KuzuDB database and backups; mount this volume for persistence
- **Do NOT bind-mount `static/` directory on macOS** — Docker Desktop's osxfs can cause EDEADLK deadlocks; static files are baked into the image
- **Google Books API** used for book search and metadata fetching — no API key required for basic use
- **Multi-user:** Each user has isolated book data; admin panel for user management

### Pre-built vs. build from source

| Option | How |
|--------|-----|
| Build from source (default) | `build: .` in compose — builds image locally |
| Beta pre-built image | Use `image: pickles4evaaaa/mybibliotheca:beta-latest` instead |

---

## Example Docker Compose

```yaml
services:
  bibliotheca:
    image: pickles4evaaaa/mybibliotheca:beta-latest
    ports:
      - "5054:5054"
    volumes:
      - ./data:/app/data
    environment:
      SECRET_KEY: ${SECRET_KEY}
      SECURITY_PASSWORD_SALT: ${SECURITY_PASSWORD_SALT}
      KUZU_DB_PATH: /app/data/kuzu
      GRAPH_DATABASE_ENABLED: "true"
      SITE_NAME: MyBibliotheca
      TIMEZONE: UTC
      WORKERS: "1"
```

---

## Upgrade Procedure

1. **Back up `./data` directory** before upgrading (especially the KuzuDB files)
2. Pull new image or rebuild: `docker compose pull` / `docker compose build`
3. Restart: `docker compose up -d`
4. Check logs for migration output

---

## Gotchas

- **`WORKERS: "1"` is mandatory** — multiple workers with KuzuDB will cause data corruption
- **Unmaintained project** — no guarantees on future updates, bug fixes, or security patches; evaluate carefully before use
- **Data backup is critical** — KuzuDB does not have the same battle-tested track record as PostgreSQL/SQLite; back up `./data` regularly
- **Do not mount `static/` on macOS** Docker Desktop — deadlock risk (use beta image instead)
- `SECRET_KEY` and `SECURITY_PASSWORD_SALT` must be set before first run; changing them after users are created will invalidate all sessions

---

## Links

- Docs: https://mybibliotheca.org
- GitHub: https://github.com/pickles4evaaaa/mybibliotheca
- Docker Hub: https://hub.docker.com/repository/docker/pickles4evaaaa/mybibliotheca
