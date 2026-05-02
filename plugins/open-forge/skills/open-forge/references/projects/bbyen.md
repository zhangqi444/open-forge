# BBYEN

**What it is:** Brings back YouTube email notifications. Polls your YouTube subscriptions via the YouTube Data API and RSS feeds, then sends email notifications for new uploads via SMTP — replicating the feature YouTube removed in 2020. Keeps a local SQLite database to avoid duplicate notifications.

**Official URL:** https://github.com/MarcelRobitaille/bbyen
**Container:** `marcelrobitaille/bbyen:2.0.1`
**License:** MIT
**Stack:** Node.js + SQLite; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Any Linux VPS | Node.js (bare metal) | Requires Node 16+; 20 recommended |

---

## Inputs to Collect

### Pre-deployment (config.json, required)
- **YouTube Data API v3 key** — from Google Cloud Console; needed to list subscriptions
- **Google OAuth credentials** — for authenticating as a YouTube user (see gotchas)
- **SMTP settings** — `email.host`, `email.auth.user`, `email.auth.pass`, `email.sendingContact`
- **YouTube account** — the account whose subscriptions to poll

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  bbyen:
    image: marcelrobitaille/bbyen:2.0.1
    container_name: bbyen
    volumes:
      - ./config.json:/usr/src/app/config.json
      - ./google-credentials.json:/usr/src/app/google-credentials.json
      - ./.google-auth-token.json:/usr/src/app/.google-auth-token.json
      - ./database.sqlite:/usr/src/app/database.sqlite
    ports:
      - "3050:3050"
    restart: unless-stopped
```

**Setup files (all in the same directory as docker-compose.yml):**
- `config.json` — copy from `config.example.json` in the repo; fill in SMTP and YouTube settings
- `google-credentials.json` — OAuth client credentials from Google Cloud Console
- `.google-auth-token.json` — auto-generated on first auth; create as empty file initially: `touch .google-auth-token.json`
- `database.sqlite` — auto-created; create as empty file initially: `touch database.sqlite`

**Google API setup:**
1. Go to https://console.cloud.google.com → Create a project
2. Enable **YouTube Data API v3**
3. Create credentials: OAuth 2.0 Client ID (Desktop app type)
4. Download `credentials.json` → rename to `google-credentials.json`
5. On first run, BBYEN opens a browser to complete OAuth authentication and saves the token

**Port 3050** — used during the initial OAuth flow to receive the Google redirect; can be removed from compose after first auth is complete.

**Upgrade procedure:**
```yaml
# Update image tag in docker-compose.yml, then:
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Google OAuth required** — BBYEN needs to authenticate as your Google account to read YouTube subscriptions; the OAuth flow is a one-time browser step
- **YouTube Data API v3 quota** — free tier provides 10,000 units/day; subscription polling uses ~1 unit per channel checked; large subscription lists may hit limits
- **Port 3050 only needed for initial OAuth** — after the `.google-auth-token.json` is populated, the port mapping can be removed
- **Pre-create empty SQLite and token files** — Docker won't create files; if the volumes don't exist as files, Docker mounts them as directories and the app breaks
- **RSS feed polling** — after listing subscriptions, BBYEN uses YouTube RSS feeds (not the API) to check for new videos, saving API quota

---

## Links
- GitHub: https://github.com/MarcelRobitaille/bbyen
- Docker Hub: https://hub.docker.com/r/marcelrobitaille/bbyen
- YouTube Data API: https://developers.google.com/youtube/v3/
