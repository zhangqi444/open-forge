---
name: Convoy
description: "Open-source high-performance webhooks gateway. Ingest, persist, debug, deliver webhooks at scale. Retries, rate-limiting, static-IPs, circuit-breakers, rolling-secrets, fan-out. Go. MPL-2.0. Frain-dev org (commercial-tier + OSS)."
---

# Convoy

Convoy is **"Webhook / Hookdeck / Svix — but OSS + self-hosted + enterprise-grade"** — an open-source high-performance webhooks gateway. Securely ingest, persist, debug, deliver, manage **millions of events** reliably with retries + rate-limiting + static-IPs + circuit-breakers + rolling-secrets + fan-out routing. Acts as dedicated message queue for webhooks; horizontally scalable (api-server + workers + scheduler + socket-server components scale independently); payload-signing; bearer-token auth; static-IPs for firewall-restricted environments; rich web UI for debugging.

Built + maintained by **Frain.dev (frain-dev)** — commercial-backed OSS org. License: **MPL-2.0** (verify). Active; Docker Compose deployment; golangci-lint + integration-tests CI; getconvoy.io commercial website; Slack community.

Use cases: (a) **outbound-webhooks from your app** — reliable delivery to customer endpoints (b) **inbound-webhooks from third-parties** — Stripe/GitHub/etc. → route to internal services (c) **webhooks-as-a-service** — build-your-own Stripe-webhook-infrastructure (d) **replace ad-hoc-retry-queues** — "we have bespoke retry Lambda" → Convoy (e) **webhook debugging** — see failures + payloads + replay (f) **multi-tenant SaaS webhooks** — dispatch to tenants' endpoints at scale (g) **strict-firewall outbound webhooks** — static-IPs for customer allowlisting (h) **rolling-secrets for HMAC** — rotate webhook signing keys without downtime (i) **fan-out event delivery** — one event → many endpoints.

Features (per README):

- **Webhooks Gateway** — edge-of-network streaming
- **Scalability** — independent-scaling api/workers/scheduler/socket
- **Security** — payload-signing + bearer-token + static-IPs
- **Fan-out** — route event to multiple endpoints
- **Rate-limiting** — per-endpoint limits
- **Retries + circuit-breakers** — reliable delivery
- **Rolling-secrets** — rotate HMAC keys
- **Debug UI** — payload inspection + replay
- **Multi-tenant** — SaaS-ready

- Upstream repo: <https://github.com/frain-dev/convoy>
- Website: <https://getconvoy.io>
- Docs: <https://docs.getconvoy.io>
- Community forum: <https://community.getconvoy.io>
- Slack: <https://join.slack.com/t/convoy-community/shared_invite/zt-xiuuoj0m-yPp~ylfYMCV9s038QL0IUQ>

## Architecture in one minute

- **Go** — api + workers + scheduler + socket servers
- **PostgreSQL** — DB
- **Redis** — queue (Asynq)
- **TypesenseOR Elasticsearch** (optional) — search
- **Resource**: moderate-to-heavy at scale; start 1-2GB RAM; scale workers horizontally
- **Ports**: API (5005) + health (varies)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream compose**                                            | **Primary**                                                                        |
| **Kubernetes**     | Helm chart                                                      | Production                                                                                   |
| **Binary**         | Single Go binary                                                                                                             | Available                                                                                   |
| **Source**         | `go build`                                                                                                             | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `webhooks.example.com`                                      | URL          | TLS MANDATORY                                                                                    |
| DB                   | PostgreSQL 13+                                              | DB           |                                                                                    |
| Redis                | Queue broker                                                | Queue        |                                                                                    |
| **HMAC signing keys** | Rolling-secrets                                            | **CRITICAL** | **Payload-integrity**                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong + MFA                                                                                    |
| Incoming endpoint secrets | Per-source verification                                                                                                 | Integration  |                                                                                    |
| SMTP (optional)      | Notification                                                                                                      | Email        |                                                                                                                                            |

## Install via Docker Compose

Follow: <https://docs.getconvoy.io/deployment/install-convoy/docker>

```yaml
services:
  web:
    image: getconvoy/convoy:latest        # **pin version**
    command: ["./cmd", "server", "--config", "/convoy.json"]
    ports: ["5005:5005"]
    volumes: [./convoy.json:/convoy.json]
    depends_on: [postgres, redis]

  worker:
    image: getconvoy/convoy:latest
    command: ["./cmd", "worker", "--config", "/convoy.json"]
    depends_on: [postgres, redis]

  scheduler:
    image: getconvoy/convoy:latest
    command: ["./cmd", "scheduler", "--config", "/convoy.json"]
    depends_on: [postgres, redis]

  postgres:
    image: postgres:17
    environment:
      POSTGRES_DB: convoy
      POSTGRES_USER: convoy
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine

volumes:
  pgdata: {}
```

## First boot

1. Start stack → run migrations
2. Browse admin UI → create first project
3. Define sources (incoming) + endpoints (outgoing)
4. Configure HMAC signing-keys + rolling-secrets
5. Test: POST to source → verify delivery to endpoint
6. Enable static-IPs (if customer requires)
7. Configure retry policy + circuit-breakers
8. Invite team members + RBAC
9. Back up DB

## Data & config layout

- PostgreSQL — events + endpoints + configs
- Redis — queues (ephemeral)
- `convoy.json` — main config

## Backup

```sh
docker compose exec postgres pg_dump -U convoy convoy > convoy-$(date +%F).sql
cp convoy.json backups/convoy-$(date +%F).json
```

## Upgrade

1. Releases: <https://github.com/frain-dev/convoy/releases>. Active.
2. Docker pull + restart; migrations auto-run
3. Workers + api + scheduler can be rolled separately (zero-downtime)

## Gotchas

- **WEBHOOK GATEWAY = EVENT-TRAFFIC CROWN-JEWEL**:
  - All webhook traffic flows through Convoy
  - Outbound: your events hit customer endpoints
  - Inbound: customer webhooks route to your services
  - Compromise = full event-stream visibility + manipulation
  - **81st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL** — sub-category "event-pipeline-infrastructure"
  - **NEW CROWN-JEWEL Tier 1 sub-category: "event-pipeline-infrastructure"** — 1st tool named (Convoy)
  - **CROWN-JEWEL Tier 1: 20 tools; 18 sub-categories**
- **HMAC SIGNING KEYS = PAYLOAD-INTEGRITY**:
  - Convoy signs outbound webhook payloads with HMAC
  - Customers verify signature to prevent replay + tampering
  - Key leak = attacker can mint valid-signed webhooks
  - **Rolling-secrets positive-signal**: Convoy supports rolling HMAC keys without breakage
  - **Recipe convention: "HMAC-rolling-secrets positive-signal"**
  - **NEW positive-signal convention** (Convoy 1st)
- **STATIC-IPs FOR CUSTOMER-ALLOWLISTING**:
  - Enterprise customers require: "deliver from these specific IPs"
  - Convoy supports routing through fixed-egress-IPs
  - **Recipe convention: "static-egress-IP-for-customer-firewalls positive-signal"**
  - **NEW positive-signal convention**
- **RATE-LIMITING = CUSTOMER-PROTECTION**:
  - Prevents overwhelming customer endpoints
  - Convoy rate-limits per-endpoint
- **CIRCUIT-BREAKERS**:
  - If customer endpoint fails → pause + exponential-backoff
  - Prevents cascading failures
  - **Recipe convention: "circuit-breaker-for-webhook-delivery positive-signal"**
- **RETRIES + QUEUE DEPTH**:
  - Failed webhooks retry with backoff
  - Queue grows during customer-outage
  - **Operational concern**: monitor queue depth; set max-retries + dead-letter-queue
- **FAN-OUT = MULTIPLIER EFFECT**:
  - One event → multiple endpoints
  - Misconfigured fan-out + high-volume source = amplified traffic
  - **Recipe convention: "fan-out-amplification-risk" callout**
- **PAYLOAD PERSISTENCE = PII RETENTION**:
  - Convoy stores webhook payloads for debugging/replay
  - Payloads often contain PII (customer emails, IDs, event data)
  - **Retention policy = compliance-feature** (reinforces Speakr 102 precedent)
  - **Recipe convention: "webhook-payload-PII-retention" callout**
- **MULTI-COMPONENT ARCHITECTURE**:
  - api + worker + scheduler + socket = 4 processes
  - Each can scale independently (positive)
  - Each has config + dependencies
  - **Recipe convention: "microservice-complexity-tax"** applies (Stoat 101 precedent) — now 3+ tools
- **COMMERCIAL-BACKED OSS**:
  - Frain.dev sells Convoy Cloud
  - OSS tier + Commercial tier
  - **Commercial-tier-taxonomy: "OSS + commercial-cloud parallel"** (reinforces many precedents)
- **MPL-2.0 LICENSE**:
  - File-level copyleft — modified files must be MPL; but can combine with proprietary
  - Less viral than AGPL
  - **Recipe convention: "MPL-2.0-weak-copyleft" sub-convention**
  - **NEW convention**
- **RISK: WEBHOOK-REPLAY-ATTACK**:
  - Replay-protection = timestamp + nonce
  - Convoy supports; verify config
- **PAYMENT-WEBHOOKS = HIGH SENSITIVITY**:
  - Stripe/PayPal/etc. webhook payloads = payment-events
  - Misdelivery → double-charge / missed-charge
  - **Recipe convention: "payment-webhook-reliability criticality" callout**
  - **NEW recipe convention** (Convoy 1st — critical category)
- **INSTITUTIONAL-STEWARDSHIP**: Frain.dev commercial org + community + Slack. **67th tool — founder-with-commercial-tier-funded-development sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + golangci-lint + integration-tests-CI + commercial-website + docs + forum + Slack. **75th tool in transparent-maintenance family** 🎯 **75-TOOL MILESTONE.**
- **WEBHOOK-GATEWAY-CATEGORY:**
  - **Convoy** — OSS; multi-tenant; enterprise-features
  - **Hookdeck** — commercial
  - **Svix** — commercial (OSS core)
  - **Pipedream** — commercial iPaaS
  - **Ngrok** — tunnel + inspect (different scope)
- **ALTERNATIVES WORTH KNOWING:**
  - **Svix** — commercial alternative with OSS core
  - **Hookdeck** — commercial; different feature-set
  - **Direct webhook-sending from app** — if scale small
  - **Choose Convoy if:** you want OSS + self-hosted + enterprise-features + multi-tenant.
- **PROJECT HEALTH**: active + commercial-backing + multi-component + CI + docs + forum + Slack. Strong.

## Links

- Repo: <https://github.com/frain-dev/convoy>
- Docs: <https://docs.getconvoy.io>
- Website: <https://getconvoy.io>
- Svix (alt OSS-core commercial): <https://www.svix.com>
- Hookdeck (alt commercial): <https://hookdeck.com>
- Ngrok (adjacent): <https://ngrok.com>
