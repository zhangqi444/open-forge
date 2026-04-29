---
name: medusa-project
description: Medusa recipe for open-forge. MIT-licensed headless commerce platform — TypeScript/Node.js backend + admin dashboard for building custom digital commerce applications (B2B/DTC/marketplaces/POS). Architected as modules on top of a framework; ships an Admin SPA and storefront-agnostic REST + GraphQL APIs. Self-host is **non-obvious** — upstream recommends either `create-medusa-app` CLI (Node-native, requires Postgres) or the `dtc-starter` Docker approach. Covers both, plus the (optional) Next.js Starter Storefront, production deployment model, and a reality check on Medusa Cloud being the upstream-preferred managed path.
---

# Medusa

MIT-licensed headless commerce platform. Upstream: <https://github.com/medusajs/medusa>. Docs: <https://docs.medusajs.com>. Cloud: <https://cloud.medusajs.com>.

TypeScript/Node.js framework + admin dashboard for building custom commerce apps. Unlike Shopify or WooCommerce, Medusa is a **toolkit** — you compose modules (products, orders, customers, carts, payments, shipping, promotions, tax, inventory, etc.) into your own backend, then build a storefront against its APIs.

Good fit for:

- B2B stores with custom pricing / approval flows
- DTC brands that need more than Shopify but less than a full custom rewrite
- Marketplaces / multi-vendor platforms
- Point-of-Sale / service businesses
- "Shopify but we own the code"

Less good fit for:

- "I want to click-deploy a store in 5 minutes." (Use Shopify / WooCommerce.)
- Teams without Node.js / TypeScript engineers.

## Architecture

A Medusa application is:

- **Backend** (`@medusajs/medusa` + Modules) — Node.js server (Express-like) that exposes REST + GraphQL APIs, plus a Vite-built **Admin SPA** served at `/app`. Runs on a single port (default `:9000`).
- **Storefront** — Customer-facing site. **Not included** — you build your own or use the [Next.js Starter Storefront](https://github.com/medusajs/nextjs-starter-medusa) (optional). The storefront talks to the backend via the Store API.
- **Postgres** — Primary DB.
- **Redis** (optional in dev, recommended in prod) — Event bus, cache, job queue.

So: at minimum, **1 Node process + 1 Postgres**. In production: add Redis, a worker process (or set `workerMode: "shared"`), and a reverse proxy.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `create-medusa-app` CLI | <https://docs.medusajs.com/learn/installation> | ✅ Recommended for dev | The "official" install path. Scaffolds a monorepo with backend + (optional) Next.js storefront. Requires Node + Postgres on the host. |
| `dtc-starter` + Docker | <https://github.com/medusajs/dtc-starter> | ✅ Alternative | Docker-only path if you don't want Node on the host. |
| Production deployment | <https://docs.medusajs.com/learn/deployment> | ✅ | Guides for Railway / Vercel / AWS / DigitalOcean / self-host. |
| Medusa Cloud | <https://cloud.medusajs.com> | ✅ | Managed PaaS from the Medusa team. Upstream pushes this for production use. |
| Build from source (contributors) | `yarn && yarn build` in the monorepo | ✅ | Contributors only. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `create-medusa-app` / `dtc-starter-docker` / `existing-project` | Drives section. |
| preflight | "Node version?" | Must be 20 LTS+ (and ≤ v24 if using Next.js Starter Storefront) | `node -v` check. |
| db | "Postgres host/port/user/pass/dbname?" | Free-text (sensitive) | Maps to `DATABASE_URL=postgres://user:pass@host:port/dbname`. The CLI can create one locally. |
| redis | "Redis URL?" | Free-text, e.g. `redis://localhost:6379` | Required in production; optional in dev. |
| storefront | "Install Next.js Starter Storefront?" | Boolean | If yes, requires Node ≤ v24. Adds `apps/storefront` to the monorepo. |
| secrets | "Session + cookie secrets?" | Free-text (sensitive) | `JWT_SECRET`, `COOKIE_SECRET`. Generate via `openssl rand -base64 32`. |
| cors | "Allowed origins?" | List | `STORE_CORS`, `ADMIN_CORS`, `AUTH_CORS`. Storefront URL + admin URL. Required for production. |
| admin | "Initial admin email + password?" | Free-text (sensitive) | Created via CLI prompt on first run. |
| dns | "Backend public URL?" | Free-text, e.g. `https://api.mystore.com` | For production + CORS config. |

## Install — `create-medusa-app` (recommended, dev-friendly)

Prereqs:

- Node.js 20 LTS+ (and ≤ v24 if installing with storefront)
- Git CLI
- Postgres running locally or reachable

```bash
# Using npm (simplest)
npx create-medusa-app@latest my-medusa-store

# Or pnpm (faster, recommended)
pnpm dlx create-medusa-app@latest my-medusa-store

# Or yarn
yarn dlx create-medusa-app@latest my-medusa-store
```

The CLI will:

1. Ask whether to install the Next.js Starter Storefront.
2. Ask for Postgres DB URL (or offer to create one locally if Postgres is available).
3. Generate a monorepo at `my-medusa-store/` with:
   - `apps/backend/` — the Medusa app + admin dashboard
   - `apps/storefront/` — Next.js Starter (if selected)
4. Run initial migrations, create the first admin user.
5. Open `http://localhost:9000/app` in your browser.

### Dev loop

```bash
cd my-medusa-store/apps/backend
npm run dev
# Backend + admin: http://localhost:9000
# Admin UI:        http://localhost:9000/app
```

For the storefront:

```bash
cd my-medusa-store/apps/storefront
npm run dev
# Storefront: http://localhost:8000
```

## Install — Docker (`dtc-starter`)

If you don't want Node on the host:

```bash
git clone https://github.com/medusajs/dtc-starter.git --depth=1 my-medusa-store
cd my-medusa-store

# See docs/learn/installation/docker for the full setup:
# https://docs.medusajs.com/learn/installation/docker
# It walks through the Dockerfile + docker-compose.yml provided in the starter.

docker compose up -d
```

The starter ships a `docker-compose.yml` that runs Postgres + Redis + the Medusa backend in containers. Inspect it before running — adjust image versions + env vars.

## Production deployment

Upstream's production guides: <https://docs.medusajs.com/learn/deployment>.

Minimum production topology:

- **Backend container** running `apps/backend` in `workerMode: "server"` (default) — serves API + admin.
- **Worker container** running the same image with `workerMode: "worker"` — handles background jobs (subscribers, scheduled tasks). Optional but recommended at scale.
- **Postgres** — managed (RDS / Cloud SQL / Neon) strongly recommended.
- **Redis** — managed (ElastiCache / Upstash).
- **Reverse proxy** with TLS (Nginx / Caddy / your PaaS's router).
- **Storefront** deployed separately (Vercel / Netlify / self-hosted Next.js).

### Key env vars

| Var | Purpose |
|---|---|
| `DATABASE_URL` | Postgres connection string |
| `REDIS_URL` | Redis connection string (required for prod) |
| `JWT_SECRET` | JWT signing secret |
| `COOKIE_SECRET` | Session cookie signing secret |
| `STORE_CORS` | Comma-separated storefront origins |
| `ADMIN_CORS` | Comma-separated admin origins (usually same host) |
| `AUTH_CORS` | Comma-separated auth-flow origins |
| `MEDUSA_ADMIN_ONBOARDING_TYPE` | `default` / `nextjs` (tweaks onboarding wizard) |
| `NODE_ENV` | `production` |
| `MEDUSA_WORKER_MODE` | `server` / `worker` / `shared` |

Each module (payment, notifications, file storage, etc.) has its own env vars — see the module's docs.

## Storefront options

Medusa is storefront-agnostic. Choose one:

- **Next.js Starter Storefront** (`medusajs/nextjs-starter-medusa`) — official, full-featured, reference implementation.
- **Custom Next.js / Remix / Nuxt / SvelteKit / React Native** — use `@medusajs/js-sdk` to hit the Store API.
- **Shopify Hydrogen-style** — community storefronts exist.
- **Mobile** — use the JS SDK in React Native, or hit the REST API directly.

## Data layout

Everything lives in Postgres. Backups = `pg_dump` the Medusa DB + back up your file storage bucket (if you're using local disk, back up that too; production typically uses S3/GCS/etc. for uploads).

Module-specific tables:

- `product`, `variant`, `option`, `image`
- `order`, `line_item`, `payment_collection`, `fulfillment`
- `customer`, `address`
- `cart`, `reservation`, `inventory_item`
- `region`, `currency`, `country`, `tax_rate`
- `promotion`, `campaign`
- `sales_channel`, `stock_location`
- `api_key`, `user` (admin users)

Each module owns its tables; run `npx medusa db:migrate` after any custom module changes.

## Upgrade procedure

```bash
cd apps/backend
# 1. Check the Medusa release notes for breaking changes
# https://github.com/medusajs/medusa/releases

# 2. Bump versions
npm install @medusajs/medusa@latest @medusajs/admin-sdk@latest @medusajs/framework@latest
# (or pnpm / yarn equivalent)

# 3. Apply any new migrations
npx medusa db:migrate

# 4. Restart
npm run build
npm run start
```

**Major versions** (e.g. `v1.x` → `v2.x`) have had breaking changes. Read the migration guide in release notes.

## Gotchas

- **The core project's README is intentionally minimal** and points at the docs + Cloud. Don't try to self-host from just the GitHub README — use <https://docs.medusajs.com/learn/installation>.
- **Upstream pushes Medusa Cloud** for production. Self-host is supported but not first-class in marketing. If you have a small team and don't want to run Postgres + Redis + Node yourself, Cloud is the path of least resistance.
- **Next.js Starter Storefront doesn't support Node v25+** (as of recipe write time). If you pick "install storefront" during `create-medusa-app`, downgrade to Node v24 first, or skip the storefront and use a different framework.
- **Single port (`:9000`) serves BOTH the API AND the admin UI.** Admin is at `/app`. If you reverse-proxy only specific paths, make sure `/app/*` + `/admin/*` + `/store/*` + `/auth/*` all route correctly.
- **CORS is strict and mandatory in production.** Missing `STORE_CORS` / `ADMIN_CORS` = storefront can't call API = blank/error screens. Set these explicitly to your real origin URLs, not `*` wildcards.
- **`workerMode`** — in small deploys, use `shared` (one process handles web + jobs). At scale, split into dedicated `server` and `worker` containers sharing DB + Redis. Misconfigured worker mode = scheduled jobs silently don't run.
- **Admin bundle is built at build time.** Setting `ADMIN_CORS` / `BACKEND_URL` at runtime in some configs doesn't affect the already-baked admin bundle. For production, set env vars BEFORE `npm run build`. Upstream has been shipping improvements here; check release notes.
- **Modules are opt-in + stateful.** Adding a module (e.g. `@medusajs/payment-stripe`) adds DB tables. Removing one = dead tables + potential migration errors. Plan module adoption carefully.
- **Admin + backend on same origin** by default — if you want to host admin separately (at `admin.example.com` pointing at `api.example.com`), you need to configure the admin SDK's backend URL. Non-trivial; see the admin-sdk docs.
- **File uploads go to local disk by default.** In production use the S3/GCS/Azure module (`@medusajs/file-s3`, etc.) to avoid losing images on container restart.
- **Email notifications are a separate module.** No email = no order-confirmation emails. Configure SendGrid / Resend / SMTP via a notification provider module.
- **Breaking changes between minor versions happen.** Medusa v2 is still evolving. Pin exact versions in `package.json`, upgrade deliberately, read release notes every time.
- **Payments require per-gateway setup.** Stripe, PayPal, etc. each need their own module with API keys + webhook routes. The "payment" module alone is just the abstraction layer.
- **Admin user creation** is via CLI or seed script. No web-based self-signup for admins by default (that's a feature, not a bug). First admin user is prompted during `create-medusa-app`; additional admins via `npx medusa user -e email -p password`.
- **Local Postgres for dev but remote for prod** — be careful not to commit `.env.development` with production DB creds. Use `.env.local` / `.env.production.local`.
- **Event bus is in-memory by default.** In prod, switch to the Redis event bus module for durability. In-memory = jobs lost on restart.

## Links

- Upstream repo: <https://github.com/medusajs/medusa>
- Docs: <https://docs.medusajs.com>
- Installation (Node): <https://docs.medusajs.com/learn/installation>
- Installation (Docker): <https://docs.medusajs.com/learn/installation/docker>
- Deployment guides: <https://docs.medusajs.com/learn/deployment>
- DTC starter repo: <https://github.com/medusajs/dtc-starter>
- Next.js Starter Storefront: <https://github.com/medusajs/nextjs-starter-medusa>
- Commerce modules: <https://docs.medusajs.com/resources/commerce-modules>
- Architecture overview: <https://docs.medusajs.com/learn/advanced-development/architecture/overview>
- Releases: <https://github.com/medusajs/medusa/releases>
- Medusa Cloud: <https://cloud.medusajs.com>
- Discord (14k+ members): <https://discord.gg/medusajs>
- Integrations: <https://medusajs.com/integrations/>
