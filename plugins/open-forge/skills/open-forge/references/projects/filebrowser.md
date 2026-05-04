---
name: filebrowser
description: File Browser recipe for open-forge. Web-based file manager for a directory on your server. Two image variants: bare Alpine (filebrowser/filebrowser) and S6 overlay with PUID/PGID support (filebrowser/filebrowser:s6). No external DB — uses a single SQLite file. Upstream: https://github.com/filebrowser/filebrowser. Docs: https://filebrowser.org.
---

# File Browser

Web-based file manager that lets you browse, upload, download, and manage files in a server directory through a clean browser UI. 34k★ on GitHub. Upstream: <https://github.com/filebrowser/filebrowser>. Docs: <https://filebrowser.org>. Docker Hub: <https://hub.docker.com/r/filebrowser/filebrowser>.

> **Project status:** File Browser is **maintenance-only** — security fixes are applied, but no new features are being developed. It remains widely used and stable for its core use case.

File Browser exposes port `80` inside the container (mapped to your chosen host port, commonly `8080`). It uses a single SQLite database file for all state — no separate DB service needed.

## Image variants

| Image | Tag | When to use |
|---|---|---|
| `filebrowser/filebrowser` | `latest` / `s6` | Bare Alpine — minimal, default |
| `filebrowser/filebrowser` | `s6` | S6 init overlay — supports `PUID`/`PGID` env vars for correct file ownership |

Use the `:s6` tag when you need the container process to run as a specific UID/GID (e.g. to match a NAS user or avoid permission issues on bind-mounted directories).

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which image variant?" | `AskUserQuestion`: `latest (bare Alpine)` / `s6 (PUID/PGID support)` | Default: `latest`. |
| paths | "Which host directory should File Browser serve?" | Free-text path | Mounted at `/srv` in container. This is the root of what users can browse. |
| uid | "What UID/GID should the container run as?" | Free-text | `:s6` only — sets `PUID` / `PGID`. Skip for `latest`. |
| port | "Which host port should File Browser listen on?" | Free-text | Default: `8080`. Maps to container port `80`. |

## Compose (bare Alpine)

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser
    ports:
      - "8080:80"
    volumes:
      - /path/to/files:/srv
      - filebrowser_database:/database
      - filebrowser_config:/config
    restart: unless-stopped

volumes:
  filebrowser_database:
  filebrowser_config:
```

## Compose (S6 overlay — PUID/PGID)

```yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:s6
    ports:
      - "8080:80"
    environment:
      PUID: "1000"
      PGID: "1000"
    volumes:
      - /path/to/files:/srv
      - filebrowser_config:/config
      - filebrowser_database:/database
    restart: unless-stopped

volumes:
  filebrowser_config:
  filebrowser_database:
```

## Volumes

| Mount path (container) | Purpose | Notes |
|---|---|---|
| `/srv` | Files to manage | Bind-mount the host directory you want to expose. Must be readable (and writable if uploads are allowed) by the container UID. |
| `/database` | SQLite database file | Stores users, settings, shares. Use a named volume or bind-mount to persist across container recreates. |
| `/config` | Config file (`settings.json`) | Optional — File Browser writes a default config here on first start. |

## First boot

On first start, File Browser auto-generates an admin account. **The generated admin password is printed once to container logs and never shown again.**

```bash
# Retrieve the generated password immediately after first start
docker compose logs filebrowser | grep -i password
```

Then open `http://localhost:8080` and log in with `admin` / `<generated-password>`. Change the password immediately.

## CLI reference

File Browser ships a CLI for headless configuration. Run it inside the container:

```bash
# Open a shell in the running container
docker compose exec filebrowser /bin/sh

# Key CLI commands (run inside the container, or via docker exec)
filebrowser config set --auth.method=noauth          # disable login (trusted LAN only)
filebrowser config set --signup=false                # disable self-registration
filebrowser config set --root=/srv                   # set root directory
filebrowser users add <username> <password> --perm.admin  # add an admin user
filebrowser users rm <username>                      # remove a user
filebrowser help                                     # full command list
```

Or run one-shot commands without opening a shell:

```bash
docker compose exec filebrowser filebrowser users add bob s3cr3t
```

## Verify

```bash
# Check container is running
docker compose ps

# Check logs for errors or the initial admin password
docker compose logs filebrowser

# HTTP check
curl -sI "http://localhost:8080/"    # → 200 or redirect to /login
```

## Lifecycle

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Update image
docker compose pull
docker compose up -d

# View logs
docker compose logs -f filebrowser
```

## Gotchas

- **Generated admin password shown only once.** It's printed to logs on first start only. If you miss it, delete the `filebrowser_database` volume to reset (all users/settings/shares will be lost) and let File Browser regenerate.
- **Bind-mounted /srv must be owned by UID 1000 / GID 1000** (or whatever UID the container runs as). With the bare Alpine image this is UID 1000 by default; with `:s6` it matches your `PUID`/`PGID`. If the container can't read `/srv`, the file list will be empty or throw permission errors.
  ```bash
  # Fix ownership on the host directory
  sudo chown -R 1000:1000 /path/to/files
  ```
- **No built-in auth hardening beyond username/password.** File Browser has no 2FA, rate limiting, or IP allow-listing. Put it behind a reverse proxy (Caddy, Nginx Proxy Manager, Traefik) with HTTPS and optionally an additional auth layer for any internet-facing deployment.
- **Maintenance-only project.** Security patches are applied, but feature requests are not being implemented. It's stable for its current feature set — just don't expect new capabilities.
- **Named volumes vs bind mounts for /database.** Named volumes (as shown above) are simpler; bind mounts give you a predictable host path for backups. Either works — just be consistent and don't mix across recreates.
