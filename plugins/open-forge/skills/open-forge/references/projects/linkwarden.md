---
name: Linkwarden
description: Collaborative bookmark manager with full-page archiving (screenshot + PDF + single-file HTML), tagging, AI tagging, RSS, and team collections. Next.js + Postgres + Meilisearch.
---

# Linkwarden

Linkwarden saves links into collections, takes a snapshot of each page (screenshot, PDF, single-file HTML via `monolith`, `readability` extract), indexes them with Meilisearch, and optionally runs AI-based auto-tagging (OpenAI, Ollama, LM Studio). Multi-user, team collections, browser extensions + native mobile apps.

- Upstream repo: <https://github.com/linkwarden/linkwarden>
- Docs: <https://docs.linkwarden.app/>
- Self-hosting guide: <https://docs.linkwarden.app/self-hosting/>
- Image: `ghcr.io/linkwarden/linkwarden`

## Architecture in one minute

Three services:

1. **linkwarden** — Next.js app + background workers (archive, search index)
2. **postgres** — Postgres 16 (pinned in upstream compose)
3. **meilisearch** — full-text search (`v1.12.8` pinned upstream)

Headless Chromium (`@sparticuz/chromium` or Playwright) is bundled inside the linkwarden container for page capture.

## Compatible install methods

| Infra              | Runtime                  | Notes                                            |
| ------------------ | ------------------------ | ------------------------------------------------ |
| Single VM (2+ GB RAM) | Docker + Compose      | **Recommended.** Upstream ships `docker-compose.yml` |
| Kubernetes         | Community Helm           | No official chart                                |
| Bare metal (Node)  | `yarn build && yarn start` | Requires Chromium + Postgres + Meilisearch host-side |

## Inputs to collect

| Input                    | Example                                         | Phase     | Notes                                                                       |
| ------------------------ | ----------------------------------------------- | --------- | --------------------------------------------------------------------------- |
| `NEXTAUTH_URL`           | `https://links.example.com/api/v1/auth`         | Runtime   | **Must include `/api/v1/auth` path.** Used for callbacks                    |
| `NEXTAUTH_SECRET`        | `openssl rand -base64 32`                       | Runtime   | **Required.** Session signing; rotating invalidates sessions                 |
| `POSTGRES_PASSWORD`      | strong random                                   | Runtime   | Used by both postgres service and linkwarden's `DATABASE_URL`               |
| `MEILI_MASTER_KEY`       | `openssl rand -hex 16`                          | Runtime   | **Required** or Meilisearch refuses connections; the upstream compose leaves it unset — must be added |
| AI provider (optional)   | OpenAI / Ollama / LM Studio                     | Runtime   | For auto-tagging; set `OPENAI_API_KEY` or `NEXT_PUBLIC_OLLAMA_ENDPOINT_URL` |
| S3 (optional)            | endpoint + bucket + keys                        | Runtime   | Stores archives in S3 instead of `./data` volume                            |
| SMTP (optional)          | any provider                                    | Runtime   | Needed for password reset and email-verified signup                         |

## Install via Docker Compose

Upstream's `docker-compose.yml` (at <https://github.com/linkwarden/linkwarden/blob/main/docker-compose.yml>) — note the **missing Meilisearch env vars**; you must add `MEILI_MASTER_KEY` yourself:

```sh
git clone https://github.com/linkwarden/linkwarden.git
cd linkwarden

curl -fsSL -o .env.example https://raw.githubusercontent.com/linkwarden/linkwarden/main/.env.sample
cp .env.example .env

# Edit .env (at minimum):
cat > .env <<EOF
NEXTAUTH_URL=https://links.example.com/api/v1/auth
NEXTAUTH_SECRET=$(openssl rand -base64 32)
POSTGRES_PASSWORD=$(openssl rand -base64 24)
MEILI_MASTER_KEY=$(openssl rand -hex 16)
MEILI_HOST=http://meilisearch:7700
# Optional AI:
# OPENAI_API_KEY=sk-...
# OPENAI_MODEL=gpt-4o-mini
EOF
```

Pin the image tag in compose (`ghcr.io/linkwarden/linkwarden:v2.10.0` or whatever the latest release is at <https://github.com/linkwarden/linkwarden/releases>) — upstream default is `:latest`.

```sh
docker compose up -d
```

Browse `https://links.example.com` and register. The **first registered user becomes admin** automatically; subsequent users are regular unless promoted via `NEXT_PUBLIC_ADMIN`.

### Disable public registration

Set `NEXT_PUBLIC_DISABLE_REGISTRATION=true` after the first user registers.

## Data & config layout

- `./pgdata/` on host → `/var/lib/postgresql/data`
- `./data/` on host → `/data/data` — archive files (screenshots, PDFs, single-file HTML). **Can be very large**; plan disk
- `./meili_data/` on host → `/meili_data` — Meilisearch index
- No config files — all env-var driven; full reference: <https://docs.linkwarden.app/self-hosting/environment-variables>

## Backup

```sh
# Database
docker compose exec -T postgres pg_dump -U postgres postgres | gzip > linkwarden-db-$(date +%F).sql.gz

# Archives
tar czf linkwarden-data-$(date +%F).tgz ./data

# Meilisearch index (optional — rebuildable from DB)
tar czf linkwarden-meili-$(date +%F).tgz ./meili_data
```

Back up `.env` (contains `NEXTAUTH_SECRET`, `MEILI_MASTER_KEY`, DB password) separately in your secret store.

## Upgrade

1. Releases: <https://github.com/linkwarden/linkwarden/releases>.
2. Bump image tag in compose.
3. `docker compose pull && docker compose up -d`.
4. The app runs Prisma migrations on start; watch `docker compose logs -f linkwarden`.
5. **Back up Postgres before major versions** — Linkwarden has occasionally had schema migrations that take minutes on large link databases.

## Gotchas

- **Upstream compose is missing `MEILI_MASTER_KEY`.** The `meilisearch` service has `env_file: - .env` but you must actually set `MEILI_MASTER_KEY` in `.env` — otherwise Meilisearch runs with a random key each boot, and Linkwarden can't reach it after restart. Set it explicitly.
- **`NEXTAUTH_URL` must include `/api/v1/auth`.** The most common config mistake — set it to the bare origin and OAuth/SSO callbacks 404.
- **First registered user = admin.** If DNS flips to the server before you're ready, a stranger could claim admin. Set `NEXT_PUBLIC_DISABLE_REGISTRATION=true` immediately after creating your account, or register before pointing DNS.
- **Archive disk usage balloons.** Each link saves a full-page screenshot + PDF + single-file HTML (~1–5 MB per link). 10k links ≈ 20–50 GB.
- **Chromium inside the container** needs ~500 MB RAM per archive job. Multiple concurrent users + `MAX_WORKERS` > 2 can OOM small VMs.
- **Playwright path** defaults to the bundled Chromium. Set `PLAYWRIGHT_LAUNCH_OPTIONS_EXECUTABLE_PATH` or `PLAYWRIGHT_WS_URL` only if you're running an external browser pool.
- **Private-network archiving is disabled by default** for SSRF safety. Set `ALLOW_PRIVATE_NETWORK_ACCESS=true` only if you deliberately want to archive intranet sites and you trust your users.
- **`NEXTAUTH_SECRET` rotation invalidates all sessions and pending invites.** Keep it stable.
- **S3 storage driver** requires the AWS_S3_* vars to all be set; partial config silently falls back to local.
- **Meilisearch 1.x has breaking changes across minor versions.** The upstream compose pins `v1.12.8`; don't bump it independently without reading Meilisearch release notes.
- **SSO users**: `DISABLE_NEW_SSO_USERS=true` prevents SSO from auto-provisioning accounts — pair with manual invite flow for closed deployments.
- **vs Pocket (shut down 2024) / Omnivore (shut down 2024)** — Linkwarden is a viable migration target and has bulk-import paths for both; see docs.
- **Browser extension + native mobile apps** are separate repos under `linkwarden/` org; they talk to the self-hosted server once you point them at your URL.

## Links

- Docs: <https://docs.linkwarden.app/>
- Self-hosting: <https://docs.linkwarden.app/self-hosting/>
- Env var reference: <https://docs.linkwarden.app/self-hosting/environment-variables>
- Compose file: <https://github.com/linkwarden/linkwarden/blob/main/docker-compose.yml>
- Env sample: <https://github.com/linkwarden/linkwarden/blob/main/.env.sample>
- Releases: <https://github.com/linkwarden/linkwarden/releases>
- Browser extension: <https://github.com/linkwarden/browser-extension>
- Mobile apps: <https://github.com/linkwarden/mobile>
