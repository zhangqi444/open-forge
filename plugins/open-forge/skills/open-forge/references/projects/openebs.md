---
name: openebs
description: OpenEBS recipe for open-forge. CNCF project providing cloud-native, container-native storage for Kubernetes. Offers Local PV (hostpath, ZFS, LVM) and Replicated PV (Mayastor) storage engines via CSI drivers.
---

# OpenEBS

CNCF project providing cloud-native persistent storage for Kubernetes workloads. Uses containerized storage controllers and CSI drivers. Supports multiple storage engines: Local PV (hostpath, ZFS, LVM) for single-node performance and Replicated PV (Mayastor) for multi-node HA. Apache 2.0 licensed. Upstream: <https://github.com/openebs/openebs>. Docs: <https://openebs.io/docs>.

## Storage engines

| Engine | Type | Best for |
|---|---|---|
| Local PV Hostpath | Single-node | Dev, distributed DBs (Mongo, Cassandra) that self-replicate |
| Local PV ZFS | Single-node | ZFS users; snapshots, clones, RAID protection |
| Local PV LVM | Single-node | LVM2 users; dynamic provisioning on LVM volumes |
| Mayastor | Multi-node (replicated) | HA stateful workloads; NVMe-oF semantics |

## Compatible install methods

| Method | When to use |
|---|---|
| Helm (recommended) | Standard K8s install |
| kubectl apply (manifests) | Air-gapped or minimal installs |

## Helm install (all engines)

```bash
helm repo add openebs https://openebs.github.io/openebs
helm repo update

helm install openebs openebs/openebs \
  --namespace openebs \
  --create-namespace \
  --set engines.replicated.mayastor.enabled=false   # set true for Mayastor (needs NVMe/high-perf nodes)
```

Full install guide: <https://openebs.io/docs/user-guides/quickstart>

## Creating a StorageClass

### Local PV Hostpath

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-hostpath
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: openebs.io/local
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
parameters:
  storageType: hostpath
  basePath: /var/openebs/local
```

### Mayastor (replicated, HA)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: mayastor-3-replicas
provisioner: io.openebs.csi-mayastor
parameters:
  protocol: nvmf
  repl: "3"
```

## Software-layer concerns

- OpenEBS installs as a set of DaemonSets and Deployments in the `openebs` namespace
- Local PV engines: no data replication — node failure = data unavailable (apps must handle HA)
- Mayastor: requires NVMe SSDs or high-performance block devices; Linux kernel ≥ 5.13; 2 CPU cores dedicated per node
- Backups: integrate with Velero + Restic for Local PVs; Velero + VolumeSnapshot for Mayastor
- Default StorageClass: annotate one StorageClass as default for cluster-wide PVC provisioning

## Upgrade procedure

```bash
helm repo update
helm upgrade openebs openebs/openebs --namespace openebs --reuse-values
```

Check upgrade notes: <https://openebs.io/docs/versioned-docs/version-3.10.x/quickstart-guide/installation>

## Gotchas

- Local PV data is tied to the node — if the node is lost, data is lost (suitable for apps with self-replication only)
- Mayastor requires significant resources and NVMe-class storage — not suitable for all environments
- `volumeBindingMode: WaitForFirstConsumer` is required for Local PV to schedule pods on the correct node
- Mayastor DiskPools must be configured with physical block devices before Mayastor volumes can be provisioned

## Links

- GitHub: <https://github.com/openebs/openebs>
- Docs: <https://openebs.io/docs>
- Helm chart: <https://artifacthub.io/packages/helm/openebs/openebs>
