---
name: supertokens-project
description: SuperTokens recipe for open-forge. Open-source authentication solution with passwordless, social/OAuth, email+password, MFA, and multi-tenancy support. Three-part architecture: Frontend SDK + Backend SDK + Core HTTP service. Docker images supertokens/supertokens-postgresql, supertokens/supertokens-mysql, supertokens/supertokens-mongodb. Self-hosted Core connects to a user-managed database. Upstream: https://github.com/supertokens/supertokens-core.
---

# SuperTokens

Open-source authentication and session management. Covers passwordless (OTP/magic link), social login (OAuth2), email+password, MFA (TOTP), and multi-tenancy. Upstream (Core): <https://github.com/supertokens/supertokens-core>. Docs: <https://supertokens.com/docs/>.

SuperTokens is a **three-part system**:
1. **Frontend SDK** — React, Vanilla JS, mobile (integrates into your app's frontend)
2. **Backend SDK** — Node.js, Python, Go, Java (integrates into your app's backend/API)
3. **Core** — standalone HTTP service that both SDKs talk to; stores sessions and auth data in a SQL/MongoDB database

The Core is what you self-host. The Frontend and Backend SDKs are library dependencies added to your application code.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (Core + PostgreSQL) | <https://supertokens.com/docs/quickstart> | ✅ | Recommended self-hosted production path with Postgres. |
| Docker (Core + MySQL) | <https://supertokens.com/docs/quickstart> | ✅ | Use `supertokens/supertokens-mysql` image for MySQL backend. |
| Docker (Core + MongoDB) | <https://supertokens.com/docs/quickstart> | ✅ | Use `supertokens/supertokens-mongodb` image (MongoDB backend). |
| Docker Compose | Upstream examples | ✅ | Core + DB in Compose — typical for self-hosting. |
| Manual install (JAR) | <https://supertokens.com/docs/community/self-host/core/with-docker> | ✅ | Run Core as a bare JAR on any OS with Java 11+. |
| SuperTokens managed service | <https://supertokens.com/pricing/> | ✅ | Upstream-hosted Core — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which database backend?" | `AskUserQuestion`: `PostgreSQL (recommended)` / `MySQL` / `MongoDB` | Determines image tag and DB config vars. |
| db | "Existing database, or provision a new one via Compose?" | `AskUserQuestion`: `Existing DB (provide connection string)` / `New DB in Compose` | Drives whether to include a DB service in Compose. |
| db | "Database host, port, name, user, password?" | Free-text fields | Connection parameters for Core's `config.yaml` / env vars. |
| network | "Which port should the Core listen on?" (default `3567`) | Free-text | Core HTTP API port. Backend SDK points to this. |
| api_key | "Set an API key to protect the Core HTTP API?" (recommended) | `AskUserQuestion`: `Yes — generate one` / `Skip (for local dev only)` | Without an API key, any client can call the Core. |
| app | "What are your app name, API domain, and website domain?" | Free-text | Set in `config.yaml` or env: `APP_NAME`, `API_DOMAIN`, `WEBSITE_DOMAIN`. |
| recipe | "Which auth recipes to enable?" | Multi-select: `emailpassword`, `passwordless`, `thirdparty`, `totp`, `session` | Configured in the Backend SDK, not the Core. Core supports all by default. |

## Software-layer concerns

### Docker images

| Image | Database | Notes |
|---|---|---|
| `supertokens/supertokens-postgresql` | PostgreSQL 9.6+ | Recommended |
| `supertokens/supertokens-mysql` | MySQL 5.7+ / 8.0+ | |
| `supertokens/supertokens-mongodb` | MongoDB 4.4+ | |

Tags follow the Core version: `supertokens/supertokens-postgresql:9.0` etc. Check current tags at <https://hub.docker.com/r/supertokens/supertokens-postgresql/tags>.

### Core environment variables / config.yaml

The Core can be configured via `config.yaml` (mount to `/usr/lib/supertokens/config.yaml`) or via environment variables. Key variables:

| Variable / Key | Default | Description |
|---|---|---|
| `POSTGRESQL_CONNECTION_URI` | — | Full Postgres connection URI (alternative to host/port/user/pass) |
| `POSTGRESQL_HOST` | `localhost` | Postgres host |
| `POSTGRESQL_PORT` | `5432` | Postgres port |
| `POSTGRESQL_DATABASE_NAME` | `supertokens` | Database name |
| `POSTGRESQL_USER` | — | DB username |
| `POSTGRESQL_PASSWORD` | — | DB password |
| `API_KEYS` | — | Comma-separated API keys; if set, all Core requests must include `api-key` header |
| `SUPERTOKENS_PORT` | `3567` | Port Core listens on |
| `ACCESS_TOKEN_VALIDITY` | `3600` | Access token validity in seconds |
| `REFRESH_TOKEN_VALIDITY` | `144000` | Refresh token validity in minutes |

Full config reference: <https://supertokens.com/docs/community/self-host/core/config-file-reference>.

### Ports

- Core HTTP API: `3567` (configurable)

### Data directory

Core state is stored entirely in the database — no persistent bind-mount needed for the Core container itself.

### Docker Compose (Core + PostgreSQL)

Based on upstream self-hosting docs:

```yaml
# compose.yaml
services:
  supertokens:
    image: supertokens/supertokens-postgresql:latest
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "127.0.0.1:3567:3567"
    environment:
      POSTGRESQL_CONNECTION_URI: "postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}"
      API_KEYS: "${SUPERTOKENS_API_KEY}"
    restart: unless-stopped
    healthcheck:
      test: >
        bash -c 'exec 3<>/dev/tcp/127.0.0.1/3567 && echo -e "GET /hello HTTP/1.1\r\nhost: 127.0.0.1:3567\r\nConnection: close\r\n\r\n" >&3 && cat <&3 | grep "Hello"'
      interval: 10s
      timeout: 5s
      retries: 5

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: "${DB_USER}"
      POSTGRES_PASSWORD: "${DB_PASSWORD}"
      POSTGRES_DB: "${DB_NAME}"
    volumes:
      - db_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "${DB_USER}", "-d", "${DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  db_data:
```

```bash
docker compose up -d

# Verify Core is up
curl http://localhost:3567/hello
# Expected: "Hello"
```

### Verify

```bash
# Basic liveness
curl http://localhost:3567/hello

# With API key
curl -H "api-key: ${SUPERTOKENS_API_KEY}" http://localhost:3567/hello
```

### Backend SDK integration

Once the Core is running, add the Backend SDK to your application. Example (Node.js / Express):

```bash
npm install supertokens-node
```

Then initialise in your app (see <https://supertokens.com/docs/quickstart/backend-setup>):

```javascript
const supertokens = require("supertokens-node");
supertokens.init({
  framework: "express",
  supertokens: {
    connectionURI: "http://localhost:3567",
    apiKey: process.env.SUPERTOKENS_API_KEY,
  },
  appInfo: {
    appName: process.env.APP_NAME,
    apiDomain: process.env.API_DOMAIN,
    websiteDomain: process.env.WEBSITE_DOMAIN,
  },
  recipeList: [/* emailpassword, passwordless, thirdparty, session, etc. */],
});
```

Frontend SDK integration: <https://supertokens.com/docs/quickstart/frontend-setup>.

## Upgrade procedure

Per upstream docs at <https://supertokens.com/docs/community/self-host/core/updating-the-core>:

1. **Read the migration guide** for the target version — breaking changes and DB migration notes are listed per release at <https://github.com/supertokens/supertokens-core/releases>.
2. Check SDK compatibility: Core version must be compatible with your Backend and Frontend SDK versions. Compatibility matrix: <https://supertokens.com/docs/community/compatibility-table>.
3. **Backup the database** before upgrading.
4. Pull the new Core image and restart:

```bash
docker compose pull supertokens
docker compose up -d supertokens
# Core runs DB migrations automatically on startup
```

5. Upgrade Backend SDK and Frontend SDK to compatible versions in your application code.
6. Verify with `curl http://localhost:3567/hello` and run your app's auth flow.

## Gotchas

- **Three-part system — the Core alone does nothing.** You must also integrate the Backend SDK and Frontend SDK into your application. The Core is just the storage and session service; auth flows are orchestrated by the Backend SDK.
- **SDK ↔ Core version compatibility is strict.** Using a Backend SDK that's too new for your Core version (or vice versa) will cause API errors. Always check the compatibility table before upgrading any component.
- **API key required for production.** Without `API_KEYS` set, the Core API is open to anyone who can reach the port. Always set an API key for anything beyond local development.
- **Core auto-runs DB migrations on startup.** There is no separate migration command — it runs on boot. Back up the database before upgrading the Core image.
- **DB schemas are created automatically** — no need to pre-create tables. The Core creates the SuperTokens schema on first run.
- **Multi-tenancy requires a paid license for some features.** Basic multi-tenancy is open-source; enterprise features (Active Directory, SAML, advanced tenant isolation) require a commercial license. Check <https://supertokens.com/pricing/> for the current feature split.
- **Port 3567 must be reachable from your backend, not your frontend.** The Frontend SDK calls your backend, which calls the Core. The Core should NOT be directly reachable from the browser.

## Upstream references

- Core GitHub: <https://github.com/supertokens/supertokens-core>
- Docs (self-hosting): <https://supertokens.com/docs/community/self-host>
- Quickstart: <https://supertokens.com/docs/quickstart>
- Config reference: <https://supertokens.com/docs/community/self-host/core/config-file-reference>
- SDK compatibility matrix: <https://supertokens.com/docs/community/compatibility-table>
- Docker Hub (PostgreSQL image): <https://hub.docker.com/r/supertokens/supertokens-postgresql>
- Release notes: <https://github.com/supertokens/supertokens-core/releases>
