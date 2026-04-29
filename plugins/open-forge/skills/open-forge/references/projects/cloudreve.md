---
name: cloudreve-project
description: Cloudreve recipe for open-forge. GPL-3.0 self-hosted file management system with multi-cloud backing — connect local disk + S3-compatible + OneDrive + Aliyun OSS + Tencent COS + Huawei Cloud OBS + Kingsoft KS3 + Upyun + Qiniu Kodo + remote Cloudreve node as storage policies. Single Go binary + Postgres + Redis stack. Features: drag-drop upload w/ resumable parallel transfer, WebDAV, integrated aria2/qBittorrent for background downloads, compress/extract archives, online media preview (video/image/audio/ePub) and document editing (text/diagrams/Markdown/images/Office), multi-user with groups, share links, metadata extraction, full-text search addon via Tika+Meilisearch, dark mode, PWA, i18n. Covers official docker-compose.yml (Cloudreve v4 + Postgres 17 + Redis), CR_CONF_* env vars, Pro edition overlay, and the Dockerfile reality (aria2 + ffmpeg + libreoffice + vips bundled via supervisord in the single image).
---

# Cloudreve

GPL-3.0 self-hosted file management system with multi-cloud backends. Upstream: <https://github.com/cloudreve/cloudreve>. Docs: <https://docs.cloudreve.org>. Website: <https://cloudreve.org>. Demo: <https://demo.cloudreve.org>.

Think "self-hosted Nextcloud-like file UI, but the storage backend is pluggable across 10+ providers." You can mix local disk with S3 + OneDrive + remote Cloudreve nodes and present them as a unified file tree.

## What makes it different from Nextcloud / Seafile

- **Storage abstraction is first-class.** Every folder can have a different "storage policy" — local, S3, OneDrive, remote Cloudreve node, etc. Files live where the policy says; upload/download goes direct from client to provider when possible.
- **No app ecosystem.** Not a platform, just a file manager. Lighter than Nextcloud.
- **Go + React.** Single Go binary for the backend, no PHP. ~34 MB release size.
- **Bundled aria2 + qBittorrent integration** for background downloads (magnet / torrent / HTTP).
- **Bundled libreoffice + vips + ffmpeg + libraw** in the Docker image for thumbnails / previews / metadata.
- **GPLv3** — copyleft. There's also a Pro edition (paid, closed-source overlay via private image registry + license key).

## Storage policies supported

Local disk, Remote Cloudreve node (multi-node / federation), OneDrive (personal + business), S3-compatible (AWS / MinIO / Wasabi / Backblaze B2 / DigitalOcean Spaces / any S3 API), Aliyun OSS, Tencent COS, Huawei Cloud OBS, Kingsoft KS3, Qiniu Kodo, Upyun.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/cloudreve/docker-compose> | ✅ Recommended | Standard self-host. |
| Docker run (single container) | <https://hub.docker.com/r/cloudreve/cloudreve> | ✅ | Tiny eval / non-Postgres (uses bundled SQLite). |
| Binary tarball | <https://github.com/cloudreve/cloudreve/releases> | ✅ | Bare-metal / systemd. |
| Build from source | <https://docs.cloudreve.org/overview/build/> | ✅ | Contributors. |
| Supervisor (process manager) | <https://docs.cloudreve.org/overview/deploy/supervisor> | ✅ | Bare-metal non-Docker. |

Image tags:

- `cloudreve/cloudreve:v4` — major version 4.x (current)
- `cloudreve/cloudreve:v4.2` — minor pin (recommended for production)
- `cloudreve/cloudreve:latest` — avoid for production (jumps on majors)

Pro edition: `cloudreve.azurecr.io/...` (private registry; license key required).

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `binary-systemd` | Drives section. |
| edition | "Community or Pro?" | `AskUserQuestion`: `community (free, GPLv3)` / `pro (paid, private image + license)` | Pro needs `CR_LICENSE_KEY`. |
| ports | "Main port?" | Default `5212` | Cloudreve's HTTP port. |
| ports | "Aria2 BT port?" | Default `6888/tcp + 6888/udp` | Only needed if using aria2 BT downloads. Open through firewall/NAT. |
| db | "Database?" | `AskUserQuestion`: `postgres-in-stack (recommended)` / `sqlite (single-container only)` / `mysql (manual setup)` | Compose ships Postgres 17. |
| fts | "Enable full-text search?" | Boolean | Adds Meilisearch + Apache Tika via `docker-compose.fts.yml` overlay. |
| fts | "Meilisearch master key?" | 32-byte hex (`openssl rand -hex 32`) | Required if fts enabled. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none` | Cloudreve speaks plain HTTP; terminate TLS externally. |

## Install — Docker Compose (community edition)

Canonical flow per upstream (<https://docs.cloudreve.org/overview/deploy/docker-compose>):

```bash
git clone https://github.com/cloudreve/docker-compose.git ~/cloudreve
cd ~/cloudreve
cp .env.example .env
docker compose up -d
# → http://<host>:5212/
```

Base compose file (`docker-compose.yml` verbatim from upstream):

```yaml
services:
  cloudreve:
    image: cloudreve/cloudreve:v4
    container_name: cloudreve
    depends_on:
      postgresql: { condition: service_started }
      redis:      { condition: service_started }
    restart: unless-stopped
    ports:
      - 5212:5212
      - 6888:6888
      - 6888:6888/udp
    environment:
      - CR_CONF_Database.Type=postgres
      - CR_CONF_Database.Host=postgresql
      - CR_CONF_Database.User=cloudreve
      - CR_CONF_Database.Name=cloudreve
      - CR_CONF_Database.Port=5432
      - CR_CONF_Redis.Server=redis:6379
    volumes:
      - backend_data:/cloudreve/data

  postgresql:
    image: postgres:17
    container_name: postgresql
    restart: unless-stopped
    environment:
      - POSTGRES_USER=cloudreve
      - POSTGRES_DB=cloudreve
      - POSTGRES_HOST_AUTH_METHOD=trust
    volumes:
      - database_postgres:/var/lib/postgresql/data

  redis:
    image: redis:latest
    container_name: redis
    restart: unless-stopped
    volumes:
      - redis_data:/data

volumes:
  backend_data:
  database_postgres:
  redis_data:
```

⚠️ **`POSTGRES_HOST_AUTH_METHOD=trust` is insecure by default.** Fine if the Postgres container is not exposed to anything beyond the compose network. For hardening, replace with `POSTGRES_PASSWORD=<strong-pwd>` and set `CR_CONF_Database.Password=<same>`.

First registered account becomes admin.

## Pro edition overlay

```bash
# Register at https://cloudreve.org/login → Pro license panel
# → obtain container registry credentials + license key

docker login -u <obtained> -p <obtained> cloudreve.azurecr.io

# Add to .env:
# CR_LICENSE_KEY=<authorization-key>

docker compose -f docker-compose.yml -f docker-compose.pro.yml up -d
```

Registry credentials expire — re-login when pulls fail.

## Full-text search overlay (Tika + Meilisearch)

```bash
# Generate a Meilisearch master key
openssl rand -hex 32
# Set MEILI_MASTER_KEY=<that-value> in .env

docker compose -f docker-compose.yml -f docker-compose.fts.yml up -d
```

Docs: <https://docs.cloudreve.org/usage/search/fts>.

## Install — Docker run (single container, SQLite)

For tiny trials only:

```bash
docker run -d --name cloudreve \
  -p 5212:5212 -p 6888:6888 -p 6888:6888/udp \
  -v cloudreve_data:/cloudreve/data \
  --restart unless-stopped \
  cloudreve/cloudreve:v4
```

Without `CR_CONF_Database.*` envs, Cloudreve uses bundled SQLite. Works, but poorly suited for multi-user production.

## Configuration — `CR_CONF_*` environment variables

Cloudreve 4 is configured via env vars (or a `conf.ini` file). The format is `CR_CONF_<Section>.<Key>`:

| Env var | Purpose |
|---|---|
| `CR_CONF_Database.Type` | `postgres` / `mysql` / `sqlite` |
| `CR_CONF_Database.Host` | DB host |
| `CR_CONF_Database.Port` | DB port |
| `CR_CONF_Database.User` | DB user |
| `CR_CONF_Database.Password` | DB password |
| `CR_CONF_Database.Name` | DB name |
| `CR_CONF_Redis.Server` | `host:port` |
| `CR_CONF_Redis.Password` | Redis password (if set) |
| `CR_CONF_System.Listen` | Listen address (default `:5212`) |
| `CR_CONF_System.ProxyHeader` | If behind reverse proxy: `X-Forwarded-For` |
| `CR_ENABLE_ARIA2=1` | Enable bundled aria2 (default in image) |
| `CR_SETTING_DEFAULT_thumb_ffmpeg_enabled=1` | Enable ffmpeg thumbs |
| `CR_SETTING_DEFAULT_thumb_vips_enabled=1` | Enable vips thumbs |
| `CR_SETTING_DEFAULT_thumb_libreoffice_enabled=1` | Enable libreoffice thumbs |
| `CR_SETTING_DEFAULT_media_meta_ffprobe=1` | Enable ffprobe metadata |
| `CR_SETTING_DEFAULT_thumb_libraw_enabled=1` | Enable libraw (RAW image) thumbs |
| `CR_LICENSE_KEY` | Pro edition license |

Full reference: <https://docs.cloudreve.org/overview/deploy/configure>.

## Reverse proxy (Caddy example)

```caddy
files.example.com {
    reverse_proxy cloudreve:5212
}
```

In Cloudreve admin: **System → General** → set Site URL to `https://files.example.com/` so share links and email notifications use the public URL.

## Data layout

| Path | Content |
|---|---|
| `/cloudreve/data/` | Main data dir — config, uploaded files (for local policy), aria2 temp, logs |
| `/cloudreve/data/cloudreve.db` | SQLite DB (if using SQLite — not recommended for prod) |
| `/cloudreve/data/temp/aria2/` | aria2 working dir (torrents, HTTP downloads in-flight) |
| Postgres volume | User accounts, file metadata, shares, groups, storage policies, sessions |
| Redis volume | Cache, job queue, session data (rebuildable) |
| Cloud storage providers | Actual file contents (if policy is S3 / OneDrive / etc.) |

**Backup priority:**

1. **Postgres** (`pg_dump`) — ALL metadata (users, file records, shares). Losing this = files orphaned.
2. **`/cloudreve/data/`** (tar while paused) — local files + config.
3. **Remote storage providers** — their own backup strategy (S3 versioning, OneDrive's recycle bin, etc.). Cloudreve doesn't back these up.
4. Redis — cache only; rebuildable.

## Upgrade procedure

```bash
cd ~/cloudreve
# Pin to a new tag in docker-compose.yml if you want predictable moves
docker compose pull
docker compose up -d
docker compose logs -f cloudreve
```

Cloudreve runs DB migrations automatically on startup. For major version jumps (v3 → v4), read release notes at <https://github.com/cloudreve/cloudreve/releases> — v4 was a significant rewrite with admin-UI changes.

## Gotchas

- **First registered account = admin.** Register immediately after boot to claim the admin role; after that, disable public registration in admin settings (System → Register).
- **Storage policies are per-folder.** Setting up policies is the #1 configuration task after install. Admin → Storage Policies → create → assign to groups / users.
- **Default Postgres is `trust` auth.** Insecure. Replace with `POSTGRES_PASSWORD` + `CR_CONF_Database.Password` for any deployment not tightly networked.
- **`POSTGRES_HOST_AUTH_METHOD=trust` means ANY user from ANY IP on the compose network can connect without a password.** If you expose Postgres port 5432 accidentally = wide open.
- **Image bundles libreoffice + ffmpeg + libraw + vips** → ~1.5 GB+ container. For thumbnail generation this is required; for RAM-limited deploys consider disabling `CR_SETTING_DEFAULT_thumb_libreoffice_enabled` etc.
- **Aria2 BT ports 6888 TCP/UDP** must be exposed + forwarded through NAT for torrent peering. Without port forward, BT downloads still work (client-only) but slow.
- **v4 is a rewrite of v3.** Data migration from v3 is non-trivial. Read <https://docs.cloudreve.org/overview/migration> first.
- **Pro edition license** ties to specific install (hostname/host-id). Moving between hosts may require license re-activation.
- **`TZ` is hardcoded to `Asia/Shanghai`** in the default Dockerfile. Override via env: `TZ=UTC` (or your timezone). Otherwise timestamps in the UI show Shanghai time.
- **Remote node federation** needs shared master key between nodes; network reachability on whatever port you pick. Admin → Storage Policies → Remote node.
- **OneDrive personal and OneDrive business** have different OAuth flows. Register app at Azure AD portal FIRST, then configure the policy.
- **S3 "direct upload" requires CORS** on the bucket pointing at your Cloudreve origin. Without CORS, uploads fall back to "relay via Cloudreve," which is slower and uses bandwidth on your server.
- **WebDAV endpoint** is at `/dav`. Most WebDAV clients need the full URL (`https://files.example.com/dav`) + username + password (create app-specific password in user settings).
- **File names with special characters** can break on some storage providers (Windows-incompatible chars in S3, etc.). Cloudreve doesn't sanitize — surfaces errors at upload time.
- **Disk quota is per-user (admin-set).** No storage-policy-level quota in OSS.
- **No built-in encryption at rest.** Files on S3 are encrypted iff S3 is configured with SSE. Files on local disk = plaintext.
- **Share links can be public or password-protected.** Default expiry = never. Set a default expiry in admin settings.
- **Upload chunk size** is configurable per storage policy. Larger chunks = fewer requests but more memory. Defaults are sensible.
- **Search** (Community edition) is filename-only. Full-text search requires the FTS overlay (Meilisearch + Tika).
- **Admin UI is separate from user UI.** `/admin/*` path. Log in as admin, click avatar → Admin panel.
- **Meilisearch master key** is sensitive — exposed = anyone can modify the search index. Keep in .env, not committed.
- **Docs are primarily in Chinese**, with English translations at docs.cloudreve.org. Discord channel is available for English support.

## Links

- Upstream repo: <https://github.com/cloudreve/cloudreve>
- Docs: <https://docs.cloudreve.org>
- Docker Compose repo: <https://github.com/cloudreve/docker-compose>
- Docker install: <https://docs.cloudreve.org/overview/deploy/docker>
- Docker Compose install: <https://docs.cloudreve.org/overview/deploy/docker-compose>
- Configuration reference: <https://docs.cloudreve.org/overview/deploy/configure>
- Quickstart: <https://docs.cloudreve.org/overview/quickstart>
- Upgrade: <https://docs.cloudreve.org/overview/deploy/docker-compose> (Common Issues → How to upgrade)
- Full-text search: <https://docs.cloudreve.org/usage/search/fts>
- Docker Hub: <https://hub.docker.com/r/cloudreve/cloudreve>
- Releases: <https://github.com/cloudreve/cloudreve/releases>
- Pro license portal: <https://cloudreve.org/login>
- Demo: <https://demo.cloudreve.org>
- Telegram: <https://t.me/cloudreve_official>
- Discord: <https://discord.com/invite/WTpMFpZT76>
- Frontend repo: <https://github.com/cloudreve/frontend>
