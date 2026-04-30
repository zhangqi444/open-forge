---
name: Octelium
description: "Unified zero-trust secure access platform — self-hosted Tailscale/Cloudflare-Access/Teleport/ngrok/Kong alternative. ZTNA + WireGuard/QUIC tunnels + secretless access + identity-based L7 policy-as-code. Runs on Kubernetes. Dual-licensed Apache-2.0 + AGPL-3.0."
---

# Octelium

Octelium is **"the Swiss-Army-knife of self-hosted zero-trust access"** — a unified platform that collapses what used to be 5+ separate products (remote access VPN + ZTNA gateway + public-tunnel / ngrok alternative + API gateway + PaaS-for-containers) into one Kubernetes-native system. Per upstream README: operates as **"a modern zero-config remote access VPN, a comprehensive Zero Trust Network Access (ZTNA)/BeyondCorp platform, an ngrok/Cloudflare Tunnel alternative, an API gateway, an AI/LLM gateway, a scalable infrastructure for MCP gateways and AI agent-based architectures, a PaaS-like deployment platform for containerized applications, a Kubernetes gateway/ingress and even as a homelab infrastructure."**

Built + maintained by **Octelium** (team + community). **Dual-licensed: Apache-2.0 + AGPL-3.0** (per README badges). Runs on Kubernetes (can be single-node on a $5 VPS). **Single-tenant self-hosted by design** — no SaaS-backing-cloud dependency.

Use cases: (a) **company remote access VPN replacement** (Tailscale/Twingate-class) (b) **ZTNA / BeyondCorp** (Cloudflare-Access / Teleport class) (c) **public tunnel / ngrok alternative** — expose localhost services to internet with auth (d) **API gateway** (Kong / Apigee class) (e) **AI/LLM gateway** with identity-based routing (f) **MCP gateway** for AI-agent architectures (g) **homelab unified-access infrastructure** (h) **Kubernetes ingress replacement** with L7-policy-as-code (i) **secretless SaaS-API access** (S3, Lambda, etc.) without distributing long-lived API keys.

Features:

- **Zero-trust architecture (ZTA)** with identity-aware proxies
- **WireGuard + QUIC tunnels** + clientless BeyondCorp access
- **Secretless access** to SSH, DB (Postgres/MySQL), HTTP APIs, Kubernetes
- **Policy-as-code**: CEL + Open Policy Agent (OPA)
- **Per-request L7 authorization** (not just network-level)
- **Identity providers**: OIDC, SAML 2.0, GitHub OAuth2; FIDO2/WebAuthn MFA
- **Workload identity** — OIDC-based secretless auth for services
- **Zero-config WireGuard client** — Linux, macOS, Windows, Kubernetes sidecars
- **Embedded SSH** — SSH into containers/IoT without SSH daemon on target
- **Managed containers** — Octelium can deploy + host containerized apps as "Services"
- **OpenTelemetry-native auditing** — every request logged + exported to SIEM
- **No proprietary cloud control plane** — everything self-hosted
- **declarative management** via `octeliumctl` — GitOps-friendly

- Upstream repo: <https://github.com/octelium/octelium>
- Homepage: <https://octelium.com>
- Docs: <https://octelium.com/docs>
- Quick install: <https://octelium.com/docs/octelium/latest/overview/quick-install>
- Management guide: <https://octelium.com/docs/octelium/latest/overview/management>
- Discord: <https://octelium.com/external/discord>
- Slack: <https://octelium.com/external/slack>

## Architecture in one minute

- **Go** — primary language
- **Kubernetes-native** — deploys AS a Kubernetes cluster's special workload
- **Single-node OR multi-node**: single-node for dev/homelab/undemanding-prod on 2GB+ VPS; multi-node for production HA
- **WireGuard + QUIC** data plane
- **CEL / OPA** for policy
- **OpenTelemetry** for audit
- **Installs via script**: `curl ... | bash` per quick-install guide
- **Resource**: 2GB RAM + 20GB disk minimum (single-node); scales up for production

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single-node VPS    | **`curl -o install-cluster.sh ... && ./install-cluster.sh --domain`** | **Quick-install path** — upstream primary                                          |
| Multi-node K8s     | Self-deploy Octelium on existing Kubernetes                               | For HA production                                                                          |
| Local VM           | Linux VM on Mac/Windows host                                                            | Dev/test                                                                                             |
| GitHub Codespaces  | Upstream offers a trial Codespace                                                                          | Evaluation path                                                                                                      |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `octelium.example.com` + wildcard                           | URL          | Cluster binds to YOUR domain; TLS cert management automatic                                                                         |
| VPS / server         | 2GB+ RAM, 20GB+ disk, Ubuntu 24.04+ / Debian 12+                          | Infra        | Single-node minimum                                                                                    |
| IdP config           | OIDC or SAML IdP details (Google / Okta / GitHub / Authentik / etc.)                | Auth         | REQUIRED for real users                                                                                                      |
| DNS records          | A records for cluster domain + wildcard                                                                | DNS          | Wildcard enables per-Service subdomains                                                                                                              |
| Policies (as code)   | CEL or OPA policies for access rules                                                                            | Config       | Version-controlled in Git                                                                                                                   |
| Upstream resources   | Backend services to expose (IPs, ports, paths)                                                                                     | Config       | Define as Octelium _Services_                                                                                                                                     |

## Install (single-node quick start)

Per <https://octelium.com/docs/octelium/latest/overview/quick-install>:

```sh
ssh root@your-vps
curl -o install-cluster.sh https://octelium.com/install-cluster.sh
chmod +x install-cluster.sh
# Review the script before executing! (same discipline as any curl|bash)
./install-cluster.sh --domain your-domain.com
```

Then install `octeliumctl` on your workstation + connect. Read the [management guide](https://octelium.com/docs/octelium/latest/overview/management) for full workflow.

## First boot

1. Cluster installed; root-authorized access via initial credentials
2. Install `octeliumctl` on your admin workstation
3. Log in → create first User + IdP binding (connect to Google/Okta/GitHub etc.)
4. Define your first **Service**: e.g., SSH into a private VPS; HTTP upstream; Kubernetes pod; PostgreSQL DB
5. Define **Policies** (CEL or OPA) — who can access what, from where, under what conditions
6. Install WireGuard/QUIC client on end-user devices; connect
7. Validate: user from approved device + approved context can reach Service; others blocked
8. Enable MFA (FIDO2 / WebAuthn / TOTP)
9. Wire OpenTelemetry to your SIEM
10. Back up Cluster state (DB + configs)

## Data & config layout

- **Kubernetes etcd** — cluster state (Services, Users, Policies, Sessions)
- **Octelium internal storage** — per upstream docs
- **Policies** (CEL / OPA) — declarative; store in Git
- **Audit logs** — OpenTelemetry OTLP receivers (your SIEM infrastructure)

## Backup

Octelium cluster state = Kubernetes etcd + Octelium-specific objects. Per upstream docs + standard Kubernetes backup:
- `etcd` snapshot (via `etcdctl` or managed Kubernetes snapshot)
- Git-versioned policies (source-of-truth; re-appliable after restore)
- Managed-container volumes (if using Octelium-as-PaaS)

**Disaster recovery = restore etcd snapshot + re-apply Git-versioned declarations.**

## Upgrade

1. Releases: <https://github.com/octelium/octelium/releases>. Active.
2. Upstream-documented upgrade path (cluster-wide + rolling).
3. Back up etcd FIRST.
4. Read release notes for breaking changes — CEL/OPA semantics or Service-object shape.

## Gotchas

- **KUBERNETES AS PREREQUISITE**: Octelium doesn't run "alongside" your infra — it IS a Kubernetes cluster or lives IN one. If you don't know Kubernetes, your operational-complexity bill is high:
  - Single-node quick-install HIDES much of the K8s complexity (good for starter)
  - Production multi-node = you need real K8s ops skills (or hire them)
- **CROWN-JEWEL-OF-CROWN-JEWELS**: Octelium IS the access-control plane for your infrastructure. If Octelium is compromised:
  - Every Service it fronts is compromised
  - Every user identity it authenticates can be impersonated
  - Every policy it enforces can be bypassed
  - **12th tool in hub-of-credentials family + contender for "most-extreme" alongside Guacamole (batch 87)**
  - Treat as **bastion-tier + control-plane-tier** infrastructure:
    - Deployed in its own isolated environment
    - MFA mandatory for all admin access
    - Separate break-glass admin credentials
    - Intensive monitoring of cluster + admin-access logs
    - Regular offline backups
    - Test disaster recovery with actual restore drills
- **"Policy as code" means your POLICIES are your security**: wrong CEL expression = unintended access or complete lockout. **Test policies in staging before prod.** Same discipline as Kubernetes RBAC or AWS IAM.
- **CEL + OPA learning curve**: CEL (Google's Common Expression Language) + OPA are modern policy-as-code tools with strong semantics but a learning curve. Budget time for your team to learn them.
- **"No admin user" + "zero standing privileges" by default**: a design goal that REQUIRES thinking about break-glass access patterns. When your OIDC provider is down, how do you recover? Upstream docs cover this; don't skip the planning.
- **WireGuard vs QUIC tunnels**: WireGuard is production-ready; QUIC is marked experimental in README. Use WireGuard for production unless you have specific reasons.
- **Single-tenant self-hosted by design**: Octelium is NOT multi-tenant SaaS. You run one Cluster per org (or per environment). This is a strength for sovereignty + a different architecture from multi-tenant commercial ZTNA.
- **Permissive license — Apache-2.0 + AGPL-3.0 dual**: README shows both badges. Dual-license = embedding flexibility. **5th tool in permissive-license-ecosystem-asset family** (following Rustpad, IronCalc, yarr, Guacamole from batch 87). Same "dual-license pattern" as IronCalc (MIT + Apache-2.0).
- **Secretless access is the CROWN FEATURE + biggest operational change**: Octelium's value prop is that users don't need SSH private keys / DB passwords / API keys on their local machines. Octelium injects credentials at request-time. **Users' workflows change** — no more `ssh user@host`; instead `octeliumctl connect + transparent-routing`. Train your users.
- **Audit log volume**: per-request L7 logs = HIGH VOLUME. Plan OpenTelemetry OTLP receiver capacity; plan retention; plan cost if using a paid SIEM.
- **MCP / AI-gateway features** are newer. README flags them prominently but evaluate production-readiness for your use case.
- **Commercial-tier visibility**: README doesn't prominently feature a commercial SaaS offering (unlike Rotki, Chartbrew, AzuraCast, Piwigo). Long-term sustainability model: community + self-hosted-first. Watch for future announcements — funded OSS infra projects typically develop a commercial path over time.
- **Kubernetes ingress replacement** framing: if you're already on Kubernetes with ingress-nginx / Traefik / Contour, Octelium CAN replace them with policy-rich ingress. Whether you SHOULD depends on whether you need L7 policy + identity-based routing beyond basic ingress.
- **Homelab use**: README explicitly calls out homelab — 2GB-VPS quick-install + self-host-all-your-services-via-Octelium is a viable pattern. Homelabbers get BeyondCorp-grade access from their home network to remote services + from outside into their home.
- **Institutional-trust signals**: OpenTelemetry-native + CEL-standard + OPA-standard + Kubernetes-native — all industry-standard building blocks. **Good signal: Octelium composes-with-ecosystem rather than reinvents.**
- **Alternatives worth knowing:**
  - **Tailscale** — commercial SaaS + OSS client; WireGuard-based; simpler but not self-hosted control plane
  - **Headscale** — OSS self-hosted Tailscale control-plane
  - **Cloudflare Access** — commercial ZTNA SaaS
  - **Teleport** — OSS + commercial ZTNA with SSH/DB focus
  - **Pomerium** — OSS identity-aware proxy
  - **Boundary (HashiCorp)** — OSS identity-aware access
  - **ngrok** / **Cloudflare Tunnel** — commercial tunnel services (feature overlap only)
  - **Kong / Apigee** — API gateways (feature overlap on API-gateway use case)
  - **Choose Octelium if:** you want unified ZTNA+VPN+tunnel+API-gateway + Kubernetes-native + policy-as-code + self-hosted + Apache/AGPL.
  - **Choose Headscale if:** you only need Tailscale-equivalent VPN without ZTNA/API-gateway scope.
  - **Choose Teleport if:** you want focused SSH/DB/K8s access with modern ZTNA.
  - **Choose Pomerium if:** you want identity-aware web-proxy specifically.

## Links

- Repo: <https://github.com/octelium/octelium>
- Homepage: <https://octelium.com>
- Docs: <https://octelium.com/docs>
- Quick install: <https://octelium.com/docs/octelium/latest/overview/quick-install>
- Management: <https://octelium.com/docs/octelium/latest/overview/management>
- Discord: <https://octelium.com/external/discord>
- Headscale (alt, OSS Tailscale control plane): <https://headscale.net>
- Teleport (alt): <https://goteleport.com>
- Pomerium (alt): <https://www.pomerium.com>
- Boundary (alt): <https://www.boundaryproject.io>
- CEL: <https://cel.dev>
- OPA: <https://www.openpolicyagent.org>
