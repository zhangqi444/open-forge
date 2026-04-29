---
name: glances-project
description: Glances recipe for open-forge. LGPL-3.0 cross-platform system monitoring tool — htop-on-steroids with CPU/RAM/disk/network/sensors/GPU/containers/RAID/SMART/Wi-Fi/processes/logs, optional web UI on port 61208, REST + GraphQL APIs, Prometheus exporter, InfluxDB/Graphite/Kafka/MQTT/OpenSearch/Cassandra exporters, and MCP server for AI assistants. Install via pip (with extras), uvx, pipx, Docker, Homebrew, distro packages, or Snap. Covers `[all]` vs `[web]` extras, Docker `latest-full` image, console vs web-server vs central-browser modes, and the 30+ export destinations.
---

# Glances

LGPL-3.0 cross-platform system monitor. Upstream: <https://github.com/nicolargo/glances>. Docs: <https://glances.readthedocs.io>. Live demo: `http://glances.demo.nicolargo.com`.

`htop` meets `netstat` meets `iotop` meets Grafana — a single tool that shows CPU, RAM, disk, network, processes, sensors, GPU, Docker/Podman containers, RAID, SMART health, Wi-Fi signal, public IP, cloud metadata, warnings/alerts, and more, in a single terminal or web UI. Plus a REST API, GraphQL, and built-in exporters to Prometheus/InfluxDB/Graphite/Kafka/MQTT/OpenSearch/Cassandra/etc.

## Modes of operation

1. **Console** — TUI on the local terminal (`glances`).
2. **Web server** — Browser UI on port 61208 (`glances -w`). Simple hosted dashboard for one machine.
3. **Client/server (RPC)** — Central `glances -s` server, remote `glances -c <host>` client. Binary protocol, fast.
4. **Central browser** — Connect to many Glances RPC servers from one UI (`glances --browser`).
5. **Exporter** — Push metrics to external systems (Prometheus / InfluxDB / Graphite / Kafka / etc.) for centralized dashboards.
6. **MCP server** — Expose system state to AI assistants via Model Context Protocol (`glances --mcp`). New-ish.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| PyPI + pip in venv | `pip install 'glances[all]'` | ✅ Recommended for Linux | Most Linux users. Full feature set. |
| `uvx` (one-shot) | `uvx glances` | ✅ | No-install, one-off runs. Requires `uv`. |
| `pipx` | `pipx install 'glances[all]'` | ✅ | Python app isolation without manual venv. |
| Docker (`nicolargo/glances`) | Docker Hub | ✅ Recommended for containers | Tags: `latest-full`, `latest`, `dev`, `ubuntu-latest-full`. |
| Distro packages (`apt install glances`, `dnf install glances`, etc.) | ⚠️ Usually outdated | ✅ | If you don't care about latest features. |
| Homebrew | `brew install glances` | ✅ | macOS. |
| Snap | `snap install glances` | ✅ | Ubuntu. |
| Windows binaries | <https://github.com/nicolargo/glances/releases> | ✅ | Windows — limited plugin support. |
| Build from source | `git clone && pip install -e '.[all]'` | ✅ | Contributors. |

## Pip extras (what features to install)

Per upstream README, `pip install 'glances[<extra>]'`:

| Extra | Adds |
|---|---|
| `all` | Everything (largest install) |
| `web` | Web UI (FastAPI + JavaScript frontend) |
| `containers` | Docker + Podman monitoring |
| `gpu` | NVIDIA + AMD GPU monitoring (nvidia-ml-py) |
| `sensors` | Hardware temperature/fan sensors (py-cpuinfo, etc.) |
| `smart` | SMART disk health (`pySMART`) |
| `raid` | Linux mdadm RAID arrays |
| `wifi` | Wi-Fi signal strength |
| `snmp` | SNMP remote host monitoring |
| `cloud` | Cloud provider metadata (AWS / GCP / Azure) |
| `ip` | Public IP lookup |
| `export` | All exporters (Prometheus / InfluxDB / Graphite / Kafka / etc.) |
| `graph` | Built-in time-series graphs (MatPlotLib) |
| `action` | Trigger scripts on alerts |
| `browser` | Central browser mode dependencies |
| `mcp` | MCP server for AI assistants |
| `sparklines` | Sparkline graphs |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `pip` / `pipx` / `uvx` / `docker` / `distro-pkg` / `snap` / `brew` | Drives section. |
| preflight | "Which features?" | Multi-select pip extras, OR pick `latest-full` Docker image | `[all]` is easiest; `[web,containers]` is a common minimum. |
| mode | "Mode?" | `AskUserQuestion`: `console` / `web-server` / `rpc-server+clients` / `exporter-only` | Drives run command. |
| ports | "Web UI port?" | Default `61208` (web) | Web mode. |
| ports | "RPC port?" | Default `61209` | Client/server mode. |
| export | "Exporter target?" | Optional multi-select: `prometheus` / `influxdb` / `graphite` / `mqtt` / ... | Each has its own config block in `glances.conf`. |
| auth | "Web UI password?" | Free-text (sensitive) | Enable with `--password`. Default is no auth (any viewer). |

## Install — pip in venv

```bash
python3 -m venv ~/.venv/glances
source ~/.venv/glances/bin/activate
pip install 'glances[all]'
# Alternative: 'glances[web,containers]' for a lighter install

# Run TUI
glances

# Run web UI
glances -w
# → http://<host>:61208
```

Note: Python headers required for `psutil`. On Debian/Ubuntu: `sudo apt install python3-psutil` OR `sudo apt install python3-dev gcc`.

## Install — Docker (web mode + container monitoring)

```yaml
# compose.yaml
services:
  glances:
    image: nicolargo/glances:latest-full
    container_name: glances
    restart: unless-stopped
    pid: host                                     # see host processes, not just containers
    network_mode: host                            # simplest, preserves real interface names
    environment:
      GLANCES_OPT: "-w"                           # web-server mode
      TZ: "Europe/London"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro   # Docker container metrics
      # Optional: Podman socket (rootless)
      # - /run/user/1000/podman/podman.sock:/run/user/1000/podman/podman.sock:ro
      # Optional: override the default config
      # - ./glances.conf:/etc/glances/glances.conf:ro
```

Open `http://<host>:61208/`.

### Plain docker run

```bash
docker run -d \
  --name glances \
  --restart always \
  -p 61208-61209:61208-61209 \
  -e TZ="${TZ}" \
  -e GLANCES_OPT="-w" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --pid host \
  nicolargo/glances:latest-full
```

### Image tags

- `latest` — Alpine, basic (FastAPI + Docker support)
- `latest-full` — Alpine, everything (all plugins + exporters). **Recommended.**
- `dev` — development branch, unstable
- `ubuntu-latest` / `ubuntu-latest-full` / `ubuntu-dev` — Ubuntu-based variants

## systemd service (for pip / pipx installs)

```ini
# /etc/systemd/system/glances-web.service
[Unit]
Description=Glances web server
After=network-online.target

[Service]
Type=simple
User=glances
Group=glances
ExecStart=/home/glances/.local/bin/glances -w --bind 0.0.0.0 --port 61208 --password
# If using a shared venv:
# ExecStart=/opt/glances-venv/bin/glances -w --bind 0.0.0.0 --port 61208
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin glances
sudo systemctl daemon-reload
sudo systemctl enable --now glances-web
# Web UI: http://<host>:61208
```

## Exporters — sending metrics elsewhere

Glances can push metrics continuously to external systems. Configure in `glances.conf` + start with `glances --export <name>`:

```bash
glances --export prometheus -w   # web UI + Prometheus endpoint at /metrics
glances --export influxdb2       # push to InfluxDB 2
glances --export graphite        # send to Graphite
```

Exporter list: Prometheus, InfluxDB (v1 + v2), Graphite, CSV, JSON, StatsD, Kafka, MQTT, OpenSearch, Elasticsearch, Cassandra, CouchDB, RabbitMQ, Riemann, ZeroMQ, RestAPI.

## Central Browser — one UI, many hosts

On each target:

```bash
glances -s -B 0.0.0.0      # RPC server on :61209
```

On the monitoring host:

```bash
glances --browser
```

Enter hostnames of the RPC servers → browse them all from one UI. Simple mesh without a central DB.

## REST API + GraphQL

When running in web mode (`-w`), Glances exposes:

- REST API at `/api/4/*` (e.g. `/api/4/cpu`, `/api/4/processlist`, `/api/4/all`)
- GraphQL endpoint at `/api/4/graphql`

Full schema: <https://glances.readthedocs.io/en/latest/api.html>.

Example:

```bash
curl http://localhost:61208/api/4/mem | jq
```

## Data layout

Glances is **mostly stateless** — it reads live system state on each refresh. Optional state:

| Path | Content |
|---|---|
| `~/.config/glances/glances.conf` (per-user) | Config file. Thresholds, plugin toggles, exporter settings. |
| `/etc/glances/glances.conf` (system-wide) | Default config in Docker image. |
| CSV / JSON export dirs | If using file exporters. |

No DB. No user accounts (web mode has optional HTTP Basic auth via `--password`; no multi-user). Backup = `glances.conf`.

## Upgrade procedure

### pip / pipx

```bash
pip install --upgrade glances
# or
pipx upgrade glances
```

### Docker

```bash
docker pull nicolargo/glances:latest-full
docker stop glances && docker rm glances
# Re-run
```

### Snap / Homebrew / distro

```bash
snap refresh glances
brew upgrade glances
sudo apt upgrade glances   # or dnf/pacman
```

Config file format is stable; minor version upgrades don't require migration.

## Gotchas

- **`pip install glances` without extras = NO web UI.** Very common first-timer confusion. Install `glances[web]` or `glances[all]` if you want `glances -w` to work.
- **psutil needs Python headers.** On minimal Linux images / Alpine, `pip install glances` fails cryptically. Fix: `apt install python3-dev gcc` (Debian/Ubuntu) or use `python3-psutil` system package first.
- **Web UI default has no authentication.** Anyone on the network can see your system metrics + running processes (= potentially sensitive — leaked commands, env vars in ps output). Use `--password` OR put behind a reverse proxy with auth.
- **`--password` prompts interactively on first run** to set the password, then caches it in `~/.glances_password`. For systemd: preset the file OR use `--password-badge` / `--disable-plugin sensors` + manual config.
- **`pid: host` + Docker socket = effectively root on host.** Glances in a container with `pid: host` can see all host processes; with Docker socket mount, it can control Docker. This is inherent to "monitor the host from a container" — the container is as privileged as the host. Don't expose this to untrusted networks.
- **Docker stats are from the Docker socket directly.** Containers not managed by Docker (raw runc / podman-as-systemd / Kubernetes-only) won't show. For Podman: mount the podman socket (path varies by root vs rootless).
- **`nicolargo/glances:latest-full` is ~400MB.** Not tiny. For minimal installs where you don't need all exporters, use `latest` (~200MB) or `ubuntu-latest` variants.
- **Sensors plugin requires `lm-sensors` on the host** (not just the Python package). On bare metal: `sudo apt install lm-sensors && sudo sensors-detect`. In Docker: sensors often unavailable or limited — depends on kernel module visibility into the container.
- **SMART plugin needs `smartctl` binary + CAP_SYS_RAWIO.** In Docker, requires privileged mode or specific capabilities. Most users skip SMART in containers.
- **MCP server (`--mcp`) is new and evolving.** Designed to let AI assistants query system state. Don't expose this to the internet; it's an information-disclosure pipe.
- **Exporter failures are non-fatal but silent.** If your InfluxDB is down, Glances keeps running and you have to check logs to know. Monitor the exporter side too.
- **`glances -s` RPC server has NO built-in auth by default.** Use `--password`, OR bind to a private network only, OR front with SSH tunnel / WireGuard / Tailscale.
- **Browser mode memory usage** grows with the number of monitored hosts. A "browse 50 servers" setup can hit hundreds of MB client-side.
- **Windows / macOS feature matrix is smaller than Linux.** Some plugins (RAID, sensors for some hardware, Wi-Fi) are Linux-only.
- **Distro packages are usually 6-12 months behind.** For new features (MCP, latest exporters), use pip / Docker.
- **Config keys changed between major versions.** `glances 3` → `glances 4` had some renames. Copy from the latest `glances.conf.template` rather than assuming your old config still works after upgrade.
- **Display refresh rate** (default 3 seconds) can be too aggressive on slow boxes. Use `glances -t 10` for 10-second refresh; less CPU.

## Links

- Upstream repo: <https://github.com/nicolargo/glances>
- Docs: <https://glances.readthedocs.io>
- PyPI: <https://pypi.org/project/Glances/>
- Docker Hub: <https://hub.docker.com/r/nicolargo/glances>
- Docker docs: <https://glances.readthedocs.io/en/latest/docker.html>
- API docs: <https://glances.readthedocs.io/en/latest/api.html>
- Exporters config: <https://glances.readthedocs.io/en/latest/exports.html>
- Releases: <https://github.com/nicolargo/glances/releases>
- Demo: <http://glances.demo.nicolargo.com>
- Discord / Matrix: linked from README
