---
name: valkey-project
description: Valkey recipe for open-forge. BSD 3-clause high-performance in-memory key-value datastore, a community fork of Redis OSS created right before Redis's March 2024 license change to SSPL/RSAL. Linux Foundation project, backed by AWS/Google/Oracle/Ericsson. Drop-in replacement for Redis 7.2.4 with protocol, command, RDB/AOF, and Sentinel/Cluster compatibility — `valkey-cli` / `valkey-server` instead of `redis-cli` / `redis-server`. Newer minor versions (7.2.x → 8.x) add multi-threaded I/O, better SCAN performance, ASYNC FLUSHALL etc. Covers single-instance, Sentinel HA, and Cluster modes; official `valkey/valkey` Docker image (also `valkey/valkey:<ver>-alpine`); migration from Redis (stop Redis → copy `dump.rdb` → start Valkey); clients compatibility (all Redis clients work unchanged); AWS ElastiCache/MemoryDB and GCP Memorystore ship Valkey as a managed offering.
---

# Valkey

BSD 3-clause in-memory key-value datastore. A Linux Foundation-hosted community fork of Redis OSS 7.2.4, created the week Redis Ltd. changed their license to SSPL/RSAL (March 2024). Upstream: <https://github.com/valkey-io/valkey>. Website: <https://valkey.io>. Docs: <https://valkey.io/topics/>.

Backed by AWS, Google Cloud, Oracle, Ericsson, Snap — most of whom had Redis-based managed services that couldn't continue under SSPL.

## The short version

Wherever you'd have run Redis 7.2.x, you can run Valkey. Everything is compatible:

| | Redis OSS 7.2.4 | Valkey 7.2 / 8.x |
|---|---|---|
| License | BSD 3-clause (last version) | **BSD 3-clause** |
| Wire protocol (RESP2/RESP3) | ✅ | ✅ identical |
| Commands | ✅ | ✅ identical + new (`OBJECT ENCODING`, etc.) |
| `dump.rdb` format | ✅ | ✅ identical |
| AOF format | ✅ | ✅ identical |
| Sentinel (HA) | ✅ | ✅ identical |
| Cluster | ✅ | ✅ identical |
| Client libraries (Jedis, Lettuce, redis-py, ioredis, etc.) | ✅ | ✅ all work unchanged |
| Config file format | ✅ | ✅ identical |
| Modules API | ✅ | ✅ (some module-specific tweaks) |
| CLI binary | `redis-cli` | `valkey-cli` (same flags) |
| Server binary | `redis-server` | `valkey-server` (same flags) |

Valkey 8.0+ adds:

- **Multi-threaded I/O by default** (was opt-in on Redis 7.2).
- **Faster SCAN** (reduces tail latency on large keyspaces).
- **ASYNC FLUSHALL / FLUSHDB**.
- **Improvements to memory efficiency** (smaller key/value overhead).
- **LFU / LRU policy refinements**.

## ⚠️ Redis vs Valkey vs Redis-Inc modules

- **Redis OSS ≤ 7.2.4** — BSD 3-clause. Valkey forked from here.
- **Redis Stack / Redis ≥ 7.4** — SSPL + RSAL. NOT permissive anymore. CANNOT re-license.
- **Redis modules (RediSearch, RedisJSON, RedisTimeSeries, RedisBloom, RedisGraph)** — still owned by Redis Ltd. under AGPL/SSPL.

Valkey does NOT ship RediSearch / RedisJSON / RedisBloom — those are Redis-Inc modules. Valkey has its own search (`valkey-search`) and JSON (`valkey-json`) module projects with permissive licenses. If you use Redis modules, check compatibility before migrating.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker run | <https://hub.docker.com/r/valkey/valkey> | ✅ Recommended | Standard self-host. |
| Docker Compose | Write your own from examples | ✅ | Same. |
| Build from source (`make`) | <https://github.com/valkey-io/valkey> | ✅ | Contributors / bare-metal. |
| `apt install valkey` (Debian 13+ / Ubuntu 24.10+) | Distro packages | ✅ | Modern distros. |
| `brew install valkey` | Homebrew | Community | macOS dev. |
| AWS ElastiCache (Valkey) | <https://aws.amazon.com/elasticache/valkey/> | ✅ | AWS managed. |
| AWS MemoryDB (Valkey) | <https://aws.amazon.com/memorydb/> | ✅ | AWS durable. |
| GCP Memorystore for Valkey | <https://cloud.google.com/memorystore/docs/valkey> | ✅ | GCP managed. |
| Kubernetes (Helm charts) | Community — Bitnami `valkey` chart | ✅ | Clusters. |

Docker image tags (Docker Hub `valkey/valkey`): `8.2.x`, `8.1.x`, `8.0.x`, `7.2.x` — plus `-alpine`, `-bookworm`, `-trixie` variants. Always pin a version in prod.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Deploy mode?" | `AskUserQuestion`: `single-node` / `sentinel-ha` / `cluster` / `managed-aws-gcp` | Drives section. |
| preflight | "Install method?" | `AskUserQuestion`: `docker-run` / `docker-compose` / `apt-package` / `from-source` / `helm` | |
| ports | "Port?" | Default `6379` | Same as Redis. Cluster bus = port + 10000. |
| security | "Require password (`requirepass`)?" | Boolean | Always yes for anything non-localhost. |
| security | "`protected-mode`?" | Default `yes` | Refuses external connections if no password + no bind. Keep on. |
| security | "Bind addresses?" | Default `127.0.0.1 -::1` (container default `*`) | Production: bind to internal interface + reverse proxy / firewall. |
| security | "TLS?" | Boolean | `--tls-port 6380` + cert/key/ca. Most users terminate TLS at a proxy. |
| memory | "`maxmemory`?" | e.g. `2gb` | Hard cap; pair with eviction policy. |
| memory | "`maxmemory-policy`?" | `AskUserQuestion`: `noeviction` / `allkeys-lru` / `allkeys-lfu` / `volatile-lru` / `volatile-ttl` | Depends on cache vs source-of-truth use. |
| persistence | "Persistence?" | `AskUserQuestion`: `rdb-only` / `aof-only` / `rdb+aof` / `none (cache-only)` | RDB = snapshots; AOF = append-log. |
| storage | "Data dir?" | Default `/data` in container | Mount for persistence. |
| migration | "Migrating from Redis?" | Boolean | Stop Redis → copy `dump.rdb` to Valkey's `/data` → start Valkey. No schema change. |

## Install — Docker run (single-node)

```bash
docker run -d --name valkey \
  -p 6379:6379 \
  -v valkey_data:/data \
  --restart unless-stopped \
  valkey/valkey:8.1-alpine \
  valkey-server \
    --requirepass "<strong-password>" \
    --maxmemory 2gb \
    --maxmemory-policy allkeys-lru \
    --save 900 1 --save 300 10 --save 60 10000 \
    --appendonly yes

# Connect
docker exec -it valkey valkey-cli -a '<strong-password>' PING
```

## Install — Docker Compose

```yaml
services:
  valkey:
    image: valkey/valkey:8.1-alpine
    restart: unless-stopped
    command:
      - "valkey-server"
      - "--requirepass"
      - "${VALKEY_PASSWORD}"
      - "--maxmemory"
      - "2gb"
      - "--maxmemory-policy"
      - "allkeys-lru"
      - "--save"
      - "3600 1 300 100 60 10000"
      - "--appendonly"
      - "yes"
    environment:
      - VALKEY_PASSWORD=${VALKEY_PASSWORD}
    volumes:
      - valkey_data:/data
    ports:
      - "127.0.0.1:6379:6379"          # bind to localhost; expose via app network or reverse proxy
    healthcheck:
      test: ["CMD", "valkey-cli", "-a", "${VALKEY_PASSWORD}", "--no-auth-warning", "PING"]
      interval: 10s
      timeout: 3s
      retries: 5

volumes:
  valkey_data:
```

`.env`:

```bash
VALKEY_PASSWORD=<openssl rand -base64 32>
```

## Install — Debian / Ubuntu package

```bash
sudo apt update
sudo apt install valkey-server valkey-tools      # Debian 13+, Ubuntu 24.10+

# Config file at /etc/valkey/valkey.conf (format identical to redis.conf)
sudo nano /etc/valkey/valkey.conf
# Set: requirepass, bind, maxmemory, maxmemory-policy, dir

sudo systemctl enable --now valkey-server
valkey-cli -a '<password>' PING
```

On older distros without Valkey in apt, use the upstream Docker image or build from source (`make BUILD_TLS=yes`).

## Migrating from Redis → Valkey

No schema change — RDB + AOF are binary-compatible.

```bash
# On Redis host
redis-cli -a "$REDIS_PASSWORD" SAVE            # or BGSAVE + wait
systemctl stop redis-server
# Copy /var/lib/redis/dump.rdb + appendonly.aof to Valkey data dir
scp /var/lib/redis/dump.rdb valkey-host:/var/lib/valkey/
# On Valkey host
chown valkey:valkey /var/lib/valkey/dump.rdb
systemctl start valkey-server
valkey-cli -a "$VALKEY_PASSWORD" DBSIZE        # sanity check
```

Client apps keep their Redis client library — they speak RESP2/RESP3 to Valkey unchanged. Update connection string to new host; done.

## Replication (primary-replica)

```bash
# Primary — same as redis
valkey-server --port 6379 --requirepass primary-pass \
              --masterauth replica-pass       # if replicas also require-pass

# Replica — replicates from primary
valkey-server --port 6380 --requirepass replica-pass \
              --replicaof <primary-ip> 6379 \
              --masterauth primary-pass
```

## Sentinel HA

Sentinel runs as a separate process on 26379. Config identical to Redis Sentinel (rename `redis-sentinel` to `valkey-sentinel`). Client libraries (Jedis / Lettuce / ioredis / redis-py) use their existing Sentinel support — just point at Valkey Sentinel hosts.

## Cluster mode (sharding)

Cluster protocol identical to Redis Cluster. 6-node minimum (3 primaries + 3 replicas) for production.

```bash
valkey-cli --cluster create \
  node1:6379 node2:6379 node3:6379 \
  node4:6379 node5:6379 node6:6379 \
  --cluster-replicas 1 \
  -a '<password>'
```

## Configuration file

All Redis 7.2 config directives work unchanged in Valkey. New Valkey-specific directives:

| Directive | Default | Purpose |
|---|---|---|
| `io-threads` | `1` (8.x auto-scales) | Threads for I/O |
| `io-threads-do-reads` | `no` | Parallelize reads too (faster, slightly more CPU) |
| `enable-debug-command` | `no` | Safety — disable DEBUG in prod |
| `enable-module-command` | `no` | Disable MODULE LOAD in prod |

Full reference: <https://github.com/valkey-io/valkey/blob/unstable/valkey.conf>.

## Data layout

| Path (container default) | Content |
|---|---|
| `/data/dump.rdb` | RDB snapshot |
| `/data/appendonly.aof` (or `appendonlydir/` in 7.4+) | AOF log(s) |
| `/data/nodes.conf` | Cluster state (cluster mode only) |

**Backup priority:**

1. **`/data/`** — `tar` the whole directory while running is fine for RDB (atomic file replace). For AOF, pause writes or use `BGREWRITEAOF` first.
2. **Periodic `BGSAVE`** — script it; offsite the resulting `dump.rdb`.
3. **For real HA**: replication + Sentinel (or Cluster) + offsite `dump.rdb` snapshots.

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d
```

Within a minor version series (8.0 → 8.1), drop-in replace. Across minor (7.2 → 8.x), read release notes — RDB forward-compatible, AOF forward-compatible (Valkey reads older RDB/AOF; older versions don't read newer).

**Rolling upgrade for HA (Sentinel)**: upgrade one replica → failover to it → upgrade old primary. Clients stay connected via Sentinel.

Release notes: <https://github.com/valkey-io/valkey/releases>.

## Gotchas

- **`protected-mode yes` + no password + no bind** = accepts ONLY localhost connections. If you remove the bind (or bind to `0.0.0.0`) without setting a password, Valkey refuses. This is a footgun for dev but saves you in prod.
- **No authentication by default** — set `requirepass`. Attackers scan 6379 constantly.
- **`maxmemory` not set = unbounded RAM growth** — OOM-killer will eventually kill the process. Always set + pick an eviction policy.
- **Persistence defaults vary**: Docker image default `save 3600 1 300 100 60 10000` (RDB) + AOF off. Explicitly set what you want.
- **`appendonlydir/`** (7.4+ AOF multi-part files) replaces the old single `appendonly.aof`. Don't delete individual files — use `BGREWRITEAOF`.
- **RDB writes during SAVE fork()** can cause memory overcommit on hosts with insufficient swap. Enable `vm.overcommit_memory=1` (`sysctl`).
- **`enable-debug-command`** disabled by default in 7.4+. Don't enable in prod — DEBUG SLEEP / SEGFAULT exist.
- **Valkey ≠ Redis Stack.** Modules like RediSearch / RedisJSON / RedisBloom are NOT in Valkey. Use `valkey-search` + `valkey-json` (separate modules) if you need them, or stay on Redis Stack (SSPL).
- **Client library compatibility is the whole point — but check major-version compatibility claims.** All Jedis / Lettuce / redis-py / ioredis / go-redis work with Valkey out of the box; a few obscure clients hardcoded `redis_version >= 8.0` checks may balk — report upstream.
- **`ACL`** — Valkey supports ACL (multi-user) same as Redis 6+. Configure `aclfile` or `user` directives.
- **`CLUSTER SLOTS` / `CLUSTER SHARDS`** — cluster commands identical. Ruby/Jedis/ioredis cluster clients work unchanged.
- **Docker image runs as UID `999`** (valkey user). Bind-mount `-v ./data:/data` needs `chown -R 999:999 data`.
- **Named volumes** (`-v valkey_data:/data`) work without chown — Docker handles it.
- **`io-threads`** — 8.x defaults to auto-scale; on single-core VMs you may want to set to `1` explicitly to avoid overhead.
- **AWS ElastiCache Serverless (Valkey)** is cheaper than the Redis variant as of 2024. If you're on AWS, worth migrating for cost alone.
- **GCP Memorystore for Valkey** is Valkey 7.2 baseline; check for 8.x availability.
- **Managed Redis → managed Valkey migration** on AWS: ElastiCache "in-place upgrade" option or via backup/restore from snapshot.
- **TLS setup**: identical flags to Redis. `--tls-port 6380 --port 0 --tls-cert-file ... --tls-key-file ... --tls-ca-cert-file ...`.
- **`CLIENT NO-EVICT`** / **`CLIENT NO-TOUCH`** — new-ish commands (Redis 7.2+) work in Valkey.
- **Lua scripting** via `EVAL` / `EVALSHA` — identical behavior.
- **Functions (7.0+)** — identical.
- **Pub/Sub** — identical (including sharded pub/sub in cluster mode).
- **Keyspace notifications** — identical, same `notify-keyspace-events` config directive.
- **`SELECT`** databases 0-15 — same. Cluster mode only uses DB 0.
- **Memory fragmentation** — same `MEMORY PURGE`, same jemalloc tuning knobs.
- **Monitoring**: Prometheus redis_exporter works against Valkey (protocol-level compat). Or use `INFO` parsing.

## Links

- Upstream repo: <https://github.com/valkey-io/valkey>
- Website: <https://valkey.io>
- Docs / topics: <https://valkey.io/topics/>
- Commands: <https://valkey.io/commands/>
- Download: <https://valkey.io/download/>
- Docker Hub: <https://hub.docker.com/r/valkey/valkey>
- Releases: <https://github.com/valkey-io/valkey/releases>
- Config reference: <https://github.com/valkey-io/valkey/blob/unstable/valkey.conf>
- Valkey Search (RediSearch alt): <https://github.com/valkey-io/valkey-search>
- Valkey JSON (RedisJSON alt): <https://github.com/valkey-io/valkey-json>
- Valkey Bloom: <https://github.com/valkey-io/valkey-bloom>
- Performance dashboards: <https://valkey.io/performance/>
- AWS ElastiCache Valkey: <https://aws.amazon.com/elasticache/valkey/>
- GCP Memorystore Valkey: <https://cloud.google.com/memorystore/docs/valkey>
- License history (Redis → SSPL): <https://redis.io/legal/licenses/>
- Linux Foundation announcement: <https://www.linuxfoundation.org/press/linux-foundation-launches-open-source-valkey-community>
