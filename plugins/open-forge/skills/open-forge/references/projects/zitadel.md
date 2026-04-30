---
name: ZITADEL
description: Self-hosted identity infrastructure (IDP + auth provider). OIDC, SAML 2.0, OAuth 2.0, LDAP (beta), passkeys, social login, MFA, SCIM, actions/webhooks. Multi-tenant by design. Go + Postgres 17. Apache-2.0.
---

# ZITADEL

ZITADEL is a cloud-native, multi-tenant identity provider (IDP). It's the full stack:

- **Authentication**: OIDC 1.0, SAML 2.0, OAuth 2.0, passwordless (passkeys / WebAuthn), TOTP, SMS OTP, social login (Google/GitHub/Apple/etc.)
- **Authorization**: roles, projects, granted roles, fine-grained permissions per organization
- **Multi-tenant**: organizations within a single instance, each with its own users/projects/settings
- **Actions** (v1) / **Flows/Actions v2**: JavaScript hooks on login/provisioning events
- **SCIM 2.0** for user provisioning
- **LDAP server** (experimental)

Think Keycloak with a modern Go codebase, first-class multi-tenant design, and slicker UX. Maintained by a commercial company (Zitadel AG) with a SaaS option, but core is Apache-2.0 self-hostable.

- Upstream repo: <https://github.com/zitadel/zitadel>
- Website: <https://zitadel.com>
- Docs: <https://zitadel.com/docs>
- Self-hosting docs: <https://zitadel.com/docs/self-hosting/deploy/overview>
- Docker install: <https://zitadel.com/docs/self-hosting/deploy/compose>
- Cloud: <https://zitadel.com> (SaaS tier)

## Architecture in one minute

- **`zitadel`** — single Go binary, no sidecar services. Serves HTTP (API + console UI) on 8080. Uses gRPC internally.
- **Postgres 17+** (upstream also supports CockroachDB) — event-sourced storage
- **Optional: reverse proxy** for TLS termination (Caddy, Traefik, nginx)

Event sourcing model: every change (user signup, role grant, passkey add) is an append-only event. Projections are built for queries. Makes audit trivially complete; makes DB size grow steadily.

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                                      |
| ----------- | ------------------------------------------------------ | -------------------------------------------------------------------------- |
| Single VM   | Docker Compose (upstream example)                      | **Recommended for self-hosts**                                              |
| Single VM   | Docker + external Postgres                             | For production — don't run Postgres in compose for serious use              |
| Kubernetes  | Official Helm chart (`zitadel/zitadel`)                 | Upstream-maintained; production-ready                                       |
| Bare metal  | Single binary + systemd                                 | Docs: <https://zitadel.com/docs/self-hosting/deploy/linux>                  |
| Managed     | zitadel.com cloud                                       | SaaS at <https://zitadel.com/pricing>                                       |

## Inputs to collect

| Input                      | Example                                       | Phase     | Notes                                                              |
| -------------------------- | --------------------------------------------- | --------- | ------------------------------------------------------------------ |
| Public domain + TLS        | `https://auth.example.com`                    | DNS + TLS | **REQUIRED for production** — OIDC requires HTTPS                   |
| `ZITADEL_MASTERKEY`        | exactly 32 chars                              | Security  | **Critical** — encrypts all stored secrets; rotation is involved    |
| `ZITADEL_EXTERNALDOMAIN`   | `auth.example.com`                            | Runtime   | Must match real domain; used in token issuer URL                    |
| `ZITADEL_EXTERNALSECURE`   | `true`                                         | Runtime   | Whether public URL is HTTPS                                         |
| `ZITADEL_EXTERNALPORT`     | `443`                                          | Runtime   | Public port                                                         |
| `ZITADEL_DATABASE_POSTGRES_*` | host/port/user/password/db                 | DB        | Separate app user + admin user (for migrations)                     |
| Default admin              | `zitadel-admin@zitadel.<domain>` after init    | Bootstrap | Initial password printed in logs on first start; change immediately |
| SMTP                       | host/user/password/sender                     | Email     | For password reset, invitations, verification                        |
| IdP config (optional)      | per IdP                                        | Auth      | Google/Entra/GitHub/SAML — configured post-install                  |

## Install via Docker Compose

From upstream's [`apps/docs/content/self-hosting/manage/configure/docker-compose.yaml`](https://raw.githubusercontent.com/zitadel/zitadel/main/apps/docs/content/self-hosting/manage/configure/docker-compose.yaml):

```yaml
services:
  zitadel:
    image: ghcr.io/zitadel/zitadel:v2.72.0   # pin! never :latest in prod
    restart: always
    command: >
      start-from-init
      --config /example-zitadel-config.yaml
      --config /example-zitadel-secrets.yaml
      --steps /example-zitadel-init-steps.yaml
      --masterkey "${ZITADEL_MASTERKEY}"
      --tlsMode disabled      # TLS terminated upstream by reverse proxy
    ports: ["8080:8080"]
    volumes:
      - ./example-zitadel-config.yaml:/example-zitadel-config.yaml:ro
      - ./example-zitadel-secrets.yaml:/example-zitadel-secrets.yaml:ro
      - ./example-zitadel-init-steps.yaml:/example-zitadel-init-steps.yaml:ro
    depends_on:
      db: { condition: service_healthy }
    networks: [zitadel]
    environment:
      - ZITADEL_EXTERNALDOMAIN=auth.example.com
      - ZITADEL_EXTERNALSECURE=true
      - ZITADEL_EXTERNALPORT=443

  db:
    image: postgres:17-alpine
    restart: always
    environment:
      - POSTGRES_USER=root
      - POSTGRES_PASSWORD=<strong>
      - POSTGRES_DB=zitadel
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d zitadel -U root"]
      interval: 10s
      timeout: 30s
      retries: 5
      start_period: 20s
    volumes:
      - data:/var/lib/postgresql/data:rw
    networks: [zitadel]

networks:
  zitadel:
volumes:
  data:
```

Minimal `example-zitadel-config.yaml`:

```yaml
ExternalDomain: auth.example.com
ExternalSecure: true
ExternalPort: 443
TLS:
  Enabled: false   # reverse proxy does TLS

Database:
  Postgres:
    Host: db
    Port: 5432
    Database: zitadel
    User:
      Username: zitadel_user
      Password: <strong>
      SSL: { Mode: disable }
    Admin:
      Username: root
      Password: <strong>
      SSL: { Mode: disable }
```

Watch first-boot logs for the auto-generated admin password:

```
docker compose logs zitadel | grep -A1 "initial user"
```

OR: set `FirstInstance.Org.Human.Password` in `example-zitadel-init-steps.yaml` to define it explicitly.

## Reverse proxy (Caddy example — simplest)

```caddyfile
auth.example.com {
  reverse_proxy zitadel:8080 {
    transport http {
      versions h2c 1.1
    }
  }
}
```

gRPC requires h2c over HTTP/1.1 fallback — Caddy's `versions h2c 1.1` handles this. Nginx / Traefik examples in upstream docs: <https://zitadel.com/docs/self-hosting/manage/reverseproxy/reverse_proxy>.

## Data & config layout

- **Database**: Postgres 17+ stores everything (events, projections, config). Size grows with event history.
- **Config files** (mounted read-only):
  - `example-zitadel-config.yaml` — public config
  - `example-zitadel-secrets.yaml` — sensitive values (SMTP password, JWT signing, etc.)
  - `example-zitadel-init-steps.yaml` — first-boot provisioning (default org, admin)
- **`ZITADEL_MASTERKEY`** — 32-byte string; encrypts secrets at rest in the DB

## Backup

```sh
# Main thing is Postgres
docker compose exec -T db pg_dump -U root zitadel | gzip > zitadel-db-$(date +%F).sql.gz

# Config + masterkey (keep secure)
tar czf zitadel-config-$(date +%F).tgz \
  example-zitadel-config.yaml \
  example-zitadel-secrets.yaml \
  example-zitadel-init-steps.yaml
echo "ZITADEL_MASTERKEY=..." > zitadel-masterkey-$(date +%F).txt
```

**Backup without the masterkey is useless.** Store the masterkey separately in a vault.

## Upgrade

1. Releases: <https://github.com/zitadel/zitadel/releases>. Semver-ish; read each release.
2. `docker compose pull && docker compose up -d`.
3. Schema migrations run automatically on startup via the "admin" DB user (needs DDL rights).
4. **Never skip multiple minor versions.** ZITADEL supports upgrades within the last two minor versions; `v2.55` → `v2.72` may need intermediate stops.
5. Read upgrade guide per version: <https://zitadel.com/docs/self-hosting/manage/updating_scaling>.
6. Downgrade is **not supported** after migrations run.

## Gotchas

- **`ZITADEL_MASTERKEY` must be exactly 32 characters.** Shorter/longer = startup fail. Generate with `openssl rand -base64 24 | tr -d '=' | cut -c1-32`.
- **Losing the masterkey = unrecoverable.** All stored secrets (IdP client secrets, SMTP password, signing keys) are encrypted with it. No way back without the key.
- **External domain is baked into issuer URLs.** OIDC tokens say `iss: https://auth.example.com`. Changing the domain = invalidating all existing tokens + reconfiguring every RP (relying party).
- **Database is event-sourced.** It grows. Not unboundedly (projections are compacted) but noticeably. Plan for steady DB growth in capacity planning.
- **`start-from-init` vs `start`**. `start-from-init` runs init on first boot then serves; `start` only serves (expects init already done). Upstream compose uses `start-from-init` for convenience; production Helm uses `init` + `setup` + `start` as separate jobs.
- **Admin user from init steps has a printed one-time password** in the logs. Change on first login; set up MFA immediately.
- **Multi-tenancy is aggressive.** "Organization" is a first-class concept. Even single-tenant installs have at least one org. Learn the org/project/app hierarchy: Org → Project → App → Grants.
- **LDAP server support is experimental.** Don't rely on it for primary LDAP-dependent apps yet.
- **Actions v1 (legacy) vs v2.** v1 is JS hooks on flow points; v2 is a more general event system. v2 preferred for new installs.
- **SCIM 2.0** for provisioning works with Okta, Azure, OneLogin. Per-app config.
- **gRPC over HTTP/2 is required.** Reverse proxy must support h2c (Caddy ✓, nginx needs `proxy_http_version 1.1` + grpc_pass).
- **Rate limits at API level.** Aggressive login attempts → temporary blocks. Tune in settings.
- **Passkeys (WebAuthn)** work out of the box; require HTTPS (even locally use mkcert).
- **SMTP template customization** per-org in the console UI.
- **Observability:** Prometheus metrics at `/debug/metrics`; OpenTelemetry tracing supported.
- **No built-in LDAP client.** If you want ZITADEL to authenticate against an external AD/LDAP, configure via an IdP (LDAP IdP is beta).
- **Cockroach vs Postgres:** upstream supports both. Postgres is the easier path for most; Cockroach for horizontal scale.
- **First login redirects to `/ui/console/`** — the admin console. User-facing login lives at `/ui/login/login`.
- **Alternatives worth knowing:**
  - **Keycloak** — Java, larger feature set, heavier, older codebase
  - **Authentik** — Python, great UI, blueprints for config
  - **Authelia** — lightweight forward-auth; not a full IDP
  - **Ory stack** (Kratos + Hydra + Keto) — unbundled, more ops burden but very flexible
  - **Casdoor** — similar positioning (covered separately)
- **License**: Core is Apache-2.0. Some enterprise features (like customer portal tiers) gated in SaaS only, not in OSS.

## Links

- Repo: <https://github.com/zitadel/zitadel>
- Docs: <https://zitadel.com/docs>
- Self-hosting: <https://zitadel.com/docs/self-hosting/deploy/overview>
- Docker Compose: <https://zitadel.com/docs/self-hosting/deploy/compose>
- Kubernetes (Helm): <https://zitadel.com/docs/self-hosting/deploy/kubernetes>
- Reverse proxy guide: <https://zitadel.com/docs/self-hosting/manage/reverseproxy/reverse_proxy>
- Configure: <https://zitadel.com/docs/self-hosting/manage/configure>
- Updating: <https://zitadel.com/docs/self-hosting/manage/updating_scaling>
- Releases: <https://github.com/zitadel/zitadel/releases>
- Docker image: <https://github.com/zitadel/zitadel/pkgs/container/zitadel>
- Cloud: <https://zitadel.com>
