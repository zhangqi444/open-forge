---
name: poenskelisten-project
description: Poenskelisten recipe for open-forge. Self-hosted wishlist sharing app with anonymous gift claiming. Docker Compose with SQLite or PostgreSQL. Based on upstream README at https://github.com/aunefyren/poenskelisten.
---

# Pønskelisten

Self-hosted web app for creating, sharing, and collaborating on wishlists without ruining the surprise. Friends can claim wishes anonymously (the owner cannot see who claimed what). Go binary, SQLite/PostgreSQL/MySQL. GPL-3.0. Upstream: https://github.com/aunefyren/poenskelisten. Docker: ghcr.io/aunefyren/poenskelisten.

## Compatible install methods

| Method | Database | When to use |
|---|---|---|
| Docker Compose (SQLite) | SQLite | Simplest; recommended for personal/small use |
| Docker Compose (PostgreSQL) | PostgreSQL | Production with more users |
| Binary / executable | SQLite/PostgreSQL/MySQL | Bare-metal without Docker |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Docker or binary?" | Docker / Binary | |
| config | "Database type?" | sqlite / postgres / mysql | sqlite is default and simplest |
| config | "Public URL of the instance?" | URL | externalurl env var |
| config | "Timezone?" | TZ string (e.g. Europe/Oslo) | |
| database | "DB host / name / user / password?" | Four values | PostgreSQL/MySQL only |
| smtp | "SMTP host, port, user, password, from?" | Five values | Optional; for notifications |
| network | "Port to expose?" | Number (default 8080) | |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Go single binary |
| Config methods | Environment variables (recommended for Docker), startup flags, or config.json |
| Data dirs | ./files/ and ./images/ — must be persisted |
| First-run invite | Set generateinvite=true on first start to generate an invite code; remove after first user created |
| Image | ghcr.io/aunefyren/poenskelisten:latest |
| UID/GID | PUID/PGID env vars control the file-owning user inside container |

## Install: Docker Compose (SQLite — recommended)

Source: https://github.com/aunefyren/poenskelisten/blob/main/README.md

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
      externalurl: https://wishes.example.com
      generateinvite: true    # remove after first user is created
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
```

```bash
docker compose up -d
# Get the invite code from logs:
docker compose logs poenskelisten-app | grep -i invite
# Visit http://localhost:8080 and register with the invite code
```

After the first user is created, remove `generateinvite: true` from the compose file and restart.

## Install: Docker Compose (PostgreSQL)

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
      externalurl: https://wishes.example.com
      generateinvite: true    # remove after first user is created
    depends_on:
      - db
    volumes:
      - ./files/:/app/files/:rw
      - ./images/:/app/images/:rw
```

## Configuration reference

Key environment variables:

| Variable | Default | Description |
|---|---|---|
| dbtype | sqlite | sqlite, postgres, or mysql |
| dbip | — | DB host (PostgreSQL/MySQL) |
| dbport | — | DB port |
| dbname | — | DB name |
| dbusername | — | DB user |
| dbpassword | — | DB password |
| timezone | — | e.g. Europe/Oslo, America/New_York |
| externalurl | — | Public URL of the instance |
| port | 8080 | Listen port |
| generateinvite | false | Generate invite code on startup |
| smtphost | — | SMTP server |
| smtpport | — | SMTP port |
| smtpusername | — | SMTP user |
| smtppassword | — | SMTP password |
| smtpfrom | — | Sender address |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- generateinvite must be removed after first user: If left enabled, a new invite code is generated every time the container starts. Remove it once you've registered your first account.
- files/ and images/ must be writable: Uploaded images and files go here. If missing or not writable, uploads fail.
- PUID/PGID must match the owner of mounted directories: Ensure ./files/ and ./images/ on the host are owned by the UID/GID specified.
- No public registration by default: New users require an invite code. Share it to invite people.
- Claiming is anonymous to the wishlist owner: Friends can see who claimed what; the wish owner cannot. This is by design.

## Links

- GitHub: https://github.com/aunefyren/poenskelisten
- Docker Hub: https://hub.docker.com/r/aunefyren/poenskelisten
- Releases: https://github.com/aunefyren/poenskelisten/releases
