# Pønskelisten

> Self-hosted wishlist web app for families and friends — create and share wish lists, claim gifts anonymously (claimant is visible to others, not to the owner), and coordinate gift-giving without spoiling surprises.

**URL:** https://github.com/aunefyren/poenskelisten
**Source:** https://github.com/aunefyren/poenskelisten
**License:** Not specified in README (check repository root)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker  | Official image: `ghcr.io/aunefyren/poenskelisten:latest` |
| Any   | Binary  | Download prebuilt executable from releases |
| Any   | Build from source | Requires Go |

## Inputs to Collect

### Provision phase
- Domain / public URL (for external access; optional for LAN-only use)
- Database choice: SQLite (default, file-based), PostgreSQL, or MySQL

### Deploy phase
- `dbtype` — `sqlite`, `postgres`, or `mysql` (default: SQLite)
- `externalurl` — public URL of the instance
- `timezone` — timezone string (e.g. `Europe/Oslo`)
- `generateinvite` — set `true` on first run to create an invite code; remove afterward
- Optional: `dbip`, `dbport`, `dbusername`, `dbpassword`, `dbname`, `dbssl` — for PostgreSQL/MySQL
- Optional: `smtphost`, `smtpport`, `smtpusername`, `smtppassword`, `smtpfrom` — for email notifications

## Software-layer Concerns

### Docker Compose (SQLite — recommended)
```yaml
services:
  poenskelisten-app:
    container_name: poenskelisten-app
    image: ghcr.io/aunefyren/poenskelisten:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      PUID: 1000
      PGID: 1000
      dbtype: sqlite
      timezone: Europe/Oslo
      generateinvite: true
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
```
Remove `generateinvite: true` after the first run.

### Docker Compose (PostgreSQL)
```yaml
services:
  db:
    container_name: poenskelisten-db
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: poenskelisten
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    volumes:
      - ./db/:/var/lib/postgresql/data/:rw

  poenskelisten-app:
    container_name: poenskelisten-app
    image: ghcr.io/aunefyren/poenskelisten:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      PUID: 1000
      PGID: 1000
      dbtype: postgres
      dbip: db
      dbport: 5432
      dbname: poenskelisten
      dbusername: myuser
      dbpassword: mypassword
      timezone: Europe/Oslo
      generateinvite: true
    depends_on:
      - db
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
```

### Config / env vars
Environment variables match the config file keys directly:

| Variable | Description |
|----------|-------------|
| `port` | Listen port (default `8080`) |
| `externalurl` | Public URL of instance |
| `environment` | `production` or `test` |
| `timezone` | Timezone (e.g. `Europe/Oslo`) |
| `dbtype` | `sqlite`, `postgres`, or `mysql` |
| `dbip` | DB host (postgres/mysql) |
| `dbport` | DB port |
| `dbusername` / `dbpassword` / `dbname` | DB credentials |
| `dbssl` | Use SSL for DB connection |
| `generateinvite` | Generate invite code on startup (remove after first run) |
| `smtphost` / `smtpport` / `smtpusername` / `smtppassword` / `smtpfrom` | SMTP for email notifications |
| `loglevel` | `info`, `debug`, or `trace` |
| `PUID` / `PGID` | UID/GID for file ownership inside container |

### Data dirs
- `./files/` → `/app/files/` — user-uploaded files and wishlist data
- `./images/` → `/app/images/` — user-uploaded images
- SQLite DB is stored inside the container's app directory (persist via volumes)

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```

## Gotchas
- **Remove `generateinvite` after first run** — if left in, a new invite code is printed to logs on every container start.
- **First registered user becomes admin** — there is no separate admin account setup; the first signup gets admin privileges.
- **Invite-only registration** — new users need an invite code; generate additional codes from the admin panel.
- **Lost admin access** — restart with `generateinvite=true` to get a new invite code and create a new admin account.
- Mobile UI is not yet fully optimized for small screens (per README).
- "Pønskelisten" is a Norwegian wordplay: "ønskeliste" = wishlist, "pønske" = to plot/plan.

## Links
- [README](https://github.com/aunefyren/poenskelisten/blob/main/README.md)
- [GitHub Container Registry — ghcr.io/aunefyren/poenskelisten](https://github.com/aunefyren/poenskelisten/pkgs/container/poenskelisten)
- [Releases](https://github.com/aunefyren/poenskelisten/releases)
