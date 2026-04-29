---
name: opencut-project
description: OpenCut recipe for open-forge. MIT-licensed free/OSS video editor positioned as a CapCut alternative. Monorepo with a Next.js web app (primary target), a Tauri/GPUI native desktop app (in progress), and a Rust WASM core (GPU compositor, effects, masks). The self-hostable artifact is the web app — runs in production Docker (`docker compose up -d` in the repo root) on port 3100, or dev mode with Bun + local Docker Postgres/Redis. Privacy-first model — video data stays in the browser.
---

# OpenCut

MIT-licensed "free, open-source video editor for web, desktop, and mobile" — positioned as a CapCut alternative. Upstream: <https://github.com/OpenCut-app/OpenCut>. Project landing: <https://opencut.app>.

**Project structure** (per upstream README):

- `apps/web/` — Next.js web application (the self-hostable target).
- `apps/desktop/` — Native desktop built with GPUI (in progress, Rust-side).
- `rust/` — Platform-agnostic core: GPU compositor, effects, masks, WASM bindings. Business logic is actively migrating from TypeScript → Rust.
- `docs/` — Architecture + subsystem docs.

**Self-host target = the web app.** The desktop and native bits are download-and-install artifacts, not things you host. What an open-forge deploy means here is "run the Next.js production build in Docker (port 3100) with a local Postgres + Redis sidecar."

**Privacy model:** per upstream README, "Your videos stay on your device." OpenCut is built as a client-side editor — the backend stores user accounts and project metadata, not video content. Raw frames live in the browser (IndexedDB + File System Access API).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (production) | `docker-compose.yaml` in repo root | ✅ Recommended | The self-host path. `docker compose up -d` builds + runs the Next.js prod image + Postgres + Redis + serverless-redis-http. |
| Bun dev server | <https://github.com/OpenCut-app/OpenCut#setup> | ✅ | Development only. `bun dev:web` after `docker compose up -d db redis serverless-redis-http`. |
| Native desktop (GPUI / Tauri) | `apps/desktop/README.md` | ⚠️ In progress | Not a hosted artifact — it's a user-installed app. Out of scope for open-forge's deploy model. |
| Managed web (`opencut.app` live instance) | <https://opencut.app> | ✅ (Vercel-hosted) | Use as a client if you don't want to self-host; the company runs this. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install shape? (production Docker / dev)" | `AskUserQuestion` | Drives section. |
| env | "Path to `.env.local` template?" | Free-text | Upstream ships `apps/web/.env.example` with defaults matching the Docker compose; usually just copy it. |
| db | "Use bundled Postgres container, or external?" | `AskUserQuestion` | Production deploys sometimes want a managed Postgres; OpenCut currently ships with a local Postgres in compose. |
| port | "Public port? (default `3100`)" | Integer | Docker exposes `3100` for the production build. |
| domain | "Public domain?" | Free-text | Only if exposing publicly. |
| proxy | "Reverse proxy?" | `AskUserQuestion` | Next.js does not terminate TLS. |
| auth | "OAuth providers?" | Multi-select (upstream uses `next-auth` — providers are configured via env) | Each provider needs its own client ID + secret in `.env.local`. |

## Install — Production Docker (upstream path)

From upstream's README §Self-Hosting with Docker:

```bash
# 1. Clone
git clone https://github.com/OpenCut-app/OpenCut.git
cd OpenCut

# 2. Prepare env
cp apps/web/.env.example apps/web/.env.local
# Edit apps/web/.env.local if you need to override DB URLs, auth provider IDs, etc.

# 3. Up the full stack (web + db + redis + serverless-redis-http)
docker compose up -d
docker compose logs -f web

# → App available at http://localhost:3100
```

The compose file builds the Next.js app from source into a multi-stage image on first run. Subsequent `docker compose up -d` reuses the built image.

### Compose services (from the repo's `docker-compose.yaml`)

At the time of writing, upstream ships:

- **web** — the production Next.js container, bound to host port `3100`.
- **db** — Postgres 16.
- **redis** — Redis 7 for caching + pub/sub.
- **serverless-redis-http** — HTTP shim that exposes Redis over HTTP (used by the Next.js edge runtime in regions that don't allow TCP outbound to Redis).

Verify the exact shape against the current `docker-compose.yaml` on `main`, as the project is actively developed.

### Build caveat

The first `docker compose up -d` has to BUILD the Next.js image, which pulls npm packages + runs `bun install` + `next build`. Budget 5–15 minutes depending on bandwidth + CPU. Subsequent starts are instant.

For air-gapped / reproducible deploys, pre-build the image:

```bash
docker build -t opencut-web:local -f apps/web/Dockerfile .
# Then reference `image: opencut-web:local` in compose instead of the build context.
```

## Install — Dev mode (Bun)

```bash
# Prereqs: Bun (https://bun.sh/docs/installation) + Docker
git clone https://github.com/OpenCut-app/OpenCut.git
cd OpenCut
cp apps/web/.env.example apps/web/.env.local

# Up only the infra (DB + Redis), not the web container
docker compose up -d db redis serverless-redis-http

# Install deps + start dev server
bun install
bun dev:web

# → http://localhost:3000 (dev port; differs from production's 3100)
```

## Reverse proxy (Caddy example)

```caddy
edit.example.com {
    reverse_proxy 127.0.0.1:3100

    # Large upload body limits — video uploads can be >1GB
    request_body {
        max_size 10GB
    }
}
```

For nginx, the corresponding knobs are `client_max_body_size 10G;` and high `proxy_read_timeout`.

**Note on media handling:** OpenCut's privacy model keeps video frames in the browser (File System Access API + IndexedDB). The server primarily handles account state + project metadata — not gigabyte-sized uploads. The large-body-size limits above are defensive; verify what your deployment actually uploads.

## Data layout

OpenCut stores:

| Location | Content |
|---|---|
| Postgres (bundled container) | User accounts, project metadata, auth tokens, saved project states. |
| Redis (bundled container) | Session cache, pub/sub, job queue. |
| Browser IndexedDB + File System API | Video frames, timeline state, unsaved edits. **Not server-side.** |

**Backup = Postgres `pg_dump` + Redis `BGSAVE` snapshot** while containers are up. Browser-side state is per-user and not centrally backed up (which is intentional for privacy).

## Configuration

`apps/web/.env.example` (see upstream for current contents) exposes:

| Var | Purpose |
|---|---|
| `DATABASE_URL` | Postgres connection string. Default points at the compose `db` service. |
| `REDIS_URL` | Redis connection string. |
| `NEXTAUTH_URL` | Canonical public URL (e.g. `https://edit.example.com`). Needed for OAuth redirect URLs. |
| `NEXTAUTH_SECRET` | Session signing key. Generate via `openssl rand -base64 32`. |
| `GITHUB_ID` / `GITHUB_SECRET` | GitHub OAuth. |
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth. |
| `FAL_API_KEY` | fal.ai integration (used for AI-powered effects per upstream's Sponsors section). Optional. |

## WASM-core development (out of scope for basic self-host, but flagged)

Only relevant if you're editing `rust/wasm` (the GPU compositor / effects / masks core) and want the web app to use your local build instead of the npm-published `opencut-wasm` package:

```bash
# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Build tooling
cargo install wasm-pack
cargo install cargo-watch

# Build + link
bun run build:wasm
cd rust/wasm/pkg && bun link
cd ../../../apps/web && bun link opencut-wasm

# Rebuild on changes while editing
bun dev:wasm
```

Revert with `cd apps/web && bun add opencut-wasm`.

## Upgrade procedure

```bash
cd OpenCut
git fetch origin
git checkout main
git pull

# Rebuild + restart
docker compose build
docker compose up -d
docker compose logs -f web
```

DB migrations run on boot (Drizzle ORM migrations, based on the current stack). Always `pg_dump` before upgrading.

## Gotchas

- **Actively developed / refactoring.** Upstream's CONTRIBUTING section explicitly lists "focus areas" (timeline, project management, perf) and "avoid for now" areas (preview panel enhancements, export functionality — being rewritten with a new binary rendering approach). Some features in `main` may not work end-to-end during active refactors.
- **Desktop is opt-in + in progress.** The `apps/desktop/` native app is not production-ready. Self-hosting = web app only.
- **First build is slow.** `docker compose up -d` first run does `bun install` + `next build` — expect 5–15 minutes. Budget for this on slow links / small VMs.
- **Port 3100 (prod) vs 3000 (dev).** Production Docker binds 3100; dev mode binds 3000. Don't confuse them when testing reverse proxies.
- **`.env.example` has sensible defaults that match compose.** Per upstream README: "it should work out of the box." Don't over-edit unless you're changing DB host / ports / auth.
- **No built-in auth on first boot.** Login / account creation paths depend on which OAuth providers you configure in `.env.local`. If none are set, the app boots but sign-in buttons don't do anything. Configure at least one provider (GitHub is quickest).
- **Large video uploads hit the browser, not the server.** OpenCut's File System API usage means huge upload spikes don't hit your ingress. Plan DB / Redis sizing based on user + project counts, not media volume.
- **Rust WASM package is on npm.** `opencut-wasm` is published to npm; the web app consumes it. You don't need Rust tooling to self-host — only if modifying the WASM core.
- **Export / rendering still TypeScript.** The binary rendering rewrite is on the roadmap but not merged. Heavy export jobs run in the browser; large projects may OOM tabs.
- **fal.ai integration is optional.** Several effects depend on `FAL_API_KEY`. Without it, those effects grey out — core editing still works.
- **License: MIT on OpenCut itself.** Check `LICENSE` in the repo root; individual subdependencies carry their own licenses.
- **Mobile support is named in the tagline but not ready.** Upstream says "video editor for web, desktop, and mobile" — mobile is aspirational as of 2025. Self-host assumes desktop browsers.

## Links

- Upstream repo: <https://github.com/OpenCut-app/OpenCut>
- Project site: <https://opencut.app>
- Contributing: <https://github.com/OpenCut-app/OpenCut/blob/main/.github/CONTRIBUTING.md>
- Desktop subproject: <https://github.com/OpenCut-app/OpenCut/blob/main/apps/desktop/README.md>
- Architecture docs: <https://github.com/OpenCut-app/OpenCut/tree/main/docs>
- Releases: <https://github.com/OpenCut-app/OpenCut/releases>
