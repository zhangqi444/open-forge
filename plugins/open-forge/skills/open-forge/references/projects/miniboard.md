---
name: miniboard
description: Recipe for Miniboard — lightweight Go dashboard with tabs, uptime monitoring, and notifications. Configurable via GUI or YAML. Docker single-container, SQLite, optional auth. Also supports local network (offline) mode.
---

# Miniboard

Lightweight dashboard with tabs, uptime monitoring, and notifications. Upstream: https://github.com/aceberg/miniboard

Go binary + Bootstrap UI. Configure service bookmarks organized by tabs and panels — either through the web GUI or a YAML config file. Built-in uptime monitor tracks host availability and stores history in SQLite. Optional session-cookie authentication. Supports an offline/local-network mode (no CDN dependencies).

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — single container, data in mounted volume |
| Docker run | Supported — see quick start |
| Binary install | Pre-built binaries available (see docs/INSTALL-BIN.md) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Timezone (TZ) | e.g. America/New_York — for uptime monitor timestamps |
| preflight | Data directory | Host path for board.yaml, config.yaml, uptime.db |
| auth (opt) | AUTH_USER + AUTH_PASSWORD | Enable session-cookie auth; password must be bcrypt-hashed |
| theme (opt) | THEME | Any Bootswatch theme name in lowercase (default: flatly) |

## Software-layer concerns

**Config:** Environment variables or config.yaml. All settings can also be changed via the web GUI.

**Key env vars:**
| Var | Default | Description |
|---|---|---|
| TZ | "" | Timezone for uptime monitor |
| PORT | 8849 | Web GUI port |
| HOST | 0.0.0.0 | Listen address |
| AUTH | false | Enable session-cookie authentication |
| AUTH_USER | "" | Username (if AUTH=true) |
| AUTH_PASSWORD | "" | bcrypt-hashed password (if AUTH=true) |
| AUTH_EXPIRE | 7d | Session expiration (m/h/d/M suffix) |
| THEME | flatly | Bootswatch theme name |
| COLOR | dark | Background: light or dark |
| WEBREFRESH | 60 | Uptime/tab page refresh interval (seconds) |
| DBTRIMDAYS | 30 | Days to keep uptime history |

**Data:** Three files in the data directory:
- `board.yaml` — dashboard layout (tabs, panels, hosts)
- `config.yaml` — app settings
- `uptime.db` — SQLite uptime history

**Docker socket (optional):** Mount `/var/run/docker.sock` only if you want to auto-create panels from running Docker containers via the Edit panels page.

**Offline mode:** By default, Miniboard loads themes, icons, and fonts from CDNs. For fully offline/air-gapped use, run the companion `aceberg/node-bootstrap` container and pass `-n http://<node-bootstrap-ip>:8850`.

## Docker Compose

```yaml
services:
  miniboard:
    image: aceberg/miniboard
    restart: unless-stopped
    ports:
      - "8849:8849"
    environment:
      - TZ=America/New_York
      - THEME=flatly
      - COLOR=dark
    volumes:
      - ~/.dockerdata/miniboard:/data/miniboard
      # Optional: for auto-creating panels from Docker containers
      # - /var/run/docker.sock:/var/run/docker.sock
```

First run creates the data directory and default config files. Open http://localhost:8849 and configure via GUI, or edit `~/.dockerdata/miniboard/board.yaml` directly.

## bcrypt password generation (if enabling AUTH)

```bash
docker run --rm aceberg/miniboard -bcrypt yourpassword
```

Set the output as AUTH_PASSWORD.

## Upgrade procedure

```bash
docker compose pull miniboard
docker compose up -d miniboard
```

Data volume is preserved. No manual migrations needed.

## Gotchas

- **AUTH disabled by default** — without AUTH=true, the dashboard is accessible to anyone on the network. Enable auth or restrict network access.
- **bcrypt required** — AUTH_PASSWORD must be a bcrypt hash, not a plaintext password.
- **Docker socket grants host access** — only mount the Docker socket if you need the auto-panel feature; it's not required for normal operation.
- **Offline mode needs companion container** — the `node-bootstrap` container must be running and accessible from the Miniboard container before starting Miniboard with `-n`.
- **board.yaml format** — see the commented example at https://github.com/aceberg/miniboard/blob/main/configs/board.yaml for the full schema.

## Links

- Upstream repository: https://github.com/aceberg/miniboard
- Docker Hub: https://hub.docker.com/r/aceberg/miniboard
- Binary install: https://github.com/aceberg/miniboard/blob/main/docs/INSTALL-BIN.md
- Example board.yaml: https://github.com/aceberg/miniboard/blob/main/configs/board.yaml
- Offline node-bootstrap image: https://github.com/aceberg/my-dockerfiles/tree/main/node-bootstrap
