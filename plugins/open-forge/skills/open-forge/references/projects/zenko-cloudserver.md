---
name: zenko-cloudserver
description: Zenko CloudServer recipe for open-forge. Covers Docker install. CloudServer is an open-source Amazon S3-compatible object storage server by Scality — useful for dev/test S3 emulation and as an abstraction layer over multiple storage backends.
---

# Zenko CloudServer

Open-source Amazon S3-compatible object storage server. Maintained by Scality as part of the Zenko multi-cloud data controller platform. Provides a single S3 API interface for accessing multiple storage backends: local filesystem, AWS S3, Azure Blob, GCP Storage, Ceph, and more. Widely used as a drop-in S3 emulator for development and CI/CD testing without cloud costs. Upstream: <https://github.com/scality/cloudserver>. Website: <https://www.zenko.io/cloudserver>.

**License:** Apache-2.0 · **Language:** Node.js · **Default port:** 8000 · **Stars:** ~1,900

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/zenko/cloudserver> | ✅ | **Recommended** — simplest setup. |
| Docker Compose | See below | ✅ | Persistent data with named volumes. |
| Source (yarn) | <https://github.com/scality/cloudserver> | ✅ | Development / custom builds. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| access_key | "S3 access key to use (default: accessKey1)" | Free-text | All methods. |
| secret_key | "S3 secret key to use (default: verySecretKey1)" | Free-text | All methods. |
| data_path | "Directory to store object data? (e.g. /opt/cloudserver/data)" | Free-text | All methods. |
| meta_path | "Directory to store metadata? (e.g. /opt/cloudserver/metadata)" | Free-text | All methods. |

## Install — Docker (quickstart)

```bash
docker run -d \
  --name cloudserver \
  -p 8000:8000 \
  -e S3ACCESSKEY=accessKey1 \
  -e S3SECRETKEY=verySecretKey1 \
  zenko/cloudserver
```

The server starts on port 8000. Default credentials: `accessKey1` / `verySecretKey1`.

> ⚠️ **Change the default credentials** if exposed beyond localhost.

## Install — Docker Compose (persistent)

```bash
mkdir cloudserver && cd cloudserver
mkdir -p data metadata

cat > docker-compose.yml << 'COMPOSE'
services:
  cloudserver:
    image: zenko/cloudserver:latest
    container_name: cloudserver
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      S3ACCESSKEY: "YOUR_ACCESS_KEY"
      S3SECRETKEY: "YOUR_SECRET_KEY"
      S3DATAPATH: /data
      S3METADATAPATH: /metadata
    volumes:
      - ./data:/data
      - ./metadata:/metadata
COMPOSE

docker compose up -d
```

## Using CloudServer as an S3 endpoint

### AWS CLI

```bash
# Configure AWS CLI to use CloudServer
aws configure set aws_access_key_id accessKey1
aws configure set aws_secret_access_key verySecretKey1
aws configure set default.region us-east-1

# Use --endpoint-url for all CloudServer operations
aws --endpoint-url http://localhost:8000 s3 mb s3://my-bucket
aws --endpoint-url http://localhost:8000 s3 cp file.txt s3://my-bucket/
aws --endpoint-url http://localhost:8000 s3 ls s3://my-bucket/
```

### boto3 (Python)

```python
import boto3

s3 = boto3.client(
    "s3",
    endpoint_url="http://localhost:8000",
    aws_access_key_id="accessKey1",
    aws_secret_access_key="verySecretKey1",
    region_name="us-east-1",
)

s3.create_bucket(Bucket="my-bucket")
s3.upload_file("file.txt", "my-bucket", "file.txt")
```

### MinIO Client (mc)

```bash
mc alias set cloudserver http://localhost:8000 accessKey1 verySecretKey1
mc mb cloudserver/my-bucket
mc cp file.txt cloudserver/my-bucket/
```

## Multiple storage backends

CloudServer can route objects to different storage backends per bucket:

```bash
# Enable multiple backends
docker run -d \
  -p 8000:8000 \
  -e S3DATA=multiple \
  -v $(pwd)/locationConfig.json:/usr/src/app/locationConfig.json \
  zenko/cloudserver
```

With `locationConfig.json` mapping bucket names to backends (local, AWS S3, Azure, GCP, etc.).

Full multi-backend docs: <http://s3-server.readthedocs.io/en/latest/>

## Software-layer concerns

| Concern | Detail |
|---|---|
| Default credentials | `accessKey1` / `verySecretKey1` are hardcoded defaults. **Change them** before exposing on any network. |
| No TLS built-in | CloudServer serves HTTP only. Put it behind nginx/Caddy with TLS for HTTPS. |
| Development vs production | Primarily designed as a dev/test S3 emulator. For production S3-compatible storage at scale, consider MinIO or SeaweedFS. |
| Path-style vs virtual-hosted | Uses path-style bucket access by default (`http://localhost:8000/bucket-name`) rather than virtual-hosted style (`bucket-name.localhost:8000`). Configure `--virtual-style` for virtual-hosted if needed. |
| Data persistence | Data is stored in `localData/` and metadata in `localMetadata/` by default. Mount volumes to persist across container restarts. |
| Ports 9990/9991 | Internal metadata and data transfer ports — not needed to expose externally. |
| Active development | Scality actively maintains CloudServer with frequent commits. |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- **Default credentials are public knowledge:** `accessKey1` / `verySecretKey1` are documented widely. Any service running CloudServer with defaults that's accessible on the network is immediately compromised. Set custom credentials.
- **Not a full S3 replacement for production:** CloudServer implements the S3 API well for dev/test use. For high-throughput production workloads storing TBs of data, MinIO or SeaweedFS are better suited.
- **Path-style access:** Some S3 client libraries default to virtual-hosted style (`bucket.host`) which may not work out of the box with CloudServer. Configure your client for path-style access.
- **Node.js version pinning:** The source installation requires Node.js 10.x and yarn 1.17.x — quite old. The Docker image manages this for you; prefer Docker over source for non-development use.
- **Port 8000 conflicts:** Port 8000 is commonly used by many development servers. Check for conflicts before exposing it.

## Upstream links

- GitHub: <https://github.com/scality/cloudserver>
- Website: <https://www.zenko.io/cloudserver>
- Documentation: <http://s3-server.readthedocs.io/en/latest/>
- Docker Hub: <https://hub.docker.com/r/zenko/cloudserver>
- Zenko project: <https://www.zenko.io>
