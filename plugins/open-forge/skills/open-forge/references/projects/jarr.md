# JARR

**Web-based RSS news aggregator and reader** — Just Another RSS Reader. Fork of Newspipe. Distinguishing feature: article **clustering** by similar links or content (TF-IDF). Docker-based deployment with separate server and worker containers.

**Official site:** https://1pxsolidblack.pl/jarr-en.html  
**Source:** https://github.com/jaesivsm/JARR  
**Official instance:** https://app.jarr.info  
**Demo API:** https://api.jarr.info  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose | Primary install method |

---

## System Requirements

- Docker + Docker Compose
- PostgreSQL
- Python + pipenv (for build/CLI steps)

---

## Inputs to Collect

| Input | Description | Default |
|-------|-------------|---------|
| PostgreSQL host / db / user / password | Database connection | — |
| `API_URL` | Public URL of the JARR API | — |
| Admin credentials | First user (default: `admin`/`admin`) | `admin`/`admin` |

---

## Software-layer Concerns

### Docker Compose install
```bash
git clone https://github.com/jaesivsm/JARR.git
cd JARR

# Install pipenv dependencies (required for build steps)
pip install pipenv
pipenv sync --dev

# Build the base image
make build-base

# Copy and configure the example compose file
cp Dockerfiles/prod-example.yml Dockerfiles/my-compose.yml
# Edit my-compose.yml: set DB connection, API URL, storage paths

# Start services
make start-env COMPOSE_FILE=Dockerfiles/my-compose.yml

# Initialize database
make db-bootstrap-user COMPOSE_FILE=Dockerfiles/my-compose.yml
make db-bootstrap-tables COMPOSE_FILE=Dockerfiles/my-compose.yml
make init-env-docker COMPOSE_FILE=Dockerfiles/my-compose.yml
```

Access at `http://localhost:8501/` — default login: `admin` / `admin`.

### Services in the stack
| Service | Purpose |
|---------|---------|
| `jarr-server` | API server (Python/Flask) |
| `jarr-worker` | Background feed fetching and processing |
| `jarr-front` | Web frontend |
| `postgresql` | Database |
| Redis (optional) | Caching |

### Start the feed scheduler
```bash
docker compose --file Dockerfiles/my-compose.yml exec jarr-worker pipenv run python3 -c "from jarr.crawler.main import scheduler; scheduler()"
```

### Article clustering
JARR groups similar articles using:
- **Link clustering** — same URL across multiple feeds
- **Content clustering** — TF-IDF similarity between article bodies

This reduces duplicate coverage of the same story across different sources.

---

## Upgrade Procedure

```bash
git pull
make build-base
make start-env COMPOSE_FILE=Dockerfiles/my-compose.yml
```
Run database migrations after pulling new code.

---

## Gotchas

- **Frontend must be rebuilt** with your API URL — the default `jaesivsm/jarr-front` image is built pointing to the production server (`app.jarr.info`). See the INSTALL.md for rebuild instructions.
- **pipenv required** even for Docker deployments — build steps use Python scripts.
- **Default `admin`/`admin` credentials must be changed** before exposing to the internet.
- **PostgreSQL address in `jarr.json`** must be set to `"postgresql"` (the service name) when using Docker Compose — the installer will fail if left at the default.
- **Scheduler must be started manually** after initial setup (see above).

---

## References

- Install guide: https://github.com/jaesivsm/JARR/blob/master/INSTALL.md
- Upstream README: https://github.com/jaesivsm/JARR#readme
