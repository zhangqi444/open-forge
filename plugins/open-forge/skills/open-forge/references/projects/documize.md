# Documize Community

Modern, self-hosted knowledge management and documentation platform. Documize provides spaces, labels, categories, versioning, and a rich text editor — designed for both internal team wikis and customer-facing documentation. Built as a single Go binary with PostgreSQL, MySQL, or SQL Server backend.

**Official site:** https://www.documize.com/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official compose file fetches binary at runtime |
| Any Linux host / macOS / Windows | Binary (Go) | Self-contained binary; no runtime dependencies |
| Raspberry Pi / ARM | Binary | ARM64 build available |
| Kubernetes | Deployment + PVC | Run binary image in a pod |

---

## Inputs to Collect

### Phase 1 — Planning
- Database: PostgreSQL (recommended), MySQL/MariaDB, or Microsoft SQL Server
- Edition: Community (free) or Community+ (free for ≤5 users, paid beyond)
- Domain name and TLS setup (reverse proxy recommended)
- SMTP config for user invitations and notifications
- Auth: built-in email/password, or LDAP/AD/Keycloak/CAS

### Phase 2 — Deployment
- `DOCUMIZEDB` — database connection string
- `DOCUMIZEDBTYPE` — `postgresql`, `mysql`, or `sqlserver`
- `DOCUMIZELOCATION` — `selfhost`
- `DOCUMIZESALT` — random salt string for password hashing
- `DOCUMIZEPORT` — HTTP listen port (default `5001`)

---

## Software-Layer Concerns

### Docker Compose

```yaml
version: "3"
services:
  db:
    image: postgres:15
    restart: always
    environment:
      POSTGRES_USER: documize
      POSTGRES_PASSWORD: Passw0rd
      POSTGRES_DB: documize
    volumes:
      - db-data:/var/lib/postgresql/data

  app:
    image: debian:latest
    restart: always
    command: >
      /bin/sh -c "apt-get -qq update &&
      apt-get -qq install -y wget &&
      wget -q https://github.com/documize/community/releases/latest/download/documize-community-linux-amd64 &&
      chmod +x documize-community-linux-amd64 &&
      ./documize-community-linux-amd64"
    depends_on:
      - db
    ports:
      - "5001:5001"
    environment:
      DOCUMIZEPORT: 5001
      DOCUMIZEDB: "host=db port=5432 dbname=documize user=documize password=Passw0rd sslmode=disable"
      DOCUMIZEDBTYPE: postgresql
      DOCUMIZESALT: "change-me-random-string"
      DOCUMIZELOCATION: selfhost

volumes:
  db-data:
```

> **Tip:** For a cleaner setup, download the binary directly to a persistent volume instead of fetching it at runtime. This also makes upgrades more controlled.

### Binary Install

```bash
# Download from GitHub Releases
wget https://github.com/documize/community/releases/latest/download/documize-community-linux-amd64
chmod +x documize-community-linux-amd64

# Run with environment variables
export DOCUMIZEPORT=5001
export DOCUMIZEDB="host=localhost port=5432 dbname=documize user=documize password=secret sslmode=disable"
export DOCUMIZEDBTYPE=postgresql
export DOCUMIZESALT="random-salt-string"
export DOCUMIZELOCATION=selfhost
./documize-community-linux-amd64
```

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `DOCUMIZEPORT` | HTTP listen port (default `5001`) |
| `DOCUMIZEDB` | Database connection string |
| `DOCUMIZEDBTYPE` | `postgresql`, `mysql`, or `sqlserver` |
| `DOCUMIZESALT` | Random string for password hashing — set once, never change |
| `DOCUMIZELOCATION` | `selfhost` for self-hosted deployments |
| `DOCUMIZESSL` | `true` to enable built-in TLS (provide cert/key) |
| `DOCUMIZECERT` | Path to TLS certificate file |
| `DOCUMIZEKEY` | Path to TLS private key file |

---

## Upgrade Procedure

1. Stop the running binary / container
2. Download new release from [GitHub Releases](https://github.com/documize/community/releases)
3. Replace old binary
4. Start — Documize runs DB migrations automatically on startup

---

## Gotchas

- **`DOCUMIZESALT` must never change** — it's used to hash existing passwords; changing it will lock out all users.
- **DB migrations are automatic** — Documize upgrades the schema on startup; always back up the database before upgrading.
- **No official Docker image** — the compose file fetches the binary from S3/GitHub at runtime; pin to a specific release URL for reproducibility.
- **Community+ edition** is free for ≤5 users; the compose file defaults to the `plus` edition — swap for the regular `community` binary if you prefer the free-forever version.
- **Full-text search requires FTS** — MySQL must have FTS enabled; PostgreSQL's `tsvector` FTS works out of the box.
- **LDAP/SSO** requires Community+ edition.

---

## References
- GitHub: https://github.com/documize/community
- Official site: https://www.documize.com/
- Releases: https://github.com/documize/community/releases
- Documentation: https://docs.documize.com/
