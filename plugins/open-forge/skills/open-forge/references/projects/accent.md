---
name: accent-project
description: Accent recipe for open-forge. Covers Docker single-container and Docker Compose install as documented at https://github.com/mirego/accent.
---

# Accent

Developer-oriented, open source translation management tool. Provides asynchronous workflow between translators and dev teams, full history with rollback, CLI tooling, GraphQL API, and SSO via GitHub/GitLab/Google/Slack/Discord/Microsoft/OIDC. Built on Elixir/Phoenix + PostgreSQL. Upstream: <https://github.com/mirego/accent>. Official site: <https://www.accent.reviews/>. Demo: <https://accent-demo.fly.dev>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker single container | <https://github.com/mirego/accent#-getting-started> | Quickest path — just bring your own PostgreSQL |
| Docker Compose (build from source) | <https://github.com/mirego/accent/blob/master/docker-compose.yml> | Local dev or full stack self-host |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| db | "PostgreSQL connection URL?" | `postgresql://<user>:<pass>@<host>/<db>` | `DATABASE_URL` |
| security | "Secret key base (64-byte hex)?" | Run `openssl rand -hex 64` | `SECRET_KEY_BASE` — required; unsafe default must be overridden |
| security | "Signing salt?" | Run `openssl rand -hex 32` | `SIGNING_SALT` |
| auth | "Which login provider(s)?" | Choice: Dummy (email only) / GitHub / GitLab / Google / Slack / Discord / Microsoft / OIDC | At least one required; `DUMMY_LOGIN_ENABLED=1` for simple setups |
| email (optional) | "Email provider?" | Choice: SendGrid / Mailgun / Mandrill / SMTP / None | `MAILER_FROM` + provider-specific key |
| domain | "Canonical URL (e.g. https://translations.example.com)?" | URL | `CANONICAL_URL` — required for OAuth redirects and outbound email links |

## Docker quick-start (from upstream README)

```bash
# 1. Create .env
cat > .env << 'ENV'
DATABASE_URL=postgresql://postgres:password@db:5432/accent_development
SECRET_KEY_BASE=$(openssl rand -hex 64)
SIGNING_SALT=$(openssl rand -hex 32)
DUMMY_LOGIN_ENABLED=1
CANONICAL_URL=https://translations.example.com
ENV

# 2. Run
docker run --env-file .env -p 4000:4000 mirego/accent
```

Access at `http://localhost:4000`.

## Key environment variables

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SECRET_KEY_BASE` | ✅ | 64-byte hex — encrypts sessions. **Always override the default.** |
| `SIGNING_SALT` | ✅ | Signs session cookies. **Always override.** |
| `CANONICAL_URL` | Prod | App URL — used in OAuth callbacks and outbound emails |
| `DUMMY_LOGIN_ENABLED` | Dev | Set to `1` for email-only login (no password) |
| `FORCE_SSL` | Prod | Redirect HTTP → HTTPS and WS → WSS |
| `MAILER_FROM` | Email | From address for outbound emails |
| `SMTP_ADDRESS` / `SMTP_PORT` / `SMTP_USERNAME` / `SMTP_PASSWORD` | Email | SMTP sender config |
| `SENDGRID_API_KEY` | Email | Alternative to SMTP |
| `MAILGUN_API_KEY` + `MAILGUN_DOMAIN` | Email | Alternative to SMTP |
| `RESTRICTED_PROJECT_CREATOR_EMAIL_DOMAIN` | Optional | Lock project creation to one email domain |

Full environment variable reference: <https://github.com/mirego/accent#-environment-variables>

## Software-layer concerns

| Concern | Detail |
|---|---|
| Port | Default `4000` (`PORT` env var) |
| Database | PostgreSQL ≥ 9.4. Accent runs Ecto migrations automatically on startup. |
| Auth | At minimum, enable `DUMMY_LOGIN_ENABLED=1` or configure one OAuth provider — otherwise no one can log in. |
| Translations vault | `MACHINE_TRANSLATIONS_VAULT_KEY` — encrypts API keys for machine translation services (DeepL etc.). Override the unsafe default. |
| Data dir | No local file storage — all state in PostgreSQL. |
| GraphQL API | Available at `/graphiql` — fully documented. |

## Upgrade procedure

Per <https://github.com/mirego/accent/releases>:

1. Pull the new image: `docker pull mirego/accent`
2. Stop and restart with the same environment: `docker stop accent && docker run --env-file .env -p 4000:4000 mirego/accent`
3. Ecto migrations run automatically on startup.
4. Verify at `http://localhost:4000`.

## Gotchas

- **Unsafe defaults**: `SECRET_KEY_BASE` and `SIGNING_SALT` have hardcoded dev defaults. Running with these in production means sessions can be forged. Always set them explicitly.
- **Auth required**: with `DUMMY_LOGIN_ENABLED` unset and no OAuth configured, the login page appears but no login method works.
- **`CANONICAL_URL` for OAuth**: OAuth providers redirect to `CANONICAL_URL` after authentication. Misconfigured URL breaks all SSO logins.
- **`FORCE_SSL` and reverse proxy**: if terminating TLS at Nginx/Caddy and setting `FORCE_SSL=true`, ensure `X-Forwarded-Proto: https` is forwarded — otherwise Accent enters an HTTPS redirect loop.
- **Email optional**: Accent functions without email (invites and collaboration reminders are disabled), but useful for team workflows.

## Links

- Upstream README & env vars: <https://github.com/mirego/accent>
- Docker Hub: <https://hub.docker.com/r/mirego/accent>
- Demo: <https://accent-demo.fly.dev>
- CLI: <https://github.com/mirego/accent/tree/master/cli>
