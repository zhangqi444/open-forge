# Kong Gateway (OSS)

Cloud-native API and LLM/MCP gateway. Kong is a high-performance, extensible reverse proxy for microservices and AI traffic. Handles routing, load balancing, authentication, rate limiting, SSL/TLS termination, and more via a plugin ecosystem. The OSS edition (Apache-2.0) supports DB-less declarative config or PostgreSQL-backed config.

**Official site:** https://konghq.com  
**Source:** https://github.com/Kong/kong  
**Upstream docs:** https://docs.konghq.com/gateway/  
**License:** Apache-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (DB-less) | Declarative config, no database needed |
| Any Linux host | Docker Compose + PostgreSQL | Full config persistence via DB |
| Kubernetes | Helm / KIC | Kong Ingress Controller for K8s |

---

## Inputs to Collect

### DB mode
| Variable | Description | Default |
|----------|-------------|---------|
| `KONG_DATABASE` | `off` for DB-less, `postgres` for DB mode | `off` |
| `KONG_PG_HOST` | PostgreSQL host | `db` |
| `KONG_PG_DATABASE` | PostgreSQL database name | `kong` |
| `KONG_PG_USER` | PostgreSQL user | `kong` |
| `KONG_PG_PASSWORD_FILE` | Path to file containing PG password | `/run/secrets/kong_postgres_password` |

### Optional
| Variable | Description | Default |
|----------|-------------|---------|
| `KONG_PROXY_LISTEN` | Proxy listen address | `0.0.0.0:8000, 0.0.0.0:8443 ssl` |
| `KONG_ADMIN_LISTEN` | Admin API listen address | `127.0.0.1:8001` |
| `KONG_PREFIX` | Kong working directory | `/var/run/kong` |
| `KONG_DECLARATIVE_CONFIG` | Path to declarative config file (DB-less) | unset |

---

## Software-Layer Concerns

### Quick start (Docker Compose)
```sh
git clone https://github.com/Kong/docker-kong.git
cd docker-kong/compose
# Create postgres password file
echo "your-postgres-password" > POSTGRES_PASSWORD
# DB-less mode (no postgres needed):
KONG_DATABASE=off docker compose up -d kong
# DB mode (with postgres):
docker compose --profile database up -d
```

### Ports
| Port | Protocol | Description |
|------|----------|-------------|
| `8000` | HTTP | Proxy — send traffic to services through Kong |
| `8443` | HTTPS | Proxy (SSL) |
| `8001` | HTTP | Admin API — configure Kong |
| `8002` | HTTP | Kong Manager (web UI) |
| `8444` | HTTPS | Admin API (SSL) |

### DB-less declarative config
In DB-less mode, all config is defined in a YAML/JSON file:
```yaml
# kong.yml
_format_version: "3.0"
services:
  - name: my-service
    url: http://backend:8080
    routes:
      - name: my-route
        paths:
          - /api
```
Mount the file and set `KONG_DECLARATIVE_CONFIG=/path/to/kong.yml`.

### DB mode — migrations
When using PostgreSQL, run migrations before starting Kong:
```sh
docker compose --profile database run kong-migrations
docker compose --profile database up -d
```

### Security notes
- Admin API (`8001`) should **never** be exposed publicly — bind to `127.0.0.1` or restrict with firewall
- Use `KONG_ADMIN_ACCESS_LOG` and `KONG_ADMIN_ERROR_LOG` to monitor admin API access

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Run migrations if using DB mode: `docker compose --profile database run kong-migrations-up`
3. Recreate: `docker compose up -d`
4. Check migration notes: https://docs.konghq.com/gateway/changelog/

---

## Gotchas

- **Admin API is unauthenticated by default** — do not expose port 8001 publicly without adding auth (e.g., bind to localhost and use SSH tunneling or Kong's RBAC)
- **DB-less mode cannot use all plugins** — some plugins (e.g., OAuth2, Session) require a database; check plugin docs before choosing DB-less
- **Postgres password via Docker secrets** — the default compose uses Docker secrets (`kong_postgres_password` file); adjust if not using Docker Swarm secrets
- **DB migrations are separate containers** — `kong-migrations` and `kong-migrations-up` are one-off jobs using compose profiles; don't skip them when upgrading
- **Port 8002 (Kong Manager)** — available in OSS as a basic read-only UI; full RBAC/audit features require Kong Enterprise

---

## Links
- Upstream README: https://github.com/Kong/kong
- Docker Compose quick start: https://github.com/Kong/docker-kong/tree/master/compose
- Official install page: https://konghq.com/install/
- Admin API reference: https://docs.konghq.com/gateway/api/admin-oss/
