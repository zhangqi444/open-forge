---
name: portainer-project
description: Portainer Community Edition recipe for open-forge. zlib-licensed web UI for managing Docker, Swarm, Kubernetes, and ACI environments. Single-container deploy that mounts /var/run/docker.sock (or talks to a remote Agent) and exposes a web UI at :9443 (HTTPS) / :9000 (legacy HTTP). Covers the Docker standalone install, Docker Swarm install, Kubernetes (Helm) install, the Portainer Agent edge-node pattern, and the initial admin bootstrap (must claim within a few minutes of first boot or Portainer refuses with "the instance timed out for security purposes").
---

# Portainer Community Edition

zlib-licensed web UI for container orchestrators. Manages Docker standalone, Docker Swarm, Kubernetes clusters, and Azure Container Instances from one dashboard. Upstream: <https://github.com/portainer/portainer>. Docs: <https://docs.portainer.io>.

**CE vs Business:** Portainer CE is the open-source build (this recipe). Portainer Business adds RBAC, LDAP/OIDC integration, team-based access, and support. For ≤3 nodes, Business is free via "Take3" (<https://www.portainer.io/take-3>) — use that if you need RBAC, otherwise CE is enough.

## What you deploy

- One Portainer container (or Helm chart on K8s).
- It reads `/var/run/docker.sock` for local Docker env, OR connects to a remote **Portainer Agent** running on the target.
- Web UI: HTTPS `:9443` (self-signed by default), legacy HTTP `:9000`, agent tunnel `:8000` (used by Edge agents).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker standalone (`portainer/portainer-ce`) | <https://docs.portainer.io/start/install-ce/server/docker/linux> | ✅ Recommended | Single-host Docker. Most selfh.st deploys land here. |
| Docker Swarm | <https://docs.portainer.io/start/install-ce/server/swarm/linux> | ✅ | Multi-node Swarm. Uses a stack + global agent service. |
| Kubernetes (Helm) | <https://docs.portainer.io/start/install-ce/server/kubernetes/baremetal> · chart: `portainer/portainer` | ✅ | K8s cluster. Chart repo: <https://portainer.github.io/k8s/>. |
| Azure Container Instances | Docs §ACI | ✅ | Azure-native. Out of scope for most open-forge users. |
| Portainer Agent (per-node) | <https://docs.portainer.io/start/install-ce/agent> | ✅ | Run alongside Portainer server to manage a remote Docker host without exposing its socket. |
| Portainer Edge Agent | Docs §Edge | ✅ | NAT-traversing agent for hosts you can't reach inbound (home labs, customer sites). |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install target?" | `AskUserQuestion`: `docker standalone` / `swarm` / `kubernetes` / `edge-agent-only` | Drives the section. |
| preflight | "Portainer edition?" | `AskUserQuestion`: `CE (open-source)` / `Business (free for ≤3 nodes via Take3)` | Changes the image tag (`portainer-ce` vs `portainer-ee`). This recipe covers CE. |
| dns | "Public domain?" | Free-text | For the HTTPS reverse-proxy setup. Portainer can terminate its own TLS or delegate to a proxy. |
| tls | "Use Portainer's built-in self-signed cert, or front with a reverse proxy (Caddy/nginx/Traefik)?" | `AskUserQuestion` | Self-signed fine for single-admin LAN; reverse proxy strongly recommended for public. |
| storage | "Host path for Portainer volume?" | Free-text, default `portainer_data` (Docker named volume) | Mounted at `/data` in the container — holds DB, certs, user settings. |
| admin | "Initial admin username?" | Free-text, default `admin` | Set via first-run UI. |
| admin | "Initial admin password? (≥12 chars)" | Free-text (sensitive) | Set via first-run UI OR seeded via `--admin-password-file` flag. |

## Install — Docker standalone

```bash
# 1. Create the named volume for Portainer state
docker volume create portainer_data

# 2. Run Portainer CE
docker run -d \
  --name portainer \
  --restart=always \
  -p 9443:9443 \
  -p 9000:9000 \
  -p 8000:8000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:2.41.1
```

Or as Compose (preferred for long-term):

```yaml
# compose.yaml
services:
  portainer:
    image: portainer/portainer-ce:2.41.1   # pin an exact version in prod
    container_name: portainer
    restart: always
    ports:
      - "9443:9443"   # HTTPS UI (self-signed by default)
      - "9000:9000"   # Legacy HTTP UI (optional)
      - "8000:8000"   # Tunnel port for Edge agents (only needed if using Edge)
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
```

```bash
docker compose up -d
```

Open `https://<host>:9443/` → accept the self-signed cert → create the initial admin account.

### Pre-seed the admin password (skip the 5-minute bootstrap window)

```bash
# Hash a password (bcrypt) on your workstation
htpasswd -nbB admin 'your-strong-password' | cut -d ':' -f 2 > /tmp/admin_password
docker run --rm -v /tmp/admin_password:/tmp/admin_password:ro \
  portainer/portainer-ce:2.41.1 \
  --admin-password-file /tmp/admin_password
```

Mount the same file into your running Portainer and pass `--admin-password-file=/data/admin_password` via `command:`. Useful for automation.

## Install — Docker Swarm

On a Swarm manager:

```bash
curl -L https://downloads.portainer.io/ce/portainer-agent-stack.yml -o portainer-agent-stack.yml
docker stack deploy -c portainer-agent-stack.yml portainer
```

This deploys:

- `portainer_agent` — global service, one instance per Swarm node, mounts that node's Docker socket.
- `portainer_portainer` — one replica of the UI, talking to the agent overlay.

UI on `https://<swarm-manager>:9443/`.

## Install — Kubernetes (Helm)

```bash
helm repo add portainer https://portainer.github.io/k8s/
helm repo update

kubectl create namespace portainer

# Baremetal / NodePort
helm install portainer portainer/portainer \
  --namespace portainer \
  --set service.type=NodePort \
  --set service.httpsNodePort=30779

# Or cloud with LoadBalancer
helm install portainer portainer/portainer \
  --namespace portainer \
  --set service.type=LoadBalancer
```

Chart defaults persist the DB in a PVC. For ingress, disable the bundled NodePort and point your ingress controller at the `portainer` Service on port `9443`.

## Install — Portainer Agent (manage a remote Docker host)

On the **remote host** (not the Portainer server):

```bash
docker run -d \
  --name portainer_agent \
  --restart=always \
  -p 9001:9001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  portainer/agent:latest
```

Then in the Portainer UI: **Environments → Add environment → Agent**, enter `<remote-host>:9001`.

**Use the Edge Agent instead** if the remote host is behind NAT or you can't open inbound ports — Edge Agent dials out to Portainer's `:8000` tunnel.

## Initial admin bootstrap — 5-minute window

Portainer CE 2.0+ enforces a security timeout: **if you don't create the initial admin within a few minutes of first boot, Portainer locks down and refuses to proceed until you restart the container.**

Error message: *"The instance timed out for security purposes. To re-enable your Portainer instance, please restart the Portainer container."*

Fix: `docker restart portainer` — the countdown resets. Either hit the URL promptly, or use `--admin-password-file` to seed the account at boot.

## Reverse proxy (Caddy example)

```caddy
portainer.example.com {
    # Portainer's own HTTPS uses a self-signed cert; proxy with TLS skip-verify
    reverse_proxy https://portainer:9443 {
        transport http {
            tls
            tls_insecure_skip_verify
        }
    }
}
```

Or point Caddy at Portainer's HTTP port `9000` instead and let Portainer serve HTTP internally:

```caddy
portainer.example.com {
    reverse_proxy portainer:9000
}
```

## Data layout

Single Docker volume at `/data` inside the container:

| Path | Content |
|---|---|
| `/data/portainer.db` | BoltDB: all settings, users, endpoints, teams, stacks, auth tokens. |
| `/data/certs/` | Auto-generated self-signed TLS certs. |
| `/data/compose/` | Compose project files uploaded via the UI. |
| `/data/bin/` | Downloaded helper binaries (Docker CLI, kubectl, helm) for stack management. |

**Backup = stop container, `docker run --rm -v portainer_data:/source -v $(pwd):/backup alpine tar czf /backup/portainer-$(date +%F).tar.gz /source`.**

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker logs -f portainer
```

Portainer runs BoltDB migrations automatically on first boot of a new version. Back up `portainer_data` before any major-version bump (1.x → 2.x was particularly invasive).

**Read release notes**: <https://github.com/portainer/portainer/releases>. Some versions deprecate older agent protocols — if your remote hosts run an old agent, update them in the same maintenance window.

## Gotchas

- **5-minute admin-bootstrap timeout.** The #1 Portainer support question. Either claim the admin account immediately after `docker compose up -d`, or use `--admin-password-file`. After timeout, just `docker restart portainer`.
- **Mounting `/var/run/docker.sock` = root on the host.** Anyone with UI access + permission to deploy a privileged container has full host control. Treat Portainer's admin accounts like root SSH — strong passwords, 2FA (Business tier), don't expose the UI to the public internet without auth + IP restrictions.
- **Self-signed cert on `:9443` triggers browser warnings.** Fine for single-admin LAN. For shared use, front with a reverse proxy that has a real cert.
- **CE vs Business image tags.** `portainer/portainer-ce` (CE) vs `portainer/portainer-ee` (Business). Don't mix — the DB schema is compatible but the licensing + feature set differs.
- **Port 8000 (Edge tunnel) must be publicly reachable if using Edge agents.** Edge agents dial out to it; if it's firewalled, Edge hosts never connect.
- **Kubernetes chart default service type is ClusterIP in some versions.** If you can't reach the UI, check `kubectl get svc -n portainer` — you probably need NodePort / LoadBalancer / an ingress route.
- **"Environments" not "endpoints".** The UI terminology changed in 2.0+; older tutorials use "endpoints". Same concept.
- **Matomo analytics are enabled by default.** First-run dialog offers an opt-out; you can also toggle it later in **Settings → Application settings**.
- **Agent version must match server version (loosely).** A Portainer 2.x server can talk to agents within ~2 minor versions. Mismatched versions cause "connection failed" with little explanation in the UI — check agent logs.
- **Docker Swarm stack deploys only work when connected to a Swarm manager.** Connecting Portainer to a non-manager node disables stack management silently.
- **Zlib license.** Permissive but different from MIT/Apache — verify with your legal team if that matters for your org.

## Links

- Upstream repo: <https://github.com/portainer/portainer>
- Docs site: <https://docs.portainer.io>
- Install CE (server): <https://docs.portainer.io/start/install-ce/server>
- Install agent: <https://docs.portainer.io/start/install-ce/agent>
- Helm chart: <https://github.com/portainer/k8s>
- Release notes: <https://github.com/portainer/portainer/releases>
- Take3 (Business free for ≤3 nodes): <https://www.portainer.io/take-3>
- Slack: <https://portainer.io/slack>
