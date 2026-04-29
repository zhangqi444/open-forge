---
name: prometheus-project
description: Prometheus recipe for open-forge. Apache-2.0 CNCF-graduated monitoring system + TSDB (pull-based metrics collection, PromQL, alerting). Covers the official install paths (precompiled binaries from prometheus.io/download, Docker images at `prom/prometheus` on Docker Hub / `quay.io/prometheus/prometheus`, building from source) plus the typical deployment shape (Prometheus + Node Exporter + Alertmanager sidecars, config as YAML, data in a local TSDB directory). Emphasizes "single server nodes are autonomous" — no clustering primitives upstream; horizontal scale via federation / remote_write.
---

# Prometheus

CNCF-graduated systems monitoring + time-series database. Scrapes metrics from instrumented targets over HTTP, stores them locally, and evaluates PromQL queries for dashboards + alerts. Upstream: <https://github.com/prometheus/prometheus>. Docs: <https://prometheus.io/docs/>. Download / releases: <https://prometheus.io/download/>.

**Architecture basics.** Prometheus is a single autonomous binary (Go). It PULLS metrics from configured HTTP endpoints (`/metrics` by convention) at a scrape interval and writes to a local TSDB. There is no built-in clustering; horizontal scale comes from:

- **Federation** — a hierarchy of Prometheus servers where parents scrape aggregated metrics from children.
- **`remote_write`** — ship samples to an external long-term store (Cortex, Mimir, Thanos, VictoriaMetrics, InfluxDB, managed cloud products).

A typical deployment bundles three upstream-maintained binaries:

| Component | Role | Repo |
|---|---|---|
| `prometheus` | Scrape engine + TSDB + query engine + alert evaluator. This recipe. | <https://github.com/prometheus/prometheus> |
| `alertmanager` | Receives fired alerts from Prometheus, deduplicates, routes to email/PagerDuty/Slack/etc. | <https://github.com/prometheus/alertmanager> |
| `node_exporter` | Exposes host-level metrics (CPU, memory, disk, network) at `:9100/metrics` for Prometheus to scrape. | <https://github.com/prometheus/node_exporter> |

Each is a separate install. This recipe covers Prometheus itself; see upstream docs for the others (the install patterns are identical — binary or container).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Precompiled binary + systemd | <https://prometheus.io/download/> + <https://prometheus.io/docs/introduction/install/> | ✅ | **Upstream-recommended.** Tarball with `prometheus` + `promtool`, drop into `/usr/local/bin`, write a systemd unit. Smallest-footprint production setup. |
| Docker image (`prom/prometheus`) | <https://hub.docker.com/r/prom/prometheus> · <https://quay.io/repository/prometheus/prometheus> | ✅ | Containerised deploys. One volume for `prometheus.yml`, one for TSDB data. Same binary, just wrapped. |
| Docker Compose (with exporters) | Community patterns (not a single canonical upstream file) | ⚠️ | Multi-container stack with `prometheus` + `node_exporter` + `alertmanager` + optional Grafana. Convenient but you're assembling it yourself. |
| Kubernetes — `prometheus-operator` / kube-prometheus-stack | <https://github.com/prometheus-operator/kube-prometheus> | ⚠️ | Operator-managed Prometheus + Alertmanager + Grafana + scrape-target CRDs. Not first-party upstream but CNCF-adjacent; de facto standard on K8s. |
| Build from source | README "Building from source" | ✅ | Contributors only (requires Go + Node.js for UI assets). |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion` from table above | Drives the flow. |
| preflight | "Target OS / arch?" | Auto-detect: `uname -sm` | Downloads the right binary tarball. |
| version | "Which Prometheus version?" | `AskUserQuestion`: `latest LTS` / `latest stable` / `specific` | Released versions at <https://github.com/prometheus/prometheus/releases>. Pin a version for reproducibility. |
| config | "What should Prometheus scrape?" | `AskUserQuestion`: `Just itself (starter)` / `Local node_exporter` / `Custom jobs` | Drives the scrape_configs shape in prometheus.yml. |
| storage | "TSDB retention period?" | Free-text (default `15d`) | `--storage.tsdb.retention.time`. Disk usage scales with scrape volume × retention. |
| storage | "TSDB data directory?" | Free-text (default `/var/lib/prometheus/data`) | `--storage.tsdb.path`. Must be on a disk with enough headroom. |
| network | "Bind address + port?" | Free-text (default `0.0.0.0:9090`) | `--web.listen-address`. 9090 is the convention; the UI + API live there. |
| network | "External URL (for links in alerts)?" | Free-text | `--web.external-url`. Needed if Prometheus is behind a reverse proxy. |
| alerting | "Wire up Alertmanager?" | `AskUserQuestion`: `Yes — pointed at <host:port>` / `Not yet` | Fills in `alerting.alertmanagers` block. |
| remote_write | "Ship samples to long-term store?" (Thanos/Mimir/VictoriaMetrics/managed cloud) | `AskUserQuestion`: `Yes — config URL` / `No (local TSDB only)` | Adds `remote_write:` block. |

## Install — precompiled binary + systemd (upstream-recommended)

```bash
# 1. Pick version + arch from https://prometheus.io/download/
PROM_VERSION="2.54.1"   # check the download page for current LTS
ARCH="linux-amd64"      # or linux-arm64 / darwin-arm64 / etc.

# 2. Create a system user (no login shell)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin prometheus

# 3. Download + verify SHA256 from the release page
cd /tmp
curl -fsSL -O "https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.${ARCH}.tar.gz"
# (Optionally also fetch sha256sums.txt and verify)

tar xzf "prometheus-${PROM_VERSION}.${ARCH}.tar.gz"
cd "prometheus-${PROM_VERSION}.${ARCH}"

# 4. Install binaries
sudo install -o root -g root -m 0755 prometheus /usr/local/bin/prometheus
sudo install -o root -g root -m 0755 promtool /usr/local/bin/promtool

# 5. Config + data dirs
sudo install -o prometheus -g prometheus -m 0755 -d /etc/prometheus
sudo install -o prometheus -g prometheus -m 0755 -d /var/lib/prometheus/data

# Copy bundled console templates + libraries
sudo cp -r consoles /etc/prometheus/
sudo cp -r console_libraries /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus/consoles /etc/prometheus/console_libraries

# 6. Starter config — scrape Prometheus itself
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'YAML'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: []   # add 'alertmanager:9093' when ready

rule_files: []

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
YAML
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

# 7. systemd unit
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'UNIT'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/data \
  --storage.tsdb.retention.time=15d \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
```

Verify at `http://<host>:9090/` — the built-in UI + PromQL explorer. `http://<host>:9090/metrics` is Prometheus's own metrics endpoint (so it can scrape itself).

## Install — Docker

```bash
# 1. Prep host dirs for persistence
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown -R 65534:65534 /var/lib/prometheus    # nobody:nogroup — the image runs as this UID

# 2. Drop prometheus.yml at /etc/prometheus/prometheus.yml (same content as the systemd install)

# 3. Run
docker run -d \
  --name prometheus \
  --restart unless-stopped \
  -p 9090:9090 \
  -v /etc/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  -v /var/lib/prometheus:/prometheus \
  prom/prometheus:latest \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus \
  --storage.tsdb.retention.time=15d \
  --web.listen-address=0.0.0.0:9090
```

For a multi-container setup (Prometheus + node_exporter + Alertmanager + Grafana), write a `docker-compose.yml`. Example at the end of this recipe's "References" section.

## Config surface — `prometheus.yml`

Top-level sections (see <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>):

| Section | Role |
|---|---|
| `global` | `scrape_interval`, `evaluation_interval`, `scrape_timeout`, default external labels. |
| `alerting.alertmanagers` | Where to send fired alerts. `static_configs` for fixed endpoints, `kubernetes_sd_configs` / `dns_sd_configs` for discovery. |
| `rule_files` | List of YAML files with alerting + recording rules. |
| `scrape_configs` | What to scrape. Each job has `job_name`, target discovery (`static_configs`, `kubernetes_sd_configs`, `ec2_sd_configs`, `file_sd_configs`, etc.), relabeling. |
| `remote_write` | Ship samples to external TSDB (Mimir/Cortex/Thanos/VictoriaMetrics/cloud). |
| `remote_read` | Query external TSDB for historical data. |
| `storage.tsdb` | Retention / out-of-order / exemplars settings. |

**Reload config without restart:**

```bash
# Requires --web.enable-lifecycle flag on Prometheus startup
curl -X POST http://localhost:9090/-/reload
# Or: systemctl reload prometheus  (with ExecReload=SIGHUP in the unit)
sudo systemctl reload prometheus
```

**Validate config before applying:**

```bash
promtool check config /etc/prometheus/prometheus.yml
promtool check rules /etc/prometheus/rules/*.yml
```

### Reverse-proxy / TLS

Prometheus listens plain HTTP. Terminate TLS upstream (Caddy / nginx / Traefik). Set `--web.external-url=https://prometheus.example.com/` so UI links + Alertmanager alert URLs are correct.

Caddy example:

```caddy
prometheus.example.com {
    reverse_proxy localhost:9090
    basicauth {
        admin <hashed-password-from-caddy-hash-password>
    }
}
```

Prometheus has **no built-in authentication** other than TLS client certs (`--web.config.file`). For simple setups, put basic-auth at the reverse proxy. See <https://prometheus.io/docs/prometheus/latest/configuration/https/> for the upstream web config (TLS + basic-auth at the Prometheus binary level).

## Upgrade

```bash
# Binary install
sudo systemctl stop prometheus
# Download + install new version's prometheus + promtool binaries (same steps as install)
sudo systemctl start prometheus
# Schema migrations happen transparently; TSDB format is backward-compatible within major versions.

# Docker
docker pull prom/prometheus:latest
docker stop prometheus && docker rm prometheus
# Re-run docker run with the new image.
```

**Before major version bumps** (e.g. 2.x → 3.x whenever that ships): read the release notes. TSDB format changes are rare but have happened; the upgrade notes call them out.

## Gotchas

- **Prometheus is ALL pull.** Services you want monitored must expose `/metrics` endpoints. For batch jobs that can't stay running long enough to be scraped, use [Pushgateway](https://github.com/prometheus/pushgateway). Don't push samples directly to Prometheus — there's no ingest API.
- **No clustering.** A single Prometheus instance is a single point of failure for its scrape set. Run two in parallel scraping the same targets for HA; deduplicate with Alertmanager's HA clustering or a remote-write target.
- **TSDB grows unbounded without retention.** Default `--storage.tsdb.retention.time=15d`. Size headroom: estimate `bytes_per_sample × samples_per_second × seconds_in_retention`. ~1–2 bytes/sample compressed is a rule of thumb for mature Prometheus (2.x+).
- **Cardinality is the #1 footgun.** Labels with high-cardinality values (user IDs, request IDs, timestamps) blow up memory + disk. Monitor `prometheus_tsdb_head_series` and `rate(prometheus_tsdb_head_samples_appended_total[5m])`.
- **`--web.enable-lifecycle` is NOT on by default.** Without it, `POST /-/reload` + `POST /-/quit` return 403. Enable if you want to reload config via HTTP (systemd reload with SIGHUP works without it).
- **`--web.enable-admin-api` gates snapshot/delete.** Also off by default. Enable ONLY if you plan to use the admin API and understand the blast radius (can delete series, trigger snapshots).
- **No auth by default.** Anyone who reaches `:9090` can read all metrics + run PromQL. Either bind to localhost + reverse-proxy with auth, or use Prometheus's native `--web.config.file` for TLS + basic-auth.
- **Config reload can partially-apply.** If `prometheus.yml` has a syntax error, the reload returns 400 and the old config stays loaded. Check the response body for the error. `promtool check config` before reloading is the belt-and-braces move.
- **Docker image runs as `nobody` (UID 65534).** If you bind-mount a host TSDB dir, it must be writable by 65534:65534 or Prometheus won't start.
- **`remote_write` is best-effort.** If the remote side is down, Prometheus buffers in a WAL and retries, but the WAL has a max size. Long remote outages = dropped samples. Monitor `prometheus_remote_storage_samples_dropped_total`.
- **Alertmanager is a SEPARATE process.** Prometheus evaluates alerting rules and fires alerts to Alertmanager — it does not email / page anyone itself. Not running Alertmanager = fired alerts go nowhere.

## Upstream references

- Repo: <https://github.com/prometheus/prometheus>
- Docs: <https://prometheus.io/docs/>
- Installation guide: <https://prometheus.io/docs/introduction/install/>
- Downloads: <https://prometheus.io/download/>
- Configuration reference: <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>
- TLS / auth config: <https://prometheus.io/docs/prometheus/latest/configuration/https/>
- Example config (starter): <https://github.com/prometheus/prometheus/blob/main/documentation/examples/prometheus.yml>
- Alertmanager: <https://github.com/prometheus/alertmanager>
- Node Exporter: <https://github.com/prometheus/node_exporter>
- Operator (K8s): <https://github.com/prometheus-operator/kube-prometheus>
- Docker Hub: <https://hub.docker.com/r/prom/prometheus>

## TODO — verify on first deployment

- Confirm current stable version + SHA256 process at <https://prometheus.io/download/>.
- Test `--web.config.file` TLS+basic-auth flow end-to-end against a recent release.
- Verify the systemd unit against the latest upstream guidance (binary release notes sometimes adjust recommended flags).
- Test a federation + remote_write + Alertmanager triad in a single test harness to shake out config-wiring mistakes.
