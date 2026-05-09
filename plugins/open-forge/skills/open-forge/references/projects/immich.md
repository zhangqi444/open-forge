---
name: immich-project
description: Immich recipe for open-forge. High-performance self-hosted photo/video management (AGPL). Covers the official 4-service Docker Compose (server, machine-learning, redis/valkey, postgres w/ pgvector), optional hardware-accelerated transcoding and ML inference, and the canonical release-pinned compose file pattern.
---

# Immich (self-hosted photos + videos)

AGPL-3.0 self-hosted photo and video management. Mobile apps (iOS/Android) back up to a server you run; web UI for browsing, albums, sharing, face recognition, CLIP search.

**Upstream README:** https://github.com/immich-app/immich/blob/main/README.md
**Docs:** https://immich.app / https://docs.immich.app
**Installation:** https://docs.immich.app/install/docker-compose
**Compose file (pinned release):** https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml

> [!WARNING]
> Follow a 3-2-1 backup plan. Immich is primary storage for many users, but first-party backup tooling is limited — volume-level backups of `UPLOAD_LOCATION` and the Postgres database are your responsibility.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker Compose | ✅ default | Recommended path per upstream |
| byo-vps | Docker Compose | ✅ | Raise upload size limits at the reverse proxy |
| raspberry-pi | Docker Compose (arm64) | ✅ | Works on Pi 4+ 8GB; ML may be slow without GPU |
| aws/ec2 | Docker Compose | ✅ | GPU instance (g4dn) for faster ML if desired |
| hetzner/cloud-cx | Docker Compose | ✅ | CCX for CPU-heavy ML |
| digitalocean/droplet | Docker Compose | ✅ | |
| gcp/compute-engine | Docker Compose | ✅ | |
| kubernetes | community Helm | ⚠️ | `immich-app/immich-charts` is official-ish (lives in the immich-app org). Still flagged as "verify at pull time" because of the AGPL + velocity of upstream. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Immich on?" | Free-text | e.g. `photos.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| storage | "Where should uploaded photos live? (host path)" | Free-text | `UPLOAD_LOCATION` — large dir, plan for growth. Network shares OK for media, NOT for the DB. |
| storage | "Where should the Postgres data dir live? (host path)" | Free-text | `DB_DATA_LOCATION` — local disk only, not NFS/SMB. |
| secrets | "Generate a strong Postgres password?" | Confirm | `DB_PASSWORD` — a-z, A-Z, 0-9 only (no special chars) |
| version | "Pin to a specific release (e.g. `v2.7.5`) or track `v2`?" | AskUserQuestion: pinned / major-latest | `v2` = latest 2.x; pinning specific versions recommended for production. |
| hwaccel | "Use hardware acceleration for ML inference?" | AskUserQuestion: No / CUDA / OpenVINO / ROCm / ARM-NN / RKNN | Only if you have the hardware. |
| hwaccel | "Use hardware acceleration for video transcoding?" | AskUserQuestion: No / NVENC / QuickSync / VAAPI / RKMPP | |
| smtp | "Outbound email for password reset + sharing notifications?" | AskUserQuestion: Resend / SendGrid / Mailgun / Skip | Optional |

## Install method — Docker Compose (upstream canonical)

Source: https://docs.immich.app/install/docker-compose

**Key upstream convention:** use the compose file from the latest release tag, **not** `main`. The warning at the top of `docker/docker-compose.yml` on `main` says: "The compose file on main may not be compatible with the latest release."

```bash
mkdir ./immich-app
cd ./immich-app

# 1. Pull compose + env from the latest release
wget -O docker-compose.yml \
  https://github.com/immich-app/immich/releases/latest/download/docker-compose.yml
wget -O .env \
  https://github.com/immich-app/immich/releases/latest/download/example.env

# 2. Edit .env:
#    UPLOAD_LOCATION    -> absolute path for photos (e.g. /srv/immich/library)
#    DB_DATA_LOCATION   -> absolute path for Postgres (e.g. /srv/immich/postgres)
#    TZ                 -> e.g. America/Los_Angeles
#    DB_PASSWORD        -> strong password, [A-Za-z0-9] only
#    IMMICH_VERSION     -> pinned tag like v2.7.5 or major-track like v2

# 3. Start
docker compose up -d
```

Server lands on `http://host:2283`. First visit creates the admin user.

### Services (from upstream compose)

| Service | Image | Role |
|---|---|---|
| `immich-server` | `ghcr.io/immich-app/immich-server` | API + web UI + backup endpoints |
| `immich-machine-learning` | `ghcr.io/immich-app/immich-machine-learning` | Face recognition, CLIP, smart search |
| `redis` | `docker.io/valkey/valkey:9` (SHA-pinned) | Job queue |
| `database` | `ghcr.io/immich-app/postgres` (SHA-pinned — custom build with pgvector, vectorchord, pgvectors) | Postgres w/ vector search extensions |

**Note:** upstream's Postgres image is a **custom build**, not stock postgres. It ships `vectorchord`, `pgvecto.rs`, and specific versions. Do not substitute stock `postgres:16` — Immich requires these extensions. See the SHA-pinned tag in the compose file.

### Hardware-accelerated transcoding (optional)

The compose references `hwaccel.transcoding.yml` (in the same release assets). Uncomment the `extends:` block for `immich-server` and set `service:` to one of:

- `nvenc` — NVIDIA GPU (requires nvidia-container-toolkit)
- `quicksync` — Intel QSV
- `rkmpp` — Rockchip (ARM SoCs)
- `vaapi` — generic Linux VAAPI
- `vaapi-wsl` — VAAPI inside WSL2

### Hardware-accelerated ML inference (optional)

Append a suffix to the ML image tag: `${IMMICH_VERSION:-release}-cuda` (or `-armnn`, `-rocm`, `-openvino`, `-rknn`). Also uncomment the `extends:` block referencing `hwaccel.ml.yml`.

## Software-layer concerns

### Key env vars (from upstream `example.env`)

| Var | Required? | Purpose |
|---|---|---|
| `UPLOAD_LOCATION` | yes | Host path where uploaded media is stored (mapped to `/data` in the server container) |
| `DB_DATA_LOCATION` | yes | Host path for Postgres data (local disk — no NFS/SMB) |
| `TZ` | recommended | Affects timestamps and scheduled jobs |
| `IMMICH_VERSION` | yes | Image tag — pin for production |
| `DB_PASSWORD` | yes | Postgres superuser password. Only `A-Za-z0-9` (no special chars) |
| `DB_USERNAME` | no | Default `postgres` (don't change) |
| `DB_DATABASE_NAME` | no | Default `immich` (don't change) |

Full env-var reference: https://docs.immich.app/install/environment-variables

### Paths (inside containers / volumes)

| Thing | Path |
|---|---|
| Media (server) | `${UPLOAD_LOCATION}` → `/data` |
| Postgres data | `${DB_DATA_LOCATION}` → `/var/lib/postgresql/data` |
| ML model cache | docker volume `model-cache` → `/cache` |

### Reverse proxy

Point a domain at `:2283`. Immich uploads can be large (4K videos) — **raise proxy body-size limits** and enable websockets. Caddy:

```caddy
photos.example.com {
  reverse_proxy 127.0.0.1:2283

  request_body {
    max_size 50GB
  }
}
```

Nginx default `client_max_body_size` (1 MB) will silently truncate uploads. Set it to something generous like `50G`.

### Mobile app config

Point the mobile app's `Server Endpoint URL` at `https://photos.example.com/api`. (Yes, `/api` suffix — upstream convention.)

## Upgrade procedure

1. Review https://github.com/immich-app/immich/releases for breaking changes (Immich bumps fast; migrations between majors sometimes require manual steps).
2. **Back up** `UPLOAD_LOCATION` and the Postgres DB (`pg_dump` or volume snapshot while stopped).
3. Update `IMMICH_VERSION` in `.env` (or re-fetch the release's `docker-compose.yml` + `example.env`).
4. `docker compose pull`
5. `docker compose up -d`
6. Watch `docker compose logs -f immich-server` for schema migrations to complete.

Immich DB migrations run automatically on server start; rollback = restore the DB backup + use the older image tag.

## Gotchas

- **Pin the version.** `IMMICH_VERSION=release` pulls whatever `:release` currently points at — great for latest, painful when upstream ships a breaking v2→v3. Pin to `v2.7.5` or similar for stability.
- **Postgres image is a custom upstream build.** Don't substitute `postgres:16` — Immich needs specific vector extensions at specific versions. The SHA-pinned tag in the compose is intentional.
- **Do NOT store `DB_DATA_LOCATION` on NFS/SMB.** Postgres hates network filesystems. `UPLOAD_LOCATION` on NFS is fine (with caveats on performance and locking).
- **`DB_PASSWORD` character set is restrictive.** Only `A-Za-z0-9` because it flows into URLs/connection strings without escaping.
- **ML container is heavy.** ~4 GB image, needs ~2 GB RAM. On Pi / small VPS, consider disabling the `immich-machine-learning` service (search-by-face/smart-search will break; everything else works).
- **Reverse-proxy body-size limit.** Default Nginx kicks back uploads > 1 MB with a 413. Raise it everywhere — Caddy, Nginx, CloudFront (if fronting), tailscale serve, etc.
- **Mobile backup can flood the server.** First full-library sync from a phone can push 10s of GB. Check upload-concurrency settings and consider kicking it off on wifi overnight.
- **`main` branch compose file is not release-compatible.** Use the release asset, not `docker/docker-compose.yml` from `main`. Upstream is emphatic about this.
- **AGPL implications.** If you fork and deploy a modified version publicly, you must share your changes. Using stock Immich for personal/family photos is fine.
- **Postgres checksum enabling is default.** `POSTGRES_INITDB_ARGS: '--data-checksums'` is in the compose — good for integrity, but means restoring a non-checksum dump may require `--no-data-checksums` initdb on restore.

## TODO — verify on subsequent deployments

- [ ] Exercise CUDA ML path end-to-end (hwaccel.ml.yml + `IMMICH_VERSION=v2-cuda`).
- [ ] Verify `immich-charts` Helm deploys cleanly on k3s.
- [ ] Backup-script reference — which tool (`pgbackrest`, `restic`, `borg`)? Add to `references/modules/backups.md`.
- [ ] Confirm OAuth (Authelia, Authentik, Keycloak) wiring patterns for shared-household setups.
- [ ] Test upload size limit behavior behind Cloudflare — CF caps at 100 MB on free tier; may need Tunnel + direct origin for large videos.
