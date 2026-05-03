# Drivebase

> Self-hosted, cloud-agnostic file management platform. Connects Google Drive, AWS S3 (and S3-compatible services), and local filesystem under a single OS-like browser UI — windowed apps, a taskbar, and a desktop shell. Batch copy/move across providers with conflict resolution and real-time progress.

**Official URL:** https://github.com/drivebase/drivebase

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose (official installer) | Recommended; installer auto-generates config |
| Any Linux VPS/VM | Docker Compose (manual) | Use `docker-compose.yml` from repo |
| Local / dev | Bun (bare metal) | Requires Bun 1.3.5+, PostgreSQL 15+, Redis 7+ |

> ⚠️ v4 is still in active development — expect breaking changes until a stable release is tagged.

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DB_URL` | PostgreSQL connection string | `postgres://user:pass@localhost:5432/drivebase` |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `MASTER_KEY` | 32-byte base64 crypto key | `openssl rand -base64 32` |
| `AUTH_SECRET` | Better Auth secret | `openssl rand -hex 32` |
| `BASE_URL` | Public URL of the instance | `http://localhost:4000` |
| `TRUSTED_ORIGINS` | Comma-separated allowed origins | `http://localhost:3000` |

### Phase: Cloud Provider (optional, per provider)
| Input | Description |
|-------|-------------|
| Google OAuth client ID + secret | For Google Drive integration |
| AWS/S3 access key + secret + region + bucket | For S3-compatible storage |

---

## Software-Layer Concerns

### Config & Environment
- Official installer: `curl -fsSL https://drivebase.io/install | bash` — creates a `drivebase/` directory with Docker Compose and auto-generated `config.toml`
- Manual: copy `packages/config/config.example.toml` to `config.toml` and fill in values
- Run migrations before first start: `bun run db:migrate` (bare metal) or handled by installer

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| PostgreSQL data volume | All application data |
| Redis data volume | Queue and cache |
| `config.toml` | Application config (bind-mount into container) |

### Key `config.toml` Fields
```toml
[server]
env = "prod"
port = 4000
host = "0.0.0.0"

[db]
url = "postgres://user:password@db:5432/drivebase"

[redis]
url = "redis://redis:6379/0"

[crypto]
masterKeyBase64 = "<openssl rand -base64 32>"

[auth]
betterAuthSecret = "<openssl rand -hex 32>"
baseUrl = "http://localhost:4000"
trustedOrigins = ["http://localhost:3000"]
```

### Ports
| Port | Service |
|------|---------|
| `4000` | API (GraphQL + SSE) |
| `3000` | Web UI |

---

## Upgrade Procedure

1. Pull the latest image: `docker compose pull`
2. Stop services: `docker compose down`
3. Start with new image: `docker compose up -d`
4. Check logs: `docker compose logs -f`
5. Migrations run automatically on startup (verify in logs)

---

## Gotchas

- **Active development (v4)** — APIs and config format may change between releases; pin to a specific image tag in production
- **Two ports exposed** — API on 4000 and UI on 3000; reverse proxy both under the same domain (e.g., `/api` → 4000, `/` → 3000) or expose separately
- **`masterKeyBase64` must not change** — changing it breaks decryption of stored provider credentials; back it up
- **Google Drive OAuth** — requires a Google Cloud project with Drive API enabled and an OAuth 2.0 client; callback URL must match `BASE_URL`
- **Presigned S3 uploads** — direct S3 uploads bypass the Drivebase server; make sure your S3 CORS policy allows the browser origin
- **GraphQL API** — all operations are exposed via GraphQL at `http://localhost:4000/graphql`; useful for automation

---

## Links
- GitHub: https://github.com/drivebase/drivebase
- README / installer docs: https://github.com/drivebase/drivebase#readme
- Docker Hub: https://hub.docker.com/r/drivebase/drivebase (check for official image)
