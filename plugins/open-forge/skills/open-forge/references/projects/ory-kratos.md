---
name: ory-kratos
description: Recipe for Ory Kratos — cloud-native identity and user management server (login, registration, MFA, account recovery).
---

# Ory Kratos

API-first, cloud-native identity and user management system. Handles login, registration, account recovery/verification, MFA, and profile management flows via HTTP APIs — your app's UI drives the flows, Kratos handles the logic and storage. No built-in UI; you bring your own (or use the reference UI). Part of the Ory ecosystem (pairs with Ory Hydra for OAuth2/OIDC). Upstream: <https://github.com/ory/kratos>. Docs: <https://www.ory.com/docs/kratos/>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://www.ory.com/docs/kratos/quickstart> | Yes | Recommended quickstart and dev setup |
| Helm chart | <https://k8s.ory.sh/helm/charts> | Yes | Kubernetes production deployments |
| Binary | <https://github.com/ory/kratos/releases> | Yes | Bare-metal installs |
| Ory Network (cloud) | <https://console.ory.sh> | Yes (managed) | Hosted SaaS — no self-hosting needed |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Public URL for Kratos public API? | HTTPS URL (e.g. https://kratos.example.com) | Required for cookie domains + redirects |
| infra | Database DSN? | postgres:// or sqlite:// | Required; SQLite for dev, PostgreSQL for prod |
| software | SMTP credentials for email flows? | host:port + user/pass | Required for account verification + recovery |
| software | Secrets (cookie, cipher)? | 32-byte hex strings | Required; generate with `openssl rand -hex 16` |
| software | Identity schema URL? | URL to JSON schema | Optional; defaults to basic email+password schema |

## Software-layer concerns

### Docker Compose (quickstart)

```yaml
services:
  kratos-migrate:
    image: oryd/kratos:v26.2.0
    environment:
      DSN: sqlite:///var/lib/sqlite/db.sqlite?_fk=true&mode=rwc
    volumes:
      - kratos-sqlite:/var/lib/sqlite
      - ./kratos-config:/etc/config/kratos
    command: migrate sql -e --yes
    restart: on-failure

  kratos:
    depends_on:
      - kratos-migrate
    image: oryd/kratos:v26.2.0
    ports:
      - "4433:4433"   # public API
      - "4434:4434"   # admin API (never expose publicly)
    restart: unless-stopped
    environment:
      DSN: sqlite:///var/lib/sqlite/db.sqlite?_fk=true
      LOG_LEVEL: trace
    command: serve -c /etc/config/kratos/kratos.yml --dev --watch-courier
    volumes:
      - kratos-sqlite:/var/lib/sqlite
      - ./kratos-config:/etc/config/kratos

volumes:
  kratos-sqlite:
```

> Production: use PostgreSQL DSN and never use `--dev` flag.

### Example kratos.yml

```yaml
version: v1.0.0

dsn: sqlite:///var/lib/sqlite/db.sqlite?_fk=true

serve:
  public:
    base_url: http://127.0.0.1:4433/
    cors:
      enabled: true
  admin:
    base_url: http://kratos:4434/

selfservice:
  default_browser_return_url: http://127.0.0.1:4455/
  allowed_return_urls:
    - http://127.0.0.1:4455

  methods:
    password:
      enabled: true
    totp:
      config:
        issuer: Kratos
      enabled: true

  flows:
    error:
      ui_url: http://127.0.0.1:4455/error
    settings:
      ui_url: http://127.0.0.1:4455/settings
    recovery:
      enabled: true
      ui_url: http://127.0.0.1:4455/recovery
    verification:
      enabled: true
      ui_url: http://127.0.0.1:4455/verification
    logout:
      after:
        default_browser_return_url: http://127.0.0.1:4455/login
    login:
      ui_url: http://127.0.0.1:4455/login
    registration:
      ui_url: http://127.0.0.1:4455/registration

log:
  level: debug
  format: text
  leak_sensitive_values: true

secrets:
  cookie:
    - PLEASE-CHANGE-ME-I-AM-VERY-INSECURE
  cipher:
    - 32-LONG-SECRET-NOT-SECURE-AT-ALL-!!

courier:
  smtp:
    connection_uri: smtps://test:test@mailslurper:1025/?skip_ssl_verify=true

identity:
  default_schema_id: default
  schemas:
    - id: default
      url: base64://...  # or file:///etc/config/kratos/identity.schema.json
```

### Ports

| Port | Purpose |
|---|---|
| 4433 | Public API — exposed to users/browser (login, registration flows) |
| 4434 | Admin API — internal only; never expose to internet |

### Self-service UI

Kratos has no built-in UI. You must provide one. Options:
- **Ory Kratos SelfService UI Node.js** (reference): <https://github.com/ory/kratos-selfservice-ui-node>
- Build your own using the flow APIs

## Upgrade procedure

```bash
# Run migrations first
docker run --rm oryd/kratos:v26.2.0 migrate sql -e --yes --config /etc/config/kratos/kratos.yml

# Then update the service
docker compose pull && docker compose up -d
```

Always run migrations before upgrading the server binary. Check the upgrade guide: <https://www.ory.com/docs/kratos/guides/upgrade>

## Gotchas

- Admin API must never be publicly exposed: port 4434 is for internal/backend use only. Expose only port 4433 publicly.
- No built-in UI: Kratos exposes flow APIs; your frontend must implement the UI. Use the reference Node.js UI to get started quickly.
- `--dev` flag: disables HTTPS requirement and relaxes security — never use in production.
- Database migrations: always run `migrate sql` before upgrading to a new version.
- Secrets rotation: cookie and cipher secrets must be kept consistent. Changing them invalidates all active sessions.
- Pairs with Ory Hydra for OAuth2/OIDC: Kratos handles identity/sessions; Hydra handles token issuance for third-party apps.

## Links

- GitHub: <https://github.com/ory/kratos>
- Docs: <https://www.ory.com/docs/kratos/>
- Quickstart: <https://www.ory.com/docs/kratos/quickstart>
- Reference UI: <https://github.com/ory/kratos-selfservice-ui-node>
- Docker Hub: <https://hub.docker.com/r/oryd/kratos>
- Ory ecosystem overview: <https://www.ory.com/docs/ecosystem/projects>
