# Harbor

Cloud-native container image and Helm chart registry. Harbor extends the open-source OCI Distribution spec with security scanning, role-based access control, image replication, content trust (Cosign/Notary), and audit logging. CNCF graduated project. Upstream: <https://github.com/goharbor/harbor>. Docs: <https://goharbor.io/docs>.

Harbor runs as a multi-service application. The core portal listens on port `80`/`443`. Deployment methods are the offline installer (bare-metal/VM) and the Helm chart (Kubernetes). What varies is the TLS configuration, external database/Redis/storage options, and auth integration (local, LDAP/AD, OIDC).

## Compatible install methods

Verified against upstream docs at <https://goharbor.io/docs/latest/install-config/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Offline installer (Docker Compose) | <https://goharbor.io/docs/latest/install-config/installation-prereqs/> | ✅ | Bare-metal or VM. Harbor provides its own compose-based install. |
| Helm chart (Kubernetes) | <https://github.com/goharbor/harbor-helm> | ✅ | Production Kubernetes. Official Harbor Helm chart. |
| Harbor Operator (Kubernetes) | <https://github.com/goharbor/harbor-operator> | ✅ | GitOps-style Kubernetes management. Less mature than Helm chart. |

> The offline installer bundles all dependencies (Docker images, compose file, config generator). Download from <https://github.com/goharbor/harbor/releases>.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| domain | "Hostname for Harbor (e.g. `harbor.example.com`)?" | Free-text | All |
| tls | "TLS method?" | `AskUserQuestion`: `Auto-generate self-signed` / `Provide cert/key files` / `Let's Encrypt (via cert-manager, K8s only)` | All |
| admin | "Initial admin password?" | Free-text (sensitive) | All |
| storage | "Default artifact storage?" | `AskUserQuestion`: `Local filesystem` / `S3` / `Azure Blob` / `GCS` | All |
| optional | "External PostgreSQL?" | Free-text — leave blank to use bundled | Optional |
| optional | "External Redis?" | Free-text — leave blank to use bundled | Optional |
| auth | "Authentication type?" | `AskUserQuestion`: `Local` / `LDAP/AD` / `OIDC` | All |

## Software-layer concerns

### Installer-based deploy (offline installer)

1. Download the offline installer from GitHub Releases:
   ```bash
   wget https://github.com/goharbor/harbor/releases/download/v2.14.0/harbor-offline-installer-v2.14.0.tgz
   tar xzvf harbor-offline-installer-v2.14.0.tgz
   cd harbor
   ```

2. Copy and edit `harbor.yml`:
   ```bash
   cp harbor.yml.tmpl harbor.yml
   # Edit: hostname, https.certificate, https.private_key, harbor_admin_password, database, storage_service
   ```

3. Run the installer:
   ```bash
   sudo ./install.sh
   # Optional flags:
   # --with-trivy         Enable Trivy vulnerability scanner
   # --with-notary        Enable Notary content trust (deprecated in v2.6+, use Cosign instead)
   ```

Harbor deploys as a Docker Compose stack under `harbor/` directory.

### Key `harbor.yml` settings

| Setting | Purpose | Notes |
|---|---|---|
| `hostname` | External domain | Must match TLS cert CN |
| `https.certificate` / `https.private_key` | TLS cert/key paths | Required for HTTPS |
| `harbor_admin_password` | Initial admin password | Change after first login |
| `database.password` | Internal PostgreSQL password | Change from default |
| `storage_service.local.location` | Local storage path | Default `/data`; or configure S3/Azure/GCS |
| `trivy.ignore_unfixed` | Skip unfixed CVEs in scan results | Optional |

### Helm chart (Kubernetes)

```bash
helm repo add harbor https://helm.goharbor.io
helm install harbor harbor/harbor \
  --set expose.type=ingress \
  --set expose.ingress.hosts.core=harbor.example.com \
  --set externalURL=https://harbor.example.com \
  --set harborAdminPassword=changeme
```

Full values reference: <https://github.com/goharbor/harbor-helm/blob/main/values.yaml>.

### Services (Docker Compose installer)

| Service | Role |
|---|---|
| `nginx` / `proxy` | Reverse proxy, TLS termination |
| `core` | Main API server |
| `portal` | Web UI (nginx serving SPA) |
| `jobservice` | Background job runner (replication, GC) |
| `registry` | OCI Distribution registry |
| `registryctl` | Registry management API |
| `database` | PostgreSQL (bundled; can use external) |
| `redis` | Cache + job queue (bundled; can use external) |
| `trivy` | Vulnerability scanner (optional) |

### Data directories

| Path | Contents |
|---|---|
| `/data` | Default artifact storage (registry blobs, charts) |
| `/data/database` | Bundled PostgreSQL data (if not using external) |
| `/var/log/harbor` | Harbor logs |
| `harbor/` | Installer compose files, config, scripts |

## Upgrade procedure

Based on <https://goharbor.io/docs/latest/administration/upgrade/>:

1. **Back up** the database and the `/data` directory.
2. Download the new offline installer version.
3. Stop the current Harbor: `docker compose -f harbor/docker-compose.yml down`
4. Extract the new installer to a new directory.
5. Copy `harbor.yml` from the old installation; run `./prepare` to regenerate compose files.
6. Run `./install.sh` (or `docker compose up -d`).
7. Harbor runs DB migrations automatically on startup.

For Helm: `helm upgrade harbor harbor/harbor --reuse-values`.

## Gotchas

- **TLS is required in the `harbor.yml` config.** The installer generates compose with HTTPS. If you want HTTP-only (behind a TLS-terminating proxy), you must configure `harbor.yml` accordingly and ensure the proxy passes the `X-Forwarded-Proto` header.
- **Docker daemon must trust Harbor's CA.** If using self-signed certs, configure the Docker daemon on all client hosts to trust Harbor's CA cert, or use `--insecure-registry` (not recommended).
- **Garbage collection is manual or scheduled.** Deleting images in the UI marks them for deletion but does not free disk space until a GC job runs. Schedule GC under Administration → Garbage Collection.
- **Trivy DB download requires internet access.** On air-gapped setups, you must mirror the Trivy vulnerability DB.
- **Replication rules are pull or push.** Harbor can push to or pull from other registries (Docker Hub, ECR, other Harbor instances).
- **Cosign replaces Notary for content trust.** Notary is deprecated since v2.6. Use Cosign for image signing.

## Links

- Upstream: <https://github.com/goharbor/harbor>
- Docs: <https://goharbor.io/docs/latest/>
- Install config docs: <https://goharbor.io/docs/latest/install-config/>
- Releases (offline installer): <https://github.com/goharbor/harbor/releases>
- Helm chart: <https://github.com/goharbor/harbor-helm>
- Upgrade guide: <https://goharbor.io/docs/latest/administration/upgrade/>
