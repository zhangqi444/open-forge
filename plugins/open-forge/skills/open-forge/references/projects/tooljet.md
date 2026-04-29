---
name: tooljet-project
description: ToolJet recipe for open-forge. AGPLv3 open-source low-code platform for internal tools (dashboards, admin panels, CRUD apps) — visual drag-and-drop builder with 50+ data source integrations. Self-host via Docker Compose (upstream's canonical path, using `docker-compose-db.yaml` + `internal.sh` helper to generate secrets). Ships a built-in Postgres for convenience, but recommends external PostgreSQL for production. This recipe covers the Docker setup (built-in vs external DB), the `LOCKBOX_MASTER_KEY` / `SECRET_KEY_BASE` bootstrap, the `TOOLJET_HOST` + HTTPS requirement, ToolJet Database vs external data sources, and the `try:ee-lts-latest` quick-spin image.
---

# ToolJet

AGPLv3 open-source low-code platform for building internal tools. Upstream: <https://github.com/ToolJet/ToolJet>. Docs: <https://docs.tooljet.com>. Cloud: <https://tooljet.com>.

ToolJet is a visual app builder (similar to Retool, Appsmith): drag-and-drop UI components, wire them to 50+ data sources (Postgres/MySQL/MongoDB/Elasticsearch/S3/GCS/REST/GraphQL/SaaS tools), optionally run custom JS/Python. Output = a custom internal dashboard / admin panel served by the ToolJet server.

**Open-core model:**

- **ToolJet Community (`tooljet/tooljet-ce`)** — AGPLv3. The primary self-host target. Full visual builder, all data sources, multi-user, workspaces, granular permissions.
- **ToolJet Enterprise (`tooljet/tooljet-ee`)** — proprietary add-on. Audit logs, SSO (SAML/SCIM), advanced RBAC, white-labeling. Not on this recipe's happy path.
- **ToolJet Cloud** — managed hosted version.

Latest-version tag: `tooljet/try:ee-lts-latest` (EE LTS in try mode — fine for eval; switch to CE for self-host production).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `docker run` (try) | README `Try using Docker` | ✅ | Single-container quick eval. Uses bundled Postgres. |
| Docker Compose (built-in PostgreSQL) | <https://docs.tooljet.com/docs/setup/docker> | ✅ Recommended for small self-host | Upstream's docs-led path. |
| Docker Compose (external PostgreSQL) | Same docs page | ✅ Recommended for production | Use managed Postgres (RDS / Cloud SQL / supabase-db). |
| Kubernetes / Helm | <https://docs.tooljet.com/docs/setup/helm> | ✅ | Upstream Helm chart exists. |
| AWS EC2 / ECS / EKS | Per-provider docs | ✅ | Marketplace AMIs available. |
| GCP Cloud Run / GKE | Per-provider docs | ✅ | |
| Azure Container / AKS | Per-provider docs | ✅ | |
| DigitalOcean 1-click | DO Marketplace | ✅ | |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-quick` / `compose-builtin-db` / `compose-external-db` / `k8s` / `cloud-provider` | Drives the section used. |
| dns | "`TOOLJET_HOST` (public URL with scheme)?" | Free-text, e.g. `https://tools.example.com` | **REQUIRED.** Must include `http://` or `https://`. The #1 self-host footgun. |
| tls | "Reverse proxy?" | `AskUserQuestion` | ToolJet doesn't terminate TLS natively. |
| secrets | "Generate `LOCKBOX_MASTER_KEY`?" | Auto via `internal.sh` OR `openssl rand -hex 32` | **REQUIRED + irreplaceable.** Encrypts stored datasource credentials. |
| secrets | "Generate `SECRET_KEY_BASE`?" | Auto via `internal.sh` OR `openssl rand -hex 64` | **REQUIRED.** Session cookie signing. |
| db | "External PostgreSQL URL?" | Free-text | External-DB path only. `PG_HOST` / `PG_USER` / `PG_PASS` / `PG_DB`. |
| db | "External Postgres for ToolJet Database?" | Free-text | ToolJet v2+ introduced a separate DB for the no-code built-in database. Can point at the same external Postgres with a different DB name. |
| smtp | "SMTP config (for email auth + invites)?" | Free-text | `SMTP_USERNAME` / `SMTP_PASSWORD` / `SMTP_DOMAIN` / `SMTP_PORT`. |
| auth | "Initial admin email?" | Free-text | Created during first-run signup via UI. |
| storage | "File storage for assets? (filesystem / S3)" | `AskUserQuestion` | `STORAGE_TYPE=local` or `s3`. |

## Install — Quick `docker run` (eval only)

```bash
docker run \
  --name tooljet \
  --restart unless-stopped \
  -p 80:80 \
  --platform linux/amd64 \
  -v tooljet_data:/var/lib/postgresql/13/main \
  tooljet/try:ee-lts-latest
```

Visit `http://<host>/` — sign up, you become the instance owner. This image bundles Postgres in the same container — **not** production-shaped. Use for evaluation only.

## Install — Docker Compose with built-in PostgreSQL (upstream-recommended)

```bash
# 1. Download compose + env template + helper script
curl -LO https://tooljet-deployments.s3.us-west-1.amazonaws.com/pre-release/docker/docker-compose-db.yaml
mv docker-compose-db.yaml docker-compose.yaml

curl -LO https://tooljet-deployments.s3.us-west-1.amazonaws.com/pre-release/docker/.env.internal.example
curl -LO https://tooljet-deployments.s3.us-west-1.amazonaws.com/pre-release/docker/internal.sh
chmod +x internal.sh

mv .env.internal.example .env

# 2. Run internal.sh — auto-generates LOCKBOX_MASTER_KEY, SECRET_KEY_BASE, Postgres password
./internal.sh

mkdir postgres_data

# 3. Edit .env — set TOOLJET_HOST at minimum
#    TOOLJET_HOST=https://tools.example.com
#    (or http://<ip> for LAN testing — MUST include the scheme)

# 4. Bring it up
docker compose up -d
docker compose logs -f

# 5. Visit TOOLJET_HOST, sign up as the first user, become admin.
```

### Download from alternate source

The upstream docs reference files hosted on an S3 bucket (`tooljet-deployments.s3.us-west-1.amazonaws.com`). You can alternatively grab them from the GitHub repo at <https://github.com/ToolJet/ToolJet/tree/main/deploy/docker> — check the repo for any drift.

## Install — Docker Compose with external PostgreSQL (production)

```bash
# 1. Provision an external Postgres — managed (RDS/Cloud SQL/Supabase) or self-hosted.
#    Create TWO databases: one for ToolJet metadata, one for ToolJet Database.
createdb tooljet
createdb tooljet_db

# 2. Download external compose
curl -LO https://tooljet-deployments.s3.us-west-1.amazonaws.com/pre-release/docker/docker-compose.yaml
curl -LO https://tooljet-deployments.s3.us-west-1.amazonaws.com/pre-release/docker/.env.external.example
mv .env.external.example .env

# 3. Edit .env — fill:
#    TOOLJET_HOST=https://tools.example.com
#    LOCKBOX_MASTER_KEY=$(openssl rand -hex 32)
#    SECRET_KEY_BASE=$(openssl rand -hex 64)
#    PG_HOST=<external-pg-host>
#    PG_USER=<user>
#    PG_PASS=<password>
#    PG_DB=tooljet
#    PG_DB_OWNER=tooljet_user        # for ToolJet Database
#    ORM_LOGGING=error
#    ENABLE_TOOLJET_DB=true
#    TOOLJET_DB_HOST=<external-pg-host>
#    TOOLJET_DB_USER=<user>
#    TOOLJET_DB_PASS=<password>
#    TOOLJET_DB=tooljet_db

# 4. Bring it up
docker compose up -d
```

## Reverse proxy (Caddy)

```caddy
tools.example.com {
    reverse_proxy tooljet:80
}
```

Ensure `TOOLJET_HOST=https://tools.example.com` matches what the browser sees. nginx needs websocket headers for multiplayer editing:

```nginx
location / {
    proxy_pass http://127.0.0.1:80;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Data layout

### Built-in-DB compose

| Path / volume | Content |
|---|---|
| `./postgres_data/` (host bind) | Postgres cluster — ToolJet app metadata + ToolJet Database data. |
| Container `/var/lib/tooljet/` | App artifacts, uploaded files (unless `STORAGE_TYPE=s3`). |
| `.env` | **Secrets — back up OUT OF BAND.** |

### External-DB compose

| Resource | Content |
|---|---|
| External Postgres DB `tooljet` | App metadata (apps, data-source configs, workspace members, encrypted credentials). Back up via your DB provider's snapshot mechanism. |
| External Postgres DB `tooljet_db` | User-created tables in ToolJet's no-code database. |
| S3 bucket (if `STORAGE_TYPE=s3`) | Uploaded assets. |
| `.env` | **Secrets — back up OUT OF BAND.** |

### Backup

```bash
# Built-in DB:
docker compose exec postgres pg_dumpall -U postgres | gzip > tooljet-$(date +%F).sql.gz

# External DB: use your provider's snapshot/dump tooling.
```

## Upgrade procedure

```bash
# 1. Read release notes. ToolJet has had breaking changes (v1 → v2 DB schema).
#    https://github.com/ToolJet/ToolJet/releases

# 2. Backup secrets + DB.

# 3. Pull new image + restart
docker compose pull
docker compose up -d
docker compose logs -f | grep -iE 'migrat|error'
```

The ToolJet container runs migrations automatically on boot.

## Gotchas

- **`TOOLJET_HOST` must include the scheme** (`http://` or `https://`). `TOOLJET_HOST=tools.example.com` fails silently — the UI half-loads and API calls fail. Upstream docs emphasize this but users miss it.
- **`LOCKBOX_MASTER_KEY` is irreplaceable.** It encrypts stored datasource credentials (DB passwords, API keys) in the ToolJet DB. Lose or rotate it = every stored credential becomes undecryptable. Back it up BEFORE first boot.
- **`SECRET_KEY_BASE` rotation = session invalidation.** All logged-in users get booted; not data loss.
- **`internal.sh` output is ephemeral.** The helper script generates secrets and writes them into `.env`. Grep `.env` for `LOCKBOX_MASTER_KEY=` and `SECRET_KEY_BASE=` and stash both in your password manager.
- **`try:ee-lts-latest` bundles Postgres inside the ToolJet container.** Fine for eval, terrible for production — a container restart that corrupts Postgres = data loss with no separate snapshot surface. Always use the full compose (separate Postgres container or external DB) for real deployments.
- **ToolJet Database is separate from app DB.** Introduced in v2.x. Users can create tables via the UI, stored in a separate DB. If you migrate from v1, there's a migration step to enable it.
- **AGPLv3 license triggers copy-left on distribution.** If you modify ToolJet and deploy the modified version as a service accessible over a network, you must publish your modifications under AGPLv3. Internal-only self-host is fine.
- **50+ data sources each have their own quirks.** A failing query to, say, Elasticsearch usually traces back to the Elasticsearch side, not ToolJet. Check the query's response payload in the ToolJet debugger before blaming ToolJet.
- **JS / Python custom code runs in the ToolJet server** (not sandboxed per user). Malicious apps from untrusted workspace members could execute arbitrary code in the server context. Restrict "create app" permissions appropriately.
- **Multiplayer editing uses WebSockets.** Reverse proxy must forward WS (nginx: `Upgrade` / `Connection` headers). Symptom of misconfiguration: second editor's changes don't appear until page refresh.
- **Marketplace apps require `ENABLE_MARKETPLACE=true`.** Hidden behind a feature flag. Set it in `.env` if users need to import community-shared templates.
- **EE vs CE switching.** `tooljet-ee` images have a gated feature set behind a license key. Plain `tooljet-ce` is the AGPL core. Mixing them breaks the DB in interesting ways — pick one and stick with it.
- **Postgres version pinning.** The built-in compose bundles Postgres 13. Upstream migration from PG 13 → 15/16 is manual (not handled by compose updates) — `pg_dumpall` → recreate volume → restore.

## Links

- Upstream repo: <https://github.com/ToolJet/ToolJet>
- Docs site: <https://docs.tooljet.com>
- Docker setup: <https://docs.tooljet.com/docs/setup/docker>
- Helm chart: <https://docs.tooljet.com/docs/setup/helm>
- Environment variables: <https://docs.tooljet.com/docs/setup/env-vars>
- Component reference: <https://docs.tooljet.com/docs/widgets/button>
- Data source reference: <https://docs.tooljet.com/docs/data-sources/airtable/>
- Slack: <https://tooljet.com/slack>
- Releases: <https://github.com/ToolJet/ToolJet/releases>
