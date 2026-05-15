---
name: VictoriaMetrics
description: Fast, cost-effective, scalable time-series database + monitoring solution. Drop-in Prometheus replacement for long-term storage; also speaks Graphite, InfluxDB, OpenTSDB, DataDog ingestion. Apache-2.0.
---

# VictoriaMetrics

VictoriaMetrics (VM) is a TSDB engineered to store Prometheus-style metrics cheaply at scale. It uses ~7× less RAM than Prometheus for the same dataset, compresses aggressively, and speaks the Prometheus remote-write / query protocols + Graphite / InfluxDB / OpenTSDB / DataDog line protocols for ingestion. Two deployment shapes — **single-server** (one binary, fine for up to millions of samples/sec) and **cluster** (horizontally sharded, for true scale).

Upstream ships a family of binaries / images beyond the core DB, each with its own purpose:

| Binary           | Role                                                                          |
| ---------------- | ----------------------------------------------------------------------------- |
| `victoria-metrics` | The TSDB (single-node)                                                      |
| `vmagent`        | Prometheus-config-compatible scraper + remote-write router                    |
| `vmalert`        | Prometheus-alert-rule and recording-rule evaluator                            |
| `vmauth`         | Auth proxy / load balancer for VM read+write endpoints                        |
| `vmbackup` / `vmrestore` | Block-storage snapshot tooling (S3/GCS/Azure)                          |
| `vmctl`          | Migrate data from Prometheus / OpenTSDB / InfluxDB / Remote Write             |
| `vmstorage` / `vminsert` / `vmselect` | Cluster-mode shards                                      |

- Main repo: <https://github.com/VictoriaMetrics/VictoriaMetrics>
- Docs: <https://docs.victoriametrics.com/>
- Deployment examples: <https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/deployment/docker>
- Single-node guide: <https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/>
- Cluster guide: <https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/>
- Images: `victoriametrics/victoria-metrics`, `victoriametrics/vmagent`, `victoriametrics/vmalert`, …

## Compatible install methods

| Infra                  | Runtime                                    | Notes                                                                   |
| ---------------------- | ------------------------------------------ | ----------------------------------------------------------------------- |
| Single VM (≤10M series) | Docker + single-server compose            | **Recommended.** The `compose-vm-single.yml` in `deployment/docker/`    |
| Multi-node cluster     | Docker + cluster compose OR Kubernetes     | Use for >10M active series or HA; needs `vminsert`/`vmstorage`/`vmselect` |
| Kubernetes             | `vm-operator` (CRDs) or Helm charts        | Upstream-blessed: <https://github.com/VictoriaMetrics/operator>          |
| Bare metal             | Static binaries from releases              | Fine for small/edge deployments                                         |
| Managed cloud          | VictoriaMetrics Cloud                      | Commercial, run by upstream                                             |

## Inputs to collect

| Input                     | Example                                   | Phase   | Notes                                                                   |
| ------------------------- | ----------------------------------------- | ------- | ----------------------------------------------------------------------- |
| Retention period          | `--retentionPeriod=12` (months)           | Runtime | Default 1 month; bump for long-term storage                              |
| Storage path              | `/storage` mounted as named volume        | Data    | Disk the biggest variable — plan ~0.4 bytes/sample compressed           |
| Scrape config             | `prometheus.yml`                          | Config  | Fed to `vmagent` (reuses upstream Prometheus format exactly)            |
| Remote-write target (if replacing Prometheus) | `http://victoriametrics:8428/api/v1/write` | Config | What your existing Prometheus / OTLP collector pushes to             |
| Grafana datasource URL    | `http://victoriametrics:8428`             | Config  | Select "Prometheus" type — VM is wire-compat                            |
| Alertmanager              | `http://alertmanager:9093`                | Config  | For `vmalert`                                                            |
| HTTP auth (optional)      | via `vmauth` or reverse proxy             | Security | No built-in auth on single-node binary — see Gotchas                    |
| TLS                       | reverse proxy (nginx/Caddy/Traefik)       | Security | No built-in TLS — terminate at the edge                                 |

## Install via Docker Compose (single-node stack)

Simplest end-to-end deployment uses `deployment/docker/compose-vm-single.yml` (includes `vmagent`, `victoria-metrics`, `vmalert`, `alertmanager`, `grafana` with pre-provisioned datasources and dashboards):

```sh
git clone --depth 1 https://github.com/VictoriaMetrics/VictoriaMetrics.git
cd VictoriaMetrics/deployment/docker
make docker-vm-single-up        # brings up the full stack
# or: docker compose -f compose-vm-single.yml up -d
```

Endpoints:

- Grafana: <http://localhost:3000> (admin/admin by default — change it)
- vmui (lightweight query UI): <http://localhost:8428/vmui>
- vmalert UI: <http://localhost:8428/vmalert/>
- VictoriaMetrics HTTP API: <http://localhost:8428>

Shutdown: `make docker-vm-single-down`.

### Minimal standalone compose (just the DB)

If you already have Prometheus scraping and just want long-term storage:

```yaml
services:
  victoriametrics:
    image: victoriametrics/victoria-metrics:v1.143.0
    container_name: victoriametrics
    restart: unless-stopped
    ports:
      - "8428:8428"
    volumes:
      - vmdata:/storage
    command:
      - "--storageDataPath=/storage"
      - "--retentionPeriod=12"        # 12 months
      - "--httpListenAddr=:8428"
volumes:
  vmdata:
```

Point Prometheus at it via `remote_write`:

```yaml
remote_write:
  - url: http://victoriametrics:8428/api/v1/write
```

## Install via Docker Compose (cluster)

For >10M active series or HA requirements, use `compose-vm-cluster.yml` — it runs multiple `vmstorage` shards, `vminsert` for write routing, `vmselect` for read fan-out, `vmauth` for load-balancing, plus Grafana/vmalert/Alertmanager.

```sh
cd deployment/docker
make docker-vm-cluster-up
```

Cluster write endpoint: `http://localhost:8480/insert/0/prometheus/api/v1/write` (tenant 0). Read endpoint via vmauth: `http://localhost:8427`.

## Install via `vm-operator` on Kubernetes (upstream-recommended for k8s)

<https://github.com/VictoriaMetrics/operator> ships CRDs (`VMSingle`, `VMCluster`, `VMAgent`, `VMAlert`, `VMAlertmanager`, `VMRule`, `VMProbe`, `VMServiceScrape`, `VMPodScrape`) that replace the Prometheus Operator 1:1.

```sh
helm repo add vm https://victoriametrics.github.io/helm-charts/
helm install vmo vm/victoria-metrics-operator
kubectl apply -f vmsingle.yaml    # or vmcluster.yaml
```

## Data & config layout

- `/storage` (single-node) or `/vmstorage-data` (cluster shards) — the only state. Back up by snapshotting the volume *while the process is paused* or use `vmbackup`.
- `/etc/prometheus/prometheus.yml` — scrape config fed to `vmagent`.
- `/etc/alerts/*.yml` — alert + recording rules (Prometheus-compatible syntax) for `vmalert`.
- Grafana provisioning: `deployment/docker/provisioning/` has ready datasources + dashboards.

## Backup

Live-consistent snapshots via HTTP API — no downtime:

```sh
# Create snapshot
curl http://victoriametrics:8428/snapshot/create
# Upload to S3 (production path)
docker run --rm victoriametrics/vmbackup:v1.143.0 \
  -storageDataPath=/storage \
  -snapshotName=<name> \
  -dst=s3://bucket/vm-backups/$(date +%F)
```

`vmbackup` supports incremental snapshots — subsequent runs only upload changed blocks. Restore with `vmrestore` into a stopped VM instance.

## Upgrade

1. Releases: <https://github.com/VictoriaMetrics/VictoriaMetrics/releases>. LTS releases marked "v1.X.Y-cluster"-style.
2. Read the release notes — VM is conservative about breaking changes, but data-format bumps happen across majors.
3. Bump image tags, `docker compose pull && docker compose up -d`. VM auto-migrates on-disk format on first start.
4. For cluster mode, upgrade in order: `vmstorage` first, then `vmselect`, then `vminsert`. Documented at <https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/#updating--reconfiguring-cluster-nodes>.
5. For `vm-operator`: bump the operator image, then update CR `spec.image.tag` fields.

## Gotchas

- **No built-in auth on the core binary.** `victoria-metrics` on `:8428` is wide open by default. Put it behind `vmauth`, a reverse proxy with basic/OIDC auth, or network isolation. A single HTTP request to `/api/v1/admin/tsdb/delete_series?match[]=...` can nuke data.
- **`--httpListenAddr=:8428` binds 0.0.0.0.** Bind to localhost or a private interface in host-networked deployments.
- **Retention applies per storage, not per metric.** You can't say "keep high-cardinality metrics 7 days but low-cardinality ones 2 years" on a single instance — use the `-retentionFilter` flag (requires enterprise) or run two VM instances.
- **Cardinality explosions still hurt VM**, just less than Prometheus. Monitor `vm_cache_size_bytes` + `vm_cache_entries` — if you're adding a high-churn label (pod name, UUIDs), VM will eat RAM anyway.
- **`vmagent` → VM write** is eventually consistent. `vmagent` buffers locally; network blip means delayed ingestion, not dropped data, but queries immediately after a write may not see it.
- **Cluster-mode tenants are written in the URL path** (`/insert/<tenant>/prometheus/…`). Multi-tenancy via URL is the *only* isolation — no per-tenant RBAC on queries without `vmauth` in front.
- **Grafana datasource type is "Prometheus"**, not "VictoriaMetrics". VM speaks the Prometheus query API; there's also an optional VM-native datasource plugin for PromQL extensions (`MetricsQL`).
- **MetricsQL ≠ PromQL.** Most PromQL works, plus extensions (`keep_last_value()`, `range_first()`, dropdown of experimental time functions). Grafana dashboards authored for pure Prometheus may use queries VM's extensions interpret slightly differently — test.
- **Default retention is 1 month.** Plenty of first-time deployers don't set `-retentionPeriod` and wonder why last year's data is gone.
- **Disk IO matters more than CPU.** VM is IO-bound on ingestion at scale. Use SSDs, avoid network-attached cheap storage.
- **`vmbackup` does not stop ingestion.** Snapshots are consistent; backups are taken against a snapshot. Restoring requires the target VM instance to be stopped (otherwise it refuses — safeguard).
- **`vmagent` can proxy OTLP** (`--httpListenAddr=:8429 --httpListenAddr=:4318/otlp`) but the OTLP support is newer and still evolving; pin versions.
- **Alertmanager is NOT included in the image.** You bring your own (the compose files in `deployment/docker/` do this for you). Enterprise users may use upstream's hosted alerting.
- **Enterprise vs community.** Some features (downsampling, automatic multi-tenancy, retention filters, S3-native querying) are enterprise-only. Docs usually mark them clearly; compose files in `deployment/docker/` are 100% community.
- **Don't confuse with Vector.** Both appear in monitoring stacks; Vector (vector.dev) is a logs/metrics pipeline, VictoriaMetrics is the TSDB. They're complementary, not alternatives.

## Links

- Repo: <https://github.com/VictoriaMetrics/VictoriaMetrics>
- Docs: <https://docs.victoriametrics.com/>
- Deployment examples: <https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/deployment/docker>
- Single-node guide: <https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/>
- Cluster guide: <https://docs.victoriametrics.com/victoriametrics/cluster-victoriametrics/>
- MetricsQL reference: <https://docs.victoriametrics.com/metricsql/>
- Operator: <https://github.com/VictoriaMetrics/operator>
- Helm charts: <https://github.com/VictoriaMetrics/helm-charts>
- Releases: <https://github.com/VictoriaMetrics/VictoriaMetrics/releases>
- Enterprise: <https://victoriametrics.com/products/enterprise/>
