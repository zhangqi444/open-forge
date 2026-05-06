---
name: zot-oci-registry
description: ZOT OCI Registry recipe for open-forge. Covers Docker and binary install. ZOT is a production-ready, vendor-neutral OCI-native container image registry storing images in OCI format on disk.
---

# ZOT OCI Registry

Production-ready, vendor-neutral OCI-native container image registry. Images are stored in OCI image format on disk and served over the OCI Distribution Specification API. Purpose-built for hosting and distributing container images without vendor lock-in — no hidden formats, no proprietary extensions. Includes a web UI (zui), CLI tool (zli), Prometheus metrics, image scanning, replication/mirroring, and garbage collection. Upstream: <https://github.com/project-zot/zot>. Docs: <https://zotregistry.dev>.

**License:** Apache-2.0 · **Language:** Go · **Default port:** 5000 · **Stars:** ~2,100

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | `ghcr.io/project-zot/zot-linux-amd64` | ✅ | **Recommended** — multi-arch, easy config mount. |
| Binary | <https://github.com/project-zot/zot/releases> | ✅ | Bare-metal / systemd service. |
| Helm (Kubernetes) | <https://zotregistry.dev/v2.1.16/install-guides/install-guide-k8s/> | ✅ | Kubernetes deployments. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| storage_path | "Where should OCI image data be stored? (e.g. /var/lib/zot)" | Free-text | All methods. |
| port | "Port to listen on? (default: 5000)" | Free-text | All methods. |
| auth | "Enable authentication? (htpasswd / LDAP / none)" | AskUserQuestion | Recommended for production. |
| tls | "Enable TLS? (required to push/pull with standard Docker clients over HTTPS)" | AskUserQuestion: Yes / No | Recommended. |

## Install — Docker

```bash
mkdir zot && cd zot
mkdir -p data config

cat > config/config.json << 'CONFIG'
{
  "distSpecVersion": "1.1.1",
  "storage": {
    "rootDirectory": "/var/lib/registry"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000"
  },
  "log": {
    "level": "info"
  }
}
CONFIG

cat > docker-compose.yml << 'COMPOSE'
services:
  zot:
    image: ghcr.io/project-zot/zot-linux-amd64:latest
    container_name: zot
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - ./config/config.json:/etc/zot/config.json:ro
      - ./data:/var/lib/registry
COMPOSE

docker compose up -d
```

Test:
```bash
curl http://localhost:5000/v2/
# Should return: {}
```

### With authentication (htpasswd)

Add to `config.json`:

```json
{
  "distSpecVersion": "1.1.1",
  "storage": { "rootDirectory": "/var/lib/registry" },
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "auth": {
      "htpasswd": {
        "path": "/etc/zot/htpasswd"
      }
    }
  },
  "log": { "level": "info" }
}
```

Generate htpasswd file:
```bash
htpasswd -bnB myuser mypassword > config/htpasswd
```

Mount it:
```yaml
volumes:
  - ./config/config.json:/etc/zot/config.json:ro
  - ./config/htpasswd:/etc/zot/htpasswd:ro
  - ./data:/var/lib/registry
```

## Install — Binary (Linux)

```bash
# Download binary
VERSION=v2.1.16
sudo wget -O /usr/bin/zot \
  https://github.com/project-zot/zot/releases/download/${VERSION}/zot-linux-amd64
sudo chmod +x /usr/bin/zot
sudo chown root:root /usr/bin/zot

# Create config
sudo mkdir -p /etc/zot /var/lib/zot
sudo tee /etc/zot/config.json << 'CONFIG'
{
  "distSpecVersion": "1.1.1",
  "storage": { "rootDirectory": "/var/lib/zot" },
  "http": { "address": "0.0.0.0", "port": "5000" },
  "log": { "level": "info" }
}
CONFIG

# Create systemd service
sudo tee /etc/systemd/system/zot.service << 'UNIT'
[Unit]
Description=ZOT OCI Registry
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/zot serve /etc/zot/config.json
Restart=unless-stopped
User=zot
Group=zot

[Install]
WantedBy=multi-user.target
UNIT

# Create service user
sudo useradd -r -s /sbin/nologin -d /var/lib/zot zot
sudo chown -R zot:zot /var/lib/zot

sudo systemctl daemon-reload
sudo systemctl enable --now zot
```

## TLS configuration

```json
{
  "http": {
    "address": "0.0.0.0",
    "port": "443",
    "tls": {
      "cert": "/etc/zot/certs/server.crt",
      "key": "/etc/zot/certs/server.key"
    }
  }
}
```

## Web UI (zui)

The full Docker image includes the web UI. Access it at `http://your-server:5000`.

The minimal image (`zot-minimal`) has no UI — use if you only need the registry API.

## zli CLI tool

```bash
# Download zli
wget -O /usr/local/bin/zli \
  https://github.com/project-zot/zot/releases/download/v2.1.16/zli-linux-amd64
chmod +x /usr/local/bin/zli

# Configure
zli config add myregistry localhost:5000

# Search images
zli images --config myregistry
```

## Push/pull images

```bash
# Tag and push
docker tag myimage:latest localhost:5000/myimage:latest
docker push localhost:5000/myimage:latest

# Pull
docker pull localhost:5000/myimage:latest
```

For authenticated registries:
```bash
docker login localhost:5000
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| OCI-native storage | Images stored as OCI layout on disk — no proprietary database. Human-readable directory structure under `rootDirectory`. |
| Multi-arch | Docker images available for linux/amd64, linux/arm64, linux/arm/v7. |
| Garbage collection | Run `zot gc config.json` periodically to reclaim space from deleted layers. |
| Mirroring | Can mirror from Docker Hub and other registries. Configure under `sync` in config. |
| Extensions | UI, search, metrics, scrub, sync are optional extensions compiled into the full image; absent in minimal. |
| GHCR image | The official Docker image is on GitHub Container Registry (`ghcr.io`), not Docker Hub. |
| Prometheus metrics | Enable under `extensions.metrics` in config. Expose on same port or separate. |
| Image scanning | Trivy integration available via `extensions.search.cve` — requires internet access for CVE DB. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Binary
sudo systemctl stop zot
sudo wget -O /usr/bin/zot \
  https://github.com/project-zot/zot/releases/download/v2.1.16/zot-linux-amd64
sudo chmod +x /usr/bin/zot
sudo systemctl start zot
```

## Gotchas

- **GHCR not Docker Hub:** The official image is `ghcr.io/project-zot/zot-linux-amd64`, not on Docker Hub. Using an unofficial Docker Hub image risks running unmaintained builds.
- **Full vs minimal image:** `zot-linux-amd64` is the full build (includes web UI, search, metrics). `zot-minimal-linux-amd64` is stripped down — no UI, no extensions. Choose based on your needs.
- **TLS required for remote Docker clients:** Docker clients outside localhost require TLS to push/pull. Without TLS, add the registry to Docker's `insecure-registries` list in `daemon.json`.
- **htpasswd bcrypt only:** Like nginx, zot only accepts bcrypt-hashed passwords in htpasswd files.
- **Garbage collection:** Deleting images via the API marks layers for deletion but doesn't free disk space until `zot gc` runs. Schedule it as a cron job.
- **distSpecVersion:** Must match the OCI Distribution Spec version. Use `1.1.1` for current releases.

## Upstream links

- GitHub: <https://github.com/project-zot/zot>
- Docs: <https://zotregistry.dev>
- Install guide (Linux): <https://zotregistry.dev/v2.1.16/install-guides/install-guide-linux/>
- Install guide (Kubernetes): <https://zotregistry.dev/v2.1.16/install-guides/install-guide-k8s/>
- Configuration reference: <https://zotregistry.dev/v2.1.16/admin-guide/admin-configuration/>
- Releases: <https://github.com/project-zot/zot/releases>
- GHCR packages: <https://github.com/project-zot/zot/pkgs/container/zot-linux-amd64>
- Live demo: <https://zothub.io>
