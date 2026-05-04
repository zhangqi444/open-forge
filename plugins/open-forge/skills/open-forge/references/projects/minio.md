# MinIO

High-performance, S3-compatible object storage. Designed for AI/ML, analytics, and data-intensive workloads. Supports distributed multi-node deployments with erasure coding. Upstream: <https://github.com/minio/minio>. Docs: <https://min.io/docs/minio/>.

> ⚠️ **Important:** The MinIO community edition (this repo) is now **source-only** — no pre-compiled binary releases are provided for the community version. The Docker image `minio/minio` on Docker Hub is maintained by the MinIO team for AIStor; community users build from source or use the provided `Dockerfile`.

MinIO listens on port `9000` (S3 API) and `9001` (web console). Root credentials default to `minioadmin:minioadmin` and **must be changed in production**.

## Compatible install methods

Verified against upstream README at <https://github.com/minio/minio>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Build from source (`go install`) | <https://github.com/minio/minio#install-from-source> | ✅ | Recommended for community edition. Requires Go 1.24+. |
| Build Docker image from source | <https://github.com/minio/minio#build-docker-image> | ✅ | Containerized deploy. Build from the upstream Dockerfile. |
| Helm (Kubernetes) — community charts | <https://github.com/minio/minio/tree/master/helm/minio> | ✅ | Kubernetes. Community-maintained Helm chart. |
| MinIO Operator (Kubernetes) | <https://github.com/minio/operator> | ✅ | Production Kubernetes; operator manages distributed tenant deployments. |
| AIStor binary/Docker (enterprise) | <https://min.io/download> | ✅ | AIStor free tier — pre-built binaries, not AGPLv3 community edition. |

> Note: The legacy pre-compiled binaries at `dl.min.io` and GitHub Releases are **not updated**. Do not use them for new deployments.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `Build from source` / `Docker (build from source)` / `Kubernetes/Helm` | All |
| preflight | "Deployment mode?" | `AskUserQuestion`: `Standalone (single node)` / `Distributed (erasure set)` | All |
| storage | "Data directory or volume path?" | Free-text (e.g. `/data`, `/mnt/minio-data`) | Source / Docker |
| secrets | "Root username and password?" | Free-text (sensitive) — change defaults from `minioadmin:minioadmin` | All |
| domain | "Domain for MinIO API and console?" | Free-text | Production/reverse-proxy setups |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `MINIO_ROOT_USER` | Root (admin) username | `minioadmin` |
| `MINIO_ROOT_PASSWORD` | Root password (8+ chars) | `minioadmin` |
| `MINIO_VOLUMES` | Data volume path(s) | Passed as CLI arg |
| `MINIO_CONSOLE_ADDRESS` | Console listen address | `:9001` |
| `MINIO_SITE_NAME` | Cluster name | — |

### Build from source

```bash
# Requires Go 1.24+
go install github.com/minio/minio@latest

# Start standalone server
minio server /data --console-address :9001
```

### Build Docker image from source

```bash
git clone https://github.com/minio/minio.git
cd minio
# Build binary first (cross-compile if needed)
go build -o minio .
# Build Docker image
docker build -t myminio:latest .
```

Run:
```bash
docker run -d \
  -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=strongpassword \
  -v /data:/data \
  myminio:latest server /data --console-address :9001
```

### Docker Compose (build from source)

```yaml
services:
  minio:
    build: https://github.com/minio/minio.git
    command: server /data --console-address :9001
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER:-admin}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD:-changeme}
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    restart: unless-stopped

volumes:
  minio_data:
```

### Data directories

| Path | Contents |
|---|---|
| `/data` (or configured path) | Object storage buckets and objects |
| `.minio.sys/` | MinIO system metadata (inside data dir) |

## Upgrade procedure

Based on <https://min.io/docs/minio/linux/operations/install-deploy-manage/upgrade-minio-deployment.html>:

1. **Back up** the MinIO data directory (or at minimum, `.minio.sys/`).
2. For source builds: pull latest code and rebuild (`go build -o minio .`).
3. For Docker: rebuild the image from the updated source.
4. For Helm: `helm upgrade minio minio/minio`.
5. MinIO supports **rolling upgrades** in distributed mode — update one node at a time while the cluster remains online.
6. Check the console/UI after upgrade to confirm all services are healthy.

## Gotchas

- **No pre-built community binaries.** The repo is source-only for the community edition. The AIStor free download at `min.io/download` is a separate product with a different license.
- **Change default credentials immediately.** `minioadmin:minioadmin` is well-known. Set `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` before exposing to any network.
- **AGPLv3 license.** Any modifications must be published. If you need proprietary/commercial use, use AIStor.
- **Console port is separate.** Port 9000 is the S3 API; port 9001 is the web console. Both need to be reachable if you use the console.
- **Distributed mode requires all nodes simultaneously.** You cannot start a distributed cluster partially. All nodes in an erasure set must be up.
- **Single-node is not HA.** For production HA, deploy as a distributed erasure set across multiple nodes/drives.

## Links

- Upstream: <https://github.com/minio/minio>
- Docs: <https://min.io/docs/minio/>
- Community Helm chart: <https://github.com/minio/minio/tree/master/helm/minio>
- MinIO Operator (Kubernetes): <https://github.com/minio/operator>
- Build guide: <https://github.com/minio/minio#install-from-source>
