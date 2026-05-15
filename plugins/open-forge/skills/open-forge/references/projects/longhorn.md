---
name: longhorn
description: Recipe for Longhorn — cloud-native distributed block storage for Kubernetes. CNCF incubating project by Rancher/SUSE.
---

# Longhorn

Cloud-native distributed block storage system for Kubernetes. Provides persistent volumes backed by replicated block storage distributed across cluster nodes. Features: incremental snapshots, backup to S3/NFS, scheduled backup, online non-disruptive upgrades, and a web UI dashboard. Each volume has a dedicated storage controller replicated across multiple nodes. CNCF incubating project. Upstream: <https://github.com/longhorn/longhorn>. Docs: <https://longhorn.io/docs/>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Helm chart | <https://longhorn.io/docs/latest/deploy/install/install-with-helm/> | Yes | Recommended production install |
| kubectl (manifest) | <https://longhorn.io/docs/latest/deploy/install/install-with-kubectl/> | Yes | Simple installs |
| Rancher App Catalog | <https://longhorn.io/docs/latest/deploy/install/install-with-rancher/> | Yes | Rancher-managed clusters |
| Flux / Argo CD | Community | Community | GitOps-managed installs |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Number of replica copies? | Integer (default 3; minimum 1) | Drives data durability |
| infra | Dedicated storage nodes? | Boolean | Optional; taint non-storage nodes |
| infra | Backup target (S3 or NFS)? | s3://bucket@region/ or nfs://host/path | Optional; required for off-cluster backups |
| infra | S3 backup credentials? | AWS key/secret or compatible | Required if using S3 backup |

## Prerequisites

Each node must have:
- `open-iscsi` installed: `sudo apt install open-iscsi` / `sudo dnf install iscsi-initiator-utils`
- `util-linux` with `findmnt`
- `bash`, `curl`, `dmsetup`
- Kernel modules: `iscsi_tcp`

Check all nodes: run the [environment check script](https://longhorn.io/docs/latest/deploy/install/#installation-requirements):
```bash
curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/master/scripts/environment_check.sh | bash
```

## Software-layer concerns

### Helm install

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update

helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.11.1 \
  --set defaultSettings.defaultReplicaCount=3 \
  --set defaultSettings.backupTarget=s3://my-bucket@us-east-1/ \
  --set defaultSettings.backupTargetCredentialSecret=s3-backup-secret
```

### kubectl install

```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.11.2/deploy/longhorn.yaml
```

### S3 backup credentials secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-backup-secret
  namespace: longhorn-system
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "your-access-key"
  AWS_SECRET_ACCESS_KEY: "your-secret-key"
  AWS_ENDPOINTS: ""        # leave blank for AWS; set for MinIO/Ceph S3
  VIRTUAL_HOSTED_STYLE: "false"
```

### Accessing the UI

```bash
# Port-forward
kubectl port-forward svc/longhorn-frontend -n longhorn-system 8080:80
```

Or create an Ingress pointing to `longhorn-frontend:80` in `longhorn-system`.

### StorageClass (default)

Longhorn creates a `longhorn` StorageClass. Use it in PVC claims:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 10Gi
```

## Upgrade procedure

```bash
helm upgrade longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --version <new-version>
```

Longhorn supports online non-disruptive upgrades. Review important notes for each release: <https://longhorn.io/docs/latest/important-notes/>

Never skip minor versions — upgrade incrementally (e.g. 1.9 → 1.10 → 1.11).

## Gotchas

- `open-iscsi` required on every node: Longhorn uses iSCSI to attach block devices. Missing it causes PVC attachment failures.
- Replica count: set `defaultReplicaCount=1` only for development. Production needs at least 2-3 replicas for data durability.
- Node disk space: Longhorn uses host disk space for volume data. Monitor `longhorn-manager` disk space metrics.
- `ReadWriteMany` not supported: Longhorn volumes are `ReadWriteOnce`. For RWX, use NFS-based storage or Longhorn's experimental RWX (NFS server provisioner).
- Don't skip minor versions on upgrade: Longhorn has mandatory migration steps between minor versions.
- UI is unauthenticated by default: protect it with an Ingress with basic auth or SSO.

## Links

- GitHub: <https://github.com/longhorn/longhorn>
- Docs: <https://longhorn.io/docs/>
- Installation requirements: <https://longhorn.io/docs/latest/deploy/install/>
- Helm chart: <https://artifacthub.io/packages/helm/longhorn/longhorn>
- Important notes per release: <https://longhorn.io/docs/latest/important-notes/>
