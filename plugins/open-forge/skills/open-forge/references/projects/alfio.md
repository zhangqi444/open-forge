# Alf.io

Open-source event attendance management and ticket reservation system. Built for event organizers who prioritize privacy and fair pricing — supports multi-event management, multiple payment gateways, check-in apps, and waiting lists.

**Official site:** https://alf.io/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; official image on Docker Hub |
| Any Linux host | JAR (Java 17) | Run as a Spring Boot application |
| Kubernetes | Helm (community) | Community charts available |
| Cloud VPS | Docker Compose | Standard deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- PostgreSQL 10+ instance (required — no SQLite support)
- Domain name and TLS/reverse-proxy setup
- Payment gateway credentials (Stripe, PayPal, Mollie, etc.) — optional for free events
- Email/SMTP config for ticket delivery

### Phase 2 — Deployment
- `POSTGRES_*` connection environment variables
- `SPRING_PROFILES_ACTIVE` profile (`dev` for development, `jdbc-session` for stateless sessions)
- Admin credentials (created on first launch, printed to console)

---

## Software-Layer Concerns

### Docker Compose

```yaml
version: "3.7"
services:
  alfio:
    image: alfio/alf.io
    environment:
      POSTGRES_PORT_5432_TCP_PORT: 5432
      POSTGRES_PORT_5432_TCP_ADDR: db
      POSTGRES_ENV_POSTGRES_DB: alfio
      POSTGRES_ENV_POSTGRES_USERNAME: alfio
      POSTGRES_ENV_POSTGRES_PASSWORD: alfio
      SPRING_PROFILES_ACTIVE: dev,jdbc-session
    ports:
      - "8080:8080"
    depends_on:
      - db

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: alfio
      POSTGRES_USER: alfio
      POSTGRES_PASSWORD: alfio
    volumes:
      - data-volume:/var/lib/postgresql/data

volumes:
  data-volume:
```

> **Note:** Change `SPRING_PROFILES_ACTIVE` to `prod,jdbc-session` for production. The `dev` profile enables debug logging and relaxed security settings.

### Environment Variables
| Variable | Purpose |
|----------|---------|
| `POSTGRES_PORT_5432_TCP_ADDR` | PostgreSQL hostname |
| `POSTGRES_PORT_5432_TCP_PORT` | PostgreSQL port |
| `POSTGRES_ENV_POSTGRES_DB` | Database name |
| `POSTGRES_ENV_POSTGRES_USERNAME` | DB username |
| `POSTGRES_ENV_POSTGRES_PASSWORD` | DB password |
| `SPRING_PROFILES_ACTIVE` | Spring profiles (use `prod,jdbc-session` for production) |

### Configuration Paths
- `custom.jvmargs` — optional extra JVM flags (gitignored; can contain API keys)
- Admin UI: `http://localhost:8080/admin` — log in with auto-generated credentials on first run

### Java / JAR Install

```bash
# Requires Java 17
./gradlew -Pprofile=dev :bootRun
# Or build a fat JAR:
./gradlew -Pprofile=prod shadowJar
java -jar build/libs/alfio-*-all.jar
```

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

Alf.io runs automatic database migrations on startup — no manual migration step needed.

**JAR:** Download new release from [GitHub Releases](https://github.com/alfio-event/alf.io/releases), replace JAR, restart service.

---

## Gotchas

- **Admin password is printed to console on first run** — check `docker compose logs alfio` to find it.
- **PostgreSQL is mandatory** — no embedded or SQLite database support.
- **Row-level security:** The DB user must NOT be a PostgreSQL SUPERUSER, or RLS policy checks are skipped.
- **Java 17 required** — won't start on older JDKs.
- **`2.0-M4-maintenance` branch** is the stable production-ready branch; `master` may contain unstable code.
- **Check-in app:** Alf.io has companion mobile apps for event check-in — see the official site for links.
- **Port 8080** is the default; put Nginx or Caddy in front for TLS termination.

---

## References
- GitHub: https://github.com/alfio-event/alf.io
- Official site: https://alf.io/
- Docker Hub: https://hub.docker.com/r/alfio/alf.io
- Releases: https://github.com/alfio-event/alf.io/releases
