---
name: 4gaboards
description: 4ga Boards recipe for open-forge. Straightforward realtime kanban boards for project management. Dark mode, collapsable lists, SSO (Google/GitHub/Microsoft/OIDC), Trello import. Docker Compose + PostgreSQL. Derived from https://github.com/RARgames/4gaBoards and https://docs.4gaboards.com/.
---

# 4ga Boards

Straightforward realtime kanban boards for project management. Multi-level hierarchy (projects → boards → lists → cards → tasks), dark mode, Trello import, SSO, and multi-language support.

- Upstream repo: https://github.com/RARgames/4gaBoards
- Docs: https://docs.4gaboards.com/
- Docker Hub: https://ghcr.io/rargames/4gaboards
- License: MIT

## What it does

4ga Boards is a Planner/Trello-style kanban tool with a modern, wide-screen-friendly UI. It supports real-time updates (no page reload required), simultaneous editing of cards, markdown in card descriptions, card attachments, and project/board background images. Teams can sign in with Google, GitHub, Microsoft, or any OIDC provider. Boards can be exported and re-imported; Trello boards can be imported natively.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose (recommended) | https://docs.4gaboards.com/docs/dev/install/docker-install | yes | Standard self-host. PostgreSQL + app container. |
| Kubernetes | https://docs.4gaboards.com/docs/dev/install/k8s-install | yes | Helm-based cluster deploy. |
| TrueNAS | https://docs.4gaboards.com/docs/dev/install/truenas-install | yes | TrueNAS SCALE community chart. |
| Manual (Node.js) | https://docs.4gaboards.com/docs/dev/install/manual | yes | Bare-metal; requires Node.js. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | Web UI port? | Integer, default 3000 | Maps to host port (container listens on 1337). |
| preflight | Where should data be stored? | Path, default ./4gaboards-data | Used for Docker volume mounts. |
| config | BASE_URL? | URL, e.g. http://yourhost:3000 | Must include scheme and port; used for OAuth redirects and asset URLs. |
| config | SECRET_KEY? | String | Generate with openssl rand -hex 64. Never share or rotate without clearing sessions. |
| db | PostgreSQL password? | String | Set in POSTGRES_PASSWORD and DATABASE_URL. Use openssl rand -hex 16. |
| sso (optional) | SSO provider credentials? | Client ID + Secret per provider | Google, GitHub, Microsoft, OIDC. See docker-vars docs for env var names. |

## Install — Docker Compose

Source: https://docs.4gaboards.com/docs/dev/install/docker-install

```bash
# 1. Download the compose file
curl -L https://raw.githubusercontent.com/RARgames/4gaBoards/main/docker-compose.yml -o docker-compose.yml

# 2. Edit docker-compose.yml:
#    - Set BASE_URL to your domain/IP + port
#    - Replace SECRET_KEY with: openssl rand -hex 64
#    - Replace notpassword with a strong DB password in both POSTGRES_PASSWORD
#      and DATABASE_URL (postgresql://postgres:NEWPASS@db/4gaBoards)

# 3. Start
docker compose up -d
```

docker-compose.yml (full reference from upstream):

```yaml
services:
  db:
    image: postgres:16-alpine
    restart: always
    networks:
      - boards-network
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: 4gaBoards
      POSTGRES_PASSWORD: notpassword        # CHANGE THIS
      POSTGRES_INITDB_ARGS: '-A scram-sha-256'
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres -d 4gaBoards']
      interval: 5s
      timeout: 5s
      retries: 20

  4gaBoards:
    image: ghcr.io/rargames/4gaboards:latest
    restart: always
    networks:
      - boards-network
    volumes:
      - user-avatars:/app/public/user-avatars
      - project-background-images:/app/public/project-background-images
      - attachments:/app/private/attachments
    ports:
      - 3000:1337
    environment:
      BASE_URL: http://localhost:3000       # CHANGE TO YOUR URL
      SECRET_KEY: notsecretkey             # CHANGE TO: openssl rand -hex 64
      DATABASE_URL: postgresql://postgres:notpassword@db/4gaBoards   # update password
      NODE_ENV: production
    depends_on:
      db:
        condition: service_healthy

volumes:
  user-avatars:
  project-background-images:
  attachments:
  db-data:
networks:
  boards-network:
```

Access http://localhost:3000. Default credentials: `demo` / `demo`.

## Software-layer concerns

### Ports

| Port (host) | Port (container) | Use |
|---|---|---|
| 3000 (default) | 1337 | Web UI |

### Key environment variables

| Variable | Required | Notes |
|---|---|---|
| BASE_URL | yes | Full URL with scheme and port. Used for OAuth redirects, asset paths, and email links. Must match how users access the site. |
| SECRET_KEY | yes | Session/JWT secret. Generate with openssl rand -hex 64. Rotating it invalidates all active sessions. |
| DATABASE_URL | yes | PostgreSQL connection string: postgresql://postgres:PASSWORD@db/4gaBoards |
| NODE_ENV | yes | Set to production for production deploys. |

Full list of optional SSO and feature env vars: https://docs.4gaboards.com/docs/dev/install/docker-vars

### Data directories (Docker volumes)

| Volume | Contents |
|---|---|
| user-avatars | User profile images |
| project-background-images | Board/project background images |
| attachments | Card attachments (private, not web-served directly) |
| db-data | PostgreSQL data files |

## Backup and restore

Upstream provides backup/restore scripts in the repository. Run these from the directory containing docker-compose.yml:

```bash
# Backup
curl -L https://raw.githubusercontent.com/RARgames/4gaBoards/main/boards-backup.sh -o boards-backup.sh
chmod +x boards-backup.sh
./boards-backup.sh
# Produces: 4gaBoards-backup.tgz

# Restore
curl -L https://raw.githubusercontent.com/RARgames/4gaBoards/main/boards-restore.sh -o boards-restore.sh
chmod +x boards-restore.sh
./boards-restore.sh 4gaBoards-backup.tgz
```

If restoring with a different database password than the one in the backup, you must comment out the ALTER ROLE line inside the postgres.sql file inside the backup archive before restoring.

## Upgrade procedure

1. Check release notes: https://github.com/RARgames/4gaBoards/releases
2. Back up first (see Backup section above).
3. Pull the new image and restart:
   ```bash
   docker compose pull 4gaBoards
   docker compose up -d 4gaBoards
   ```
4. Database migrations run automatically on container start. Check logs:
   ```bash
   docker compose logs -f 4gaBoards
   ```
5. If pinning a specific version, update `ghcr.io/rargames/4gaboards:latest` to `ghcr.io/rargames/4gaboards:vX.Y.Z`.

## Importing from Trello

Trello import is built in. After creating a project, click "Import" when creating a new board and select the Trello JSON export.

## Gotchas

- **Change default credentials immediately.** Default user is demo/demo — change or delete this account before exposing the instance publicly.
- **BASE_URL must exactly match how you access the app.** OAuth SSO redirects will fail if BASE_URL is wrong (e.g., http vs https, missing port). Include the full scheme, host, and port.
- **SECRET_KEY rotation invalidates all sessions.** Users will be logged out when you change SECRET_KEY. Plan for a maintenance window if rotating in production.
- **POSTGRES_PASSWORD in DATABASE_URL must match.** The compose file has the password in two places — POSTGRES_PASSWORD in the db service and inside the DATABASE_URL connection string. Keep them in sync.
- **latest tag.** The default compose file uses :latest. In production, pin to a specific release tag (e.g., ghcr.io/rargames/4gaboards:v3.3.6) so upgrades are deliberate.
- **No built-in TLS.** The container serves plain HTTP on port 1337. Place a reverse proxy (Caddy, nginx, Traefik) in front for HTTPS in production.
- **Attachment volume.** The attachments volume is mapped to /app/private/attachments — it is not served statically by the web server. Ensure this volume is included in your backup strategy.

## Links

- Repo: https://github.com/RARgames/4gaBoards
- Docs: https://docs.4gaboards.com/
- Docker install guide: https://docs.4gaboards.com/docs/dev/install/docker-install
- Docker env vars reference: https://docs.4gaboards.com/docs/dev/install/docker-vars
- Releases: https://github.com/RARgames/4gaBoards/releases
- GHCR image: https://ghcr.io/rargames/4gaboards
