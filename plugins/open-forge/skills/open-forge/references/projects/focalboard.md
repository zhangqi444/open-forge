---
name: focalboard-project
description: Focalboard recipe for open-forge. Open-source self-hosted project management tool (alternative to Trello/Notion/Asana). Covers Docker-based Personal Server deployment, configuration, and upgrade. Derived from https://github.com/mattermost/focalboard and https://www.focalboard.com/download/personal-edition/ubuntu/. Note: standalone Focalboard is no longer actively maintained; the Mattermost Boards plugin is the supported continuation.
---

# Focalboard

Open-source self-hosted project management tool. Upstream: <https://github.com/mattermost/focalboard>. Documentation: <https://www.focalboard.com/>. License: MIT / Apache 2.0 / AGPL 3.0.

Focalboard is an alternative to Trello, Notion, and Asana. It helps define, organize, track and manage work across individuals and teams using boards, cards, and views.

**Important**: The standalone Focalboard repository is no longer actively maintained. The continuation is the [Mattermost Boards plugin](https://github.com/mattermost/mattermost-plugin-boards). For new deployments, consider deploying full Mattermost instead. Existing standalone deployments continue to work.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker (Personal Server) | <https://hub.docker.com/r/mattermost/focalboard> | yes | Self-hosted multi-user server. SQLite or PostgreSQL backend. |
| Ubuntu binary | <https://www.focalboard.com/download/personal-edition/ubuntu/> | yes | Bare-metal Ubuntu install. |
| Desktop apps | <https://www.focalboard.com/download/personal-edition/desktop/> | yes | Single-user local app. No server needed. |
| Mattermost Boards plugin | <https://github.com/mattermost/mattermost-plugin-boards> | yes | Recommended for new deployments — integrated into Mattermost. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should Focalboard run on?" | Integer default 8000 | Web UI and API port. |
| config | "Use PostgreSQL or SQLite?" | PostgreSQL / SQLite | SQLite is fine for personal/small team; PostgreSQL for larger teams. |
| config | "PostgreSQL connection string?" | postgres://user:pass@host/db | Only if PostgreSQL selected. |

## Docker install

Upstream: <https://hub.docker.com/r/mattermost/focalboard>

### docker-compose.yml (with SQLite, simplest)

```yaml
services:
  focalboard:
    image: mattermost/focalboard:latest
    ports:
      - "8000:8000"
    volumes:
      - focalboard-data:/data
    restart: unless-stopped

volumes:
  focalboard-data:
```

### docker-compose.yml (with PostgreSQL)

```yaml
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: focalboard
      POSTGRES_PASSWORD: focalboard
      POSTGRES_DB: focalboard
    volumes:
      - focalboard-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "focalboard"]
      interval: 10s
      retries: 5
  focalboard:
    image: mattermost/focalboard:latest
    ports:
      - "8000:8000"
    environment:
      - FOCALBOARD_DB_TYPE=postgres
      - FOCALBOARD_DB_CONFIG=postgres://focalboard:focalboard@db/focalboard?sslmode=disable
    volumes:
      - focalboard-data:/data
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

volumes:
  focalboard-db:
  focalboard-data:
```

### Deploy steps

```bash
docker compose up -d
```

Access at http://localhost:8000. Register the first user account.

## Software-layer concerns

### Ports

| Port | Use |
|---|---|
| 8000 | Web UI and REST API |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /data | SQLite database and file uploads (SQLite mode) |

### config.json

Focalboard uses a config.json for advanced configuration. The Docker image supports environment variables for the most common settings; full config reference at <https://www.focalboard.com/guide/admin/>.

### Environment variables (Docker)

| Variable | Description |
|---|---|
| FOCALBOARD_DB_TYPE | sqlite or postgres |
| FOCALBOARD_DB_CONFIG | Database connection string |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Gotchas

- **Maintenance status**: Standalone Focalboard is not actively maintained. It still works but will not receive new features. For new production deployments, use Mattermost with the Boards plugin.
- **Port 8000 default**: The server listens on port 8000 by default. Configured in config.json (serverRoot, port fields).
- **SQLite for small teams**: SQLite works well for personal or small team use. Switch to PostgreSQL for teams with many concurrent users.
- **No built-in TLS**: Focalboard does not handle TLS itself. Use a reverse proxy (NGINX, Caddy) for HTTPS in production.
- **File uploads**: Uploaded files are stored relative to the data directory. Back up /data before upgrades.

## Links

- GitHub: <https://github.com/mattermost/focalboard>
- Mattermost Boards plugin (maintained): <https://github.com/mattermost/mattermost-plugin-boards>
- Docker Hub: <https://hub.docker.com/r/mattermost/focalboard>
- Admin guide: <https://www.focalboard.com/guide/admin/>
- Ubuntu install guide: <https://www.focalboard.com/download/personal-edition/ubuntu/>
