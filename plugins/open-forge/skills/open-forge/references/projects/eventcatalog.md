---
name: EventCatalog
description: "Architecture catalog for distributed systems. Document domains/services/events/schemas with AI-powered discovery + interactive visualizations. 15+ generators (Kafka, EventBridge, RabbitMQ, ...). Node.js + Astro. MIT. 31,000+ catalogs. Active."
---

# EventCatalog

EventCatalog is **"Swagger UI / SpectaQL — but for event-driven architectures"** — a documentation platform for distributed systems. Catalog your **domains + services + events + schemas** in one browsable UI. **AI-powered discovery** + interactive visualizations + **15+ generators** for Kafka / Amazon EventBridge / RabbitMQ / AsyncAPI / OpenAPI / etc. Static-site-generated (Astro under the hood); can be self-hosted OR deployed as static docs. 31,000+ catalogs created (per README).

Built + maintained by **event-catalog org** + 69 contributors. License: **MIT**. Active; well-documented at eventcatalog.dev; Discord community; live demo at demo.eventcatalog.dev; extensive plugin ecosystem (generators).

Use cases: (a) **microservices-docs catalog** — teams publish their events + services (b) **event-driven architecture documentation** — onboard new engineers fast (c) **schema registry UI** — browse Kafka/EventBridge schemas (d) **cross-team API contract discovery** — who produces / who consumes what (e) **architectural decision-record repository** — document "why" alongside "what" (f) **internal developer portal component** — piece of larger IDP (g) **AI-assisted-discovery of undocumented events** (h) **compliance/audit trail** — document data flows for GDPR/SOX.

Features (per README):

- **Architecture catalog** — domains / services / events / schemas
- **AI-powered discovery**
- **Interactive visualizations**
- **15+ generators**: Kafka, Amazon EventBridge, RabbitMQ, AsyncAPI, OpenAPI, plus more
- **Static-site generation** (Astro)
- **Multi-team collaboration**
- **Markdown-driven** docs
- **MIT license**

- Upstream repo: <https://github.com/event-catalog/eventcatalog>
- Docs: <https://www.eventcatalog.dev/docs>
- Live demo: <https://demo.eventcatalog.dev>
- Discord: <https://discord.gg/3rjaZMmrAm>
- npm: `@eventcatalog/core`

## Architecture in one minute

- **Node.js + Astro**
- **Generates static site** — can deploy to S3 / Netlify / Vercel / nginx
- **Markdown-driven** content
- **Resource**: low — build-time compute; run-time static
- **No DB required** (static output)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Static site container (nginx-served)**                        | Self-host                                                                        |
| **Static hosting** | **S3 / Netlify / Vercel / GitHub Pages**                        | **Primary for static**                                                                                   |
| **Node.js**        | `npx @eventcatalog/create-eventcatalog`                         | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `architecture.example.com`                                  | URL          | TLS                                                                                    |
| Catalog source       | Git repo with markdown                                      | Content      |                                                                                    |
| Generators to enable | Kafka/EventBridge/RabbitMQ/AsyncAPI/OpenAPI                 | Config       |                                                                                    |
| AI provider (opt)    | For AI-discovery                                            | AI          |                                                                                    |
| Auth (opt)           | If exposing beyond company VPN                              | Security     |                                                                                    |

## Install via static-site

```sh
npx @eventcatalog/create-eventcatalog@latest my-catalog
cd my-catalog
npm install
npm run build
# dist/ is static HTML — deploy to your preferred host
```

Or Docker:
```yaml
services:
  eventcatalog:
    image: nginx:alpine
    volumes:
      - ./my-catalog/dist:/usr/share/nginx/html:ro
    ports: ["8080:80"]
```

## First boot

1. Scaffold catalog with CLI
2. Define first domain + first service + first event
3. Configure generators for each upstream system (Kafka topics, EventBridge schemas, etc.)
4. Build → deploy static output
5. Put behind TLS + company-auth (VPN / IAP / Authelia)
6. Set up CI to regenerate on source-system changes
7. Announce to team

## Data & config layout

- Markdown files in Git repo — all config + content
- `dist/` — static build output
- **No runtime DB** — fully static

## Backup

Git repo = backup (standard).

## Upgrade

1. Releases: <https://github.com/event-catalog/eventcatalog/releases>. Active.
2. `npm update @eventcatalog/core` + rebuild
3. Major-version may require markdown-frontmatter changes

## Gotchas

- **ARCHITECTURE-DOCS = LEAKAGE RISK**:
  - Publishes internal architecture, event names, schemas, data flows
  - If exposed publicly by mistake → reconnaissance goldmine for attackers
  - **Recipe convention: "internal-architecture-doc-exposure-risk" callout**
  - **NEW recipe convention** (EventCatalog 1st formally)
  - Equivalent to "internal network diagram leak" risk
- **93rd HUB-OF-CREDENTIALS TIER 3 (soft)**:
  - By itself: just docs; no creds
  - BUT reveals architecture secrets → soft credential-equivalent
  - **93rd tool in hub-of-credentials family — Tier 3**
- **GENERATORS MAY CONTAIN UPSTREAM CREDENTIALS**:
  - Kafka-generator needs Kafka brokers + creds
  - EventBridge needs AWS IAM credentials
  - RabbitMQ needs broker creds
  - These CREDS-IN-CI-PIPELINE to regenerate catalog
  - **Recipe convention: "generator-credentials-in-build-pipeline" callout**
  - **NEW recipe convention** (EventCatalog 1st)
- **AI-POWERED DISCOVERY = LLM USAGE**:
  - AI-discovery may require cloud LLM (OpenAI/Anthropic/etc.)
  - Internal architecture-info sent to 3rd party → DATA EXFILTRATION concern
  - **Recipe convention: "LLM-feature-sends-data-externally" callout**
  - **NEW recipe convention** — increasingly important
  - Mitigation: local LLM (via Ollama) OR self-hosted inference
- **31,000+ CATALOGS CREATED = ADOPTION SIGNAL**:
  - Public-metric of usage
  - **Recipe convention: "public-adoption-metric" positive-signal**
- **15+ GENERATORS = ECOSYSTEM BREADTH**:
  - Kafka, EventBridge, RabbitMQ, AsyncAPI, OpenAPI, ...
  - Wider than competitors (Backstage, Internal Developer Platforms)
  - **Recipe convention: "broad-generator-ecosystem positive-signal"** (reinforces Backstage-style)
- **ASTRO-GENERATED = FAST + STATIC**:
  - Static output = easy to deploy + no runtime vulnerabilities
  - **Recipe convention: "static-site-generated-no-runtime-vulnerabilities" positive-signal**
  - **NEW positive-signal convention** (EventCatalog 1st; applicable to many static tools)
- **69 CONTRIBUTORS**:
  - all-contributors badge
  - **Recipe convention: "all-contributors-recognition positive-signal"**
  - **NEW positive-signal convention** (EventCatalog 1st named)
- **MARKDOWN-FILE-BASED META-FAMILY EXTENDED**:
  - Flatnotes + Basic Memory + Raneto (prior batches) — knowledge bases
  - EventCatalog is similar: markdown-driven content
  - **Markdown-file-based-knowledge-base META-FAMILY: 4 tools** (+EventCatalog as architecture-docs variant)
  - 4-tool milestone
- **INSTITUTIONAL-STEWARDSHIP**: event-catalog org + 69 contributors + npm-published + Discord + commercial-tier (David Boyne). **79th tool — org-with-visible-contributor-community sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + CI + docs + Discord + live-demo + releases + npm + 69-contributors + all-contributors-badge + 31k-catalogs + license-MIT. **87th tool in transparent-maintenance family.**
- **COMMERCIAL-TIER PRESENT** (check for David Boyne's hosted tier/enterprise tier):
  - EventCatalog has a hosted enterprise tier
  - Similar to Dittofeed (106) / tududi (107) patterns — open-core sustainable-OSS
  - Reinforces commercial-tier-taxonomy
- **INTERNAL-DEVELOPER-PLATFORM-CATEGORY (adjacent):**
  - **EventCatalog** — event-driven arch docs
  - **Backstage** (Spotify) — generic IDP
  - **Port** — commercial IDP
  - **Cortex** — commercial IDP
  - **Roadie** — managed Backstage
- **ALTERNATIVES WORTH KNOWING:**
  - **Backstage** — if you want generic internal developer platform
  - **Confluence / Notion** — if you want general-purpose docs
  - **Swagger/Redoc** — if you only need REST API docs
  - **Choose EventCatalog if:** you have event-driven architecture + want visual + generator-driven docs.
- **PROJECT HEALTH**: active + 69-contributors + 31k-catalogs + commercial-tier + Discord + CI. EXCELLENT.

## Links

- Repo: <https://github.com/event-catalog/eventcatalog>
- Docs: <https://www.eventcatalog.dev>
- Demo: <https://demo.eventcatalog.dev>
- Discord: <https://discord.gg/3rjaZMmrAm>
- Backstage (alt): <https://backstage.io>
