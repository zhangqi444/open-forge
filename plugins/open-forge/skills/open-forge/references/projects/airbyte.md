---
name: airbyte
description: Airbyte recipe for open-forge. Covers self-hosted deployment via abctl (Airbyte's CLI tool, the current upstream-recommended local install method) and Helm/Kubernetes for production, as documented at https://docs.airbyte.com/quickstart/deploy-airbyte.
---

# Airbyte

Open-source ELT data integration platform with 600+ connectors for APIs, databases, warehouses, and data lakes. Upstream: <https://github.com/airbytehq/airbyte>. Deploy guide: <https://docs.airbyte.com/quickstart/deploy-airbyte>.

Airbyte runs as a Kubernetes-based platform (even locally via `abctl` which embeds a local k3d/kind cluster). The platform includes a web UI, API server, worker pods, and a connector catalog. Connectors run as ephemeral Docker containers.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `abctl local install` | <https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart> | ✅ | Current recommended local/single-node install. Uses embedded Kubernetes. |
| Helm on Kubernetes | <https://docs.airbyte.com/platform/operator-guides/deploy-airbyte-on-kubernetes-via-helm> | ✅ | Production Kubernetes cluster. |
| AWS EC2 (community guide) | <https://docs.airbyte.com/operator-guides/deploy-airbyte-on-aws-ec2> | ✅ | EC2 instance with abctl or Helm. |
| GCP Compute (community guide) | <https://docs.airbyte.com/operator-guides/deploy-airbyte-on-gcp-compute-engine> | ✅ | GCP VM with abctl or Helm. |

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux VM (4+ CPU, 8GB+ RAM) | abctl (embedded k3d) | Recommended for single-node |
| Kubernetes cluster | Helm chart | Production multi-node |
| AWS EC2 (t3.xlarge+) | abctl | Per AWS deployment guide |
| GCP GCE (n2-standard-4+) | abctl | Per GCP deployment guide |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method?" | options: abctl / Helm/Kubernetes | Drives setup path |
| preflight | "Server port for Airbyte UI?" | number (default: 8000) | `--port` flag for abctl |
| preflight | "CPU architecture?" | options: amd64 / arm64 | abctl supports both |
| auth | "Username for Airbyte UI?" | free-text (default: airbyte) | Auto-generated if not set |
| auth | "Password for Airbyte UI?" | sensitive | Retrieved via `abctl local credentials` post-install |
| tls | "Domain for Airbyte?" | free-text | Needed for production TLS setup |
| storage | "External PostgreSQL connection string?" | sensitive free-text | Optional; for production external DB |
| storage | "External state storage (S3/GCS/Azure)?" | options | For production connector state |

## Software-layer concerns

### Install via `abctl` (recommended)

From <https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart>:

```bash
# 1. Install Docker Engine (required prerequisite)
# https://docs.docker.com/engine/install/

# 2. Install abctl
# Via curl:
curl -LsfS https://get.airbyte.com | bash -

# Via brew:
brew tap airbytehq/tap && brew install abctl

# 3. Install Airbyte (takes up to 30 min on first run)
abctl local install

# 4. Retrieve login credentials
abctl local credentials
# Output: username, password, client-id, client-secret

# 5. Access UI at http://localhost:8000 (or specified --port)
```

### Custom port

```bash
abctl local install --port 8080
```

### Configuration directory

abctl stores its state under `~/.airbyte/abctl/`. Helm values are stored there for customization.

### Key environment concerns

- Airbyte requires Docker to be running even when using abctl (abctl itself manages a local Kubernetes cluster via kind/k3d).
- Connectors run as short-lived Docker containers — Docker socket must be accessible.
- Minimum specs: 4 CPU cores, 8 GB RAM, 30 GB disk.

### Helm-based production values

For Kubernetes/Helm, key values in `values.yaml`:

```yaml
global:
  edition: "community"
  auth:
    enabled: true
  database:
    # Use external PostgreSQL for production
    secretName: airbyte-config-secrets
  storage:
    type: "S3"  # or GCS / AZURE
```

Full Helm chart: <https://github.com/airbytehq/airbyte-platform>

## Upgrade procedure

```bash
# abctl upgrade
abctl local install  # Re-running install upgrades to latest

# Check current version
abctl version

# For Helm:
helm repo update airbyte
helm upgrade airbyte airbyte/airbyte -f values.yaml -n airbyte
```

⚠️ Check [Airbyte release notes](https://github.com/airbytehq/airbyte/releases) for migration steps before upgrading — some upgrades require database migrations that run automatically but may take time.

## Gotchas

- **First install is slow**: `abctl local install` downloads ~4GB of container images on first run (can take 15–30 min depending on internet speed).
- **Credentials are auto-generated**: Run `abctl local credentials` after install to retrieve the randomly generated username and password.
- **Port 8000 must be free**: abctl defaults to port 8000. Use `--port` to override if it's taken.
- **Docker required**: Even though abctl manages Kubernetes internally, Docker must be installed and running.
- **Connector image pulls**: Each connector type is a separate Docker image. First run of a new connector type will pull its image.
- **Resource requirements**: Airbyte is resource-intensive. Running on under-spec hardware causes slow syncs or OOM errors.
- **abctl vs docker-compose**: The old `docker-compose` deployment is deprecated. Use `abctl` for all new installs.
- **Firewall**: Port 8000 (or custom port) must be open if accessing remotely.

## Links

- Upstream README: <https://github.com/airbytehq/airbyte/blob/master/README.md>
- Quickstart deploy: <https://docs.airbyte.com/quickstart/deploy-airbyte>
- OSS Quickstart (abctl): <https://docs.airbyte.com/platform/using-airbyte/getting-started/oss-quickstart>
- abctl CLI: <https://github.com/airbytehq/abctl>
- Helm deployment: <https://docs.airbyte.com/platform/operator-guides/deploy-airbyte-on-kubernetes-via-helm>
- Connector catalog: <https://connectors.airbyte.com/>
- Configuration reference: <https://docs.airbyte.com/platform/operator-guides/configuring-airbyte>
