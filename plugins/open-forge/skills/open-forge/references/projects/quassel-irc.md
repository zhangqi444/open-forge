---
name: quassel-irc
description: Recipe for Quassel IRC — a distributed IRC client where one or more graphical clients attach to a persistent central core (quasselcore). C++ + SQLite/PostgreSQL + Docker.
---

# Quassel IRC

Distributed IRC client. A central daemon (`quasselcore`) stays connected to IRC 24/7 and stores all messages; graphical clients (`quasselclient`) on any device connect to it and detach freely. Like ZNC but with a full GUI client included. Upstream: <https://github.com/quassel/quassel>. Website: <https://quassel-irc.org/>.

License: GPL-2.0. Platform: C++, Docker. Latest stable: 0.14.0 (2022). Low recent activity but stable.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (linuxserver/quassel-core) | Recommended for running the core (deprecated image, still works) |
| Package manager (apt/pacman) | Native install on Linux servers |
| Build from source | For latest code |

## Architecture

| Component | Role |
|---|---|
| `quasselcore` | Server-side daemon, stays connected to IRC, stores backlog |
| `quasselclient` | Desktop GUI client — connects to `quasselcore` from any machine |

Run `quasselcore` on your server; install `quasselclient` on your laptop/desktop.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Port for quasselcore to listen on?" | Default `4242` |
| db | "Database backend: SQLite (default) or PostgreSQL?" | SQLite fine for personal use; PostgreSQL for multi-user |
| db | "PostgreSQL host/user/password?" | Only if using PostgreSQL |
| auth | "Initial admin username and password?" | Set via setup wizard on first client connect |

## Docker (linuxserver/quassel-core)

> ⚠️ LinuxServer's `quassel-core` Docker image is deprecated but still widely used and functional.

`docker-compose.yml`:
```yaml
services:
  quassel-core:
    image: linuxserver/quassel-core:latest
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      # Optional: PostgreSQL backend instead of SQLite
      # - DB_BACKEND=PostgreSQL
      # - DB_PGSQL_HOST=postgres
      # - DB_PGSQL_PORT=5432
      # - DB_PGSQL_USER=quassel
      # - DB_PGSQL_PASSWORD=strongpassword
      # - DB_PGSQL_DATABASE=quassel
    volumes:
      - ./config:/config
    ports:
      - "4242:4242"
    restart: unless-stopped
```

```bash
docker compose up -d
```

On first run, open `quasselclient` on your desktop and connect to `your-server:4242`. A setup wizard will ask you to create the initial admin user and choose database backend.

## Package manager install (Debian/Ubuntu)

```bash
# Install the core (server)
sudo apt install quasselcore

# Configure
sudo systemctl enable --now quasselcore
# Default config dir: /var/lib/quassel
```

## Adding users (after initial setup)

```bash
quasselcore --add-user
# Follow the interactive prompts
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config dir | `/config` (Docker) or `/var/lib/quassel/` (native) |
| Database | SQLite (default) at `/config/quassel-storage.sqlite`; or PostgreSQL |
| Default port | `4242` (TCP) — must be accessible from client machines |
| TLS | Quassel generates a self-signed cert on first run; clients will warn once |
| Client download | <https://quassel-irc.org/downloads> — available for Windows, macOS, Linux |
| Multi-user | Multiple users can have separate IRC identities on the same core |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

For native installs: `sudo apt upgrade quasselcore`

Database migrations are applied automatically on startup.

## Gotchas

- **Client required for setup**: `quasselcore` has no web UI. You must connect with the `quasselclient` desktop app to complete initial configuration.
- **Self-signed TLS**: Quassel generates its own TLS certificate. Clients will prompt you to accept it on first connect — this is expected. For production, replace with a proper cert in the config dir.
- **LinuxServer image is deprecated**: The official LinuxServer image is marked deprecated as of 2023. It still works, but may not receive updates. Consider building from source or using the upstream Debian packages for long-term deployments.
- **quasselcore version must match quasselclient**: Mismatched protocol versions between core and client can cause connection failures. Upgrade both together.
- **PostgreSQL for multi-user**: SQLite is fine for one user, but under concurrent multi-user load, PostgreSQL is more reliable. Switching backends later requires an export/import step.
- **0.14.0 is from 2022**: The project is in maintenance mode with occasional commits but no major releases. It is stable for existing use cases.

## Upstream links

- Source: <https://github.com/quassel/quassel>
- Website/downloads: <https://quassel-irc.org/>
- Docker image: <https://github.com/linuxserver/docker-quassel-core>
- Wiki/docs: <https://bugs.quassel-irc.org/projects/quassel-irc/wiki>
