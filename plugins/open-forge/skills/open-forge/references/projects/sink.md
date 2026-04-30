---
name: Sink
description: "Simple, fast, privacy-focused URL shortener with analytics — 100% runs on Cloudflare (Workers + KV + Analytics Engine). AI slug generation, link expiration, device routing, OpenGraph preview, QR code, real-time 3D globe analytics. Nuxt + shadcn/ui. MIT."
---

# Sink

Sink is **a URL shortener that runs entirely on Cloudflare's free tier** — no VM, no server, no database of your own. Cloudflare Workers runs the code, Workers KV stores the links, Analytics Engine collects the click data. Push via Wrangler; Cloudflare does the rest.

Perfect for individuals / small teams who want a **private link shortener for their own domain** (`s.yourdomain.com`, `go.yourdomain.com`) without running infrastructure. Bitly-for-you, on Cloudflare's free plan.

Features:

- **URL shortening** with compact slugs
- **Analytics dashboard** — clicks, geolocation, referrer, device, over-time
- **Real-time 3D globe** visualization of clicks
- **AI Slug** — LLM generates memorable slug from URL/title
- **Customizable slug** — pick your own
- **Case-sensitive slugs** — optional
- **Link expiration** — auto-disable after date
- **Device routing** — iOS users → App Store, Android users → Play Store, desktop → web
- **OpenGraph preview** — custom social media card per link (title, description, image)
- **QR code generation** — every link gets a printable QR
- **Real-time events log** — see clicks as they happen
- **Import/export** — bulk JSON/CSV
- **i18n** — multi-language dashboard
- **Dark/light theme**
- **100% serverless** — Cloudflare Workers only

- Upstream repo: <https://github.com/miantiao-me/Sink>
- Website / demo: <https://sink.cool/dashboard> (demo token: `SinkCool`)
- Deployment docs (Workers): <https://github.com/miantiao-me/Sink/blob/main/docs/deployment/workers.md>
- Deployment docs (Pages): <https://github.com/miantiao-me/Sink/blob/main/docs/deployment/pages.md>
- Configuration docs: <https://github.com/miantiao-me/Sink/blob/main/docs/configuration.md>
- API docs: <https://github.com/miantiao-me/Sink/blob/main/docs/api.md>

## Architecture in one minute

- **Framework**: Nuxt (Vue 3) SSR/serverless
- **Storage**: **Cloudflare Workers KV** (eventually-consistent key-value)
- **Analytics**: **Cloudflare Workers Analytics Engine** (time-series event storage)
- **UI**: shadcn-vue + Tailwind CSS
- **Deployment target**: **Cloudflare Workers** (recommended) or **Cloudflare Pages**
- **No traditional backend, no DB** — Cloudflare's serverless primitives are the backend

## Compatible install methods

| Infra              | Runtime                                                   | Notes                                                                      |
| ------------------ | --------------------------------------------------------- | -------------------------------------------------------------------------- |
| Cloudflare         | **Workers + KV + Analytics Engine**                           | **The ONLY supported platform — Sink is Cloudflare-native**                        |
| Cloudflare Pages   | Also supported                                                       | Similar tradeoffs to Workers                                                              |
| Self-hosted VM     | ❌ Not supported — depends on Cloudflare-specific APIs                            |                                                                                         |
| Other serverless (Vercel, AWS Lambda) | ❌ — APIs used are Cloudflare-only                                           |                                                                                                   |

## Inputs to collect

| Input                | Example                             | Phase      | Notes                                                                    |
| -------------------- | ----------------------------------- | ---------- | ------------------------------------------------------------------------ |
| Cloudflare account   | free tier works                         | Platform   | Sign up at cloudflare.com                                                                 |
| Domain               | `s.yourdomain.com`                        | DNS        | Must be on Cloudflare DNS (zone)                                                                    |
| KV namespace         | created via Wrangler                                 | Storage    | For links                                                                                                    |
| Analytics dataset    | created via Wrangler                                      | Analytics  | For click events                                                                                                             |
| Site token           | random string                                                   | Auth       | Dashboard login — **this IS your admin password**                                                                                          |
| AI (opt)             | Cloudflare AI or OpenAI API key                                          | Feature    | For AI-generated slugs                                                                                                                              |

## Install / deploy via Wrangler

```sh
# Prereqs: Node.js + pnpm + Cloudflare Wrangler + Cloudflare account
npm install -g wrangler
wrangler login

# Clone Sink
git clone https://github.com/miantiao-me/Sink.git
cd Sink
pnpm install

# Create KV namespace
wrangler kv:namespace create "LINKS"
# Copy the ID into wrangler.toml under [[kv_namespaces]]

# Edit wrangler.toml:
#   name = "sink"
#   [vars]
#   NUXT_SITE_TOKEN = "your-strong-random-token"
#   NUXT_CF_ACCOUNT_ID = "<your cf account id>"
#   NUXT_CF_API_TOKEN = "<token with analytics perms>"

# Deploy
pnpm run deploy
```

Bind your custom domain (`s.yourdomain.com`) in Cloudflare dashboard → Workers → Custom domains.

## Alternative: Cloudflare Pages

One-click-ish via Cloudflare Pages → Connect Git → point at the repo → set env vars. Less flexible than Workers for some features (KV binding path differs).

## First boot

1. Visit `https://s.yourdomain.com/dashboard`
2. Enter your **Site Token** (from `wrangler.toml`)
3. Dashboard loads — empty state
4. + New Link → paste long URL → pick slug (or AI) → create
5. Copy short URL → test redirect
6. Analytics tab → see clicks populate
7. Install Chrome / Raycast / iOS Shortcut for faster shortening

## Data & config layout

- **Links**: Cloudflare KV namespace
- **Analytics**: Cloudflare Analytics Engine dataset
- **Config**: `wrangler.toml` + Cloudflare env vars
- **No local storage** on your side

## Backup

- **Export from dashboard** — JSON export of all links (+ metadata)
- **Cloudflare KV** has no native backup — export regularly (schedule via cron: `curl -H "Authorization: Bearer $TOKEN" https://s.yourdomain.com/api/links/export > backup-$(date +%F).json`)
- Analytics data — Cloudflare retains per tier; export via API if long-term retention needed

## Upgrade

1. Releases: <https://github.com/miantiao-me/Sink/releases>. Active.
2. `git pull` → `pnpm install` → `pnpm run deploy` — Cloudflare updates the Worker.
3. Watch release notes for `wrangler.toml` schema changes (new bindings).

## Gotchas

- **Cloudflare lock-in.** Sink literally cannot run outside Cloudflare. If Cloudflare changes pricing, your Workers limits get exceeded, or you want to migrate — you have to rewrite. Weigh this against the convenience.
- **Cloudflare free tier limits** — Workers have 100k requests/day free. For a personal link shortener this is plenty; for a team / public link shortener, watch consumption. KV has 100k reads/day + 1k writes/day free; beyond that, Workers Paid plan ($5/mo).
- **Analytics Engine** is a separate product; check current pricing — it's been free-with-limits for a while.
- **Site Token = your only auth.** No per-user accounts. Anyone with the token has full admin. Rotate if it leaks (edit wrangler.toml + redeploy).
- **KV eventual consistency** — link creation takes ~seconds to propagate globally. Usually fine; edge cases exist.
- **Domain MUST be on Cloudflare DNS.** Sink binds as a Worker route on your zone. If your DNS is elsewhere, transfer it or use a subdomain CNAME'd into CF (less clean).
- **OpenGraph previews** work via the Worker intercepting requests from social media crawlers — make sure your Cloudflare rules don't bypass the Worker for `?crawl=true` style queries.
- **AI slug feature** requires either Cloudflare Workers AI binding (free models) or an OpenAI-compatible key. Adds latency + cost.
- **Custom short domain requires an Enterprise plan?** — No; Workers Custom Domains on any paid Workers plan ($5/mo) allow custom domain routing; on free, you use `*.workers.dev` subdomains.
- **Slug collision** — KV + simple uniqueness check; races unlikely but possible on simultaneous creates.
- **Deletion** — deleting a link makes the old short URL 404 immediately; consider a "deleted" state or redirect to root instead.
- **Case sensitivity** — configure per-deployment; remember this affects all existing links.
- **Privacy**: Cloudflare sees every click + origin IP. If privacy from Cloudflare is critical, Sink isn't the right tool.
- **Compared to YOURLS / Shlink / Kutt**: those run on your own VMs/VPS; you own the infra + the logs. Sink is simpler to deploy but more locked-in.
- **Mobile**: bookmark the dashboard; the iOS app + Raycast extension are better.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **YOURLS** — classic PHP URL shortener; self-host on your own VM
  - **Shlink** — PHP; more features; self-hosted (separate recipe likely)
  - **Kutt** — Node; modern UI; self-hosted
  - **Polr** — PHP; simple
  - **Bitly** (SaaS) — commercial
  - **Rebrandly / Short.io** (SaaS) — commercial with vanity domains
  - **Pangolin** (unrelated) — not a URL shortener
  - **Dub** — modern open-source URL shortener (TypeScript/Next.js); self-host + cloud (separate recipe likely)
  - **Choose Sink if:** you're already in Cloudflare ecosystem + want the simplest URL shortener with analytics + don't need to own infra.
  - **Choose Shlink/YOURLS/Kutt if:** you want self-hosted on your own VM + full data ownership.
  - **Choose Dub if:** you want the most polished modern OSS shortener that runs anywhere.
  - **Choose Bitly if:** you want commercial SaaS + don't want to manage anything.

## Links

- Repo: <https://github.com/miantiao-me/Sink>
- Live demo: <https://sink.cool/dashboard> (token: `SinkCool`)
- Deployment (Workers): <https://github.com/miantiao-me/Sink/blob/main/docs/deployment/workers.md>
- Deployment (Pages): <https://github.com/miantiao-me/Sink/blob/main/docs/deployment/pages.md>
- Configuration: <https://github.com/miantiao-me/Sink/blob/main/docs/configuration.md>
- API: <https://github.com/miantiao-me/Sink/blob/main/docs/api.md>
- Tutorial video: <https://www.youtube.com/watch?v=MkU23U2VE9E>
- Releases: <https://github.com/miantiao-me/Sink/releases>
- Chrome extension: <https://chromewebstore.google.com/detail/sink-quick-shorten/emlojomjpenjgkaphajcokijobpkejih>
- Raycast extension: <https://github.com/foru17/raycast-sink>
- iOS app: <https://apps.apple.com/app/id6745417598>
- Cloudflare Workers KV: <https://developers.cloudflare.com/kv/>
- Cloudflare Analytics Engine: <https://developers.cloudflare.com/analytics/>
- Shlink (alt): <https://shlink.io>
- YOURLS (alt): <https://yourls.org>
- Kutt (alt): <https://kutt.it>
- Dub (alt): <https://github.com/dubinc/dub>
