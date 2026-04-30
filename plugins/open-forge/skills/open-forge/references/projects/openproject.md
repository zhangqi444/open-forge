---
name: OpenProject
description: Full-featured open-source project management — work packages, Gantt charts, Kanban boards, wikis, time tracking, BCF-compatible BIM, meetings, forums, SAML/OIDC SSO. Ruby on Rails monolith. GPL-3.0 Community Edition + proprietary Enterprise add-ons.
---

# OpenProject

OpenProject is a heavyweight project management suite — a competitive self-hosted alternative to Jira, Asana, Basecamp. Rails monolith with PostgreSQL + memcached; collaborative editing via a separate Node.js "hocuspocus" service for real-time work-package editing.

Community Edition (GPL-3.0) is fully featured for most teams; Enterprise Edition adds advanced permissions, custom actions, BIM/IFC, multi-select custom fields, multi-project reporting. Both ship in the same Docker images — you flip `OPENPROJECT_EDITION=enterprise` with a license key.

- Upstream repo: <https://github.com/opf/openproject>
- Docker Compose repo: <https://github.com/opf/openproject-docker-compose> **(use this for prod, not the repo root's dev compose)**
- Docs: <https://www.openproject.org/docs/>
- Install docs: <https://www.openproject.org/docs/installation-and-operations/installation/docker/>
- Helm chart: <https://charts.openproject.org>

## Architecture in one minute

Minimum services for the upstream compose:

1. **`web`** — Rails app server (Puma); serves HTTP
2. **`worker`** — `good_job` background worker (email, attachments, exports)
3. **`cron`** — scheduled jobs (reindexing, cleanup)
4. **`seeder`** — one-shot DB initializer (ensures migrations run, admin user created, demo data optional)
5. **`db`** — PostgreSQL 13 (default) or 17 (recommended for new installs)
6. **`cache`** — memcached
7. **`proxy`** — nginx fronting `web`; handles /hocuspocus/* routing
8. **`hocuspocus`** — Node.js service for real-time collaborative work-package editing (new in 17.x)
9. **`autoheal`** — restarts unhealthy containers (optional but included by default)

Nine containers. Plan accordingly: 4 GB RAM minimum, 8 GB realistic.

## Compatible install methods

| Infra     | Runtime                                            | Notes                                                                  |
| --------- | -------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM | Docker Compose (`opf/openproject-docker-compose`) | **Recommended.** Pin to `stable/17` branch                             |
| Single VM | All-in-one container `openproject/community`       | Easier; bundles PostgreSQL + memcached internally; good for small teams |
| Single VM | `.deb` / `.rpm` packages                           | Native; good if you already manage Postgres separately                 |
| Kubernetes | Official Helm chart                               | Production-grade; scales `web` + `worker` independently                |
| Managed   | openproject.com Cloud                              | SaaS; their own hosting                                                |

## Inputs to collect

| Input                                 | Example                       | Phase     | Notes                                                                    |
| ------------------------------------- | ----------------------------- | --------- | ------------------------------------------------------------------------ |
| `OPENPROJECT_HOST__NAME`              | `op.example.com`              | Runtime   | Must match the public hostname exactly                                   |
| `OPENPROJECT_HTTPS`                   | `true` (prod) / `false` (first boot) | Runtime | Disable for initial local test; enable before public exposure            |
| `SECRET_KEY_BASE`                     | `openssl rand -hex 64`        | Runtime   | **Critical.** Signs sessions + cookies. Never change once set             |
| `COLLABORATIVE_SERVER_SECRET`         | `openssl rand -hex 32`        | Runtime   | Auth between `web` and `hocuspocus` containers                            |
| `DATABASE_URL`                        | `postgres://postgres:p4ssw0rd@db/openproject` | DB | Upstream default pw is `p4ssw0rd` — change it                    |
| `POSTGRES_VERSION`                    | `17` (new installs) / `13` (legacy) | DB  | **Default is still 13 for backwards compat** — bump only after running migration |
| SMTP creds                            | any provider                  | Runtime   | Email required for user invites + notifications                          |
| Admin password                        | change from `admin` default   | Bootstrap | Dashboard → top right → My Account                                        |
| `OPDATA` host path                    | `/var/openproject/assets`     | Data      | Attachments, exports — owned by UID 1000                                  |

## Install via upstream Docker Compose

From <https://github.com/opf/openproject-docker-compose>:

```sh
# 1. Clone stable branch (NOT main — main is dev-only)
git clone --depth=1 --branch=stable/17 \
  https://github.com/opf/openproject-docker-compose.git openproject
cd openproject

# 2. Configure
cp .env.example .env
vim .env
# Set at minimum:
#   OPENPROJECT_HOST__NAME=op.example.com
#   SECRET_KEY_BASE=<openssl rand -hex 64>
#   COLLABORATIVE_SERVER_SECRET=<openssl rand -hex 32>
#   POSTGRES_PASSWORD=<strong password, matches DATABASE_URL>

# 3. Create host volume with correct ownership (attachments live here)
sudo mkdir -p /var/openproject/assets
sudo chown 1000:1000 -R /var/openproject/assets

# 4. First boot: disable HTTPS for bootstrap, pull latest images
OPENPROJECT_HTTPS=false docker compose up -d --build --pull always

# 5. Wait ~2 minutes while seeder runs migrations. Watch logs:
docker compose logs -f seeder

# 6. Browse http://localhost:8080 — login as admin / admin
# 7. Change admin password immediately
```

### Enable HTTPS (production)

After first boot succeeds:

```sh
# Stop, flip OPENPROJECT_HTTPS=true, restart:
docker compose down
# Edit .env: OPENPROJECT_HTTPS=true
docker compose up -d
# Now put a TLS-terminating reverse proxy (Caddy, Traefik, nginx) in front of :8080
```

**OpenProject does NOT terminate TLS itself.** The container's internal `proxy` service is plain HTTP — terminate TLS at an upstream Caddy/Traefik/nginx and proxy to `http://openproject:8080` with `X-Forwarded-Proto: https` + the hostname matching `OPENPROJECT_HOST__NAME`.

### All-in-one container (simpler, smaller teams)

From <https://www.openproject.org/docs/installation-and-operations/installation/docker/#one-container-per-process-recommended>:

```sh
docker run -d --name openproject \
  -p 8080:80 \
  -e OPENPROJECT_HTTPS=false \
  -e OPENPROJECT_HOST__NAME=op.example.com \
  -e OPENPROJECT_SECRET__KEY__BASE="$(openssl rand -hex 64)" \
  -v opdata:/var/openproject/assets \
  -v pgdata:/var/lib/postgresql/15/main \
  openproject/community:17
```

Bundles Postgres + memcached inside. Fine for <20 users; for larger teams use the multi-container compose above.

## Data & config layout

Persistent data (compose setup):

- `${OPDATA:-opdata}` volume — uploaded attachments, generated exports, backups
- `${PGDATA:-pgdata}` volume — PostgreSQL data directory
- `.env` file on host — all runtime config (hostnames, secrets, DB credentials)

Environment variables in OpenProject use **double underscores for nested config**: `OPENPROJECT_FOG_CREDENTIALS_PROVIDER=AWS` maps to `fog.credentials.provider`. See <https://www.openproject.org/docs/installation-and-operations/configuration/environment/>.

## Backup

```sh
# Stop writes, snapshot, restart:
cd /path/to/openproject
docker compose stop web worker cron

# Postgres dump
docker compose exec -T db pg_dump -U postgres openproject | gzip > op-db-$(date +%F).sql.gz

# Attachments volume
docker run --rm -v openproject_opdata:/src -v "$PWD":/backup alpine \
  tar czf /backup/op-opdata-$(date +%F).tgz -C /src .

docker compose start web worker cron

# .env (contains all secrets — keep in a password manager, NOT git)
cp .env op-env-$(date +%F)
```

## Upgrade

1. Releases: <https://www.openproject.org/docs/installation-and-operations/operation/upgrading/>.
2. `git fetch --tags && git checkout stable/18` (next major) when ready.
3. `docker compose pull && docker compose up -d --build` — the `seeder` service runs migrations automatically on startup.
4. **Major upgrades run DB migrations** that can take 10–60 minutes on large DBs; expect downtime.
5. **Postgres major upgrades** (13 → 17) require explicit migration: <https://www.openproject.org/docs/installation-and-operations/misc/migration-to-postgresql17/>. Bumping the `POSTGRES_VERSION` env alone will NOT migrate the DB — Postgres refuses to start on mismatched data dir.
6. Never skip majors (e.g. 14 → 17 without passing through 15 + 16). Each major's migrations assume the prior schema.

## Gotchas

- **Do NOT use the `docker-compose.yml` at the repo root of `opf/openproject`.** That's a dev-only compose (it'll refuse to start with `LOCAL_DEV_CHECK` unset). Use the dedicated `opf/openproject-docker-compose` repo, `stable/17` branch.
- **`p4ssw0rd` is the default Postgres password in the upstream compose.** Change it in BOTH `.env` (`POSTGRES_PASSWORD`) AND the `DATABASE_URL` to the matching value. Exposed instance + default pw = database compromise.
- **`SECRET_KEY_BASE` rotation invalidates all sessions + encrypted stored values.** Generate once, back it up with your DB backup, never change it.
- **OpenProject assumes HTTPS in production.** Without `OPENPROJECT_HTTPS=true` + a reverse proxy in front of it, users get redirected to weird URLs. For first boot, set `OPENPROJECT_HTTPS=false` explicitly; flip to true once TLS is ready.
- **Postgres default version is 13 (not 17).** Upstream keeps `POSTGRES_VERSION=13` as default "as to not break existing setups." New installs should set `POSTGRES_VERSION=17` in `.env` BEFORE the first boot. Changing it after the first boot = manual dump+restore required.
- **Hocuspocus is new in 17.x.** It's the real-time collaborative-editing backend. If you disable it (by removing the service), collaborative editing stops working but OpenProject continues to function otherwise.
- **9 containers = heavy.** 4 GB RAM is the practical minimum; 8 GB for smooth operation with 20+ users. Smaller teams should consider the all-in-one `openproject/community` image instead.
- **Email is required for realistic usage.** Users invited without SMTP configured never receive their activation link.
- **Enterprise Edition is a license-key flip, not a separate image.** The same `openproject/openproject` image runs CE; set `OPENPROJECT_EDITION=enterprise` + license key to unlock Enterprise features. Source is GPL-3.0; Enterprise add-ons live behind a runtime flag.
- **BIM/IFC features are bandwidth-heavy.** If you enable BIM, uploads can be gigabytes. Check your reverse proxy `client_max_body_size` (nginx default 1 MB rejects these).
- **LDAP + SAML SSO work differently.** LDAP is built-in; SAML/OIDC requires configuration via environment variables (prefix `OPENPROJECT_AUTH__SAML_*`). See <https://www.openproject.org/docs/system-admin-guide/authentication/>.
- **Default `admin/admin` credentials are universally known.** Change on first login; OpenProject prompts you.
- **`caprover`-style autoheal is enabled by default** (`willfarrell/autoheal` sidecar). It restarts any container with `autoheal=true` label that's unhealthy for 10 minutes. Fine for production; remove if you prefer manual intervention.
- **Helm chart is the production-grade path for Kubernetes.** Compose works but scaling beyond one host is unergonomic; migrate to K8s + chart when growing.
- **Pinning image tag matters.** `openproject/openproject:17-slim` floats within the 17.x line. For strict stability, pin `17.3.1` (or whatever current patch is). Releases: <https://github.com/opf/openproject/releases>.
- **`/hocuspocus` path must be proxied through the same host** or the `OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL` env must be set to a distinct reachable URL. Misconfigured = collaborative editing silently breaks.

## Links

- Repo: <https://github.com/opf/openproject>
- Docker Compose repo: <https://github.com/opf/openproject-docker-compose>
- Docs home: <https://www.openproject.org/docs/>
- Docker install: <https://www.openproject.org/docs/installation-and-operations/installation/docker/>
- Configuration: <https://www.openproject.org/docs/installation-and-operations/configuration/>
- Environment variables: <https://www.openproject.org/docs/installation-and-operations/configuration/environment/>
- Upgrade: <https://www.openproject.org/docs/installation-and-operations/operation/upgrading/>
- Postgres 13 → 17 migration: <https://www.openproject.org/docs/installation-and-operations/misc/migration-to-postgresql17/>
- Helm chart: <https://charts.openproject.org>
- Releases: <https://github.com/opf/openproject/releases>
- Cloud edition: <https://www.openproject.org/enterprise-edition/>
