# MongooseIM

MongooseIM is a robust, scalable, enterprise-grade XMPP messaging server built in Erlang/OTP. It supports vanilla XMPP, REST API, Server-Sent Events, WebSockets, and BOSH (HTTP long-polling), with clustering support for horizontal scaling.

**Website:** https://www.erlang-solutions.com/products/mongooseim.html
**Source:** https://github.com/esl/MongooseIM
**License:** GPL-2.0
**Stars:** ~1,735

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker | Recommended for quick start |
| Kubernetes | Helm chart | Official chart available |
| Ubuntu/Debian/CentOS | DEB/RPM packages | Pre-built packages from GitHub releases |
| Any | Erlang/OTP + build from source | For custom builds |

---

## Inputs to Collect

### Phase 1 — Planning
- XMPP domain (e.g. `chat.example.com`)
- Database backend: PostgreSQL (recommended), MySQL, or Riak
- Cluster size (single node vs. multi-node)
- Client connection ports: C2S (5222), S2S (5269), BOSH/WS (5280/5285)

### Phase 2 — Deployment
- `hosts`: list of XMPP domains to serve
- Database credentials (host, db, user, password)
- TLS certificate path (for encrypted connections)
- `admin_extra_module`: for admin CLI access

---

## Software-Layer Concerns

### Docker Quick Start
```bash
# Pull and run with default in-memory database (dev/test only)
docker run -d \
  --name mongooseim \
  -p 5222:5222 \
  -p 5269:5269 \
  -p 5280:5280 \
  erlangsolutions/mongooseim:latest
```

### Docker Compose with PostgreSQL
```yaml
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: mongooseim
      POSTGRES_USER: mongooseim
      POSTGRES_PASSWORD: mongooseim
    volumes:
      - pg_data:/var/lib/postgresql/data

  mongooseim:
    image: erlangsolutions/mongooseim:latest
    ports:
      - "5222:5222"   # XMPP client-to-server
      - "5269:5269"   # XMPP server-to-server
      - "5280:5280"   # BOSH / HTTP
      - "5285:5285"   # BOSH + WS TLS
      - "8088:8088"   # REST API
    environment:
      - MIM_DB_HOST=db
      - MIM_DB_PORT=5432
      - MIM_DB_DATABASE=mongooseim
      - MIM_DB_USERNAME=mongooseim
      - MIM_DB_PASSWORD=mongooseim
    depends_on:
      - db
    volumes:
      - mongooseim_data:/var/lib/mongooseim

volumes:
  pg_data:
  mongooseim_data:
```

### Port Reference
| Port | Protocol | Purpose |
|------|----------|---------|
| 5222 | TCP | XMPP Client-to-Server (C2S) |
| 5269 | TCP | XMPP Server-to-Server (S2S) |
| 5280 | TCP | BOSH / HTTP-polling |
| 5285 | TCP | BOSH + WebSocket (TLS) |
| 8088 | TCP | REST API |

### Configuration File
Main config: `/etc/mongooseim/mongooseim.toml`

Key sections:
```toml
[general]
  hosts = ["example.com"]
  default_server_domain = "example.com"

[listen.c2s]
  port = 5222
  access = "c2s"

[outgoing_pools.rdbms.default]
  strategy = "best_worker"
  connection.driver = "pgsql"
  connection.host = "db"
  connection.port = 5432
  connection.database = "mongooseim"
  connection.username = "mongooseim"
  connection.password = "mongooseim"
```

### Database Schema
```bash
# Apply schema (first run)
docker exec mongooseim mongooseimctl install_pgsql_schema
# or manually apply SQL from:
# https://github.com/esl/MongooseIM/tree/master/priv/pg.sql
```

### Admin CLI
```bash
# Access admin console
docker exec -it mongooseim mongooseimctl

# Create admin user
mongooseimctl register_identified admin@example.com example.com secretpassword

# List connected users
mongooseimctl connected_users
```

### Clustering (Multi-Node)
```bash
# On node 2, join existing cluster
mongooseimctl join_cluster mongooseim@node1.example.com
```

---

## Upgrade Procedure

```bash
# Pull new image
docker compose pull

# Stop and restart
docker compose down
docker compose up -d

# Check if schema migration needed
# Review release notes: https://github.com/esl/MongooseIM/releases
```

---

## Gotchas

- **Erlang-based**: Uses Erlang/OTP internals; not beginner-friendly to debug without Erlang knowledge. Logs are in Erlang crash dump format.
- **TLS required for production**: Plain-text C2S is insecure; configure TLS certificates in the config and use STARTTLS or direct TLS.
- **Database schema must be applied manually**: The container does not auto-apply the SQL schema on first run in all configurations; apply it explicitly.
- **S2S for federation**: Port 5269 needed only if federating with other XMPP servers. Close it if running a closed/private deployment.
- **Clustering complexity**: Multi-node clustering works well but requires Erlang node naming (FQDN-based) and distributed Erlang cookie configuration.
- **BOSH vs WebSocket**: Modern clients prefer WebSocket (port 5285); BOSH (port 5280) is the HTTP long-polling fallback for restricted networks.

---

## Links
- Docs: https://esl.github.io/MongooseDocs/
- Getting Started: https://esl.github.io/MongooseDocs/latest/getting-started/Installation/
- Docker image: https://hub.docker.com/r/erlangsolutions/mongooseim/
- Helm chart: https://trymongoose.im/downloads#helm
- GitHub Releases: https://github.com/esl/MongooseIM/releases/latest
