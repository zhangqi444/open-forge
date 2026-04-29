---
name: supabase-project
description: Supabase recipe for open-forge. Open-source Firebase alternative built on Postgres. Covers the official docker-compose self-host (13-service stack — Studio, Kong, Auth, PostgREST, Realtime, Storage, imgproxy, postgres-meta, Postgres, Edge Runtime, Logflare, Vector, Supavisor) and the mandatory pre-prod secret rotation.
---

# Supabase (open-source Firebase alternative)

Apache-2.0 licensed Postgres-based development platform — Auth, REST/GraphQL auto-APIs, Realtime subscriptions, Storage, Edge Functions, and a dashboard. Self-hosted via a 13-service Docker Compose stack.

**Upstream README:** https://github.com/supabase/supabase/blob/master/README.md
**Self-host README:** https://github.com/supabase/supabase/blob/master/docker/README.md
**Docs (self-hosting):** https://supabase.com/docs/guides/self-hosting/docker
**Docker dir (source of truth):** https://github.com/supabase/supabase/tree/master/docker

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker Compose | ✅ default | `docker compose up -d` from the repo's `docker/` dir |
| byo-vps | Docker Compose | ✅ | Recommended — 13 services, needs ~4-8 GB RAM |
| aws/ec2 | Docker Compose | ✅ | `t3.medium` minimum; `t3.large` realistic |
| hetzner/cloud-cx | Docker Compose | ✅ | CX22 minimum; CX32+ recommended |
| digitalocean/droplet | Docker Compose | ✅ | 4 GB droplet minimum |
| gcp/compute-engine | Docker Compose | ✅ | `e2-standard-2` minimum |
| kubernetes | community Helm | ⚠️ | `supabase-community/supabase-kubernetes` — **community-maintained** |

**Note:** upstream ships variant compose files in `docker/`: `docker-compose.caddy.yml`, `docker-compose.nginx.yml`, `docker-compose.envoy.yml` (alternative reverse proxies); `docker-compose.s3.yml` (S3 storage backend); `docker-compose.pg17.yml` (Postgres 17 instead of default 15). These are overlays — `docker compose -f docker-compose.yml -f docker-compose.s3.yml up -d`.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Supabase on?" | Free-text | e.g. `supabase.example.com` — used for Kong + Studio |
| tls | "Email for Let's Encrypt notices?" | Free-text | If fronting with Caddy/Traefik |
| secrets | "Generate all secrets now? (Postgres password, JWT secret, JWT keys, anon/service keys, dashboard password, Logflare tokens, Vault key, S3 keys, SECRET_KEY_BASE)" | Confirm | Run `sh ./utils/generate-keys.sh` — upstream ships a helper |
| secrets | "Dashboard username/password?" | Free-text (sensitive) | Default `supabase` / `this_password_is_insecure_and_should_be_updated` — **MUST change** |
| storage | "Storage backend: filesystem (default) or S3?" | AskUserQuestion: filesystem / S3 | S3 requires overlay compose + access keys |
| db | "Postgres version: 15 (default) or 17?" | AskUserQuestion: 15 / 17 | PG17 is an overlay file |

## Install method — Docker Compose (upstream canonical)

Source: https://supabase.com/docs/guides/self-hosting/docker

```bash
# 1. Clone
git clone --depth 1 https://github.com/supabase/supabase
cd supabase/docker

# 2. Copy env template and edit
cp .env.example .env

# 3. Generate strong secrets (upstream helper)
sh ./utils/generate-keys.sh   # rotates JWT, keys, etc.

# 4. Manually update these in .env before `up` (security-critical):
#    POSTGRES_PASSWORD, JWT_SECRET, ANON_KEY, SERVICE_ROLE_KEY,
#    SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY, JWT_KEYS, JWT_JWKS,
#    DASHBOARD_USERNAME, DASHBOARD_PASSWORD, SECRET_KEY_BASE, VAULT_ENC_KEY,
#    PG_META_CRYPTO_KEY, LOGFLARE_PUBLIC_ACCESS_TOKEN,
#    LOGFLARE_PRIVATE_ACCESS_TOKEN, S3_PROTOCOL_ACCESS_KEY_ID,
#    S3_PROTOCOL_ACCESS_KEY_SECRET, SUPABASE_PUBLIC_URL, API_EXTERNAL_URL

# 5. Pull and start
docker compose pull
docker compose up -d
```

Studio lands at `http://localhost:8000` (or whatever `SUPABASE_PUBLIC_URL` is set to). The API gateway (Kong) is the public entry point.

### Alternative overlay: S3 storage

```bash
docker compose -f docker-compose.yml -f docker-compose.s3.yml up -d
```

Requires `STORAGE_S3_*` vars in `.env`.

### Alternative overlay: Postgres 17

```bash
docker compose -f docker-compose.yml -f docker-compose.pg17.yml up -d
```

## Software-layer concerns

### Service inventory

From `docker/docker-compose.yml`:

| Service | Purpose | Upstream repo |
|---|---|---|
| `studio` | Dashboard UI | supabase/supabase/tree/master/apps/studio |
| `kong` | API gateway | Kong/kong |
| `auth` | Auth (JWT) | supabase/auth |
| `rest` | PostgREST | PostgREST/postgrest |
| `realtime` | Realtime WS subscriptions (Elixir) | supabase/realtime |
| `storage` | File storage REST API | supabase/storage |
| `imgproxy` | Image transforms | imgproxy/imgproxy |
| `meta` | postgres-meta (schema browser) | supabase/postgres-meta |
| `db` | Postgres + extensions (pgvector, pg_graphql, supabase_vault, pgsodium) | supabase/postgres |
| `functions` | Edge Runtime (Deno) | supabase/edge-runtime |
| `analytics` | Logflare | Logflare/logflare |
| `vector` | Vector log shipper | vectordotdev/vector |
| `supavisor` | Postgres connection pooler | supabase/supavisor |

### Required env vars (non-exhaustive)

See `docker/.env.example` for the full list. Critical ones:

| Var | Purpose | Default (INSECURE) |
|---|---|---|
| `POSTGRES_PASSWORD` | DB superuser password | `your-super-secret-and-long-postgres-password` |
| `JWT_SECRET` | Legacy symmetric HS256 key (>= 32 chars) | placeholder |
| `ANON_KEY`, `SERVICE_ROLE_KEY` | Signed JWTs; regenerate with `utils/generate-keys.sh` | demo JWTs |
| `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY` | New opaque API keys (ES256 asymmetric) | empty |
| `JWT_KEYS`, `JWT_JWKS` | EC private + public JWK sets | empty |
| `DASHBOARD_USERNAME`, `DASHBOARD_PASSWORD` | Studio basic-auth | `supabase` / insecure default |
| `SECRET_KEY_BASE` | Realtime + Supavisor cookie key | placeholder |
| `VAULT_ENC_KEY` | Vault encryption (32 chars) | placeholder |
| `PG_META_CRYPTO_KEY` | postgres-meta encryption (32 chars) | placeholder |
| `LOGFLARE_PUBLIC_ACCESS_TOKEN`, `LOGFLARE_PRIVATE_ACCESS_TOKEN` | Analytics tokens | placeholders |
| `S3_PROTOCOL_ACCESS_KEY_ID`, `S3_PROTOCOL_ACCESS_KEY_SECRET` | Storage S3-compatible access | placeholders |
| `SUPABASE_PUBLIC_URL` | Public URL for Studio + Kong | `http://localhost:8000` |
| `API_EXTERNAL_URL` | Auth OAuth callbacks, email links | `http://localhost:8000` |
| `SITE_URL` | Post-signin redirect | |
| `ADDITIONAL_REDIRECT_URLS` | Other allowed post-auth redirects | |
| `SMTP_*` | Auth transactional email | empty (Auth works but can't send emails) |

### Ports (from compose)

- `8000` — Kong (public API gateway — all client traffic goes here)
- `5432` — Postgres (direct DB access — should be firewalled)
- `6543` — Supavisor (pooled DB connections)
- Studio lives behind Kong at `/`; REST at `/rest/v1/`; Auth at `/auth/v1/`; Realtime at `/realtime/v1/`; Storage at `/storage/v1/`; Functions at `/functions/v1/`.

### Reverse proxy

Point one public domain at Kong on `:8000`:

```caddy
supabase.example.com {
  reverse_proxy 127.0.0.1:8000
}
```

Then update `SUPABASE_PUBLIC_URL=https://supabase.example.com` and `API_EXTERNAL_URL=https://supabase.example.com` in `.env` and `docker compose up -d` to propagate.

Upstream ships `docker-compose.caddy.yml` that wires Caddy directly — alternative to managing the proxy separately.

### Data directories

Volumes (declared in compose):
- `db-data` — Postgres data dir (`/var/lib/postgresql/data`)
- `storage-data` — file storage (unless using S3 overlay)
- `functions-data` — Edge Functions
- `db-config` — Postgres config

Back up `db-data` + `storage-data` at minimum. Postgres `pg_dump` via Supavisor works; cold volume snapshots work when services are stopped.

## Upgrade procedure

From `docker/README.md`:

1. Review `docker/CHANGELOG.md` for breaking changes.
2. Check `docker/versions.md` for new image versions (rollback reference).
3. Update `docker-compose.yml` if configuration shape changed.
4. `docker compose pull`
5. `docker compose down` (wait for clean shutdown — Postgres especially)
6. **Back up the database first** (`pg_dump` or cold volume snapshot).
7. `docker compose up -d`
8. Watch logs: `docker compose logs -f db` until migrations settle.

Upstream explicitly recommends pulling new `docker-compose.yml` from the repo each upgrade — they iterate on service wiring.

## Gotchas

- **Default secrets are dangerous.** The shipped `.env.example` ANON_KEY/SERVICE_ROLE_KEY are world-known demo JWTs. Anyone who finds your instance with the defaults can bypass RLS. **First action on install: `sh ./utils/generate-keys.sh`** and edit every placeholder in `.env`.
- **Many secrets must be exactly 32 chars.** `VAULT_ENC_KEY`, `PG_META_CRYPTO_KEY` — don't use `openssl rand -hex 16` (32 hex chars works; truly-32 of random bytes base64 also works). Check the comment above each var.
- **`SUPABASE_PUBLIC_URL` + `API_EXTERNAL_URL` must match what clients call.** If your reverse proxy terminates TLS at `https://supabase.example.com`, set both there. Mismatch breaks OAuth callbacks + password-reset email links + realtime.
- **13 services = real RAM.** Cold boot needs ~2 GB; steady-state 3–4 GB. `t3.small` or CX11 is not enough.
- **Don't expose Postgres directly (`:5432`).** Default compose binds to all interfaces. Either firewall externally or edit the compose to bind `127.0.0.1:5432`.
- **Logflare analytics service is heavy.** On resource-constrained hosts, consider disabling — comment out `analytics` and `vector` services, and remove the `depends_on: analytics` lines (Studio will show warnings but core functionality works).
- **Self-hosted Edge Functions need a different deploy path.** `supabase functions deploy` (CLI) targets the hosted platform; for self-host, drop `.ts` files into the `functions` volume + restart the service.
- **Pulling `:latest` is risky.** Pin image tags per `docker/versions.md` for prod. Breaking changes have happened mid-minor (service shape, env-var renames).
- **`DASHBOARD_PASSWORD` default is literally `this_password_is_insecure_and_should_be_updated`.** The `.env.example` shouts this but the string makes it into production-looking installs surprisingly often.

## TODO — verify on subsequent deployments

- [ ] Run `utils/generate-keys.sh` end-to-end and verify every JWT/opaque-key works with the Studio login.
- [ ] Test `docker-compose.caddy.yml` vs standalone Caddy for TLS termination.
- [ ] Confirm the `supabase-community/supabase-kubernetes` Helm chart is most-active for k8s paths.
- [ ] Resource sizing: actual RAM/CPU footprint at idle vs light use.
- [ ] SMTP wiring — point to Resend/SendGrid/Mailgun via `SMTP_*` vars; verify magic-link email delivery.
- [ ] Upgrade rehearsal: take a v15 stack → v15 newer-minor → v17 overlay.
