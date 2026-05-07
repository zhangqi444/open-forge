---
name: listaway
description: Listaway recipe for open-forge. Self-hosted list management app for creating and publicly sharing lists (wishlists, to-do, collections) with randomized read-only URLs. Docker + PostgreSQL. Source: https://github.com/jeffrpowell/listaway
---

# Listaway

A self-hosted list management app for creating and publicly sharing lists of items — wishlists, reading lists, build component lists, task lists, etc. Supports auth/admin, group-based sharing, item priorities and notes, and opt-in public read-only access via randomized URLs (an alternative to Amazon Lists). MIT licensed, Docker + PostgreSQL. Upstream: <https://github.com/jeffrpowell/listaway>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | PostgreSQL | Only supported setup |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Listaway?" | FQDN | e.g. lists.example.com — used in password reset links |
| "PostgreSQL host, user, password?" | connection details | Existing PostgreSQL instance or bundled |
| "Auth key?" | 128-char random alphanumeric string | Used to sign sessions — generate with: openssl rand -hex 64 |
| "Port to expose?" | Number | Default 8080 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "SMTP config for password reset emails?" | host:port + user/pass/from | Optional; if omitted, reset email bodies are logged to stdout |
| "OIDC/OAuth2 SSO?" | provider URL + client ID + secret | Optional; enables login via Google, Keycloak, etc. |

## Software-Layer Concerns

- **PostgreSQL required**: Must create the database schema manually before first run (SQL in the README's Quick Start section).
- **LISTAWAY_AUTH_KEY**: Must be a stable, random 128-character alphanumeric string. Changing it invalidates all existing sessions.
- **APP_URL**: Must be set for password reset links to contain the correct domain — set to the public URL.
- **Public lists use randomized URLs**: Shared list URLs contain a random token — share the full URL; guessing is impractical.
- **Groups**: Create a group, add users, then share list edit or read access with group members.
- **Collections**: Group multiple lists (including shared ones) into a collection with its own optional public URL.
- **OIDC optional**: Add SSO via any OIDC-compatible provider (Google, Keycloak, Authentik, etc.) alongside or instead of username/password.

## Deployment

### PostgreSQL schema setup (one-time)

```sql
-- Connect with an admin role
CREATE ROLE listaway LOGIN PASSWORD 'your-password';
CREATE DATABASE listaway;
GRANT CONNECT ON DATABASE listaway TO listaway;
-- Connect to the listaway database
CREATE SCHEMA listaway;
GRANT CREATE, USAGE ON SCHEMA listaway to listaway;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA listaway TO listaway;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA listaway TO listaway;
```

### Docker Compose

```yaml
services:
  listaway:
    image: ghcr.io/jeffrpowell/listaway:v1.17.2
    ports:
      - "8080:8080"
    env_file:
      - .env
    restart: unless-stopped
```

**.env file:**

```
LISTAWAY_AUTH_KEY=<128-char random alphanumeric>
PORT=8080
POSTGRES_USER=listaway
POSTGRES_PASSWORD=your-password
POSTGRES_HOST=your-postgres-host
POSTGRES_DATABASE=listaway

# Optional SMTP
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=username
SMTP_PASSWORD=password
SMTP_FROM=noreply@example.com
APP_URL=https://lists.example.com

# Optional OIDC
# OIDC_ENABLED=true
# OIDC_PROVIDER_URL=https://accounts.google.com
# OIDC_CLIENT_ID=your-client-id
# OIDC_CLIENT_SECRET=your-client-secret
# OIDC_REDIRECT_URL=https://lists.example.com/auth/oidc/callback
```

## Upgrade Procedure

1. Update image tag in compose file (or use `:latest`): `docker compose pull && docker compose up -d`
2. Schema migrations run automatically on startup.
3. Backup PostgreSQL before upgrading.

## Gotchas

- **Manual DB schema creation**: Unlike many apps, Listaway requires manual SQL setup before first run — don't skip the schema creation step.
- **LISTAWAY_AUTH_KEY rotation**: Changing this key invalidates all active sessions — all users will be logged out.
- **No Docker Hub image**: Image is on GitHub Container Registry (`ghcr.io/jeffrpowell/listaway`).
- **SMTP optional but recommended**: Without SMTP, password reset emails are logged to stdout — functional for single-user setups, not for shared instances.
- **Pin to a specific tag**: Upstream uses explicit version tags (e.g. `v1.17.2`) — pin to a version for predictable upgrades.

## Links

- Source: https://github.com/jeffrpowell/listaway
- Releases: https://github.com/jeffrpowell/listaway/releases
- Docker image: ghcr.io/jeffrpowell/listaway
