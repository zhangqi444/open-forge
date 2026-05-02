# Melody Auth

**What it is:** Self-hostable OAuth 2.0 and authentication server. Supports sign-in, MFA, RBAC, social login, SAML/OIDC SSO, passkeys, and more. Can deploy to Cloudflare Workers (serverless) or self-host with Node.js + PostgreSQL + Redis.

**Official URL:** https://auth.valuemelody.com  
**GitHub:** https://github.com/ValueMelody/melody-auth  
**Stars:** 606

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose (Node.js + PostgreSQL + Redis) | Full self-hosted control |
| Cloudflare | Workers + D1 + KV | Serverless, minimal infra overhead |

---

## Inputs to Collect

### Before deploying (self-hosted)
- Domain for the auth server (e.g., `auth.example.com`)
- PostgreSQL connection details (or use bundled compose service)
- Redis connection details (or use bundled compose service)
- SMTP credentials for email (MFA, verification, password reset)

### Environment / Config (server/.dev.vars or equivalent)
- `ENVIRONMENT` — `production` or `development`
- `DB_*` — PostgreSQL host, port, name, user, password
- `REDIS_*` — Redis host, port
- `SECRET` — JWT/session signing secret
- `SENDGRID_API_KEY` / `MAILGUN_*` / `BREVO_*` / `RESEND_*` / `POSTMARK_*` — email provider (one required for MFA/verification)
- `GOOGLE_AUTH_CLIENT_ID` / `GITHUB_AUTH_CLIENT_ID` / etc. — social login (optional)

---

## Software-Layer Concerns

- **Components:** Auth server (Node.js), Admin Panel (React), optional frontend SDKs (React/Angular/Vue/Web)
- **Database:** PostgreSQL for persistent storage; Redis for sessions/caching
- **Migration:** Run `npm run node:migration:apply` inside the server container on first start and after upgrades
- **Admin Panel:** Deploy separately or together; manages users, apps, scopes, organizations
- **SDKs:** PKCE-based frontend SDKs available on npm for React, Angular, Vue, and plain Web
- **Cloudflare alternative:** Uses Workers + D1 (SQLite) + KV instead of PostgreSQL/Redis — separate deployment path; see upstream docs

---

## Upgrade Procedure

1. Pull latest images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Run migrations: `docker compose exec server npm run node:migration:apply`

---

## Gotchas

- The self-hosted Docker Compose in the repo (`devops/docker/docker-compose.yml`) is a **dev setup** — it builds from source and uses `.dev.vars`. Production deployments should use pre-built images or adapt the compose file
- SAML SSO is **Node.js only** — not available on Cloudflare Workers deployment
- French translations are AI-generated — review before exposing to users
- Admin panel requires a separate deployment and its own env configuration; it's not bundled with the auth server container

---

## References

- Auth server setup: https://auth.valuemelody.com/auth-server-setup.html
- Self-host guide: https://auth.valuemelody.com/auth-server-configuration.html
- Admin panel: https://auth.valuemelody.com/admin-panel-setup.html
- Feature overview: https://github.com/ValueMelody/melody-auth/blob/main/docs/feature-overview.md
- GitHub: https://github.com/ValueMelody/melody-auth
