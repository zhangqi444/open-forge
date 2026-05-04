# AWX

Web-based UI, REST API, and task engine for Ansible. AWX is the upstream open-source project for Red Hat Ansible Automation Platform. It provides a visual interface for managing Ansible playbooks, inventories, credentials, schedules, and job execution at scale. Upstream: <https://github.com/ansible/awx>. Docs: <https://docs.ansible.com/projects/awx/en/latest/>.

> ⚠️ **Releases paused (as of July 2024).** AWX is undergoing a large-scale refactoring into a pluggable, service-oriented architecture. The last stable release was in July 2024. Follow the [Ansible Forum](https://forum.ansible.com/tag/awx) for updates. The project is still active in development — releases are just paused during the refactor.

AWX **requires Kubernetes** for production installation (via the AWX Operator). A Docker Compose path exists but is only for development/testing — it has no official release and is unsupported for production.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| AWX Operator (Kubernetes) | <https://github.com/ansible/awx-operator> | ✅ | **Preferred.** Production install. Requires a Kubernetes cluster (k3s, kind, RKE2, EKS, etc.). |
| Docker Compose (dev only) | <https://github.com/ansible/awx/blob/devel/tools/docker-compose/README.md> | ✅ | Development and testing only. Not production-ready, no published release. |
| Helm chart (via AWX Operator) | <https://github.com/ansible/awx-operator/tree/devel/charts> | ✅ | Kubernetes with Helm. Wraps the AWX Operator. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| k8s | "Kubernetes distribution?" | `AskUserQuestion`: `k3s` / `kind` / `RKE2` / `EKS` / `GKE` / `other` | Operator |
| domain | "Hostname for AWX?" | Free-text (e.g. `awx.example.com`) | All |
| tls | "TLS method?" | `AskUserQuestion`: `Ingress with cert-manager` / `Self-signed` / `Pre-existing secret` | Operator |
| storage | "PostgreSQL storage class?" | Free-text (Kubernetes storage class name) | Operator |
| admin | "Admin password?" | Free-text (sensitive) — auto-generated if blank | Operator |

## Software-layer concerns

### AWX Operator install (Kubernetes — preferred)

The AWX Operator manages the full AWX deployment lifecycle.

```bash
# Install the AWX Operator (latest stable release)
kubectl apply -k "github.com/ansible/awx-operator/config/default?ref=$(curl -sf https://api.github.com/repos/ansible/awx-operator/releases/latest | grep '"tag_name"' | grep -o 'v[^"]*')"

# Create namespace
kubectl create namespace awx
```

Create an `awx.yaml` manifest:
```yaml
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: ClusterIP
  ingress_type: ingress
  hostname: awx.example.com
  # admin_user: admin       # defaults to 'admin'
  # admin_password_secret:  # optional: reference existing secret
```

Apply:
```bash
kubectl apply -f awx.yaml -n awx

# Watch deployment progress
kubectl get pods -n awx -w
```

Retrieve the admin password:
```bash
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode
```

### Services deployed by the Operator

| Component | Role |
|---|---|
| `awx-web` | Django web application + REST API |
| `awx-task` | Celery task worker (runs Ansible playbooks) |
| `awx-receptor` | Mesh networking for execution nodes |
| `awx-postgres` | PostgreSQL database (or external DB) |
| `awx-redis` | Cache / message broker |

### Key AWX custom resource spec fields

| Field | Purpose | Default |
|---|---|---|
| `service_type` | Service type (`ClusterIP`, `LoadBalancer`, `NodePort`) | `ClusterIP` |
| `ingress_type` | Ingress type (`none`, `ingress`, `route`) | `none` |
| `hostname` | External hostname | — |
| `postgres_storage_class` | StorageClass for PostgreSQL | cluster default |
| `replicas` | Web pod replicas | 1 |
| `task_replicas` | Task worker replicas | 1 |

### Development Docker Compose (not for production)

```bash
git clone https://github.com/ansible/awx.git
cd awx
make docker-compose-build
make docker-compose
```
This starts AWX on `http://localhost:8013`. No published image — you build from source.

## Upgrade procedure

Based on <https://ansible.readthedocs.io/projects/awx-operator/en/latest/upgrade/upgrading.html>:

1. Update the AWX Operator to the new version: re-apply the operator manifest with the new `?ref=` tag.
2. The operator detects the version change and triggers a rolling upgrade of the AWX pods.
3. Monitor with `kubectl get pods -n awx -w`.
4. Database migrations run automatically.

Note: During the release pause (mid-2024 onward), check the forum for guidance on whether upgrades are safe.

## Gotchas

- **Kubernetes is required for production.** The Docker Compose path is explicitly dev-only and has no stable release.
- **Releases are paused.** As of July 2024, no new stable releases. The codebase is being refactored. Use the last stable tag if you need a production deployment now.
- **Receptor is the execution mesh.** AWX uses Receptor for distributing job execution to remote nodes. Understand this architecture before scaling out.
- **PostgreSQL is a hard dependency.** SQLite is not supported. The operator deploys PostgreSQL by default; you can point to an external DB.
- **High resource usage.** AWX is not lightweight — plan for at least 4GB RAM for a minimal cluster.
- **AWX vs Ansible Tower/AAP.** AWX is the upstream community project; Red Hat Ansible Automation Platform (AAP) is the supported commercial product. AWX does not come with support SLAs.

## Links

- Upstream: <https://github.com/ansible/awx>
- AWX Operator: <https://github.com/ansible/awx-operator>
- Docs: <https://docs.ansible.com/projects/awx/en/latest/>
- Install guide (INSTALL.md): <https://github.com/ansible/awx/blob/devel/INSTALL.md>
- Release pause announcement: <https://www.ansible.com/blog/upcoming-changes-to-the-awx-project/>
- Ansible Forum (AWX updates): <https://forum.ansible.com/tag/awx>
