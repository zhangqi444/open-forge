---
name: umami-project
description: Umami recipe for open-forge. MIT-licensed privacy-focused web analytics — Next.js app + PostgreSQL or MySQL backend. Simple, fast, GDPR-compliant alternative to Google Analytics that runs on a single container + DB. Covers Docker Compose (upstream-shipped), source install (Node 18.18+ + pnpm), and the critical `APP_SECRET` rotation-semantics pitfall that invalidates all sessions.
---

# Umami

MIT-licensed privacy-focused web analytics — a Next.js app backed by PostgreSQL or MySQL. Upstream: <https://github.com/umami-software/umami>. Docs: <https://umami.is/docs>.

One container, one DB, no cookies, no personal data, no sampling. Drop a `<script>` tag on your site; Umami aggregates pageviews, sessions, referrers, UTM params, events. Works without a cookie banner in most jurisdictions.

## What's in the box

- Next.js app on port `:3000`
- PostgreSQL v12.14+ or MySQL v8+ backend
- Built-in default user (`admin` / `umami`) created on first run — **must change immediately**
- Share URLs, team support, multi-website, funnels, retention, goals

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (upstream compose.yml) | <https://github.com/umami-software/umami/blob/master/docker-compose.yml> | ✅ Recommended | The upstream-blessed self-host shape. Ships PostgreSQL alongside. |
| Docker image (`ghcr.io/umami-software/umami`) | <https://github.com/umami-software/umami/pkgs/container/umami> | ✅ | External DB / custom orchestration. Also published at `docker.umami.is/umami-software/umami`. |
| Source install (`pnpm install && pnpm build && pnpm start`) | README §Installing from Source | ✅ | Dev / customization. Node 18.18+ and pnpm required. |
| Vercel + external PG | Docs | ✅ | Hosted cheap; ok for small sites. |
| Railway / Render / Dokku | Community | ⚠️ | Varies. Use Docker image + managed PG. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `compose` / `docker` / `source` | Drives section. |
| db | "Database backend?" | `AskUserQuestion`: `postgresql` / `mysql` | Upstream compose ships PG; MySQL works but you'll need to edit `DATABASE_URL`. |
| secrets | "`APP_SECRET`?" | Free-text (sensitive, generate `openssl rand -hex 32`) | **MUST rotate from the `replace-me-with-a-random-string` default.** Used to sign session JWTs. Rotating invalidates all existing sessions (users re-login). |
| secrets | "Database password?" | Free-text (sensitive) | Default in compose is `umami`/`umami`/`umami` — rotate for production. |
| dns | "Public domain?" | Free-text | For reverse proxy + TLS. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Umami does not terminate TLS. |
| admin | "Initial admin credentials?" | Free-text (sensitive) | Default is `admin` / `umami` — **change on first login**. |

## Install — Docker Compose (upstream-recommended)

Upstream's `docker-compose.yml` on `master`:

```yaml
services:
  umami:
    image: ghcr.io/umami-software/umami:latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://umami:umami@db:5432/umami
      APP_SECRET: replace-me-with-a-random-string     # MUST change
    depends_on:
      db:
        condition: service_healthy
    init: true
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "curl http://localhost:3000/api/heartbeat"]
      interval: 5s
      timeout: 5s
      retries: 5
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: umami
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: umami                        # MUST change for production
    volumes:
      - umami-db-data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5
volumes:
  umami-db-data:
```

Bring up:

```bash
# Generate a strong APP_SECRET and a strong DB password BEFORE starting
export APP_SECRET=$(openssl rand -hex 32)
export DB_PASS=$(openssl rand -hex 24)

# Edit compose.yml to inject ${APP_SECRET} and ${DB_PASS}, or write a .env file
cat > .env <<EOF
APP_SECRET=${APP_SECRET}
POSTGRES_PASSWORD=${DB_PASS}
EOF

docker compose up -d
docker compose logs -f umami
```

Login at `http://<host>:3000/login` with `admin` / `umami`. Go to **Profile → Change Password** immediately.

## Install — Docker with external PostgreSQL

```bash
docker run -d \
  --name umami \
  -p 3000:3000 \
  -e DATABASE_URL='postgresql://umami:xxx@db.internal:5432/umami' \
  -e APP_SECRET='<generated>' \
  --restart unless-stopped \
  ghcr.io/umami-software/umami:latest
```

On first boot, Umami runs its own Prisma migrations and creates tables + the default admin.

## Install — from source (dev)

```bash
# Requires Node 18.18+ and pnpm
git clone https://github.com/umami-software/umami.git
cd umami
pnpm install

cat > .env <<'EOF'
DATABASE_URL=postgresql://umami:umami@localhost:5432/umami
APP_SECRET=<generated-random-hex>
EOF

pnpm run build     # runs migrations + seeds default admin on first build
pnpm run start     # listens on :3000
```

## Adding the tracker to a website

After first login, **Settings → Websites → Add website**. Umami generates a `<script>` tag:

```html
<script defer src="https://umami.example.com/script.js" data-website-id="abc-123..."></script>
```

Drop it in the `<head>` of your site. Pageviews start flowing in minutes.

## Environment variables (common)

| Var | Required? | Default | Purpose |
|---|---|---|---|
| `DATABASE_URL` | ✅ | — | `postgresql://...` or `mysql://...` |
| `APP_SECRET` | ✅ (for JWT signing) | — | Sign session tokens. Rotate = force re-login. |
| `DATABASE_TYPE` | Auto-detected | — | `postgresql` / `mysql`. Usually inferred from URL scheme. |
| `TRACKER_SCRIPT_NAME` | ❌ | `script` | Rename `/script.js` to bypass ad-blockers. |
| `COLLECT_API_ENDPOINT` | ❌ | `/api/send` | Rename the collect endpoint to bypass ad-blockers. |
| `DISABLE_TELEMETRY` | ❌ | — | Set to `1` to disable anonymous usage telemetry. |
| `DISABLE_UPDATES` | ❌ | — | Set to `1` to suppress the update-check in the UI. |
| `REMOVE_TRAILING_SLASH` | ❌ | — | Normalize URL tracking. |
| `CLIENT_IP_HEADER` | ❌ | `X-Forwarded-For` | For correct IP detection behind a reverse proxy. |
| `BASE_PATH` | ❌ | — | Serve Umami at a subpath (e.g. `/umami`). |

## Reverse proxy (Caddy)

```caddy
umami.example.com {
    reverse_proxy umami:3000
}
```

## Data layout

| Path | Content |
|---|---|
| Docker volume `umami-db-data` → `/var/lib/postgresql/data` | All pageview data, sessions, event data, user accounts. |

**Backup = `pg_dump` the `umami` DB.** There's no separate file/object storage; everything lives in PostgreSQL.

```bash
docker exec umami-db-1 pg_dump -U umami umami | gzip > umami-$(date +%F).sql.gz
```

## Upgrade procedure

### Docker Compose

```bash
# 1. Back up DB first (above)
# 2. Pull + restart
docker compose pull
docker compose up -d
docker compose logs -f umami
```

Schema migrations run automatically on startup (Prisma migrations). Always read release notes at <https://github.com/umami-software/umami/releases> before a major version bump (v1 → v2 required a one-shot data migration script).

### Source

```bash
git pull
pnpm install
pnpm build     # runs new migrations
pnpm start
```

## Gotchas

- **Default credentials `admin` / `umami` are well-known.** Anyone hitting a fresh install can log in and own your analytics data. Change the password on the first login, BEFORE exposing the instance to the public internet. Better: set a password via the DB before first HTTP exposure.
- **`APP_SECRET=replace-me-with-a-random-string` default.** Upstream's sample compose literally ships this default. Every install that doesn't override it uses the same signing key — anyone with that key can forge session tokens. Rotate to `openssl rand -hex 32` or `openssl rand -base64 48` BEFORE first boot.
- **Rotating `APP_SECRET` invalidates all sessions.** All users get logged out and must re-login. That's the intended behavior but surprises admins mid-day.
- **Ad-blockers block `/script.js` and `/api/send`.** Many uBlock lists ship Umami signatures now. Rename via `TRACKER_SCRIPT_NAME` + `COLLECT_API_ENDPOINT` env vars, or proxy the endpoints through your own domain's paths (e.g. `/_analytics/script.js`), which defeats naive path-based blocklists but not signature-based ones.
- **v1 → v2 data migration was painful.** If you're still on Umami v1 (pre-2023), upgrading to v2 requires running a separate migration script, not just a `docker compose pull`. Read <https://umami.is/docs/migrate-v1-v2> first.
- **`latest` tag drift.** Auto-updaters like Watchtower can bring in a breaking migration. Pin a version tag (`ghcr.io/umami-software/umami:v2.15`) in production.
- **PostgreSQL 15+ required.** Older PG versions (12/13) still work but upstream dev is tested against 15+. Compose ships `postgres:15-alpine`.
- **No built-in TLS.** Terminate at reverse proxy. With a proxy, set `CLIENT_IP_HEADER=X-Forwarded-For` (or `X-Real-IP`) so Umami gets the client's real IP for geo lookups.
- **Trailing-slash double-counts.** `/` and `""` register as different URLs by default. Set `REMOVE_TRAILING_SLASH=1` to normalize, or accept it.
- **Tracker script is NOT async by default in the docs snippet** — uses `defer`. Fine for most sites; if you prefer `async`, swap it in your HTML.
- **DB size grows linearly with pageviews.** High-traffic sites accumulate tens of GB per year. No automatic retention pruning in OSS — upstream's hosted Umami Cloud has retention policies that self-host does not. You can run manual cleanup SQL on the `website_event` and `session` tables.

## Links

- Upstream repo: <https://github.com/umami-software/umami>
- Docs site: <https://umami.is/docs>
- Install docs: <https://umami.is/docs/install>
- Running on Docker: <https://umami.is/docs/running-on-docker>
- Environment variables: <https://umami.is/docs/environment-variables>
- Releases: <https://github.com/umami-software/umami/releases>
- Docker image: <https://github.com/umami-software/umami/pkgs/container/umami>
- Hosted alternative: <https://cloud.umami.is/> (paid, managed)
