# Corteza

Open-source low-code platform for building CRM, business process, and structured data applications. Corteza provides a visual app builder, workflow automation, RBAC security, REST API, and integrations — all in a single Go binary backed by a database.

**Official site:** https://cortezaproject.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; official image on Docker Hub |
| Any Linux host | Binary (Go) | Single binary, no runtime dependencies |
| Kubernetes | Helm (community) | Community charts available |
| Cloud VPS | Docker Compose | Standard production deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- Database backend: PostgreSQL (recommended), MySQL, SQLite
- Domain name and TLS config
- SMTP for notifications and user invites
- Whether to enable built-in authentication or connect OIDC/LDAP/SAML

### Phase 2 — Deployment
- `AUTH_SECRET` — JWT signing secret (random, min 32 chars)
- `DB_DSN` — database connection string
- `HTTP_ADDR` — bind address (default `:80`)
- `DOMAIN` — public hostname
- SMTP credentials for email

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  corteza:
    image: cortezaproject/corteza:latest
    restart: always
    ports:
      - "80:80"
    environment:
      DB_DSN: "postgres://corteza:secret@db:5432/corteza?sslmode=disable"
      AUTH_SECRET: "change-me-to-32-char-random-string"
      DOMAIN: "corteza.example.com"
      SMTP_HOST: "smtp.example.com"
      SMTP_PORT: "587"
      SMTP_USER: "user@example.com"
      SMTP_PASS: "smtp-password"
      SMTP_FROM: "no-reply@example.com"
    depends_on:
      - db
    volumes:
      - corteza-data:/data

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: corteza
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: corteza
    volumes:
      - db-data:/var/lib/postgresql/data

volumes:
  corteza-data:
  db-data:
```

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `DB_DSN` | Database connection string |
| `AUTH_SECRET` | JWT secret key (min 32 chars) |
| `DOMAIN` | Public hostname for URL generation |
| `HTTP_ADDR` | Listen address (default `:80`) |
| `SMTP_HOST` / `SMTP_PORT` | SMTP server for emails |
| `SMTP_USER` / `SMTP_PASS` | SMTP credentials |
| `SMTP_FROM` | Sender email address |
| `LOG_LEVEL` | `info`, `debug`, `warn`, `error` |
| `STORAGE_PATH` | File upload storage path (default `/data`) |

### Binary Install

Download the latest release binary from [GitHub Releases](https://github.com/cortezaproject/corteza/releases):

```bash
wget https://github.com/cortezaproject/corteza/releases/latest/download/corteza-linux-amd64
chmod +x corteza-linux-amd64
sudo mv corteza-linux-amd64 /usr/local/bin/corteza

# Run with env vars
export DB_DSN="postgres://..."
export AUTH_SECRET="..."
corteza serve-api
```

### Data Paths
- `/data/` — file uploads, attachments (inside container)
- Database stores all application data (records, modules, workflows)

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**Binary:** Download new release binary, replace old binary, restart service. Corteza runs database migrations automatically on startup.

Review the [upgrade guide](https://docs.cortezaproject.org/corteza-docs/2024.9/devops-guide/upgrade/index.html) and [changelog](https://docs.cortezaproject.org/corteza-docs/2024.9/changelog/index.html) before major version upgrades.

---

## Gotchas

- **`AUTH_SECRET` must be set** — the application will not start without a JWT secret.
- **DB migrations run on startup** — no separate migration step needed; ensure the DB is running before Corteza starts.
- **Single binary** — Corteza (API + web UI) ships as one binary; no separate frontend server needed.
- **Default port 80** — change `HTTP_ADDR` if running behind a reverse proxy.
- **File storage:** The `/data` volume must be persistent — it stores all uploaded files and attachments.
- **Auth providers:** Built-in local auth is enabled by default. LDAP, SAML, and OIDC can be configured via the admin UI.

---

## References
- GitHub: https://github.com/cortezaproject/corteza
- Official site: https://cortezaproject.org/
- Docs: https://docs.cortezaproject.org/corteza-docs/2024.9/devops-guide/index.html
- Docker Hub: https://hub.docker.com/r/cortezaproject/corteza
- Releases: https://github.com/cortezaproject/corteza/releases
- Upgrade guide: https://docs.cortezaproject.org/corteza-docs/2024.9/devops-guide/upgrade/index.html
