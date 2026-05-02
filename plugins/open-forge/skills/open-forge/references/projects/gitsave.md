---
name: gitsave-project
description: GitSave recipe for open-forge. Covers Docker and Docker Compose deployment of this Git repository backup scheduler with web UI. Based on upstream README at https://github.com/TimWitzdam/GitSave.
---

# GitSave

Scheduled Git repository backup tool with a responsive web interface. Backs up repositories from GitHub, GitLab, or any Git host on a configurable schedule; supports SMB share as a backup target. Upstream: <https://github.com/TimWitzdam/GitSave>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host / VPS | Docker (single container) | Official method; image `timwitzdam/gitsave:latest` |
| Any Linux host / VPS | Docker Compose | Compose file provided in upstream README |
| Windows / macOS (dev) | Docker Desktop | Same image; not recommended for production |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| deploy | "Domain or IP + port for GitSave?" | Free-text | Default port `3000`; put behind reverse proxy for production |
| secrets | "JWT secret for session tokens?" | Free-text (32+ chars) | Generate with a JWT secret generator; set as `JWT_SECRET` |
| secrets | "Encryption secret (exactly 32 characters)?" | Free-text | Set as `ENCRYPTION_SECRET`; used to encrypt stored credentials |
| auth | "Disable authentication? (not recommended for public deployments)" | Yes / No | Sets `DISABLE_AUTH=true/false` |
| storage | "Backup destination — local path or SMB share?" | Free-text | Local path maps to `./backups` in the container |

## Software-layer concerns

### Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `JWT_SECRET` | ✅ | — | Encrypts authentication tokens |
| `ENCRYPTION_SECRET` | ✅ | — | Must be exactly 32 characters; encrypts repo credentials |
| `DISABLE_AUTH` | ✅ | `false` | Set `true` to disable login (internal-only deployments) |

### Volumes

| Container path | Purpose |
|---|---|
| `/app/data` | SQLite database + app state (named volume `gitsave`) |
| `/app/backups` | Output directory for backup archives |

### Docker Compose (from upstream README)

```yaml
services:
  gitsave:
    image: timwitzdam/gitsave:latest
    container_name: GitSave
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - gitsave:/app/data
      - ./backups:/app/backups
    environment:
      - JWT_SECRET=${JWT_SECRET:?error}
      - DISABLE_AUTH=${DISABLE_AUTH:?error}
      - ENCRYPTION_SECRET=${ENCRYPTION_SECRET:?error}

volumes:
  gitsave:
```

### `.env` file

```env
JWT_SECRET="<your-jwt-secret>"
DISABLE_AUTH=false
ENCRYPTION_SECRET="<exactly-32-character-secret>"
```

## Upgrade procedure

Per upstream: pull the new image and recreate the container.

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- `ENCRYPTION_SECRET` must be **exactly** 32 characters — shorter or longer values will cause startup failure.
- `JWT_SECRET` and `ENCRYPTION_SECRET` must not change after initial setup; changing them invalidates all stored credentials and active sessions.
- Back up `/app/data` (the SQLite database) before upgrades; stored repo credentials and schedules live there.
- SMB share support: configure via the web UI after first login — upstream does not expose SMB credentials as env vars.
- Default port `3000` conflicts with many other services; change the host-side port mapping if needed.
- For public-facing deployments, put GitSave behind a reverse proxy (nginx/Caddy) with TLS — the container does not handle HTTPS directly.

## Links

- Upstream repo: <https://github.com/TimWitzdam/GitSave>
- Docker Hub image: <https://hub.docker.com/r/timwitzdam/gitsave>
