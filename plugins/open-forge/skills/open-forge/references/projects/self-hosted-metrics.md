# Self-Hosted Metrics (SHM)

> Privacy-first telemetry server for self-hosted software developers — collect aggregate usage stats and version adoption from your distributed instances without ever seeing user content. Instances authenticate with Ed25519 keypairs; you get a dynamic dashboard and embeddable SVG badges.

**Official URL:** https://self-hosted-metrics.com  
**GitHub:** https://github.com/kOlapsis/shm

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; includes PostgreSQL |
| Any Linux VPS/VM | Binary (Go) | Single Go binary + separate Postgres |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DB_PASSWORD` | PostgreSQL password | strong random string |
| `PORT` | HTTP server port | `8080` |

### Phase: Optional
| Input | Description | Example |
|-------|-------------|---------|
| `GITHUB_TOKEN` | GitHub PAT to fetch star counts at higher rate limit (5000/h vs 60/h) | `ghp_...` |

---

## Software-Layer Concerns

### Architecture
- **Server** (this recipe): Go binary + embedded UI + PostgreSQL — deployed once centrally
- **SDK** (client-side): Go library embedded in your own apps that signs and ships telemetry snapshots to the server
- The server is what you self-host; the SDK is what you add to the software you distribute

### Docker Compose Setup
```yaml
name: shm
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: shm
      POSTGRES_PASSWORD: ${DB_PASSWORD:-change-me}
      POSTGRES_DB: metrics
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shm -d metrics"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ghcr.io/kolapsis/shm:latest
    depends_on:
      db:
        condition: service_healthy
    environment:
      SHM_DB_DSN: "postgres://shm:${DB_PASSWORD:-change-me}@db:5432/metrics?sslmode=disable"
      PORT: "8080"
    ports:
      - "8080:8080"

volumes:
  postgres_data:
```

### Migrations
Must be downloaded before first run:
```bash
mkdir -p migrations
curl -sL https://raw.githubusercontent.com/kolapsis/shm/main/migrations/001_init.sql -o migrations/001_init.sql
curl -sL https://raw.githubusercontent.com/kolapsis/shm/main/migrations/002_applications.sql -o migrations/002_applications.sql
```

### Key Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `SHM_DB_DSN` | required | PostgreSQL connection string |
| `PORT` | `8080` | HTTP server port |
| `GITHUB_TOKEN` | — | GitHub PAT for star count fetching |
| `SHM_RATELIMIT_ENABLED` | `true` | Enable rate limiting |
| `SHM_RATELIMIT_SNAPSHOT_REQUESTS` | `1` | Snapshots per period per instance |
| `SHM_RATELIMIT_SNAPSHOT_PERIOD` | `1m` | Snapshot rate window |
| `SHM_RATELIMIT_BRUTEFORCE_THRESHOLD` | `5` | Failed auths before IP ban |
| `SHM_RATELIMIT_BRUTEFORCE_BAN` | `15m` | IP ban duration |

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `postgres_data` volume | All metrics data — back this up |

### Ports
- Default: `8080` — proxy with Nginx/Caddy; TLS strongly recommended since instance SDK keys are sent over the wire

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull app`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. New migrations (if any): check the repo's `migrations/` folder for new `.sql` files and download them before restarting
5. Check logs: `docker compose logs -f app`

---

## Gotchas

- **Migrations must exist before first run** — the `db` container uses `docker-entrypoint-initdb.d` to apply SQL on first startup; missing migration files = empty schema = app crash
- **One server, many apps** — a single SHM instance can track multiple software products; each gets its own application slug in the dashboard
- **SDK integration is the real work** — the server is easy to deploy; the value comes from embedding the Go SDK into your distributed application so instances report back
- **Dynamic schema** — the dashboard auto-creates KPI cards from whatever JSON keys your SDK sends (e.g. `{"users_count": 42}`); no schema migration needed for new metric keys
- **Privacy model** — SHM collects aggregate counters and instance IDs (Ed25519 public key), never user content; instances generate their own keypair locally and can rotate it

---

## Links
- GitHub: https://github.com/kOlapsis/shm
- Website: https://self-hosted-metrics.com
- Deployment docs: https://github.com/kOlapsis/shm/blob/main/docs/DEPLOYMENT.md
- SDK (Go): https://github.com/kolapsis/shm/tree/main/sdk
