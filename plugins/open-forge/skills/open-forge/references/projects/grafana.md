---
name: grafana-project
description: Grafana recipe for open-forge. AGPL-3.0 open-source observability + data visualization. Covers the official Docker image (`grafana/grafana` for OSS, `grafana/grafana-enterprise` for commercial), provisioning via YAML datasources/dashboards, and the typical Prometheus + Grafana stack with Loki for logs. Flag: Grafana is a visualization layer — it queries OTHER data sources (Prometheus, Loki, InfluxDB, Elasticsearch, Postgres, MySQL, etc.); self-hosting Grafana alone is half the story.
---

# Grafana (observability + data visualization)

AGPL-3.0 (with Apache-2.0 exceptions — see LICENSING.md) open-source platform for visualizing, exploring, and alerting on metrics / logs / traces. Data-source-agnostic — connects to Prometheus, Loki, InfluxDB, Elasticsearch, Postgres, MySQL, CloudWatch, BigQuery, and ~80 others.

**Upstream README:** https://github.com/grafana/grafana/blob/main/README.md
**Docs:** https://grafana.com/docs/grafana/latest/
**Install docs:** https://grafana.com/docs/grafana/latest/setup-grafana/installation/
**Docker image:** `grafana/grafana` (OSS) or `grafana/grafana-enterprise` (requires license)

## Architecture note

Grafana is a **visualization layer**, not a data store. A "Grafana deployment" typically means:

1. Grafana itself (this recipe)
2. One or more data sources it queries — Prometheus for metrics, Loki for logs, Tempo/Jaeger for traces, any SQL DB, etc.

This recipe covers (1). For the classic "self-host the metrics stack" pattern, combine with:
- `prometheus.md` (metrics scraper + TSDB) — TODO
- `loki.md` (log aggregation) — TODO
- `tempo.md` (traces) — TODO

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | `docker run grafana/grafana` |
| localhost | native (apt/dnf/brew) | ✅ | Grafana ships first-party packages |
| byo-vps | Docker | ✅ | Typical self-host pattern |
| byo-vps | Docker Compose | ✅ | Usually bundled with Prometheus in one compose |
| aws/ec2 | Docker | ✅ | `t3.small` for a personal install |
| kubernetes | official Helm | ✅ | `grafana/helm-charts` (first-party) |
| Grafana Cloud | hosted | ✅ | Upstream SaaS with a generous free tier |
| raspberry-pi | Docker (arm64) | ✅ | |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Grafana on?" | Free-text | e.g. `grafana.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| admin | "Admin username?" | Free-text (default `admin`) | `GF_SECURITY_ADMIN_USER` |
| admin | "Admin password?" | Free-text (sensitive) | `GF_SECURITY_ADMIN_PASSWORD`. **First boot uses this or defaults to `admin` — change it.** |
| auth | "External auth (OAuth / LDAP / OIDC)?" | AskUserQuestion: none / Google / GitHub / OIDC / LDAP | Optional; can configure later |
| smtp | "Outbound email for alerts + password reset?" | AskUserQuestion: Resend / SendGrid / Mailgun / Skip | |
| data | "Data sources to pre-provision?" | Free-text | e.g. `Prometheus at http://prometheus:9090` — can be YAML-provisioned |
| edition | "OSS or Enterprise?" | AskUserQuestion: OSS (default) / Enterprise | Enterprise requires a license key from Grafana |

## Install methods

### 1. Docker (upstream canonical)

Source: https://grafana.com/docs/grafana/latest/setup-grafana/installation/docker/

```bash
docker run -d --name=grafana \
  -p 3000:3000 \
  -v grafana-storage:/var/lib/grafana \
  -e GF_SECURITY_ADMIN_PASSWORD=<strong-password> \
  --restart unless-stopped \
  grafana/grafana:latest
```

Web UI: `http://localhost:3000`. Default login `admin` / whatever you set (or `admin`/`admin` if unset — forces a password change on first login).

### 2. Docker Compose (typical observability stack)

Grafana's own repo doesn't ship a prod compose (the one in-repo is dev-only). The canonical pattern — Grafana + Prometheus — looks like:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus

  grafana:
    image: grafana/grafana:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    depends_on:
      - prometheus
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD}
      GF_SERVER_ROOT_URL: https://${GRAFANA_DOMAIN}/
      GF_SERVER_DOMAIN: ${GRAFANA_DOMAIN}
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./grafana-provisioning:/etc/grafana/provisioning:ro

volumes:
  prometheus-data:
  grafana-storage:
```

With `./grafana-provisioning/datasources/prometheus.yml`:

```yaml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
    access: proxy
    isDefault: true
```

### 3. Native packages

Source: https://grafana.com/docs/grafana/latest/setup-grafana/installation/

**Debian/Ubuntu:**

```bash
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update && sudo apt-get install -y grafana
sudo systemctl enable --now grafana-server
```

**Fedora/RHEL:** `yum install grafana` (after adding the Grafana YUM repo per docs).

**macOS:** `brew install grafana`.

Service runs on `:3000`. Config at `/etc/grafana/grafana.ini`.

### 4. Helm (official)

Source: https://github.com/grafana/helm-charts

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana grafana/grafana
```

Deploys Grafana to k8s. Many values to tune; see the chart's README.

## Software-layer concerns

### Key env vars

Grafana's config is `grafana.ini`. Any setting can be overridden via env var by converting `[section] key = value` to `GF_<SECTION>_<KEY>=<value>` (uppercase, underscores). Some useful ones:

| Var | Purpose |
|---|---|
| `GF_SECURITY_ADMIN_USER` | Admin username (default `admin`) |
| `GF_SECURITY_ADMIN_PASSWORD` | Admin password on first boot |
| `GF_SERVER_DOMAIN` | Public domain; affects generated URLs |
| `GF_SERVER_ROOT_URL` | Full public URL (include trailing slash); critical for OAuth redirects |
| `GF_DATABASE_TYPE` | `sqlite3` (default), `mysql`, `postgres` |
| `GF_DATABASE_URL` | e.g. `postgres://user:pass@host/db?sslmode=require` |
| `GF_AUTH_ANONYMOUS_ENABLED` | `true` for public dashboards |
| `GF_AUTH_GOOGLE_ENABLED` etc. | OAuth providers |
| `GF_SMTP_ENABLED`, `GF_SMTP_HOST`, `GF_SMTP_USER`, `GF_SMTP_PASSWORD` | Outbound mail |
| `GF_FEATURE_TOGGLES_ENABLE` | Comma-separated feature flags |

Full ref: the `conf/defaults.ini` in the repo documents every key with comments.

### Paths

| Thing | Path (container) |
|---|---|
| Data (SQLite DB, plugins, sessions) | `/var/lib/grafana/` |
| Config | `/etc/grafana/grafana.ini` |
| Provisioning (datasources, dashboards, alerting) | `/etc/grafana/provisioning/` |
| Custom plugins | `/var/lib/grafana/plugins/` |

### Provisioning (declarative setup)

Drop YAML files into `/etc/grafana/provisioning/{datasources,dashboards,alerting,plugins}/` and Grafana reads them on boot. Example dashboards:

```yaml
# /etc/grafana/provisioning/dashboards/default.yml
apiVersion: 1
providers:
  - name: 'default'
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

Then drop `.json` dashboard exports into `/var/lib/grafana/dashboards/`. Grafana picks them up on restart.

### Database

Default is SQLite — fine up to hundreds of dashboards. For HA / horizontal scale, use Postgres or MySQL (`GF_DATABASE_*`). SQLite is embedded; Grafana handles it transparently.

### Reverse proxy

Trivial — no WebSocket requirements in Grafana core (Live features use WS; most installs don't need it). Caddy:

```caddy
grafana.example.com {
  reverse_proxy 127.0.0.1:3000
}
```

Set `GF_SERVER_ROOT_URL=https://grafana.example.com/` so generated links (password reset, invite) use HTTPS.

### Plugins

Install via `grafana-cli plugins install <plugin-id>` or mount a pre-populated `/var/lib/grafana/plugins/`. Env var: `GF_INSTALL_PLUGINS=plugin1,plugin2` at container start.

## Upgrade procedure

Upstream release notes: https://grafana.com/docs/grafana/latest/release-notes/

**Docker:**

```bash
docker pull grafana/grafana:latest
docker stop grafana && docker rm grafana
docker run ... (same command)
```

**Native:**

```bash
sudo apt update && sudo apt upgrade grafana
sudo systemctl restart grafana-server
```

Grafana migrates its DB schema on startup. Watch logs: `docker logs -f grafana` for `Migrations complete`. Rollback = restore DB backup + downgrade the image tag.

## Gotchas

- **Default admin password is `admin`.** If you don't set `GF_SECURITY_ADMIN_PASSWORD`, Grafana asks you to change `admin` on first login — but only if you *log in*. Automation that hits the API before a human logs in can leave the default in place. Always set the env var.
- **`GF_SERVER_ROOT_URL` must match public URL exactly.** OAuth callbacks, password-reset emails, invite links — all use this. Mismatch and you'll see loops or broken links.
- **AGPL since 2021.** If you fork + deploy publicly, you must share source. Using stock Grafana is fine. Enterprise is separately licensed.
- **Grafana queries data sources each render.** Complex dashboards can hammer Prometheus / Loki. Use `refresh=5m` defaults (not 5s), use query caching (enabled by default in newer versions).
- **Plugin installs need container rebuild (ish).** Either bake plugins into a custom image, use `GF_INSTALL_PLUGINS`, or persist `/var/lib/grafana/plugins/` in a volume.
- **Anonymous access is per-org.** `GF_AUTH_ANONYMOUS_ORG_NAME=Main Org.` is needed alongside `GF_AUTH_ANONYMOUS_ENABLED=true`.
- **Alerting has two systems.** Legacy "dashboard alerting" (pre-v8) vs unified alerting (v8+). Migrate old alerts when upgrading across v8. Upstream provides migration guidance.
- **SQLite corrupts on unclean shutdown.** Rare but real. For prod, use Postgres. For home use, SQLite + daily backup is fine.
- **Enterprise vs OSS image.** `grafana/grafana-enterprise` requires a license key; without one, it runs in OSS-equivalent mode + nags.
- **Docker volume mode.** The image runs as UID 472 by default. If bind-mounting a host path, `chown -R 472:472 /host/path` or pass `--user` matching host ownership.

## TODO — verify on subsequent deployments

- [ ] Exercise provisioning-only setup (no UI clicks) end-to-end for CI-driven dashboards.
- [ ] Postgres-backed Grafana for HA — confirm auth/session consistency across replicas.
- [ ] OIDC with Authelia / Authentik / Pocket ID — worked `GF_AUTH_GENERIC_OAUTH_*` config.
- [ ] Document minimum Prometheus + Loki + Tempo bundle for a full observability stack.
- [ ] Grafana-Cloud comparison — when does self-host pay off vs Cloud free tier?
