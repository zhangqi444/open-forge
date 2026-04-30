---
name: AnyCable
description: "Realtime server for two-way reliable communication over WebSockets and SSE. Go + Ruby. Evil Martians. MIT. Pro + managed offerings. Rails Action Cable-compatible."
---

# AnyCable

AnyCable is **"Action Cable / Socket.io / Phoenix Channels — but faster, language-agnostic, production-grade WebSocket/SSE infra"** — a realtime server for two-way reliable communication over WebSockets and SSE. Originally a faster alternative to Rails' Action Cable (which became Ruby-process-bound); now evolved into a general realtime infra. Open source edition is in this repo; also Pro + managed offerings.

Built + maintained by **Evil Martians** (famous Ruby-community consultancy: Ruby on Rails, Rails itself, many open-source contributions). License: **MIT**. Active; extensive documentation.

Use cases: (a) **Rails + Action Cable scaling** — offload WS to AnyCable-go (b) **language-agnostic WS infra** — Rails-independent (c) **chat / multiplayer / collaborative apps** (d) **live-updates dashboards** (e) **notifications channel** (f) **SSE streaming** for one-way (g) **GraphQL-subscriptions transport** (h) **Rails-WS-on-Heroku-scale** workarounds.

Features (per README):

- **WebSockets + SSE**
- **Two-way reliable** communication
- **Pro + managed versions** available
- **MIT license** (OSS core)
- **Evil Martians** maintained

- Upstream repo: <https://github.com/anycable/anycable>
- Docs: <https://docs.anycable.io>
- Pro: <https://docs.anycable.io/pro>
- Managed: <https://plus.anycable.io>

## Architecture in one minute

- **AnyCable-go** WebSocket server (Go binary)
- **Ruby (or other language) app backend**
- **Redis** for pub/sub
- **Resource**: scales — Go WS server is lightweight
- **Port**: WS (8080 default)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`anycable/anycable-go`**                                      | **Primary**                                                                        |
| **Binary**         | Go binary                                                                                                              | Alt                                                                                   |
| **Rails + Docker** | Use alongside Rails app                                                                                               | Common use-case                                                                                   |
| **Kubernetes**     | Helm / Manifests                                                                                                       | Common production                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `ws.example.com`                                            | URL          | TLS (WSS)                                                                                    |
| Backend (RPC)        | gRPC to Rails app                                           | Connect      |                                                                                    |
| Redis                | Pub/sub                                                     | Infra        |                                                                                    |
| JWT secret (opt)     | Token-based client auth                                     | Config       |                                                                                    |

## Install via Docker

```yaml
services:
  anycable:
    image: anycable/anycable-go:1        # **pin major version**
    environment:
      ANYCABLE_RPC_HOST: rails:50051
      ANYCABLE_REDIS_URL: redis://redis:6379/0
      ANYCABLE_HOST: 0.0.0.0
      ANYCABLE_PORT: 8080
    ports: ["8080:8080"]
    depends_on: [rails, redis]

  rails:
    # Your Rails app with anycable-rails gem
    # exposes gRPC on 50051 for AnyCable to call back

  redis:
    image: redis:7-alpine
```

## First boot

1. Add `anycable-rails` gem to Rails app (or equivalent for your language)
2. Configure channels
3. Start AnyCable-go
4. Test client connection
5. Monitor Redis pub/sub health
6. Put behind WSS (reverse proxy with WS upgrade support)

## Data & config layout

- Stateless (AnyCable-go) — no persistent local data
- Redis = ephemeral pub/sub state
- Rails app = persistent data

## Backup

AnyCable itself is stateless — no backup needed.

## Upgrade

1. Releases: <https://github.com/anycable/anycable/releases>. Active.
2. Docker pull + restart (graceful shutdown for active WS connections)
3. Rails-side gem + AnyCable-go must match protocol version

## Gotchas

- **121st HUB-OF-CREDENTIALS TIER 3 — MILD**:
  - Holds active WS sessions + JWT-auth-tokens in flight
  - Pub/sub channels via Redis
  - **121st tool in hub-of-credentials family — Tier 3**
- **STATELESS-TOOL-RARITY**:
  - AnyCable-go is stateless — no local persistence
  - **Stateless-tool-rarity: 11 tools** (+AnyCable) 🎯 **11-TOOL MILESTONE**
- **RPC-TO-APP-BACKEND**:
  - AnyCable calls back to app via gRPC
  - App must expose gRPC endpoint
  - **Recipe convention: "RPC-callback-to-app-backend" architectural-pattern**
  - **NEW neutral-convention** (AnyCable 1st formally)
- **WS-UPGRADE REVERSE-PROXY REQUIREMENT**:
  - WebSockets require proxy with HTTP Upgrade support (Nginx, Traefik, Caddy all fine)
  - **Recipe convention: "WS-upgrade-reverse-proxy-requirement" callout**
  - **NEW recipe convention** (AnyCable 1st formally)
- **PROTOCOL-VERSION-MATCHING Rails gem ↔ AnyCable-go**:
  - **Recipe convention: "library-server-protocol-version-match" callout**
  - **NEW recipe convention** (AnyCable 1st formally)
- **EVIL MARTIANS STEWARDSHIP**:
  - Legendary Ruby-community consultancy
  - Maintainers of: martian_regexp, Imgproxy, AnyCable, Logux, many Rails contributions
  - **Recipe convention: "recognized-community-consultancy-steward positive-signal"** — reinforces Tecnativa (112), Zerodha Tech (111)
  - **NEW positive-signal convention** (AnyCable 1st formally — Evil Martians-specific)
  - **Commercial-consultancy-maintained-OSS-tool family: 3 tools** (Tecnativa + AnyCable/Evil Martians + Zerodha Tech)
- **COMMERCIAL-PARALLEL**:
  - AnyCable Pro + managed
  - **Commercial-parallel-with-OSS-core: 8 tools** (+AnyCable) 🎯 **8-TOOL MILESTONE**
- **MIT LICENSE**:
  - Non-copyleft; permits commercial use
  - **Recipe convention: "MIT-permissive-license neutral-signal"** — many tools
- **SECURITY-CONTACT PUBLISHED**:
  - README has `anycable@evilmartians.com` for vuln reports
  - **Recipe convention: "security-contact-published positive-signal"**
  - **NEW positive-signal convention** (AnyCable 1st formally)
- **REALTIME-INFRA-CATEGORY:**
  - **AnyCable** — Go; Ruby-origin; language-agnostic now
  - **Centrifugo** — Go; general-purpose
  - **Ably / Pusher** (commercial managed)
  - **Mercure** — SSE server
  - **Phoenix Channels** — Elixir
  - **NATS / MQTT** — different paradigm (pub/sub)
- **ALTERNATIVES WORTH KNOWING:**
  - **Centrifugo** — if you want language-agnostic from start
  - **Mercure** — if you want SSE only + Hub-spec
  - **NATS** — if you want pub/sub paradigm
  - **Choose AnyCable if:** you're Rails + Action Cable + need scale.
- **INSTITUTIONAL-STEWARDSHIP**: Evil Martians org + MIT + Pro + managed + docs + community. **107th tool — commercial-consultancy-OSS-arm sub-tier** (reinforces — 3 tools: Tecnativa + Evil Martians + Zerodha Tech).
- **TRANSPARENT-MAINTENANCE**: active + CI + docs + releases + Pro-parallel + security-contact + docs.anycable.io. **114th tool in transparent-maintenance family.**
- **PROJECT HEALTH**: active + Evil-Martians-backed + battle-tested + Pro-offerings. EXCELLENT.

## Links

- Repo: <https://github.com/anycable/anycable>
- Docs: <https://docs.anycable.io>
- Evil Martians: <https://evilmartians.com>
- Centrifugo (alt): <https://github.com/centrifugal/centrifugo>
- Mercure (alt): <https://mercure.rocks>
