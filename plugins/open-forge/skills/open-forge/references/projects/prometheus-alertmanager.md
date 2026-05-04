---
name: prometheus-alertmanager
description: Recipe for Prometheus Alertmanager — handles alerts sent by Prometheus, deduplicates/groups/routes them to receivers (email, Slack, PagerDuty, webhooks).
---

# Prometheus Alertmanager

Handles alerts fired by Prometheus (and other compatible sources). Deduplicates incoming alerts, groups related alerts together, routes them to the correct receiver (email, Slack, PagerDuty, OpsGenie, webhook, etc.), and manages silences and inhibition rules. Typically deployed alongside Prometheus. Upstream: <https://github.com/prometheus/alertmanager>. Docs: <https://prometheus.io/docs/alerting/latest/alertmanager/>. License: Apache-2.0. ~6K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/prom/alertmanager> | Yes | Recommended containerized deployment |
| Docker Compose | alongside Prometheus stack | Yes | Standard monitoring stack (Prometheus + Alertmanager + Grafana) |
| Linux binary | <https://prometheus.io/download/> | Yes | Bare-metal; runs as a systemd service |
| Helm chart (kube-prometheus-stack) | <https://github.com/prometheus-community/helm-charts> | Community | Kubernetes; bundled with Prometheus Operator |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for Alertmanager UI? | Port (default 9093) | All |
| software | Notification receivers? | email / Slack / PagerDuty / webhook / etc. | Required — at least one |
| software | SMTP server + credentials? | host:port + user/pass | Required if using email receiver |
| software | Slack webhook URL? | https://hooks.slack.com/... | Required if using Slack receiver |
| software | Grouping labels? | List of label names (default: alertname) | Optional tuning |
| software | Repeat interval? | Duration (default 4h) | How often to re-notify if alert persists |

## Software-layer concerns

### Docker Compose (with Prometheus)

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--alertmanager.url=http://alertmanager:9093'

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'

volumes:
  prometheus-data:
  alertmanager-data:
```

### Example alertmanager.yml

```yaml
global:
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager@example.com'
  smtp_auth_password: 'secretpassword'
  smtp_require_tls: true

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 30s       # wait to batch alerts into a group
  group_interval: 5m    # how long to wait before sending a new group notification
  repeat_interval: 4h   # re-send if still firing after this long
  receiver: 'default-email'
  routes:
    - match:
        severity: critical
      receiver: 'pagerduty-critical'
    - match:
        severity: warning
      receiver: 'slack-warnings'

receivers:
  - name: 'default-email'
    email_configs:
      - to: 'team@example.com'

  - name: 'slack-warnings'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        title: '{{ template "slack.default.title" . }}'
        text: '{{ template "slack.default.text" . }}'

  - name: 'pagerduty-critical'
    pagerduty_configs:
      - routing_key: 'YOUR_PAGERDUTY_ROUTING_KEY'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

### Connecting Prometheus to Alertmanager

In `prometheus.yml`:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

rule_files:
  - /etc/prometheus/rules/*.yml
```

### Example alert rule (rules/node.yml)

```yaml
groups:
  - name: node
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

Alertmanager config format is stable; review release notes for any breaking changes: <https://github.com/prometheus/alertmanager/releases>

## Gotchas

- Config reload: Alertmanager supports hot-reload via `POST /-/reload` or SIGHUP — no restart needed for config changes.
- `amtool`: the CLI tool (`amtool`) can manage silences, check config, and query alerts. Available in the Docker image: `docker exec alertmanager amtool --help`
- HA clustering: for high availability, run multiple Alertmanager instances and configure them as a cluster (mesh gossip). See `--cluster.*` flags.
- Silences vs inhibitions: silences mute alerts manually for a time window; inhibition rules automatically suppress lower-priority alerts when higher-priority ones are firing.
- `group_wait` tuning: increase `group_wait` to batch more alerts together during incident spikes; decrease it for faster notifications on isolated alerts.
- Alert deduplication: Prometheus fires alerts on each scrape cycle; Alertmanager deduplicates and only re-notifies after `repeat_interval`.

## Links

- GitHub: <https://github.com/prometheus/alertmanager>
- Docs: <https://prometheus.io/docs/alerting/latest/alertmanager/>
- Configuration reference: <https://prometheus.io/docs/alerting/latest/configuration/>
- Docker Hub: <https://hub.docker.com/r/prom/alertmanager>
- Downloads: <https://prometheus.io/download/>
