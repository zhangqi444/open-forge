---
name: Logto
description: Identity + authentication platform (Auth0/Okta alternative). Multi-tenant OIDC + OAuth 2.0 provider, M2M tokens, user management, social sign-in, SAML/SSO, MFA, organizations/roles/scopes, passkeys, SMS/email/magic-link. Node.js + Postgres. MPL-2.0 (OSS) / commercial (Cloud + paid Enterprise features).
---

# Logto

Logto is the modern OSS Auth0 / Clerk / Supabase Auth / Okta competitor. Drops in as an OIDC + OAuth 2.0 provider that your apps and APIs talk to for login, registration, tokens, and identity management. Developer-focused with React/Vue/Angular/Next.js/iOS/Android SDKs + a polished Admin Console.

Core capabilities:

- **Universal login** — social (Google, Apple, GitHub, Microsoft, Facebook, ~20 others), email/SMS OTP, passwords, passkeys (WebAuthn)
- **MFA** — TOTP, backup codes, WebAuthn, SMS/email
- **OIDC + OAuth 2.0 + PKCE + Device Flow + M2M client credentials**
- **SAML SSO** (identity + service provider)
- **Multi-tenant organizations** — orgs, roles, permissions, invitations
- **User management** — directory, profiles, custom data, bulk import
- **Webhooks** — sign-in/sign-up/profile update events
- **Impersonation** — admin-acts-as-user for support
- **Audit log** — every auth event
- **White-label** — fully themeable login pages (OSS + deeper branding controls in commercial)

- Upstream repo: <https://github.com/logto-io/logto>
- Website: <https://logto.io>
- Docs: <https://docs.logto.io>
- OSS install: <https://docs.logto.io/logto-oss/get-started-with-oss>
- Cloud (hosted, free tier): <https://cloud.logto.io>

## Architecture in one minute

- **`logto`** — Node.js monolith serving two ports:
  - **`3001`** — OIDC endpoints + APIs used by your apps (the **core**)
  - **`3002`** — Admin Console web UI
- **Postgres 14+** — all state: tenants, users, applications, connectors, tokens, sessions, audit log
- **Optional**: Redis (caching at scale), S3 (custom asset storage)

Your apps redirect browsers to `3001/oidc/auth`, users log in, Logto redirects back with auth code → your app exchanges for tokens. Standard OIDC flow.

## Compatible install methods

| Infra       | Runtime                                                  | Notes                                                                  |
| ----------- | -------------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM   | Docker Compose with bundled Postgres                     | **For demo / dev only** per upstream comment                            |
| Single VM   | Docker with external Postgres                            | **Recommended for prod**                                                 |
| Single VM   | Native via `npm init @logto` (needs Postgres)            | For dev                                                                  |
| Kubernetes  | Official Helm chart                                        | <https://github.com/logto-io/helm-charts>                                |
| Cloud (free tier) | Logto Cloud                                          | <https://cloud.logto.io>                                                 |

## Inputs to collect

| Input                          | Example                                       | Phase     | Notes                                                                    |
| ------------------------------ | --------------------------------------------- | --------- | ------------------------------------------------------------------------ |
| `ENDPOINT`                     | `https://auth.example.com`                     | DNS       | **PERMANENT** — baked into OIDC `issuer` claim; clients lock to this URL   |
| `ADMIN_ENDPOINT`               | `https://admin.example.com`                    | DNS       | Admin Console; can be same host + different path in reverse proxy         |
| `DB_URL`                       | `postgres://user:pw@host:5432/logto`           | DB        | Postgres 14+                                                              |
| `TRUST_PROXY_HEADER`           | `1`                                            | Runtime   | When behind a reverse proxy                                               |
| Private key rotation grace     | seconds (default 5-30 min)                     | Runtime   | OIDC signing key rotation window                                          |
| First admin                    | set via web wizard                             | Bootstrap | First visit to `/admin` creates the superadmin                            |

## Install via Docker Compose (production-style)

Upstream's official `docker-compose.yml` is **labeled "demonstration only, do not use in prod"** — it bundles Postgres with a weak password for convenience. Use it to evaluate; for prod, use an external managed Postgres.

Demo one-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/logto-io/logto/HEAD/docker-compose.yml | \
  docker compose -p logto -f - up
```

Prod-style compose (external DB, pinned tag, TLS via reverse proxy):

```yaml
services:
  logto:
    image: svhd/logto:1.39.0       # pin; check https://github.com/logto-io/logto/releases
    container_name: logto
    restart: unless-stopped
    entrypoint: ["sh", "-c", "npm run cli db seed -- --swe && npm start"]
    ports:
      - "3001:3001"
      - "3002:3002"
    environment:
      TRUST_PROXY_HEADER: "1"
      DB_URL: postgres://logto:<strong>@db:5432/logto
      ENDPOINT: https://auth.example.com
      ADMIN_ENDPOINT: https://admin.example.com
    depends_on:
      db: { condition: service_healthy }

  db:
    image: postgres:17-alpine
    container_name: logto-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: logto
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: logto
    volumes:
      - logto-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U logto"]
      interval: 5s
      retries: 5

volumes:
  logto-db:
```

Reverse proxy: route `auth.example.com` → `3001` and `admin.example.com` → `3002`. Both need WebSocket upgrade for the Admin Console live-reload.

## First boot

1. Browse `https://admin.example.com`
2. Create the first superadmin (first-user-is-admin)
3. **Applications** → **Create application** → pick type (SPA / Native / Web / M2M) → get client_id + client_secret
4. **Connectors** → add social login providers (Google/GitHub/etc.) with their OAuth creds
5. **Sign-in experience** → customize login page (logo, colors, terms links, language)
6. Drop the SDK in your app (`@logto/react`, `@logto/next`, `@logto/vue`, iOS/Android) with the client_id + endpoint

## Data & config layout

Postgres contains everything:

- `users` + `user_identities` — identities across providers
- `applications` — your OAuth clients (SPAs, native apps, M2M)
- `connectors` — social login configs + credentials
- `tenants` (multi-tenant mode) — isolated tenants
- `organizations` + `organization_roles` — B2B orgs
- `logs` — audit events
- `oidc_keys` — signing keys (auto-rotated)

No local filesystem state (except optional `/opt/logto/packages/core/src/routes-custom/` for custom endpoints).

## Backup

```sh
docker compose exec -T db pg_dump -U logto logto | gzip > logto-db-$(date +%F).sql.gz
```

Backup DB + **any custom connector secrets stored externally**. Social provider client secrets live in DB; losing DB = reconfiguring every connector.

OIDC signing keys are in DB — losing them = all issued tokens become unverifiable immediately (users get logged out, need to re-auth).

## Upgrade

1. Releases: <https://github.com/logto-io/logto/releases>. Frequent (weekly-ish).
2. `docker compose pull && docker compose up -d`. The container's entrypoint runs `npm run cli db seed -- --swe` → applies migrations.
3. **`--swe`** = "skip on existing" — safe to re-run; won't overwrite existing data.
4. Back up DB before every minor version bump during 1.x era.
5. Read release notes for connector API changes.

## Gotchas

- **Upstream says "demo only" for their compose.yml.** Take seriously — it has `POSTGRES_PASSWORD=p0stgr3s` hardcoded. Use external DB for prod.
- **`ENDPOINT` is baked into the OIDC issuer URL.** Every issued token includes `"iss": "<ENDPOINT>"`. Clients validate this. Change it → every deployed client breaks, every issued token becomes invalid. Pick the URL permanently.
- **Two ports, two hostnames.** `3001` (user-facing auth) and `3002` (admin). Route via reverse proxy to separate subdomains, or run on same host with path-based routing (custom config).
- **`TRUST_PROXY_HEADER=1` required behind any reverse proxy.** Without it, source-IP detection for rate limiting + audit logs is wrong.
- **Multi-tenant mode** (OSS) lets one instance serve many tenants — each tenant has isolated users/apps/connectors. Useful for SaaS builders.
- **OIDC signing keys auto-rotate.** Clients should periodically fetch the JWKS URI (`<ENDPOINT>/oidc/jwks`) — most SDKs handle this automatically.
- **Connectors ship as JS modules** in the image. Adding custom connectors requires a custom image build, or via Logto's custom-connector plugin mechanism.
- **Admin Console is served on `:3002`** as a separate Next.js app. Heavy on first load; thereafter it's SPA + WebSocket for live updates.
- **SAML** (both IdP and SP) supported in OSS.
- **MFA enforcement** is per-app or per-org; configure in Sign-in experience.
- **Passkeys (WebAuthn)** supported out of the box; browsers handle the UX.
- **M2M tokens**: create an M2M application → use `client_credentials` grant to get tokens for server-to-server calls. First-class feature.
- **User impersonation** for admin support: admin clicks "Sign in as user" → gets a scoped token representing them.
- **Webhooks** fire on auth events; hMAC-signed for authenticity.
- **Audit log** retention is configurable; default ~90 days.
- **MPL-2.0 license** (Mozilla Public License 2.0) — weaker copyleft than AGPL, file-level: you can link Logto from proprietary code without copyleft on your code, but modifications to Logto files must be contributed back. Permissive for most commercial uses.
- **Commercial tier** (Logto Cloud) offers managed hosting + SSO (SAML from your IdP), SCIM, dedicated support, compliance certifications. OSS is feature-rich — most orgs don't need to pay.
- **SDKs**: React, Next.js (app + pages router), Vue, Angular, Svelte, iOS, Android, Flutter, React Native, Express, Koa, NestJS, Go, Python, PHP, Ruby, Rust, .NET. Coverage is very good.
- **Custom domains + custom email templates + full white-label branding** in OSS.
- **Subpath hosting** is NOT fully supported — prefer subdomains for `ENDPOINT` + `ADMIN_ENDPOINT`.
- **Alternatives worth knowing:**
  - **Authelia** — OSS auth proxy for self-hosted services; simpler, not an OIDC provider with M2M, org/role features
  - **Keycloak** — Red Hat's OIDC+SAML IdP, Java, heavy, very mature
  - **Zitadel** — OIDC IdP in Go, similar positioning, multi-tenant first-class (separate recipe)
  - **Authentik** — OSS IdP in Python, strong features, steeper learning curve
  - **Auth0 / Okta / Clerk / Supabase Auth / Firebase Auth** — commercial SaaS
  - **Ory Kratos + Hydra + Keto** — modular OSS building blocks (more DIY)
  - **Casdoor** — Go-based OSS (separate recipe); more minimal

## Links

- Repo: <https://github.com/logto-io/logto>
- Website: <https://logto.io>
- Docs: <https://docs.logto.io>
- OSS getting started: <https://docs.logto.io/logto-oss/get-started-with-oss>
- OIDC concepts: <https://docs.logto.io/concepts>
- Docker image: <https://hub.docker.com/r/svhd/logto>
- Helm chart: <https://github.com/logto-io/helm-charts>
- Cloud: <https://cloud.logto.io>
- Pricing: <https://logto.io/pricing>
- Releases: <https://github.com/logto-io/logto/releases>
- Discord: <https://discord.gg/logto>
- SDKs: <https://docs.logto.io/sdks>
