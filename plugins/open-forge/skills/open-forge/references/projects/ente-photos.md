---
name: ente-photos-project
description: Ente Photos recipe for open-forge. AGPL-3.0 end-to-end encrypted cloud photo storage — the self-hostable open-source backend for the Ente Photos mobile/desktop/web apps. Everything is client-side encrypted (libsodium); the server ("Museum") stores only ciphertext + metadata. Positioned explicitly as a private alternative to Google Photos / Apple iCloud Photos / Proton Drive photos. Stack = Museum (Go server) + Postgres 15 + MinIO (S3-compat object storage for blobs). Covers the `quickstart.sh` script (1-minute install), the `server/compose.yaml` dev stack (NOT production-ready), the separate repo `ente-io/ente` (monorepo for all Ente apps), environment variables (ENTE_API_ORIGIN, ENTE_ALBUMS_ORIGIN, MinIO creds, Postgres creds), and the Ente Photos vs Auth distinction (both live in the same monorepo; auth app is free even when photos is paid).
---

# Ente Photos

AGPL-3.0 end-to-end encrypted cloud photo storage — self-hostable backend. Upstream: <https://github.com/ente-io/ente> (monorepo). Docs: <https://ente.com/help/>. Self-hosting docs: <https://ente.com/help/self-hosting>. Website: <https://ente.com>.

Ente Photos is a private, end-to-end encrypted alternative to Google Photos / iCloud Photos / OneDrive Photos. Everything is encrypted on-device (libsodium — XSalsa20 + Poly1305, X25519 ECDH, Argon2id KDF) before upload; the server ("Museum") stores only ciphertext + opaque metadata. Even Ente the company can't see your photos — neither can you after self-hosting.

## Architecture — the 3-container stack

From `server/compose.yaml` (upstream sample, **explicitly labeled "not meant for production use"**):

| Service | Image | Role |
|---|---|---|
| `museum` | built from `server/Dockerfile` | The Ente backend — API on `:8080`, manages user accounts, encrypted blob references, subscriptions. Written in Go. |
| `postgres` | `postgres:15` | User metadata, album structures, encrypted key material, billing |
| `minio` | `minio/minio` | S3-compatible object storage for encrypted photo/video blobs |
| `socat` | `alpine/socat` | Workaround: lets museum resolve `localhost:3200` → minio:3200 (so mobile-client-generated presigned URLs point back to MinIO) |

In production, you'll want Museum + managed Postgres + real S3 (Backblaze B2 / Wasabi / Scaleway / AWS S3 / self-hosted MinIO).

## Client apps (all encrypt before upload)

- **Photos**: iOS, Android, macOS, Windows, Linux, Web. <https://ente.com>
- **Auth** (separate recipe: `ente-auth.md`) — 2FA TOTP app backed by the same encrypted infra.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `quickstart.sh` | <https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh> | ✅ Recommended | 1-minute install. Creates `./my-ente/` + starts containers. |
| Docker Compose from source | <https://github.com/ente-io/ente/tree/main/server/config> | ✅ | Customized / advanced. |
| Manual server (Go binary + BYO Postgres + BYO S3) | <https://ente.com/help/self-hosting/installation/manual> | ✅ | Bare-metal / air-gapped. |
| Ente Cloud (hosted) | <https://ente.com> | Paid | Don't self-host. |

Docker Compose **version 2.30 or higher** is required (per upstream requirements doc). `docker-compose` (v1) is NOT supported — use `docker compose` (v2 plugin).

## What you actually end up with

After `quickstart.sh`:

- Photos web app at <http://localhost:3000> (and `<machine-ip>:3000`)
- Albums / public-share app at <http://localhost:3002>
- Museum API at <http://localhost:8080>
- Museum's data dir at `./my-ente/data/`

Mobile app setup needs a one-time "custom server URL" config → point at your Museum instance.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `quickstart-script` / `compose-from-source` / `manual-binary` | Drives section. |
| preflight | "Docker Compose version?" | Must be ≥ 2.30 | Hard requirement. |
| preflight | "OS?" | `AskUserQuestion`: `linux (recommended)` / `macos (support is poor)` / `windows (not supported)` | Upstream recommends Linux. |
| dns | "Museum (API) URL?" | e.g. `https://ente-api.example.com` | `ENTE_API_ORIGIN` / `NEXT_PUBLIC_ENTE_ENDPOINT`. |
| dns | "Photos web URL?" | e.g. `https://ente.example.com` | `ENTE_PHOTOS_ORIGIN` / `NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT`. |
| dns | "Albums (public share) URL?" | e.g. `https://albums.example.com` | `ENTE_ALBUMS_ORIGIN` / `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT`. |
| secrets | "Generate JWT + encryption keys?" | Auto via `go run tools/gen-random-keys/main.go` | Required for long-term use. |
| db | "Postgres creds?" | `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Quickstart generates random. Compose-from-source defaults: `pguser`/`pgpass`/`ente_db`. |
| storage | "Object storage backend?" | `AskUserQuestion`: `minio (self-hosted, included)` / `b2 (Backblaze)` / `wasabi` / `scaleway` / `aws-s3` / `r2` | Edit `museum.yaml` for non-MinIO. |
| storage | "MinIO creds?" | `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | Default samples are `changeme`/`changeme1234` — MUST change. |
| smtp | "SMTP for account verification?" | Multi-field | Required for account creation (OTP email). |
| resources | "RAM / CPU?" | Min 1 GB RAM + 1 CPU | Per upstream requirements. Scales with user count + photo count. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none-for-localhost` | For public access, mandatory. |

## Install — `quickstart.sh` (1-minute)

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

What it does:

1. Creates `./my-ente/` in current working dir.
2. Generates random Postgres + MinIO credentials.
3. Writes a `compose.yaml` + config files.
4. Prompts before `docker compose up`.
5. After up: Photos web at <http://localhost:3000>, Albums at <http://localhost:3002>.

Data ends up in `./my-ente/data/`.

## Install — Docker Compose from source (customizable)

```bash
git clone https://github.com/ente-io/ente.git
cd ente/server/config
cp example.env .env
cp example.yaml museum.yaml

# Generate JWT + email-encryption keys
cd ../                  # into ente/server
go run tools/gen-random-keys/main.go
# Copy output into museum.yaml + .env appropriately

cd config
docker compose up --build
```

Edit `.env` for Postgres/MinIO creds. Edit `museum.yaml` for:

- `db.*` — Postgres connection
- `s3.*` — Object storage config (replace MinIO defaults with your real B2/Wasabi/Scaleway/S3 creds if not using MinIO)
- `jwt.secret`, `key.encryption`, `key.hash` — generated secrets
- `email-mta.*` — SMTP
- `webauthn.rpid` / `webauthn.rporigins` — if using passkey auth

The sample `server/compose.yaml` (verbatim — from upstream, prod-disclaimer):

```yaml
# Sample docker compose file, not meant for production use.
services:
  museum:
    build:
      context: .
      args:
        GIT_COMMIT: development-cluster
    ports:
      - 8080:8080           # API
    depends_on:
      postgres: { condition: service_healthy }
    environment:
      ENTE_CREDENTIALS_FILE: /credentials.yaml
    configs:
      - source: credentials_yaml
        target: /credentials.yaml
    volumes:
      - ./museum.yaml:/museum.yaml:ro
      - ./data:/data:ro

  socat:
    image: alpine/socat
    network_mode: service:museum
    depends_on: [museum]
    command: "TCP-LISTEN:3200,fork,reuseaddr TCP:minio:3200"

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: pguser
      POSTGRES_PASSWORD: pgpass
      POSTGRES_DB: ente_db
    healthcheck:
      test: pg_isready -q -d ente_db -U pguser
      start_period: 40s
      start_interval: 1s
    volumes:
      - postgres-data:/var/lib/postgresql/data

  minio:
    image: minio/minio
    ports:
      - 3200:3200           # MinIO API
    environment:
      MINIO_ROOT_USER: changeme
      MINIO_ROOT_PASSWORD: changeme1234
    command: server /data --address ":3200" --console-address ":3201"
    volumes:
      - minio-data:/data
    # post_start creates the required buckets (b2-eu-cen, wasabi-eu-central-2-v3, scw-eu-fr-v3)

volumes:
  postgres-data:
  minio-data:
```

Note the **3 hardcoded bucket names** (`b2-eu-cen`, `wasabi-eu-central-2-v3`, `scw-eu-fr-v3`) — Ente's client code references these. If you use a different S3 backend, name your buckets the same OR edit `museum.yaml` to alias them.

## Port / URL mapping

Per upstream docs (`env-var.md`):

| Service | Host port | Purpose |
|---|---|---|
| Museum | 8080 | API |
| Ente Photos | 3000 | Main photo app (web) |
| Ente Accounts | 3001 | Account-management UI |
| Ente Albums | 3002 | Public-share album viewer |
| Ente Auth | 3003 | 2FA app (see `ente-auth.md`) |
| Ente Cast | 3004 | TV-cast app |
| Ente Public Locker | 3005 | Public file share |
| Ente Embed | 3006 | Embed viewer |
| Ente Paste | 3008 | Paste tool |
| MinIO | 3200 | S3 API |
| PostgreSQL | 5432 (internal) | DB |

Quickstart only exposes 3000 + 3002 externally.

## Reverse proxy (Caddy example)

```caddy
ente.example.com     { reverse_proxy museum:3000 }
albums.example.com   { reverse_proxy museum:3002 }
ente-api.example.com { reverse_proxy museum:8080 }
```

Set matching `ENTE_API_ORIGIN` / `ENTE_PHOTOS_ORIGIN` / `ENTE_ALBUMS_ORIGIN` env vars.

## Connecting client apps

- **Mobile (iOS / Android)**: long-press "Sign in" button on the landing screen → enter custom server URL (`https://ente-api.example.com`).
- **Desktop (Electron)**: Settings → Advanced → Custom server URL.
- **Web**: Already points at your self-hosted instance if you hosted the photos web app alongside.

Upstream guide: <https://ente.com/help/self-hosting/installation/post-install>.

## Data layout

| Path / volume | Content |
|---|---|
| `postgres-data:/var/lib/postgresql/data` | User accounts, album structures, encrypted keys, billing metadata |
| `minio-data:/data` | Encrypted photo/video blobs + thumbnails (ciphertext) |
| `./data:/data:ro` | Museum's read-only data dir — push-notification credentials, other config |
| `./museum.yaml:/museum.yaml:ro` | Main config |

**Backup priority:**

1. **Postgres** (`pg_dump`) — account data, key material, album structure. Without it, blobs in MinIO are unreachable.
2. **MinIO `/data`** — the actual encrypted content. Huge.
3. **`museum.yaml`** with JWT + encryption keys. Losing these = all accounts unusable.
4. Clients hold copies of photos too (not a backup strategy, but helpful).

**For production**, move blob storage off MinIO to S3 / B2 / Wasabi with versioning + cross-region replication. MinIO is fine for home labs.

## Upgrade procedure

```bash
git -C ente pull
cd ente/server/config
docker compose up --build -d
docker compose logs -f museum
```

Museum runs DB migrations automatically.

Release notes: <https://github.com/ente-io/ente/releases>.

## Gotchas

- **Default `MINIO_ROOT_USER=changeme` / `MINIO_ROOT_PASSWORD=changeme1234`** in upstream compose. CHANGE BEFORE going public.
- **Compose file is labeled "not meant for production use"** by upstream. For real deploys, externalize Postgres + S3 + add TLS + sane secrets.
- **3 hardcoded bucket names** (`b2-eu-cen`, `wasabi-eu-central-2-v3`, `scw-eu-fr-v3`) — these names are referenced in client presigned URL generation. Don't rename buckets without editing `museum.yaml` accordingly.
- **Docker Compose v2.30+ required.** Quickstart fails on older versions. Check: `docker compose version`.
- **Linux strongly recommended.** macOS + Windows Docker has poor compat with Ente's compose setup per upstream.
- **End-to-end encryption means server-side recovery is IMPOSSIBLE.** If a user forgets their password AND their recovery key, their data is permanently unrecoverable. By design. No amount of admin access helps.
- **Recovery key generation**: each user gets a 24-word mnemonic on signup. They MUST save it. Without it + password, account is dead.
- **JWT + email-encryption keys must be stable.** Rotating them invalidates all sessions + email tokens. Back them up.
- **SMTP is required for signup** — Ente sends an OTP email. Without SMTP configured, no one can create accounts.
- **Billing / subscriptions** in the OSS Museum are not fully wired up — self-hosted Ente is typically ungated. Enforce storage quotas at the filesystem level if needed.
- **Storage quotas default unbounded.** Set limits in `museum.yaml` (per-user) if you run a multi-user instance.
- **Mobile app custom server URL**: long-press "Sign in" on the splash screen. Easy to miss — not a visible setting.
- **Public albums** require the albums app running (`ente-albums` on :3002). If you disable it, public-share links break.
- **Post-install setup** is non-trivial: <https://ente.com/help/self-hosting/installation/post-install> covers enabling custom endpoints in clients, SMTP testing, etc.
- **The auth app (Ente Auth)** runs alongside and shares Museum + DB. See separate recipe.
- **Upstream is a large monorepo** (~GB of Git history) — cloning takes a while. Use `--depth 1` for speed.
- **Full-text search on photo content (faces, objects, EXIF)** happens ON-DEVICE (ML models shipped to the client) — server can't see. Expect higher client storage + battery use.
- **Ente Cloud (paid hosted) subsidizes OSS development.** Self-hosting is fully supported but niche; most improvements track the hosted product.
- **Scalability**: designed to run on 1 GB RAM + 1 CPU for small installs. At 100s of users + TBs of photos, expect ops work (scaling Museum replicas, moving blob storage to real S3, CDN for MinIO).
- **iCloud / Google Photos import** is client-side via the mobile/desktop apps — not a server-side bulk importer.
- **Key rotation** for individual users (change password) is supported. Bulk rotation (instance-wide) is not a thing — would require re-encrypting every blob with new keys.
- **Mobile push notifications** require push credentials in `./data/` — optional.
- **Monorepo for all Ente apps**: Photos + Auth + Locker + Cast + etc. all live in `github.com/ente-io/ente`. The backend Museum serves all of them.

## Links

- Upstream repo (monorepo): <https://github.com/ente-io/ente>
- Self-hosting docs: <https://ente.com/help/self-hosting>
- Quickstart: <https://ente.com/help/self-hosting/installation/quickstart>
- Compose from source: <https://ente.com/help/self-hosting/installation/compose>
- Manual install: <https://ente.com/help/self-hosting/installation/manual>
- Environment variables: <https://ente.com/help/self-hosting/installation/env-var>
- Requirements: <https://ente.com/help/self-hosting/installation/requirements>
- Post-install: <https://ente.com/help/self-hosting/installation/post-install>
- Upgrade: <https://ente.com/help/self-hosting/installation/upgrade>
- Quickstart script: <https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh>
- Museum (server) source: <https://github.com/ente-io/ente/tree/main/server>
- Releases: <https://github.com/ente-io/ente/releases>
- Hosted service: <https://ente.com>
- Privacy + crypto whitepaper: <https://ente.com/architecture>
- Discord: <https://ente.com/discord>
- Mobile apps: iOS / Android / macOS / Windows / Linux / web (see ente.com)
- Related — Ente Auth (same backend): see `ente-auth.md`
