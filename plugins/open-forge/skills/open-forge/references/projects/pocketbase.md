---
name: pocketbase
description: PocketBase recipe for open-forge. Open-source backend in a single Go binary with embedded SQLite, realtime subscriptions, file/user management, and Admin dashboard. Upstream https://pocketbase.io/docs.
---

# PocketBase

Open-source backend-as-a-service in a single portable Go binary. Includes an embedded SQLite database with realtime subscriptions, built-in file and user management, a web Admin dashboard UI, and a simple REST-ish API. Upstream: <https://github.com/pocketbase/pocketbase>. Docs: <https://pocketbase.io/docs>. License: MIT.

PocketBase listens on port `8090` by default. Because it ships as a self-contained executable, the primary deployment path is running the binary directly (via systemd, screen, or a process manager). A Docker image is also available from the community. There is no official docker-compose in the upstream repo; the binary-based install is the upstream-documented approach.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Prebuilt binary (standalone) | <https://pocketbase.io/docs> | ✅ | Recommended. Single executable for Linux/macOS/Windows. Process managed by systemd or similar. |
| Extend with Go | <https://pocketbase.io/docs/go-overview/> | ✅ | Build your own app embedding PocketBase as a Go library. |
| Extend with JavaScript | <https://pocketbase.io/docs/js-overview/> | ✅ | Use the bundled JS VM plugin to add server-side hooks without recompiling. |
| Docker (community) | <https://hub.docker.com/r/ghcr.io/muchobien/pocketbase> | ⚠️ Community | No official Docker image in upstream repo; community images exist. Verify at deploy time. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options from table above | Drives method section |
| domain | "What domain will PocketBase be accessible at?" | Free-text | All public-facing installs |
| auth | "Admin email for initial setup?" | Free-text | All installs — first admin created via `/admin` UI |
| storage | "Where should PocketBase store its data directory?" | Free-text (default `./pb_data`) | All methods |

## Install — standalone binary

> **Source:** <https://pocketbase.io/docs> — "Use as standalone app"

```bash
# 1. Download the prebuilt executable for your platform from the releases page
#    https://github.com/pocketbase/pocketbase/releases
# Example for Linux amd64:
PB_VERSION=0.23.0   # replace with latest from releases page
wget "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"
unzip pocketbase_${PB_VERSION}_linux_amd64.zip -d /opt/pocketbase

# 2. Run
cd /opt/pocketbase
./pocketbase serve
```

Default access:
- API + Admin UI: `http://localhost:8090`
- Admin dashboard: `http://localhost:8090/_/`

To preserve data across restarts, keep `./pb_data` directory intact (auto-created on first run).

### Systemd unit (production)

```ini
# /etc/systemd/system/pocketbase.service
[Unit]
Description=PocketBase service
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/pocketbase
ExecStart=/opt/pocketbase/pocketbase serve --http=0.0.0.0:8090
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now pocketbase
```

## Docker Compose (community)

> ⚠️ **No official docker-compose in upstream repo.** The following is a representative community pattern; verify the image tag and config at deploy time.

```yaml
# docker-compose.yml — community pattern; verify image before use
services:
  pocketbase:
    image: ghcr.io/muchobien/pocketbase:latest
    restart: unless-stopped
    ports:
      - "8090:8090"
    volumes:
      - ./pb_data:/pb/pb_data
      - ./pb_migrations:/pb/pb_migrations
```

```bash
docker compose up -d
# Admin UI at http://localhost:8090/_/
```

## Software-layer concerns

### Key env vars / CLI flags

| Flag / Env | Default | Purpose |
|---|---|---|
| `--http` | `0.0.0.0:8090` | HTTP address to listen on |
| `--https` | _(unset)_ | HTTPS address (auto TLS via Let's Encrypt) |
| `--dir` | `./pb_data` | Data directory (SQLite DB + file uploads) |
| `--publicDir` | `./pb_public` | Static files to serve |
| `--encryptionEnv` | _(unset)_ | Env var name whose value is the 32-char AES key for encrypting `pb_data` fields |
| `PB_DATA_DIR` | _(unset)_ | Alternative to `--dir` via env |

### Data directory layout

```
pb_data/
  data.db          # Main SQLite database
  auxiliary.db     # Auxiliary SQLite DB
  storage/         # Uploaded files (organised by collection/record ID)
  logs/            # Access + app logs
```

### Reverse proxy (nginx example)

PocketBase does not terminate TLS natively in production setups — put it behind nginx or Caddy:

```nginx
server {
    listen 443 ssl;
    server_name ${DOMAIN};
    # ... ssl_certificate / ssl_certificate_key ...

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Required for realtime subscriptions (SSE)
        proxy_buffering off;
        proxy_read_timeout 86400;
    }
}
```

## Upgrade procedure

```bash
# 1. Stop the running instance
sudo systemctl stop pocketbase

# 2. Back up pb_data
cp -r /opt/pocketbase/pb_data /opt/pocketbase/pb_data.bak.$(date +%Y%m%d)

# 3. Download new release binary
PB_VERSION=<new_version>
wget "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"
unzip -o pocketbase_${PB_VERSION}_linux_amd64.zip -d /opt/pocketbase

# 4. Restart
sudo systemctl start pocketbase

# 5. Verify — check Admin UI at /_/
```

For Docker: `docker compose pull && docker compose up -d`

## Gotchas

- **Pre-v1.0 — backward compat not guaranteed.** Upstream warns that full backward compatibility is not guaranteed before v1.0.0. Always back up `pb_data` before upgrading.
- **Realtime subscriptions need unbuffered proxy.** If putting behind nginx/Caddy, disable proxy buffering (`proxy_buffering off`) and increase timeout — SSE connections are long-lived.
- **`--https` flag uses Let's Encrypt.** DNS must resolve to the server before starting with `--https`. Alternatively, handle TLS at the reverse proxy layer.
- **`pb_data` is the only thing that matters for backup.** Entire state (DB + uploads) lives in `pb_data`. Back it up; lose it and all data is gone.
- **Admin account created on first run via the UI.** Navigate to `/_/` immediately after starting — first visitor claims the superuser account. Guard this endpoint during bootstrap.
- **JavaScript hooks (JS VM plugin) are in the prebuilt binary.** No separate install needed; create `.js` files under `pb_hooks/` and they auto-load.

## Upstream docs

- Main docs: <https://pocketbase.io/docs>
- Go framework docs: <https://pocketbase.io/docs/go-overview/>
- JS hooks docs: <https://pocketbase.io/docs/js-overview/>
- Releases: <https://github.com/pocketbase/pocketbase/releases>
- Testing guide: <https://pocketbase.io/docs/testing>
