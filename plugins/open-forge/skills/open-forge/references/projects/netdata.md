---
name: netdata-project
description: Netdata recipe for open-forge. GPLv3+ real-time monitoring agent. Single-binary / single-container; designed to run on every host you want to monitor. Covers the kickstart.sh native installer, the official Docker image with its full host-mount set, and the Netdata Cloud parent-child hybrid (self-host the agents, use cloud for cross-host dashboards — or self-host a "parent" agent as your own aggregator).
---

# Netdata (real-time monitoring)

GPLv3+ infrastructure monitoring agent. Runs per-host, scrapes ~3000 metrics per second per node by default, has built-in alerting, correlation, logs, ML-based anomaly detection.

**Upstream README:** https://github.com/netdata/netdata/blob/master/README.md
**Docker install doc (canonical):** https://github.com/netdata/netdata/blob/master/packaging/docker/README.md
**Install docs:** https://learn.netdata.cloud/docs/installing-netdata

## Architecture note

Netdata has **two deployment shapes** and they get conflated:

1. **Local agent only** — install Netdata on each host; browse each host's dashboard at `http://host:19999/`. Fully self-hosted, no cloud account.
2. **Parent-child ("Netdata Cloud" or own parent)** — run Netdata agents on all hosts, stream their metrics to a central "parent" node (which is just another Netdata agent configured to receive). Centralized dashboards either via Netdata Cloud (SaaS) or your own parent + reverse proxy.

Both are first-party. Netdata Cloud is the easy button; self-hosted parent is the zero-phone-home option.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | native (`kickstart.sh`) | ✅ | One-liner — auto-detects package manager |
| localhost | Docker | ✅ | Heavy mount set required |
| per-host | native | ✅ default | Netdata is designed to run everywhere you want monitoring |
| aws/ec2 | native or Docker | ✅ | |
| hetzner/cloud-cx | native | ✅ | |
| raspberry-pi | native | ✅ | Officially supported, including arm64 + armhf |
| kubernetes | official Helm | ✅ | Upstream ships a Helm chart at `github.com/netdata/helmchart` |
| parent-child | two Netdata agents | ✅ | One configured as "parent" receiver; others stream to it |

Netdata is not a "deploy on one server and point clients at it" app — it's a "install on every server you want metrics from" app.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| mode | "Install Netdata locally, or set up a parent for centralized dashboards?" | AskUserQuestion: standalone / parent-child | |
| mode | "For parent-child: is this node the parent or a child?" | AskUserQuestion: parent / child | |
| exposure | "Expose the :19999 dashboard publicly?" | AskUserQuestion: localhost-only / reverse-proxied / public | Public is inadvisable — lots of info disclosed |
| cloud | "Connect to Netdata Cloud (optional SaaS)?" | AskUserQuestion: Yes / No | If yes, needs a claim token |
| dns | "Domain for dashboard (if reverse-proxied)?" | Free-text | |

## Install methods

### 1. kickstart.sh (native, upstream-canonical)

Source: https://github.com/netdata/netdata/blob/master/README.md

```bash
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh \
  && sh /tmp/netdata-kickstart.sh
```

Detects distro and uses the best available install mechanism: native packages on Debian/Ubuntu/RHEL, static binary elsewhere. Installs to `/opt/netdata` or `/etc/netdata` depending on method.

Useful flags:
- `--dont-start-it` — install but don't auto-start
- `--claim-token` / `--claim-rooms` / `--claim-url` — connect to Netdata Cloud during install
- `--stable-channel` — use stable release channel (default is nightly)
- `--install-prefix /opt` — custom prefix

Dashboard: `http://<host>:19999/`.

### 2. Docker (official image)

Source: https://github.com/netdata/netdata/blob/master/packaging/docker/README.md

```bash
docker run -d --name=netdata \
  --pid=host \
  --network=host \
  -v netdataconfig:/etc/netdata \
  -v netdatalib:/var/lib/netdata \
  -v netdatacache:/var/cache/netdata \
  -v /:/host/root:ro,rslave \
  -v /etc/passwd:/host/etc/passwd:ro \
  -v /etc/group:/host/etc/group:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v /proc:/host/proc:ro \
  -v /sys:/host/sys:ro \
  -v /etc/os-release:/host/etc/os-release:ro \
  -v /var/log:/host/var/log:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --restart unless-stopped \
  --cap-add SYS_PTRACE \
  --cap-add SYS_ADMIN \
  --security-opt apparmor=unconfined \
  netdata/netdata
```

Or Docker Compose (upstream docker README includes a Compose example). The mount list is **not optional** — each one is specifically required for a subset of collectors (see the table in the upstream docker README).

### 3. Kubernetes (upstream Helm chart)

Source: https://github.com/netdata/helmchart (first-party)

```bash
helm repo add netdata https://netdata.github.io/helmchart/
helm install netdata netdata/netdata
```

Deploys a DaemonSet (agent on every node) plus a parent StatefulSet. See the chart's README for values.

### 4. Netdata Cloud (claim an existing agent)

Once you have agents installed:

```bash
sudo netdata-claim.sh -token=<token> -rooms=<room-id> -url=https://app.netdata.cloud
```

Links the agent to your Cloud account. Dashboard moves to the Cloud UI; agents still render locally on :19999. Disconnect anytime by running `netdata-claim.sh -id=...` with the disconnect flag.

## Software-layer concerns

### Why the long Docker mount list?

From the upstream Docker README, each mount enables a specific set of collectors:

| Mount | Enables |
|---|---|
| `/proc` | CPU, memory, network, disk I/O monitoring |
| `/sys` | CPU/power, block devices, network interfaces |
| `/var/run/docker.sock` | Docker container monitoring |
| `/var/log` | Web-server log parsing, systemd-journal |
| `/etc/passwd` + `/etc/group` | Per-user / per-group CPU/RAM accounting |
| `/etc/os-release` | Host OS detection |
| `/run/dbus` (optional) | systemd unit state |
| `/` (read-only, rslave) | Host mount-point monitoring (`df`-style) |

Dropping mounts = losing that collector. Upstream explicitly lists which ones are required vs optional.

### Why `--pid=host` + `--network=host`

- `--pid=host` — `apps.plugin` needs to see host processes to attribute CPU/RAM per app
- `--network=host` — to see the host's network interfaces (not the container's), and for `go.d.plugin` to reach services on localhost

Without these, Netdata still runs but sees only the container's own view.

### Config at `/etc/netdata`

- `/etc/netdata/netdata.conf` — main config (enable/disable plugins, tune intervals)
- `/etc/netdata/go.d/` — per-collector configs for the Go plugin modules
- `/etc/netdata/python.d/` — legacy Python collectors
- `/etc/netdata/health.d/` — alert definitions

Use `netdata-config` or `edit-config` wrapper scripts to edit correctly (they handle mode + group ownership).

### Ports

- `19999/tcp` — dashboard + REST API + streaming-protocol endpoint (for parent-child)

### Dashboard is verbose

The default dashboard reveals a lot about the host: hostname, process list, running services, Docker containers, network interfaces, ZFS pools if you have them, etc. **Do not expose `:19999` to the public internet** without reverse-proxy + basic auth / OAuth.

### Reverse proxy + auth

```caddy
netdata.example.com {
  basicauth {
    admin <bcrypt-hash>
  }
  reverse_proxy 127.0.0.1:19999
}
```

Or front with Authentik / Authelia / Cloudflare Access. Netdata has no built-in auth.

### Parent-child streaming

On the parent, `/etc/netdata/stream.conf`:

```ini
[stream]
    enabled = no

[abc123-api-key]
    enabled = yes
    default history = 86400
```

On each child, `/etc/netdata/stream.conf`:

```ini
[stream]
    enabled = yes
    destination = parent.example.com:19999
    api key = abc123-api-key
```

Restart both; the parent's dashboard now shows all children. See https://learn.netdata.cloud/docs/streaming

## Upgrade procedure

### Native (kickstart.sh)

```bash
sudo /etc/netdata/netdata-updater.sh
# or re-run kickstart.sh
```

Or configure auto-updates (enabled by default on native installs).

### Docker

```bash
docker pull netdata/netdata:stable
docker stop netdata && docker rm netdata
docker run ... (same command)
```

Config (`netdataconfig` volume) persists across upgrades.

### Tags

- `netdata/netdata:latest` — nightly
- `netdata/netdata:stable` — tagged stable release (recommended for prod)
- `netdata/netdata:edge` — same as `latest`

## Gotchas

- **The Docker install is heavy.** ~15 mounts, requires `--privileged`-adjacent caps (`SYS_PTRACE`, `SYS_ADMIN`). Because Netdata is essentially an extension of the host kernel metrics, the "unprivileged rootless container" dream doesn't apply.
- **`--pid=host` means the container sees all host processes.** Acceptable for monitoring tools; audit if your threat model cares.
- **Dashboard is public by default.** Binds `0.0.0.0:19999`. Either firewall externally, set `[web].bind to = 127.0.0.1` in `netdata.conf`, or reverse-proxy with auth.
- **Default is nightly.** Kickstart installs the nightly channel. Add `--stable-channel` for production. The nightly is usually fine but occasionally ships regressions.
- **`--user` / `user:` is unsupported.** Upstream's docker README: "We don't officially support using Docker's `--user` option or Docker Compose's `user:` parameter with our images."
- **Netdata Cloud is optional.** Claimable / unclaimable any time. Agents work fully without it — Cloud is just a cross-host aggregator.
- **Alert notifications need configuring.** Out of the box, alerts fire in the dashboard but don't email/page anyone. Edit `/etc/netdata/health_alarm_notify.conf`.
- **Disk usage grows fast by default.** Long retention + 1-second granularity + many hosts = gigs. Configure `[db]` retention in `netdata.conf` or use the multi-tier dbengine with configurable per-tier retention.
- **Streaming parent needs disk to match.** A parent holding 20 children's data needs ~20× the disk.
- **Shell install-script security.** Upstream's `kickstart.sh` is `curl | sh`. Audit before running if that worries you.
- **APT / RPM repos are cloud-netdata.** Native installs add a Netdata repo (`packagecloud.io`). Not a security concern in practice but worth noting if you manage third-party repo inventory.

## TODO — verify on subsequent deployments

- [ ] Exercise parent-child streaming end-to-end.
- [ ] Document the minimum mount set for a reduced-privilege Docker deploy (fewer collectors, smaller attack surface).
- [ ] Verify Helm chart version at next k8s deploy.
- [ ] Integrate notification wiring to Signal / Telegram / email via `health_alarm_notify.conf`.
- [ ] Retention tuning for small hosts (Pi): reduce dbengine tier sizes.
