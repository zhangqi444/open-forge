---
name: fluent-bit
description: Recipe for Fluent Bit — lightweight, high-performance telemetry agent for collecting, processing, and forwarding logs, metrics, and traces. CNCF graduated project.
---

# Fluent Bit

Lightweight, high-performance telemetry agent. Collects logs, metrics, and traces from any source; processes and transforms data; forwards to any destination (Elasticsearch, OpenSearch, Loki, Splunk, Kafka, S3, InfluxDB, and 70+ more). Sub-1 MB binary with minimal CPU and memory footprint — designed for containers, edge, and embedded environments. CNCF graduated project, part of the Fluentd ecosystem. Upstream: <https://github.com/fluent/fluent-bit>. Docs: <https://docs.fluentbit.io>. License: Apache-2.0. ~6K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/fluent/fluent-bit> | Yes | Recommended containerized agent |
| Linux packages (deb/rpm) | <https://docs.fluentbit.io/manual/installation/linux/> | Yes | Bare-metal system log agent |
| Helm chart | <https://github.com/fluent/helm-charts> | Yes | Kubernetes DaemonSet for cluster-wide log collection |
| Windows | <https://docs.fluentbit.io/manual/installation/windows> | Yes | Windows log collection |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | Log sources to collect? | docker / systemd / files / syslog / OTLP | Drives input plugins |
| software | Destination backend? | Loki / Elasticsearch / OpenSearch / S3 / Kafka / etc. | Drives output plugins |
| software | Parse log format? | json / regex / logfmt / nginx / apache | Drives parser config |

## Software-layer concerns

### Docker run (forward logs to Loki)

```bash
docker run -d \
  --name fluent-bit \
  -v /var/log:/var/log:ro \
  -v ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro \
  --restart unless-stopped \
  fluent/fluent-bit:latest
```

### Docker Compose (sidecar or standalone agent)

```yaml
services:
  fluent-bit:
    image: fluent/fluent-bit:latest
    container_name: fluent-bit
    restart: unless-stopped
    volumes:
      - ./fluent-bit.conf:/fluent-bit/etc/fluent-bit.conf:ro
      - ./parsers.conf:/fluent-bit/etc/parsers.conf:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    environment:
      LOKI_HOST: loki
      LOKI_PORT: 3100
```

### fluent-bit.conf (forward logs to Loki)

```ini
[SERVICE]
    Flush         5
    Daemon        Off
    Log_Level     info
    Parsers_File  parsers.conf

[INPUT]
    Name          tail
    Path          /var/log/*.log
    Parser        json
    Tag           host.logs
    Refresh_Interval 10

[INPUT]
    Name          systemd
    Tag           host.systemd
    Systemd_Filter _SYSTEMD_UNIT=docker.service
    Read_From_Tail On

[FILTER]
    Name          record_modifier
    Match         *
    Record        hostname ${HOSTNAME}

[OUTPUT]
    Name          loki
    Match         *
    Host          ${LOKI_HOST}
    Port          ${LOKI_PORT}
    Labels        job=fluent-bit,env=production
    Auto_Kubernetes_Labels On
```

### Common input plugins

| Plugin | What it collects |
|---|---|
| tail | Tail log files |
| systemd | Systemd journal |
| docker | Docker container logs (via socket) |
| syslog | Syslog (UDP/TCP) |
| forward | Fluentd forward protocol |
| opentelemetry | OTLP traces, metrics, logs |
| mqtt | MQTT topics |
| tcp | Raw TCP input |

### Common output plugins

| Plugin | Destination |
|---|---|
| loki | Grafana Loki |
| es | Elasticsearch / OpenSearch |
| kafka | Apache Kafka |
| s3 | Amazon S3 (or S3-compatible) |
| splunk | Splunk HEC |
| influxdb | InfluxDB |
| forward | Fluentd / another Fluent Bit |
| stdout | Console (for debugging) |
| http | Generic HTTP endpoint |

### Kubernetes DaemonSet (Helm)

```bash
helm repo add fluent https://fluent.github.io/helm-charts
helm install fluent-bit fluent/fluent-bit \
  --namespace logging \
  --create-namespace \
  -f values.yaml
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

Check the changelog for breaking config changes: <https://github.com/fluent/fluent-bit/releases>

## Gotchas

- Fluent Bit vs Fluentd: Fluent Bit is a lightweight agent (forward/collect); Fluentd is a heavier aggregator (transform/route). Common pattern: Fluent Bit on every node → Fluentd or Loki aggregator.
- Config syntax: Fluent Bit uses its own INI-style config. YAML config is supported since v1.9 as an alternative.
- Backpressure: configure `storage.type filesystem` and `storage.backlog.mem_limit` to prevent memory spikes when downstream is slow.
- Kubernetes metadata: the `kubernetes` filter auto-enriches log records with pod name, namespace, labels — essential for structured log routing in K8s.
- Buffer and retry: configure `Retry_Limit` and `storage.type` to handle output failures gracefully and avoid log loss.

## Links

- GitHub: <https://github.com/fluent/fluent-bit>
- Docs: <https://docs.fluentbit.io>
- Docker Hub: <https://hub.docker.com/r/fluent/fluent-bit>
- Helm charts: <https://github.com/fluent/helm-charts>
- Plugin list: <https://docs.fluentbit.io/manual/pipeline/inputs>
