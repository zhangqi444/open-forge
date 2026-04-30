---
name: KrakenD
description: "Ultra-high-performance API Gateway for microservices. Go. Stateless linear-scalability; 70K+ reqs/s single instance; <50MB RAM at 1000 concurrent. Content aggregation, transformation, security, throttling, telemetry. GitOps + declarative config. KrakenD-CE community edition; commercial KrakenD Enterprise."
---

# KrakenD

KrakenD is **"Kong / Tyk / AWS API Gateway — but ultra-high-performance + stateless + Go + declarative-config-driven"** — an extensible API Gateway for microservices. **Stateless** by design (no coordination / centralized persistence between nodes → true linear scalability). **70K+ reqs/s on single regular-size instance**. **<50MB RAM at 1000+ concurrent connections**. **Declarative configuration** via JSON (GitOps-friendly).

Built + maintained by **krakend + devopsfaith** orgs (Spanish team). KrakenD-CE = open-source community edition (**Apache 2.0**); separate **KrakenD Enterprise** commercial product with additional features. Active; FOSSA license-compliance; well-documented; high-performance focus.

Use cases: (a) **microservices-front-door** — aggregate calls + rate-limit + auth (b) **Backend-For-Frontend (BFF)** — tailor API per client (c) **API-aggregation / composition** — mash multiple backend calls into one (d) **security-hardening layer** — JWT / OAuth / CORS / HSTS / rate-limit without touching backends (e) **legacy-API-modernization** — XML→JSON transparent conversion (f) **high-throughput edge-gateway** — performance-critical traffic (g) **GitOps-driven API-platform** — config-as-code; declarative (h) **platform-agnostic deploy** — Kubernetes + self-hosted + bare-metal.

Features (per README):

- **Ultra-high performance** (70K+ reqs/s; <50MB RAM)
- **Stateless** linear-scalability
- **Content aggregation + composition + filtering**
- **Content manipulation** (XML↔JSON transparent conversion)
- **Zero-trust security**: CORS, OAuth, JWT, HSTS, clickjacking, HPKP, MIME-sniffing protection, XSS protection
- **Concurrent backend calls**
- **SSL + HTTP2**
- **Throttling + rate-limiting** (multi-layer, bursting, load-balancing, circuit-breaker)
- **Telemetry**: Datadog, Zipkin, Jaeger, Prometheus, Grafana
- **Extensible**: Go plugins, Lua scripts, Martian, Google CEL
- **GitOps + declarative config** (JSON)

- Upstream repo: <https://github.com/krakend/krakend-ce>
- Website: <https://www.krakend.io>
- Docs: <https://www.krakend.io/docs/overview/>

## Architecture in one minute

- **Go** single binary
- **JSON configuration** (declarative)
- **Stateless** — no DB; config is the source-of-truth
- **Resource**: low — <50MB RAM at high load
- **Horizontal scale** — add nodes freely

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |
| **Binary**         | **Multi-platform**                                              | Bare-metal                                                                                   |
| **Kubernetes**     | **Helm + Manifests**                                            | Cloud-native                                                                                   |
| **RPM/DEB**        | **Linux package**                                                                            |                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain(s)            | API endpoints                                               | URL          | TLS                                                                                    |
| Config JSON          | Endpoint definitions + backend mappings                     | **CRITICAL** | **Source of truth; GitOps**                                                                                    |
| Backend services     | Upstream APIs to proxy                                      | Integration  |                                                                                    |
| JWT signing keys     | If JWT validation                                           | Security     |                                                                                    |
| OAuth provider       | If OAuth integration                                        | Auth         |                                                                                    |
| Rate-limit config    | Per-endpoint + global                                                                                                  | Config       |                                                                                    |
| Telemetry endpoints  | Datadog / Zipkin / Jaeger / Prometheus                                                                                 | Observability |                                                                                    |

## Install via Docker

```yaml
services:
  krakend:
    image: devopsfaith/krakend:latest        # **pin version**
    volumes:
      - ./krakend.json:/etc/krakend/krakend.json:ro
    ports: ["8080:8080"]
    restart: unless-stopped
```

## First boot

1. Write `krakend.json` declaratively
2. Validate config with `krakend check -c krakend.json`
3. Start container
4. Test first endpoint
5. Configure JWT / OAuth
6. Enable telemetry
7. Deploy multiple nodes behind LB for HA
8. GitOps: config-in-Git, CI-deploy

## Data & config layout

- `krakend.json` — ALL configuration (GitOps source)
- Stateless — no runtime state

## Backup

Config-in-Git = backup. Stateless service = no data backup needed.

## Upgrade

1. Releases: <https://github.com/krakend/krakend-ce/releases>. Active.
2. Docker pull + restart
3. Config-schema changes documented per-version

## Gotchas

- **101st HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1**:
  - API Gateway holds: JWT signing keys + OAuth client-secrets + backend-auth-credentials + rate-limit-keys + telemetry-keys
  - Compromise of KrakenD → ALL backend services compromised (attacker can forge JWTs, bypass rate-limit, see all traffic)
  - **101st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL** 🎯 (**101-TOOL MILESTONE in hub-of-credentials + crossing 100 on previous tool Scriberr**)
  - **NEW CROWN-JEWEL Tier 1 sub-category: "API-gateway-credential-hub"** (1st — KrakenD formally)
  - **CROWN-JEWEL Tier 1: 26 tools / 23 sub-categories**
- **STATELESS-BY-DESIGN POSITIVE-SIGNAL**:
  - No DB; no coordination; horizontal scale trivially
  - Reinforces "stateless-tool-simpler-ops" (now 8 tools: prior 7 + **KrakenD**)
  - **Stateless-tool-rarity: 8 tools** 🎯 **8-TOOL MILESTONE**
- **ULTRA-HIGH-PERFORMANCE CLAIMS**:
  - 70K+ reqs/s + <50MB RAM
  - Go compiled + stateless = plausible
  - **Recipe convention: "performance-benchmarked positive-signal"** — concrete numbers
  - **NEW positive-signal convention** (KrakenD 1st formally)
- **GITOPS + DECLARATIVE CONFIG**:
  - Config-as-code; no UI-clicks for config
  - Reviewable; versionable; rollback-able
  - **Recipe convention: "declarative-config-GitOps-ready positive-signal"**
  - **NEW positive-signal convention** (KrakenD 1st formally)
- **COMMERCIAL-TIER-TAXONOMY**:
  - KrakenD-CE (Apache 2.0 OSS) + KrakenD Enterprise (commercial)
  - Similar to Dittofeed (106) "open-core-with-licensed-closed-source-extensions"
  - Reinforces that sub-category
- **NO-VENDOR-LOCK-IN CLAIM**:
  - Reuse existing tools (telemetry, IdP)
  - Gateway doesn't try to replace ecosystem
  - **Recipe convention: "no-vendor-lock-in-claim positive-signal"** — architectural-philosophy
  - **Zero-lock-in: 6 tools** (prior 5 + **KrakenD**) 🎯 **6-TOOL MILESTONE**
- **EXTENSIBILITY MECHANISMS**:
  - Go plugins (compiled)
  - Lua scripts (embedded)
  - Martian proxy-matchers
  - Google CEL expressions
  - **4 extension mechanisms** — unusually flexible
  - **Recipe convention: "multi-language-extension-mechanisms positive-signal"**
  - **NEW positive-signal convention** (KrakenD 1st formally)
- **FOSSA-LICENSE-COMPLIANCE BADGE**:
  - Supply-chain-license transparency
  - **Recipe convention: "FOSSA-license-compliance positive-signal"** — reinforces (prior YunoHost 104)
  - **2 tools now** with FOSSA-badge
- **TELEMETRY INTEGRATIONS = BROAD**:
  - Datadog + Zipkin + Jaeger + Prometheus + Grafana
  - **Recipe convention: "broad-telemetry-integration positive-signal"**
- **MULTI-LAYER RATE-LIMITING**:
  - Both client-facing AND KrakenD-to-backend
  - Circuit-breaker built-in
  - Bursting + load-balancing
- **SOC2/COMPLIANCE-ADJACENT TOOL**:
  - Rate-limit + OAuth + JWT + logging = compliance-enabling
- **INSTITUTIONAL-STEWARDSHIP**: krakend + devopsfaith orgs (Spanish team) + commercial-parallel (KrakenD Enterprise) + community. **87th tool — commercial-parallel-with-OSS-core sub-tier** (reinforces Dittofeed / Fasten precedents).
- **TRANSPARENT-MAINTENANCE**: active + Go + FOSSA + extensive-docs + commercial-tier + multi-platform + Apache-2.0. **95th tool in transparent-maintenance family.**
- **API-GATEWAY-CATEGORY (crowded):**
  - **KrakenD** — Go; stateless; performance-first
  - **Kong** — Lua/Nginx; plugins-rich; commercial-tier
  - **Tyk** — Go; open-source-core; commercial-tier
  - **APISIX** — Lua/Nginx; Apache project
  - **Traefik** — Go; modern-ingress; auto-discovery
  - **Envoy** — C++; Istio-foundation
  - **Zuul / Spring Cloud Gateway** — Java/JVM
  - **AWS API Gateway / Google Apigee / Azure API Management** — commercial cloud
- **ALTERNATIVES WORTH KNOWING:**
  - **Kong** — if you want biggest plugin ecosystem
  - **APISIX** — if you want Apache project + Lua-based
  - **Traefik** — if you want reverse-proxy + gateway combined
  - **Envoy** — if you want service-mesh + gateway
  - **Choose KrakenD if:** you want Go + stateless + declarative + performance-first + no-vendor-lock-in.
- **PROJECT HEALTH**: active + commercial-backing + performance-focus + broad-integration + FOSSA. EXCELLENT.

## Links

- Repo: <https://github.com/krakend/krakend-ce>
- Website: <https://www.krakend.io>
- Docs: <https://www.krakend.io/docs/overview/>
- Kong (alt): <https://github.com/Kong/kong>
- APISIX (alt): <https://github.com/apache/apisix>
- Traefik (alt): <https://github.com/traefik/traefik>
- Envoy (alt): <https://github.com/envoyproxy/envoy>
