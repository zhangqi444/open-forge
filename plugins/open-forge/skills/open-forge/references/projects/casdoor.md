---
name: Casdoor
description: Self-hosted UI-first identity + access management. OIDC / OAuth 2.0 / SAML / CAS / LDAP / SCIM provider with 50+ built-in "identity provider" integrations (Google, Entra, Apple, WeChat, Alipay, Feishu, LinkedIn, GitHub, Discord, Slack, Okta, …). Go backend + Vue/React admin UI. Apache-2.0.
---

# Casdoor

Casdoor is an identity + access management (IAM) server focused on **plug-and-play social login**. Where Keycloak and Zitadel are IDPs you configure to accept external providers, Casdoor ships with 50+ IdP integrations pre-coded — Google, Entra, Apple, GitHub, Slack, Discord, WeChat, Alipay, Feishu (Lark), Baidu, LinkedIn, Twitter, Okta, OneLogin — you paste your client_id/secret and it works.

Extremely strong in the Chinese-market-integrations space (WeChat, Alipay, QQ, Baidu, Feishu). Multi-tenant ("organization" model). Covers federated SSO, MFA (TOTP/SMS/Email), WebAuthn, LDAP server mode, SCIM, CAS, SAML IdP + SP, password managers' OIDC, and has a built-in admin UI for user/permission/role management.

- Upstream repo: <https://github.com/casdoor/casdoor>
- Website: <https://casdoor.ai> (formerly casdoor.org — redirects)
- Docs: <https://casdoor.ai/docs/overview>
- Docker install: <https://casdoor.ai/docs/basic/server-installation#docker>
- Live demo: <https://door.casdoor.com> (read-only)

## Architecture in one minute

- **`casdoor`** — single Go binary, serves web UI + API on :8000
- **Storage backend** — relational DB: **MySQL 8** (default upstream), Postgres, SQLite, or others (CockroachDB, TiDB, Dameng, …)
- **Optional**: LDAP server mode (listens on :389), CAS server mode (CAS 1.0/2.0/3.0 protocols)

Ships with a management UI + a separate user-facing login page under the same server.

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                               |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------------------- |
| Single VM   | Docker Compose (upstream `docker-compose.yml` builds from source) | Dev-style; production uses published image             |
| Single VM   | Docker `casbin/casdoor:<VERSION>` (STANDARD edition)   | **Production path**                                                  |
| Single VM   | Binary + systemd                                         | Upstream ships .tar.gz releases                                      |
| Kubernetes  | Helm chart (community-maintained)                        | <https://github.com/casdoor/casdoor-helm>                            |
| Managed     | Casdoor Cloud (commercial SaaS)                          | <https://casdoor.com>                                                |

Casdoor has two build targets:

- **STANDARD** — static assets baked into the binary; single process
- **AIO** (All-In-One) — bundles MySQL inside the same container (convenient for demos; NOT for production)

## Inputs to collect

| Input                    | Example                                       | Phase     | Notes                                                               |
| ------------------------ | --------------------------------------------- | --------- | ------------------------------------------------------------------- |
| Domain                   | `auth.example.com`                            | DNS       | Used as OIDC issuer URL                                              |
| DB (MySQL/Postgres/SQLite) | MySQL 8 (compose default)                   | DB        | `createDatabase=true` on first boot auto-creates                     |
| Admin credentials        | `admin`/`123` defaults                        | Bootstrap | **CHANGE IMMEDIATELY**                                               |
| `app.conf`               | in `./conf/app.conf`                          | Runtime   | Main config — driver, DSN, etc.                                      |
| JWT cert                 | auto-generated on first start                 | Security  | Stored in the DB                                                     |
| IdP credentials          | per provider (Google client_id/secret, …)    | Post-install | Added via admin UI → Providers                                    |
| SMTP                     | for password reset / verification emails      | Email     | Per-org in admin UI                                                  |

## Install via Docker (production)

Upstream's production path — image: `casbin/casdoor:<version>` (not the `docker-compose.yml` in the repo, which builds from source and is more for contributors):

```yaml
services:
  casdoor:
    image: casbin/casdoor:v3.49.0     # pin to a release
    container_name: casdoor
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - RUNNING_IN_DOCKER=true
    volumes:
      - ./conf:/conf                    # mount config
    depends_on:
      db: { condition: service_healthy }

  db:
    image: mysql:8.0
    container_name: casdoor-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: <strong>
    volumes:
      - db_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  db_data:
```

Create `./conf/app.conf`:

```ini
appname = casdoor
httpport = 8000
runmode = prod
copyrequestbody = true
driverName = mysql
dataSourceName = root:<strong>@tcp(db:3306)/
dbName = casdoor
tableNamePrefix =
showSql = false
redisEndpoint =
defaultStorageProvider =
isCloudIntranet = false
authState = "casdoor"
socks5Proxy =
verificationCodeTimeout = 10
initScore = 0
logPostOnly = true
origin = https://auth.example.com
originFrontend =
staticBaseUrl = "https://cdn.casbin.org"
```

Upstream config reference: <https://casdoor.ai/docs/basic/server-installation>.

### First boot

1. `docker compose up -d` (auto-creates `casdoor` DB if `createDatabase=true` flag is passed at startup)
2. Browse `http://<host>:8000` → log in as `admin` / `123` → **change immediately**
3. Default organization `built-in` has the default `app-built-in` application — shows your OIDC discovery URL
4. OIDC discovery: `https://auth.example.com/.well-known/openid-configuration`

## Wire an app to Casdoor (OIDC)

For any OIDC-compatible relying party:

- **OIDC issuer**: `https://auth.example.com`
- **Authorization endpoint**: `https://auth.example.com/login/oauth/authorize`
- **Token endpoint**: `https://auth.example.com/api/login/oauth/access_token`
- **Userinfo**: `https://auth.example.com/api/userinfo`
- **JWKS**: `https://auth.example.com/.well-known/jwks`

Register the RP under **Applications** in Casdoor admin. Client ID + Secret + redirect URIs + allowed grant types.

## Data & config layout

- `./conf/app.conf` — main config (DB DSN, origin URL, debug/prod mode)
- Database — stores everything else: users, orgs, apps, providers, permissions, roles, groups, tokens, sessions, models, adapters, enforcers (Casbin), certs, webhooks, syncers, tokens, sessions
- `./conf/token_jwt_key.pem` + `token_jwt_key.pub` — JWT signing keys (auto-generated if missing)

## Backup

```sh
# DB (holds everything important)
docker compose exec -T db mysqldump -uroot -p"<pw>" casdoor | gzip > casdoor-db-$(date +%F).sql.gz

# Config + JWT keys
tar czf casdoor-conf-$(date +%F).tgz ./conf
```

**JWT keys must be backed up.** Losing them = all issued tokens become unverifiable; every RP needs to re-fetch JWKS (which works automatically if the server just re-generates them, BUT ongoing sessions are invalidated).

## Upgrade

1. Releases: <https://github.com/casdoor/casdoor/releases>. Rapid (multiple per week).
2. Docker: `docker compose pull && docker compose up -d`.
3. Schema migrations run on startup. Always back up DB first — Casdoor is pre-1.0-vibe; migrations occasionally need manual intervention on edge cases.
4. Read release notes; breaking API changes happen at minor version jumps.

## Gotchas

- **Default admin credentials are `admin` / `123`.** Change on first login. Scanner bots look for default Casdoor admin.
- **Pre-1.0 in spirit.** Versions advance fast (`v1.7xx`); occasional breaking changes in config keys, API surface, or DB schema. Pin + test upgrades.
- **Two editions: STANDARD vs AIO.** AIO bundles MySQL inside the container — convenient for laptop demos; AIO MySQL data lives **inside** the container and vanishes if you recreate it. Production = STANDARD + external DB.
- **`origin` setting** must match the public URL including protocol. Mismatch = broken OIDC callbacks + CORS errors.
- **Default JWT key pair** auto-generates in the DB on first boot. Don't panic if `token_jwt_key.pem` isn't on disk — it's in the DB, editable from admin UI → Certs.
- **LDAP server mode** listens on :389 when enabled. Not for authenticating TO external LDAP (that's "LDAP provider" under Providers); it's Casdoor acting AS an LDAP server.
- **CAS server support** (legacy university SSO protocol) is built-in — useful if you need to integrate with legacy CAS clients.
- **Chinese-market integrations** are first-class (WeChat, Alipay, Feishu, DingTalk, Baidu, QQ, etc.) — usually better than Keycloak's equivalents.
- **Casbin engine under the hood** provides the authorization layer. You can define ACL / RBAC / ABAC policies at the role level.
- **Multi-tenant "Organization"** is the top-level container. Each org has its own users, applications, providers, certs, LDAPs. App config is per-org. Bootstrap `built-in` org is the super-admin realm.
- **Default database name `casdoor`.** Customize via `dbName` in app.conf.
- **`showSql = true`** prints every SQL query to stdout — **only** for debugging.
- **Redis** is optional; used for session caching + rate limiting when configured. Without, sessions go to DB.
- **Email verification + SMS verification** — configured per-organization in admin UI. OTP channels: Email (SMTP), SMS (Aliyun, Tencent Cloud, AWS SNS, Twilio, …), TOTP, WebAuthn.
- **Password hashing**: bcrypt by default. PBKDF2 + Argon2 supported.
- **User Management UI** is visible to end-users (customizable per-app). Careful what you expose.
- **Webhooks** fire on login/register/etc. Useful for downstream provisioning.
- **Syncer** can push/pull users to/from external databases (MySQL, Postgres, MongoDB, Kafka) — for migrating from legacy user stores.
- **Theme + i18n** are admin-settable per-application.
- **Apache-2.0 license** — no copyleft surprises.
- **Alternatives worth knowing:**
  - **Zitadel** — modern, event-sourced, Apache-2.0, slicker UI
  - **Keycloak** — Java, heaviest, most features, most integrations via extensions
  - **Authentik** — Python, strong UX, "blueprints" for config-as-code
  - **Authelia** — lightweight forward-auth, not a full IDP
  - **Ory stack** (Kratos + Hydra + Keto + Oathkeeper) — unbundled, composable
  - **LogTo** — newer, developer-focused OSS IDP

## Links

- Repo: <https://github.com/casdoor/casdoor>
- Website: <https://casdoor.ai> (formerly casdoor.org — redirects)
- Docs: <https://casdoor.ai/docs/overview>
- Server installation: <https://casdoor.ai/docs/basic/server-installation>
- Docker: <https://casdoor.ai/docs/basic/server-installation#docker>
- Providers list: <https://casdoor.ai/docs/provider/oauth/overview>
- Docker Hub: <https://hub.docker.com/r/casbin/casdoor>
- Helm chart: <https://github.com/casdoor/casdoor-helm>
- Demo: <https://door.casdoor.com>
- Releases: <https://github.com/casdoor/casdoor/releases>
- Community (Discord): <https://discord.gg/5rPsrAzK7S>
- Casdoor Cloud (SaaS): <https://casdoor.com>
