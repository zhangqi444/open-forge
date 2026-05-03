# LetterFeed

> Self-hosted email-to-RSS bridge — scans an IMAP mailbox for newsletters from configured senders and exposes each as an RSS feed, so you can read newsletters in any feed reader.

**URL:** https://github.com/LeonMusCoden/LetterFeed
**Source:** https://github.com/LeonMusCoden/LetterFeed
**License:** Not specified in README (check repository root)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker Compose | Separate backend + frontend containers; SQLite default |

## Inputs to Collect

### Provision phase
- IMAP mailbox credentials (server, username, password) — must support IMAP over SSL on port 993
- Public URL for the app (for feed URLs and frontend config)

### Deploy phase
- `LETTERFEED_IMAP_SERVER` — IMAP hostname
- `LETTERFEED_IMAP_USERNAME` — email address / IMAP username
- `LETTERFEED_IMAP_PASSWORD` — IMAP password or app password
- `LETTERFEED_SECRET_KEY` — session signing key (generate with `openssl rand -hex 32`)
- `LETTERFEED_AUTH_USERNAME` / `LETTERFEED_AUTH_PASSWORD` — UI login credentials
- `LETTERFEED_APP_BASE_URL` — public base URL (e.g. `http://localhost:3000`)
- `LETTERFEED_BACKEND_URL` — internal backend URL (default `http://backend:8000`)

## Software-layer Concerns

### Docker Compose
```yaml
services:
  backend:
    image: ghcr.io/leonmuscoden/letterfeed-backend:latest
    restart: unless-stopped
    env_file:
      - .env
    volumes:
      - letterfeed_data:/data
    networks:
      - letterfeed_network

  frontend:
    image: ghcr.io/leonmuscoden/letterfeed-frontend:latest
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - letterfeed_network

volumes:
  letterfeed_data:

networks:
  letterfeed_network:
    driver: bridge
```

### .env file
```bash
LETTERFEED_APP_BASE_URL=http://localhost:3000
LETTERFEED_BACKEND_URL=http://backend:8000

# SQLite (default) — change path only if you change the volume mount
LETTERFEED_DATABASE_URL=sqlite:////data/letterfeed.db

# IMAP
LETTERFEED_IMAP_SERVER=imap.example.com
LETTERFEED_IMAP_USERNAME=you@example.com
LETTERFEED_IMAP_PASSWORD=yourpassword

# Auth
LETTERFEED_SECRET_KEY=<openssl rand -hex 32>
LETTERFEED_AUTH_USERNAME=admin
LETTERFEED_AUTH_PASSWORD=changeme

# Optional processing settings
# LETTERFEED_SEARCH_FOLDER=INBOX
# LETTERFEED_MOVE_TO_FOLDER=Newsletters
# LETTERFEED_MARK_AS_READ=true
# LETTERFEED_EMAIL_CHECK_INTERVAL=15     # minutes between checks
# LETTERFEED_AUTO_ADD_NEW_SENDERS=false
```

### Config / env vars
- `LETTERFEED_APP_BASE_URL`: public URL of the frontend (used in generated feed URLs)
- `LETTERFEED_BACKEND_URL`: internal backend service URL (default `http://backend:8000`)
- `LETTERFEED_DATABASE_URL`: SQLite path or other SQLAlchemy DSN
- `LETTERFEED_IMAP_SERVER`: IMAP hostname (must support SSL on 993)
- `LETTERFEED_IMAP_USERNAME` / `LETTERFEED_IMAP_PASSWORD`: mailbox credentials
- `LETTERFEED_SEARCH_FOLDER`: IMAP folder to scan (default `INBOX`)
- `LETTERFEED_MOVE_TO_FOLDER`: move processed emails here (optional)
- `LETTERFEED_MARK_AS_READ`: mark scanned emails as read (default `true`)
- `LETTERFEED_EMAIL_CHECK_INTERVAL`: check frequency in minutes (default `15`)
- `LETTERFEED_AUTO_ADD_NEW_SENDERS`: auto-create a feed for new unknown senders (default `false`)
- `LETTERFEED_SECRET_KEY`: session signing key (required)
- `LETTERFEED_AUTH_USERNAME` / `LETTERFEED_AUTH_PASSWORD`: UI login (required)
- Settings set in `.env` are **locked** in the UI and cannot be changed there

### Data dirs
- `letterfeed_data` (named volume) → `/data` — SQLite database and feed data

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```

## Gotchas
- **IMAP over SSL port 993 required** — plain-text IMAP is not supported.
- **Settings in `.env` are locked in the UI** — to change IMAP credentials or other env-configured settings, update `.env` and restart.
- **No automatic sender discovery** — by default, only pre-configured senders get feeds; set `LETTERFEED_AUTO_ADD_NEW_SENDERS=true` to auto-create feeds for new senders.
- The backend and frontend are separate services; both must be in the same Docker network for inter-container communication.
- `LETTERFEED_BACKEND_URL` must use the Docker service name (`backend`), not `localhost`.

## Links
- [README](https://github.com/LeonMusCoden/LetterFeed/blob/main/README.md)
- [GitHub Container Registry — letterfeed-backend](https://github.com/LeonMusCoden/LetterFeed/pkgs/container/letterfeed-backend)
- [GitHub Container Registry — letterfeed-frontend](https://github.com/LeonMusCoden/LetterFeed/pkgs/container/letterfeed-frontend)
