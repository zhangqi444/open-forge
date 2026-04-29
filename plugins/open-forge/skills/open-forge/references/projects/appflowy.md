---
name: appflowy-project
description: AppFlowy recipe for open-forge. AGPL-3.0 open-source alternative to Notion (docs + databases + kanban + AI). Self-host is split across two repos — `AppFlowy-IO/AppFlowy` is the Flutter desktop/mobile/web CLIENT; `AppFlowy-IO/AppFlowy-Cloud` is the Rust SERVER backend (Postgres + Redis + MinIO + GoTrue for auth + nginx + multiple Rust services). Covers the official Docker Compose self-host deploy from AppFlowy-Cloud, the client-install matrix, and the open-core caveat (self-hosted cloud is free for 1 user seat; upgrades are commercial).
---

# AppFlowy

Open-source workspace / Notion alternative. Two codebases:

- **Client** — <https://github.com/AppFlowy-IO/AppFlowy> (Flutter + Rust, desktop/iOS/Android/web). This is the ⭐ 70k-star repo in selfh.st's directory.
- **Server** — <https://github.com/AppFlowy-IO/AppFlowy-Cloud> (Rust). What you actually self-host. Clients connect to it.

**Open-core warning.** AppFlowy-Cloud is open-source but the hosted AppFlowy product adds proprietary services. The free self-host tier includes: **one user seat per instance**, the AppFlowy Web app at `your-domain/app`, up to 3 guest editors, page publishing, unlimited workspaces. Multi-user / team tiers require a commercial license via the closed-source AppFlowy-SelfHost-Commercial fork. Source: the first section of <https://github.com/AppFlowy-IO/AppFlowy-Cloud/blob/main/README.md>. For a single-user setup on your own hardware, the open-source Cloud is enough.

Upstream self-host walkthrough (authoritative, kept current): <https://appflowy.com/docs/Step-by-step-Self-Hosting-Guide---From-Zero-to-Production>.

## Architecture (what `docker compose up` gives you)

The AppFlowy-Cloud `docker-compose.yml` on `main` launches:

| Service | Image | Role |
|---|---|---|
| `nginx` | `nginx` | Reverse proxy / TLS termination; binds `:80` and `:443`. |
| `minio` | `minio/minio` | S3-compatible object storage for user files + attachments. Skip if bringing your own S3. |
| `postgres` | Custom `appflowy-postgres` | Primary DB for AppFlowy Cloud + GoTrue (separate `auth` schema). Uses pgvector + custom extensions. |
| `redis` | `redis` | Cache / pub-sub. |
| `gotrue` | `supabase/gotrue`-derived | Auth server — email/password, magic links, OAuth (Google / GitHub / Discord / Apple). |
| `appflowy_cloud` | `appflowyinc/appflowy_cloud` | Main Rust API server. |
| `admin_frontend` | `appflowyinc/admin_frontend` | Web admin UI (user mgmt, invites). |
| `appflowy_worker` | `appflowyinc/appflowy_worker` | Background worker for imports / exports / emails. |
| `appflowy_search` | `appflowyinc/appflowy_search` | Search indexer (background + keyword index). |
| `appflowy_web` | `appflowyinc/appflowy_web` | Public web app at `/app` (shared/published pages + browser editor). |
| `appflowy_ai` | `appflowyinc/appflowy_ai` *(optional)* | AI features. Requires an OpenAI API key or Azure OpenAI endpoint. |

That's ~10 containers for one single-user deployment. Plan for ≥ 4 GB RAM, ≥ 2 vCPUs, ≥ 20 GB disk.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (AppFlowy-Cloud) | <https://github.com/AppFlowy-IO/AppFlowy-Cloud> + <https://appflowy.com/docs/Step-by-step-Self-Hosting-Guide---From-Zero-to-Production> | ✅ | The only upstream-documented server self-host path. |
| AppFlowy Desktop (local, no server) | <https://github.com/AppFlowy-IO/AppFlowy/releases> | ✅ | Standalone client with **local** storage — works offline, no server needed. Useful for single-device users; no sync across devices. |
| FlatHub / Snapcraft / App Store / Play Store | See client README | ✅ | Client-only distribution channels; connect to either AppFlowy managed cloud OR your self-host. |
| AppFlowy Managed Cloud | <https://app.appflowy.com> | ✅ | Commercial SaaS. Out of scope for open-forge. |
| Commercial self-host (AppFlowy-SelfHost-Commercial) | Private repo, paid license | 💰 | Out of scope — requires purchased license. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Docker + Docker Compose available on the target host?" | `AskUserQuestion`: `Yes` / `No — install Docker first` | Required for Cloud path. |
| preflight | "Are you OK with the one-user-seat limit on free self-host?" | `AskUserQuestion`: `Yes — solo use` / `No — need team` | If no, direct them to the commercial tier; open-forge stops here. |
| dns | "What's the FQDN for AppFlowy?" (e.g. `appflowy.example.com`) | Free-text | Sets `FQDN`, `APPFLOWY_BASE_URL`, `APPFLOWY_WEBSOCKET_BASE_URL`. |
| dns | "HTTPS (recommended) or HTTP (LAN only)?" | `AskUserQuestion`: `HTTPS` / `HTTP` | Sets `SCHEME` + `WS_SCHEME`. HTTPS uses the built-in nginx TLS config. |
| tls | "Path to the TLS cert + key on the host?" | Free-text | Nginx mounts `./nginx/ssl/certificate.crt` + `./nginx/ssl/private_key.key`. Bring your own (Let's Encrypt via certbot, Caddy-provisioned, CA, etc.). |
| auth | "Admin email + password for the initial GoTrue admin account?" | Free-text + prompt for password | Sets `GOTRUE_ADMIN_EMAIL` + `GOTRUE_ADMIN_PASSWORD`. **Change from the defaults.** |
| auth | "JWT secret (random 32+ chars)?" | Generated: `openssl rand -hex 32` | Sets `GOTRUE_JWT_SECRET` — rotating this invalidates all existing sessions. |
| smtp | "Set up SMTP for magic-link login / invites?" | `AskUserQuestion`: `Yes` / `No (use GOTRUE_MAILER_AUTOCONFIRM=true)` | Without SMTP, users are auto-confirmed on signup (fine for private single-user; weaker for multi-user). |
| smtp | *if yes* "SMTP host / port / user / pass / from-address?" | Free-text chain | Sets `GOTRUE_SMTP_*` + mirrored `APPFLOWY_MAILER_SMTP_*`. |
| storage | "Bring your own S3 or use bundled MinIO?" | `AskUserQuestion`: `MinIO` (default) / `AWS S3` / `Other S3-compatible` | Sets `APPFLOWY_S3_USE_MINIO` + related keys. |
| storage | *if own S3* "S3 endpoint / bucket / access-key / secret-key?" | Free-text | Sets `APPFLOWY_S3_*` + disables the `minio` service via Compose override. |
| ai | "Enable AI features? Requires an OpenAI API key or Azure OpenAI." | `AskUserQuestion`: `Yes — OpenAI` / `Yes — Azure OpenAI` / `No` | Optional. Toggles the `appflowy_ai` container + sets `AI_OPENAI_API_KEY` / `AZURE_OPENAI_*`. |

Write every answer to state so resume skips re-prompting.

## Install (official self-host walkthrough)

Based on upstream's `AppFlowy-Cloud/README.md` + the step-by-step guide above. Three major stages: clone → configure `.env` → bring up nginx + services.

```bash
# 1. Install Docker (assumed handled by runtimes/docker.md preflight)

# 2. Clone AppFlowy-Cloud
sudo git clone https://github.com/AppFlowy-IO/AppFlowy-Cloud.git /opt/appflowy-cloud
cd /opt/appflowy-cloud
sudo chown -R "$USER:$USER" .

# 3. Copy the env template — upstream calls it deploy.env (NOT .env.example)
cp deploy.env .env

# 4. Patch the critical fields
#    - FQDN (and SCHEME=https if TLS)
#    - GOTRUE_ADMIN_EMAIL / GOTRUE_ADMIN_PASSWORD (change from 'admin@example.com' / 'password')
#    - GOTRUE_JWT_SECRET (random 32 bytes)
#    - POSTGRES_PASSWORD (random)
#    - AWS_ACCESS_KEY / AWS_SECRET (random for MinIO, or paste real AWS creds)
#    - APPFLOWY_MAILER_SMTP_* + GOTRUE_SMTP_* if using SMTP

JWT_SECRET=$(openssl rand -hex 32)
PG_PASSWORD=$(openssl rand -hex 32)
MINIO_KEY=$(openssl rand -hex 16)
MINIO_SECRET=$(openssl rand -hex 32)

sed -i \
  -e "s|^FQDN=.*|FQDN=${CANONICAL_HOST}|" \
  -e "s|^SCHEME=.*|SCHEME=https|" \
  -e "s|^WS_SCHEME=.*|WS_SCHEME=wss|" \
  -e "s|^GOTRUE_ADMIN_EMAIL=.*|GOTRUE_ADMIN_EMAIL=${ADMIN_EMAIL}|" \
  -e "s|^GOTRUE_ADMIN_PASSWORD=.*|GOTRUE_ADMIN_PASSWORD=${ADMIN_PASSWORD}|" \
  -e "s|^GOTRUE_JWT_SECRET=.*|GOTRUE_JWT_SECRET=${JWT_SECRET}|" \
  -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${PG_PASSWORD}|" \
  -e "s|^AWS_ACCESS_KEY=.*|AWS_ACCESS_KEY=${MINIO_KEY}|" \
  -e "s|^AWS_SECRET=.*|AWS_SECRET=${MINIO_SECRET}|" \
  .env

# 5. TLS cert + key — if using HTTPS, drop them at these paths
mkdir -p nginx/ssl
cp /path/to/fullchain.pem nginx/ssl/certificate.crt
cp /path/to/privkey.pem   nginx/ssl/private_key.key

# 6. Bring up the stack
docker compose up -d

# 7. Watch it come up (takes 1–2 min; postgres + gotrue must be healthy before appflowy_cloud starts)
docker compose ps
docker compose logs -f appflowy_cloud     # wait for "Starting AppFlowy Cloud server"
```

Then open `https://${CANONICAL_HOST}/` in a browser. First user to sign up becomes the workspace owner (guard the URL during the bootstrap window).

### Admin frontend

At `https://${CANONICAL_HOST}/console` — log in with `GOTRUE_ADMIN_EMAIL` / `GOTRUE_ADMIN_PASSWORD` to manage users / invites.

### Pointing the client at your self-host

Install the desktop/mobile client per the client README's install matrix (<https://github.com/AppFlowy-IO/AppFlowy#user-installation>). On first launch, choose **"AppFlowy Cloud"** and enter:

- **Base URL**: `https://${CANONICAL_HOST}`
- **WebSocket URL**: `wss://${CANONICAL_HOST}/ws/v2`
- **GoTrue URL**: `https://${CANONICAL_HOST}/gotrue`

## Config surface

All via `.env`. Key namespaces:

| Namespace | What it controls |
|---|---|
| `POSTGRES_*` | Database credentials + host/port. `POSTGRES_HOST=postgres` = container name on the Compose network. |
| `REDIS_HOST` / `REDIS_PORT` | Redis wiring. |
| `MINIO_*` / `AWS_*` / `APPFLOWY_S3_*` | Object storage. Switch between bundled MinIO and external S3 here. |
| `GOTRUE_*` | Auth — JWT secret, admin creds, SMTP, OAuth providers (Google/GitHub/Discord/Apple — all off by default). |
| `APPFLOWY_MAILER_SMTP_*` | SMTP for AppFlowy's own notification emails (mirrored from `GOTRUE_SMTP_*`). `TLS_KIND` = `none` / `wrapper` (implicit TLS, port 465) / `required` / `opportunistic` (STARTTLS). |
| `AI_OPENAI_API_KEY` / `AZURE_OPENAI_*` | AI features. Omit → AI container starts but features are dormant. |
| `APPFLOWY_SEARCH_*` / `APPFLOWY_INDEXER_*` | Search/indexer sidecar. |
| `RUST_LOG` | Log verbosity across Rust services. Default `info`; raise to `debug` for troubleshooting (noisy). |

Full list: <https://github.com/AppFlowy-IO/AppFlowy-Cloud/blob/main/deploy.env>.

## Upgrade

```bash
cd /opt/appflowy-cloud

# 1. Pull upstream (gets new compose + nginx config + migration scripts)
git pull origin main

# 2. Diff your .env vs deploy.env — new keys may have been added
diff .env deploy.env | grep '^>'   # lines only in deploy.env

# 3. Pull new images
docker compose pull

# 4. Up — Postgres migrations run automatically on appflowy_cloud startup
docker compose up -d

# 5. Check all services healthy
docker compose ps
docker compose logs --tail=100 appflowy_cloud
```

**Always** `pg_dump` before a major upgrade:

```bash
docker compose exec -T postgres pg_dumpall -U postgres | gzip \
  > /opt/appflowy-cloud/backups/appflowy-$(date +%Y%m%d-%H%M%S).sql.gz
```

## Gotchas

- **Two repos, easy to mix up.** Clients come from `AppFlowy-IO/AppFlowy`; server from `AppFlowy-IO/AppFlowy-Cloud`. Self-host docs live with the server repo.
- **Free tier = 1 user seat.** Multi-user needs the commercial fork (`AppFlowy-SelfHost-Commercial`) with a paid license. Set expectations up-front — there's no "just unlock it" flag.
- **Bundled nginx terminates TLS.** The stock compose binds `:80` and `:443` on the host and mounts `nginx/ssl/certificate.crt` + `nginx/ssl/private_key.key`. If you already run Caddy / Traefik on the host, either: (a) remove the `:80`/`:443` publishes from the Compose file and reverse-proxy `appflowy_cloud:8000` + `gotrue:9999` + `admin_frontend:3000` yourself, or (b) disable the bundled nginx service. Upstream's step-by-step guide assumes (a) + the bundled nginx.
- **`POSTGRES_HOST_AUTH_METHOD`** is NOT set to `trust` here (unlike AFFiNE) — `POSTGRES_PASSWORD` is mandatory. Don't leave it as `password`.
- **`GOTRUE_MAILER_AUTOCONFIRM=true` bypasses email verification.** Default in `deploy.env`. Safe for single-user self-host; in multi-user / public setups, set to `false` and configure SMTP — otherwise strangers can sign up with random addresses.
- **WebSockets at `/ws/v2`.** Any upstream proxy (if you replace the bundled nginx) must forward WS with `Upgrade`/`Connection` headers on that path.
- **`AWS_*` vs `MINIO_*` env overlap.** AppFlowy uses `AWS_ACCESS_KEY` + `AWS_SECRET` as the canonical creds even for bundled MinIO (the MinIO container reads them). Don't fork them into separate values.
- **JWT secret rotation = forced global logout.** Changing `GOTRUE_JWT_SECRET` after users exist invalidates every session immediately. Fine for credential rotation; surprising if you didn't know.
- **AI container needs a real key.** `appflowy_ai` container starts even without keys, but any AI feature call 500s. Either supply a key or document that AI is unavailable.
- **No built-in backup.** Postgres, MinIO, and the `keyword_index_data` volume are yours to snapshot. At minimum: `pg_dumpall` + `tar` of the MinIO volume on a cron.
- **Admin panel default creds.** `admin@example.com` / `password` in `deploy.env` — a common forgotten-to-change mistake. Check `GOTRUE_ADMIN_EMAIL` / `GOTRUE_ADMIN_PASSWORD` in your `.env` before `docker compose up -d`.

## Upstream references

- Client (⭐ 70k): <https://github.com/AppFlowy-IO/AppFlowy>
- Server (what you deploy): <https://github.com/AppFlowy-IO/AppFlowy-Cloud>
- Step-by-step self-host guide: <https://appflowy.com/docs/Step-by-step-Self-Hosting-Guide---From-Zero-to-Production>
- Compose + `deploy.env` (source of truth): `docker-compose.yml` + `deploy.env` on `main` in AppFlowy-Cloud
- Self-host pricing / tier docs: <https://appflowy.com/docs/Self-hosted-Plans-and-Pricing>
- Commercial fork license: <https://github.com/AppFlowy-IO/AppFlowy-SelfHost-Commercial/blob/main/SELF_HOST_LICENSE_AGREEMENT.md>

## TODO — verify on first deployment

- Confirm the container list hasn't drifted (new sidecars added? `appflowy_ai` renamed?).
- Verify `GOTRUE_SMTP_*` keys against the latest GoTrue version AppFlowy pins.
- Check whether `deploy.env` has new mandatory keys since this recipe was written (diff during upgrade step).
- Test the client-configuration flow against a live self-host (the "Base URL / WebSocket URL / GoTrue URL" trio may have changed in newer client versions).
