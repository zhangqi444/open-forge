---
name: pocketbase-project
description: PocketBase recipe for open-forge. MIT-licensed Go backend-in-one-file — embedded SQLite with realtime subscriptions, built-in auth/file/admin UI, REST-ish API. Single static binary, no dependencies. Covers the prebuilt-executable install (upstream-recommended), the Docker container (community-maintained), and the Go-framework embedding path. Pre-v1.0; upstream explicitly warns that full backward compatibility is not guaranteed before reaching v1.0.
---

# PocketBase

MIT-licensed open-source Go backend, distributed as a single self-contained executable. Upstream: <https://github.com/pocketbase/pocketbase>. Docs: <https://pocketbase.io/docs>.

PocketBase bundles everything into one binary:

- Embedded SQLite + realtime subscriptions (SSE)
- Built-in admin dashboard UI (served by the same binary)
- User/file management, OAuth2, REST-ish API
- JS VM plugin (`JSVM`) lets you extend with JavaScript hooks without rebuilding

No PostgreSQL, no Redis, no reverse proxy required. The single binary listens on `:8090` by default.

**⚠️ Pre-1.0 stability warning** (from upstream README): *"Please keep in mind that PocketBase is still under active development and therefore full backward compatibility is not guaranteed before reaching v1.0.0."* Breaking changes between minor releases do happen. Pin an exact version in production.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Prebuilt executable (GitHub release) | <https://github.com/pocketbase/pocketbase/releases> | ✅ Recommended | The upstream-recommended install — one static binary, run it. |
| Docker image (community) | <https://hub.docker.com/r/spectado/pocketbase> · <https://github.com/muchobien/pocketbase-docker> | ⚠️ Community-maintained | Upstream does NOT publish an official Docker image. Community images exist; verify image source before pulling. |
| Build from source | Standard Go build | ✅ | Dev / reproducible builds. Needs Go 1.25+ (per upstream README). |
| Go framework/library (`pocketbase.New()`) | `examples/base/main.go` | ✅ | Embed PocketBase in your own Go app + custom routes / hooks. Still a single binary at the end. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method? (binary / Docker / Go-framework)" | `AskUserQuestion` | Drives the section used. |
| platform | "OS + arch?" | Free-text (e.g. `linux-amd64`, `darwin-arm64`) | Binary install — picks the right release asset. |
| service | "Run as systemd unit, plain nohup, or foreground?" | `AskUserQuestion` | Binary install. Systemd is upstream's recommended production shape. |
| dns | "Public domain for PocketBase?" | Free-text | Any public-facing deploy. |
| tls | "Reverse proxy for HTTPS? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | PocketBase's built-in auto-TLS exists but upstream docs recommend a reverse proxy in production. |
| admin | "Initial admin email?" | Free-text | Required for the first superuser (created via CLI or first-run web flow). |
| admin | "Initial admin password?" | Free-text (sensitive) | Stored hashed. `pocketbase superuser create` command. |

## Install — Prebuilt executable (upstream-recommended)

```bash
# 1. Pick a version (check https://github.com/pocketbase/pocketbase/releases for latest)
PB_VERSION=0.29.1  # example — verify current at install time
ARCH=linux_amd64   # or linux_arm64, darwin_amd64, darwin_arm64, windows_amd64

# 2. Download + extract
curl -L -o /tmp/pocketbase.zip \
  "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_${ARCH}.zip"
sudo mkdir -p /opt/pocketbase
sudo unzip /tmp/pocketbase.zip -d /opt/pocketbase
sudo chmod +x /opt/pocketbase/pocketbase

# 3. First run — creates pb_data/ in CWD
cd /opt/pocketbase
./pocketbase serve
# → "Server started at http://127.0.0.1:8090"
# → Admin UI at http://127.0.0.1:8090/_/
# → First request prompts to create the initial superuser interactively,
#   OR create one non-interactively before starting:
# ./pocketbase superuser create admin@example.com 'strong-password'
```

### Systemd unit (production)

```ini
# /etc/systemd/system/pocketbase.service
[Unit]
Description=PocketBase
After=network.target

[Service]
Type=simple
User=pocketbase
Group=pocketbase
LimitNOFILE=4096
Restart=always
RestartSec=5s
WorkingDirectory=/opt/pocketbase
ExecStart=/opt/pocketbase/pocketbase serve --http=0.0.0.0:8090

[Install]
WantedBy=multi-user.target
```

```bash
sudo useradd --system --home /opt/pocketbase --shell /usr/sbin/nologin pocketbase
sudo chown -R pocketbase:pocketbase /opt/pocketbase
sudo systemctl daemon-reload
sudo systemctl enable --now pocketbase
sudo systemctl status pocketbase
sudo journalctl -u pocketbase -f
```

### Reverse proxy (Caddy example)

```caddy
pb.example.com {
    reverse_proxy 127.0.0.1:8090
}
```

Caddy obtains Let's Encrypt automatically. For nginx/Traefik, terminate TLS at the proxy and forward to `127.0.0.1:8090`.

**Realtime (SSE) requires proxy buffering disabled.** For nginx:

```nginx
location / {
    proxy_pass http://127.0.0.1:8090;
    proxy_buffering off;
    proxy_cache off;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Install — Docker (community-maintained)

There is **no official `pocketbase/pocketbase` image on Docker Hub**. Community images exist; the most popular is `ghcr.io/muchobien/pocketbase` (<https://github.com/muchobien/pocketbase-docker>). Verify any image's Dockerfile before pulling — you're trusting the maintainer to bundle a legitimate upstream binary.

```yaml
# compose.yaml — based on muchobien/pocketbase-docker; verify before use
services:
  pocketbase:
    image: ghcr.io/muchobien/pocketbase:latest
    container_name: pocketbase
    restart: unless-stopped
    ports:
      - "8090:8090"
    volumes:
      - ./pb_data:/pb_data
      # Optional: migrations + hooks mounts
      - ./pb_migrations:/pb_migrations
      - ./pb_hooks:/pb_hooks
    healthcheck:
      test: wget --no-verbose --tries=1 --spider http://localhost:8090/api/health || exit 1
      interval: 30s
      timeout: 5s
      retries: 3
```

Pin to a specific version tag (not `latest`) in production to avoid surprise upgrades.

## Install — Go framework (embed)

For custom backends that want PocketBase's plumbing but with your own routes / business logic:

```bash
# 1. Install Go 1.25+ (per upstream README)

# 2. mkdir myapp && cd myapp && go mod init myapp
# 3. go get github.com/pocketbase/pocketbase

# 4. main.go — see upstream's minimal example in README, or examples/base/main.go
```

See <https://pocketbase.io/docs/go-overview/> for the full API.

```bash
# Build a single static binary
go build -o myapp
./myapp serve --http=0.0.0.0:8090
```

## Data layout

PocketBase creates `pb_data/` in the working directory on first run:

| Path | Content |
|---|---|
| `pb_data/data.db` | Main SQLite DB (collections, records, auth) |
| `pb_data/auxiliary.db` | Auxiliary DB (logs, jobs) |
| `pb_data/storage/` | Uploaded files (default: local FS) |
| `pb_data/backups/` | Generated via admin UI "Backups" feature |
| `pb_migrations/` | JS migration files (optional; `--migrationsDir` flag) |
| `pb_hooks/` | JSVM hook scripts (optional; `--hooksDir` flag) |

**Backup = snapshot `pb_data/` while the server is stopped, OR use the built-in Backups feature** (admin UI → Settings → Backups — uses SQLite online backup API so it's safe to run while up).

## Configuration

PocketBase is configured mostly via CLI flags and the admin UI, not env vars. Key flags:

| Flag | Default | Purpose |
|---|---|---|
| `--http` | `127.0.0.1:8090` | HTTP bind address. |
| `--https` | (off) | HTTPS bind address + auto-TLS via Let's Encrypt (needs public DNS + port 443). |
| `--dir` | `./pb_data` | Main data directory. |
| `--migrationsDir` | `./pb_migrations` | JS migration scripts dir. |
| `--hooksDir` | `./pb_hooks` | JSVM hooks dir. |
| `--origins` | `*` | CORS origins (comma-separated). Tighten in production. |

S3-compatible file storage, SMTP, OAuth2 providers, logs retention — all configured in the admin UI under Settings.

## Upgrade procedure

### Binary install

```bash
# 1. ALWAYS backup pb_data/ first
sudo systemctl stop pocketbase
sudo cp -a /opt/pocketbase/pb_data /opt/pocketbase/pb_data.bak.$(date +%F)

# 2. Download new release
PB_VERSION=0.30.0
curl -L -o /tmp/pb-new.zip \
  "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"

# 3. Replace binary
sudo unzip -o /tmp/pb-new.zip -d /opt/pocketbase
sudo chown pocketbase:pocketbase /opt/pocketbase/pocketbase

# 4. Read release notes FIRST — pre-v1.0, migrations may be required
# https://github.com/pocketbase/pocketbase/releases/tag/v<version>

# 5. Start — migrations run automatically on first boot
sudo systemctl start pocketbase
sudo journalctl -u pocketbase -n 100
```

### Docker

```bash
docker compose pull
docker compose up -d
docker compose logs -f pocketbase
```

**Pre-v1.0 upgrade discipline:** read the release notes for EVERY version bump. Even patch versions can ship schema migrations. Backing up `pb_data/` before upgrading is non-negotiable.

## Gotchas

- **Pre-v1.0 breaking changes.** Upstream's own README warns about this. Don't build a production system assuming semver stability — pin exact versions, read release notes on every upgrade, and have a tested rollback plan (restore `pb_data/`).
- **No official Docker image.** Community images are fine for hobby use but verify their Dockerfile. The binary is the upstream-blessed install; Docker is not.
- **SSE / realtime needs proxy buffering OFF.** nginx default proxy_buffering=on breaks PocketBase's realtime subscriptions. Caddy is fine by default.
- **Admin superuser bootstrap.** The first request to `/_/` creates the initial superuser via browser — if PocketBase is exposed to the internet before you create one, anyone can claim it. Either create non-interactively with `pocketbase superuser create <email> <password>` first, OR firewall port 8090 until you've claimed the account.
- **SQLite single-writer.** PocketBase uses SQLite with WAL mode. Suitable for the "dozens to low-thousands of writes/sec" range. For heavy write workloads, PocketBase is not the right tool.
- **No horizontal scaling.** Single process, single DB file on one disk. The upgrade path for "I need multiple nodes" is usually "migrate to a different backend," not "scale PocketBase."
- **File storage defaults to local FS.** To survive host loss, either (a) put `pb_data/` on durable storage and back it up, or (b) configure S3-compatible remote storage in admin UI → Settings → Files.
- **JSVM hooks run in a separate Goja runtime, not Node.** Not all npm packages work; check the docs at <https://pocketbase.io/docs/js-overview/> for what's supported.
- **CORS default is `*`.** For public deploys, narrow `--origins` to the actual frontend origins, or lock it down at the reverse proxy.

## Links

- Upstream repo: <https://github.com/pocketbase/pocketbase>
- Docs site: <https://pocketbase.io/docs>
- Go overview: <https://pocketbase.io/docs/go-overview/>
- JS overview (JSVM): <https://pocketbase.io/docs/js-overview/>
- How-to collection: <https://pocketbase.io/docs/how-to-use/>
- Releases: <https://github.com/pocketbase/pocketbase/releases>
- Community Docker image: <https://github.com/muchobien/pocketbase-docker>
