---
name: ory-hydra
description: Recipe for Ory Hydra — OpenID Certified OAuth 2.0 and OpenID Connect server optimized for low latency and high throughput.
---

# Ory Hydra

Hardened, OpenID Certified OAuth 2.0 Authorization Server and OpenID Connect Provider. Does not manage users itself — it delegates login/consent to your existing identity system (or Ory Kratos). Issues access, refresh, and ID tokens; manages OAuth2 clients; handles PKCE, device authorization, and introspection. Optimized for high throughput and low resource usage. Part of the Ory ecosystem. Upstream: <https://github.com/ory/hydra>. Docs: <https://www.ory.com/docs/hydra/>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://www.ory.com/docs/hydra/5min-tutorial> | Yes | Recommended quickstart |
| Helm chart | <https://k8s.ory.sh/helm/charts> | Yes | Kubernetes production |
| Binary | <https://github.com/ory/hydra/releases> | Yes | Bare-metal installs |
| Ory Network (cloud) | <https://console.ory.sh> | Yes (managed) | Hosted SaaS |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Database DSN? | postgres:// or mysql:// | Required; PostgreSQL recommended for production |
| infra | Public URL for Hydra? | HTTPS URL | Required for issuer, token URLs |
| software | Login and consent app URL? | HTTPS URL | Required; your app's login/consent UI endpoints |
| software | System secret? | 32+ char string | Required; generate with `openssl rand -hex 16` |
| software | Cookie same-site policy? | Lax / None | None required for cross-origin iframes |

## Software-layer concerns

### Docker Compose (5-minute tutorial)

```yaml
services:
  hydra-migrate:
    image: oryd/hydra:v26.2.0
    environment:
      DSN: postgres://hydra:secret@postgresd:5432/hydra?sslmode=disable
    command: migrate sql -e --yes
    restart: on-failure
    depends_on:
      - postgresd

  hydra:
    image: oryd/hydra:v26.2.0
    ports:
      - "4444:4444"   # public API
      - "4445:4445"   # admin API (internal only)
    command: serve all --dev
    environment:
      DSN: postgres://hydra:secret@postgresd:5432/hydra?sslmode=disable
      URLS_SELF_ISSUER: https://hydra.example.com/
      URLS_CONSENT: http://your-login-app/consent
      URLS_LOGIN: http://your-login-app/login
      URLS_LOGOUT: http://your-login-app/logout
      SECRETS_SYSTEM: youReallyNeedToChangeThis
      OIDC_SUBJECT_IDENTIFIERS_SUPPORTED_TYPES: public,pairwise
      OIDC_SUBJECT_IDENTIFIERS_PAIRWISE_SALT: youReallyNeedToChangeThis
    restart: unless-stopped
    depends_on:
      - hydra-migrate

  postgresd:
    image: postgres:16
    environment:
      POSTGRES_USER: hydra
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: hydra
    volumes:
      - hydra-postgres:/var/lib/postgresql/data

volumes:
  hydra-postgres:
```

### Ports

| Port | Purpose |
|---|---|
| 4444 | Public API — OAuth2/OIDC endpoints, token issuance |
| 4445 | Admin API — client management, token introspection/revocation. Never expose publicly. |

### Login and consent flow

Hydra does not authenticate users. When authorization is requested, it redirects to your `URLS_LOGIN` endpoint. Your login app:
1. Authenticates the user (via session, Kratos, LDAP, etc.)
2. Calls Hydra admin API to accept/reject the login request
3. Redirects back to Hydra

Then Hydra redirects to `URLS_CONSENT`. Your consent app:
1. Shows the user which scopes are requested
2. Calls Hydra admin API to accept/reject
3. Hydra issues tokens and redirects to the client's `redirect_uri`

### Managing OAuth2 clients (CLI)

```bash
# Create a client
hydra create client \
  --endpoint http://localhost:4445 \
  --name "my-app" \
  --secret my-client-secret \
  --grant-type authorization_code,refresh_token \
  --response-type code \
  --scope openid,offline \
  --redirect-uri http://my-app/callback

# List clients
hydra list clients --endpoint http://localhost:4445
```

## Upgrade procedure

```bash
# Run migrations first
docker run --rm oryd/hydra:v26.2.0 migrate sql -e --yes

# Then update service
docker compose pull && docker compose up -d
```

Always migrate before upgrading. Check: <https://www.ory.com/docs/hydra/guides/upgrade>

## Gotchas

- Admin API (port 4445) must never be publicly reachable: it can revoke tokens, delete clients, and read all sessions.
- `--dev` flag disables HTTPS enforcement — do not use in production.
- Hydra does not store passwords: it only issues tokens based on your login app's authentication decision.
- PKCE is recommended for all public clients (SPAs, mobile apps); enforce it with `--pkce=required`.
- Cookie SameSite: if your app lives on a different domain, set `COOKIES_SAME_SITE_MODE=None` and ensure HTTPS.
- Pairs with Ory Kratos: Kratos manages user identities/sessions; Hydra manages OAuth2/OIDC token issuance for third-party apps.

## Links

- GitHub: <https://github.com/ory/hydra>
- Docs: <https://www.ory.com/docs/hydra/>
- 5-minute tutorial: <https://www.ory.com/docs/hydra/5min-tutorial>
- Docker Hub: <https://hub.docker.com/r/oryd/hydra>
- Ory ecosystem: <https://www.ory.com/docs/ecosystem/projects>
