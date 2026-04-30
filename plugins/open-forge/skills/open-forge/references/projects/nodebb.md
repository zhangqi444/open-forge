---
name: NodeBB
description: Modern Node.js-based forum platform. Real-time chat, social login, rich editor, plugin ecosystem. Supports MongoDB (primary), PostgreSQL, or Redis as database. GPL-3.0.
---

# NodeBB

NodeBB is a Node.js forum — faster and more modern than the PHP-era options (phpBB, Flarum, Discourse-via-Ruby). Real-time posting via WebSockets, mobile-first design, 400+ plugins, pluggable database (MongoDB recommended), built-in social login (Google/Facebook/GitHub/etc.), first-class theming.

- Upstream repo: <https://github.com/NodeBB/NodeBB>
- Docs: <https://docs.nodebb.org>
- Install docs: <https://docs.nodebb.org/installing/os>
- Docker image: `ghcr.io/nodebb/nodebb` (also builds from upstream repo)

## Architecture in one minute

Three services minimum:

1. **`nodebb`** — the Node.js app on port 4567
2. **Database** — **MongoDB 7+ recommended** (default), or **PostgreSQL 18+**; Redis can also serve as primary DB but is usually for cache/scaling only
3. **Redis** (optional) — clustering, pub/sub, session store when running multi-instance

The upstream `docker-compose.yml` uses Docker Compose profiles (`mongo` is default, `redis` and `postgres` are opt-in with `--profile`). Only one primary DB should be enabled.

## Compatible install methods

| Infra      | Runtime                                  | Notes                                                                  |
| ---------- | ---------------------------------------- | ---------------------------------------------------------------------- |
| Single VM  | Docker + upstream `docker-compose.yml`   | **Recommended self-host path**                                         |
| Single VM  | Native Node.js 20+ + MongoDB             | Upstream documents this; used by NodeBB Cloud                          |
| Kubernetes | Community manifests / Helm              | Stateless Node + external DB; clustering via Redis                      |
| Managed    | NodeBB Cloud                             | Upstream-hosted, SaaS pricing                                          |

## Inputs to collect

| Input                   | Example                                 | Phase     | Notes                                                              |
| ----------------------- | --------------------------------------- | --------- | ------------------------------------------------------------------ |
| Public URL              | `https://forum.example.com`             | Runtime   | Baked into `config.json`; required                                 |
| DB type                 | `mongo` (recommended) / `postgres` / `redis-only` | Bootstrap | Chosen during `./nodebb setup`                                |
| DB credentials          | strong password                         | DB        | **Change from default `nodebb/nodebb`**                             |
| Admin account           | username + email + password             | Bootstrap | First user created during setup wizard                             |
| SMTP                    | any provider                            | Runtime   | Email verification + password reset                                |
| Secret key              | auto-generated                          | Runtime   | Stored in `config.json`; **back up with DB**                       |
| Node version            | `>=20`                                  | Runtime   | Container bundles it; bare-metal needs managed install             |

## Install via Docker Compose (upstream default: MongoDB)

From <https://github.com/NodeBB/NodeBB/blob/master/docker-compose.yml>:

```sh
git clone --depth 1 https://github.com/NodeBB/NodeBB.git
cd NodeBB

# Edit install/docker/setup.json with your admin email/password + URL
# (this gets baked in at setup-time, avoids the web wizard)
cp install/docker/setup.json.example install/docker/setup.json

# Bring up MongoDB + NodeBB (mongo is the default profile)
docker compose up -d
```

The default compose:

- **`nodebb`** — built from the repo's Dockerfile (or uncomment `image: ghcr.io/nodebb/nodebb:latest` to pull prebuilt)
- **`mongo`** — `mongo:7-jammy` with init script at `install/docker/mongodb-user-init.js`
- **`postgres`** — profile-gated (`--profile postgres`)
- **`redis`** — profile-gated (`--profile redis`)

For PostgreSQL instead of MongoDB:

```sh
docker compose --profile postgres up -d
```

For Redis as the primary DB (unusual; typically for read-heavy caches):

```sh
docker compose --profile redis up -d
```

**Never run all three profiles at once** — NodeBB uses only one primary DB; the others sit idle or fight over the same DB name.

### Pin the image

The default compose uses `build: .` — fine for development. For production, switch to the pinned release image:

```yaml
  nodebb:
    # build: .
    image: ghcr.io/nodebb/nodebb:3.x       # or specific patch version
```

Tags at <https://github.com/NodeBB/NodeBB/pkgs/container/nodebb>.

## Install via native Node.js

```sh
git clone -b master https://github.com/NodeBB/NodeBB.git
cd NodeBB
./nodebb setup            # interactive: URL, DB, admin account
./nodebb start            # run forever
# OR, as a service:
sudo cp /path/to/nodebb.service /etc/systemd/system/
sudo systemctl enable --now nodebb
```

`./nodebb setup` prompts for URL, DB choice (mongo/postgres/redis), DB host/port/auth, admin username/email/password. After setup, edit `config.json` directly for advanced tuning.

## Data & config layout

- `config.json` (container: `/opt/config/config.json`) — URL, DB connection string, `secret`, port — this is the source of truth
- `public/uploads/` (container volume: `nodebb-uploads`) — user-uploaded avatars, images, attachments
- `build/` (container volume: `nodebb-build`) — compiled template + client assets
- MongoDB / Postgres / Redis data — one volume per DB service
- Custom plugins installed via `./nodebb plugins -i nodebb-plugin-X` — compiled into `build/`

## Backup

```sh
# MongoDB
docker compose exec -T mongo mongodump --archive=/tmp/nodebb.archive && \
  docker compose cp mongo:/tmp/nodebb.archive ./nodebb-mongo-$(date +%F).archive

# Postgres variant
docker compose exec -T postgres pg_dump -U nodebb nodebb | gzip > nodebb-pg-$(date +%F).sql.gz

# Uploads
docker run --rm -v nodebb_nodebb-uploads:/src -v "$PWD":/backup alpine \
  tar czf /backup/nodebb-uploads-$(date +%F).tgz -C /src .

# config.json (small but critical)
docker compose cp nodebb:/opt/config/config.json ./config-$(date +%F).json
```

## Upgrade

1. Releases: <https://github.com/NodeBB/NodeBB/releases>.
2. Pin image tag; `docker compose pull && docker compose up -d`.
3. NodeBB runs migrations automatically on startup. Watch logs for `info: Database Upgrade Complete!`.
4. **Upgrade one major at a time** (e.g. 2.x → 3.x, not 1.x → 3.x directly). Mismatched DB schemas from skipped majors cause cryptic errors.
5. Upgrade docs: <https://docs.nodebb.org/installing/upgrade>.
6. Plugins may not be compatible with a new major — check each plugin's repo before upgrading.

## Gotchas

- **Default DB credentials `nodebb/nodebb` are in the upstream compose.** Change them in BOTH the DB service AND the NodeBB config. Public-internet NodeBB + default creds = instant compromise.
- **Only one primary DB.** Running with two profiles enabled (e.g. `--profile redis --profile postgres`) makes the behavior undefined — NodeBB picks whichever its `config.json` points to and the others idle.
- **WebSockets require reverse-proxy support.** Nginx needs `proxy_http_version 1.1` + `Upgrade`/`Connection` headers. Traefik, Caddy, and HAProxy handle this out of the box. Without it, real-time posting falls back to long-polling (slow + flaky).
- **`config.json` `secret` must stay stable.** It signs session cookies. Rotating it = every user logged out. Losing it = same effect.
- **MongoDB 7 vs 8 upgrade** requires running a compat shim (`setFeatureCompatibilityVersion`) before rolling. If you bump `mongo:7-jammy` → `mongo:8` without this, Mongo refuses to start.
- **Postgres port mapping is default** (`5432:5432`). Remove the public port mapping in production — Postgres inside the compose network doesn't need to be reachable from outside.
- **Plugin quality varies.** The 400+ plugin ecosystem includes several abandoned plugins that silently break with new NodeBB majors. Stick with officially-maintained or high-star plugins.
- **Bind-mounted volumes use `./docker/database/*` subpaths** — upstream compose does this because Docker's `driver_opts: o: bind, device:` pattern means you can't use named volumes elsewhere. If you modify the compose, preserve the directory layout.
- **Email is required for real usage.** Without SMTP, new users can't verify their email and can't reset passwords. Bare install blocks realistic operation quickly.
- **Social login requires HTTPS.** OAuth providers (Google, Facebook, GitHub) reject HTTP callback URLs in production. Set up TLS before enabling social auth.
- **`install/docker/setup.json`** if populated before first boot pre-configures the admin account, skipping the web wizard. Great for IaC.
- **Theming = actual templates.** NodeBB's theme system compiles `.tpl` files into client assets. Theme changes require `./nodebb build` — the image's entrypoint handles this, but ignoring the `nodebb-build` volume means a rebuild on every container restart.
- **Scaling past 1 instance** needs Redis for pub/sub + session sharing. Set up the `redis` profile alongside `mongo`, point NodeBB at both in `config.json`.
- **GPL-3.0 source license.** Forks must share source. Closed-source forum SaaS can't use NodeBB verbatim.
- **Compared to Flarum**: NodeBB is Node.js (faster, heavier) vs Flarum's PHP (simpler deployment). Both are modern; NodeBB has more features built in, Flarum has more "taste". NodeBB is commercial-hosted (Cloud) — Flarum has no first-party hosting.

## Links

- Repo: <https://github.com/NodeBB/NodeBB>
- Docs: <https://docs.nodebb.org>
- Install: <https://docs.nodebb.org/installing/os>
- Cloud-installation docs: <https://docs.nodebb.org/installing/cloud/>
- Upgrade docs: <https://docs.nodebb.org/installing/upgrade>
- Releases: <https://github.com/NodeBB/NodeBB/releases>
- Docker image: <https://github.com/NodeBB/NodeBB/pkgs/container/nodebb>
- Plugins directory: <https://nodebb.org/plugins>
- Themes directory: <https://nodebb.org/themes>
- NodeBB Cloud: <https://nodebb.com/>
- Community forum: <https://community.nodebb.org/>
