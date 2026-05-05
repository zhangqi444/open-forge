# DreamFactory

Self-hosted enterprise API generation platform. DreamFactory connects to any database (MySQL, PostgreSQL, MongoDB, SQL Server, Oracle, etc.) and auto-generates a complete REST API with CRUD operations, relationship handling, stored procedure access, role-based access control, and OpenAPI/Swagger documentation — without writing backend code.

**Official site:** https://dreamfactory.com/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (`df-docker`) | Recommended; official compose in `df-docker` repo |
| Any Linux host | Installer script | Bash installer for Ubuntu/CentOS/Debian |
| Kubernetes | Helm (`df-helm`) | Official Helm chart in `df-helm` repo |
| Windows | Installer | Windows installer available |

---

## Inputs to Collect

### Phase 1 — Planning
- Primary metadata DB: MySQL (bundled) or PostgreSQL
- External data sources to connect (databases, APIs, file storage)
- SMTP for user invitations and system notifications
- Whether to enable MCP daemon for LLM/AI access

### Phase 2 — Deployment
- `APP_KEY` — Laravel application key (auto-generated if omitted on first run)
- Database credentials for DreamFactory's own metadata store
- Redis connection (for caching and session management)
- `SERVERNAME` — domain name for the instance

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: dreamfactory
      MYSQL_USER: df_admin
      MYSQL_PASSWORD: df_admin
    volumes:
      - df-mysql:/var/lib/mysql

  redis:
    image: redis:alpine

  web:
    image: dreamfactorysoftware/df-docker:latest
    depends_on:
      - mysql
      - redis
    environment:
      SERVERNAME: dreamfactory.example.com
      DB_DRIVER: mysql
      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_USERNAME: df_admin
      DB_PASSWORD: df_admin
      DB_DATABASE: dreamfactory
      CACHE_DRIVER: redis
      CACHE_HOST: redis
      CACHE_PORT: 6379
      ENABLE_MCP_DAEMON: "true"
      # APP_KEY: your-laravel-app-key
    ports:
      - "80:80"

volumes:
  df-mysql:
```

> **Note:** On first run, DreamFactory auto-generates `APP_KEY` and creates the admin account. The credentials are shown in the container logs.

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `SERVERNAME` | Public hostname |
| `DB_DRIVER` / `DB_CONNECTION` | Metadata DB type (`mysql`, `pgsql`, `sqlite`) |
| `DB_HOST` / `DB_USERNAME` / `DB_PASSWORD` / `DB_DATABASE` | DB connection |
| `APP_KEY` | Laravel app key (auto-generated if not set) |
| `CACHE_DRIVER` | `redis` or `file` |
| `CACHE_HOST` / `CACHE_PORT` | Redis connection |
| `ENABLE_MCP_DAEMON` | `true` to enable MCP server for LLM tool access |
| `APP_DEBUG` | `true` for debug logging (disable in production) |

### Linux Installer

```bash
# Ubuntu/Debian
curl -sL https://raw.githubusercontent.com/dreamfactorysoftware/dreamfactory/master/installers/ubuntu.sh | bash
```

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**Installer:** Re-run the installer script or follow the [upgrade guide](https://docs.dreamfactory.com/getting-started/upgrading-dreamfactory/).

DreamFactory runs database migrations automatically on startup.

---

## Gotchas

- **Admin credentials in logs on first run** — check `docker compose logs web` to find the auto-generated admin email and password.
- **`APP_KEY` must be preserved** — once set, never change it; it's used to encrypt stored credentials for your connected data sources.
- **Redis is required** for production — without Redis, session management and caching fall back to file storage which won't work properly in containers.
- **MCP daemon** (`ENABLE_MCP_DAEMON=true`) exposes DreamFactory APIs as MCP tools for use with local LLMs and AI agents.
- **License tiers:** The open-source version on GitHub covers most use cases; enterprise features (LDAP, Active Directory, premium connectors) require a commercial license.
- **HTTPS:** Put Nginx or a load balancer in front for TLS termination in production.

---

## References
- GitHub: https://github.com/dreamfactorysoftware/dreamfactory
- Docker repo: https://github.com/dreamfactorysoftware/df-docker
- Helm chart: https://github.com/dreamfactorysoftware/df-helm
- Docs: https://docs.dreamfactory.com/
- Getting started: https://guide.dreamfactory.com/
