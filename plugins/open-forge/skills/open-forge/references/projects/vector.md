---
name: Vector
description: High-performance observability data pipeline (logs, metrics, traces). Single static Rust binary; config-file driven; runs as an agent or aggregator. Maintained by Datadog.
---

# Vector

Vector is a Rust-based observability pipeline: collect from any source (files, syslog, kafka, docker, journald, cloud APIs), transform (filter, remap, route via VRL), and send to any sink (Loki, Elasticsearch, S3, Kafka, Datadog, Splunk, ClickHouse, many more). Everything is declared in a single `vector.toml` / `.yaml` / `.json` config; there is no web UI or database.

- Upstream repo: <https://github.com/vectordotdev/vector>
- Docs: <https://vector.dev/docs/>
- Quickstart: <https://vector.dev/docs/setup/quickstart/>
- Component reference: <https://vector.dev/components/>
- Image: `timberio/vector` on Docker Hub (also `ghcr.io/vectordotdev/vector`)

## Architecture in one minute

Two deployment roles, same binary:

- **Agent** — runs on each host, tails local files / reads the systemd journal / scrapes Docker, and forwards to an aggregator or directly to a sink. Tiny footprint.
- **Aggregator** — runs centrally, receives from agents via `vector` source (lumberjack-style) or standard protocols (syslog, kafka, HTTP), applies heavy transforms, then fans out to backend sinks.

You can also run Vector as a single-host "all-in-one" for a small deployment.

## Compatible install methods

| Infra              | Runtime                              | Notes                                                                 |
| ------------------ | ------------------------------------ | --------------------------------------------------------------------- |
| Linux host         | `.deb` / `.rpm` package              | Recommended for agents — upstream maintains official repos            |
| Linux host         | Single static binary                 | Portable; useful for immutable infra                                  |
| Any host           | Docker / Podman                      | `timberio/vector` — use for aggregators, containerized agents         |
| Kubernetes         | Helm chart (`vector`)                | Official; DaemonSet for agents + StatefulSet/Deployment for aggregators |
| macOS / Windows    | Homebrew / MSI                       | Also supported; less common for production                            |

## Inputs to collect

| Input                | Example                                   | Phase     | Notes                                                            |
| -------------------- | ----------------------------------------- | --------- | ---------------------------------------------------------------- |
| Role                 | `agent` / `aggregator` / `all-in-one`     | Design    | Drives sources/sinks topology                                    |
| Version              | `0.46.0` (example)                        | Runtime   | Pin exactly — behavior across minors can change                  |
| Config path          | `/etc/vector/vector.yaml`                 | Runtime   | Vector loads one file or a dir of files                           |
| Data directory       | `/var/lib/vector`                         | Runtime   | **Required** — used for disk buffers & checkpoints                |
| Sources              | `file`, `docker_logs`, `journald`, `kafka` | Runtime  | List in config                                                   |
| Sinks                | `loki`, `elasticsearch`, `clickhouse`, etc.| Runtime  | Credentials + endpoints per sink                                 |
| API                  | `api.enabled: true`, `api.address:0.0.0.0:8686` | Runtime | Optional introspection + `vector top`                          |

## Install via package (agent, recommended)

Upstream repos documented at <https://vector.dev/docs/setup/installation/package-managers/>.

```sh
# Debian/Ubuntu example
curl -1sLf 'https://repositories.timber.io/public/vector/setup.deb.sh' | sudo -E bash
sudo apt install vector
```

Drop config at `/etc/vector/vector.yaml`, enable service, done:

```yaml
# /etc/vector/vector.yaml
data_dir: /var/lib/vector

sources:
  system_logs:
    type: journald

sinks:
  loki_out:
    type: loki
    inputs: [system_logs]
    endpoint: https://loki.example.com
    labels:
      host: "{{ host }}"
      service: "{{ _SYSTEMD_UNIT }}"
    encoding:
      codec: json
```

```sh
sudo vector validate --config /etc/vector/vector.yaml    # sanity-check before restart
sudo systemctl restart vector
```

## Install via Docker (aggregator)

```yaml
services:
  vector:
    image: timberio/vector:0.46.0-debian    # pin; see https://hub.docker.com/r/timberio/vector/tags
    restart: unless-stopped
    volumes:
      - ./vector.yaml:/etc/vector/vector.yaml:ro
      - vector-data:/var/lib/vector
    ports:
      - "8686:8686"   # API (optional)
      - "9000:9000"   # inbound `vector` source (if using agent→aggregator)
    command: ["--config", "/etc/vector/vector.yaml"]
volumes:
  vector-data:
```

## Install via Kubernetes

Use the official Helm chart: <https://github.com/vectordotdev/helm-charts>

```sh
helm repo add vector https://helm.vector.dev
helm upgrade --install vector vector/vector \
  --set role=Agent \
  --values agent-values.yaml
```

Chart supports `role=Agent` (DaemonSet), `role=Aggregator` (StatefulSet), `role=Stateless-Aggregator` (Deployment).

## Data & config layout

- `/etc/vector/` — config file(s); Vector merges any `.yaml`/`.toml`/`.json` under a config directory
- `/var/lib/vector/` — disk buffers (for sinks with `buffer.type: disk`), file-source checkpoints, aggregator state. **Persist this volume** — losing it means re-tailing from scratch and possible duplicates/gaps.
- Logs: stderr; use `--log-level` or `VECTOR_LOG=debug`
- Config hot-reload: `SIGHUP` or `vector reload` (if API enabled)

## Upgrade

1. Check release notes: <https://github.com/vectordotdev/vector/releases>. The `RELEASES.md` file in-repo also lists upgrade impact.
2. Run `vector validate` against the new binary with your current config **before** swapping (catches removed/renamed component fields).
3. Bump package or image tag; restart.
4. For aggregators, do a rolling restart; agents can be updated fleet-wide with your usual config-management tool.
5. Major-version upgrades (0.x → 0.(x+major)) occasionally rename components; read the "highlights" entry in release notes.

## Gotchas

- **`data_dir` is mandatory.** Without it, disk buffers silently fall back to memory and source checkpoints do not survive restarts → duplicate or missing events on restart.
- **`buffer.type: memory` is lossy on crash.** Use `disk` for any sink where you can't afford to drop events.
- **VRL (Vector Remap Language) is its own language.** Transformations in `transforms.*.type: remap` use VRL, not Lua/JS. Reference: <https://vector.dev/docs/reference/vrl/>.
- **Sink back-pressure** is per-sink; a slow sink blocks its upstream pipeline. Use `acknowledgements` + `buffer` to isolate.
- **Upgrading config between minors** occasionally requires small edits — components are marked stable / beta / alpha. Check component state before relying on it in prod.
- **The API (port 8686) is unauthenticated.** Never expose it publicly; bind to localhost or a private network.
- **`journald` source needs `/var/log/journal` bind-mount** when running Vector in a container; otherwise it sees no logs.
- **Docker source requires the socket.** `docker_logs` source mounts `/var/run/docker.sock` — that is host-level access. Prefer reading via `file` source from `/var/lib/docker/containers/` on hosts where it's acceptable.
- **Distroless images are tiny but lack a shell**, making debugging harder. Use `timberio/vector:*-debian` tags for iteration, `*-distroless-static` in locked-down prod.

## Links

- Docs: <https://vector.dev/docs/>
- Config reference: <https://vector.dev/docs/reference/configuration/>
- Component catalog (sources/transforms/sinks): <https://vector.dev/components/>
- VRL docs: <https://vector.dev/docs/reference/vrl/>
- Helm chart: <https://github.com/vectordotdev/helm-charts>
- Releases: <https://github.com/vectordotdev/vector/releases>
- Docker Hub: <https://hub.docker.com/r/timberio/vector>
