---
name: Garage
description: "S3-compatible distributed object storage for self-hosting at small-to-medium scale. Rust. Designed for geographically-distributed nodes; replication across physical locations; resilient to machine failure. Alternative to MinIO / Ceph / SeaweedFS. AGPL-3.0. Built by Deuxfleurs collective (French FOSS)."
---

# Garage

Garage is **"the self-hosted S3-compatible object store for federated + small-to-medium deployments"** — a Rust implementation designed specifically for storage clusters spanning **geographically distributed nodes** (different physical locations with asymmetric network links). Replicates data across locations; stays available even when some servers are unreachable; focuses on being lightweight, easy to operate, resilient to machine failures. The antidote to MinIO's 2024+ enterprise-freemium-licensing shift + Ceph's operational weight.

Built + maintained by **Deuxfleurs** (<https://deuxfleurs.fr>) — a French FOSS collective operating an experimental small-scale self-hosted service provider since 2020. **AGPL-3.0**. Used in production by Deuxfleurs since first release; well-respected in the self-hosted-federation ecosystem (Matrix homeservers, Mastodon instances, etc. use Garage for media storage).

Use cases: (a) **S3-compatible backend** for self-hosted apps expecting S3 (Mastodon media, Matrix media repository, Nextcloud external storage, Peertube, MinIO drop-in) (b) **geographically-distributed storage** across 2-3+ sites (home + VPS + friend's home) for family-photo-grade redundancy (c) **small-to-medium federation** storage — federation-adjacent projects (Fediverse, Matrix) (d) **backup target** for Restic / BorgBackup / rclone (e) **homelab S3 store** as alternative to MinIO (f) **ingredient for CI/CD artifact storage**.

Features:

- **S3 API** — compatible subset; works with most S3 clients + SDKs
- **Distributed replication** — configurable replication factor (typically 3)
- **Multi-region / multi-zone awareness** — replicate across named zones
- **Lightweight Rust binary** — single static binary; low resource usage
- **Kubernetes-friendly** — deployable on K8s clusters
- **K2V API** — optional key-value layer on top of object-storage (Garage-specific)
- **Web-UI / CLI** — `garage` CLI for cluster operations
- **Bucket quotas + ACLs**
- **S3 presigned URLs**
- **CORS support**
- **Erasure-coding planned** (not primary mode; replication is default)

- Upstream repo: <https://git.deuxfleurs.fr/Deuxfleurs/garage> (primary) + GitHub mirror: <https://github.com/deuxfleurs-org/garage>
- Homepage: <https://garagehq.deuxfleurs.fr>
- Docs: <https://garagehq.deuxfleurs.fr/documentation/>
- Quick start: <https://garagehq.deuxfleurs.fr/documentation/quick-start/>
- Design goals: <https://garagehq.deuxfleurs.fr/documentation/design/goals/>
- Features reference: <https://garagehq.deuxfleurs.fr/documentation/reference-manual/features/>
- Binary releases: <https://garagehq.deuxfleurs.fr/_releases.html>
- Matrix channel: `#garage:deuxfleurs.fr`

## Architecture in one minute

- **Rust** — single static binary
- **Dynamo-style** eventually-consistent replication
- **Per-zone replication**: data replicated across zones per policy (e.g., replication=3, 3 zones → one copy per zone)
- **No centralized metadata server** — gossip-based cluster state
- **Resource**: light — 200-500MB RAM per node; disk = your data
- **Ports**: 3900 (S3 API), 3902 (admin/RPC), 3903 (web), 3901 (internal RPC gossip)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static binary**  | **`garage` Rust binary** → systemd                              | **Upstream-primary**                                                               |
| Docker             | `dxflrs/garage` official image                                            | Multi-arch                                                                                 |
| Kubernetes         | Helm chart + upstream docs                                                              | For serious ops                                                                                      |
| NixOS              | NixOS module available                                                                             | For Nix users                                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Nodes                | 3+ nodes across zones (ideal)                               | Infra        | Minimum 1 node; 3 nodes across zones for production                                                                         |
| RPC secret           | Shared secret across cluster                                | **CRITICAL** | **IMMUTABLE for running cluster** — change requires coordinated cluster restart                                                                                    |
| Admin token          | For admin API                                                                                     | Auth         | Bootstrap + rotate later                                                                                    |
| Replication factor   | `3` typical; `2` acceptable for small-scale                                                                     | Config       | Governs durability                                                                                                              |
| Zones                | `home`, `vps`, `friend` (whatever your geography)                                                                                 | Config       | Each node assigned a zone                                                                                                                                   |
| Storage dirs         | Data path + metadata path on each node                                                                                                  | Storage      | SSD for metadata recommended                                                                                                                                                              |
| Bucket + access keys | Per-application S3 creds                                                                                                                                         | App          | Generate per-app; revocable                                                                                                                                                                                     |

## Install (single-node quick start)

Download the static binary from <https://garagehq.deuxfleurs.fr/_releases.html>. Example systemd service + minimal `/etc/garage.toml`:

```toml
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "lmdb"
replication_factor = 1  # single-node dev

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "[node-ip]:3901"
rpc_secret = "<hex-encoded 32-byte secret — generate with `openssl rand -hex 32`>"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.local"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.local"
```

Then bootstrap: `garage status` → `garage layout assign ...` → apply layout. See quick-start: <https://garagehq.deuxfleurs.fr/documentation/quick-start/>

## First boot

1. Install Garage on each node; matching version; shared RPC secret
2. Start the daemon on each node
3. On any node: `garage status` → lists all nodes
4. Assign roles + zones: `garage layout assign <node-id> -z <zone> -c <capacity-in-GB>`
5. Apply layout: `garage layout apply`
6. Create bucket: `garage bucket create my-bucket`
7. Create access key: `garage key new --name my-app` → note `access_key` + `secret_key`
8. Grant: `garage bucket allow my-bucket --read --write --key my-app`
9. Test with `aws s3` CLI: `AWS_ACCESS_KEY_ID=... aws --endpoint-url http://node:3900 s3 ls`
10. Set up TLS in front via SWAG / Caddy / Traefik

## Data & config layout

- **metadata_dir** — LMDB (or sqlite/sled depending on version) metadata
- **data_dir** — actual object blobs
- **garage.toml** — config (RPC secret, replication factor, bind addrs)
- **`rpc_secret`** in config — cluster-wide shared secret
- **access keys + bucket policies** — in Garage's metadata

## Backup

- **Metadata** — back up `metadata_dir` per node (each node has its own)
- **Data** — typically NOT backed up traditionally; replication across zones IS the durability story
- **Disaster recovery**: lose 1 node in 3-zone cluster → Garage reconstructs from other 2; lose entire cluster = lose data (replication != backup)
- **For critical data**: separate offsite backup via S3-to-other-bucket replication, or client-side Restic/BorgBackup to a different target

## Upgrade

1. Releases: <https://garagehq.deuxfleurs.fr/_releases.html>. Semver-ish; read changelog.
2. **Rolling upgrade across cluster**: upgrade one node at a time; cluster continues serving from remaining nodes.
3. **Version compatibility window**: check release notes — some upgrades require simultaneous restart (coordinated).
4. **Back up metadata FIRST** for major versions.

## Gotchas

- **Small-to-medium-scale specifically**: Deuxfleurs positions Garage for **small-to-medium self-hosted** use — think 3-10 nodes, terabytes of data. **NOT Ceph-scale** (petabytes, 100+ nodes); **NOT MinIO-enterprise** (thousands of nodes). If you need hyperscale, choose differently. For homelab / small federation / nonprofit / small-business = ideal.
- **Replication ≠ backup**: Garage replicates data across zones for AVAILABILITY + DURABILITY but:
  - Accidental delete via S3 API → deleted from all replicas
  - Malicious access with valid credentials → same
  - **Need a separate backup strategy** (object versioning if available + offsite cold copy). Same class as any RAID-is-not-backup warning.
- **RPC SECRET IMMUTABILITY**: the shared `rpc_secret` gates inter-node communication. Changing it requires ALL nodes to restart with the new secret simultaneously (or you split the cluster). **16th tool in immutability-of-secrets family.** Generate once + store securely + ALL nodes share.
- **Geographic distribution value**: Garage's design goal is **"stays available even when some servers are unreachable"** — this is a REAL feature only if you actually deploy across multiple failure domains. Running 3 nodes on the same VPS provider = same failure domain = Ceph-replication-theater. **Value requires geographic/network/provider diversity.** Deuxfleurs's example: home + VPS + friend's home.
- **Asymmetric network latency**: unlike Ceph (assumes LAN-grade low-latency), Garage tolerates inter-node latency of hundreds-of-ms (inter-continental acceptable). Read/write performance is bounded by your slowest link, but cluster keeps functioning.
- **S3 compat is a SUBSET of AWS S3**:
  - Works with: most common SDK calls, `aws s3`, rclone, Restic, Duplicati, Mastodon, Matrix, Nextcloud
  - **May not support**: some advanced features (Object Lock for immutability, some bucket-policy DSL corner cases, SSE-KMS, Glacier-style transition rules)
  - **Test your specific workload** before committing.
- **NO BUILT-IN ENCRYPTION-AT-REST**: Garage stores objects as-is. For encryption-at-rest:
  - **Client-side encryption** (Restic / age / rclone crypt) — best option
  - **Disk-level encryption** (LUKS / ZFS native encryption) — OS-level
  - **Do not assume Garage encrypts your data without explicit config.**
- **ENCRYPTION-IN-TRANSIT**: Garage's inter-node RPC uses the `rpc_secret` for auth + uses TLS if configured. S3 API access = put TLS-terminating reverse proxy in front. Same discipline as MinIO / any-object-store.
- **Access keys = full S3 ACL power**: Garage access keys ARE the auth — no IAM-role-like fine-grained policies. Bucket-level allow/deny only. Scoped access = separate key per app + separate bucket per app. Not per-path-permission granular like AWS.
- **HUB-OF-CREDENTIALS** (Tier 2): Garage cluster + its access keys gate ALL objects stored there. Lost admin token = potentially lose admin access; lost RPC secret = cluster integrity compromise; lost access keys = that app's data readable/writable by attacker. **20th tool in hub-of-credentials family.**
- **K2V API** (Garage-specific key-value layer): interesting Garage-unique feature for apps that want K-V on top of object-store. NOT in S3 spec. Lock-in to Garage if you use it. Useful for specific integrations (Aerogramme mail storage, some Matrix-adjacent projects).
- **Matrix-channel support model** — Deuxfleurs runs Matrix channel for community support. Responsive community + focused scope. **Not-commercial-tier** — pure volunteer/collective-funded; donations welcome.
- **AGPL-3 for object-store**: fine for internal use. If offering S3-as-a-Service to third parties and modifying Garage, AGPL triggers source-disclosure. Same discipline as any-AGPL service tool.
- **Deuxfleurs institutional signal**: French FOSS collective, small-scale-by-design (**transparent-maintenance-status** — explicit scope-limit). **10th tool in institutional-stewardship family** (small-collective tier — different from ASF industrial-scale but equally authentic). **10th tool in transparent-status family** (honest scope-limit: "we target small-to-medium, not hyperscale").
- **Project health**: production-used by Deuxfleurs since 2020 + active development + French federation ecosystem adoption. Strong bus-factor-via-collective rather than single-maintainer.
- **When to choose Garage vs alternatives**:
  - **Garage**: small-to-medium + geographically-distributed + AGPL OK + self-host-friendly
  - **MinIO**: larger-scale + AGPL / commercial enterprise-license; operator-friendly but 2024+ licensing tension
  - **SeaweedFS**: file + object unified; Apache-2
  - **Ceph**: petabyte-scale + LAN-grade networking; heavy ops burden
  - **Rook/Ceph on K8s**: Kubernetes-native Ceph
  - **Backblaze B2 / Wasabi / AWS S3**: commercial SaaS (fully-managed)
- **Alternatives worth knowing:**
  - **MinIO** — mature S3-compatible; AGPL + commercial; hyperscale-capable
  - **SeaweedFS** — Apache-2 file + object; distributed
  - **Ceph / Rook** — petabyte-scale; operational heavyweight
  - **OpenIO** — (acquired by OVH; status uncertain)
  - **ZenKo CloudServer (S3 Server)** — Apache-2 S3 compat; former Scality
  - **Backblaze B2 / Wasabi / Cloudflare R2 / AWS S3** — commercial SaaS
  - **Choose Garage if:** you want lightweight + small-to-medium-scale + geographically-distributed + AGPL + federation-aligned.
  - **Choose MinIO if:** you want hyperscale + enterprise features + willing to navigate commercial licensing.
  - **Choose Ceph if:** you have ops team + petabyte scale + LAN networking.
  - **Choose SeaweedFS if:** you want unified file + object + Apache-2.

## Links

- Repo (primary): <https://git.deuxfleurs.fr/Deuxfleurs/garage>
- Repo (GitHub mirror): <https://github.com/deuxfleurs-org/garage>
- Homepage: <https://garagehq.deuxfleurs.fr>
- Docs: <https://garagehq.deuxfleurs.fr/documentation/>
- Quick start: <https://garagehq.deuxfleurs.fr/documentation/quick-start/>
- Design goals: <https://garagehq.deuxfleurs.fr/documentation/design/goals/>
- Deuxfleurs collective: <https://deuxfleurs.fr>
- MinIO (alt): <https://min.io>
- SeaweedFS (alt): <https://github.com/seaweedfs/seaweedfs>
- Ceph (alt): <https://ceph.io>
- Cloudflare R2 (commercial alt): <https://www.cloudflare.com/developer-platform/r2/>
- Backblaze B2 (commercial alt): <https://www.backblaze.com/b2/>
