# Databunker

Self-hosted, GDPR-compliant personal data tokenization vault. Databunker stores PII/PHI/KYC records encrypted at rest, issues UUID tokens for safe referencing in application databases, and provides a NoSQL-like API — protecting against SQL injection, GraphQL query abuse, and bulk data leaks.

**Official site:** https://databunker.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker (single container) | Quickest start; SQLite or MySQL backend |
| Any Linux host | Docker Compose (with MySQL) | Recommended for production |
| Any Linux host | Binary (Go) | Build from source |
| Kubernetes | Deployment + PVC | Use the official Docker image |

---

## Inputs to Collect

### Phase 1 — Planning
- Backend database: SQLite (demo/dev) or MySQL (production)
- Master encryption key (auto-generated on first run, or supply via `DATABUNKER_MASTERKEY`)
- API token for admin access (`DATABUNKER_ADMINTOKEN`)
- Whether to enable audit logging

### Phase 2 — Deployment
- MySQL credentials (if not using SQLite)
- `DATABUNKER_MASTERKEY` — 32-byte hex encryption key
- `DATABUNKER_ADMINTOKEN` — admin API bearer token
- Listen port (default `3000`)

---

## Software-Layer Concerns

### Docker Quick Start (Demo)

```bash
docker run -p 3000:3000 -d --rm --name databunker \
  securitybunker/databunker demo
```

Admin UI: `http://localhost:3000` — uses `DEMO` as the token for testing.

### Docker Compose (Production with MySQL)

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootsecret
      MYSQL_DATABASE: databunker
      MYSQL_USER: bunker
      MYSQL_PASSWORD: bunkersecret
    volumes:
      - mysql-data:/var/lib/mysql

  databunker:
    image: securitybunker/databunker:latest
    container_name: databunker
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABUNKER_DBHOST: mysql
      DATABUNKER_DBNAME: databunker
      DATABUNKER_DBUSER: bunker
      DATABUNKER_DBPASS: bunkersecret
      # On first run, these are auto-generated and printed to logs:
      # DATABUNKER_MASTERKEY: <32-byte hex>
      # DATABUNKER_ADMINTOKEN: <UUID>
    depends_on:
      - mysql

volumes:
  mysql-data:
```

> **Critical:** On first run, Databunker prints the auto-generated `MASTERKEY` and `ADMINTOKEN` to logs. **Copy these immediately** — they cannot be recovered. Set them as environment variables for subsequent runs.

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `DATABUNKER_DBHOST` | MySQL host |
| `DATABUNKER_DBNAME` | MySQL database name |
| `DATABUNKER_DBUSER` / `DATABUNKER_DBPASS` | MySQL credentials |
| `DATABUNKER_MASTERKEY` | 32-byte hex encryption master key |
| `DATABUNKER_ADMINTOKEN` | Admin API bearer token (UUID) |

### API Usage

```bash
# Store a user record (returns UUID token)
curl -s http://localhost:3000/v1/user -X POST \
  -H "X-Bunker-Token: DEMO" \
  -H "Content-Type: application/json" \
  -d '{"first":"Jane","last":"Doe","email":"jane@example.com","phone":"+1234567890"}'

# Returns: {"status":"ok","token":"<uuid>"}

# Retrieve user by token
curl -s -H "X-Bunker-Token: DEMO" \
  http://localhost:3000/v1/user/token/<uuid>

# Retrieve user by email
curl -s -H "X-Bunker-Token: DEMO" \
  http://localhost:3000/v1/user/email/jane@example.com
```

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

Ensure `DATABUNKER_MASTERKEY` and `DATABUNKER_ADMINTOKEN` are set in environment — the vault cannot open without the master key.

---

## Gotchas

- **Master key is shown ONCE** — copy it from container logs on first run and persist it as an environment variable. Losing it means losing all encrypted data.
- **Use production mode** (MySQL/PostgreSQL) for real deployments — `demo` mode uses SQLite and is not for production.
- **Store UUID tokens, not plaintext** in your application database — that's the core security model.
- **Admin token ≠ app token** — create app-specific tokens via the admin API; don't use the admin token in application code.
- **Audit log** captures all data access events for GDPR compliance and breach investigation.

---

## References
- GitHub: https://github.com/securitybunker/databunker
- Official site: https://databunker.org/
- Docker Hub: https://hub.docker.com/r/securitybunker/databunker
- API docs: https://documenter.getpostman.com/view/11310294/Szmcbz32
