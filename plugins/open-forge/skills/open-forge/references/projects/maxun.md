---
name: Maxun
description: No-code web data extraction platform — visual scraper builder. Point-and-click to extract, scrape, crawl, and search websites; export to Airtable, Google Sheets, or JSON. Playwright-powered browser automation. AGPL-3.0.
---

# Maxun

Maxun lets non-engineers build "robots" that extract structured data from websites. Record a browsing session → Maxun infers selectors → runs on schedule or on-demand → pushes results to Airtable / Google Sheets / webhook. Backed by Playwright + Chromium for rendering.

Four deployment components, all Docker-native:

- Upstream repo: <https://github.com/getmaxun/maxun>
- Docs: <https://docs.maxun.dev>
- Self-host guide: <https://docs.maxun.dev/installation/docker>
- Images: `getmaxun/maxun-backend`, `getmaxun/maxun-frontend` (+ you build `browser` from repo)

## Architecture in one minute

1. **`frontend`** (`getmaxun/maxun-frontend`) — Vite/React UI on :5173
2. **`backend`** (`getmaxun/maxun-backend`) — Node.js API + Playwright orchestrator on :8080
3. **`browser`** (built locally from `browser/Dockerfile`) — dedicated Chromium-in-container on WS :3001 + health :3002
4. **Postgres 13+** — workflows, users, runs, recipes
5. **MinIO** — extracted data / screenshots / binary exports
6. **Redis** (optional but recommended) — job queue + caching

Browser isolation is the big architectural choice: user-defined scrapers never run in the backend container, they run in the dedicated `browser` service (`SYS_ADMIN` cap, `seccomp=unconfined`, 2 GB shm) to prevent one broken scraper from poisoning others.

## Compatible install methods

| Infra     | Runtime                          | Notes                                                                          |
| --------- | -------------------------------- | ------------------------------------------------------------------------------ |
| Single VM (6+ GB RAM) | Docker Compose       | **Recommended.** Upstream ships `docker-compose.yml` + self-hosting doc         |
| Kubernetes | Plain manifests                 | No official chart; community works in progress                                 |
| Managed   | Maxun Cloud                      | Upstream-hosted beta                                                            |

## Inputs to collect

| Input                     | Example                              | Phase    | Notes                                                                |
| ------------------------- | ------------------------------------ | -------- | -------------------------------------------------------------------- |
| `PUBLIC_URL` + `BACKEND_URL` | `https://maxun.example.com`       | Runtime  | Must match external URL exactly; frontend build bakes this in         |
| `DB_PASSWORD`             | random 24+ chars                     | DB       | `openssl rand -base64 24`                                            |
| `JWT_SECRET`              | random 48+ chars                     | Runtime  | Auth token signing                                                   |
| `ENCRYPTION_KEY`          | random 64+ chars                     | Runtime  | Encrypts stored credentials (Airtable/Google tokens, site logins)     |
| `SESSION_SECRET`          | random 48+ chars                     | Runtime  | Express session cookies                                              |
| `MINIO_ACCESS_KEY` + `MINIO_SECRET_KEY` | `minio` / random       | Object store | Change defaults; MinIO console on :9001                           |
| `REDIS_PASSWORD`          | random (or unset for local-only)     | Queue    | If exposing Redis beyond compose network                             |
| Google/Airtable OAuth     | client ID + secret + redirect        | Optional | Only if using the "export to Google Sheets / Airtable" integrations   |
| Chromium resources        | 2 GB RAM, `shm_size: 2gb`, `cap_add: SYS_ADMIN` | Runtime | Required by `browser` service                                   |
| `MAXUN_TELEMETRY`         | `true` / `false`                     | Privacy  | Upstream anonymous usage telemetry; set `false` to disable            |

## Install via Docker Compose (upstream doc)

From <https://docs.maxun.dev/installation/docker>:

```sh
mkdir -p ~/Docker/maxun/{db,minio,redis}
cd ~/Docker/maxun

cat > .env <<'EOF'
NODE_ENV=production
JWT_SECRET=<openssl rand -base64 48>
DB_NAME=maxun
DB_USER=postgres
DB_PASSWORD=<openssl rand -base64 24>
DB_HOST=postgres
DB_PORT=5432
ENCRYPTION_KEY=<openssl rand -base64 64>
SESSION_SECRET=<openssl rand -base64 48>

MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_ACCESS_KEY=minio
MINIO_SECRET_KEY=<openssl rand -base64 24>

REDIS_HOST=maxun-redis
REDIS_PORT=6379
REDIS_PASSWORD=

BACKEND_PORT=8080
FRONTEND_PORT=5173
BACKEND_URL=https://maxun.example.com
PUBLIC_URL=https://maxun.example.com
VITE_BACKEND_URL=https://maxun.example.com
VITE_PUBLIC_URL=https://maxun.example.com

# Optional integrations:
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=
AIRTABLE_CLIENT_ID=
AIRTABLE_REDIRECT_URI=

MAXUN_TELEMETRY=false
EOF

curl -O https://raw.githubusercontent.com/getmaxun/maxun/develop/docker-compose.yml

docker compose up -d
```

Browse `http://<host>:5173`. First signup = admin. Behind a reverse proxy with TLS for production.

### Browser build

The `browser` service is `build`-only (no prebuilt image) — Docker Compose will build it on first `up`. Takes a few minutes. It pulls `browser/Dockerfile` from the repo's `develop` branch structure — cloning the repo is the cleanest approach:

```sh
git clone --depth 1 -b v0.x.y https://github.com/getmaxun/maxun.git
cd maxun
# Copy .env to this dir, then:
docker compose up -d
```

## Data & config layout

- `postgres_data` volume — workflow definitions, users, schedules, run history
- `minio_data` volume — extracted artifacts (CSV exports, screenshots, HTML snapshots)
- Redis — ephemeral job queue; loss = re-queue pending jobs
- **No data on the backend/frontend/browser containers** — they're stateless

## Backup

```sh
# Database (critical — workflows + auth)
docker compose exec -T postgres pg_dump -U postgres maxun | gzip > maxun-db-$(date +%F).sql.gz

# MinIO bucket (extracted data)
docker run --rm -v maxun_minio_data:/src -v "$PWD":/backup alpine \
  tar czf /backup/maxun-minio-$(date +%F).tgz -C /src .
```

The `ENCRYPTION_KEY` is required to decrypt stored OAuth tokens. Losing it = re-authorize every integration. Back it up separately from compose files (e.g. in a password manager).

## Upgrade

1. Releases: <https://github.com/getmaxun/maxun/releases>.
2. Bump image tags (and `git pull` the browser Dockerfile), `docker compose pull && docker compose build browser && docker compose up -d`.
3. Migrations run automatically on backend startup.
4. Upgrade doc: <https://docs.maxun.dev/installation/upgrade>.

## Gotchas

- **Playwright needs 2 GB+ shared memory.** The `browser` service specifies `shm_size: 2gb` — lowering this causes Chromium crashes on non-trivial pages (dev tools open, modern SPAs).
- **`SYS_ADMIN` capability is granted to `browser`.** Required for Chromium sandboxing, but means the browser container is equivalent to host-root for container escape purposes. Keep it on an isolated Docker network if running untrusted scrapers.
- **`seccomp=unconfined`** on both `backend` and `browser` weakens container isolation. These scrape-the-wild-internet workloads are inherently high-risk; isolate on a dedicated host or VM.
- **`BACKEND_URL` + `PUBLIC_URL` + `VITE_BACKEND_URL` + `VITE_PUBLIC_URL` — four variables that must all match your external URL.** The VITE_* variants are baked into the frontend bundle at build time; changing them requires rebuilding the image (not just restarting).
- **First signup = admin.** No admin-email allowlist built in. Wire up the admin account *before* exposing BACKEND_URL publicly.
- **Bound ports leak services.** The default compose publishes Postgres 5432, MinIO 9000/9001, backend 8080, frontend 5173 **all to 0.0.0.0**. Behind a firewall, change to `127.0.0.1:5432:5432` / similar; only the reverse-proxy-facing ports should be public.
- **MinIO defaults `minio`/`minioadmin`.** The compose references `.env` values — set real ones. A wide-open MinIO console on :9001 is a common own-goal.
- **Scraping is legally gray.** Maxun doesn't enforce robots.txt or rate limits — users do. Self-hosting doesn't change whether a target site considers you abusive; apply judgment + retain lawyer.
- **Bot detection catches Maxun.** Cloudflare, DataDome, PerimeterX, etc. fingerprint Playwright/Chromium. Commercial-scale scraping usually requires stealth patches, residential proxies, or CAPTCHA-solving — not provided by Maxun out-of-the-box.
- **Chromium consumes 500 MB–2 GB per concurrent scrape.** The `deploy.resources` cap is 2 GB / 1.5 CPU. Scaling = scaling-out, not up.
- **Tokenized webhooks / OAuth flows** require public HTTPS URLs (for OAuth callback URIs). Localhost dev only works for hand-testing without integrations.
- **Airtable/Google integrations need OAuth app registration.** Google Sheets export requires `GOOGLE_CLIENT_ID` + `GOOGLE_CLIENT_SECRET` from a Google Cloud project with the Sheets API enabled.
- **`MAXUN_TELEMETRY=true`** ships anonymous usage data to upstream — set `false` if you care about zero upstream calls.
- **AGPL-3.0.** Hosting a modified Maxun as a service requires providing source to users.
- **Redis password is empty by default.** Fine inside the Compose network (Redis is not exposed); set it if you externalize Redis.
- **The upstream compose publishes Postgres/MinIO ports for developer convenience.** Production should remove those mappings.

## Links

- Repo: <https://github.com/getmaxun/maxun>
- Docs: <https://docs.maxun.dev>
- Self-host guide: <https://docs.maxun.dev/installation/docker>
- Env reference: <https://docs.maxun.dev/installation/environment_variables>
- Upgrade guide: <https://docs.maxun.dev/installation/upgrade>
- Releases: <https://github.com/getmaxun/maxun/releases>
- Docker Hub: <https://hub.docker.com/u/getmaxun>
- Discord: <https://discord.com/invite/5GbPjBUkws>
