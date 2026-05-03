# Mobilizon

> Federated event and community platform — a self-hosted alternative to Facebook Events and Meetup. Instances federate via ActivityPub so users on one instance can interact with events on another. Developed by Framasoft (2017–2024).

**Official URL:** https://mobilizon.org  
**Source:** https://framagit.org/kaihuri/mobilizon  
**Docs:** https://docs.mobilizon.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended for most deployments |
| Any Linux VPS/VM | Elixir release (bare metal) | Documented in upstream install guide |
| Debian/Ubuntu VPS | Package install | Via Framasoft's documented procedure |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DOMAIN` | Public domain for your instance | `events.example.com` |
| `ADMIN_EMAIL` | Admin account email | `admin@example.com` |
| `ADMIN_PASSWORD` | Initial admin password | strong password |
| `SECRET_KEY_BASE` | Phoenix app secret (64+ random chars) | generate with `mix phx.gen.secret` |
| `DB_NAME` | PostgreSQL database name | `mobilizon` |
| `DB_USER` | PostgreSQL username | `mobilizon` |
| `DB_PASS` | PostgreSQL password | strong password |

### Phase: Email (required for user registration)
| Input | Description | Example |
|-------|-------------|---------|
| `SMTP_HOST` | SMTP server hostname | `smtp.mailgun.org` |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USER` | SMTP username | `postmaster@mg.example.com` |
| `SMTP_PASS` | SMTP password | secret |
| `FROM_EMAIL` | Sender address | `noreply@events.example.com` |

---

## Software-Layer Concerns

### Config File
- Main config: `config/config.exs` (or environment-variable overrides depending on deploy method)
- Upstream docs cover Docker and bare-metal approaches: https://docs.mobilizon.org

### Database
- Requires PostgreSQL with the `postgis` extension for geolocation features
- Run `docker exec -it mobilizon_db psql -U mobilizon -c "CREATE EXTENSION IF NOT EXISTS postgis;"` after DB init

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/var/lib/mobilizon/uploads` | Uploaded media and attachments — bind-mount to persist |
| `/etc/mobilizon` | Config files |

### Ports
- Default HTTP: `4000` — proxy with Nginx/Caddy and terminate TLS

### Federation
- ActivityPub federation works out of the box; your instance can share events with Mastodon, Pleroma, and other Mobilizon instances
- The domain you set at install is permanent — changing it breaks federation

---

## Upgrade Procedure

1. Pull updated images: `docker compose pull`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`
4. Run pending migrations: `docker compose exec mobilizon bin/mobilizon eval "Mobilizon.Release.migrate"`
5. Check logs: `docker compose logs -f mobilizon`

---

## Gotchas

- **Domain is permanent** — the instance domain is embedded in federation identities; changing it after launch breaks all federated links and user identities
- **PostGIS required** — standard PostgreSQL is not enough; use `postgis/postgis` Docker image or install the extension manually
- **SMTP required for registration** — users must confirm their email; without working SMTP, no one can sign up
- **Project status** — Framasoft developed Mobilizon from 2017–2024; the project is maintained but the primary developer phase has concluded; check framagit for current activity
- **Resources** — Elixir/Phoenix apps can be memory-hungry at startup; allocate at least 512 MB RAM; 1 GB+ recommended for production

---

## Links
- Official site: https://mobilizon.org
- Source: https://framagit.org/kaihuri/mobilizon
- Docs: https://docs.mobilizon.org
- Matrix chat: https://matrix.to/#/#Mobilizon:matrix.org
