---
name: traduora
description: Traduora (Ever Traduora) recipe for open-forge. Covers Docker Compose install. Traduora is an open-source translation management platform for teams — manage localization strings, invite collaborators, import/export in multiple formats.
---

# Traduora (Ever Traduora)

Open-source translation management platform for software teams. Centralizes localization strings across projects, lets team members collaborate on translations, and supports import/export in JSON (flat/nested), CSV, YAML, Java Properties, XLIFF 1.2, Gettext (.po), Strings, and Android Resources (.xml). Delivers translations via REST API for OTA updates. Upstream: <https://github.com/ever-co/ever-traduora>. Website: <https://traduora.co>. Docs: <https://docs.traduora.co>.

**License:** AGPL-3.0 · **Language:** Node.js / TypeScript · **Default port:** 8080 · **Stars:** ~2,100

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/ever-co/ever-traduora> | ✅ | **Recommended** — includes app + MySQL. |
| Kubernetes | <https://docs.traduora.co/docs/deploy/kubernetes> | ✅ | K8s / Helm deployments. |
| Build from source | <https://docs.traduora.co/docs/contributing> | ✅ | Development. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app_secret | "Random secret for JWT signing (generate with: openssl rand -hex 32)" | Free-text | All methods. |
| db_password | "MySQL root and app password?" | Free-text | All methods. |
| first_user_email | "Initial admin email address?" | Email | All methods. |
| first_user_password | "Initial admin password?" | Free-text | All methods. |

## Install — Docker Compose

```bash
git clone https://github.com/ever-co/ever-traduora.git
cd ever-traduora

# Copy the demo compose file
cp docker-compose.demo.yaml docker-compose.override.yml
```

Edit `docker-compose.override.yml` and set your secrets, or create a `.env` file:

```bash
cat > .env << 'EOF'
APP_SECRET=your-random-secret-here
DB_PASSWORD=strongpassword
FIRST_USER_EMAIL=admin@example.com
FIRST_USER_PASSWORD=adminpassword
EOF
```

Start:

```bash
docker-compose -f docker-compose.demo.yaml up -d
```

Access the UI at `http://localhost:8080`.

### Minimal production Docker Compose

```yaml
services:
  traduora:
    image: everco/ever-traduora:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      APP_SECRET: "${APP_SECRET}"
      DB_TYPE: mysql
      DB_HOST: db
      DB_PORT: 3306
      DB_DATABASE: traduora
      DB_USER: traduora
      DB_PASSWORD: "${DB_PASSWORD}"
      FIRST_USER_EMAIL: "${FIRST_USER_EMAIL}"
      FIRST_USER_PASSWORD: "${FIRST_USER_PASSWORD}"
      FRONTEND_URL: "http://localhost:8080"
    depends_on:
      - db

  db:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_PASSWORD}"
      MYSQL_DATABASE: traduora
      MYSQL_USER: traduora
      MYSQL_PASSWORD: "${DB_PASSWORD}"
    volumes:
      - traduora-db:/var/lib/mysql

volumes:
  traduora-db:
```

## Key environment variables

| Variable | Description | Default |
|---|---|---|
| `APP_SECRET` | JWT signing secret — **must be set** | (none) |
| `DB_TYPE` | Database type: `mysql` or `postgres` | `mysql` |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `3306` |
| `DB_DATABASE` | Database name | `traduora` |
| `DB_USER` | Database user | (none) |
| `DB_PASSWORD` | Database password | (none) |
| `FIRST_USER_EMAIL` | Admin email for first-run setup | (none) |
| `FIRST_USER_PASSWORD` | Admin password for first-run setup | (none) |
| `FRONTEND_URL` | Public URL of the app (used for CORS) | `http://localhost:8080` |
| `JWT_EXPIRY` | JWT token expiry duration | `7d` |
| `MAX_IMPORT_SIZE_BYTES` | Max file size for translation imports | `20971520` (20 MB) |

Full configuration reference: <https://docs.traduora.co/docs/configuration>

## Core workflow

1. **Sign up / log in** at `http://your-server:8080`
2. **Create a project** → add locales (e.g. en, fr, de, ja)
3. **Import existing translations** (JSON, XLIFF, CSV, etc.) via the UI or API
4. **Invite team members** → assign Viewer, Editor, or Admin roles per project
5. **Edit translations** in the browser UI
6. **Export** in your app's required format
7. **Integrate via API** for automated OTA delivery

## REST API access

Traduora exposes a REST API for CI/CD integration:

```bash
# Get auth token
TOKEN=$(curl -sf -X POST http://localhost:8080/api/v1/auth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"YOUR_ID","client_secret":"YOUR_SECRET"}' \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Export translations
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8080/api/v1/projects/PROJECT_ID/exports?locale=en&format=jsonflat"
```

API docs: <https://docs.traduora.co/docs/category/wildduck-api>

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | Requires MySQL 5.7+ or PostgreSQL 10+. Not embedded — must be provided separately. |
| APP_SECRET | Must be set before first run. Changing it after users are registered will invalidate all existing sessions. |
| First user | `FIRST_USER_EMAIL` / `FIRST_USER_PASSWORD` only take effect on first run when no users exist. |
| CORS | Set `FRONTEND_URL` to your public URL — incorrect value causes browser login failures when behind a reverse proxy. |
| Reverse proxy | Run behind nginx/Caddy with TLS. The app itself has no built-in TLS. |
| Multi-tenant | Multiple teams/projects can share one Traduora instance — each project has its own member roles. |
| API clients | Community CLI available at <https://github.com/iilei/traduora-cli> (unofficial). |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the changelog for migration steps: <https://github.com/ever-co/ever-traduora/blob/develop/CHANGELOG.md>

## Gotchas

- **APP_SECRET is mandatory:** Starting without it will cause startup failure or generate a random secret that changes on restart (invalidating all JWTs).
- **FRONTEND_URL must match your actual URL:** If your instance is at `https://translate.example.com`, set `FRONTEND_URL` to that — otherwise the browser will reject API responses due to CORS.
- **First user only creates once:** The `FIRST_USER_EMAIL` / `FIRST_USER_PASSWORD` env vars only apply on the very first run. After the database has a user, these are ignored.
- **Database migrations run automatically:** Traduora runs DB migrations on startup. Don't interrupt the first startup.
- **Project archived state:** Traduora doesn't have a "delete project" button — projects are archived. Archived projects still count toward storage.
- **Slow development pace:** Commits are sporadic (ever-co maintains several open-source projects). The core product is feature-complete but don't expect rapid iteration.

## Upstream links

- GitHub: <https://github.com/ever-co/ever-traduora>
- Website: <https://traduora.co>
- Docs: <https://docs.traduora.co>
- Configuration: <https://docs.traduora.co/docs/configuration>
- Docker Hub: <https://hub.docker.com/r/everco/ever-traduora>
- API reference: <https://docs.traduora.co/docs/category/wildduck-api>
