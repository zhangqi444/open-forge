---
name: Etherpad
description: Real-time collaborative document editor. Node.js server with Postgres (or MySQL/SQLite/Dirty/RethinkDB/CouchDB) backing store. Open-source since 2008 — the OG collaborative editor.
---

# Etherpad

Etherpad (upstream package name: `etherpad-lite`) is a lightweight real-time collaborative text editor. Multiple users edit the same "pad" concurrently; changes sync via WebSocket, with authorship highlighting and a plugin ecosystem for rich text, chat, spell-check, LDAP auth, etc.

- Upstream repo: <https://github.com/ether/etherpad>
- Docs: <https://etherpad.org/doc/>
- Docker docs: <https://github.com/ether/etherpad/blob/develop/doc/docker.md>
- Image: `etherpad/etherpad` on Docker Hub

## Compatible install methods

| Infra              | Runtime                 | Notes                                                                  |
| ------------------ | ----------------------- | ---------------------------------------------------------------------- |
| Single VM          | Docker + Compose        | **Recommended.** Upstream ships `docker-compose.yml`                   |
| Single VM          | Node.js + pnpm          | `pnpm install --prod` + `pnpm run prod`; supported for packagers       |
| Kubernetes         | Community manifests     | No official chart                                                      |
| PaaS               | Heroku / Railway / Fly  | Dockerfile-friendly; config via env                                    |

## Inputs to collect

| Input                  | Example                                | Phase     | Notes                                                                           |
| ---------------------- | -------------------------------------- | --------- | ------------------------------------------------------------------------------- |
| `ADMIN_PASSWORD`       | strong random                          | Runtime   | Admin login for `/admin` UI; username is `admin`                                |
| DB type + creds        | `postgres` + user/pass/db              | Runtime   | SQLite / MySQL / Postgres / RethinkDB / CouchDB / Dirty all supported           |
| `TRUST_PROXY`          | `true`                                 | Runtime   | Required behind a reverse proxy for correct client IP logging + cookies         |
| `DEFAULT_PAD_TEXT`     | `" "` (must be non-empty)              | Runtime   | Upstream treats empty as invalid — bug flagged in compose                        |
| `DISABLE_IP_LOGGING`   | `true` / `false`                       | Runtime   | Privacy-sensitive deployments should set `true`                                   |
| `SOFFICE`              | `/usr/bin/soffice` or `null`           | Runtime   | LibreOffice path for Office-format import/export; off by default                 |
| Port                   | `9001`                                 | Runtime   | Etherpad listens here; terminate TLS at a reverse proxy                          |

## Install via Docker Compose

Upstream's `docker-compose.yml` (at <https://github.com/ether/etherpad/blob/develop/docker-compose.yml>) uses Postgres 15:

```sh
git clone https://github.com/ether/etherpad.git
cd etherpad

# Pick strong passwords (the defaults in compose are "admin" / "admin"):
cat > .env <<EOF
DOCKER_COMPOSE_APP_ADMIN_PASSWORD=$(openssl rand -base64 24)
DOCKER_COMPOSE_POSTGRES_USER=etherpad
DOCKER_COMPOSE_POSTGRES_PASSWORD=$(openssl rand -base64 24)
DOCKER_COMPOSE_POSTGRES_DATABASE=etherpad
DOCKER_COMPOSE_APP_PORT_PUBLISHED=9001
DOCKER_COMPOSE_APP_DISABLE_IP_LOGGING=true
DOCKER_COMPOSE_APP_TRUST_PROXY=true
EOF

docker compose up -d
```

Pin the image tag — upstream compose uses `etherpad/etherpad:latest`. Check releases at <https://github.com/ether/etherpad/releases> and set `image: etherpad/etherpad:<ver>` (edit compose or use override).

Browse `http://<host>:9001/` for the pad UI and `http://<host>:9001/admin/` for plugin management (login with `admin` / your `ADMIN_PASSWORD`).

### Using an external database

Etherpad supports many databases — for managed Postgres, set:

```
DB_TYPE=postgres
DB_HOST=<external-host>
DB_PORT=5432
DB_NAME=etherpad
DB_USER=etherpad
DB_PASS=<pw>
DB_CHARSET=utf8mb4
```

Drop the local `postgres` service from compose if using external DB.

### Single-container / dev mode

For a SQLite-backed single-container deploy (no Postgres), run:

```sh
docker run -d --name etherpad -p 9001:9001 \
  -e ADMIN_PASSWORD=<pw> \
  -e DB_TYPE=sqlite \
  -e DB_FILENAME=/opt/etherpad-lite/var/etherpad.sqlite \
  -v etherpad-var:/opt/etherpad-lite/var \
  etherpad/etherpad:2
```

## Data & config layout

- `plugins` volume → `/opt/etherpad-lite/src/plugin_packages` — installed plugins persist here
- `etherpad-var` volume → `/opt/etherpad-lite/var` — pad attachments, session data, SQLite if used
- `postgres_data` volume → `/var/lib/postgresql/data/pgdata` — database
- `/opt/etherpad-lite/settings.json` inside container — rendered from env vars; edit only via env or custom `settings.json` bind mount

Full env reference: <https://github.com/ether/etherpad/blob/develop/.env.default>

## Plugins

Install from the `/admin/plugins` UI or pre-install at build time. Popular plugins: `ep_adminpads2`, `ep_chat`, `ep_comments_page`, `ep_spellcheck`, `ep_markdown`. Plugins are npm packages (prefix `ep_`).

To pre-install (so they survive container recreation) either mount the `plugins` volume or build a custom image with `pnpm install ep_foo ep_bar` in the Dockerfile.

## Backup

```sh
# Postgres (upstream default)
docker compose exec -T postgres pg_dump -U etherpad etherpad | gzip > etherpad-db-$(date +%F).sql.gz

# Pad attachments + SQLite (if any)
docker run --rm -v etherpad_etherpad-var:/data -v "$PWD":/backup alpine \
  tar czf /backup/etherpad-var-$(date +%F).tgz -C /data .
```

Pads themselves live in the database. Losing the DB = losing all pads.

## Upgrade

1. Releases: <https://github.com/ether/etherpad/releases>.
2. Bump `etherpad/etherpad` tag (major versions may require DB migration — read release notes).
3. `docker compose pull && docker compose up -d`.
4. Plugins may need re-install after major upgrades if they pin to an older Etherpad version.

## Gotchas

- **Default admin password is `admin`/`admin`.** The upstream compose uses this as a fallback if `DOCKER_COMPOSE_APP_ADMIN_PASSWORD` isn't set. **Always** set a real password before booting.
- **`DEFAULT_PAD_TEXT` cannot be empty.** Upstream compose comment: "For now, the env var DEFAULT_PAD_TEXT cannot be unset or empty; it seems to be mandatory in the latest version." A single space works.
- **WebSocket passthrough is mandatory.** If your reverse proxy doesn't forward `Upgrade` / `Connection: upgrade`, pads look like they work but never sync between users.
- **`TRUST_PROXY=true` is required behind any proxy.** Without it Etherpad logs the proxy's IP for every client, and rate limiting becomes cluster-global.
- **No built-in authentication by default.** Anyone who reaches the Etherpad URL can create + edit pads. Plugins like `ep_auth_useraccount` or external auth (OIDC via reverse proxy) are needed for anything public-facing.
- **Pad URLs are the security boundary.** Anyone with the URL can access the pad unless you enable group/session auth via the HTTP API. Treat pad names like secrets.
- **Plugin quality varies.** Many plugins haven't been updated for Etherpad v2 — check `ep_*` npm package compatibility before installing.
- **`etherpad-lite` rename** — the project renamed from `etherpad-lite` to `etherpad`. Old docker image `etherpad/etherpad-lite` still exists but is deprecated; use `etherpad/etherpad`.
- **SQLite backend works but is not recommended beyond a handful of users.** Write contention stalls pads under load.
- **No server-side rate limiting on pad creation.** A spammer can create millions of pads; front this with a reverse proxy that rate-limits POSTs to `/p/`.
- **`DISABLE_IP_LOGGING=false` (default) logs client IPs** to stdout + access.log in every pad event. Set to `true` for privacy-first deployments.
- **Postgres 15 is pinned in upstream compose.** For upgrades to 16/17, pg_dump → restore into a new volume.

## Links

- Repo: <https://github.com/ether/etherpad>
- Docker docs: <https://github.com/ether/etherpad/blob/develop/doc/docker.md>
- Plugin catalog: <https://static.etherpad.org/plugins.html>
- Env reference: <https://github.com/ether/etherpad/blob/develop/.env.default>
- API docs: <https://etherpad.org/doc/v1.8.18/#index_http_api>
- Releases: <https://github.com/ether/etherpad/releases>
