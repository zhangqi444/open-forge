# Pønskelisten

**Self-hosted wishlist sharing app** — create and share wishlists with friends and family for gift coordination, without spoiling surprises. Claims are anonymous to the list owner; collaborators can see what's taken.

**Source:** https://github.com/aunefyren/poenskelisten  
**Docker Hub:** https://hub.docker.com/r/aunefyren/poenskelisten  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker | Primary recommended method |
| Linux/macOS/Windows | Binary (Go) | Pre-compiled releases available |
| Any | Build from source | Requires Go |

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `port` | HTTP port | `8080` |
| `externalurl` | Public URL of the instance | — |
| `timezone` | e.g. `Europe/Oslo` | — |
| Database type | SQLite (default), PostgreSQL, MySQL | SQLite |

### Optional SMTP (for email invites/notifications)
| Input | Description |
|-------|-------------|
| `smtphost` / `smtpport` | SMTP server |
| `smtpusername` / `smtppassword` | SMTP credentials |
| `smtpfrom` | Sender email address |

---

## Software-layer Concerns

### Docker Compose
```yaml
services:
  poenskelisten:
    image: aunefyren/poenskelisten:latest
    ports:
      - '8080:8080'
    environment:
      - port=8080
      - externalurl=https://your-domain.com
      - timezone=Europe/Oslo
      # SQLite is default — no DB config needed
      # For PostgreSQL:
      # - dbtype=postgresql
      # - dbhost=postgres
      # - dbport=5432
      # - dbusername=poenskelisten
      # - dbpassword=secret
      # - dbname=poenskelisten
    volumes:
      - ./data:/app/data
    restart: unless-stopped
```

### Configuration methods (choose one)
1. **Environment variables** — recommended for Docker
2. **Startup flags** — e.g. `./poenskelisten -port 8080 -externalurl https://...`
3. **config.json** — generated on first run, editable manually

### Key environment variables
| Variable | Description | Default |
|----------|-------------|---------|
| `port` | HTTP listen port | `8080` |
| `externalurl` | Public URL (used in email links) | — |
| `timezone` | Timezone for date display | — |
| `environment` | `production` or `test` | `production` |
| `dbtype` | `sqlite`, `postgresql`, `mysql` | `sqlite` |
| `dbhost` / `dbport` / `dbusername` / `dbpassword` / `dbname` | DB connection | — |
| `smtphost` / `smtpport` / `smtpusername` / `smtppassword` / `smtpfrom` | Email config | — |
| `disablesmtp` | Set `true` to disable email features | `false` |

### Features
- Create wishlists and add wishes (name, description, URL, image)
- Share wishlists with groups of people
- Claims are anonymous to the list owner (others see an item is taken; owner does not)
- Group management for collaborating with family/friends

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **`externalurl` is required for email invitations to work.** Without it, invite links in emails will be broken.
- **SQLite is the easiest** database option — no extra container needed. The DB file is stored in the mounted data directory.
- **UI not yet fully optimized for small screens** — noted as a known limitation in the README.
- **SMTP is optional** but enables user invitations and notifications. Disable with `disablesmtp=true` for a local-only setup.

---

## References

- Upstream README: https://github.com/aunefyren/poenskelisten#readme
