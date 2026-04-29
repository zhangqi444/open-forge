---
name: La Suite Docs (suitenumerique/docs)
description: Open-source collaborative text editor — Notion/Google-Docs alternative built by the French government's "La Suite Numérique". Django backend + Next.js frontend + y-provider (Yjs CRDT for real-time co-editing) + PostgreSQL + Redis + S3. MIT (core) with some GPL features (PDF export).
---

# La Suite Docs

"Docs" is a collaborative document editor — rich-text + markdown, live cursors, block-based editing (BlockNote), subpages / hierarchy, granular access control, `.docx` / `.odt` / `.pdf` export. Built by the French public-sector "La Suite Numérique" program and deployed in production at scale on Kubernetes (upstream's own deployment). Docker Compose is supported as an **experimental, community-supported** alternative.

> **Upstream caveat** (from the install README, paraphrased): "We only run Kubernetes in production. We can only provide advanced support for Kubernetes. Compose is provided experimentally — file issues, we'll try to help."

- Upstream repo: <https://github.com/suitenumerique/docs>
- Installation guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md>
- Docker Compose guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/compose.md>
- Kubernetes guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/kubernetes.md>
- Images: `lasuite/impress-backend`, `lasuite/impress-frontend`, `lasuite/impress-y-provider` on Docker Hub

## Architecture in one minute

- **`backend`** — Django app (`lasuite/impress-backend`) — REST API, auth, permissions, document storage metadata, media signing
- **`frontend`** — Next.js + BlockNote (`lasuite/impress-frontend`) — served via nginx
- **`y-provider`** — Yjs / HocusPocus WebSocket server (`lasuite/impress-y-provider`) — real-time collaboration backbone
- **PostgreSQL 16** — document metadata
- **Redis 8** — Django cache + Celery broker
- **S3-compatible object store** (MinIO example provided) — actual document content + uploaded media
- **OIDC Identity Provider** (Keycloak example provided) — **mandatory**, Docs has no built-in local-password auth
- **Reverse proxy with TLS** (nginx-proxy example provided) — mandatory in production

## Compatible install methods

| Infra         | Runtime                              | Notes                                                                       |
| ------------- | ------------------------------------ | --------------------------------------------------------------------------- |
| Kubernetes    | Helm charts + `impress.values.yaml`  | **Production path upstream uses.** Only method with "advanced support"      |
| Single VM     | Docker Compose (official example)    | Experimental but functional; needs OIDC + S3 wired in                       |
| Single VM     | Docker Compose with MinIO + Keycloak | All-in-one bundle; upstream ships compose examples for both                 |
| Community     | Nix, Podman, YunoHost, Coop-Cloud    | Contributor-maintained; see installation README for links                    |
| Cloud         | Clever Cloud marketplace             | One-click; 🇫🇷 provider                                                      |

## Inputs to collect

| Input                            | Example                                            | Phase    | Notes                                                                 |
| -------------------------------- | -------------------------------------------------- | -------- | --------------------------------------------------------------------- |
| Public URL                       | `https://docs.yourdomain.tld`                      | Runtime  | Used by frontend + OIDC redirect URIs                                 |
| OIDC provider                    | Keycloak realm `docs` with client `docs`           | Runtime  | **Mandatory**; set `OIDC_RP_CLIENT_ID`, `OIDC_RP_CLIENT_SECRET`       |
| S3 bucket + credentials          | `docs-media-storage` on MinIO or AWS               | Runtime  | Set `AWS_S3_ACCESS_KEY_ID`, `AWS_S3_SECRET_ACCESS_KEY`, `AWS_STORAGE_BUCKET_NAME` |
| `DJANGO_SECRET_KEY`              | random 50+ chars                                   | Runtime  | Django signing key; generate once                                     |
| `DB_PASSWORD`                    | strong password                                    | DB       | Postgres password (used by backend + Postgres init)                    |
| `Y_PROVIDER_API_KEY` + `COLLABORATION_SERVER_SECRET` | random strings                 | Runtime  | Shared secret between backend ↔ y-provider                             |
| SMTP                             | any provider                                       | Runtime  | For invitations + notifications                                       |
| `PUBLISH_AS_MIT`                 | `true` / `false`                                   | Build    | `true` = strip GPL-only features (like PDF export) — see Gotchas       |

## Install via Docker Compose (experimental)

From <https://github.com/suitenumerique/docs/blob/main/docs/installation/compose.md>:

```sh
# 1. Prepare workspace
mkdir -p docs/env.d && cd docs

# 2. Grab the upstream compose + env.d templates
curl -o compose.yaml https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docs/examples/compose/compose.yaml
curl -o env.d/common     https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/common
curl -o env.d/backend    https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/backend
curl -o env.d/yprovider  https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/yprovider
curl -o env.d/postgresql https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/env.d/production.dist/postgresql
# nginx-proxy variant:
curl -o default.conf.template https://raw.githubusercontent.com/suitenumerique/docs/refs/heads/main/docker/files/production/etc/nginx/conf.d/default.conf.template

# 3. Edit env.d/common — OIDC_RP_CLIENT_*, AWS_S3_*, DOCS_HOST, email settings
# 4. Edit env.d/backend — DJANGO_SECRET_KEY, REDIS_URL, DJANGO_EMAIL_* ...
# 5. Edit env.d/postgresql — DB_PASSWORD
# 6. Edit env.d/yprovider — Y_PROVIDER_API_KEY, COLLABORATION_SERVER_SECRET

# 7. Pin image tags in compose.yaml (upstream defaults :latest — don't use in prod)
# 8. Bring it up
docker compose up -d

# 9. Run initial migrations + create admin
docker compose run --rm backend python manage.py migrate
docker compose run --rm backend python manage.py createsuperuser --email admin@yourdomain.tld --password 'REPLACE_ME'
```

Browse `https://docs.yourdomain.tld` → log in via OIDC (first user gains access as a normal user; admin UI is at `/admin`).

### Add Keycloak + MinIO + nginx-proxy

Upstream ships three additional example composes in `docs/examples/compose/`:

- `keycloak/compose.yaml` — a pre-configured Keycloak realm (`realm.json`) with a `docs` client
- `minio/compose.yaml` — MinIO with auto-bucket provisioning
- `nginx-proxy/compose.yaml` — `jwilder/nginx-proxy` + `acme-companion` for automatic Let's Encrypt TLS

Each has its own README with the `VIRTUAL_HOST` / `LETSENCRYPT_HOST` wiring the base compose expects.

## Install via Kubernetes (upstream-recommended)

Upstream ships example Helm values files in `docs/examples/helm/`:

- `impress.values.yaml` — the Docs application itself
- `keycloak.values.yaml` + `postgresql.values.yaml` (for keycloak's db)
- `minio.values.yaml`
- `postgresql.values.yaml` (for Docs itself)
- `redis.values.yaml`

Install order: Postgres → Redis → MinIO → Keycloak → Docs. Kubernetes guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/kubernetes.md>.

## Data & config layout

- `./data/databases/backend/` — Postgres data (compose example)
- S3 bucket — all document content + uploaded media; **the DB alone is not a sufficient backup**
- `env.d/common` — shared env (OIDC, S3, host)
- `env.d/backend` — Django settings, SMTP, AI
- `env.d/yprovider` — y-provider secrets
- `env.d/postgresql` — Postgres init env

## Backup

```sh
# 1. Postgres
docker compose exec -T postgresql pg_dump -U impress impress | gzip > docs-db-$(date +%F).sql.gz

# 2. S3 bucket — the actual document content lives here, NOT in Postgres
mc mirror docs-media-storage/ backups/docs-media-$(date +%F)/    # MinIO client
# or: aws s3 sync s3://docs-media-storage backups/docs-media-$(date +%F)/

# 3. OIDC config (Keycloak realm export) — necessary to re-create users+clients after disaster
docker compose exec keycloak /opt/keycloak/bin/kc.sh export --dir /tmp/realms && \
  docker cp $(docker compose ps -q keycloak):/tmp/realms backups/keycloak-$(date +%F)/
```

## Upgrade

1. Upgrade notes (mandatory reading): <https://github.com/suitenumerique/docs/blob/main/UPGRADE.md>.
2. Changelog: <https://github.com/suitenumerique/docs/blob/main/CHANGELOG.md>.
3. Bump image tags in `compose.yaml`, `docker compose pull`, `docker compose up -d`.
4. If UPGRADE.md lists manual migration steps (rare but happens), run them before restarting.
5. For Kubernetes: `helm upgrade` with new chart + pinned image tag.

## Gotchas

- **OIDC is mandatory.** There is no fallback local-password login. If your IdP is down, nobody can log in. Run the IdP HA if Docs is production-critical.
- **S3 is mandatory.** Document content lives in S3, not Postgres. No built-in local-disk mode for production. For single-host setups, run MinIO in the same compose.
- **"PUBLISH_AS_MIT=true" strips GPL features.** PDF export via BlockNote's XL packages is GPL, not MIT — if your org can't use GPL components, you must rebuild the frontend image with `PUBLISH_AS_MIT=true`, losing PDF export. Most private deployments skip this and use the prebuilt `lasuite/impress-frontend:latest`.
- **`frontend` user is UID 101.** Volume permissions on `./default.conf.template` must allow UID 101 read access, or nginx inside the container fails silently (the container starts but serves 502s).
- **`backend` requires `DJANGO_CONFIGURATION=Production` env.** Without this env var, Django runs in dev mode and refuses to serve static assets.
- **Upstream compose uses `:latest` tags.** **Pin explicitly** to released versions (see GHCR / Docker Hub for Docker images and releases page for version numbers). `:latest` has moved through breaking changes.
- **Celery / background workers aren't in the example compose.** The `backend` image runs the web process; periodic tasks (metadata indexing, cleanup) will not run. For small installs this is OK; for busy ones you need to run `backend` again with a `celery worker` command.
- **`y-provider` is a stateful WebSocket server.** Don't scale it horizontally without sticky sessions — Yjs documents are held in memory per-connection; splitting a doc's editors across replicas fragments the collaboration state.
- **Default Keycloak realm file uses `impress` as a display name.** Unrelated to the public product name "Docs" / "La Suite Docs" — Impress is the internal codename. Don't be confused when you see `lasuite/impress-*` images and `impress` in DB names.
- **Reverse proxy must forward WebSocket for y-provider** (path usually `/ws/...`). `nginx-proxy` example handles this; custom proxies need `Upgrade`/`Connection` headers.
- **Export/import formats:** import works for `.docx` and `.md`; export works for `.docx`, `.odt`, `.pdf`. No `.html` export; no bulk import.
- **Django admin (`/admin`)** is separate from the OIDC-authenticated user base. Superusers created via `createsuperuser` log in with local creds at `/admin` only; regular-user access goes through OIDC.
- **Default credentials in `make bootstrap` (dev setup)** are `impress` / `impress`. These exist only in the local-development compose (`compose.yml` in repo root), NOT in the production `docs/examples/compose/compose.yaml`. Don't confuse the two files.
- **AI features are opt-in** (`AI_FEATURE_ENABLED=true`) and require an external OpenAI-compatible endpoint. No on-prem model shipped.
- **Scaling past ~1k concurrent editors** needs Kubernetes + horizontal y-provider replicas with a shared Redis persistence layer for Yjs updates — not supported in the compose example.
- **French government origin**: active development, clear governance; but issue responses are sometimes in French. English is welcome on GitHub and Matrix.

## Links

- Repo: <https://github.com/suitenumerique/docs>
- Installation index: <https://github.com/suitenumerique/docs/blob/main/docs/installation/README.md>
- Compose guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/compose.md>
- Kubernetes guide: <https://github.com/suitenumerique/docs/blob/main/docs/installation/kubernetes.md>
- Upgrade guide: <https://github.com/suitenumerique/docs/blob/main/UPGRADE.md>
- Changelog: <https://github.com/suitenumerique/docs/blob/main/CHANGELOG.md>
- Env variable reference: <https://github.com/suitenumerique/docs/blob/main/docs/env.md>
- Example composes: <https://github.com/suitenumerique/docs/tree/main/docs/examples/compose>
- Helm values: <https://github.com/suitenumerique/docs/tree/main/docs/examples/helm>
- Matrix chat: <https://matrix.to/#/#docs-official:matrix.org>
- Docker Hub org: <https://hub.docker.com/u/lasuite>
