---
name: Authgear
description: "Open-source alternative to Auth0 / Clerk / Firebase Auth. Go. authgear/authgear-server. OIDC/OAuth 2.0/SAML + passkeys + MFA + SSO + RBAC + Admin API. Self-hosted consumer auth."
---

# Authgear

**Open-source alternative to Auth0 / Clerk / Firebase Auth.** A turnkey consumer-auth platform: passwordless login (email/SMS/WhatsApp OTP + magic-link), passkeys, biometric login (iOS/Android SDKs), TOTP/SMS/Email MFA, OIDC/OAuth 2.0/SAML SSO, ADFS/LDAP enterprise connections, a web portal for admins, and a GraphQL Admin API. Pre-built signup/login + account-settings pages.

Built + maintained by **Skymakers / Authgear team** (~42 contributors). Also available as SaaS at authgear.com.

- Upstream repo: <https://github.com/authgear/authgear-server>
- Docs: <https://docs.authgear.com>
- SaaS cloud: <https://www.authgear.com>
- Demo: <https://demo.authgear.com>
- Discord: <https://discord.gg/Kdn5vcYwAS>
- Helm chart (recommended production deploy): <https://docs.authgear.com/deployment/production-deployment/helm>

## Architecture in one minute

- **Go** backend (core auth service + AuthUI + Portal + Admin API)
- **PostgreSQL** + **Redis** — required dependencies
- **Four components** shipped from the single repo: `authgear-server` (core), `AuthUI` (user-facing login/settings), `Portal` (admin web UI), `Admin API` (GraphQL for dev integration)
- Pre-built SDKs for JS/React/Vue/Angular/Next.js, React Native, Capacitor, iOS, Android, Flutter, Xamarin
- Resource: **medium-to-heavy** (several services + Postgres + Redis)

## Compatible install methods

| Infra                  | Runtime                       | Notes                                                                             |
| ---------------------- | ----------------------------- | --------------------------------------------------------------------------------- |
| **Kubernetes + Helm**  | Authgear Helm chart           | **Upstream-recommended for production.** See `docs.authgear.com/deployment/…/helm` |
| **Docker Compose**     | Local development / small POC | Upstream ships `docker-compose.yaml` (Postgres 16 build context + services)       |
| **Authgear Cloud**     | SaaS                          | <https://www.authgear.com> — not self-hosted; free tier available                 |

## Inputs to collect

| Input                      | Example                       | Phase   | Notes                                                                                                   |
| -------------------------- | ----------------------------- | ------- | ------------------------------------------------------------------------------------------------------- |
| Domain(s)                  | `auth.example.com`            | URL     | Usually also a portal host, e.g. `portal.example.com` — upstream splits them                            |
| Postgres connection        | host + DB + user + pw         | Storage | Can be external managed (RDS / Cloud SQL) or the bundled container                                      |
| Redis connection           | host + pw                     | Storage | Required for sessions / rate limits                                                                     |
| SMTP / SMS / WhatsApp      | Provider API keys             | Notify  | Needed for OTP / magic-link / verification flows                                                        |
| OAuth providers (optional) | Google / Apple / Facebook IDs | Auth    | Configure in Portal → Connections                                                                       |
| SAML IdP (optional)        | Metadata / cert               | Auth    | For B2B enterprise SSO                                                                                   |
| Branding                   | Logo + theme                  | UI      | Authgear Portal → Branding (AuthUI customization)                                                       |

## Install via Helm (production-recommended)

Follow upstream: <https://docs.authgear.com/deployment/production-deployment/helm>.

High-level:

1. Provision Kubernetes cluster (EKS / GKE / AKS / on-prem).
2. Install Postgres 16+ and Redis (managed services or the chart's subcharts).
3. Configure ingress + TLS (cert-manager + Let's Encrypt, or managed ingress).
4. `helm install authgear authgear/authgear --values values.yaml` with your domain + DB + Redis configured.
5. Visit Portal → create first admin → configure first app.

## Install via Docker Compose (local / POC only)

Per `<repo>/docker-compose.yaml` (upstream): builds Postgres 16 from `./postgres/postgres16` context and wires up Authgear services. This is the **local development** stack — not production.

For production → Helm.

Quick start (dev):

```sh
git clone https://github.com/authgear/authgear-server.git
cd authgear-server
docker compose up -d
# Follow docs.authgear.com/deployment/local-development/local for post-up config
```

## First boot

1. Deploy (Helm or Compose).
2. Visit **Portal** URL → create root admin account.
3. Create your first **project** in the Portal.
4. Configure **login methods** (password / OTP / passkey / biometric).
5. Configure **SMTP/SMS providers** for verification flows.
6. Note the **issuer URL** + **client_id** for your app's OIDC config.
7. Integrate via SDK → test signup/login flow end-to-end.
8. Enable **MFA** (TOTP + SMS fallback) for admin accounts before going live.
9. Back up Postgres + Redis persistent data.

## Data & config layout

- **Postgres** — all auth config, users, sessions, audit logs, RBAC roles, SAML/OAuth creds
- **Redis** — session cache, rate-limit counters, OTP-in-flight state
- **Authgear config** — YAML/Helm values or env vars (issuer URL, server keys, provider creds)

## Backup

```sh
# Postgres: use your infra's backup (RDS snapshot, pg_dump, etc.)
# Redis: mostly ephemeral cache, but session state is here — RDB snapshot if needed
# Authgear config (Helm values.yaml) — commit to a private repo
```

Contents: **every user password hash, OAuth token, session, audit log, MFA secret** — this is literally your identity provider. Back up encrypted; restrict access to security + SRE team only.

## Upgrade

1. Releases: <https://github.com/authgear/authgear-server/releases>
2. Helm: `helm repo update && helm upgrade authgear authgear/authgear -f values.yaml`
3. Run DB migrations per release notes (usually automatic via the chart's migration job).

## Gotchas

- **Identity provider = crown-jewel.** Compromise of Authgear = compromise of every app it protects. Treat the Postgres DB + Authgear admin creds + signing keys as Tier-1 secrets.
- **Helm is the production path, not Compose.** Upstream's `docker-compose.yaml` is developer-facing — missing proper HA, ingress, TLS defaults, backup story. For real deployments use the Helm chart.
- **Portal + auth on separate domains.** Upstream convention: `portal.example.com` (admin) + `accounts.example.com` (end-user auth). Single-domain setups are possible but make RBAC + CORS noisier.
- **Postgres 16 required.** The Compose file builds Postgres 16 from source context (`./postgres/postgres16`) — older versions may work for minor versions but upstream targets 16.
- **Redis is not optional.** Sessions + rate limits + OTP state all live in Redis. If Redis dies, all users get logged out and OTP flows break.
- **SMTP + SMS providers for OTP flows.** Without outbound email/SMS, magic-link + OTP login methods are dead. Configure providers (SendGrid / Twilio / etc.) in Portal before enabling OTP for end-users.
- **SAML + LDAP are B2B-only features.** Configurable per-project in Portal → Connections. Enterprise customers expect these — if you're building a B2B SaaS, enable them early.
- **SDK versions drift from server.** The iOS/Android/JS SDKs have independent release cadences. Pin SDK versions matching your server version (changelogs usually note compat breaks).
- **Audit logs fill Postgres.** Every login, MFA event, OAuth exchange is logged. Plan log retention / archival or the audit table will grow unbounded.
- **AuthUI is customizable but uses a templating layer.** Branding/theming via Portal → Branding is safe; deeper HTML overrides need the "AuthUI static files" mechanism — documented in upstream's customization guide.
- **OAuth-alternative-family: many players.** Keycloak, Authentik, Zitadel, Ory Hydra, Logto, Dex — see alternatives below.
- **SaaS option exists.** `authgear.com` has a free tier — good for POCs before self-hosting commitment.

## Project health

Active development (CI badges), 42 contributors, Helm chart, SDKs across 7+ platforms, Discord community, named customers (Bupa, MTR, Hongkong Land, K11), SaaS cloud available.

## OAuth/identity-provider-family comparison

- **Authgear** — turnkey consumer auth, strong passwordless + passkey story, 7+ SDK platforms, B2B enterprise connections (ADFS/LDAP/SAML)
- **Keycloak** — Red Hat, most mature OSS IdP, heavy (Java + Wildfly), best-of-breed enterprise/SAML
- **Authentik** — Python/Django, modern UI, strong for SSO + proxy-auth
- **Zitadel** — Go, multi-tenant-first, gRPC API
- **Ory Hydra + Kratos** — unbundled OAuth server + identity management, most "lego-brick" approach
- **Logto** — Node-based modern alt, developer-UX focused
- **Dex** — minimal OIDC provider, federates to other IdPs, K8s-native

**Choose Authgear if:** you want consumer-auth-out-of-the-box with passkey + passwordless + multi-SDK, prefer turnkey over lego-brick, and value B2B enterprise connections alongside consumer flows.

## Links

- Repo: <https://github.com/authgear/authgear-server>
- Docs: <https://docs.authgear.com>
- SDK examples: <https://github.com/orgs/authgear/repositories?q=example>
- Keycloak (alt): <https://www.keycloak.org>
- Authentik (alt): <https://goauthentik.io>
- Zitadel (alt): <https://zitadel.com>
