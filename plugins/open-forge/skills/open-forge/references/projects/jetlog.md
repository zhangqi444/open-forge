# Jetlog

**What it is:** Self-hostable personal flight tracker and viewer. Lets you log past flights with world-map visualisation, statistics, CSV/iCal export, and import from MyFlightRadar24. Supports multiple users with secure authentication. Uses an external API (adsbdb.com) for automatic flight data lookup by flight number (optional, can be disabled for privacy).

**Official URL:** https://github.com/pbogre/jetlog

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `SECRET_KEY` | Long random string for session signing — required |
| Deploy | Data directory path | Mounted at `/data`; contains SQLite database |
| Deploy | Host port | Default `3000` |
| Optional | `JETLOG_PORT` | Override container listen port (default `3000`) |
| Optional | `ENABLE_EXTERNAL_APIS` | Set to `false` to disable adsbdb.com lookups (privacy) |

---

## Software-Layer Concerns

### Docker image
```
pbogre/jetlog:latest
```

### docker-compose.yml
```yaml
services:
  jetlog:
    image: pbogre/jetlog:latest
    volumes:
      - ./data:/data
    environment:
      JETLOG_PORT: 3000        # optional, default is 3000
      SECRET_KEY: yourLongAndRandomStringOfCharacters123!
    restart: unless-stopped
    ports:
      - 3000:3000
```

### Data directory
- SQLite database stored in `/data` inside the container
- Create host directory before first start: `mkdir data`

### Default credentials
- Default admin username and password: **`admin` / `admin`**
- **Change the password immediately after first login**

### Stack
- FastAPI + SQLite backend
- React + TailwindCSS frontend

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database persists in the mounted volume. No explicit migration step documented; check release notes for schema changes.

---

## Gotchas

- **Change default password immediately** — the default `admin`/`admin` credentials are public knowledge
- **`SECRET_KEY` is required** — without it, sessions won't work properly; generate with `openssl rand -hex 32`
- **External API privacy** — by default, Jetlog calls `adsbdb.com` to look up flight data by flight number; set `ENABLE_EXTERNAL_APIS=false` if you don't want to share flight numbers with a third party
- **Path prefix support** — Jetlog can be deployed under a path prefix (e.g. `/jetlog`); see the [installation wiki](https://github.com/pbogre/jetlog/wiki/Installation) for configuration details
- **Import formats** — CSV import follows a custom format; MyFlightRadar24 CSV export is directly supported; see [importing wiki](https://github.com/pbogre/jetlog/wiki/Importing)

---

## Links

- GitHub: https://github.com/pbogre/jetlog
- Installation wiki: https://github.com/pbogre/jetlog/wiki/Installation
- Usage wiki: https://github.com/pbogre/jetlog/wiki/Usage
- Importing guide: https://github.com/pbogre/jetlog/wiki/Importing
- Docker Hub: https://hub.docker.com/r/pbogre/jetlog
