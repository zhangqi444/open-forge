---
name: bknd
description: "Lightweight Firebase/Supabase alternative — fully functional visual backend for database + auth + media + workflows. Node 22+/Bun/Deno/Cloudflare Workers/edge-compatible. TypeScript/npm package. Pre-1.0 / actively developing. FSL-1.1-MIT license (Functional Source License → MIT after 2 years). Self-hostable + embeddable in frontend framework."
---

# bknd

bknd is **"a self-hostable Firebase/Supabase alternative that fits in a Cloudflare Worker"** — a lightweight visual backend-as-a-service published as an npm package. Spins up a Postgres/SQLite-backed data API, auth, media/file handling, and workflow automation in one shot; deploys anywhere that runs JavaScript (Node 22+, Bun, Deno, Browser, Cloudflare Workers, Vercel, Netlify, AWS Lambda, Valtown). Designed to avoid vendor lock-in by being adapter-based on every infrastructure dimension (database, storage, runtime).

Built + maintained by **bknd-io** (team + community). **License: FSL-1.1-MIT** (Functional Source License — source-available with 2-year-to-MIT conversion; see below). **Pre-1.0 / actively developed** — upstream README warns: *"bknd is still under active development and therefore full backward compatibility is not guaranteed before reaching v1.0.0."*

Use cases: (a) **Firebase / Supabase alternative** — self-hosted BaaS (b) **CMS** with visual schema editor (WordPress alternative) (c) **AI agent backend** — state store + MCP server integration (d) **SaaS products** with multi-tenant RLS + user management (e) **prototypes / MVPs** — backend in minutes without infra (f) **API-first apps** with TypeScript SDK or OpenAPI REST (g) **IoT / embedded** where minimal footprint matters (h) **edge-deployed backend** on Cloudflare Workers / Vercel Edge.

Features:

- **Data**: visual schema editor → REST API with full CRUD
- **Auth**: user management, roles, permissions, RLS-style data isolation
- **Media**: file/image upload + storage with adapters (S3, R2, Cloudinary, FS, OPFS)
- **Flows**: workflow automation primitives
- **Admin UI**: drag-and-drop config; no YAML
- **Integrated MCP server** — AI agents can interact via Model Context Protocol
- **Runtimes**: Node 22+, Bun 1.0+, Deno, Browser, Cloudflare Workers/Pages, Vercel, Netlify, AWS Lambda
- **DBs**: LibSQL, Node SQLite, Bun SQLite, Cloudflare D1, Durable Objects SQLite, SQLocal, Postgres (Vanilla / Supabase / Neon / Xata)
- **Storage**: S3 + S3-compatible (Tigris, R2, MinIO) + Cloudinary + FS + OPFS
- **Frameworks**: React, Next.js, React Router, Astro, Vite, Waku
- **Bundle size**: ~300KB gzipped minimum for a full API-only app
- **TypeScript SDK** + **OpenAPI REST** — typed client access
- **WinterTC Minimum Common Web Platform API** — portable JavaScript base

- Upstream repo: <https://github.com/bknd-io/bknd>
- Homepage: <https://bknd.io>
- Docs: <https://docs.bknd.io>
- npm: <https://www.npmjs.com/package/bknd>
- Live demo (StackBlitz): <https://stackblitz.com/github/bknd-io/bknd-demo>

## Architecture in one minute

- **TypeScript / npm package** — ships as a library
- **Universal runtime**: built on WinterTC standard APIs → works on Node / Bun / Deno / Workers / browsers
- **Modular**: data + auth + media + flows as separate opt-in modules
- **Adapter-based**: swap DB (SQLite ↔ Postgres), storage (FS ↔ S3 ↔ R2), runtime at will
- **Resource**: tiny — can run inside a Cloudflare Worker (128MB limit); scales to full servers

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Standalone (Node)** | `npx bknd` or install from npm                              | **Simplest self-host**                                                             |
| Docker             | Containerize Node app with bknd                                           | Standard Node Docker pattern                                                                   |
| Cloudflare Workers | Deploy bknd + D1 database + R2 storage                                                      | Edge path; free tier viable for small use                                                                             |
| Vercel / Netlify / AWS Lambda | Serverless deploy                                                                   | Function-per-request pattern                                                                                           |
| Embedded in your framework | `import` into Next.js / React / Astro / etc.                                                          | Integrated use                                                                                                                      |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Runtime              | Node 22.13+ required (per README)                           | Infra        | `node:sqlite` requires Node 22.13+                                                                         |
| DB adapter           | SQLite (default) or Postgres                                | DB           | Choose at setup                                                                                    |
| Storage adapter      | FS / S3 / R2 / Cloudinary                                                      | Media        | If using file features                                                                                    |
| Auth config          | JWT secret, OIDC providers (if any)                                                            | Auth         | Generate secrets (see immutability-of-secrets)                                                                                    |
| Admin bootstrap      | First admin user via setup UI                                                                                      | Bootstrap    | Strong password                                                                                                              |

## Install (simplest path)

```sh
npx bknd
# Follow setup UI: create admin, configure DB, configure schema
```

Or in Docker:

```yaml
services:
  bknd:
    image: node:22-alpine
    working_dir: /app
    command: sh -c "npm install bknd && npx bknd"
    ports: ["3000:3000"]
    volumes:
      - ./bknd-data:/app/data
```

Or embed in your Next.js app per <https://docs.bknd.io>.

## First boot

1. Run bknd → browse admin UI
2. Create admin user (first-run setup)
3. **Set JWT secret / auth keys** — treat as immutable (see gotchas)
4. Define your data schema visually (tables + fields + relations)
5. Set up auth providers (password / OIDC / etc.)
6. Configure media storage adapter if using files
7. Build first flow (workflow automation) if relevant
8. Export TypeScript SDK or use REST API from your frontend
9. Back up DB + config
10. TLS reverse proxy if exposed

## Data & config layout

- **SQLite file** or external Postgres — depending on adapter
- **Media storage** — depending on adapter (FS / S3 / R2 / etc.)
- **bknd config** — typically `bknd.config.ts` or env vars
- **Auth secrets** — JWT signing keys (immutable; see below)

## Backup

- **Postgres adapter**: standard `pg_dump`
- **SQLite adapter**: `sqlite3 bknd.db ".backup backup.db"`
- **S3 / R2 storage**: separate backup of the storage bucket (versioning recommended)
- **Config files** — version-controlled in Git

## Upgrade

1. Releases: <https://github.com/bknd-io/bknd/releases>. Active pre-1.0 development.
2. `npm update bknd` + restart.
3. **BREAKING CHANGES EXPECTED pre-1.0** — read release notes + test in staging before prod.
4. Back up DB + config FIRST.

## Gotchas

- **PRE-1.0 = BREAKING CHANGES EXPECTED** per upstream's own README: *"full backward compatibility is not guaranteed before reaching v1.0.0."* **Honest transparent maintenance signal — 8th tool in transparent-status family.** Don't adopt for long-life production unless you accept migration cost at every release.
- **FSL-1.1-MIT LICENSE** (Functional Source License → MIT conversion):
  - **FSL is source-available, NOT true OSS (OSI-approved)**. Restricts COMPETING uses (other SaaS vendors can't clone bknd and offer it as a service) for 2 years.
  - **After 2 years, each release auto-converts to MIT** (permissive OSS).
  - **Most self-host / embed / personal / internal-commercial use = allowed immediately**.
  - **Forbidden use (in the first 2 years)**: offering bknd-as-a-Service in competition with upstream's commercial offering.
  - **Read the license text carefully** for your use case: <https://github.com/bknd-io/bknd/blob/main/LICENSE>
  - **New license-taxonomy entry**: **"source-available with time-delayed OSS conversion"** — distinct from:
    - Traditional OSI-approved OSS (MIT / Apache / GPL / AGPL)
    - Pure source-available non-OSS (BSL = Business Source License)
    - Commercial closed-source
  - **Same FSL pattern**: Sentry, others adopting FSL/BSL-lineage licenses. Emerging 2024-2026 license class. Worth-naming.
- **IMMUTABILITY-OF-SECRETS**: JWT signing key + DB password + storage adapter credentials. **13th tool in immutability-of-secrets family.** Changing JWT key invalidates all existing user sessions; handle with care.
- **HUB-OF-CREDENTIALS tier (LIGHT-to-MID)**: bknd IS the auth + data backend for YOUR app. If compromised, all user accounts in your app are compromised + all data is exposed. **17th tool in hub-of-credentials family.** Treat as Tier 2 (crown-jewel proper, not control-plane).
- **Edge-deployment vs stateful backend**: bknd runs on Cloudflare Workers but Workers are stateless + ephemeral. For persistent state you NEED a real DB (D1, Durable Objects, Neon, Supabase) — not just the Worker. Understand the split.
- **WinterTC portability is REAL but not universal**: most code works everywhere per the Minimum Common API. Advanced features (crypto, streaming, specific Node APIs) may have runtime-specific gotchas. Test where you deploy.
- **Node 22.13+ hard requirement**: uses `node:sqlite` which landed in Node 22.13. Older Node = doesn't work. Distro packages often lag; use Volta/nvm/asdf to pin Node versions.
- **Bundle size discipline**: `bknd` npm package is large because it includes the whole backend. Using it as a library (not full CLI) = much smaller bundle (~300KB gzipped for API-only). Read docs for optimal bundling.
- **Multi-tenant RLS (Row-Level Security)**: bknd offers this; **but validate your policies carefully** — same class as Postgres RLS in general, Supabase RLS gotchas. Mis-configured RLS = data leak across tenants. Test with multiple user accounts as part of integration tests.
- **Plugin-as-RCE caveat**: bknd flows can execute user-defined code. **Treat flow code as privileged** — a malicious admin can define flows that exfiltrate data or attack your infra. Audit flow definitions like you audit infrastructure-as-code.
- **AI agent / MCP server features**: interesting but newer surface. MCP is a 2024+ protocol from Anthropic. Evaluate maturity for production AI-agent use.
- **Self-hosted-Firebase-class positioning**: bknd competes with:
  - **Supabase** — Postgres-based; open-core; larger ecosystem
  - **Pocketbase** — Go + SQLite single-binary; simpler; MIT (great license)
  - **Appwrite** — Docker-heavy; full-featured; BSD-3
  - **Nhost** — Hasura-based; Postgres + GraphQL
  - **bknd's niche**: lightweight + edge-compatible + TypeScript-native + adapter-based-universal-portability.
- **Pre-1.0 means "evaluate carefully"**: don't bet production on pre-1.0 tools unless you're willing to migrate at each minor. For prototypes / MVPs / internal tools / homelab / AI-agent-backends = reasonable now.
- **Project health**: active dev + npm releases + documentation + demos. Funded via commercial offering (implicit via FSL structure). Positive signals.
- **Alternatives worth knowing:**
  - **Supabase** (Postgres + RLS + edge functions) — more mature, more features, open-core
  - **Pocketbase** (Go + SQLite single-binary) — simpler + MIT; less featureful
  - **Appwrite** (Docker + full-featured) — heavier + BSD-3
  - **Firebase** (Google commercial SaaS) — the incumbent
  - **Hasura** (GraphQL over Postgres) — different architecture
  - **Directus** (headless CMS over existing DB) — data-centric
  - **Xano** (commercial no-code backend) — SaaS
  - **Choose bknd if:** you want lightweight + edge-compatible + TypeScript-native + self-hosted + willing-to-accept-pre-1.0 + adapter-based-portability.
  - **Choose Pocketbase if:** you want single-binary + permissive-MIT + SQLite-only + stable.
  - **Choose Supabase if:** you want mature + Postgres + bigger-ecosystem + open-core acceptable.
  - **Choose Appwrite if:** you want full-featured + Docker-native + don't mind weight.

## Links

- Repo: <https://github.com/bknd-io/bknd>
- Homepage: <https://bknd.io>
- Docs: <https://docs.bknd.io>
- npm: <https://www.npmjs.com/package/bknd>
- StackBlitz demo: <https://stackblitz.com/github/bknd-io/bknd-demo>
- License: <https://github.com/bknd-io/bknd/blob/main/LICENSE>
- FSL explanation: <https://fsl.software>
- Pocketbase (alt, single-binary Go): <https://pocketbase.io>
- Supabase (alt, Postgres open-core): <https://supabase.com>
- Appwrite (alt, Docker): <https://appwrite.io>
- Directus (alt, headless CMS): <https://directus.io>
- MCP: <https://modelcontextprotocol.io>
