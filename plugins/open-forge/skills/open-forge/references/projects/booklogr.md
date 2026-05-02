# BookLogr

**What it is:** Simple self-hosted personal book library tracker. Search and add books by title or ISBN (powered by OpenLibrary), track reading status (Reading / Already Read / To Be Read / Did Not Finish), log current page, rate books (0.5–5 stars), take notes and save quotes, share a public library profile, export data (CSV/JSON/HTML), and optionally share reading progress to Mastodon.

**Official site:** https://booklogr.app  
**Demo:** https://demo.booklogr.app  
**Docs:** https://booklogr.app/docs/Getting%20started  
**GitHub:** https://github.com/Mozzo1000/booklogr

> ⚠️ **Active development** — expect bugs and breaking changes. Back up data before upgrading.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Two containers: API + web frontend |
| Bare metal | Python + Node.js | API (Flask) + frontend (Vue) separately |

---

## Stack Components

| Container | Image | Port | Role |
|-----------|-------|------|------|
| `booklogr-api` | `mozzo/booklogr:v1.9.0` | `5000` | Flask API backend |
| `booklogr-web` | `mozzo/booklogr-web:v1.9.0` | `5150` | Vue.js frontend |

---

## Inputs to Collect

### Phase: Deploy (`.env` file)

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | SQLite (default `sqlite:///books.db`) or PostgreSQL connection string |
| `AUTH_SECRET_KEY` | Secret key for auth token signing — generate a strong random string |

### Phase: Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `AUTH_ALLOW_REGISTRATION` | Allow public registration | `True` |
| `AUTH_REQUIRE_VERIFICATION` | Require email verification on signup | `False` |
| `SINGLE_USER_MODE` | Disable multi-user; single account only | `False` |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Enable Google OAuth login | Empty (disabled) |
| `MAIL_SERVER`, `MAIL_USERNAME`, etc. | SMTP for email verification/notifications | Empty |
| `BL_API_ENDPOINT` | Frontend env — URL of the API accessible to the browser | `http://localhost:5000/` |
| `BL_GOOGLE_ID` | Frontend env — Google Client ID for Google login | Empty |

---

## Software-Layer Concerns

- **SQLite default** — stored in `./data:/app/instance`; persist this volume; for production consider PostgreSQL
- **`BL_API_ENDPOINT` must be the public-facing URL** of the API — this is embedded in the frontend and called from the user's browser; `localhost` only works if browser and API are on the same machine
- **Two separate containers** — API and web frontend must both be running
- **OpenLibrary integration** — book search and metadata (no API key required)
- **Mastodon integration** — optional; configure per-user in app settings
- **Export formats** — CSV, JSON, HTML — available from user settings

---

## Example Docker Compose

```yaml
services:
  booklogr-api:
    container_name: booklogr-api
    image: mozzo/booklogr:v1.9.0
    env_file: .env
    ports:
      - "5000:5000"
    volumes:
      - ./data:/app/instance

  booklogr-web:
    container_name: booklogr-web
    image: mozzo/booklogr-web:v1.9.0
    env_file: .env
    environment:
      BL_API_ENDPOINT: https://booklogr-api.example.com/
      BL_GOOGLE_ID: ""
      BL_DEMO_MODE: "false"
    ports:
      - "5150:80"
```

---

## Upgrade Procedure

1. Update image tags in `docker-compose.yml` to new version
2. Pull: `docker compose pull`
3. Restart: `docker compose up -d`
4. Back up `./data` before upgrading (active development = potential breaking changes)

---

## Gotchas

- **`BL_API_ENDPOINT` must be externally reachable** — not `localhost` unless testing locally; set to the public API URL
- **Hardcoded version tags** — update both `booklogr` and `booklogr-web` image tags together when upgrading
- **Active development warning** — data migrations may not always be smooth; always back up before upgrades
- Google login requires both `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` in the API env AND `BL_GOOGLE_ID` in the frontend env

---

## Links

- Website: https://booklogr.app
- Demo: https://demo.booklogr.app
- Docs: https://booklogr.app/docs/Getting%20started
- GitHub: https://github.com/Mozzo1000/booklogr
