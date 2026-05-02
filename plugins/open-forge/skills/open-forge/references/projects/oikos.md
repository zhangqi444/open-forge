# Oikos

A self-hosted family planner for small households. Runs as a Docker container, accessible from every device on the network, and installable as a PWA. Features shared tasks with Kanban board, grocery/shopping lists, meal planning with recipe scaling, shared calendar with Google Calendar (OAuth) and Apple iCloud (CalDAV) two-way sync, document management, budget tracking, notes, contacts, birthdays, and family management. SQLCipher AES-256 encrypted database, zero telemetry, 15 languages.

- **Official site / docs:** https://github.com/ulsklyc/oikos
- **Docker image:** `ghcr.io/ulsklyc/oikos:latest`
- **License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container + named volume |
| Any Docker host | Web Installer | Node.js-based interactive wizard (clone required) |

---

## Inputs to Collect

### Deploy Phase (required)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SESSION_SECRET` | **Yes** | — | Long random string for session signing (use `openssl rand -hex 32`) |
| `DB_ENCRYPTION_KEY` | **Yes** | — | Strong key for SQLCipher AES-256 database encryption |
| `PORT` | No | `3000` | HTTP port |
| `NODE_ENV` | No | `production` | Environment mode |

### Deploy Phase (optional integrations)
| Variable | Required | Description |
|----------|----------|-------------|
| `OPENWEATHER_API_KEY` | No | OpenWeatherMap API key for weather widget |
| `OPENWEATHER_CITY` | No | City for weather (e.g. `Berlin`) |
| `OPENWEATHER_UNITS` | No | `metric` or `imperial` |
| `OPENWEATHER_LANG` | No | Language code (e.g. `en`) |
| `GOOGLE_CLIENT_ID` | No | Google OAuth client ID for Google Calendar sync |
| `GOOGLE_CLIENT_SECRET` | No | Google OAuth client secret |
| `GOOGLE_REDIRECT_URI` | No | OAuth callback URL (e.g. `https://your-domain.com/api/v1/calendar/google/callback`) |
| `APPLE_CALDAV_URL` | No | Apple CalDAV URL (default: `https://caldav.icloud.com`) |
| `APPLE_USERNAME` | No | Apple ID username |
| `APPLE_APP_SPECIFIC_PASSWORD` | No | Apple app-specific password for CalDAV |
| `SYNC_INTERVAL_MINUTES` | No | Calendar sync interval in minutes (default: `15`) |
| `SESSION_SECURE` | No | Set `false` for direct HTTP (no reverse proxy); leave unset behind HTTPS proxy |
| `LOG_LEVEL` | No | `debug`, `info`, `warn`, `error` (default: `info`) |

Config is loaded from a `.env` file (copy from `.env.example`).

---

## Software-Layer Concerns

### Config
- `.env` file at project root (or environment variables in compose)
- `SESSION_SECRET` and `DB_ENCRYPTION_KEY` must be set before first run — cannot be changed after data is written

### Data Directories
- `oikos_data` (named volume) mounted at `/data` — SQLCipher database and uploads

### Ports
- `3000` — Web app (configurable via `PORT`)

---

## Minimal docker-compose.yml

```yaml
services:
  oikos:
    image: ghcr.io/ulsklyc/oikos:latest
    container_name: oikos
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - oikos_data:/data
    environment:
      - NODE_ENV=production
      - DB_PATH=/data/oikos.db
      - SESSION_SECRET=replace_with_long_random_string
      - DB_ENCRYPTION_KEY=replace_with_strong_key
      # For direct HTTP (no reverse proxy):
      - SESSION_SECURE=false

volumes:
  oikos_data:
```

Then create the admin account on first run:
```bash
docker compose exec oikos node setup.js
```

---

## Upgrade Procedure

```bash
docker compose pull oikos
docker compose up -d oikos
```

Data persists in the `oikos_data` volume; no manual migration needed.

---

## Gotchas

- **`SESSION_SECRET` and `DB_ENCRYPTION_KEY` are permanent:** Once data is written, changing these keys will make your database unreadable — back up before changing
- **`SESSION_SECURE=false` required for HTTP:** If accessing without HTTPS/reverse proxy, set this; otherwise sessions won't work
- **Admin setup required:** After first `docker compose up -d`, run `docker compose exec oikos node setup.js` to create the initial admin account
- **Web Installer alternative:** If you prefer a guided setup, clone the repo and run `node tools/installer/install-server.js` — it configures `.env`, starts Docker, and creates the admin account
- **No build step:** Oikos uses pure ES modules — no bundler required; updates are just image pulls
- **Google Calendar OAuth:** Requires a Google Cloud project with the Google Calendar API enabled and an OAuth consent screen configured
- **Apple CalDAV:** Uses an app-specific password (not your main Apple ID password) — generate in Apple ID account settings
- **File attachments:** 5 MB max per file for calendar events and documents

---

## References
- README: https://github.com/ulsklyc/oikos
- .env.example: https://raw.githubusercontent.com/ulsklyc/oikos/main/.env.example
- Docker image: https://github.com/ulsklyc/oikos/pkgs/container/oikos
