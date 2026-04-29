---
name: seaweedfs-project
description: SeaweedFS recipe for open-forge. Apache-2.0 distributed object/file/block storage — S3-compatible API, POSIX filer (FUSE + HDFS + WebDAV), tiered storage to S3/GCS/Azure/OSS, Kubernetes CSI, cross-cluster replication. Architecture: master(s) + volume server(s) + optional filer + optional S3 gateway + optional WebDAV. Single Go binary (`weed`), 50MB. Scales to billions of files / PBs. Covers single-node quickstart, production topology (3 masters for Raft, multiple volume servers, filer with embedded-or-external metadata store), docker-compose reference deployment, and the operational concepts (volumes, collections, replication, erasure coding).
---

# SeaweedFS

Apache-2.0 distributed object/file/block storage. Upstream: <https://github.com/seaweedfs/seaweedfs>. Wiki: <https://github.com/seaweedfs/seaweedfs/wiki>. Docker: `chrislusf/seaweedfs`.

A single Go binary (`weed`) that implements:

- **Object storage** — small/medium files at billion-file scale. O(1) disk seek design.
- **S3-compatible API** — works with most S3 clients (aws-cli, s3fs, Terraform, K8s CSI, etc.).
- **Filer** — POSIX-like filesystem on top of SeaweedFS. Mountable via FUSE, WebDAV, HDFS API.
- **Tiered storage** — transparently offload cold data to S3/GCS/Azure/Alibaba OSS while keeping hot data local.
- **Kubernetes CSI driver** — persistent volumes for pods backed by SeaweedFS.
- **Cross-cluster replication + backup**.
- **Erasure coding** for efficient redundancy (10+4 etc.).

Good fit for: self-hosted object storage alternative to MinIO with different tradeoffs; massive small-file workloads (photos, audio snippets, logs); Kubernetes persistent storage; HDFS replacement.

## Architecture in one minute

Three main component types:

1. **Master** — metadata + topology coordinator. Uses Raft for HA; run 1 for dev, 3+ for prod.
2. **Volume server** — stores actual data in append-only "volume" files (32GB each, default). Many per cluster; horizontal scaling = more volume servers.
3. **Filer** (optional) — translates POSIX paths/files into volume-server chunk IDs. Stores metadata in a DB (Leveldb embedded / Postgres / MySQL / Cassandra / Redis / Elasticsearch / Etcd).

Optional add-ons:

- **S3 API server** — translates S3 calls to filer operations.
- **WebDAV server** — WebDAV over the filer.
- **Mount** — FUSE mount of the filer.

A minimal single-node setup runs all of these in one binary via `weed server`; production runs each as a separate process on appropriate hosts.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Precompiled binary | <https://github.com/seaweedfs/seaweedfs/releases> | ✅ Recommended | Linux / macOS / Windows. Single file. |
| Docker image (`chrislusf/seaweedfs`) | Docker Hub | ✅ | Containerized deployments. |
| Docker Compose reference topology | <https://github.com/seaweedfs/seaweedfs/blob/master/docker/seaweedfs-compose.yml> | ✅ | Dev / small-prod example. |
| Helm chart | <https://github.com/seaweedfs/seaweedfs/tree/master/k8s> | ✅ | Kubernetes. |
| Build from source | `go install github.com/seaweedfs/seaweedfs/weed@latest` | ✅ | Custom builds. |
| Homebrew | `brew install seaweedfs` | ⚠️ Community | Quick macOS install. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `binary-single-node` / `binary-production` / `docker` / `helm` | Drives section. |
| preflight | "Use case?" | `AskUserQuestion`: `s3-alternative` / `filer-posix` / `both` / `k8s-pv` | Drives which servers to start. |
| storage | "Data directory?" | Free-text, default `/var/lib/seaweedfs` | Volume data lives here — sized to your workload (TB-scale). |
| network | "Master port?" | Default `9333` | gRPC on `19333`. |
| network | "Volume server port?" | Default `8080` | gRPC on `18080`. |
| network | "Filer port?" | Default `8888` | gRPC on `18888`. |
| network | "S3 port?" | Default `8333` | If using S3 API. |
| auth | "S3 access key + secret?" | Free-text (sensitive) | Set via `s3.json` config. Default: NO AUTH (open S3) — change on any non-trivial deploy. |
| replication | "Replication placement?" | `AskUserQuestion`: `000 (no replication)` / `001 (1 replica, same DC)` / `010 (1 replica, diff rack)` / `110 (2 replicas across DCs)` | Encoded as digits for DC/rack/node. |
| filer-store | "Filer metadata DB?" | `AskUserQuestion`: `leveldb (default, single-node)` / `postgres` / `mysql` / `redis` / `cassandra` / `elasticsearch` / `tikv` | Single-node can use leveldb; production use external DB. |

## Install — single-node quickstart

```bash
# 1. Get the binary
VERSION=$(curl -s https://api.github.com/repos/seaweedfs/seaweedfs/releases/latest | grep tag_name | cut -d'"' -f4)
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
curl -LO "https://github.com/seaweedfs/seaweedfs/releases/download/${VERSION}/linux_${ARCH}.tar.gz"
tar -xzf "linux_${ARCH}.tar.gz"
sudo install weed /usr/local/bin/
weed version

# 2. Run everything in one process (master + volume + filer + S3)
mkdir -p /var/lib/seaweedfs
weed server \
    -dir=/var/lib/seaweedfs \
    -s3 \
    -master.volumeSizeLimitMB=1024 \
    -volume.max=100
# → master: :9333
# → volume: :8080
# → filer:  :8888
# → S3:     :8333

# In another terminal, try it:
curl http://localhost:9333/cluster/status
```

## Install — Docker Compose (reference topology)

Upstream ships a reference compose at `docker/seaweedfs-compose.yml`:

```yaml
# Simplified from the upstream example
services:
  master:
    image: chrislusf/seaweedfs:latest
    ports:
      - 9333:9333
      - 19333:19333
    command: 'master -ip=master -ip.bind=0.0.0.0'
  volume:
    image: chrislusf/seaweedfs:latest
    ports:
      - 8080:8080
      - 18080:18080
    command: 'volume -ip=volume -master="master:9333" -ip.bind=0.0.0.0 -port=8080'
    depends_on: [master]
  filer:
    image: chrislusf/seaweedfs:latest
    ports:
      - 8888:8888
      - 18888:18888
    command: 'filer -ip=filer -master="master:9333" -ip.bind=0.0.0.0'
    depends_on: [master, volume]
  s3:
    image: chrislusf/seaweedfs:latest
    ports:
      - 8333:8333
    command: 's3 -filer="filer:8888" -ip.bind=0.0.0.0'
    depends_on: [master, volume, filer]
```

Bring up:

```bash
docker compose -f docker/seaweedfs-compose.yml up -d
# S3 API at http://localhost:8333
# Master console at http://localhost:9333
```

**Note:** The upstream reference compose also wires Prometheus for metrics — see the full file at <https://github.com/seaweedfs/seaweedfs/blob/master/docker/seaweedfs-compose.yml>.

## Install — Production topology

Minimum production recommendation (upstream-blessed):

- **3 master nodes** (Raft quorum, tolerate 1 failure):
  ```bash
  weed master -ip=master1 -peers=master1:9333,master2:9333,master3:9333 -mdir=/var/lib/seaweedfs/master
  # repeat on master2, master3 with appropriate -ip
  ```
- **3+ volume servers** (more = more capacity + concurrency):
  ```bash
  weed volume -ip=vol1 -mserver=master1:9333,master2:9333,master3:9333 -dir=/var/lib/seaweedfs/vol -max=200
  ```
- **1 or 2 filer servers** with external metadata store (Postgres / Cassandra / TiKV):
  ```bash
  weed filer -ip=filer1 -master=master1:9333 -defaultStoreDir=/var/lib/seaweedfs/filer
  # With external DB, configure filer.toml:
  # [postgres2]
  # enabled = true
  # ...
  ```
- **S3 + WebDAV gateways** as needed (each connects to the filer).

## Using the S3 API

```bash
# Configure aws-cli for SeaweedFS
aws configure --profile seaweedfs
# Access key: <whatever you set in s3.json>
# Secret key: <whatever you set in s3.json>
# Region: us-east-1 (arbitrary)

# Set the endpoint
aws s3 --endpoint-url http://localhost:8333 --profile seaweedfs mb s3://my-bucket
aws s3 --endpoint-url http://localhost:8333 --profile seaweedfs cp file.txt s3://my-bucket/
aws s3 --endpoint-url http://localhost:8333 --profile seaweedfs ls s3://my-bucket/
```

### S3 authentication config

Create `s3.json`:

```json
{
  "identities": [
    {
      "name": "admin",
      "credentials": [
        {
          "accessKey": "AKIA<random>",
          "secretKey": "<random-40-char>"
        }
      ],
      "actions": ["Admin", "Read", "Write", "List", "Tagging"]
    }
  ]
}
```

Start S3 server with: `weed s3 -config=/etc/seaweedfs/s3.json`.

## POSIX mount

```bash
mkdir -p /mnt/seaweedfs
weed mount -filer=filer:8888 -dir=/mnt/seaweedfs
# Now use like any local FS
cp ~/file.txt /mnt/seaweedfs/
ls /mnt/seaweedfs/
```

## Replication format (placement)

Replication is encoded as a 3-digit string passed per-collection (or global):

- `000` — no replication (single copy, fastest)
- `001` — 1 copy on another volume server in the same rack
- `010` — 1 copy on another rack, same DC
- `100` — 1 copy on another DC
- `110` — 1 on another DC, 1 on another rack
- `200` — 2 copies on other DCs

Per upstream: the digits are `<dc-count><rack-count><node-count>`. See <https://github.com/seaweedfs/seaweedfs/wiki/Replication>.

## Erasure coding

For cold data, convert replicated volumes to erasure-coded (e.g. 10+4 = 40% overhead instead of 100% for 1-replica). Trade-off: reads/writes are slower.

```bash
# Command to EC a volume (manual)
curl "http://master:9333/vol/encrypt?collection=foo&replication=001"
# See wiki for full workflow
```

## Tiered storage (hot/cold offload)

Configure the filer to offload old chunks to S3/GCS/Azure/OSS. Chunks are seamlessly fetched back on read.

See <https://github.com/seaweedfs/seaweedfs/wiki/Tiered-Storage>.

## Upgrade procedure

### Binary

```bash
# On each node, one at a time (rolling)
systemctl stop weed-<role>
# Download + replace /usr/local/bin/weed
systemctl start weed-<role>
# Confirm healthy before moving to next node
weed shell
> volume.list
```

### Docker

```bash
docker compose pull
docker compose up -d    # Upstream recommends rolling: 1 container at a time
```

Upgrade masters first (1 at a time, wait for Raft to re-quorum), then volume servers (1 at a time, wait for data rebalance), then filers, then gateways. Read release notes: breaking changes happen in major bumps.

## Data layout

| Path | Content |
|---|---|
| Master `-mdir` (default `/tmp`) | Topology state (volumes, locations, free space). Small. |
| Volume server `-dir` | Actual data: `.dat` (data) + `.idx` (index) files, one pair per volume. Large. |
| Filer `-defaultStoreDir` OR external DB | Filesystem metadata: paths, permissions, chunk references. |
| S3 `-config` file | Identity/creds for S3 authentication. |

**Backup:**

- **Metadata:** filer's DB (leveldb file OR external Postgres/Cassandra dump).
- **Data:** `weed backup` command to another cluster OR rely on replication + off-cluster sync.

## Gotchas

- **Default deployment has NO authentication.** Master is open, S3 is open (with `-config` flag not set, accepts any creds), filer is open. Fine for isolated / trusted networks. For anything else: set up s3.json, use TLS on RPC, firewall everything. See <https://github.com/seaweedfs/seaweedfs/wiki/Security>.
- **Single master is a SPOF.** Use 3+ masters with `-peers` for production.
- **Volume server max = pre-allocation.** `-max=100` means up to 100 volumes (~3.2 TB with default 32GB volumes). Set high; unused volume slots cost almost nothing.
- **Full volumes become read-only.** When a volume hits the size limit, writes go to new volumes. This is normal and fine; the master auto-creates more.
- **32 GB volume size by default.** Good for most. Tune `-volumeSizeLimitMB` at master level; volumes created at old size stay at that size.
- **Leveldb filer store is single-node.** For HA filer, use external DB (Postgres / Cassandra / TiKV). Two filers sharing leveldb = corruption.
- **Replication is eventually-consistent during writes.** A freshly-written file may not be replicated for a few seconds. Reads usually succeed from the primary.
- **Erasure coding is manual / async.** Newly written data is replicated; you run `ec.encode` periodically to convert cold data. Not automatic.
- **S3 API ≠ AWS 100% parity.** Most common operations work. Some advanced features (object lock legal-holds, SSE-KMS, versioning semantics) have gaps or differences. Test your specific client.
- **Multipart upload size limits.** Default 5 MB parts; configurable. Huge files work but need proper multipart client config.
- **File name encoding.** SeaweedFS stores bytes; name normalization is up to clients. On cross-OS mounts, case-sensitivity + Unicode surprises happen.
- **Tiered storage to cloud = cloud egress costs.** Offloaded chunks fetched on read = cloud bandwidth bill. Tune the "age threshold" for offload conservatively.
- **Cross-cluster replication is one-way by default.** Active-active setups exist but are advanced — read the wiki carefully.
- **Metrics: Prometheus endpoint on each server.** `/metrics` paths differ per component — check the Monitoring wiki page.
- **`weed shell` is the admin CLI.** Learn it (`volume.list`, `volume.fix.replication`, `collection.list`, etc.). Web UI is read-mostly — admin actions go through the shell.
- **File deletion is async.** Freed space reclaimed via compaction (volume servers compact `.dat` files periodically). Disk doesn't shrink immediately after delete.
- **Memory footprint scales with volume count.** Each loaded volume holds its index in RAM. ~20MB per volume × 100 volumes = 2 GB. Size your hosts accordingly.
- **Small file optimization is the whole point.** SeaweedFS shines on billions of small files (photos, avatars, audio clips). For workloads dominated by huge files (GB/TB each), MinIO or plain S3 may be simpler.
- **The image tag `chrislusf/seaweedfs:latest`** is the canonical Docker Hub location. Don't confuse with other `seaweedfs/*` images; `chrislusf` is the main maintainer's namespace.

## Links

- Upstream repo: <https://github.com/seaweedfs/seaweedfs>
- Wiki (primary docs): <https://github.com/seaweedfs/seaweedfs/wiki>
- Getting Started: <https://github.com/seaweedfs/seaweedfs/wiki/Getting-Started>
- Docker compose reference: <https://github.com/seaweedfs/seaweedfs/blob/master/docker/seaweedfs-compose.yml>
- Helm chart: <https://github.com/seaweedfs/seaweedfs/tree/master/k8s>
- Docker Hub: <https://hub.docker.com/r/chrislusf/seaweedfs>
- Releases: <https://github.com/seaweedfs/seaweedfs/releases>
- Replication: <https://github.com/seaweedfs/seaweedfs/wiki/Replication>
- Tiered Storage: <https://github.com/seaweedfs/seaweedfs/wiki/Tiered-Storage>
- Filer Stores: <https://github.com/seaweedfs/seaweedfs/wiki/Filer-Stores>
- S3 API: <https://github.com/seaweedfs/seaweedfs/wiki/Amazon-S3-API>
- Security: <https://github.com/seaweedfs/seaweedfs/wiki/Security>
- Slack: <https://seaweedfs.slack.com>
