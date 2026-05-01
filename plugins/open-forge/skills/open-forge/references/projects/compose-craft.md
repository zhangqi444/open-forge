---
name: Compose Craft
description: "Visual Docker Compose editor with diagram visualization. Docker. Next.js + MongoDB. composecraft/composecraft. Drag-and-drop compose editor, node graph visualization, one-click sharing, GitHub integration, import/export. MIT."
---

# Compose Craft

**Visual Docker Compose editor with node-graph visualization.** Create, edit, and share Docker Compose files through a drag-and-drop interface. Services appear as interconnected nodes with automatic layout. Import existing `docker-compose.yml` files and export your diagrams. One-click public link sharing. Monaco-based code editor with real-time preview.

Built + maintained by **composecraft team**. MIT license.

- Upstream repo: <https://github.com/composecraft/composecraft>
- Hosted SaaS: <https://composecraft.com>
- Docker Hub: `composecraft/composecraft`
- Discord: <https://discord.gg/Wdz7Dht9YQ>

## Architecture in one minute

- **Next.js 15** (React 19) — frontend + API routes
- **MongoDB** — stores compose diagrams
- Diagram engine: **React Flow** (node-based canvas)
- Port **3000**
- Resource: **low** — Node.js + MongoDB

## Compatible install methods

| Infra              | Runtime                       | Notes                                      |
| ------------------ | ----------------------------- | ------------------------------------------ |
| **Docker Compose** | `composecraft/composecraft`   | **Primary** — includes MongoDB             |

## Install via Docker Compose

```yaml
services:
  saas:
    image: composecraft/composecraft:latest
    ports:
      - "3000:3000"
    environment:
      - CORE_ONLY=true          # disables SaaS-only cloud features; set for self-host
      - URL=http://localhost:3000
      - SECRET_KEY=changeme     # change to a random string
      - MONGODB_URI=mongodb://dev:dev@db
    depends_on:
      - db

  db:
    image: mongo:latest
    environment:
      - MONGO_INITDB_ROOT_USERNAME=dev
      - MONGO_INITDB_ROOT_PASSWORD=dev
    volumes:
      - mongo_data:/data/db

volumes:
  mongo_data:
```

```bash
git clone https://github.com/composecraft/composecraft.git
cd composecraft/webapp
docker compose up -d
```

Visit `http://localhost:3000`.

## Inputs to collect

| Input | Example | Notes |
|-------|---------|-------|
| `SECRET_KEY` | random string | JWT signing key |
| `MONGODB_URI` | `mongodb://user:pass@db:27017/composecraft` | MongoDB connection string |
| `URL` | `https://compose.example.com` | Public URL for share links |
| `CORE_ONLY` | `true` | Set to `true` for self-host (disables SaaS features) |

## Features overview

| Feature | Details |
|---------|---------|
| Visual compose editor | Drag-and-drop; services appear as interconnected graph nodes |
| Real-time diagram | Automatic Dagre layout; ports/volumes/networks visualized |
| Monaco code editor | VS Code-style editor with syntax highlighting |
| Import | Paste or upload an existing `docker-compose.yml` |
| Export | Download the compose file your diagram represents |
| One-click sharing | Generate a public link to share your compose diagram |
| GitHub integration | Connect a GitHub repo to pull/push compose files |
| Env vars + volumes | Visual management of environment variables, volumes, networks, ports |

## Gotchas

- **`CORE_ONLY=true` for self-host.** Without this, the app may try to call Compose Craft cloud services. Set it to disable SaaS-only features and run fully locally.
- **`SECRET_KEY` must be random and secret.** It signs JWTs for authentication. Change it from the default before exposing to any network.
- **MongoDB volume is the only persistent state.** All diagrams are stored in MongoDB. Back up the `mongo_data` volume.
- **`URL` affects share links.** If set to `localhost`, share links won't work from other machines. Set it to your public domain.

## Backup

```sh
docker compose exec db mongodump --out /data/backup && \
  docker compose cp db:/data/backup ./compose-craft-backup-$(date +%F)
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js + MongoDB development, React Flow visualization, Monaco editor, MIT license.

## Compose-editor-family comparison

- **Compose Craft** — Next.js, visual graph editor, MongoDB, import/export/share, MIT
- **Portainer** — Go, full container management; compose editor is a code editor only; not visual
- **Dockge** — Node.js, compose manager; text-based editing; no visual graph
- **Kompose** — CLI tool converting Helm/k8s ↔ Compose; not a GUI
- **Composerize** — Converts `docker run` to compose YAML; CLI/web; not a full editor

**Choose Compose Craft if:** you want a visual, node-graph Docker Compose editor with import/export and one-click sharing.

## Links

- Repo: <https://github.com/composecraft/composecraft>
- Docs: <https://composecraft.com/docs/>
