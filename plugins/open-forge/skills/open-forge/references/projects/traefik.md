---
name: traefik-project
description: Traefik recipe for open-forge. MIT-licensed cloud-native HTTP reverse proxy + load balancer with automatic service discovery from Docker / Kubernetes / Consul / ECS / file-based config. Covers the three deployment shapes — single binary (systemd), official Docker image, and Kubernetes Ingress/IngressRoute — plus the two config layers (static startup config in CLI flags / env / `traefik.yml` vs dynamic routing config from providers) and the Let's Encrypt ACME integration that makes Traefik the de-facto reverse proxy for many self-host stacks.
---

# Traefik

Modern HTTP/TCP/UDP reverse proxy and load balancer. Reads routing config directly from your orchestrator (Docker labels, Kubernetes CRDs, Consul KV, etc.) and reconfigures itself live — no restart on route changes. Automatic Let's Encrypt certificate provisioning.

Upstream: <https://github.com/traefik/traefik>. Docs: <https://doc.traefik.io/traefik/>. Docker Hub: <https://hub.docker.com/_/traefik>.

## Two config layers (critical to understand up front)

Traefik separates **static** and **dynamic** configuration, and the distinction trips up nearly everyone on day one:

| Layer | What it controls | Sources | Applied when |
|---|---|---|---|
| **Static** | Entrypoints (ports Traefik listens on), providers (which backends to watch), ACME resolvers, API/dashboard toggle, logging. | CLI flags, env vars (`TRAEFIK_*`), `traefik.yml` / `traefik.toml`. Exactly **one** source per deployment. | Read ONCE at Traefik startup. Changing requires restart. |
| **Dynamic** | Routers, services, middlewares, TLS certs/stores. | Provider you configured in static config — Docker labels, Kubernetes CRDs, Consul KV, or a watched file. | Read continuously; reloaded live without restart. |

Everything auto-generated from container labels / K8s Ingresses is dynamic. Everything in `traefik.yml` or CLI flags is static. Don't mix them up.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`traefik:v3`) | <https://hub.docker.com/_/traefik> | ✅ | **Most common self-host pattern.** Container on the same Docker network as your apps; auto-discovers them via labels. |
| Kubernetes (Helm chart / manifests) | <https://github.com/traefik/traefik-helm-chart> | ✅ | Standard choice for K8s ingress. Upstream Helm chart is actively maintained. |
| Precompiled binary + systemd | <https://github.com/traefik/traefik/releases> | ✅ | Bare-metal / VM hosts where you don't want Docker. |
| Package managers (apt / brew / winget) | Community packages | ⚠️ | Often out of date vs upstream releases; prefer the official binary or container. |
| Kubernetes Ingress (legacy `networking.k8s.io/v1`) | Upstream supported | ✅ | Simplest K8s integration; functional but limited. Use Traefik's native `IngressRoute` CRDs for full feature set. |
| Swarm mode | Upstream supported | ✅ | Same Docker label model, different provider flag. |
| Build from source (`go build`) | <https://doc.traefik.io/traefik/contributing/building-testing/> | ✅ | Contributors only. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | `AskUserQuestion` | Drives the flow below. |
| preflight | "Traefik version?" | `AskUserQuestion`: `v3 (current)` / `v2.x (legacy)` / `pin specific` | **v2 → v3 has breaking changes** (<https://doc.traefik.io/traefik/migrate/v2-to-v3/>); new installs should start on v3. |
| dns | "What's the FQDN for Traefik's dashboard?" (e.g. `traefik.example.com`) | Free-text | Needed for dashboard access (production — never expose without auth). |
| tls | "Let's Encrypt challenge type?" | `AskUserQuestion`: `HTTP-01` (default) / `TLS-ALPN-01` / `DNS-01` (wildcard support) | HTTP-01 needs port 80 reachable; DNS-01 needs API access to your DNS provider. |
| tls | *DNS-01* "DNS provider?" | `AskUserQuestion` from <https://doc.traefik.io/traefik/https/acme/#providers> | Each provider needs its own env vars (e.g. `CF_DNS_API_TOKEN` for Cloudflare). |
| tls | "Email for Let's Encrypt expiration notices?" | Free-text | Sets `certificatesResolvers.<name>.acme.email`. Required. |
| tls | "Use Let's Encrypt staging CA for testing?" | `AskUserQuestion`: `Yes (first-time setup)` / `No (production)` | Staging avoids rate-limit burn during config iteration. |
| auth | "Enable the Traefik dashboard?" | `AskUserQuestion`: `Yes — with basic-auth` / `Yes — behind VPN only` / `No` | Dashboard at `/dashboard/` + API at `/api/`. **Do NOT** expose without auth. |
| network | "Which ports to bind?" | Free-text (default `80` + `443`) | Defines `entrypoints.web` + `entrypoints.websecure`. |
| provider | "Which provider for dynamic config?" | `AskUserQuestion`: `docker` / `kubernetesIngress` / `kubernetesCRD` / `file` / `consul` | Determines how Traefik discovers backend services. |

Write all answers to state.

## Install — Docker (most common self-host pattern)

```bash
# 1. Create a shared Docker network for Traefik + your apps
docker network create traefik_proxy

# 2. Prep volumes for ACME cert storage + static config
sudo mkdir -p /opt/traefik/{letsencrypt,dynamic}
sudo touch /opt/traefik/letsencrypt/acme.json
sudo chmod 600 /opt/traefik/letsencrypt/acme.json   # Traefik requires 0600 or it refuses to start

# 3. Write the static config (traefik.yml)
sudo tee /opt/traefik/traefik.yml > /dev/null <<'YAML'
api:
  dashboard: true
  # insecure: true   # DO NOT enable in production — dashboard on :8080 with no auth

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false       # only containers with traefik.enable=true are proxied
    network: traefik_proxy
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: you@example.com
      storage: /letsencrypt/acme.json
      # Use staging CA first to verify the flow:
      # caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web

log:
  level: INFO

accessLog: {}
YAML

# 4. Dynamic config — basic-auth middleware + dashboard router (so the dashboard has auth)
# Generate a basic-auth string. htpasswd -nB <user> -C 12 is the common approach.
BASIC_AUTH=$(htpasswd -nbB admin <password> | sed -e 's/\$/\$\$/g')   # double $ for docker-compose

sudo tee /opt/traefik/dynamic/dashboard.yml > /dev/null <<YAML
http:
  middlewares:
    dashboard-auth:
      basicAuth:
        users:
          - "${BASIC_AUTH}"
  routers:
    dashboard:
      rule: Host(\`traefik.example.com\`)
      service: api@internal
      entryPoints:
        - websecure
      middlewares:
        - dashboard-auth
      tls:
        certResolver: letsencrypt
YAML

# 5. Run Traefik
docker run -d \
  --name traefik \
  --restart unless-stopped \
  --network traefik_proxy \
  -p 80:80 -p 443:443 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /opt/traefik/traefik.yml:/etc/traefik/traefik.yml:ro \
  -v /opt/traefik/dynamic:/etc/traefik/dynamic:ro \
  -v /opt/traefik/letsencrypt:/letsencrypt \
  traefik:v3
```

### Exposing another container through Traefik (labels)

With `providers.docker.exposedByDefault: false`, only explicitly-labeled containers are proxied:

```yaml
# inside another compose.yml on the traefik_proxy network
services:
  myapp:
    image: myapp:latest
    networks:
      - traefik_proxy
    labels:
      - traefik.enable=true
      - traefik.http.routers.myapp.rule=Host(`myapp.example.com`)
      - traefik.http.routers.myapp.entrypoints=websecure
      - traefik.http.routers.myapp.tls.certresolver=letsencrypt
      - traefik.http.services.myapp.loadbalancer.server.port=3000

networks:
  traefik_proxy:
    external: true
```

The `loadbalancer.server.port` label is **required** if the container exposes multiple ports or doesn't have `EXPOSE` in its Dockerfile — Traefik doesn't guess.

## Install — binary + systemd

```bash
# 1. Pick version + arch from https://github.com/traefik/traefik/releases
TRAEFIK_VERSION="v3.7.1"
ARCH="linux_amd64"

# 2. Download + install
cd /tmp
curl -fsSL -O "https://github.com/traefik/traefik/releases/download/${TRAEFIK_VERSION}/traefik_${TRAEFIK_VERSION}_${ARCH}.tar.gz"
tar xzf "traefik_${TRAEFIK_VERSION}_${ARCH}.tar.gz"
sudo install -o root -g root -m 0755 traefik /usr/local/bin/traefik

# 3. Allow non-root Traefik to bind ports 80/443
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/traefik

# 4. System user + dirs
sudo useradd --system --no-create-home --shell /usr/sbin/nologin traefik
sudo install -o traefik -g traefik -m 0750 -d /etc/traefik /etc/traefik/dynamic /var/lib/traefik
sudo touch /var/lib/traefik/acme.json
sudo chown traefik:traefik /var/lib/traefik/acme.json
sudo chmod 600 /var/lib/traefik/acme.json

# 5. Write /etc/traefik/traefik.yml (same content as Docker example, but use provider.file instead of provider.docker)

# 6. systemd unit
sudo tee /etc/systemd/system/traefik.service > /dev/null <<'UNIT'
[Unit]
Description=Traefik
After=network-online.target
Wants=network-online.target

[Service]
User=traefik
Group=traefik
Type=simple
ExecStart=/usr/local/bin/traefik --configFile=/etc/traefik/traefik.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now traefik
sudo systemctl status traefik
```

Point it at backends via `providers.file.directory: /etc/traefik/dynamic` — drop YAML files there and Traefik watches for changes.

## Install — Kubernetes (Helm chart, upstream)

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Values-file-driven install (recommended)
cat > values.yaml <<'YAML'
deployment:
  replicas: 2

ingressClass:
  enabled: true
  isDefaultClass: true

ports:
  web:
    redirectTo:
      port: websecure
      priority: 10
  websecure:
    tls:
      enabled: true

providers:
  kubernetesCRD:
    enabled: true
  kubernetesIngress:
    enabled: true

additionalArguments:
  - "--certificatesresolvers.letsencrypt.acme.email=you@example.com"
  - "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"

persistence:
  enabled: true
  size: 128Mi
YAML

helm upgrade --install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  --values values.yaml
```

Expose services via Traefik's native `IngressRoute` CRD:

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: myapp
spec:
  entryPoints: [websecure]
  routes:
    - match: Host(`myapp.example.com`)
      kind: Rule
      services:
        - name: myapp
          port: 80
  tls:
    certResolver: letsencrypt
```

## Config surface — key concepts

- **EntryPoints** — ports Traefik listens on (`:80`, `:443`, etc.). Static config.
- **Routers** — match incoming requests (Host, Path, Headers) and send to a service. Dynamic config (from provider).
- **Services** — groups of backend targets with load-balancing config. Dynamic config.
- **Middlewares** — chained request/response transformers (basic-auth, rate-limit, IP allowlist, path-strip, etc.). Dynamic config.
- **Providers** — sources of dynamic config. At least one required. `file` watches a directory; `docker` watches container labels; `kubernetesCRD` watches CRDs.
- **Resolvers** — ACME (Let's Encrypt) certificate issuers. Static config. One resolver per challenge type; multiple resolvers allowed.

Full reference: <https://doc.traefik.io/traefik/reference/static-configuration/cli/>.

## Upgrade

- **Docker:** `docker pull traefik:v3 && docker stop traefik && docker rm traefik` → re-run `docker run` with same mounts. Zero-downtime: run two Traefik containers behind an L4 LB and roll.
- **Binary:** `systemctl stop traefik` → install new binary → `systemctl start traefik`.
- **Helm:** `helm upgrade traefik traefik/traefik --values values.yaml`. Rolling update via the Deployment's strategy.

**v2 → v3** has migration-required changes (provider key renames, middleware syntax). Follow <https://doc.traefik.io/traefik/migrate/v2-to-v3/> step by step before upgrading. Test in staging first.

## Gotchas

- **Static vs dynamic config.** Re-read the top of this recipe if unsure. Adding a resolver = static (needs restart). Adding a router = dynamic (live reload).
- **`acme.json` MUST be `chmod 0600`.** Traefik refuses to start otherwise. Common cause of "file has wrong permissions" errors after a host reinstall.
- **`exposedByDefault: false` + forgotten `traefik.enable=true`.** Containers appear "invisible" to Traefik. Double-check the label + network membership.
- **Containers must share a network with Traefik.** Traefik discovers only containers on networks it's attached to. `docker network connect traefik_proxy <container>` + `traefik.docker.network=traefik_proxy` label.
- **`api.insecure: true` exposes dashboard + API on :8080 with no auth.** Fine for laptop dev; a security incident in production. Use the `api@internal` service + basic-auth middleware pattern shown above.
- **Let's Encrypt rate limits.** 50 certs/week per registered domain (on apex + each FQDN). Burn through this during misconfigured iteration and you're locked out for 7 days. **Always test with staging CA first** (`caServer: https://acme-staging-v02.api.letsencrypt.org/directory`).
- **HTTP-01 needs port 80 reachable**, even if you redirect to HTTPS. The ACME challenge happens on `:80`.
- **DNS-01 for wildcard certs.** `*.example.com` requires DNS-01 challenge; HTTP-01 can't issue wildcards.
- **Dashboard router conflict.** Defining the dashboard router via Docker labels + via a file provider = two competing routers, non-deterministic routing. Pick one.
- **`middlewares` on HTTPS router don't chain through HTTP redirect.** If you want basic-auth on an HTTP→HTTPS redirect, middleware the `websecure` router, not the redirect from `web` → `websecure`.
- **Traefik reads Docker socket.** Mounting `/var/run/docker.sock` grants root-equivalent access to the host. For hardened setups, use [`tecnativa/docker-socket-proxy`](https://github.com/Tecnativa/docker-socket-proxy) to limit which API endpoints Traefik can hit.
- **v3 renamed `kubernetesCRD` to `kubernetesIngressRoute`**? — no, that's still `kubernetesCRD` in v3; but many v2 helper templates use the old syntax. Check your Helm values against the current chart's docs.

## Upstream references

- Repo: <https://github.com/traefik/traefik>
- Docs (v3): <https://doc.traefik.io/traefik/>
- Migration v2 → v3: <https://doc.traefik.io/traefik/migrate/v2-to-v3/>
- 5-minute quickstart: <https://doc.traefik.io/traefik/getting-started/quick-start/>
- ACME providers list: <https://doc.traefik.io/traefik/https/acme/#providers>
- Helm chart: <https://github.com/traefik/traefik-helm-chart>
- Docker Hub: <https://hub.docker.com/_/traefik>
- Releases: <https://github.com/traefik/traefik/releases>

## TODO — verify on first deployment

- Confirm the current v3 minor (v3.2.x at time of writing) is still the recommended pin.
- Test `setcap cap_net_bind_service` still works on current Ubuntu LTS kernels for non-root binary install.
- Verify the Helm chart's `ingressClass.isDefaultClass: true` behaviour doesn't conflict with existing nginx/haproxy ingress installs.
- Shake out the DNS-01 flow against at least Cloudflare + Route53 + Gandi to catch provider-specific env var naming drift.
