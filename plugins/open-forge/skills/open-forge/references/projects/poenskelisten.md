---
name: poenskelisten
description: Pønskelisten recipe for open-forge. Self-hosted collaborative wishlist app — share gift ideas without spoiling surprises. Go + Docker, SQLite/PostgreSQL/MySQL. Source: https://github.com/aunefyren/poenskelisten
---

# Pønskelisten

A self-hosted web app for creating, sharing, and collaborating on wishlists — without ruining the surprise. Share gift ideas with friends and family; participants can anonymously claim wishes (others see it's taken, the owner does not). GPL-3.0 licensed, written in Go. Upstream: <https://github.com/aunefyren/poenskelisten>. Docker Hub: <https://hub.docker.com/r/aunefyren/poenskelisten>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | SQLite | Recommended — simplest setup |
| Any Linux VPS | Docker Compose | PostgreSQL | Better for multi-user/production |
| Any Linux VPS | Docker Compose | MySQL | Supported but not recommended |
| Any Linux / macOS / Windows | Go binary (native) | Any supported | Download release binary |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Which database backend?" | sqlite / postgresql / mysql | SQLite is simplest for personal use |
| "Port to expose?" | Number | Default 8080 |
| "Timezone?" | TZ string | e.g. Europe/Oslo, America/New_York — affects date display |
| "External URL (public URL of the instance)?" | URL | Needed for invite links to work correctly |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Generate invite codes on startup?" | true / false | Set generateinvite=true for first run, then remove |
| "SMTP config for email notifications?" | host:port + credentials | Optional; enables email invites and notifications |

## Software-Layer Concerns

- **No public registration by default**: Users join via invite codes. Set `generateinvite=true` on first start to get a code, then disable it.
- **Anonymous wish claiming**: When a participant claims a wish, the list owner cannot see who claimed it — by design.
- **Config via env vars**: All settings via environment variables (recommended for Docker). Also supports startup flags and a generated `config.json`.
- **Data dirs**: `./files/` (user uploads) and `./images/` must be on persistent volumes.
- **Database**: SQLite DB file lives inside the container — mount a volume to persist it, or use the files/ volume which includes it.
- **Groups**: Users can create groups and share wishlists with groups for family/friend coordination.

## Deployment

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
      generateinvite: true       # Remove after first run
      externalurl: https://wishlists.example.com
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
```

Remove `generateinvite: true` from the compose file after the first run and restart.

### Docker Compose (PostgreSQL)

```yaml
services:
  db:
    container_name: poenskelisten-db
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: poenskelisten
      POSTGRES_USER: poenskelisten
      POSTGRES_PASSWORD: changeme
    volumes:
      - pg_data:/var/lib/postgresql/data

  poenskelisten-app:
    container_name: poenskelisten-app
    image: ghcr.io/aunefyren/poenskelisten:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      PUID: 1000
      PGID: 1000
      dbtype: postgresql
      dbhost: db
      dbport: 5432
      dbname: poenskelisten
      dbusername: poenskelisten
      dbpassword: changeme
      timezone: Europe/Oslo
      generateinvite: true
      externalurl: https://wishlists.example.com
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
    depends_on:
      - db

volumes:
  pg_data:
```

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Backup the `./files/` volume (contains SQLite DB if using SQLite) before upgrading.
3. Check release notes at https://github.com/aunefyren/poenskelisten/releases for migration notes.

## Gotchas

- **generateinvite must be removed after first run**: Leaving it enabled means a new invite code is generated every restart — harmless but noisy.
- **externalurl required for invite links**: Without it, invite emails contain localhost URLs that don't work for recipients.
- **UI not fully mobile-optimized**: Per upstream README — functional on mobile but not fully polished for small screens.
- **Name contains special character**: Slug is `poenskelisten` (without ø) for filesystem compatibility. The ASD source entry uses the special character.
- **No OAuth/SSO**: User management is invite-code based only. No LDAP or OAuth integration.

## Links

- Source: https://github.com/aunefyren/poenskelisten
- Docker Hub: https://hub.docker.com/r/aunefyren/poenskelisten
- Releases: https://github.com/aunefyren/poenskelisten/releases
