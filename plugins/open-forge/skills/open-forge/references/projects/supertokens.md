---
name: supertokens
description: Recipe for SuperTokens — open-source authentication and session management platform (Auth0/Cognito alternative).
---

# SuperTokens

Open-source, self-hostable authentication and session management platform. Drop-in alternative to Auth0, Cognito, and Firebase Auth. Provides email/password, passwordless, social login, MFA, multi-tenancy, user roles, and session management via SDKs for React, Node.js, Python, Go, and more. Architecture: frontend SDK + backend SDK + SuperTokens Core (this service). Upstream: <https://github.com/supertokens/supertokens-core>. Docs: <https://supertokens.com/docs>. License: Apache-2.0 (core). ~14K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://supertokens.com/docs/thirdpartyemailpassword/pre-built-ui/setup/core/with-docker> | Yes | Recommended |
| Docker Compose | <https://supertokens.com/docs/thirdpartyemailpassword/pre-built-ui/setup/core/with-docker> | Yes | Full stack with PostgreSQL |
| Helm chart | <https://github.com/supertokens/supertokens-helm-charts> | Yes | Kubernetes |
| Managed cloud | <https://supertokens.com/pricing> | Yes (managed) | No self-hosting needed (free tier available) |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Database? | postgresql / mysql | Required; no SQLite in production |
| infra | Database URL? | postgresql://user:pass@host:5432/supertokens | Required |
| software | API key for core? | String | Required; used by backend SDK to communicate with core |
| software | Which auth recipes to enable? | emailpassword / passwordless / thirdparty / session | Required |
| software | SMTP credentials (for email)? | host:port + user/pass | Required for passwordless, account verification |

## Software-layer concerns

### Docker Compose (with PostgreSQL)

```yaml
services:
  supertokens-db:
    image: postgres:16
    container_name: supertokens-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: supertokens
      POSTGRES_PASSWORD: secretpassword
      POSTGRES_DB: supertokens
    volumes:
      - supertokens-db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "supertokens"]
      interval: 5s
      timeout: 5s
      retries: 5

  supertokens:
    image: registry.supertokens.io/supertokens/supertokens-postgresql:latest
    container_name: supertokens
    restart: unless-stopped
    depends_on:
      supertokens-db:
        condition: service_healthy
    ports:
      - "3567:3567"
    environment:
      POSTGRESQL_CONNECTION_URI: postgresql://supertokens:secretpassword@supertokens-db:5432/supertokens
      API_KEYS: your-api-key-here     # used by your backend SDK to authenticate with core

volumes:
  supertokens-db-data:
```

### Database-specific images

| Database | Image |
|---|---|
| PostgreSQL | registry.supertokens.io/supertokens/supertokens-postgresql |
| MySQL | registry.supertokens.io/supertokens/supertokens-mysql |

### Key environment variables

| Variable | Description |
|---|---|
| POSTGRESQL_CONNECTION_URI | PostgreSQL DSN |
| MYSQL_CONNECTION_URI | MySQL DSN |
| API_KEYS | Comma-separated API keys; backend SDKs must provide one |
| SUPERTOKENS_PORT | HTTP port (default 3567) |
| LOG_LEVEL | DEBUG / INFO / WARN / ERROR |

### Backend SDK integration (Node.js example)

```typescript
import supertokens from "supertokens-node";
import Session from "supertokens-node/recipe/session";
import EmailPassword from "supertokens-node/recipe/emailpassword";

supertokens.init({
  framework: "express",
  supertokens: {
    connectionURI: "http://supertokens:3567",
    apiKey: "your-api-key-here",
  },
  appInfo: {
    appName: "My App",
    apiDomain: "https://api.example.com",
    websiteDomain: "https://example.com",
  },
  recipeList: [
    EmailPassword.init(),
    Session.init(),
  ],
});
```

### Pre-built UI vs custom UI

| Approach | SDK | When to use |
|---|---|---|
| Pre-built UI | `supertokens-auth-react` | Fast setup; React-only; hosted login page |
| Custom UI | Any backend SDK + any frontend | Full control over design; supports all frontend frameworks |

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

SuperTokens Core runs DB migrations automatically on startup. Review release notes for breaking SDK changes: <https://github.com/supertokens/supertokens-core/releases>

## Gotchas

- Core is just the HTTP service: it handles auth logic and DB. Your app integrates via backend + frontend SDKs. The core alone does nothing without SDK integration.
- API key required in production: without `API_KEYS`, the core accepts any request — always set it.
- PostgreSQL recommended: SQLite is not supported; use PostgreSQL or MySQL for production.
- Port 3567 is internal only: the SuperTokens Core port should not be publicly exposed. Your backend SDK communicates with it internally.
- Multi-tenancy (enterprise): multi-tenant/organization support and some SSO providers require the SuperTokens paid plan.
- Docker registry: images are on `registry.supertokens.io`, not Docker Hub.

## Links

- GitHub: <https://github.com/supertokens/supertokens-core>
- Docs: <https://supertokens.com/docs>
- Docker setup guide: <https://supertokens.com/docs/thirdpartyemailpassword/pre-built-ui/setup/core/with-docker>
- Backend SDK (Node.js): <https://github.com/supertokens/supertokens-node>
- Frontend SDK (React): <https://github.com/supertokens/supertokens-auth-react>
- Pricing (managed): <https://supertokens.com/pricing>
