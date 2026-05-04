# Unleash

Open-source feature flag and feature management platform. Unleash lets you decouple feature releases from code deployments — control which users see which features in production without redeploying. Supports gradual rollouts, A/B testing, kill switches, and per-environment flags. 15+ official SDKs covering every major language. Upstream: <https://github.com/Unleash/unleash>. Docs: <https://docs.getunleash.io>.

Unleash listens on port `4242` by default. It requires a PostgreSQL database. Default login after fresh Docker deploy: `admin` / `unleash4all`.

## Compatible install methods

Verified against upstream docs at <https://docs.getunleash.io/using-unleash/deploy/getting-started>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/Unleash/unleash/blob/main/docker-compose.yml> | ✅ | Easiest self-hosted setup. Bundled PostgreSQL. |
| Docker (standalone) | <https://hub.docker.com/r/unleashorg/unleash-server> | ✅ | When using external PostgreSQL. |
| Helm chart (Kubernetes) | <https://github.com/Unleash/helm-charts> | ✅ | Production Kubernetes. |
| npm / Node.js | `npm install unleash-server` | ✅ | Embed in an existing Node.js app. |
| Unleash Cloud (hosted) | <https://www.getunleash.io> | ✅ | Managed SaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | "PostgreSQL connection string?" | Free-text (sensitive) — e.g. `postgres://user:pass@host:5432/unleash` | All |
| secrets | "Admin password? (or use default `unleash4all` for dev)" | Free-text (sensitive) | All |
| port | "Port for Unleash?" | Number (default 4242) | All |
| auth | "Authentication type?" | `AskUserQuestion`: `Username/Password` / `OIDC` / `SAML` (Enterprise) | All |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Required. Format: `postgres://user:pass@host:5432/db` |
| `DATABASE_SSL` | Enable SSL for DB connection | `"false"` for local; `"true"` for production |
| `INIT_BACKEND_API_TOKENS` | Seed backend API tokens on startup | e.g. `default:development.mytoken` |
| `INIT_FRONTEND_API_TOKENS` | Seed frontend API tokens on startup | e.g. `default:development.myfrontendtoken` |
| `LOG_LEVEL` | Log verbosity | `error`, `warn`, `info`, `debug` |
| `SECRET_KEY` | Session encryption secret | Auto-generated if not set. Set explicitly in production. |
| `TRIGGER_TELEMETRY_DISABLED` | Disable telemetry | Any non-empty value disables it |

### Docker Compose (development — bundled PostgreSQL)

From the official repo:

```yaml
services:
  web:
    image: unleashorg/unleash-server:latest
    ports:
      - "4242:4242"
    environment:
      DATABASE_URL: "postgres://postgres:unleash@db/unleash"
      DATABASE_SSL: "false"
      LOG_LEVEL: "warn"
      INIT_FRONTEND_API_TOKENS: "default:development.unleash-insecure-frontend-api-token"
      INIT_BACKEND_API_TOKENS: "default:development.unleash-insecure-api-token"
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: unleash
      POSTGRES_HOST_AUTH_METHOD: trust   # ⚠️ NOT for production
    healthcheck:
      test: ["CMD", "pg_isready", "--username=postgres", "--host=127.0.0.1", "--port=5432"]
      interval: 2s
      timeout: 60s
      retries: 5
      start_period: 15s

volumes:
  postgres_data:
```

> ⚠️ `POSTGRES_HOST_AUTH_METHOD: trust` means no password — **development only**. Use proper credentials in production.

Default access: `http://localhost:4242` — login `admin` / `unleash4all`.

### Production-ready Docker Compose

```yaml
services:
  unleash:
    image: unleashorg/unleash-server:latest
    ports:
      - "4242:4242"
    environment:
      DATABASE_URL: "postgres://unleash:${POSTGRES_PASSWORD}@db:5432/unleash"
      DATABASE_SSL: "false"
      SECRET_KEY: "${UNLEASH_SECRET_KEY}"
      LOG_LEVEL: "warn"
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: unleash
      POSTGRES_USER: unleash
      POSTGRES_PASSWORD: "${POSTGRES_PASSWORD}"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U unleash"]
      interval: 5s
      retries: 5

volumes:
  postgres_data:
```

### Connecting SDKs

After deploy, create API tokens in the UI (Configure → API access) and use them in your SDKs:

```js
// JavaScript SDK example
import { UnleashClient } from 'unleash-proxy-client';
const unleash = new UnleashClient({
  url: 'http://unleash.example.com/api/frontend',
  clientKey: 'default:development.myfrontendtoken',
  appName: 'my-app',
});
unleash.start();
if (unleash.isEnabled('my-feature')) { /* ... */ }
```

### Data directories

| Location | Contents |
|---|---|
| PostgreSQL volume | All feature flags, projects, strategies, users, audit log |

Unleash itself is stateless — all state is in PostgreSQL.

## Upgrade procedure

Based on <https://docs.getunleash.io/using-unleash/deploy/upgrading-unleash>:

1. Review the [changelog](https://github.com/Unleash/unleash/releases) for breaking changes.
2. Back up the PostgreSQL database.
3. `docker compose pull` then `docker compose up -d`.
4. Unleash runs DB migrations automatically on startup.
5. Verify in the UI that flags and strategies are intact.

## Gotchas

- **Change default credentials immediately.** The default `admin`/`unleash4all` is well-known.
- **`POSTGRES_HOST_AUTH_METHOD: trust` is dev-only.** This disables PostgreSQL passwords entirely. Always use proper credentials in production.
- **Feature flag types matter.** Unleash has multiple flag types (Release, Experiment, Operational, Permission, Kill switch). Choose the right type for your use case.
- **Frontend vs backend tokens are different.** Frontend tokens (client-side) have limited capabilities and must not expose your full backend token to browsers.
- **Metrics and usage:** Unleash collects per-flag impression data. The metrics storage can grow large over time — configure retention if needed.
- **Open-source tier vs Enterprise.** SSO (OIDC/SAML), RBAC beyond basic roles, and change requests require the Enterprise tier.

## Links

- Upstream: <https://github.com/Unleash/unleash>
- Docs: <https://docs.getunleash.io>
- Getting started: <https://docs.getunleash.io/using-unleash/deploy/getting-started>
- Docker Hub: <https://hub.docker.com/r/unleashorg/unleash-server>
- Helm charts: <https://github.com/Unleash/helm-charts>
- SDK list: <https://docs.getunleash.io/reference/sdks>
- Upgrade guide: <https://docs.getunleash.io/using-unleash/deploy/upgrading-unleash>
