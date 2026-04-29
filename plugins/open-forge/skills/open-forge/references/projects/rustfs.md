---
name: rustfs-project
description: RustFS recipe for open-forge. Apache 2.0 high-performance distributed object storage system written in Rust — full S3 API compatibility plus OpenStack Swift API with Keystone authentication, designed as a permissively-licensed alternative to MinIO (which is AGPLv3). Positioning explicitly pitches Apache 2.0 vs MinIO's AGPL, Rust memory safety vs Go GC pauses, and "no telemetry" data sovereignty. Features: bitrot protection, single-node + distributed (🚧 under testing) + K8s Helm, versioning, bucket replication, logging, event notifications, lifecycle management (🚧), multi-tenancy, edge/IoT ready. Runtime: container UID 10001 (chown mounts), console on :9001, S3 API on :9000, default creds `rustfsadmin`/`rustfsadmin` (CHANGE). Covers Docker run + docker-compose w/ optional Grafana/Prometheus/Jaeger/Tempo/Loki/nginx observability profiles.
---

# RustFS

Apache 2.0 high-performance distributed object storage written in Rust. Upstream: <https://github.com/rustfs/rustfs>. Docs: <https://docs.rustfs.com>. Website: <https://rustfs.com>. Helm charts: <https://charts.rustfs.com>.

**Positioning:** open-source S3-compatible object storage, explicitly built as a permissively-licensed (Apache 2.0) alternative to MinIO (AGPL v3). Key marketing angles per upstream:

| vs Other Object Storage | RustFS | "Others" (read: MinIO + friends) |
|---|---|---|
| License | Apache 2.0 (business-friendly) | AGPL v3 (copyleft) |
| Language | Rust (memory-safe) | Go / C (GC pauses, potential leaks) |
| Telemetry | None / full compliance | Potential data egress |
| S3 compat | 100% | Variable |
| Edge / IoT | Strong | Often too heavy |

Caveat: these are RustFS's own claims; MinIO is a mature, production-hardened project at scale, while RustFS is newer (current release series is `v1.0.0-beta.x`). Evaluate accordingly.

## Features

Per upstream status table:

| Feature | Status |
|---|---|
| S3 Core Features | ✅ |
| Upload / Download | ✅ |
| Versioning | ✅ |
| Logging | ✅ |
| Event Notifications | ✅ |
| K8s Helm Charts | ✅ |
| Keystone Auth (OpenStack) | ✅ |
| Swift API (OpenStack) | ✅ |
| Bitrot Protection | ✅ |
| Single Node Mode | ✅ |
| Bucket Replication | ✅ |
| Multi-Tenancy | ✅ |
| Lifecycle Management | 🚧 Under testing |
| Distributed Mode | 🚧 Under testing |
| RustFS KMS | 🚧 Under testing |
| Swift Metadata Ops | 🚧 Partial |

**Distributed mode is marked "under testing."** For production distributed storage you may want to stick with MinIO / Ceph / SeaweedFS today. Single-node RustFS is stable.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script | `curl -O https://rustfs.com/install_rustfs.sh \| bash` | ✅ | Bare-metal quick install. |
| Docker run | <https://hub.docker.com/r/rustfs/rustfs> | ✅ Recommended | Single-node self-host. |
| Docker Compose | <https://github.com/rustfs/rustfs/blob/main/docker-compose.yml> | ✅ | Single-node + optional observability overlay. |
| Podman | Same image | ✅ | Rootless. |
| Helm chart | <https://charts.rustfs.com> | ✅ | Kubernetes. |
| Build from source | `./docker-buildx.sh` | ✅ | Contributors / multi-arch builds. |
| Nix Flake | `nix run github:rustfs/rustfs` | ✅ | NixOS users. |
| `x-cmd` | `x rustfs` | Community | x-cmd users. |

Image: `rustfs/rustfs:latest` or `rustfs/rustfs:v1.0.0-beta.1` (pin in prod). Multi-arch: `linux/amd64`, `linux/arm64`.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `install-script` / `docker-run` / `docker-compose` / `helm-k8s` / `nix` | Drives section. |
| ports | "S3 API port?" | Default `9000` | Standard S3. |
| ports | "Console port?" | Default `9001` | Web UI. |
| storage | "Data volume layout?" | Default 4 erasure-coded volumes: `/data/rustfs{0..3}` | Per upstream compose — distributed-ready layout even for single node. |
| storage | "Host data dir?" | Path for bind mount | Must be owned by UID `10001:10001` — `chown -R 10001:10001 <path>`. |
| secrets | "Access key (`RUSTFS_ACCESS_KEY`)?" | Default `rustfsadmin` | MUST change. |
| secrets | "Secret key (`RUSTFS_SECRET_KEY`)?" | Default `rustfsadmin` | MUST change. Min recommendation: 32+ chars random. |
| tls | "TLS?" | `AskUserQuestion`: `none-behind-proxy` / `terminate-at-rustfs (RUSTFS_TLS_PATH)` | For direct TLS, mount `/opt/tls` with `ca.crt` + `rustfs_cert.pem` + `rustfs_key.pem`. |
| observability | "Enable observability stack?" | Boolean | Compose profile: Grafana + Prometheus + Jaeger + Tempo + Loki + OTel Collector. |
| proxy | "Enable nginx profile?" | Boolean | Compose profile `proxy` — nginx on :80/:443 with read-only FS. |

## Install — Docker run (single-node, simplest)

Per upstream README:

```bash
# Create data + logs dirs with the right ownership (UID 10001 is the container user)
mkdir -p data logs
chown -R 10001:10001 data logs

# Pin a version in prod
docker run -d --name rustfs \
  -p 9000:9000 -p 9001:9001 \
  -e RUSTFS_ACCESS_KEY=<random-32-chars> \
  -e RUSTFS_SECRET_KEY=<random-32-chars> \
  -v "$(pwd)/data:/data" \
  -v "$(pwd)/logs:/logs" \
  --restart unless-stopped \
  rustfs/rustfs:v1.0.0-beta.1

# Console: http://localhost:9001
# S3 API:  http://localhost:9000
```

⚠️ **The default `RUSTFS_ACCESS_KEY=rustfsadmin` / `RUSTFS_SECRET_KEY=rustfsadmin` is a WIDE-OPEN hardcoded default.** Set strong custom values immediately.

## Install — Docker Compose (with optional observability)

Upstream `docker-compose.yml` ships with 3 profile groups:

| Profile | Services | Use |
|---|---|---|
| (no profile) | `rustfs` | Core storage service only |
| `observability` | `tempo` + `otel-collector` + `jaeger` + `prometheus` + `loki` + `grafana` + `tempo-init` | Full traces/metrics/logs for RustFS |
| `proxy` | `nginx` | Reverse proxy on :80/:443 |
| `dev` | `rustfs-dev` | Dev-env image with source mount |

```bash
git clone https://github.com/rustfs/rustfs.git
cd rustfs

# Core only
docker compose up -d

# With observability stack (Grafana at :3000, Jaeger at :16686)
docker compose --profile observability up -d

# With nginx proxy
docker compose --profile proxy up -d

# Everything
docker compose --profile observability --profile proxy up -d
```

The default compose binds `./deploy/data/pro:/data` and sets up 4 erasure-coded volumes via `RUSTFS_VOLUMES=/data/rustfs{0..3}` — production-ready volume layout even on single-node.

## Install — Helm (Kubernetes)

```bash
helm repo add rustfs https://charts.rustfs.com
helm repo update
helm install rustfs rustfs/rustfs -n rustfs --create-namespace --values values.yaml
```

See <https://charts.rustfs.com/> for the values.yaml reference.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `RUSTFS_ADDRESS` | `0.0.0.0:9000` | S3 API listen |
| `RUSTFS_CONSOLE_ADDRESS` | `0.0.0.0:9001` | Console listen |
| `RUSTFS_CONSOLE_ENABLE` | `true` | Toggle console |
| `RUSTFS_VOLUMES` | `/data/rustfs{0..3}` | Comma-separated paths or glob pattern for erasure-coded volumes |
| `RUSTFS_ACCESS_KEY` | `rustfsadmin` | **MUST CHANGE** |
| `RUSTFS_SECRET_KEY` | `rustfsadmin` | **MUST CHANGE** |
| `RUSTFS_CORS_ALLOWED_ORIGINS` | `*` | CORS policy for S3 API |
| `RUSTFS_CONSOLE_CORS_ALLOWED_ORIGINS` | `*` | CORS policy for Console |
| `RUSTFS_TLS_PATH` | — | Dir containing `ca.crt`, `rustfs_cert.pem`, `rustfs_key.pem` |
| `RUSTFS_OBS_LOGGER_LEVEL` | `info` | `trace` / `debug` / `info` / `warn` / `error` |
| `RUSTFS_OBS_ENDPOINT` | — | OTLP endpoint (e.g. `http://otel-collector:4318`) |
| `RUSTFS_OBS_LOG_DIRECTORY` | — | File-logging dir |

Full reference: <https://docs.rustfs.com>.

## S3 client configuration

Any AWS S3 SDK / `aws s3` / `mc` (MinIO client) / `rclone` works:

```bash
# aws CLI
aws configure set aws_access_key_id     <RUSTFS_ACCESS_KEY>
aws configure set aws_secret_access_key <RUSTFS_SECRET_KEY>
aws --endpoint-url http://localhost:9000 s3 mb s3://my-bucket
aws --endpoint-url http://localhost:9000 s3 cp file.txt s3://my-bucket/

# mc
mc alias set rustfs http://localhost:9000 <access-key> <secret-key>
mc mb rustfs/my-bucket
mc cp file.txt rustfs/my-bucket/

# rclone (remote config)
[rustfs]
type = s3
provider = Other
access_key_id = <access-key>
secret_access_key = <secret-key>
endpoint = http://localhost:9000
acl = private
```

## Data layout

| Path (container) | Content |
|---|---|
| `/data/rustfs{0..3}` | Erasure-coded data volumes (objects + metadata) |
| `/logs` | Application logs |
| `/opt/tls/` | TLS cert dir (if `RUSTFS_TLS_PATH` set) |

**Backup priority:**

1. **`/data/`** — the object store. For a single-node install, tar/rsync while paused. For anything real, use S3-level replication (`mc replicate` to another bucket/region/provider) or filesystem-level (ZFS send/receive).
2. **Console config / users** — stored within the data volumes (RustFS manages them internally).
3. TLS certs — keep elsewhere; regenerable.

## Upgrade procedure

```bash
# Pin the new version in your compose / docker run
docker compose pull
docker compose up -d
docker compose logs -f rustfs
```

Check release notes at <https://github.com/rustfs/rustfs/releases> — RustFS is still in `v1.0.0-beta.x`; breaking changes between betas are possible.

## Gotchas

- **Default credentials `rustfsadmin`/`rustfsadmin` are a critical vulnerability.** Change before exposing to anything.
- **Container runs as UID `10001`.** Bind-mounted data/log dirs MUST be `chown -R 10001:10001 <path>` OR you'll hit permission-denied on writes.
- **Distributed mode is "🚧 Under Testing"** per upstream. Single-node is stable; multi-node for production is risky today. Compare with MinIO distributed mode (production-hardened) if you need real distributed durability.
- **Still in beta (`v1.0.0-beta.x` as of recipe-write).** Don't pin `:latest` in prod — pin the specific beta tag and upgrade deliberately.
- **Swift/Keystone API** is for OpenStack migrations. Most users will use the S3 API; Swift is optional.
- **Erasure-coded volume layout** (`/data/rustfs{0..3}` = 4 volumes on single node) is the upstream-recommended layout. Even for single-node, 4 volumes give you local erasure coding for bit-rot protection.
- **Observability stack profile is HEAVY** — Grafana + Prometheus + Jaeger + Tempo + Loki + OTel Collector. 5+ containers. Only enable if you actually want to query RustFS metrics/traces.
- **`RUSTFS_CORS_ALLOWED_ORIGINS=*` by default** — for dev convenience; tighten for prod (`https://your-app.example.com`).
- **No built-in user management UI** yet in the console (as of beta). Access keys are static env-vars; no IAM-like RBAC yet. Multi-tenancy works at the bucket level.
- **No KMS** yet (marked 🚧). For encryption at rest, rely on filesystem-level (LUKS / ZFS encryption).
- **Lifecycle management 🚧** — no automatic object expiry / tiering yet. Do it via client-side scripts or wait for the feature to land.
- **Event notifications ✅** — works (webhook / queue targets). Configure via S3 `PUT bucket notification` API.
- **Client compatibility** — any S3 SDK works. If a client does unusual things (e.g. S3 Select, complex Object Lock), test it.
- **Upgrade reality** — betas may have data-format changes. Back up `./data` before upgrading.
- **MinIO migration** — RustFS is S3-compatible, so data-level migration via `mc mirror` is straightforward. IAM policies / users don't port.
- **macOS cross-compilation**: if building from source, `ulimit -n 4096` to avoid `ProcessFdQuotaExceeded`.
- **Podman**: works identically — same image, same flags.
- **`observability` profile's OTel Collector exports RustFS telemetry** via `RUSTFS_OBS_ENDPOINT=http://otel-collector:4318` — useful for seeing the storage in Grafana.
- **No Go SDK for RustFS itself** (and you don't need one — it's S3).
- **Helm chart is young.** If you need battle-tested K8s storage, MinIO Operator or Rook/Ceph are more mature.

## Links

- Upstream repo: <https://github.com/rustfs/rustfs>
- Docs: <https://docs.rustfs.com>
- Installation docs: <https://docs.rustfs.com/installation/>
- TLS configuration: <https://docs.rustfs.com/integration/tls-configured.html>
- Website: <https://rustfs.com>
- Helm charts: <https://charts.rustfs.com>
- Docker Hub: <https://hub.docker.com/r/rustfs/rustfs>
- Install script: <https://rustfs.com/install_rustfs.sh>
- Releases: <https://github.com/rustfs/rustfs/releases>
- Discussions: <https://github.com/rustfs/rustfs/discussions>
- Issues: <https://github.com/rustfs/rustfs/issues>
- Compare point (MinIO): <https://github.com/minio/minio>
