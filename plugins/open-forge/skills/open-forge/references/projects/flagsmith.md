# Flagsmith

Open-source feature flag and remote config service. Roll out features safely, run A/B tests, and manage remote configuration across web, mobile, and server-side apps. 15+ SDK languages. BSD 3-Clause. 6K+ GitHub stars. Upstream: <https://github.com/Flagsmith/flagsmith>. Docs: <https://docs.flagsmith.com>.

Flagsmith runs as a Django API on port `8000` + optional task processor, backed by PostgreSQL.

## Compatible install methods

Verified against upstream README at <https://github.com/Flagsmith/flagsmith#get-up-and-running-in-less-than-a-minute>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (one-liner) | `curl -o docker-compose.yml https://raw.githubusercontent.com/Flagsmith/flagsmith/main/docker-compose.yml && docker compose up` | ✅ | Quickest self-hosted start. |
| Docker Compose (cloned) | `git clone https://github.com/Flagsmith/flagsmith && docker compose up` | ✅ | More control over config. |
| Helm (Kubernetes) | <https://docs.flagsmith.com/deployment/kubernetes> | ✅ | Production K8s deploy. |
| Flagsmith Cloud | <https://flagsmith.com> | ✅ (hosted) | Managed SaaS — free tier available. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secret_key | "Django SECRET_KEY (generate: `openssl rand -hex 32`)?" | Free-text (sensitive) | All |
| db_password | "PostgreSQL password?" | Free-text (sensitive) | All |
| domain | "Public domain for Flagsmith (e.g. `flagsmith.example.com`)?" | Free-text | Production |
| signup | "Allow public signup?" | `AskUserQuestion`: `Yes` / `No (invitation only)` | All |

## Software-layer concerns

### Docker Compose quickstart

```bash
# One-liner
curl -o docker-compose.yml \
  https://raw.githubusercontent.com/Flagsmith/flagsmith/main/docker-compose.yml
docker compose up

# Or clone for full control
git clone https://github.com/Flagsmith/flagsmith
cd flagsmith
docker compose up
```

Visit `http://localhost:8000`. On first run, check the compose logs for the admin password-set link:

```
Superuser "admin@example.com" created successfully.
Please go to the following page and choose a password: http://localhost:8000/password-reset/confirm/...
```

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string | Default in compose: `postgresql://postgres:password@postgres:5432/flagsmith` |
| `DJANGO_SECRET_KEY` | Django session/CSRF secret | **Required in production** — change from default |
| `DJANGO_ALLOWED_HOSTS` | Allowed hostnames | Default `*` — restrict to your domain in production |
| `FLAGSMITH_DOMAIN` | Your deployment domain | Used in admin UI | 
| `ENVIRONMENT` | Runtime environment | Set to `production` in production |
| `PREVENT_SIGNUP` | Disable public self-registration | `true` to close signups |
| `ALLOW_REGISTRATION_WITHOUT_INVITE` | Open registration | `false` = invitation-only |
| `TASK_RUN_METHOD` | How to run async tasks | `TASK_PROCESSOR` (recommended), `SYNCHRONOUSLY`, `SEPARATE_THREAD` |
| `USE_POSTGRES_FOR_ANALYTICS` | Store flag analytics in Postgres | `true` (default in compose) |
| `PROMETHEUS_ENABLED` | Expose Prometheus metrics | `true` / `false` |
| `EMAIL_BACKEND` | Email backend class | e.g. `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | SMTP host | For invite/notification emails |
| `SENDER_EMAIL` | From address | For emails |
| `FLAGSMITH_LICENSE` | Enterprise license key | For enterprise features (SSO, RBAC, etc.) |

### Architecture

| Service | Role |
|---|---|
| `flagsmith` | Django API — serves REST API + admin UI on port `8000` |
| `flagsmith-task-processor` | Async task worker (when `TASK_RUN_METHOD=TASK_PROCESSOR`) |
| `postgres` | PostgreSQL 15 — primary data store |

### SDK integration

```bash
# Install SDK (JS example)
npm install flagsmith

# Initialize
import flagsmith from 'flagsmith';
flagsmith.init({
  environmentID: "your-environment-key",
  api: "https://flagsmith.example.com/api/v1/",  // point to your instance
  onChange: (oldFlags, params) => {
    if (flagsmith.hasFeature('my_feature')) {
      // feature is enabled
    }
  }
});
```

SDKs available for: JavaScript, Python, Java, .NET, Ruby, Go, Rust, PHP, Flutter, iOS/Swift, Android/Kotlin, React Native, Elixir, Django.

### Feature flag workflow

1. Create a **Project** (groups environments)
2. Create an **Environment** (Development, Staging, Production — each gets its own SDK key)
3. Create a **Feature Flag** — toggle on/off per environment
4. Optionally add **Segments** to target specific users
5. Use **Remote Config** to return a value (string, int, JSON) instead of just on/off
6. Use **Multivariate flags** for A/B testing

### Data directories

| Path | Contents |
|---|---|
| `pgdata` volume | All Flagsmith data — flags, environments, analytics, users |

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`

Django migrations run automatically on startup via the `migrate-db` init container.

## Gotchas

- **`DJANGO_SECRET_KEY` must be changed.** The compose file ships with `secret` as the default — this is insecure for any internet-facing deployment.
- **`DJANGO_ALLOWED_HOSTS` must be set.** Default is `*`. Set to your domain(s) in production to prevent host header attacks.
- **Admin email is `admin@example.com`.** The bootstrapped admin account always uses this email. Check compose logs for the password-reset link on first run.
- **Task processor service is separate.** If you use `TASK_RUN_METHOD=TASK_PROCESSOR`, you must run the `flagsmith-task-processor` service. Without it, async tasks (analytics aggregation, webhooks) won't run.
- **Two Docker registries.** Images are at `docker.flagsmith.com/flagsmith/flagsmith` (primary) and `flagsmith/flagsmith` on Docker Hub. Both work.
- **Enterprise features need a license.** SSO (SAML, LDAP), advanced audit logs, and RBAC require a `FLAGSMITH_LICENSE` key. Core feature flags are fully open-source.
- **License: BSD 3-Clause** (open-source core). Enterprise features under commercial license.

## Links

- Upstream: <https://github.com/Flagsmith/flagsmith>
- Docs: <https://docs.flagsmith.com>
- Self-hosted guide: <https://docs.flagsmith.com/deployment/docker>
- Environment variables: <https://docs.flagsmith.com/deployment/locally-api#environment-variables>
- SDK docs: <https://docs.flagsmith.com/clients>
- Version comparison: <https://docs.flagsmith.com/version-comparison>
