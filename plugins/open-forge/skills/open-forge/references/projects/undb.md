---
name: undb
description: Recipe for undb — open-source no-code database and BaaS backed by SQLite.
---

# undb

Open-source no-code database / Backend as a Service (BaaS) backed by SQLite. Provides a spreadsheet-like UI with kanban, gallery, calendar, pivot, and form views. Exposes an OpenAPI RESTful API automatically for every table. Local-first, packages to a single binary via Bun, and runs in Docker. Upstream: <https://github.com/undb-io/undb>. Docs: <https://docs.undb.io>. License: AGPL-3.0. ~4K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://github.com/undb-io/undb#quick-start> | ✅ | Quickest self-hosted setup |
| Docker Compose | <https://github.com/undb-io/undb#quick-start> | ✅ | Persistent data with named volume |
| Bun binary | <https://github.com/undb-io/undb#packaging-into-a-binary-file> | ✅ | Bare-metal or edge deployments |
| Render.com one-click | <https://render.com/deploy?repo=https://github.com/undb-io/undb> | ✅ | Managed cloud deploy |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "What port should undb listen on?" | Integer (default `3721`) | All methods |
| software | "Where should undb store its data?" | Host path (default `./undb`) | Docker with volume |

## Software-layer concerns

### Docker quickstart (ephemeral)

```bash
docker run -p 3721:3721 ghcr.io/undb-io/undb:latest
```

### Docker with persistent volume

```bash
docker run -d \
  -p 3721:3721 \
  -v $(pwd)/undb:/usr/src/app/.undb \
  --name undb \
  ghcr.io/undb-io/undb:latest
```

### Docker Compose

```yaml
services:
  undb:
    image: ghcr.io/undb-io/undb:latest
    ports:
      - "3721:3721"
    volumes:
      - undb_data:/usr/src/app/.undb
    restart: unless-stopped

volumes:
  undb_data:
```

Then visit `http://localhost:3721`.

### Data directory

`/usr/src/app/.undb` inside the container — contains the SQLite database and uploads. Mount this as a persistent volume.

### Environment variables

undb does not require mandatory env vars for basic operation. Optional vars (check upstream docs for current list):

| Variable | Description |
|---|---|
| `BASE_URL` | Public base URL (for links in emails, etc.) |

## Upgrade procedure

```bash
docker pull ghcr.io/undb-io/undb:latest
docker compose up -d
```

SQLite-backed; no migration tool required for minor version bumps. Check the release notes for breaking changes before major upgrades.

## Gotchas

- **SQLite single-file database**: Concurrent write access from multiple containers is not safe. Run a single instance.
- **Backup**: Back up the volume (`/usr/src/app/.undb`) regularly — everything is in the SQLite file there.
- **No built-in auth beyond first-user**: The first user to register becomes the admin. Protect the port from public access until you've set up your account.
- **ARM support**: Check the current release for arm64 image availability; early versions were amd64-only.

## Links

- GitHub: <https://github.com/undb-io/undb>
- Docs: <https://docs.undb.io>
- Cloud: <https://app.undb.io>
- Discord: <https://discord.gg/3rcNdU3y3U>
