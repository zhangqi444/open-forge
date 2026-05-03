---
name: Dozzle
description: Real-time Docker log viewer in the browser. Lightweight (~10 MB image), multi-host via agents, live streaming, container stats, full-text live search, optional auth (file-based, OIDC, forward-proxy). Go + vanilla JS. MIT.
---

# Dozzle

Dozzle is the "`docker logs -f` in a web UI" tool. Point it at `/var/run/docker.sock`, get live-streaming logs from every running container, searchable, with colors, container stats, and zero persistent storage. Perfect for a homelab dashboard.

Multi-host: run Dozzle **agents** on remote Docker hosts, pair them with a central Dozzle UI → one browser tab shows logs across your whole fleet. Swarm mode is first-class.

Not built for: long-term log retention, full-text historical search, log analytics. Dozzle streams what Docker's stdout ring-buffers hold (default: last 10 MB per container). For heavy use, pair with Loki / Elasticsearch / Papertrail / Grafana.

- Upstream repo: <https://github.com/amir20/dozzle>
- Website: <https://dozzle.dev>
- Docs: <https://dozzle.dev/guide/getting-started>
- Docker Hub: <https://hub.docker.com/r/amir20/dozzle>

## Architecture in one minute

- **Single Go binary** + embedded frontend
- Reads Docker API via socket (or TCP)
- **Agent mode**: runs a remote Dozzle that the main UI connects to → multi-host fleet
- **Swarm mode**: scheduled as a `global` service; auto-discovers swarm nodes
- Optional **persistent state volume** (`/data`) for user accounts in file-auth mode

## Compatible install methods

| Infra        | Runtime                                               | Notes                                                                |
| ------------ | ----------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM    | Docker (`amir20/dozzle:<VERSION>`)                    | **Simplest**                                                          |
| Docker Swarm | `docker service create ... --mode global`             | **Recommended for Swarm**                                             |
| Podman       | `podman run` with user socket                         | Works (see rootless notes)                                            |
| Kubernetes   | Community charts                                       | Less common; K8s has kubectl logs + Grafana                           |
| Multi-host   | One UI + N agents                                      | Agent on each Docker host; centralized view                           |

## Inputs to collect

| Input                       | Example                              | Phase     | Notes                                                            |
| --------------------------- | ------------------------------------ | --------- | ---------------------------------------------------------------- |
| Port                        | `8080:8080`                          | Network   | UI default                                                        |
| Docker socket               | `/var/run/docker.sock`               | Runtime   | Mount read-only (`:ro`) for safety                                |
| Data volume (optional)      | `dozzle_data:/data`                  | Storage   | Only needed for local user auth                                    |
| `DOZZLE_MODE`               | `swarm` or unset                      | Runtime   | Enables Swarm mode                                                |
| `DOZZLE_AUTH_PROVIDER`      | `simple` / `forward-proxy`            | Auth      | File-based or delegate to Authelia/oauth2-proxy                    |
| Agents (optional)           | `dozzle:7007` on each remote host     | Multi     | For multi-host                                                    |

## Install via Docker (single host)

```sh
docker run --name dozzle -d \
  --volume=/var/run/docker.sock:/var/run/docker.sock:ro \
  -v dozzle_data:/data \
  -p 8080:8080 \
  amir20/dozzle:v10.5.1    # pin; avoid :latest
```

Compose:

```yaml
services:
  dozzle:
    image: amir20/dozzle:v10.5.1
    container_name: dozzle
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - dozzle_data:/data
    # For auth:
    # environment:
    #   DOZZLE_AUTH_PROVIDER: simple

volumes:
  dozzle_data:
```

Browse `http://<host>:8080`. Zero config by default.

## Swarm mode

Runs as a global service — one Dozzle per swarm node, auto-clustered:

```sh
docker service create --name dozzle \
  --env DOZZLE_MODE=swarm \
  --mode global \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  -p 8080:8080 \
  amir20/dozzle:v10.5.1
```

## Multi-host (agents)

On each remote Docker host, run an agent:

```sh
docker run -d --name dozzle-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -p 7007:7007 \
  amir20/dozzle:v10.5.1 agent
```

On the central UI host, set `DOZZLE_REMOTE_AGENT`:

```yaml
services:
  dozzle:
    image: amir20/dozzle:v10.5.1
    environment:
      DOZZLE_REMOTE_AGENT: "host1.internal:7007,host2.internal:7007"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - dozzle_data:/data
    ports:
      - "8080:8080"
```

Agent traffic is mTLS-encrypted by default; agent + UI auto-exchange certs on first connect.

## Authentication

### File-based (simple)

```yaml
environment:
  DOZZLE_AUTH_PROVIDER: simple
```

User config file at `/data/users.yml` (auto-prompts on first visit to create admin):

```yaml
users:
  admin:
    email: admin@example.com
    password: $2a$11$... # bcrypt hash
    roles:
      - admin
```

### Forward-proxy (Authelia / oauth2-proxy / Traefik ForwardAuth)

```yaml
environment:
  DOZZLE_AUTH_PROVIDER: forward-proxy
  DOZZLE_AUTH_HEADER_USER: Remote-User
  DOZZLE_AUTH_HEADER_EMAIL: Remote-Email
```

Dozzle trusts the proxy's identity headers; no local user DB needed.

Full docs: <https://dozzle.dev/guide/authentication>.

## Install on Podman

Rootful:

```sh
podman run --volume=/run/podman/podman.sock:/var/run/docker.sock \
  -d -p 8080:8080 docker.io/amir20/dozzle:v10.5.1
```

Rootless:

```sh
podman run --volume=/run/user/1000/podman/podman.sock:/var/run/docker.sock \
  -d -p 8080:8080 docker.io/amir20/dozzle:v10.5.1
```

For the "hosts" tab to work correctly under Podman, create a file named `engine-id` under `/var/lib/docker/` containing a UUID:

```sh
sudo mkdir -p /var/lib/docker
uuidgen | sudo tee /var/lib/docker/engine-id
```

Details: <https://dozzle.dev/guide/podman>.

## Data & config layout

- `/data/users.yml` — local users (file-auth mode only)
- `/data/agent-certs/` — mTLS keys/certs for agent pairing
- No log storage — Dozzle just streams; Docker's log driver stores the logs

## Backup

Trivial: back up the `/data` volume if using file auth. Otherwise nothing to back up.

```sh
docker run --rm -v dozzle_data:/src -v "$PWD":/backup alpine \
  tar czf /backup/dozzle-data-$(date +%F).tgz -C /src .
```

## Upgrade

1. Releases: <https://github.com/amir20/dozzle/releases>. Frequent (weekly-ish).
2. `docker compose pull && docker compose up -d`. Takes 2 seconds.
3. No migrations; stateless.
4. **Upgrade agents and UI together** — protocol changes between versions; mismatched agent ↔ UI can break.
5. Changelog: <https://dozzle.dev/guide/release-notes>.

## Gotchas

- **Docker socket mount = full Docker control.** Anyone with Dozzle UI access has read access to all container logs + metadata. Put behind auth + VPN + reverse proxy.
- **Mount socket read-only** (`:ro`) — Dozzle doesn't need write access; reduces blast radius if compromised.
- **Logs are not persisted by Dozzle.** Docker's log driver (json-file default, rotates at 10 MB/container) is the source of truth. For longer retention, change Docker daemon `log-driver` + `log-opts` globally.
- **No full-text historical search.** Dozzle grep's what Docker has in-memory/on-disk. For real log search, ship logs to Loki (via Promtail / Grafana Alloy) and query in Grafana.
- **Swarm mode needs access to manager node.** `constraint: node.role == manager` for the swarm UI container.
- **Agent pairing** uses mTLS with certs auto-generated on first run. `dozzle_data:/data` volume holds the certs; losing it = re-pair all agents.
- **Resource usage is minimal** — ~20 MB RAM for UI, ~10 MB per agent. Good for Pi / NAS.
- **No native alerting.** Dozzle is viewer-only. For "alert me when X appears in logs", use Loki alerts or run a sidecar `tail -f | grep`.
- **Container stats tab** shows CPU/memory/network/io per container, nice live view.
- **Action buttons** (start/stop/restart containers) are **disabled by default**; enable via `DOZZLE_ENABLE_ACTIONS=true` — opens a security hole if auth weak.
- **Forward-proxy auth** is the cleanest prod setup — Authelia + Dozzle = user-friendly centralized auth.
- **OIDC support** added in recent versions — configure with `DOZZLE_AUTH_PROVIDER=oidc` + issuer URL + client creds.
- **No log export from UI.** For grabbing a chunk: `docker logs -f <container> > file.log` on the host, then analyze locally.
- **Dashboard customization**: pin favorites, filter by label/image/name/compose-project.
- **Color schemes** in settings; auto-detects system dark mode.
- **Lightweight by design** — author refuses feature creep. If you want more features, use a heavier log stack.
- **Alternatives worth knowing:**
  - **Portainer** — full container management + logs (heavier)
  - **Yacht** — container management with simpler UI
  - **LazyDocker** — TUI, not web
  - **ctop** — like top for containers (TUI)
  - **Docker Desktop** — built-in log viewer (dev only)
  - **Grafana + Loki + Promtail** — heavy but proper log stack with retention + search
  - **Signoz / ELK / Graylog** — enterprise log platforms

## Links

- Repo: <https://github.com/amir20/dozzle>
- Website: <https://dozzle.dev>
- Getting started: <https://dozzle.dev/guide/getting-started>
- Authentication: <https://dozzle.dev/guide/authentication>
- Swarm mode: <https://dozzle.dev/guide/swarm-mode>
- Agent mode: <https://dozzle.dev/guide/agent-mode>
- Podman install: <https://dozzle.dev/guide/podman>
- Environment variables: <https://dozzle.dev/guide/supported-env-vars>
- Release notes: <https://dozzle.dev/guide/release-notes>
- Releases: <https://github.com/amir20/dozzle/releases>
- Docker Hub: <https://hub.docker.com/r/amir20/dozzle>
- Sponsor: <https://github.com/sponsors/amir20>
