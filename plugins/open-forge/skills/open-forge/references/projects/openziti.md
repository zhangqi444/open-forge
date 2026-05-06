---
name: openziti
description: OpenZiti recipe for open-forge. Open-source zero-trust networking platform. Makes services invisible to unauthorized users via cryptographic identity, policy-based authorization, and end-to-end encryption. Self-hosted via Docker Compose (controller + routers). Source: https://github.com/openziti/ziti. Docs: https://openziti.io/docs.
---

# OpenZiti

Open-source zero-trust networking platform. Every connection (user, service, device, workload) is authenticated with cryptographic identity, authorized by policy, and encrypted end-to-end. Services become "dark" — invisible to the internet; only authorized identities can reach them. Works with existing apps (tunnelers, no code change) and new apps (embedded SDKs). Created and sponsored by NetFoundry. Upstream: <https://github.com/openziti/ziti>. Docs: <https://openziti.io/docs>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose (quickstart) | Easiest; controller + router in containers |
| VPS / bare metal | Native binaries (Linux) | Full control; recommended for production deployments |
| Kubernetes | Helm chart | Official chart available |
| Raspberry Pi / ARM | Docker or binary | ARM builds available |

## Key components

| Component | Role |
|---|---|
| Controller | Identity store, policy engine, PKI CA; the brain of the network |
| Edge Router | Traffic router between identities and services |
| Tunneler (ziti-edge-tunnel) | Client-side agent for non-SDK apps; creates TUN interface |
| SDK | Embed zero-trust directly in your application |
| ziti CLI | Management and admin tool |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker quickstart or native binary deployment?" | Docker quickstart for evaluation; native for production |
| controller | "Advertised address for the controller?" | Hostname or IP that routers/clients will reach; e.g. ziti.example.com |
| controller | "Controller edge port?" | Default: 1280 |
| admin | "Admin username and password?" | ZITI_USER + ZITI_PWD env vars |
| router | "Edge router advertised address?" | Hostname/IP for the router; can be same host as controller for single-node |
| domain | "Public domain for TLS?" | Controller and router certs are tied to advertised addresses |

## Software-layer concerns

- PKI: OpenZiti manages its own CA; controller issues certs for all identities and routers
- Ports: controller edge=1280, controller fabric=6262, router=3022 (edge), router=10080 (link listener)
- State: controller stores state in a bbolt (embedded) database at /persistent (Docker) or configured data dir
- Identities: each client/service gets a signed JWT enrollment token; enroll with `ziti edge enroll`
- Policies: service policies (who can access), bind policies (who can host), and router policies control access
- No VPN concentrator: traffic flows peer-to-peer through routers; no single bottleneck

### Docker quickstart (single-node evaluation)

```bash
git clone https://github.com/openziti/ziti.git
cd ziti/quickstart/docker

# Set admin password
export ZITI_PWD=<your-admin-password>

docker compose up -d

# Verify controller is up
curl -k https://localhost:1280/edge/client/v1/version
```

Access the web console (Ziti Admin Console - ZAC) if installed, or use the ziti CLI:

```bash
# Exec into controller to run ziti CLI
docker compose exec ziti-controller ziti edge login localhost:1280 -u admin -p <password> -y
docker compose exec ziti-controller ziti edge list services
```

### Native binary quickstart (Linux)

```bash
# Install
curl -sL https://get.openziti.io/install.bash | sudo bash -s ziti ziti-controller ziti-router ziti-edge-tunnel

# Quick-start (auto-configures controller + router)
ziti edge quickstart
```

Full native deployment: https://openziti.io/docs/category/installation

## Upgrade procedure

1. Docker: update image tags in docker-compose.yml, `docker compose pull && docker compose up -d`
2. Native: update package via package manager or re-download binaries
3. Check migration notes: https://github.com/openziti/ziti/releases (breaking changes noted in release notes)
4. Controller DB migrations run automatically on startup

## Gotchas

- **Advertised address must be resolvable**: The address set at init time is baked into certificates. Changing it requires re-initializing the PKI. Use a stable hostname (DNS, not IP) from the start.
- **Enrollment tokens expire**: Default enrollment token TTL is short. Enroll devices promptly after creating identities, or extend the TTL with ZITI_EDGE_IDENTITY_ENROLLMENT_DURATION.
- **Firewall rules**: Controller port 1280 (edge), 6262 (fabric); router port 3022 (edge), 10080 (link). Open these on your firewall/security group.
- **PKI is self-managed**: OpenZiti runs its own CA. Certificates are not publicly trusted (browsers will warn). This is by design — trust is established through the controller's PKI, not public CAs.
- **Not a traditional VPN**: OpenZiti creates per-service, per-identity access policies — not a full network subnet. Applications either need the tunneler running or an embedded SDK.
- **Single-node quickstart vs production**: The quickstart bundles controller + router on one host for evaluation. Production deployments separate these for resilience.
- **Managed alternative**: NetFoundry's managed service (CloudZiti / NetFoundry) is OpenZiti-as-a-service if you want zero-trust without self-hosting the controller.

## Links

- Upstream repo: https://github.com/openziti/ziti
- Docs: https://openziti.io/docs
- Quickstart guide: https://openziti.io/docs/category/quickstarts
- Docker quickstart: https://github.com/openziti/ziti/tree/main/quickstart/docker
- Helm chart: https://github.com/openziti/helm-charts
- Discourse forum: https://openziti.discourse.group
- Release notes: https://github.com/openziti/ziti/releases
