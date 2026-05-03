---
name: monitoring
description: Cross-cutting monitoring module for open-forge — uptime checks / TLS-cert-expiry watchers / log aggregation / metrics + alerting patterns for deployed recipes. Loaded by recipes that need ongoing observability beyond "the container is running." Default recommendation is Uptime Kuma for solo / hobby deploys; falls through to Grafana + Prometheus + Loki (the 'big three') for serious self-hosters; optional alerting via ntfy.sh / Pushover / SMTP / Discord.
---

# Monitoring module

Every long-running deploy needs *some* answer to *"is this still working?"* — beyond just *"the container hasn't crashed yet."* This module covers the cross-cutting monitoring patterns recipes can reference instead of inventing per-recipe observability.

> **Operating Principle reminder.** Per CLAUDE.md operating principle #2 (*"Towards production-ready architecture"*): even single-node hobby deploys should be on a path to monitoring. Don't write recipes that "work" but leave the operator unable to tell when they've stopped working.

## What's worth monitoring — per recipe

Recipes specify their **monitoring-relevant signals** in a `## Monitoring` section (typically after `## Backup`). Common categories:

| Category | Examples | Failure mode if unmonitored |
|---|---|---|
| **Uptime / external reachability** | HTTPS endpoint returns 200 / 30x; mail port 587 accepts STARTTLS | Site dies silently; users hit a blank page or timeouts before you notice |
| **TLS cert expiry** | Let's Encrypt renewal happened; cert valid > 14 days | Cert expires Saturday morning; site goes red until Monday morning |
| **DNS resolution** | `dig +short ${CANONICAL_HOST}` resolves | A registrar issue / IP change drops resolution — site unreachable from the wider internet |
| **Disk usage** | `/var/lib/docker`, recipe-specific data dirs | Disk fills up at 3am; container crash loops; nothing you do works until you SSH in and `du -sh` |
| **Container / process health** | App container running; not restart-looping | Service silently degrades into a restart loop; stale data served from cache |
| **Database connectivity** | App can connect; query latency p99 reasonable | Network blip → app stuck on stale errors; reconnection logic is often broken |
| **Outbound deliverability** | SMTP test sends arrive; bounce rate < 5% | Newsletter / password-reset emails silently failing; users locked out |
| **Backup-success signal** | Yesterday's `restic backup` exit code was 0 | Backups silently fail for weeks; first restore attempt fails catastrophically |

The recipe states what's worth watching for that specific app. This module covers **how** to watch it.

## Choosing a monitoring approach

| Approach | When to pick | Effort |
|---|---|---|
| **Uptime Kuma** (single-service, web UI, ~50 MB RAM) | Solo / hobby deploys; you want endpoints checked + alert when they fail; don't need metrics or logs | Lowest — `docker run` once, point at URLs |
| **Healthchecks.io** (managed cron-monitoring) | When the thing you're monitoring is *jobs* (cron / restic / borg) more than HTTP endpoints; managed > self-hosted for a $0 Personal tier | Lowest |
| **Grafana + Prometheus + Loki** (the 'big three') | Serious self-host; you want metrics + logs + dashboards; 5+ services to monitor; willing to learn PromQL | Medium — 3-4 GB RAM minimum, real config burden |
| **Beszel** (single-binary, ~30 MB) | Multi-host server-monitoring with a clean dashboard; you don't care about app-level metrics, just per-host CPU/RAM/disk/network | Low |
| **Glances + a Glances exporter** | Per-host system metrics; drop into the Grafana stack via the Glances Prometheus exporter | Low (if you already have Grafana) |
| **SigNoz** (OpenTelemetry-native APM) | App-level traces + logs + metrics under one observability backend; you have a Node / Python / Java app emitting OpenTelemetry | Medium-high |
| **Application-level monitoring** (Ghost's `/ghost/health`, Plausible's `/ping`, Mastodon's `/health`) | When upstream ships a health endpoint — check it directly | Low — usually just a curl |

**Default recommendation for open-forge recipes**: **Uptime Kuma** for the simple "is this thing up?" / TLS-expiry watch. **Grafana stack** if the user has 5+ deploys and wants a unified pane. Recipes don't dictate; they recommend.

---

## Pattern 1 — Uptime Kuma (recommended default)

> **Source**: <https://github.com/louislam/uptime-kuma> + recipe at `references/projects/uptime-kuma.md`.

Uptime Kuma is the de-facto "check a URL on a schedule and tell me when it goes down" tool. Single Docker image, browser-driven setup, ships with notification adapters for ntfy / Pushover / Slack / Discord / Telegram / generic webhook / email.

### Install

If not already in the user's homelab, deploy via the `uptime-kuma` recipe (see catalog). Standalone Docker:

```bash
docker run -d --restart=always \
  --name uptime-kuma \
  -p 3001:3001 \
  -v uptime-kuma-data:/app/data \
  louislam/uptime-kuma:1
```

Open `http://<host>:3001`, create the first admin (first-user-becomes-admin pattern), then add monitors via the web UI.

### What to monitor for an open-forge deploy

Per recipe, add these monitor types in Uptime Kuma:

| Monitor type | What to set | Catches |
|---|---|---|
| **HTTPS** with keyword/status check | URL = `https://${CANONICAL_HOST}/`; Expected status 200-299 (or 30x if you redirect-by-design); optional keyword from page body | Site down, 500s, white-page-of-death from a misconfigured config file |
| **HTTPS** with cert-expiry check | Same URL; toggle "Certificate Expiry Notification" + set days (default 7, recommend 14) | Cert about to expire; renewal failed |
| **DNS** | Hostname = `${CANONICAL_HOST}`; Resolver = `1.1.1.1`; Expected = your server IP | Registrar / DNS-provider issue; A-record reverted |
| **Ping (ICMP)** | Server IP | Network-layer reachability (sanity check distinct from HTTPS) |
| **TCP** for non-HTTP services | e.g. SMTP `${HOST}:587`, IMAP `${HOST}:993` | Mail port closed / firewall change |
| **Push** for cron jobs | (run `curl <url>` from a cron / restic post-hook) | Detects *missed* runs, not just failed ones |

### Notifications

Uptime Kuma → Settings → Notifications. Recommended priority order:

1. **ntfy.sh** (free, push to phone, no signup)
2. **Pushover** ($5 one-time, more reliable / configurable)
3. **Discord webhook** (if you're on Discord anyway)
4. **Email** (always works; goes to spam if your SMTP is the thing that broke)
5. **SMS** (Twilio etc.) — last resort, costs per message

For the *"this is critical, page me"* tier: also wire a short-form SMS path, OR use Healthchecks.io's escalation feature (their tier handles "ping me, then page me 5 minutes later if no ack").

### Status page

Uptime Kuma has a built-in public status page. For users who self-host services others depend on (family / small team), publish at `https://status.${APEX}/` — it's the polite thing to do.

---

## Pattern 2 — Healthchecks.io for cron + backup monitoring

> **Source**: <https://healthchecks.io/docs/> (managed) and <https://github.com/healthchecks/healthchecks> (self-hosted).

When the thing being monitored is a **scheduled job** (restic backup, cron rotation, periodic data sync) rather than an HTTP endpoint, Healthchecks.io is the right shape. You give it an expected schedule + grace period; it pages you if a ping doesn't arrive on time.

```bash
# After your restic backup succeeds, ping Healthchecks
restic backup ... && curl -fsS -m 10 --retry 5 -o /dev/null \
  https://hc-ping.com/<your-uuid>

# Or the systemd timer service way:
[Service]
ExecStart=/usr/local/bin/restic-backup.sh
ExecStartPost=/bin/sh -c 'curl -fsS -m 10 --retry 5 -o /dev/null https://hc-ping.com/<your-uuid>'
```

If `restic-backup.sh` doesn't run for 25 hours (its grace period), Healthchecks pages you. Free tier supports 20 monitors.

For self-host: see `references/projects/healthchecks.md` (in catalog).

---

## Pattern 3 — Grafana + Prometheus + Loki (serious-self-host)

> **Sources**: catalog recipes for `grafana.md`, `prometheus.md`, `loki.md`. Install via Compose: <https://github.com/grafana/loki/tree/main/production/docker-compose>

For users running 5+ deploys who want a unified observability pane.

### Install via Compose

`docker-compose.yml`:

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prom_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
    restart: unless-stopped

  loki:
    image: grafana/loki:latest
    volumes:
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: unless-stopped

  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./promtail.yml:/etc/promtail/config.yml:ro
    command: -config.file=/etc/promtail/config.yml
    restart: unless-stopped

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GF_ADMIN_PW:?set in .env}
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped

volumes:
  prom_data:
  loki_data:
  grafana_data:
```

`prometheus.yml`:

```yaml
global:
  scrape_interval: 30s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node_exporter
    static_configs:
      - targets: ['<host-ip>:9100']      # install node_exporter on each host you want OS metrics for

  - job_name: cadvisor
    static_configs:
      - targets: ['<host-ip>:8080']      # install cAdvisor for per-container metrics
```

Grafana → connect Prometheus + Loki as data sources → import community dashboards (1860 = node-exporter; 13639 = Loki; per-app dashboards in their respective recipes).

### What gets scraped

| Source | What it gives you |
|---|---|
| `node_exporter` (one per host) | CPU / RAM / disk / network / load average |
| `cAdvisor` (one per host) | Per-container resource usage |
| App `/metrics` endpoints (where exposed) | App-level metrics (request rate, error rate, latency p99) |
| `blackbox_exporter` | HTTPS / DNS / TCP probes from outside the host |
| Promtail → Loki | Container stdout / file logs, queryable by label |

### Alerting

Prometheus's Alertmanager handles alert fan-out. Common rules:

```yaml
groups:
  - name: open-forge-deploys
    rules:
      - alert: HighDiskUsage
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.10
        for: 5m
        labels: { severity: warning }
        annotations:
          summary: "Disk on {{ $labels.instance }} is over 90% full"

      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels: { severity: critical }
        annotations:
          summary: "{{ $labels.job }} on {{ $labels.instance }} is down"

      - alert: TLSCertExpiry
        expr: probe_ssl_earliest_cert_expiry - time() < 14 * 24 * 3600
        for: 1h
        labels: { severity: warning }
        annotations:
          summary: "Cert for {{ $labels.instance }} expires in < 14 days"
```

Wire Alertmanager → ntfy / Pushover / PagerDuty / email per the [Alertmanager config docs](https://prometheus.io/docs/alerting/latest/configuration/).

---

## Pattern 4 — Beszel (multi-host system monitoring)

> **Source**: <https://github.com/henrygd/beszel> + recipe at `references/projects/beszel.md`.

When you have 3+ hosts but don't want the Grafana-stack setup burden. Beszel is single-binary, lightweight (~30 MB), gives you per-host CPU/RAM/disk/network plus per-container metrics in a clean web UI.

```bash
# Hub (one host — the one you'll browse the dashboard from)
docker run -d --name beszel \
  -p 8090:8090 \
  -v beszel_data:/beszel_data \
  henrygd/beszel

# Agent (every host you want monitored, including the hub host)
docker run -d --name beszel-agent \
  --network host \
  --restart unless-stopped \
  -e PORT=45876 \
  -e KEY="<public key from hub UI>" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  henrygd/beszel-agent
```

No PromQL, no scrape configs — just the dashboard. Use this when "give me a dashboard of my hosts" is the whole need.

---

## Pattern 5 — Application-level health endpoints

Many apps ship a `/health` (or similar) endpoint that exposes app-aware state — DB connectivity, cache reachability, subsystem statuses. Always prefer this over generic HTTP probes when available.

| App | Health endpoint | What it actually checks |
|---|---|---|
| Ghost | `GET /ghost/api/admin/site/` | Server up; DB reachable |
| Mastodon | `GET /health` | Web tier up |
| Plausible | `GET /api/health` | Web tier; ClickHouse reachable |
| Nextcloud | `GET /status.php` | App + DB + filesystem state (JSON) |
| Vaultwarden | `GET /alive` | Server up; DB reachable |
| Open WebUI | `GET /health` | Backend up |
| Grafana | `GET /api/health` | Server + DB |

Recipes call these out in their `## Monitoring` section. Uptime Kuma + keyword check is the simplest way to consume them.

---

## Recipe integration pattern

Recipes reference this module from a `## Monitoring` section (typically after `## Backup` and before `## Gotchas`). Standard shape:

```markdown
## Monitoring

What's worth watching for `<recipe>`:

| Signal | Where | Suggested check |
|---|---|---|
| HTTPS uptime | `https://${CANONICAL_HOST}/` | Uptime Kuma → HTTPS monitor; expect 200 |
| Health endpoint | `https://${CANONICAL_HOST}/health` | Uptime Kuma → HTTPS + keyword check; expect `"ok"` |
| TLS cert | `${CANONICAL_HOST}:443` | Uptime Kuma → cert-expiry notification; alert at 14 days |
| Outbound mail | (cron or app log) | Healthchecks.io ping after newsletter / digest send |
| Disk usage | `/opt/<deployment>/data/` | node_exporter + Grafana alert at 90% |

Default approach: Uptime Kuma — see [`references/modules/monitoring.md`](../modules/monitoring.md) § *Pattern 1*.

For 5+ deploys / unified pane: Grafana + Prometheus + Loki — see § *Pattern 3*.

Recipe-specific gotchas:

- [List any app-specific quirks: e.g. "the /health endpoint returns 200 even when DB is down — also probe a real query path"]
```

---

## Common gotchas (cross-cutting)

- **Monitoring the host that runs your monitoring is circular.** If Uptime Kuma is on the same VM as the apps it monitors, a host-wide outage takes both down and you get no alert. Either run Uptime Kuma on a separate host (low-end VPS / Raspberry Pi at home) or use a managed service like Healthchecks.io / UptimeRobot for the *"is the homelab itself reachable"* tier.
- **Alert fatigue is real.** Set thresholds that fire only on genuine problems. *"Site returned 5xx for 2 minutes"* is a real issue; *"latency p50 jumped from 80 ms to 90 ms"* is noise. Tune over the first 2 weeks of monitoring; expect a half-dozen rule revisions before it settles.
- **No alerts != all good.** A monitor that's silently broken (Uptime Kuma's container died; Healthchecks.io API key expired) looks identical to "everything is fine." Set up a meta-monitor: Healthchecks.io → ping when Uptime Kuma is reachable, page if not.
- **Default Grafana admin password.** Set `GF_SECURITY_ADMIN_PASSWORD` explicitly. The default `admin/admin` was a self-host classic for years; Grafana now forces password change on first login but the env-var override is still cleaner.
- **Loki log retention costs disk.** Default config keeps everything forever. Set `retention_period: 168h` (7 days) and `retention_enabled: true` in `loki.yaml` unless you specifically need historical logs.
- **Metric cardinality explosion.** A label like `user_id` or `request_id` sounds useful — until Prometheus eats your RAM at 10k unique values. Avoid high-cardinality labels.
- **Cert expiry alerts at 7 days are too late.** Let's Encrypt renews at 30-day mark; if renewal failed, you want to know around day 14, not day 7. Set 14-day alerts.
- **Monitoring backups separately is mandatory.** A backup that silently fails for weeks is undetectable from the running system. Pair `references/modules/backups.md` with a Healthchecks.io ping in the backup script's success path.

---

## TODO — verify on subsequent deployments

- [ ] First end-to-end Grafana-stack deploy on a real host — verify the Compose file as written; confirm community dashboards 1860 + 13639 still match upstream's data shape.
- [ ] Document SigNoz setup as Pattern 6 once a recipe needs it (currently nothing in the catalog requires distributed tracing).
- [ ] Add per-cloud "use the cloud's native monitoring instead" pointers (CloudWatch / Azure Monitor / GCP Operations Suite / Hetzner Cloud Monitoring) — sometimes the cloud's own thing is sufficient and removes the self-host burden.
- [ ] Verify ntfy / Pushover / Discord webhook adapters in Uptime Kuma still work (they drift; upstream releases break adapters periodically).
- [ ] Write a "monitoring the monitor" cross-check pattern — Healthchecks.io as the canary for self-hosted Uptime Kuma — once a real deploy uses it.
