---
name: lms
description: LMS (Lightweight Music Server) recipe for open-forge. Covers Docker (recommended), Debian/Ubuntu packages, and build-from-source install methods as documented in https://github.com/epoupon/lms/blob/master/INSTALL.md and the Docker Hub page.
---

# LMS — Lightweight Music Server

Self-hosted music streaming server built on C++/Boost/Wt. Streams personal music libraries, supports multi-user access, scrobbling, and playlists. Upstream: <https://github.com/epoupon/lms>. License: GPL-3.0.

LMS listens on port `5082` by default. What varies across install methods is whether you run the official Docker image (simplest, recommended), install from a prebuilt Debian/Ubuntu `.deb` package, or compile from source. All methods use the same config file format and data directory layout.

## Compatible install methods

Verified against upstream's `INSTALL.md` and Docker Hub page.

| Method | Upstream | When to use |
|---|---|---|
| Docker | <https://hub.docker.com/r/epoupon/lms> | Recommended — minimal host dependencies, cross-distro |
| Debian/Ubuntu package | INSTALL.md §Debian/Ubuntu | When you prefer native packages over containers |
| Build from source | INSTALL.md §Build | For custom builds or unsupported distros |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method?" | docker / deb / source | Drives method section |
| volume | "Path to store LMS persistent data (database, config, cache)?" | Host path | E.g. /srv/lms |
| music | "Path to your music library on the host?" | Host path | Mounted read-only |
| port | "Which host port should LMS listen on?" | Number | Default 5082 |
| user | "User ID and group ID to run LMS as (UID:GID)?" | UID:GID | Avoids permission issues with music files |
| tls | "Front LMS with a reverse proxy for HTTPS?" | Yes / No | LMS itself has no TLS |

## Software-layer concerns

### Config file

LMS uses a config file at `/etc/lms.conf` (or a custom path passed as argument). Default values are conservative and sane. Key settings when running behind a reverse proxy:

- `listen-addr` and `listen-port` — bind to localhost if reverse-proxied
- `behind-reverse-proxy = true` — trust `X-Forwarded-*` headers from the proxy

Default config: <https://github.com/epoupon/lms/blob/master/conf/lms.conf>

### Data directory

| Content | Container path |
|---|---|
| SQLite database | `/var/lms/lms.db` |
| Optional custom config | `/var/lms/lms.conf` |
| Transcoding cache | `/var/lms/cache/` |

Mount `/var/lms` as a persistent volume. This path needs write access.

### Music directory

Mount music at `/music` (read-only). After first launch, add `/music` as a library from the LMS admin interface: **Settings → Libraries → Add**. Multiple mount points can serve multiple libraries.

## Method — Docker

> **Source:** <https://hub.docker.com/r/epoupon/lms>

### Quick start

```bash
docker run \
  --restart=unless-stopped \
  --user <user_id:group_id> \
  -p <host_port>:5082 \
  -v <path_to_music>:/music:ro \
  -v <path_to_persistent_data>:/var/lms:rw \
  epoupon/lms
```

### Docker Compose

```yaml
services:
  lms:
    image: epoupon/lms:latest
    restart: unless-stopped
    user: "${LMS_UID}:${LMS_GID}"
    ports:
      - "${LMS_PORT:-5082}:5082"
    volumes:
      - "${MUSIC_PATH}:/music:ro"
      - "${DATA_PATH}:/var/lms:rw"
```

`.env` file:
```
LMS_UID=1000
LMS_GID=1000
LMS_PORT=5082
MUSIC_PATH=/path/to/your/music
DATA_PATH=/srv/lms
```

```bash
docker compose up -d
docker compose logs -f lms
```

### Custom config file

```bash
# Place config in the data directory
curl -o /srv/lms/lms.conf \
  https://raw.githubusercontent.com/epoupon/lms/master/conf/lms.conf
# Edit, then pass as argument:
docker run ... epoupon/lms /var/lms/lms.conf
```

### Verify

Open `http://<host>:<port>` — the LMS web UI should load. Create an admin account on first access. Then go to **Settings → Libraries** and add `/music` to start scanning.

## Method — Debian/Ubuntu package

> **Source:** <https://github.com/epoupon/lms/blob/master/INSTALL.md>

```bash
curl -fsSL https://lms.poupon.fr/repo.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/lms.gpg
echo "deb [signed-by=/etc/apt/keyrings/lms.gpg] https://lms.poupon.fr bookworm main" \
  | sudo tee /etc/apt/sources.list.d/lms.list
sudo apt update && sudo apt install lms
sudo systemctl enable --now lms
```

Config lives at `/etc/lms.conf`; data at `/var/lib/lms/`. Access at `http://localhost:5082`.

## Upgrade procedure

### Docker

```bash
docker pull epoupon/lms:latest
docker compose down && docker compose up -d
```

LMS performs automatic database migrations on startup — no manual migration step required.

### Debian/Ubuntu package

```bash
sudo apt update && sudo apt upgrade lms
sudo systemctl restart lms
```

## Gotchas

- **User ownership matters.** Run LMS with `--user UID:GID` matching the owner of the music files. Without this, LMS defaults to root and may write root-owned files into the volume.
- **First-run scan takes time.** The initial library scan can take minutes to hours depending on size. The UI remains accessible during scanning.
- **`behind-reverse-proxy = true` is required when using a reverse proxy.** Without this setting, LMS won't trust `X-Forwarded-Proto` and may produce incorrect redirects.
- **No TLS in the LMS image.** Use Caddy, nginx, or Traefik to add HTTPS. Bind `listen-addr = 127.0.0.1` when only accessed via a proxy.
- **Jukebox mode (direct audio output) requires PulseAudio on the host.** Not available on headless servers. Pass `-e PULSE_SERVER=unix:/run/user/<uid>/pulse/native` and the corresponding volume mount to enable it.
- **Do not change UIDs after first run** — the SQLite database and cache files will be owned by the original UID; changing it will break file access.

## Links

- GitHub: <https://github.com/epoupon/lms>
- INSTALL.md: <https://github.com/epoupon/lms/blob/master/INSTALL.md>
- Docker Hub: <https://hub.docker.com/r/epoupon/lms>
- Default config: <https://github.com/epoupon/lms/blob/master/conf/lms.conf>
- Subsonic API compatibility: <https://github.com/epoupon/lms/blob/master/SUBSONIC.md>
