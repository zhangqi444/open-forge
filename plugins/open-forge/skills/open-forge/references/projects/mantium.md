# Mantium

> Cross-site manga tracker — follow manga across MangaDex, MangaPlus, MangaHub, MangaUpdates, RawKuma, and more from a single dashboard. Tracks metadata and chapter availability (does not download images). Embeddable iFrame for external dashboards.

**Official URL:** https://github.com/diogovalentte/mantium

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; includes PostgreSQL |
| Any Linux VPS/VM | Go binary + Postgres | Manual install |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `POSTGRES_HOST` | PostgreSQL hostname | `http://localhost` or `db` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_DB` | Database name | `postgres` |
| `POSTGRES_USER` | PostgreSQL username | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL password | strong password |
| `API_PORT` | API server port | `8080` |
| `API_ADDRESS` | Full API URL (used for iFrame links) | `http://yourserver:8080` |

---

## Software-Layer Concerns

### Docker Compose Setup
```bash
# 1. Clone or create your docker-compose.yml from the repo template
git clone https://github.com/diogovalentte/mantium
cd mantium

# 2. Create .env from example
cp .env.example .env
# Edit .env with your values

# 3. Start
docker compose up -d
```

### Minimal docker-compose.yml
```yaml
services:
  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_PORT=5432
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=yourpassword
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  mantium:
    image: ghcr.io/diogovalentte/mantium:latest
    environment:
      - POSTGRES_HOST=http://db
      - POSTGRES_PORT=5432
      - POSTGRES_DB=postgres
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=yourpassword
      - API_PORT=8080
      - API_ADDRESS=http://yourserver:8080
    ports:
      - "8080:8080"
    depends_on:
      - db

volumes:
  postgres_data:
```

### Key Environment Variables
| Variable | Description |
|----------|-------------|
| `POSTGRES_HOST` | Full URL to PostgreSQL host (include `http://`) |
| `POSTGRES_PORT` | PostgreSQL port |
| `POSTGRES_DB` | Database name |
| `POSTGRES_USER` | DB username |
| `POSTGRES_PASSWORD` | DB password |
| `API_PORT` | Port the API listens on (default: `8080`) |
| `API_ADDRESS` | Full external URL; used for iFrame embed links |

### Ports
- API + web UI: `8080` (configurable via `API_PORT`)
- Can also run on [Docker host network mode](https://docs.docker.com/network/drivers/host/) instead of port mapping

### Data Directories
| Path | Purpose |
|------|---------|
| `postgres_data` volume | All manga metadata — back this up |

### iFrame Embedding
The `/iframe` endpoint returns a minimal view showing unread chapters for manga with status "reading" or "completed". Embed in Homer, Homepage, or similar dashboards.

### Custom Manga
For sites not natively supported, the Custom Manga feature lets you manually define the manga URL pattern; Mantium will check for new chapters via configurable scraping rules.

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d` — database migrations run automatically on startup
4. Check logs: `docker compose logs -f mantium`

---

## Gotchas

- **`POSTGRES_HOST` requires `http://` prefix** — the README shows the full URL format (e.g. `http://localhost`), not just a hostname; omitting the protocol may cause connection failures
- **`API_ADDRESS` for iFrame** — must be the externally reachable URL; iFrame links embed this address, so if it's wrong, linked chapters won't open correctly
- **No image downloads** — Mantium only tracks metadata and chapter availability; you still read chapters on the source site
- **Chapter polling** — configure check intervals (e.g. every 30 minutes) in the settings; too-frequent polling may result in rate limiting by source sites
- **External site availability** — if a source site (e.g. RawKuma, KLManga) changes its structure or goes down, that source's tracking may break until Mantium is updated

---

## Links
- GitHub: https://github.com/diogovalentte/mantium
- .env example: https://github.com/diogovalentte/mantium/blob/main/.env.example
