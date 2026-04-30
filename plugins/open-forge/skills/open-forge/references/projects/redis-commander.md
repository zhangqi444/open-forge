---
name: Redis Commander
description: "Web management UI for Redis — browse keys, inspect data types (strings/lists/sets/sorted-sets/streams/ReJSON), execute commands, connect to multiple Redis servers, Sentinel + Cluster support. Node.js. MIT-licensed."
---

# Redis Commander

Redis Commander is **"phpMyAdmin for Redis"** — a Node.js-based web UI for managing + exploring Redis databases. Connect to one or many Redis servers (standalone, Sentinel-managed, or Cluster), browse keys with a tree view, inspect + edit data types, run commands, export/import data. The go-to visual companion for anyone who touches Redis and doesn't want to live exclusively in `redis-cli`.

Built + maintained by **joeferner** + community contributors. **MIT-licensed**. Long history; widely deployed. **Docker Hub images deprecated** in favor of **GHCR** — upstream is explicit: new images publish only to `ghcr.io/joeferner/redis-commander`, NOT the old `rediscommander/redis-commander` Docker Hub repo.

Use cases: (a) **developer debugging** — "why is this key set to what it's set to" (b) **visual inspection of production state** — read-only mode for ops (c) **local-dev tool** — quick sanity check on redis state (d) **teaching Redis** — visualize what data types look like (e) **migrating data** — export keys from old Redis + import to new.

Features:

- **Multi-server** — connect to many Redis instances simultaneously
- **Redis modes**: standalone, Sentinel, Cluster
- **Data types**: strings, lists, sets, sorted sets, **streams** (basic), **ReJSON** docs (basic view)
- **Key operations**: browse, add, update, delete
- **Command execution**: run arbitrary Redis commands
- **Export / import** of Redis data
- **Basic auth** + username/password login
- **HTTPS + reverse-proxy** friendly
- **Read-only mode** — useful for production
- **Docker image** multi-arch (amd64, arm, arm64)
- **Kubernetes Helm chart** (community)

- Upstream repo: <https://github.com/joeferner/redis-commander>
- GHCR image: `ghcr.io/joeferner/redis-commander:latest` (multi-arch)
- GHCR package: <https://github.com/joeferner/redis-commander/pkgs/container/redis-commander>

## Architecture in one minute

- **Node.js** app with Express + ejs templates
- **No DB** — only connects to Redis (it's a client-UI, not server)
- **Single container** deployment
- **Resource**: tiny — 30-80MB RAM
- **Default port**: `8081`

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ghcr.io/joeferner/redis-commander`** (multi-arch)           | **Upstream-primary**; old Docker Hub image is stale                                 |
| `npm install -g`   | `npm install -g redis-commander` + `redis-commander` CLI                  | Per upstream                                                                               |
| Kubernetes         | Community Helm chart                                                                     | Well-documented                                                                                        |
| Bare-metal Node    | Clone + `npm install`                                                                                 | For hacking on it                                                                                                      |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Redis host(s)        | `--redis-host redis` or `REDIS_HOSTS=label:host:port:db`    | Connection   | Multi-instance via comma-separated                                                                         |
| Redis password       | `--redis-password` or env                                               | Auth         | If Redis is password-protected                                                                              |
| UI auth              | `HTTP_USER` + `HTTP_PASSWORD`                                                       | Security     | **MANDATORY in any shared deployment**                                                                                    |
| `READ_ONLY`          | `true`                                                                          | Safety       | Lock down command execution                                                                                              |
| `URL_PREFIX`         | `/redis-commander`                                                                                      | Reverse-proxy | For path-based proxying                                                                                              |

## Install via Docker Compose

```yaml
services:
  redis-commander:
    image: ghcr.io/joeferner/redis-commander:latest     # **pin version**
    restart: unless-stopped
    environment:
      REDIS_HOSTS: "local:redis:6379"
      HTTP_USER: admin
      HTTP_PASSWORD: ${UI_PASSWORD}
      # READ_ONLY: "true"                             # strongly recommended for prod
    ports: ["8081:8081"]

  redis:
    image: redis:7-alpine
    volumes: [redis-data:/data]

volumes:
  redis-data:
```

Via npm:
```sh
npm install -g redis-commander
redis-commander --redis-host localhost --http-u admin --http-p secret
```

## First boot

1. Deploy → `http://host:8081`
2. Login with HTTP_USER / HTTP_PASSWORD
3. Connect to Redis — pre-configured via env, or "Add connection" in UI
4. Browse keys tree → click to inspect
5. If production: **set `READ_ONLY: true`** + **TLS via reverse proxy**
6. Back up: nothing to back up (stateless; config via env)

## Data & config layout

- **Stateless**: no DB, no persistent state
- All config via env vars or CLI args
- Redis connection details in UI can be ephemeral or env-provided

## Backup

Nothing Redis-Commander-specific to back up. Back up **Redis** itself — that's where your data lives. `redis-cli SAVE` / `BGSAVE` or snapshot the RDB/AOF files.

## Upgrade

1. Releases: <https://github.com/joeferner/redis-commander/releases>. Slow/stable cadence.
2. `docker pull ghcr.io/joeferner/redis-commander:latest` (or pin).
3. Migrating from old `rediscommander/redis-commander` Docker Hub → switch to GHCR.

## Gotchas

- **DOCKER HUB IMAGE DEPRECATED** — upstream is explicit: new versions only publish to `ghcr.io/joeferner/redis-commander`, not the historical `rediscommander/redis-commander` image. If you pull from Docker Hub, you're pulling OLD code. **Update your image references.** Same "registry-migration" warning class as common OSS moves (Codeberg migrations, GitLab→GitHub moves, Docker Hub rate-limit fleeing).
- **PUT IT BEHIND AUTH, ALWAYS.** The default behavior is "no HTTP auth" which means anyone who can reach the UI can read ALL your Redis data + run arbitrary commands (`FLUSHALL` included). In any shared environment:
  - **Set `HTTP_USER` + `HTTP_PASSWORD`**
  - **Bind to localhost only + reverse-proxy** with additional auth
  - **Network-isolate** — not exposed to internet
  - **Consider `READ_ONLY: true`** — read-only mode prevents destructive commands
  - This is the **hub-of-credentials + command-exec footgun class**: similar to phpMyAdmin, pgAdmin, MongoDB-Compass. Seventh tool in hub-of-credentials crown-jewel family. **Harden like bastion host.**
- **Redis itself has no auth by default** — a common gotcha: Redis dev setup with `bind 0.0.0.0` + no password = anyone on the network can read/write. Setting up Redis Commander doesn't add security; it exposes whatever security Redis already has. Ensure Redis has `requirepass` + network isolation BEFORE fronting it with Redis Commander.
- **Command execution = foot-gun**: Redis Commander can execute arbitrary Redis commands including `FLUSHDB` / `FLUSHALL` / `CONFIG SET`. One tab-click can wipe production. **READ_ONLY mode is genuinely the right default for production-access tools.**
- **Multi-server connection management** — connection details stored in-browser (localStorage) by default; Docker env var setup is the more secure pattern. Don't let devs copy-paste production connection strings into the UI where they persist in their browser.
- **ReJSON support is basic** — viewing only, no deep edit. For RedisJSON-heavy workloads, the UI is useful but limited. Use `redis-cli` + `JSON.GET` for advanced work.
- **Streams support is basic** — view + add + delete but no advanced stream consumer-group visualization. Use Redis Insight (commercial from Redis Inc.) for advanced stream workflows.
- **Slow key scans on huge DBs** — `KEYS *` is blocking in Redis. Redis Commander uses `SCAN` but browsing 10M+ keys is still slow. Filter with prefix.
- **ReJSON / Search / Graph / TimeSeries**: basic vs comprehensive support varies. RedisInsight (commercial from Redis Inc.) has deeper module support. Redis Commander is MIT + broadly functional; RedisInsight is free-use but proprietary + more polished.
- **Redis deprecation of master terminology** — Redis community moved from `SLAVEOF` to `REPLICAOF`. Redis Commander follows. Old docs may reference old names.
- **HTTP basic auth is weak** against modern threats — adequate for a private-network admin UI; NOT adequate if exposed to internet. Add reverse-proxy-level auth (Authelia / Authentik / OIDC) for anything approximating internet-exposed.
- **Project health**: joeferner solo-led + community contributions + active maintenance but slow cadence. Long history (10+ years). Stable + widely deployed. Low bus-factor risk given simplicity of codebase + forkability.
- **Redis Inc. commercial tools + RedisStack** — Redis the COMPANY (not just the software) has its own management tools + cloud offering. Redis module licensing changes (SSPL / RSAL transitions in 2018-2024) do NOT affect Redis Commander but DO affect the underlying Redis server depending on version + features. Operators running Redis 7.4+ should be aware of license changes. Redis Commander works with both Redis Inc. + fork-Redis (Valkey, KeyDB) since it speaks the Redis wire protocol.
- **Valkey / KeyDB drop-in replacements** — Linux Foundation's **Valkey** (BSD, post-Redis-license-change fork) + **KeyDB** (Snap-owned multithreaded Redis alternative) both work with Redis Commander via the standard Redis protocol.
- **Alternatives worth knowing:**
  - **RedisInsight** (Redis Inc. proprietary; free) — more-polished UI + module-aware + embedded Jupyter for Redis scripts
  - **P3X Redis UI** — another Node.js Redis UI; Electron desktop app too
  - **Another Redis Desktop Manager** — cross-platform desktop (not web)
  - **iRedis** — CLI with syntax highlighting (alternative to `redis-cli`)
  - **Choose Redis Commander if:** you want MIT + web + simple + multi-server + works-with-forks.
  - **Choose RedisInsight if:** you use Redis Stack modules heavily + can accept proprietary license.
  - **Choose iRedis if:** you prefer CLI.

## Links

- Repo: <https://github.com/joeferner/redis-commander>
- GHCR image: <https://github.com/joeferner/redis-commander/pkgs/container/redis-commander>
- Releases: <https://github.com/joeferner/redis-commander/releases>
- RedisInsight (alt, Redis Inc.): <https://redis.io/insight/>
- Another Redis Desktop Manager (alt): <https://github.com/qishibo/AnotherRedisDesktopManager>
- P3X Redis UI (alt): <https://github.com/patrikx3/redis-ui>
- iRedis (alt, CLI): <https://github.com/laixintao/iredis>
- Valkey (Redis BSD fork): <https://valkey.io>
- KeyDB (Redis alt): <https://keydb.dev>
