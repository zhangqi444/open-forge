---
name: Colanode
description: "Local-first collaboration workspace — chat + rich-text pages + databases (table/kanban/calendar) + files, all self-hosted. CRDTs (Yjs) for concurrent edits. Client + server via Postgres+pgvector+Redis+S3. Apache-2.0."
---

# Colanode

Colanode is **"Notion + Slack + structured-data, local-first, self-hosted"** — an all-in-one collaboration platform combining:

- **Real-time chat** (team + DM)
- **Rich-text pages** (Notion-like editor for docs/wikis/notes)
- **Customizable databases** (structured records with table/kanban/calendar views)
- **File management**

Built **local-first**: the client (web or desktop) writes to a **local SQLite** first, then syncs to the server via a background process. **CRDT (Yjs)** powers conflict-free real-time editing across multiple clients. Self-host the server; point any number of clients at any number of servers.

Developed by the **Colanode team**; Apache-2.0 licensed; commercial Colanode Cloud (EU + US) available free during beta.

Features (per upstream):

- **Local-first workflow** — SQLite-first writes; works offline; syncs when online
- **CRDT concurrent edits** via Yjs for pages + DB records
- **Multi-server from one client** — connect to multiple Colanode servers with a single app
- **Multi-workspace per server** — workspaces for different teams/projects
- **Web app** (beta)
- **Desktop app** (Electron, macOS/Windows/Linux)
- **Data sovereignty** — self-host = you own the bytes

- Upstream repo: <https://github.com/colanode/colanode>
- Homepage: <https://colanode.com>
- Web app (managed): <https://app.colanode.com>
- Downloads: <https://colanode.com/downloads>
- Discord: <https://discord.gg/ZsnDwW3289>
- Docker compose reference: <https://github.com/colanode/colanode/blob/main/hosting/docker/docker-compose.yaml>
- Kubernetes Helm: <https://github.com/colanode/colanode/tree/main/hosting/kubernetes>

## Architecture in one minute

- **Server**: Node/TypeScript API (Docker image)
- **Postgres + pgvector** — primary DB + vector storage
- **Redis (or Valkey)** — session/cache
- **Storage backend**: local filesystem (default), OR S3-compatible / GCS / Azure Blob (set via `STORAGE_TYPE`)
- **Client**: Electron/Web — writes to local SQLite → syncs via WebSocket
- **CRDT sync**: Yjs over WebSocket
- **Resource**: server is modest (Postgres dominates); scale by users + workspace size

### Config model (upstream)
- Server image ships with `config.json`; most defaults ready
- **Config file = source of truth**; only `POSTGRES_URL` + `REDIS_URL` required env
- Secret pattern: `env://VAR_NAME` pulls from env; `file://path/to/secret.pem` inlines mounted file
- Env vars **do not override config fields** anymore — only `env://` pointers
- Customize: copy `apps/server/config.json` + mount it

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose** (`hosting/docker/docker-compose.yaml`)                | **Upstream-recommended**                                                           |
| Kubernetes         | **Helm chart** (`hosting/kubernetes/`)                                                  | Official                                                                                    |
| Managed (beta)     | **Colanode Cloud EU / US** — free during beta                                                          | For users who don't want to self-host                                                                                      |
| S3 storage option  | Set `STORAGE_TYPE=s3` + credentials                                                                 | For scale + redundancy                                                                                                      |
| Local dev          | `npm install` + `docker compose up` for deps                                                                    | Per upstream "Running locally" section                                                                                                              |

## Inputs to collect

| Input                | Example                                              | Phase        | Notes                                                                    |
| -------------------- | ---------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `colanode.example.com`                                   | URL          | TLS via reverse proxy; WebSocket support mandatory                                   |
| PostgreSQL + pgvector| `postgres://...`                                               | DB           | **pgvector extension required** — standard Postgres won't work                                 |
| Redis/Valkey         | `redis://...`                                                       | Cache        | Required                                                                                           |
| Storage              | local filesystem OR S3/GCS/Azure                                              | Storage      | `STORAGE_TYPE` env                                                                                                |
| SMTP (opt)           | Transactional email                                                               | Email        | Signup + notifications                                                                                                            |
| Admin user           | First account becomes admin                                                               | Bootstrap    | After first login, create more users                                                                                                              |
| Secrets              | JWT secret, storage creds                                                                            | Secrets      | Use `env://` pointers per upstream config model                                                                                                             |

## Install via Docker Compose

Grab upstream compose:
```sh
curl -O https://raw.githubusercontent.com/colanode/colanode/main/hosting/docker/docker-compose.yaml
# Review; create .env with POSTGRES_URL, REDIS_URL, storage creds, JWT secret
docker compose up -d
```

Optional S3 local dev:
```sh
docker compose --profile s3 up -d     # spins up MinIO
```

## First boot

1. Browse to server URL → create first user (becomes admin)
2. Create first workspace
3. Invite team members (via email if SMTP configured, or share signup URL)
4. Create first Page → test rich-text editor; confirm Yjs sync
5. Create first Database → define fields → try table/kanban/calendar views
6. Upload a file → verify STORAGE_TYPE backend works end-to-end
7. Install desktop app (<https://colanode.com/downloads>) → add server → confirm offline capability
8. Put server behind TLS reverse proxy with WebSocket upgrade support

## Data & config layout

- Postgres DB — workspace metadata, users, document snapshots, DB records
- pgvector — embeddings for (if enabled) semantic search
- Redis — session + pubsub
- Storage backend — file uploads (binary assets)
- Client-side SQLite — local cache per user/device

## Backup

```sh
# Postgres
pg_dump -Fc -U user colanode > colanode-$(date +%F).dump
# Storage backend
# - Filesystem: sudo tar czf colanode-files-$(date +%F).tgz /var/lib/colanode/files/
# - S3: lifecycle + cross-region replication in provider
```

Redis = ephemeral; don't need backup.

## Upgrade

1. Releases: <https://github.com/colanode/colanode/releases>. Active.
2. Server image: bump tag → `docker compose pull && docker compose up -d`.
3. **Migrations typically auto** — verify in container logs.
4. **Back up Postgres before major version bumps.**
5. **Clients** (desktop) auto-update via Electron updater; ensure they stay on compatible version range with server.

## Gotchas

- **pgvector extension MANDATORY** — plain Postgres fails at startup. Use `pgvector/pgvector:pg16` or enable extension on existing Postgres (`CREATE EXTENSION vector;`).
- **Config model changed**: historically env vars overrode config fields; now they DO NOT — only `env://VAR_NAME` pointers in config are resolved from env. Operators upgrading must audit their env-var setup; old-style overrides silently ignored. Classic "documentation-vs-behavior-drift" trap — **read upstream hosting README at install time**.
- **WebSockets MUST pass through reverse proxy.** Colanode uses WS for Yjs sync. Nginx needs `Upgrade` headers (same pattern as WeTTY batch 73, Restreamer batch 75). Without this, collaboration silently degrades.
- **Local-first ≠ offline forever.** Clients sync on reconnect; long offline periods = large sync deltas; CRDT merges may be surprising for complex structures. Test your workflow with realistic offline→online cycles.
- **CRDTs ≠ magic resolution** — Yjs merges concurrent edits deterministically, but if two users make semantically conflicting changes (user A changes "meeting Monday"; user B changes same sentence to "meeting Tuesday"), the merge picks one. Important for workflows requiring human resolution (version review, approval processes) — CRDTs don't provide that; add process on top.
- **Message + file operations don't use CRDTs** (simpler DB tables). They use standard DB transactions. No offline-concurrent-edit for messages.
- **Self-host trust boundary**: server sees plaintext content of pages/chats/DB records. Storage backend sees plaintext files. If threat model = "protect from hosting-provider infrastructure compromise," use encrypting storage + at-rest-encrypted Postgres.
- **Beta status**: upstream describes web app as "in early preview." Cloud servers free during beta; pricing TBD. Plan for possible pricing changes post-beta.
- **Sync bandwidth**: active multi-user Yjs on large pages can generate sustained WebSocket traffic. For bandwidth-constrained deploys, plan for steady-state cost.
- **pgvector for AI**: upstream uses pgvector for embedding-backed features (e.g., semantic search). If you don't use AI features, you still need pgvector installed (hard requirement).
- **Backup scope**: Postgres + storage backend + JWT secret. JWT secret rotation = all sessions invalid (same env-var immutability class as Rallly SECRET_KEY, batch 75).
- **License**: **Apache-2.0**. Permissive — minimal copyleft obligations.
- **Governance**: corporate-backed OSS (Colanode team runs Cloud). Pattern: OSS + commercial managed tier. Healthy sustainability signal.
- **Alternatives worth knowing:**
  - **AppFlowy** — Notion-alt; Rust + Flutter; self-hosted
  - **AFFiNE** — Notion/Miro hybrid; open-source
  - **Nextcloud + Talk + Deck** — heavier stack; broader scope
  - **Outline** — docs-focused; no chat
  - **Rocket.Chat** — chat-focused; no docs/DB
  - **Mattermost** — chat + basic integrations
  - **Notion (commercial)** — the template; not self-hostable
  - **Slack + Confluence + Airtable** — the proprietary stack being replaced
  - **Choose Colanode if:** you want chat + docs + structured-data in one local-first self-hosted app.
  - **Choose AppFlowy if:** you want Notion-like with broader ecosystem.
  - **Choose Rocket.Chat if:** chat-only is enough.

## Links

- Repo: <https://github.com/colanode/colanode>
- Homepage: <https://colanode.com>
- Web app (managed): <https://app.colanode.com>
- Downloads: <https://colanode.com/downloads>
- Docker Compose: <https://github.com/colanode/colanode/blob/main/hosting/docker/docker-compose.yaml>
- Kubernetes: <https://github.com/colanode/colanode/tree/main/hosting/kubernetes>
- Discord: <https://discord.gg/ZsnDwW3289>
- Releases: <https://github.com/colanode/colanode/releases>
- Yjs (CRDT lib): <https://docs.yjs.dev>
- pgvector: <https://github.com/pgvector/pgvector>
- AppFlowy (alt): <https://appflowy.io>
- AFFiNE (alt): <https://affine.pro>
- Outline (alt, docs-only): <https://www.getoutline.com>
