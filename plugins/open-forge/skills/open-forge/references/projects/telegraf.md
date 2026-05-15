---
name: telegraf
description: Recipe for Telegraf — open-source plugin-driven server agent for collecting, processing, aggregating, and writing metrics, logs, and events.
---

# Telegraf

Plugin-driven metrics and telemetry collection agent by InfluxData. Over 300 plugins covering system metrics, cloud services, databases, messaging systems, IoT protocols, and more. Compiles to a single static binary. Uses TOML configuration. Commonly paired with InfluxDB + Grafana (the "TIG stack") but exports to 50+ backends including Prometheus, Elasticsearch, Kafka, MQTT, and more. Upstream: <https://github.com/influxdata/telegraf>. Docs: <https://docs.influxdata.com/telegraf/>. License: MIT. ~14K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/_/telegraf> | Yes | Containerized collection agent |
| Linux package (apt/yum) | <https://docs.influxdata.com/telegraf/latest/install/> | Yes | Bare-metal/VM system metrics collection |
| Binary download | <https://github.com/influxdata/telegraf/releases> | Yes | Any platform; no package manager |
| Windows | <https://docs.influxdata.com/telegraf/latest/install/?t=Windows> | Yes | Windows system metrics (Event Log, WMI, Perfmon) |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| software | Output destination? | InfluxDB / Prometheus / Elasticsearch / Kafka / etc. | Drives outputs config |
| software | InfluxDB URL + token? | URL + API token | If using InfluxDB output |
| software | Which inputs to enable? | cpu, disk, mem, docker, mysql, etc. | Drives inputs config |
| software | Collection interval? | Duration string (default 10s) | Optional tuning |

## Software-layer concerns

### Docker Compose (with InfluxDB)

```yaml
services:
  influxdb:
    image: influxdb:2.7
    container_name: influxdb
    restart: unless-stopped
    ports:
      - "8086:8086"
    volumes:
      - influxdb-data:/var/lib/influxdb2
    environment:
      DOCKER_INFLUXDB_INIT_MODE: setup
      DOCKER_INFLUXDB_INIT_USERNAME: admin
      DOCKER_INFLUXDB_INIT_PASSWORD: password123
      DOCKER_INFLUXDB_INIT_ORG: myorg
      DOCKER_INFLUXDB_INIT_BUCKET: telegraf
      DOCKER_INFLUXDB_INIT_ADMIN_TOKEN: mytoken123

  telegraf:
    image: telegraf:1.38.4
    container_name: telegraf
    restart: unless-stopped
    volumes:
      - ./telegraf.conf:/etc/telegraf/telegraf.conf:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro  # for Docker input
    environment:
      INFLUX_TOKEN: mytoken123
    depends_on:
      - influxdb

volumes:
  influxdb-data:
```

### Example telegraf.conf

```toml
[global_tags]
  host = "$HOSTNAME"

[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""

# Output: InfluxDB v2
[[outputs.influxdb_v2]]
  urls = ["http://influxdb:8086"]
  token = "$INFLUX_TOKEN"
  organization = "myorg"
  bucket = "telegraf"

# Inputs: system metrics
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false

[[inputs.disk]]
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "iso9660", "overlay", "aufs", "squashfs"]

[[inputs.diskio]]

[[inputs.mem]]

[[inputs.system]]

[[inputs.net]]

# Input: Docker containers
[[inputs.docker]]
  endpoint = "unix:///var/run/docker.sock"
  gather_services = false
  container_names = []
  total = false
```

### Common input plugins

| Plugin | What it collects |
|---|---|
| inputs.cpu | CPU usage per core |
| inputs.mem | Memory stats |
| inputs.disk | Disk usage by mount |
| inputs.net | Network I/O |
| inputs.docker | Docker container stats |
| inputs.mysql | MySQL/MariaDB metrics |
| inputs.postgresql | PostgreSQL metrics |
| inputs.redis | Redis metrics |
| inputs.prometheus | Scrape Prometheus endpoints |
| inputs.mqtt_consumer | MQTT messages |
| inputs.kafka_consumer | Kafka messages |
| inputs.tail | Log file tailing |
| inputs.exec | Run custom scripts |

### Prometheus output (push to Prometheus Pushgateway or scrape endpoint)

```toml
# Expose metrics for Prometheus to scrape
[[outputs.prometheus_client]]
  listen = ":9273"
  metric_version = 2
```

## Upgrade procedure

```bash
# Docker
docker compose pull && docker compose up -d

# Linux package
sudo apt update && sudo apt upgrade telegraf
sudo systemctl restart telegraf
```

## Gotchas

- Docker socket access: to collect Docker container metrics, mount `/var/run/docker.sock` into the Telegraf container and ensure the container user has access (add to `docker` group or run as root).
- Config validation: test config before deploying: `telegraf --config telegraf.conf --test`
- Plugin discovery: with 300+ plugins, use the docs to find the right one: <https://docs.influxdata.com/telegraf/latest/plugins/>
- InfluxDB v1 vs v2: use `[[outputs.influxdb]]` for v1 and `[[outputs.influxdb_v2]]` for v2. They are different plugins with different auth models.
- Batching: set `metric_batch_size` and `flush_interval` appropriately for your write load. Large batches reduce write overhead.
- Windows: Windows-specific inputs (Event Log, Management Instrumentation) require running Telegraf as a Windows Service.

## Links

- GitHub: <https://github.com/influxdata/telegraf>
- Docs: <https://docs.influxdata.com/telegraf/>
- Plugin directory: <https://docs.influxdata.com/telegraf/latest/plugins/>
- Docker Hub: <https://hub.docker.com/_/telegraf>
- Releases: <https://github.com/influxdata/telegraf/releases>
- Install guide: <https://docs.influxdata.com/telegraf/latest/install/>
