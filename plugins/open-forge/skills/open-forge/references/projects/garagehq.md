---
name: garagehq
description: GarageHQ recipe for open-forge. Geo-distributed, S3-compatible object storage designed for self-hosters and small clusters. Low resource overhead. AGPL-3.0, Rust. Source: https://git.deuxfleurs.fr/Deuxfleurs/garage
---

# GarageHQ (Garage)

A geo-distributed, S3-compatible object storage service designed for self-hosters and small clusters. Built to run across multiple machines in different locations (even on unreliable connections), with strong consistency and data redundancy. Low resource footprint — runs on Raspberry Pi or a VPS. S3 API compatible, so any S3 client works with it. AGPL-3.0, written in Rust. Website: <https://garagehq.deuxfleurs.fr/>. Source: <https://git.deuxfleurs.fr/Deuxfleurs/garage>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux (single node) | Docker or binary | Simplest setup; no redundancy |
| Multi-machine cluster | Docker (host network) | Geo-distributed; replication across nodes |
| Raspberry Pi cluster | Binary | Low memory use; perfect for home clusters |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Single node or cluster?" | Single / Cluster | Single node = no replication; cluster = redundancy |
| "Storage directories?" | Paths | `metadata_dir` (fast SSD) and `data_dir` (large HDD) |
| "Replication factor?" | 1 / 2 / 3 | 1 = no redundancy; 3 = tolerate 1 node loss |
| "S3 API endpoint port?" | Number | Default 3900 |
| "Admin API port?" | Number | Default 3903 — local only |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "S3 bucket name?" | string | Created via `garage bucket create` |
| "Access key + secret?" | credentials | Created via `garage key create` |
| "Expose S3 API publicly?" | Yes / No | Behind reverse proxy (NGINX/Caddy) for HTTPS |

## Software-Layer Concerns

- **Two storage paths**: `metadata_dir` for fast metadata (put on SSD), `data_dir` for bulk data (can be HDD). Separate paths strongly recommended.
- **Host network mode**: Docker must use `network_mode: host` — bridge networking breaks inter-node RPC.
- **`rpc_secret`**: 32-byte hex secret shared by all nodes — must be identical across the cluster. Generate with `openssl rand -hex 32`.
- **Layout assignment**: After starting nodes, must assign zones/capacities via `garage layout assign` and `garage layout apply`.
- **S3-compatible API**: Works with `aws s3` CLI, rclone, MinIO clients, S3-compatible apps (Nextcloud, Seafile, etc.).
- **No versioning or lifecycle policies** (as of recent versions): Simpler feature set than AWS S3 — check release notes for current support.
- **Web interface**: Garage includes a minimal admin API (port 3903) — no built-in web UI; use CLI (`garage` binary) for management.

## Deployment

### Single-node Docker

```bash
# Generate RPC secret
RPC_SECRET=$(openssl rand -hex 32)

# Create config
mkdir -p /etc/garage /var/lib/garage/{meta,data}

cat > /etc/garage.toml << EOF
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"
replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "${RPC_SECRET}"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.localhost"

[admin]
api_bind_addr = "127.0.0.1:3903"
EOF
```

```yaml
# docker-compose.yml
services:
  garage:
    image: dxflrs/garage:v2.3.0
    network_mode: "host"
    restart: unless-stopped
    volumes:
      - /etc/garage.toml:/etc/garage.toml
      - /var/lib/garage/meta:/var/lib/garage/meta
      - /var/lib/garage/data:/var/lib/garage/data
```

### Initialize single-node cluster

```bash
docker compose up -d

# Get node ID
docker exec -it garage_garage_1 garage node id

# Assign layout (single node, zone=dc1, capacity=1000 = 1TB)
garage layout assign -z dc1 -c 1T <node-id>
garage layout apply --version 1

# Create bucket and key
garage bucket create my-bucket
garage key create my-key
garage bucket allow --read --write --owner my-bucket --key my-key

# Show credentials
garage key info my-key
```

### NGINX reverse proxy for S3

```nginx
server {
    listen 443 ssl;
    server_name s3.example.com;

    location / {
        proxy_pass http://127.0.0.1:3900;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Use with rclone or AWS CLI

```bash
# AWS CLI
aws configure set aws_access_key_id <key-id>
aws configure set aws_secret_access_key <secret>
aws s3 ls --endpoint-url https://s3.example.com

# rclone
rclone config create garage s3 provider Other endpoint https://s3.example.com \
  access_key_id <key-id> secret_access_key <secret> region garage
```

## Upgrade Procedure

1. Read https://garagehq.deuxfleurs.fr/documentation/reference-manual/upgrading/ for version-specific steps.
2. For major versions: drain and re-layout may be needed.
3. `docker compose pull && docker compose up -d` for minor upgrades.

## Gotchas

- **Host network is mandatory in Docker**: Bridge network breaks RPC between containers/nodes.
- **`rpc_secret` must match on all nodes**: If nodes have different secrets, they cannot communicate.
- **Layout must be applied**: New nodes are inert until `garage layout assign` + `garage layout apply`.
- **Metadata dir on SSD**: Put `metadata_dir` on fast storage — slow metadata = slow reads even for large objects.
- **No built-in web UI**: Management is CLI-only. Use `docker exec -it <container> garage ...` for all operations.
- **S3 region name**: Clients must use whatever region string is configured (`garage` by default) — not `us-east-1`.

## Links

- Website: https://garagehq.deuxfleurs.fr/
- Documentation: https://garagehq.deuxfleurs.fr/documentation/
- Quick start: https://garagehq.deuxfleurs.fr/documentation/quick-start/
- Source (Gitea): https://git.deuxfleurs.fr/Deuxfleurs/garage
- Download: https://garagehq.deuxfleurs.fr/download/
