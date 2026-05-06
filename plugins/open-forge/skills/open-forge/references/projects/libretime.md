---
name: libretime
description: Recipe for LibreTime — an open-source broadcast streaming radio platform (fork of Airtime). Covers Docker Compose and native Ubuntu install methods.
---

# LibreTime

Open-source broadcast radio automation and streaming platform. Fork of Sourcefabric Airtime. Allows scheduling audio content, managing playlists, live assist, and streaming via Icecast/Shoutcast. Upstream: <https://github.com/LibreTime/libretime>. Docs: <https://libretime.org/docs/>.

Latest release: v4.5.0. License: AGPL-3.0.

LibreTime is a multi-container application: API backend, legacy PHP frontend, playout engine (Liquidsoap), file analyzer, and Icecast streaming server. Default web port: `8080`.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended for evaluation and production on containerised hosts |
| Ubuntu native install | Recommended for production bare-metal/VM broadcast stations |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Install method: Docker Compose or Ubuntu native?" | Drives section |
| network | "Public URL for LibreTime (e.g. `http://radio.example.com`)?" | Used in `config.yml` as `general.public_url` |
| db | "PostgreSQL password for the libretime user?" | Default in compose is `libretime` — change it |
| streaming | "Icecast source/admin/relay passwords?" | Change all three from the defaults (`hackme`) |
| smtp | "SMTP credentials for system emails?" | Optional but recommended for notifications |
| storage | "Path to your audio library on the host?" | Mount point for `/srv/libretime` |

## Docker Compose (recommended)

```bash
git clone https://github.com/LibreTime/libretime.git
cd libretime

# Copy example env file
cp .env.example .env
```

Edit `.env`:
```dotenv
POSTGRES_PASSWORD=strongpassword
LIBRETIME_VERSION=4.5.0
ICECAST_SOURCE_PASSWORD=changeme_source
ICECAST_ADMIN_PASSWORD=changeme_admin
ICECAST_RELAY_PASSWORD=changeme_relay
```

Create `config.yml` (based on the upstream template):
```yaml
general:
  public_url: http://radio.example.com:8080
  # Or your domain if behind reverse proxy

database:
  host: postgres
  port: 5432
  name: libretime
  user: libretime
  password: strongpassword

rabbitmq:
  host: rabbitmq
  port: 5672
  vhost: /libretime
  user: libretime
  password: libretime

storage:
  path: /srv/libretime
```

```bash
docker compose up -d
```

Web UI available at `http://your-host:8080`. Default credentials: `admin` / `admin` — **change immediately**.

### Key service ports

| Service | Port | Purpose |
|---|---|---|
| nginx (web UI) | `8080` | Main LibreTime web interface |
| Icecast | `8000` | Audio streaming endpoint for listeners |
| Liquidsoap | `8001`, `8002` | Live input ports |

## Ubuntu native install

```bash
# Prerequisites: Ubuntu 22.04 LTS
sudo apt update && sudo apt install -y curl

# Download and run the install script (check latest release tag)
curl -fsSL https://github.com/LibreTime/libretime/releases/download/4.5.0/libretime-4.5.0.tar.gz | tar xz
cd libretime-4.5.0

sudo ./install --listen-port 8080
```

The installer will:
1. Install system dependencies (Apache, PHP, PostgreSQL, RabbitMQ, Liquidsoap, Icecast2)
2. Create the `libretime` database user
3. Set up systemd services for all components
4. Configure Apache virtual host on port 8080

Post-install configuration in `/etc/libretime/config.yml`.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | `/etc/libretime/config.yml` (native) or `./config.yml` (Docker) |
| Audio storage | `/srv/libretime` — mount external volume here for large libraries |
| Logs | `docker compose logs -f <service>` or `/var/log/libretime/` (native) |
| Web port | `8080` |
| Icecast stream | `http://your-host:8000/stream` (default mount) |
| DB | PostgreSQL 15 (Docker) or system PostgreSQL (native) |
| Message broker | RabbitMQ (required for all deployments) |

## Systemd services (native install)

```
libretime-api        # REST API backend
libretime-legacy     # PHP legacy frontend
libretime-analyzer   # File analysis and import
libretime-playout    # Playout scheduling
libretime-worker     # Background task worker
```

```bash
sudo systemctl status libretime-api
sudo systemctl restart libretime-api
```

## Upgrade procedure

### Docker Compose

```bash
git pull
# Update LIBRETIME_VERSION in .env
docker compose pull
docker compose up -d
```

### Native

```bash
# Download new release tarball
curl -fsSL https://github.com/LibreTime/libretime/releases/download/<NEW_VERSION>/libretime-<NEW_VERSION>.tar.gz | tar xz
cd libretime-<NEW_VERSION>
sudo ./install --listen-port 8080
```

The installer runs database migrations automatically.

## Gotchas

- **RabbitMQ is required**: All LibreTime services communicate via RabbitMQ. If RabbitMQ is unhealthy, services will fail to start. Check RabbitMQ health first when troubleshooting.
- **Icecast passwords must be changed**: The defaults (`hackme`) are well-known and will be exploited. Change source, admin, and relay passwords before going live.
- **`general.public_url` must be correct**: Incorrect public URL breaks browser ↔ playout communication (e.g., live shows won't connect). Include port if not on 80/443.
- **Audio files must be in supported formats**: LibreTime supports MP3, OGG, AAC, FLAC. Ensure Liquidsoap can decode the format; unusual codecs may fail silently.
- **Storage volume**: Mount audio library storage (`/srv/libretime`) on fast storage with plenty of space before importing. Importing large libraries can take hours.
- **Systemd `nofile` limit**: The Docker Compose sets `ulimits.nofile: 1024` on playout containers — may need increasing for large schedules (`nofile: 65536`).
- **Legacy PHP frontend**: LibreTime still uses the legacy PHP-based frontend from Airtime. The UI is dated but functional. A modern replacement is in progress.
- **Liquidsoap version compatibility**: LibreTime pins specific Liquidsoap versions. Do not install system Liquidsoap independently; use the version bundled by LibreTime.

## Upstream links

- Source: <https://github.com/LibreTime/libretime>
- Docs: <https://libretime.org/docs/>
- Docker Compose install: <https://libretime.org/docs/admin-manual/install/install-using-docker/>
- Ubuntu install: <https://libretime.org/docs/admin-manual/install/install-using-the-installer/>
- Configuration reference: <https://libretime.org/docs/admin-manual/configuration/>
