---
name: joplin-project
description: Joplin recipe for open-forge. AGPL-3.0 open-source note-taking + to-do app. Primarily a client-side app (desktop/mobile/terminal) that syncs notes between devices. The "self-host" question is specifically about Joplin Server — the upstream-blessed sync backend. Covers Joplin Server via Docker Compose (upstream-maintained `joplin/server` image + Postgres) and the three alternative sync backends that don't require self-hosting anything (Dropbox / OneDrive / Nextcloud WebDAV). Also lists the client install matrix for completeness.
---

# Joplin

AGPL-3.0 cross-platform note-taking + to-do app. End-to-end Markdown notes synced across desktop (Win/Mac/Linux), mobile (iOS/Android), terminal, and web-clipper browser extension. Upstream: <https://github.com/laurent22/joplin>. Docs: <https://joplinapp.org/help/>.

**What self-hosting means here.** The Joplin clients are not themselves servers — they just store notes locally and sync to a backend. Self-hosting Joplin = running **Joplin Server**, a Node.js + Postgres service that provides E2E-encrypted sync + sharing between your clients. The other sync targets (Dropbox, OneDrive, Nextcloud WebDAV, S3-compatible) don't require anything to self-host — you just configure the client to use them.

## Two different "self-host" framings

| Intent | What you deploy |
|---|---|
| "I want my notes in my own cloud, no extra infra" | Use Nextcloud/WebDAV sync (point Joplin at an existing Nextcloud) — no Joplin-specific server. |
| "I want multi-user sharing and don't trust third-party sync" | **Joplin Server** (this recipe's focus). Postgres + `joplin/server` Docker image. |
| "I want a web-based Joplin with no client install" | Not officially supported. Joplin clients are desktop/mobile-native. |

## Joplin Server — Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`joplin/server` + Postgres) | <https://joplinapp.org/help/install/server_docker> · `docker-compose.server.yml` in the repo | ✅ Recommended | The only upstream-blessed self-host path for the sync server. |
| Docker Run (no compose) | Same image, standalone | ✅ | Quick test. |
| Plain Node.js + Postgres | <https://joplinapp.org/help/install/server_setup> | ✅ | Bare-metal deploy without Docker. |
| Managed (Joplin Cloud) | <https://joplinapp.org/plans/> | ✅ paid | Upstream's paid service — not self-host. |

## Joplin Server — Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| dns | "Public domain for Joplin Server?" | Free-text (e.g. `joplin.example.com`) | Server needs a stable `APP_BASE_URL`. |
| url | "Expose at root `/` or under a path `/joplin`?" | `AskUserQuestion` | Affects `APP_BASE_URL`. `https://example.com/joplin` vs `https://joplin.example.com`. |
| port | "Internal HTTP port?" | Default `22300` | Usually proxied behind port 443. |
| db | "Postgres user/password/db?" | Free-text (sensitive) | Passed as `POSTGRES_*` env vars. Server also supports SQLite but Postgres is upstream-recommended for production. |
| admin | "Default admin email + password?" | Free-text (sensitive) | First login uses these; change immediately. Defaults are `admin@localhost` / `admin` — DO NOT leave them. |
| mailer | "SMTP config?" | Free-text (sensitive) | Optional, but required for email confirmations + password resets + sharing invites. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik)" | `AskUserQuestion` | Joplin Server does not terminate TLS; always use a reverse proxy for HTTPS. |

## Install — Docker Compose (upstream recipe)

Based on `docker-compose.server.yml` on the `dev` branch:

```yaml
# compose.yaml
services:
  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DATABASE}
    volumes:
      - ./data/postgres:/var/lib/postgresql/data

  app:
    image: joplin/server:latest   # consider pinning a specific tag
    depends_on:
      - db
    restart: unless-stopped
    ports:
      - "22300:22300"
    environment:
      APP_PORT: 22300
      APP_BASE_URL: ${APP_BASE_URL}    # e.g. https://joplin.example.com
      DB_CLIENT: pg
      POSTGRES_HOST: db
      POSTGRES_PORT: 5432
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DATABASE: ${POSTGRES_DATABASE}
      # Optional — email
      MAILER_ENABLED: "1"
      MAILER_HOST: smtp.example.com
      MAILER_PORT: 587
      MAILER_SECURE: "1"
      MAILER_AUTH_USER: you@example.com
      MAILER_AUTH_PASSWORD: ${SMTP_PASSWORD}
      MAILER_NOREPLY_NAME: "Joplin Server"
      MAILER_NOREPLY_EMAIL: noreply@example.com
```

```bash
# .env
cat > .env <<'EOF'
POSTGRES_USER=joplin
POSTGRES_PASSWORD=<strong-random>
POSTGRES_DATABASE=joplin
APP_BASE_URL=https://joplin.example.com
SMTP_PASSWORD=<smtp-secret>
EOF

docker compose up -d
docker compose logs -f app
# First boot runs migrations. Server comes up on :22300.
```

### Reverse proxy (Caddy example)

```caddy
joplin.example.com {
    reverse_proxy 127.0.0.1:22300
}
```

For nginx, use the canonical `/` block with `proxy_pass http://127.0.0.1:22300;` plus websocket + forwarded headers.

## First-run bootstrap

1. Visit `https://joplin.example.com/login`.
2. Log in as `admin@localhost` / `admin`.
3. **Go to Profile → change email + password IMMEDIATELY.** The defaults are public knowledge.
4. Users tab → disable new user registration if you don't want self-signup: set `SIGNUP_ENABLED=0`. Invite users manually via the admin UI.

## Configuring Joplin clients to use your server

In any Joplin client: **Tools → Options → Synchronisation**:

| Field | Value |
|---|---|
| Synchronisation target | `Joplin Server (Beta)` |
| Joplin Server URL | `https://joplin.example.com` |
| Joplin Server email | `user@example.com` |
| Joplin Server password | `<set-in-admin-ui>` |

Hit "Check synchronisation configuration" to validate, then `Synchronise` from the main window. First sync on a client with existing notes uploads them all — can take hours for large notebooks.

### End-to-end encryption (E2EE)

E2EE is a **client-side** feature, independent of sync target. Enable via Tools → Options → Encryption → Enable encryption. The server stores only encrypted blobs; the key lives on clients. Joplin Server supports E2EE transparently — the server never sees plaintext.

## Client install matrix (reference — not deployed by this recipe)

From upstream README:

| Platform | Install |
|---|---|
| Desktop (Win/macOS/Linux) | `.exe` / `.dmg` / `.AppImage` / `Joplin_install_and_update.sh` from <https://joplinapp.org/download/> |
| Mobile | iOS App Store / Google Play (<https://joplinapp.org/download/>) |
| Terminal | `npm install -g joplin` (Node 10+ required; upstream-supported path) |
| Web Clipper | Firefox / Chrome extensions — pairs with desktop client |

## Data layout

| Path (Docker) | Content |
|---|---|
| `./data/postgres/` | Postgres data (notes metadata, users, sharing). |
| Object storage for blobs | By default attached files go in Postgres as bytea. For large notebooks, configure S3-compatible via `STORAGE_DRIVER=s3` + `STORAGE_DRIVER_S3_*` env vars. |

**Backup = pg_dump + data directory:**

```bash
docker compose exec db pg_dump -U joplin joplin > joplin-backup-$(date +%F).sql
```

## Upgrade procedure

```bash
# Read release notes first: https://github.com/laurent22/joplin/releases
cd /path/to/joplin-server
docker compose pull app
docker compose up -d app
docker compose logs -f app
# Migrations run automatically on first boot of the new image.
```

**Server + client version skew.** Upstream recommends keeping server ≥ latest client major. Clients older than the server keep working (backward compatible), but clients newer than the server may complain.

## Gotchas

- **Default admin credentials are `admin@localhost` / `admin`.** Public knowledge; change on first login or via `ADMIN_EMAIL` / `ADMIN_PASSWORD` env vars at first boot.
- **`APP_BASE_URL` must match what clients see.** Setting it to `http://localhost:22300` on a VPS means clients think the server lives at localhost and sync breaks. Use the canonical public URL, always with `https://` in production.
- **Postgres port `5432:5432` in the example compose is EXPOSED TO THE HOST.** In the upstream `docker-compose.server.yml` it's there for debugging. For production, remove the `ports:` mapping — Postgres only needs to be reachable on the internal network.
- **Joplin Server is labeled "Beta."** It has been production-ready for thousands of Joplin Cloud users for years, but upstream still carries the beta label in some places. Versioning is coupled to the main Joplin release.
- **Attachments can bloat Postgres.** Default storage driver is Postgres bytea — notes with lots of images/PDFs balloon the DB. Configure S3-compatible object storage via `STORAGE_DRIVER_TYPE=s3` for any serious use.
- **E2EE is per-client, not per-server.** The server stores encrypted blobs either way. Losing the encryption key means losing access to encrypted notes — there's no recovery path. Write down the master key somewhere durable.
- **WebDAV sync is NOT Joplin Server.** If the user already has Nextcloud they may prefer WebDAV sync — simpler, no extra infra, but no multi-user sharing features.
- **Sharing + multi-user = Joplin Server only.** Dropbox / OneDrive / WebDAV sync don't support Joplin's notebook-sharing feature.
- **Sync conflicts on first run.** A fresh client syncing to an existing server with notes: the client downloads everything first, THEN uploads local diffs. If the client already had notes locally, you may get "conflict" notes — check the Conflicts notebook after first sync.
- **Websockets not required but recommended.** Some realtime features work better with websocket passthrough at the reverse proxy. Default Caddy reverse_proxy handles this; nginx needs `proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";`.

## Links

- Upstream repo: <https://github.com/laurent22/joplin>
- Docs: <https://joplinapp.org/help/>
- Server install: <https://joplinapp.org/help/install/server_setup>
- Server + Docker: <https://joplinapp.org/help/install/server_docker>
- Admin dashboard docs: <https://joplinapp.org/help/install/server_admin_dashboard>
- Releases: <https://github.com/laurent22/joplin/releases>
- Docker image: <https://hub.docker.com/r/joplin/server>
- Joplin Cloud (paid): <https://joplinapp.org/plans/>
- Forum: <https://discourse.joplinapp.org/>
