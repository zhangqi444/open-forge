# OpenRemote

OpenRemote is a 100% open source IoT platform for device management, automation, data analytics, and multi-tenancy. It supports asset management, when-then rules, flow rules, JavaScript/Groovy rules, MQTT broker, HTTP/REST/WebSocket agents, edge gateways, and an Insights dashboard builder.

**Website:** https://openremote.io
**Source:** https://github.com/openremote/openremote
**License:** AGPL-3.0
**Stars:** ~1,744

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker Compose | Recommended |
| ARM64 (Pi, Apple Silicon) | Docker Compose | Multi-arch images supported |
| Kubernetes | Custom manifests | See developer docs |

---

## Inputs to Collect

### Phase 1 — Planning
- `OR_HOSTNAME`: the hostname/IP used to access the Manager UI (default: `localhost`)
- SSL: uses self-signed cert by default; bring your own cert or use Let's Encrypt integration
- Admin credentials (set post-install or via env)
- Realm name (default: `master`)

### Phase 2 — Deployment
- `OR_HOSTNAME` (e.g. `iot.example.com`)
- `OR_SSL_PORT` (default: 443)
- `OR_HTTP_PORT` (default: 80)
- `OR_ADMIN_PASSWORD` (if configuring via env)

---

## Software-Layer Concerns

### Quick Start (Docker Compose)
```bash
# Download official docker-compose.yml
wget https://raw.githubusercontent.com/openremote/openremote/master/docker-compose.yml

# Start with default localhost config
docker compose -p openremote up -d

# Access at https://localhost (accept self-signed cert)
# Default credentials: admin / secret
```

### Custom Hostname
```bash
# Set hostname before starting
OR_HOSTNAME=192.168.1.100 docker compose -p openremote up -d
# or export first:
export OR_HOSTNAME=iot.example.com
docker compose -p openremote up -d
```

### Example docker-compose.yml (core services)
```yaml
services:
  postgresql:
    image: openremote/postgresql:latest
    volumes:
      - postgresql-data:/var/lib/postgresql/data

  keycloak:
    image: openremote/keycloak:latest
    depends_on:
      - postgresql
    environment:
      - KEYCLOAK_ADMIN_PASSWORD=secret

  manager:
    image: openremote/manager:latest
    depends_on:
      - keycloak
    ports:
      - "443:8443"
      - "80:8080"
      - "1883:1883"   # MQTT
    environment:
      - OR_HOSTNAME=localhost
      - OR_ADMIN_PASSWORD=secret
    volumes:
      - manager-data:/deployment

volumes:
  postgresql-data:
  manager-data:
```

### Data Volumes
| Volume | What's stored |
|--------|--------------|
| `postgresql-data` | All asset, rule, and historical attribute data |
| `manager-data` | Deployment config, custom code |

### Historical Data Purge
```bash
# Default: historical data purged after X days (configurable)
# Override per-attribute or globally via:
OR_DATA_POINTS_MAX_AGE_DAYS=365
```

### Database Backup/Restore
```bash
# Backup
docker exec openremote_postgresql_1 pg_dump -U postgres openremote > backup.sql

# Restore
docker exec -i openremote_postgresql_1 psql -U postgres openremote < backup.sql
```

### MQTT Broker
Built-in MQTT broker available on port 1883. Connect IoT devices directly using MQTT protocol with realm-scoped topics.

---

## Upgrade Procedure

```bash
# Pull latest images
docker compose -p openremote pull

# Restart containers
docker compose -p openremote down
docker compose -p openremote up -d

# Schema migrations run automatically on startup
```

---

## Gotchas

- **Self-signed certificate**: Default setup uses a self-signed TLS cert; browsers will warn. For production, configure a reverse proxy (nginx/Caddy) with Let's Encrypt or supply your own cert.
- **OR_HOSTNAME matters**: The URL used to access the system must match `OR_HOSTNAME`. Misconfigured redirects cause Keycloak login failures.
- **Keycloak dependency**: Authentication is handled by a bundled Keycloak instance; this adds complexity but provides SSO/OAuth2/OIDC capabilities.
- **First login credentials**: Default `admin / secret` — change immediately after first login.
- **Historical data size**: Attribute value history can grow large; configure `dataPointsMaxAgeDays` per attribute and set `OR_DATA_POINTS_MAX_AGE_DAYS` globally.
- **Java-based backend**: The Manager is a Java/Groovy application; memory requirements scale with asset count and rule complexity.
- **Multiple realms**: OpenRemote supports multi-tenancy via Keycloak realms — useful for managing separate organizations or projects.

---

## Links
- Docs: https://docs.openremote.io
- Manager UI Guide: https://docs.openremote.io/docs/user-guide/manager-ui/
- Custom Deployment: https://docs.openremote.io/docs/user-guide/deploying/custom-deployment
- Docker Hub: https://hub.docker.com/u/openremote/
- Community Forum: https://forum.openremote.io/
- Demo: https://demo.openremote.io/
