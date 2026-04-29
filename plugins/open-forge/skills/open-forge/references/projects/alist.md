---
name: alist-project
description: Alist recipe for open-forge. AGPL-3.0 Go + SolidJS file-list / multi-cloud aggregator. Exposes a web UI, WebDAV endpoint, and API for files spread across 40+ cloud storage providers (S3, OneDrive, Google Drive, Dropbox, Aliyundrive, Baidu, 115, MEGA, SMB, FTP/SFTP, local FS, and many China-market drives). Single Go binary; deploys as Docker (`xhofe/alist`), prebuilt binary with systemd, or a one-line install script. NOT a sync tool — it proxies / 302-redirects, giving you one unified view without copying files around.
---

# Alist

AGPL-3.0 Go + SolidJS file-list program that aggregates multiple cloud storages behind one UI / WebDAV / API. Upstream: <https://github.com/AlistGo/alist>. Docs: <https://alistgo.com/>.

**What it is:**

- A **read-aggregator** for cloud drives — browse, preview, download files across many backends from one URL.
- A **WebDAV server** exposing the aggregated view (mount it as a drive, or point other apps at it).
- **Not a sync engine** — per upstream disclaimer, Alist "only does 302 redirect/traffic forwarding, and does not intercept, store, or tamper with any user data." Files stay on the original storage.

Default port: `:5244` (web + WebDAV) and `:5245` (optional stand-alone WebDAV port).

**Geographic context.** The project was originally `Xhofe/alist`, has since reorganized to `AlistGo/alist`. It supports many China-specific cloud drives (Aliyundrive, 189Cloud, 115, Baidu, Quark, Thunder, Lanzou, etc.) that Rclone doesn't — much of the user base is in China. The license is AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`xhofe/alist:latest`) | <https://hub.docker.com/r/xhofe/alist> · <https://github.com/AlistGo/alist/blob/main/docker-compose.yml> | ✅ | Most common install. Upstream publishes the compose file. |
| Docker with ffmpeg / aria2 | Build args `INSTALL_FFMPEG=true`, `INSTALL_ARIA2=true` | ✅ | For video thumbnailing and offline-download (aria2 RPC backend). |
| Prebuilt binary (GitHub releases) | <https://github.com/AlistGo/alist/releases> | ✅ | Linux / Windows / macOS native binary. Systemd under control. |
| One-line install script | <https://alistgo.com/guide/install/script.html> | ✅ | Convenience wrapper around the binary install — writes a systemd unit. |
| Build from source | Standard Go build | ✅ | Dev / custom fork. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method? (docker / binary / script / source)" | `AskUserQuestion` | Drives section. |
| data | "Data dir (holds SQLite/MySQL creds file, uploaded cache)?" | Free-text, default `/etc/alist` | Mounted at `/opt/alist/data` in Docker. |
| admin | "Generate initial admin password now, or via CLI after start?" | `AskUserQuestion` | Alist prints a random admin password on first start; override with `admin set <password>` via CLI. |
| dns | "Public domain?" | Free-text | Reverse-proxy + TLS for public-facing. |
| proxy | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Alist does not terminate TLS. |
| storage | "Which cloud backends?" | Multi-select from 40+ providers at <https://alistgo.com/guide/drivers/> | Added via admin UI or OpenAPI — not at install time. |
| aria2 | "Enable built-in aria2 offline-download?" | `AskUserQuestion` | Requires `INSTALL_ARIA2=true` build arg or standalone aria2c. |

## Install — Docker Compose

Upstream's `docker-compose.yml`:

```yaml
# docker-compose.yml (from https://github.com/AlistGo/alist/blob/main/docker-compose.yml)
services:
  alist:
    image: xhofe/alist:latest
    container_name: alist
    restart: always
    volumes:
      - '/etc/alist:/opt/alist/data'
    ports:
      - '5244:5244'
      - '5245:5245'
    environment:
      - PUID=0
      - PGID=0
      - UMASK=022
      - TZ=UTC
```

```bash
sudo mkdir -p /etc/alist
docker compose up -d
# First-boot admin password is printed to logs:
docker logs alist 2>&1 | grep -i 'password'
# Or reset:
docker exec -it alist ./alist admin set 'your-new-password'
```

Visit `http://<host>:5244/@manage` to log in.

### Image variants

| Tag | Contents |
|---|---|
| `xhofe/alist:latest` | Core binary, minimal Alpine. |
| `xhofe/alist:latest-ffmpeg` | Adds ffmpeg for video-thumbnail generation. |
| `xhofe/alist:latest-aria2` | Adds aria2c for offline download. |
| `xhofe/alist:beta` | Pre-release branch. |
| `xhofe/alist:v<x.y.z>` | Pinned version. |

## Install — Prebuilt binary + systemd

```bash
# 1. Pick version (check https://github.com/AlistGo/alist/releases)
ALIST_VERSION=v3.44.0
ARCH=linux-amd64   # or linux-arm64, darwin-amd64, etc.

# 2. Download + extract
cd /tmp
curl -L -o alist.tar.gz \
  "https://github.com/AlistGo/alist/releases/download/${ALIST_VERSION}/alist-${ARCH}.tar.gz"
sudo mkdir -p /opt/alist
sudo tar -xzf alist.tar.gz -C /opt/alist
sudo chmod +x /opt/alist/alist

# 3. Initialize (creates /opt/alist/data/ with default config + random admin password)
cd /opt/alist
sudo ./alist server  # Ctrl-C after it prints the admin password; use it or reset via ./alist admin set

# 4. Systemd unit
sudo useradd --system --no-create-home --shell /usr/sbin/nologin alist
sudo chown -R alist:alist /opt/alist

sudo tee /etc/systemd/system/alist.service > /dev/null <<'EOF'
[Unit]
Description=Alist service
After=network.target

[Service]
Type=simple
User=alist
Group=alist
WorkingDirectory=/opt/alist
ExecStart=/opt/alist/alist server
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now alist
sudo systemctl status alist
```

## Install — One-line script

Upstream's script wraps the binary install + systemd unit generation:

```bash
# Install (review the script before running)
# https://alistgo.com/guide/install/script.html
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s install

# Common management commands from the same script:
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s update
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s uninstall
```

Default install location: `/opt/alist/`. Systemd unit: `alist.service`. Config: `/opt/alist/data/config.json`.

## First-run flow

1. Start Alist (any method above).
2. Admin password is either:
   - Printed to stdout / container log on first boot (random), OR
   - You set it via `alist admin set <password>` (binary) / `docker exec alist ./alist admin set <password>` (Docker).
3. Browse `http://<host>:5244/@manage` and log in as `admin`.
4. In **Settings → Site**, set the public URL (used for WebDAV links + sharing).
5. In **Storages → Add**, add cloud backends one by one. Each has its own provider-specific OAuth / API-key / endpoint flow.
6. Files appear under their configured mount paths in the root UI.

### Two-factor authentication

Enable under **Profile → Two-Factor Authentication** (TOTP; pair with any authenticator app). **Do this before exposing to the public internet.** Alist's attack surface includes every drive it's connected to.

## Reverse proxy (Caddy example)

```caddy
alist.example.com {
    reverse_proxy 127.0.0.1:5244
}
```

WebDAV clients use the same URL: `https://alist.example.com/dav/`.

For nginx, turn off proxy buffering for large file streams:

```nginx
location / {
    proxy_pass http://127.0.0.1:5244;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_buffering off;
    client_max_body_size 20000m;   # for uploads — set to your largest expected file
    proxy_read_timeout 3600s;
}
```

## Configuration

Alist writes `data/config.json` on first start. Key fields (edit via UI under **Settings** or directly in the file, then restart):

| Key | Purpose |
|---|---|
| `scheme.address` | Bind address (default `0.0.0.0`). |
| `scheme.http_port` | `5244`. |
| `scheme.enable_h2c` | HTTP/2 cleartext. Default off. |
| `database.type` | `sqlite3` (default) / `mysql` / `postgres`. |
| `database.host/port/user/pass/name` | External DB config. |
| `jwt_secret` | Token signing key. Auto-generated. |
| `token_expires_in` | JWT TTL, default 48h. |
| `site_url` | Canonical public URL. **Must be set correctly** for WebDAV + cross-storage redirects. |

## Data layout

| Path (binary) | Path (Docker) | Content |
|---|---|---|
| `/opt/alist/data/config.json` | `/opt/alist/data/config.json` | Main config. |
| `/opt/alist/data/data.db` | `/opt/alist/data/data.db` | SQLite (storage configs, users, WebDAV creds). |
| `/opt/alist/data/log/` | `/opt/alist/data/log/` | Rolling logs. |
| `/opt/alist/data/temp/` | `/opt/alist/data/temp/` | Transient upload/cache buffers. |

**Backup:** tar `data/` while Alist is stopped. No external files to worry about — Alist doesn't store uploaded file content locally unless you enable the "Cache" or "Offline download" features.

## Upgrade procedure

### Docker

```bash
docker compose pull
docker compose up -d
docker compose logs -f alist
```

### Binary

```bash
curl -fsSL "https://alist.nn.ci/v3.sh" | bash -s update
sudo systemctl restart alist
# Or manually:
# sudo systemctl stop alist
# download new tarball → replace /opt/alist/alist
# sudo systemctl start alist
```

Database schema migrations run automatically on first start of a new version.

## Gotchas

- **`PUID=0 PGID=0` in the default compose is root-inside-container.** Upstream ships it this way because file permissions on SMB/NFS mounts are easier when root. If you're not using those mounts, switch to `PUID=1000 PGID=1000` and ensure `/etc/alist` is owned by that UID.
- **Default admin password is random and printed ONCE.** Grep Docker logs within a few minutes of first start, or reset with `alist admin set`. Missing this step and losing the log = locked out.
- **`site_url` in Settings must match the canonical external URL** — otherwise WebDAV redirects, share links, and cross-storage 302s break.
- **2FA first, expose second.** Alist connects to your cloud drives with full-access tokens. A compromised admin account = compromised every drive. Enable TOTP before DNS goes live.
- **The 302-redirect model leaks direct provider URLs.** When a file is served, Alist usually returns a 302 to the provider's CDN URL (which includes a signed token). That URL is shareable by any client for its TTL — if you point Alist at a private drive, be aware users can hand out direct-access URLs.
- **Upload size at the reverse proxy.** Default nginx `client_max_body_size 1m` breaks any file >1MB uploaded through the web UI. Set it to expected max file size explicitly.
- **WebDAV auth is HTTP Basic** (username + password). Always front with TLS — don't expose WebDAV on plain HTTP.
- **Aria2 offline download stores to local `temp/` dir first, then uploads.** Disk usage can balloon during large transfers. Configure aria2 to use a dedicated disk.
- **MySQL backend is not the default.** SQLite is fine for single-user / small deploys; for multi-admin or HA, switch `database.type` and migrate manually (export storages from old → import to new).
- **License: AGPL-3.0.** Running a modified version as a public network service triggers the source-distribution requirement. If you fork + run publicly, publish the source.
- **Sustainable Use caveat on `AlistGo/alist` fork history.** The repo moved from `Xhofe/alist` → `alist-org/alist` → `AlistGo/alist`; Docker image is still `xhofe/alist` on Docker Hub. Some older URLs / docs link to the old org — prefer the current `AlistGo/alist` and `alistgo.com` refs.
- **China-region drivers may require VPN-like network access.** Some of the 40+ drivers (Aliyundrive, 115, Baidu) work only from China-addressable IPs without extra config.
- **OpenList** (<https://github.com/OpenListTeam/OpenList>) is a community fork that diverged around mid-2024 — if you see newer features on OpenList that aren't in AlistGo, evaluate if the fork better fits. Both are AGPL-3.0 and UI-compatible.

## Links

- Upstream repo: <https://github.com/AlistGo/alist>
- Docs: <https://alistgo.com/>
- Install docs: <https://alistgo.com/guide/install/>
- Driver list: <https://alistgo.com/guide/drivers/>
- WebDAV guide: <https://alistgo.com/guide/webdav.html>
- API docs: <https://alist-public.apifox.cn/>
- Docker image: <https://hub.docker.com/r/xhofe/alist>
- Releases: <https://github.com/AlistGo/alist/releases>
- Discord: <https://discord.gg/F4ymsH4xv2>
