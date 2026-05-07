---
name: everydocs
description: EveryDocs recipe for open-forge. Simple Document Management System (DMS) for private use. Upload, organize, and search PDF documents with optional encrypted storage. Source: https://github.com/jonashellmann/everydocs-core
---

# EveryDocs

Simple Document Management System for private use. Upload PDF documents with title, description, and date; organize in folders; add people and processing states; full-text search via PDF content extraction; optional per-user encrypted storage. Two components: everydocs-core (Rails REST API) and everydocs-web (Vue.js frontend).

Upstream (core): <https://github.com/jonashellmann/everydocs-core>
Upstream (web UI): <https://github.com/jonashellmann/everydocs-web>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Core + web UI + MariaDB in one compose file — recommended |
| Any | Docker (core only) | API on :5678; bring your own frontend and DB |
| Linux | Ruby on Rails (manual) | Not recommended; use Docker |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | SECRET_KEY_BASE | Generate: openssl rand -hex 64 |
| config | Database password | Stored in compose env; change from default |
| config | API URL for web UI | Where everydocs-core will be publicly reachable (for the frontend config) |
| config | File storage path on host | e.g. /data/everydocs; mounted to /var/everydocs-files |
| config | Encryption per user | Optional — set secret_key per user in DB + enable flag |

## Software-layer concerns

### Architecture

- **everydocs-core**: Ruby on Rails REST API on port 5678. Handles auth (JWT), document CRUD, PDF text extraction, file storage.
- **everydocs-web**: Vue.js SPA on port 8080 (HTTP) / 8443 (HTTPS). Talks to the core API. Configured via a mounted `config.js` file.
- **Database**: MariaDB (default in compose). MySQL also works.

### Config file for web UI

The web frontend needs a `config.js` telling it where the API lives:

```js
// everydocs-web-config.js
window.config = {
  backendUrl: "http://YOUR_SERVER_IP_OR_DOMAIN:5678"
}
```

Mount this as: `./everydocs-web-config.js:/usr/local/apache2/htdocs/config.js`

### Environment variables (core)

| Var | Description | Default |
|---|---|---|
| SECRET_KEY_BASE | Rails secret key (mandatory) | (none) |
| EVERYDOCS_DB_ADAPTER | Database adapter | mysql2 |
| EVERYDOCS_DB_NAME | Database name | everydocs |
| EVERYDOCS_DB_USER | DB user | everydocs |
| EVERYDOCS_DB_PASSWORD | DB password | (none) |
| EVERYDOCS_DB_HOST | DB host | localhost |
| EVERYDOCS_DB_PORT | DB port | 3306 |

### Data dirs

- Uploaded files: `/var/everydocs-files/` inside the container. Bind-mount a host directory for persistence.
- Database: external MariaDB/MySQL.

### Encryption

Encryption is per-user and optional. To enable for a user:
1. Generate a key: `openssl rand -hex 32`
2. Set `secret_key` column in the `users` table to that key
3. Set `encryption_actived_flag` to true for that user

Note: when encryption is active for a user, PDF content extraction (and thus full-text search) is disabled for their documents.

## Install — Docker Compose (recommended)

```bash
mkdir everydocs && cd everydocs

# Create the web UI config
cat > everydocs-web-config.js << 'EOF'
window.config = {
  backendUrl: "http://YOUR_SERVER:5678"
}
EOF

cat > docker-compose.yml << 'EOF'
version: '2.1'
services:
  everydocs_core:
    image: jonashellmann/everydocs:latest
    restart: unless-stopped
    depends_on:
      everydocs_db:
        condition: service_healthy
    environment:
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - EVERYDOCS_DB_ADAPTER=mysql2
      - EVERYDOCS_DB_NAME=everydocs
      - EVERYDOCS_DB_USER=everydocs
      - EVERYDOCS_DB_PASSWORD=${DB_PASSWORD}
      - EVERYDOCS_DB_HOST=everydocs_db
      - EVERYDOCS_DB_PORT=3306
    volumes:
      - /data/everydocs:/var/everydocs-files
    ports:
      - '5678:5678'

  everydocs_web:
    image: jonashellmann/everydocs-web:latest
    restart: unless-stopped
    volumes:
      - ./everydocs-web-config.js:/usr/local/apache2/htdocs/config.js
    ports:
      - '8080:80'
      - '8443:443'

  everydocs_db:
    image: mariadb:10.11
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=everydocs
      - MYSQL_USER=everydocs
      - MYSQL_PASSWORD=${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:
EOF

# Set secrets
export SECRET_KEY_BASE=$(openssl rand -hex 64)
export DB_PASSWORD=$(openssl rand -hex 16)
export DB_ROOT_PASSWORD=$(openssl rand -hex 16)

# Start
docker compose up -d
```

- Core API: http://localhost:5678
- Web UI: http://localhost:8080

Edit `everydocs-web-config.js` with the correct API URL before starting if accessed from outside localhost.

## Install — Docker (core only)

```bash
docker run -p 127.0.0.1:5678:5678/tcp \
  -e SECRET_KEY_BASE="$(openssl rand -hex 64)" \
  -v /data/everydocs:/var/everydocs-files \
  jonashellmann/everydocs
```

Requires an external MySQL/MariaDB — pass EVERYDOCS_DB_* vars as needed.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check release notes for DB migration steps: https://github.com/jonashellmann/everydocs-core/releases

## Gotchas

- Account registration is open — there is currently no invite-only mode. Anyone who can reach the URL can create an account. Restrict network access or put behind an auth proxy before public exposure.
- SECRET_KEY_BASE is mandatory — the Rails app will refuse to start without it.
- Encryption disables full-text search — when a user's encryption is active, PDF text extraction does not run, so those documents are not searchable by content.
- everydocs-web-config.js must point to the publicly reachable API URL — not localhost — when the web UI is accessed from a browser outside the server.
- The upstream compose file uses hardcoded passwords in the example — always replace with generated secrets before deploying.

## Links

- Core (API): https://github.com/jonashellmann/everydocs-core
- Web UI: https://github.com/jonashellmann/everydocs-web
- Releases: https://github.com/jonashellmann/everydocs-core/releases
