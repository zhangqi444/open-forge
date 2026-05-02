# Clean Slate

Calorie tracker designed for people who struggle with dieting, binging, and self-compassion. Log food, quick-add calories/protein, scan barcodes via Open Food Facts, track exercise and meals. Works on any browser.

- **Official site:** <https://cleanslate.sh>
- **Upstream repo:** <https://github.com/successible/cleanslate>
- **License:** Apache 2.0

---

## Compatible Combos

| Infra       | Runtime        | Notes                                      |
|-------------|----------------|--------------------------------------------|
| Any Linux   | Docker Compose | Official path; includes Caddy reverse proxy |
| Coolify     | Docker         | Use docker-compose.yml directly             |
| Kubernetes  | Helm/manifests | Community effort; reference docker-compose  |

---

## Inputs to Collect

**Phase: Pre-deploy**
- `DOMAIN` — FQDN for your instance (required; Caddy auto-provisions TLS via Let's Encrypt)
- `POSTGRES_PASSWORD` — strong random password for PostgreSQL
- `HASURA_GRAPHQL_ADMIN_SECRET` — Hasura console admin secret (keep private)
- `HASURA_GRAPHQL_JWT_SECRET` — JWT secret for auth (JSON object, see upstream docs)
- `JWT_SIGNING_SECRET` — signing secret for auth server

**Phase: Post-deploy**
- First user created manually via Hasura console (`/console`) → `profiles` table → Insert Row → note the `apiToken`

---

## Software-Layer Concerns

**Config paths & env vars:**
- Run `bash configuration.sh` to generate `.env` and `Caddyfile` interactively
- `.env` holds all secrets — do not commit or share
- `Caddyfile` configures Caddy; requires port 80 open temporarily for Let's Encrypt, then port 443 only

**Services (docker-compose):**
- `database` — PostgreSQL 15 (port 5432, internal)
- `graphql-server` — Hasura GraphQL engine (port 8080, internal)
- `authentication-server` — Next.js auth server (port 3001, internal)
- `client` — Next.js frontend
- Caddy serves everything externally over HTTPS

**Data directories:**
- PostgreSQL data: `database` named volume
- Caddy config/certs: managed by Caddy container

**Authentication modes:**
1. **Local Auth (default/easy)** — pulls pre-built images, starts Caddy
2. **Firebase Auth (complex)** — builds images locally; rarely needed

---

## Upgrade Procedure

```bash
cd cleanslate
git pull origin main
bash deploy.sh
```

Always check [GitHub Releases](https://github.com/successible/cleanslate/releases) before upgrading — release notes include breaking changes and migration steps. There is a ~20-minute lag between a release and images being available on the registry.

---

## Gotchas

- **HTTPS required** — Clean Slate will not work over plain HTTP. Caddy + Let's Encrypt handles this automatically if `DOMAIN` is a real FQDN with port 80 accessible.
- **User provisioning is manual** — after deploy, go to `https://your-domain/console`, log in with `HASURA_GRAPHQL_ADMIN_SECRET`, navigate to `Data → public → profiles → Insert Row`, then note the generated `apiToken`. That long token is the login password.
- **Multi-user setup** — repeat the Insert Row step for each user.
- **Firebase is optional** — only needed if you want OAuth social login. Local auth is simpler.
- **`uuid-runtime` required** — needed for `configuration.sh` to run on Debian/Ubuntu.

---

## Links

- Upstream README: <https://github.com/successible/cleanslate#readme>
- docker-compose.yml: <https://github.com/successible/cleanslate/blob/main/docker-compose.yml>
- configuration.sh: <https://github.com/successible/cleanslate/blob/main/configuration.sh>
- Releases: <https://github.com/successible/cleanslate/releases>
