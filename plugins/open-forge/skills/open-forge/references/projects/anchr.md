# Anchr

A small self-hosted toolbox for common internet tasks: bookmark collections (searchable, categorized), link shortening (with Google Safe Browsing malicious link checking), and encrypted image uploads (client-side AES encryption). Features OAuth2 authentication (Google, Facebook), Prometheus metrics, Telegram bot integration, browser extensions (Chrome/Firefox), and an official Android app.

- **Official site / docs:** https://github.com/muety/anchr
- **Hosted instance:** https://anchr.io
- **Docker image:** Built from source (no official image published)
- **License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Two containers: anchr (Node.js) + MongoDB |
| Any Node.js host | Direct | Node.js >= 21.x + MongoDB >= 6.x |

---

## Inputs to Collect

### Deploy Phase
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANCHR_DB_PASSWORD` | **Yes** | — | MongoDB password |
| `ANCHR_SECRET` | **Yes** | `shhh` | JWT secret — use a long random string |
| `ANCHR_PUBLIC_URL` | Yes | `http://localhost:3000` | Public base URL (no trailing slash) |
| `PORT` | No | `3000` | TCP port |
| `LISTEN_ADDR` | No | `127.0.0.1` | Bind address (set to `0.0.0.0` in Docker) |
| `ANCHR_DB_USER` | No | `anchr` | MongoDB username |
| `ANCHR_DB_HOST` | No | `localhost` | MongoDB host |
| `ANCHR_DB_PORT` | No | `27017` | MongoDB port |
| `ANCHR_DB_NAME` | No | `anchr` | MongoDB database name |
| `ANCHR_UPLOAD_DIR` | No | `/var/data/anchr` | Image upload storage path |
| `ANCHR_LOG_PATH` | No | `/var/log/anchr/access.log` | Access log path |
| `ANCHR_ERROR_LOG_PATH` | No | `/var/log/anchr/error.log` | Error log path |
| `ANCHR_GOOGLE_API_KEY` | No | `""` | Google API key for Safe Browsing link checks |
| `ANCHR_FB_CLIENT_ID` / `ANCHR_FB_SECRET` | No | `""` | Facebook OAuth credentials |
| `ANCHR_GOOGLE_CLIENT_ID` / `ANCHR_GOOGLE_SECRET` | No | `""` | Google OAuth credentials |
| `ANCHR_ALLOW_SIGNUP` | No | `true` | Allow new user signups |
| `ANCHR_VERIFY_USERS` | No | `false` | Require email verification for signups |
| `ANCHR_CHECK_LINKS` | No | `true` | Check shortlinks against blocklists |
| `ANCHR_BASIC_AUTH` | No | `true` | Allow HTTP Basic Auth |
| `ANCHR_EXPOSE_METRICS` | No | `false` | Expose Prometheus metrics at `/api/metrics` |
| `ANCHR_SMTP_HOST` | No | `""` | SMTP host for email (leave empty to disable) |

Config is loaded from a `.env` file (copy `.env.example` to `.env`).

---

## Software-Layer Concerns

### Config
- `.env` file at project root (copy from `.env.example`)
- Loaded via `env_file: .env` in compose

### Data Directories
- `anchr_data` — uploaded images (mounted at `ANCHR_UPLOAD_DIR`)
- `anchr_db_data` — MongoDB data

### Ports
- `3000` — Anchr web app (configurable via `PORT`)

### Database Setup
MongoDB requires a user to be created before first run. The compose file uses an init script (`scripts/mongo-init.sh`) to create the `anchr` database user automatically.

---

## Docker Compose Setup

Clone the repo first (no published Docker image — builds from source):

```bash
git clone https://github.com/muety/anchr
cd anchr
cp .env.example .env
# Edit .env: set ANCHR_DB_PASSWORD and ANCHR_SECRET at minimum
docker compose up -d
```

docker-compose.yml (from upstream):
```yaml
services:
  anchr:
    image: anchr:latest
    build: ./
    ports:
      - "${PORT}:${PORT}"
    volumes:
      - anchr_data:/app/data
    env_file: .env
    environment:
      - ANCHR_DB_HOST=mongo
      - ANCHR_DB_PORT=27017
      - LISTEN_ADDR=0.0.0.0
    depends_on:
      - mongo

  mongo:
    image: mongo:6.0
    volumes:
      - anchr_db_data:/data/db
      - ./scripts/mongo-init.sh:/docker-entrypoint-initdb.d/mongo-init.sh:ro
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${ANCHR_DB_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${ANCHR_DB_PASSWORD}
      - MONGO_INITDB_DATABASE=${ANCHR_DB_NAME}
      - DB_USER=${ANCHR_DB_USER}
      - DB_PASSWORD=${ANCHR_DB_PASSWORD}

volumes:
  anchr_data:
  anchr_db_data:
```

---

## Upgrade Procedure

```bash
git pull
docker compose build anchr
docker compose up -d
```

Data persists in named Docker volumes.

---

## Gotchas

- **No pre-built image:** Anchr must be built from source — clone the repo and use `docker compose up -d` (which triggers `build: ./`)
- **`.env` required:** The compose file uses `env_file: .env` — copy `.env.example` first and fill in required values
- **`ANCHR_SECRET`:** Change from default `shhh` — used for JWT signing; short/guessable values are insecure
- **MongoDB init script:** The `scripts/mongo-init.sh` creates the database user; if you skip the volume mount, the DB user won't exist and the app will fail to connect
- **`LISTEN_ADDR=0.0.0.0`:** Required in Docker (overrides the default `127.0.0.1` from `.env`)
- **Safe Browsing:** Requires a Google API key with the Safe Browsing API enabled; leave blank to disable
- **Email verification:** Only works when SMTP is configured

---

## References
- README: https://github.com/muety/anchr
- .env.example: https://github.com/muety/anchr/blob/master/.env.example
- Android app: https://github.com/muety/anchr-android
