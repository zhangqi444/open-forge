---
name: focalboard-project
description: Focalboard recipe for open-forge. Open-source project management tool (Trello/Notion/Asana alternative) built on Go. Covers Personal Server (Docker/binary) and Mattermost plugin options. Derived from https://github.com/mattermost/focalboard and https://www.focalboard.com/docs/personal-edition/ubuntu/.
---

# Focalboard

Open-source, self-hosted project management tool. Upstream: <https://github.com/mattermost/focalboard>. License: MIT/Apache-2.0.

Focalboard is an alternative to Trello, Notion, and Asana. It comes in two variants: a standalone Personal Server for teams, and a Mattermost plugin (boards) for Mattermost workspaces.

**Note**: As of 2024, the standalone focalboard repository is no longer actively maintained by Mattermost. The actively developed version is the Mattermost Boards plugin at <https://github.com/mattermost/mattermost-plugin-boards>. The standalone server still works for existing installs.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Personal Server (binary, Ubuntu) | <https://www.focalboard.com/download/personal-edition/ubuntu/> | yes | Standalone multi-user server. Runs on Ubuntu directly. |
| Docker | <https://hub.docker.com/r/mattermost/focalboard> | yes | Containerized standalone server. |
| Mattermost plugin (Boards) | <https://github.com/mattermost/mattermost-plugin-boards> | yes | Integrated with Mattermost. Actively maintained. Recommended for new installs. |
| Desktop app | <https://www.focalboard.com/download/personal-edition/desktop/> | yes | Single-user local app (no server). Windows/Mac/Linux. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Standalone server or Mattermost plugin?" | Standalone / Mattermost plugin | Drives method selection. |
| preflight | "What port should Focalboard listen on?" | Integer default 8000 | Configured in config.json. |
| config | "Database backend?" | options: SQLite3 / PostgreSQL | SQLite3 is default (single-file). PostgreSQL for multi-user production. |
| config | "PostgreSQL connection string?" | e.g. user=focalboard dbname=focalboard sslmode=disable | Only if PostgreSQL selected. |
| config | "Enable telemetry?" | Yes / No default Yes | Set telemetry in config.json. |

## Docker install

Upstream: <https://hub.docker.com/r/mattermost/focalboard>

### docker-compose.yml (SQLite3, single-node)

```yaml
services:
  focalboard:
    image: mattermost/focalboard:latest
    ports:
      - "8000:8000"
    volumes:
      - focalboard-data:/opt/focalboard/data
    restart: unless-stopped

volumes:
  focalboard-data:
```

### Deploy steps

```bash
docker compose up -d
```

Access at http://localhost:8000. Register the first user account.

### Custom config.json

The default config is embedded in the image. To override, mount a custom config.json:

```json
{
  "serverRoot": "http://localhost:8000",
  "port": 8000,
  "dbtype": "sqlite3",
  "dbconfig": "./focalboard.db?_busy_timeout=5000",
  "useSSL": false,
  "webpath": "./webapp/pack",
  "filesdriver": "local",
  "filespath": "./files",
  "telemetry": true,
  "enableLocalMode": true,
  "localModeSocketLocation": "/var/tmp/focalboard_local.socket"
}
```

For PostgreSQL, change:
```json
  "dbtype": "postgres",
  "dbconfig": "dbname=focalboard sslmode=disable host=db user=focalboard password=secret",
```

## Personal Server (Ubuntu binary)

Upstream: <https://www.focalboard.com/download/personal-edition/ubuntu/>

```bash
# Download latest release from https://github.com/mattermost/focalboard/releases
wget https://github.com/mattermost/focalboard/releases/download/v7.11.4/focalboard-server-linux-amd64.tar.gz
tar -xvzf focalboard-server-linux-amd64.tar.gz
# Move to /opt and run
sudo mv focalboard /opt/focalboard
# Create systemd service and run
```

See upstream Ubuntu guide for full systemd service setup.

## Software-layer concerns

### Ports

| Port | Use |
|---|---|
| 8000 | Web UI and API (HTTP) |
| 9092 | Prometheus metrics (if enabled) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /opt/focalboard/data | SQLite database and uploaded files |

### Database

- Default: SQLite3 at ./focalboard.db — fine for single-user or small teams
- PostgreSQL: set dbtype to postgres and dbconfig to a valid connection string
- No automatic migrations between major versions — check release notes before upgrading

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

For binary installs, download the new release tarball and replace the binary. Back up the data directory first.

## Gotchas

- **Maintenance status**: The standalone focalboard repository is not actively maintained. For new production deployments, the Mattermost Boards plugin is preferred.
- **Single-user mode**: By default, the server allows anyone to register. Consider firewalling port 8000 and using a reverse proxy with auth if exposing publicly.
- **SQLite concurrency**: SQLite works fine for small teams but degrades under concurrent write load. Switch to PostgreSQL for teams of 10+.
- **Reverse proxy**: For public exposure, place behind NGINX/Caddy for TLS. Set serverRoot in config.json to the public HTTPS URL.
- **File uploads**: Uploaded files are stored alongside the database in the data directory. Include them in backups.

## Links

- GitHub (standalone): <https://github.com/mattermost/focalboard>
- GitHub (Mattermost plugin - actively maintained): <https://github.com/mattermost/mattermost-plugin-boards>
- Docker Hub: <https://hub.docker.com/r/mattermost/focalboard>
- Personal Server Ubuntu install: <https://www.focalboard.com/download/personal-edition/ubuntu/>
