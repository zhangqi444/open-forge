---
name: bytebase
description: Bytebase recipe for open-forge. Covers the Docker single-container deployment — the upstream-recommended self-hosted path. Bytebase is a database CI/CD and DevOps platform supporting schema migrations, SQL review, GitOps, and more.
---

# Bytebase

Database CI/CD and DevOps platform — schema migrations, SQL review policies, GitOps workflows for databases, data masking, RBAC, and audit logging. Supports PostgreSQL, MySQL, MongoDB, Redis, Snowflake, and many more. Upstream: <https://github.com/bytebase/bytebase>. Docs: <https://docs.bytebase.com/get-started/self-host-vs-cloud>.

Bytebase ships as a single self-contained binary (and Docker image) that bundles its own metadata store. No separate database is required to run Bytebase itself — data is persisted to a volume on the host.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://docs.bytebase.com/get-started/self-host-vs-cloud> | ✅ | Recommended self-hosted path. Zero external dependencies. |
| Docker Compose | <https://docs.bytebase.com/get-started/self-host-vs-cloud> | ✅ | Convenience wrapper around the single-container install. |
| Helm / Kubernetes | <https://docs.bytebase.com/get-started/self-host-vs-cloud> | ✅ | Production Kubernetes deployments. Out of scope for this recipe. |
| Bytebase Cloud (managed) | <https://docs.bytebase.com/get-started/self-host-vs-cloud> | ✅ | Hosted SaaS — no install. Out of scope. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Where should Bytebase store its data on the host?" | Free-text path (e.g. `~/.bytebase/data`) | Required — data volume mount |
| preflight | "What port should Bytebase expose on the host?" | Default `8080` | Required |
| preflight | "What is the external URL users will access Bytebase at?" | Free-text URL (e.g. `https://bytebase.example.com`) | Recommended — set with `--external-url` flag for correct links in notifications and webhooks |
| tls | "Is TLS termination handled by an upstream reverse proxy?" | `AskUserQuestion`: `Yes (Nginx/Traefik/Caddy)` / `No (direct access)` | Determines whether `--external-url` uses `https://` |
| databases | "Which databases will Bytebase manage? (list types: PostgreSQL, MySQL, etc.)" | Free-text | Informational — helps size the host and plan integrations |

## Method — Docker (single container)

> **Source:** <https://docs.bytebase.com/get-started/self-host-vs-cloud>
> **Image:** `bytebase/bytebase:latest`

A single container handles everything — the Bytebase backend, metadata store, and web UI. All state is persisted to `/var/opt/bytebase` inside the container, which is mounted from a host path or named volume.

### Config paths and volumes

| Host path | Container path | Purpose |
|---|---|---|
| `~/.bytebase/data` (or custom) | `/var/opt/bytebase` | All Bytebase data: metadata, migration history, configs |

### Startup flags

| Flag | Purpose | Notes |
|---|---|---|
| `--port` | Port to listen on inside the container | Default `8080` |
| `--external-url` | Canonical external URL | Used in email notifications, webhooks, OAuth redirects |
| `--data` | Data directory path inside the container | Default `/var/opt/bytebase` |
| `--pg` | External PostgreSQL DSN | Optional — use an external PG instead of the embedded store |

### Docker run (minimal)

```bash
docker run --init \
  --name bytebase \
  --publish 8080:8080 \
  --volume ~/.bytebase/data:/var/opt/bytebase \
  bytebase/bytebase:latest
```

Visit `http://localhost:8080` and follow the setup wizard to create the first admin account and workspace.

### Docker run (with external URL)

```bash
docker run --init \
  --name bytebase \
  --publish 8080:8080 \
  --volume ~/.bytebase/data:/var/opt/bytebase \
  bytebase/bytebase:latest \
  --external-url https://bytebase.example.com \
  --port 8080
```

### Compose example

```yaml
services:
  bytebase:
    image: bytebase/bytebase:latest
    init: true
    container_name: bytebase
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - bytebase-data:/var/opt/bytebase
    command:
      - --port
      - "8080"
      - --external-url
      - "https://bytebase.example.com"

volumes:
  bytebase-data:
```

### First-run setup wizard

After starting, open `http://<host>:8080`. The wizard collects:

1. Admin email and password (first user becomes workspace owner).
2. Workspace name.
3. Optional: connect the first database instance.

The wizard runs only once. If you need to re-run it, stop the container, delete the data volume, and restart (this wipes all data).

### Verify

```bash
# Container is running
docker ps | grep bytebase

# Health endpoint (returns 200 when ready)
curl -sf http://localhost:8080/healthz

# Follow logs during startup
docker logs -f bytebase
```

### Reverse proxy (Nginx example)

```nginx
server {
    listen 443 ssl;
    server_name bytebase.example.com;

    # TLS config here ...

    location / {
        proxy_pass         http://localhost:8080;
        proxy_set_header   Host              $host;
        proxy_set_header   X-Real-IP         $remote_addr;
        proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;

        # WebSocket support (required for real-time SQL editor)
        proxy_http_version 1.1;
        proxy_set_header   Upgrade    $http_upgrade;
        proxy_set_header   Connection "upgrade";
    }
}
```

### Lifecycle

```bash
# Stop
docker stop bytebase

# Start
docker start bytebase

# Remove container (data volume preserved)
docker rm bytebase

# Follow logs
docker logs -f bytebase

# Exec into container for debugging
docker exec -it bytebase /bin/sh
```

## Upgrade procedure

1. Stop the running container: `docker stop bytebase && docker rm bytebase`
2. Back up the data volume:
   ```bash
   tar czf bytebase-backup-$(date +%Y%m%d).tar.gz ~/.bytebase/data/
   ```
3. Pull the new image: `docker pull bytebase/bytebase:latest`
4. Start with the same flags and volume mount as before — Bytebase auto-migrates its internal schema on startup.
5. Verify the UI is accessible and check `docker logs bytebase` for migration success messages.

For Compose: `docker compose pull && docker compose up -d`.

## Gotchas

- **Data volume is the only backup target.** All Bytebase state lives in `/var/opt/bytebase`. Back up the host directory or named volume before upgrading or making major config changes. There is no separate DB to export.
- **`--external-url` is important for integrations.** Without it, email notifications, webhooks, OAuth callbacks, and GitOps webhook URLs will use `localhost` or an internal address, which breaks external integrations. Set it to the URL users actually type in their browser.
- **WebSocket support required for the SQL editor.** The interactive SQL editor in the Bytebase UI uses WebSockets. Ensure your reverse proxy is configured to upgrade connections (see the Nginx example above) — otherwise the editor appears to hang.
- **Schema migrations are automatic on upgrade.** Bytebase migrates its own internal schema when the new version starts. This generally succeeds silently, but always back up the data volume before upgrading.
- **First user created via wizard is the workspace owner.** Guard the first-run URL — anyone who accesses `http://<host>:8080` before setup completes can claim the workspace owner role. Complete setup immediately after starting the container.
- **Helm / Kubernetes deploys require a separate PostgreSQL.** The embedded store is not suitable for clustered Kubernetes deployments. Pass an external PG DSN via `--pg` for HA setups.
- **The `--init` flag (or `init: true` in Compose) is required.** Without PID 1 init handling, zombie processes from SQL sessions may accumulate. The upstream `docker run` example always includes `--init`.

---

> 📖 Upstream docs: <https://docs.bytebase.com/get-started/self-host-vs-cloud>
> 🐙 GitHub: <https://github.com/bytebase/bytebase>
