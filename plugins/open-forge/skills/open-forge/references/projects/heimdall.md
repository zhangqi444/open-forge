---
name: heimdall
description: Heimdall recipe for open-forge. Application dashboard and launcher — organise links to web services with application tiles, status monitoring, and a built-in search bar. Upstream https://heimdall.site. Maintained by LinuxServer.io.
---

# Heimdall

Application dashboard and launcher. Organise links to your most-used web sites and applications as tiles with icons, optionally showing live status via Enhanced App support. Includes Google/Bing/DuckDuckGo search bar. Designed as a clean browser start page. Upstream: <https://github.com/linuxserver/Heimdall>. Container image: `lscr.io/linuxserver/heimdall`. Docker docs: <https://docs.linuxserver.io/images/docker-heimdall>. License: MIT.

Heimdall (the app) is maintained at <https://github.com/linuxserver/Heimdall>; the Docker image is maintained at <https://github.com/linuxserver/docker-heimdall> by LinuxServer.io. Listens on ports `80` (HTTP) and `443` (HTTPS). The upstream-documented deployment method is Docker (Compose or CLI).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.linuxserver.io/images/docker-heimdall> | ✅ (LinuxServer.io) | Recommended. Official LinuxServer image with PUID/PGID support. |
| Docker CLI | <https://docs.linuxserver.io/images/docker-heimdall> | ✅ (LinuxServer.io) | Same image, no compose file. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options from table above | Drives method section |
| system | "Host user ID for file ownership (PUID)?" | Integer (default `1000`; find with `id -u`) | Docker — permissions for config volume |
| system | "Host group ID for file ownership (PGID)?" | Integer (default `1000`; find with `id -g`) | Docker — permissions for config volume |
| system | "Timezone (TZ)?" | TZ database name e.g. `America/New_York` | Docker |
| storage | "Host path for Heimdall config?" | Free-text (e.g. `/opt/heimdall/config`) | Docker |
| auth | "Add htpasswd password protection?" | Yes/No | Optional — see Application Setup |

## Docker Compose

> **Source:** <https://docs.linuxserver.io/images/docker-heimdall> (LinuxServer.io docker documentation for Heimdall)

```yaml
---
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:latest
    container_name: heimdall
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - ALLOW_INTERNAL_REQUESTS=false #optional
    volumes:
      - /path/to/heimdall/config:/config
    ports:
      - 80:80
      - 443:443
    restart: unless-stopped
```

### Deploy

```bash
mkdir -p /opt/heimdall
# Create docker-compose.yml as above, editing PUID/PGID/TZ/volume path

docker compose up -d

# Access the web UI at http://SERVERIP
```

## Software-layer concerns

### Key env vars

| Variable | Default | Purpose |
|---|---|---|
| `PUID` | `1000` | User ID for file ownership in `/config` — set to host user running the service |
| `PGID` | `1000` | Group ID — set to match host user's group |
| `TZ` | `Etc/UTC` | Timezone for logs and time display |
| `ALLOW_INTERNAL_REQUESTS` | `false` | Allow Heimdall to make lookup requests to private/reserved IP addresses. Set `true` only if the instance is not exposed to the internet or is behind auth. |

### Data directory

| Path (container) | Host mount | Contents |
|---|---|---|
| `/config` | `/path/to/heimdall/config` | App database (SQLite), NGINX config, user-uploaded icons |

`/config` is the only persistent data that needs to be backed up.

### Password protection (htpasswd)

Heimdall does not include authentication out of the box. To add HTTP Basic Auth:

```bash
# 1. Generate htpasswd file (while container is running)
docker exec -it heimdall htpasswd -c /config/nginx/.htpasswd <username>
# Enter password when prompted

# 2. Enable basic auth in NGINX config
#    Edit /config/nginx/site-confs/default.conf
#    Uncomment the "basic auth" lines

# 3. Restart the container
docker compose restart heimdall
```

### Ports

| Port | Protocol | Function |
|---|---|---|
| `80` | HTTP | Web UI |
| `443` | HTTPS | Web UI (TLS) |

To avoid binding to host ports 80/443 (if another service uses them), remap: e.g. `8080:80` and `8443:443`, then put a reverse proxy in front.

## Upgrade procedure

```bash
cd /opt/heimdall

# Via Docker Compose
docker compose pull heimdall
docker compose up -d heimdall
docker image prune   # clean up old images

# Or pull individually
docker pull lscr.io/linuxserver/heimdall:latest
docker stop heimdall && docker rm heimdall
# Re-run with same -v /config mapping
```

The `/config` volume persists across container replacements — data is preserved automatically.

## Gotchas

- **No auth by default.** Heimdall exposes a fully open dashboard to anyone who can reach the port. Either use the htpasswd method above, put it behind a reverse proxy with auth, or restrict access via firewall/VPN.
- **`ALLOW_INTERNAL_REQUESTS=false` by default.** This blocks Heimdall from reaching private IPs for Enhanced App status checks. If Heimdall can't see your apps (e.g. on a local network), set `true` — but only if the Heimdall instance itself is not publicly exposed.
- **PUID/PGID mismatch causes permission errors.** If `/config` on the host is owned by root but PUID is `1000`, Heimdall can't write its database. Ensure the host directory owner matches PUID/PGID.
- **TLS (443) uses a self-signed cert by default.** For a trusted cert, put a TLS-terminating reverse proxy (Caddy, nginx + Let's Encrypt) in front and remap port `80` internally.
- **Version tags.** `latest` = stable Heimdall releases. `development` = latest commit from the 2.x branch (may be unstable).
- **LinuxServer.io image, not a plain upstream image.** The GitHub repo at `linuxserver/Heimdall` is the app source; the Docker image is at `linuxserver/docker-heimdall`. The `lscr.io/linuxserver/heimdall` image is the correct production image.

## Upstream docs

- LinuxServer.io Docker image docs: <https://docs.linuxserver.io/images/docker-heimdall>
- App GitHub repo: <https://github.com/linuxserver/Heimdall>
- Docker image repo: <https://github.com/linuxserver/docker-heimdall>
- heimdall.site: <https://heimdall.site>
