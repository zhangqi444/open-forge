---
name: BroadcastChannel
description: "Turn a Telegram Channel into a MicroBlog. Zero-JS-on-client; SEO-friendly; RSS + RSS JSON; sitemap.xml. Next.js. Cloudflare Pages deploy. miantiao-me."
---

# BroadcastChannel

BroadcastChannel is **"turn your Telegram channel into a public micro-blog"** — a static site generator that renders a Telegram channel as a web micro-blog. **Zero JS on the browser side**. SEO-friendly sitemap. RSS + RSS-JSON feeds. Widely deployed on Cloudflare Pages.

Built + maintained by **miantiao-me**. Long list of real-user deployments in README (>20 production users shown). Likely MIT. Active.

Use cases: (a) **mirror TG channel to web-blog** (b) **accessible version of your TG posts** (c) **RSS of a TG channel** (d) **SEO for content** you post on TG (e) **provide web-URL for TG posts** (f) **TG = publishing tool; BC = web presence** (g) **archive TG posts via SSG deploy** (h) **link-shareable TG content**.

Features (per README):

- **Turn TG Channel → MicroBlog**
- **SEO-friendly** sitemap
- **0 JS on the client**
- **RSS + RSS-JSON feeds**
- **Multi-language** (at least EN/zh-CN)
- **Cloudflare Pages / Vercel-ready**

- Upstream repo: <https://github.com/miantiao-me/BroadcastChannel>

## Architecture in one minute

- **Next.js** SSG
- **Fetches TG channel via web-scraping** of t.me public URL
- **Deploys as static site** to CF Pages / Vercel / Netlify
- **Zero-runtime** (static)
- **Resource**: tiny at runtime; build happens on deploy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **CF Pages**       | **Deploy from repo**                                            | **Primary**                                                                        |
| **Vercel / Netlify**| Static deploy                                                                                                         | Alt                                                                                   |
| **Self-hosted nginx**| Build + serve                                                                                                        | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| TG channel name      | `@example_channel` — **public channel only**                | Required     | Must be public                                                                                    |
| Domain               | `memo.example.com`                                          | URL          |                                                                                    |
| Rebuild trigger      | How often to rebuild                                        | Config       | Webhook on new TG post                                                                                    |

## Install via Cloudflare Pages

1. Fork <https://github.com/miantiao-me/BroadcastChannel>
2. CF Pages → Connect GitHub → Select fork
3. Build command: `npm run build`
4. Set env vars (CHANNEL name, etc.)
5. Deploy
6. Bind custom domain

## First boot

1. Fork + configure env
2. Deploy
3. Verify site renders posts
4. Subscribe to /rss.xml in reader
5. Submit sitemap to search engines
6. Configure rebuild cadence (cron rebuild or webhook)

## Data & config layout

- **Static site** — no server data
- Generated at build-time from scraping

## Backup

The canonical source is the Telegram channel itself. The site is just a render.

## Upgrade

1. Releases: <https://github.com/miantiao-me/BroadcastChannel/releases>
2. Pull upstream → redeploy

## Gotchas

- **151st HUB-OF-CREDENTIALS Tier 4/ZERO — FULLY-STATIC**:
  - No server credentials
  - No database
  - Pulls from public TG channel
  - **151st tool in hub-of-credentials family — Tier 4/ZERO**
  - **Zero-credential-hub-tool Tier 4/ZERO: 5 tools** (MAZANOKE+Chitchatter+Logdy+Mini QR+BroadcastChannel) 🎯 **5-TOOL MILESTONE**
  - **Stateless-tool-rarity: 15 tools** (+BroadcastChannel) 🎯 **15-TOOL MILESTONE**
- **PUBLIC-TG-CHANNEL-ONLY**:
  - Scrapes t.me public interface
  - Private channels NOT supported
  - **Recipe convention: "public-source-scrape-only callout"**
  - **NEW recipe convention** (BroadcastChannel 1st formally)
- **TG-SCRAPE-MAY-BREAK**:
  - Depends on Telegram's public web-view
  - If TG changes format, BroadcastChannel breaks
  - **Recipe convention: "upstream-scrape-fragility callout"**
  - **NEW recipe convention** (BroadcastChannel 1st formally)
- **CONTENT-OWNED-BY-THIRD-PARTY (Telegram)**:
  - You're dependent on Telegram keeping channel available
  - If channel banned = site empty
  - **Recipe convention: "third-party-content-owner-dependency callout"**
  - **NEW recipe convention** (BroadcastChannel 1st formally)
- **ZERO-JS-ON-CLIENT = ACCESSIBILITY**:
  - No-JS browsers + older devices work
  - **Recipe convention: "zero-JS-client-progressive-enhancement positive-signal"**
  - **NEW positive-signal convention** (BroadcastChannel 1st formally)
- **RSS + RSS-JSON DUAL-FEEDS**:
  - Both formats
  - **Recipe convention: "RSS-plus-RSS-JSON-feeds positive-signal"**
  - **NEW positive-signal convention** (BroadcastChannel 1st formally)
- **20+ REAL-USER-DEPLOYMENTS SHOWN**:
  - README-listed production sites
  - Social-proof
  - **Recipe convention: "README-documented-real-user-deployments positive-signal"**
  - **NEW positive-signal convention** (BroadcastChannel 1st formally)
- **MULTI-LANGUAGE README (EN+zh-CN)**:
  - Internationalized project-README
  - **Recipe convention: "multi-language-project-README positive-signal"**
  - **NEW positive-signal convention** (BroadcastChannel 1st formally)
- **CLOUDFLARE-PAGES-PREFERRED**:
  - Author's default; optimized for CF Pages
  - **Recipe convention: "Cloudflare-Pages-optimized-deploy neutral-signal"**
  - **NEW neutral-signal convention** (BroadcastChannel 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: miantiao-me + many-real-users + bilingual-README + CF Pages-default. **137th tool — solo-SSG-with-ecosystem-adoption sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + real-user-showcase + bilingual + CF-deploy-documented. **143rd tool in transparent-maintenance family.**
- **TG-TO-WEB-CATEGORY (niche):**
  - **BroadcastChannel** — micro-blog with RSS
  - **tgPosts** (community various) — similar patterns
  - **Memos** (different — a micro-blog tool, not TG-to-web)
  - **IFTTT / Zapier** — automation to blog
- **ALTERNATIVES WORTH KNOWING:**
  - **Memos** — if you want standalone micro-blog (no TG)
  - **Mastodon** — if you want decentralized micro-blog
  - **Choose BroadcastChannel if:** your content lives on TG and you want SEO-web presence.
- **PROJECT HEALTH**: active + many-real-deployments + bilingual + CF-deploy. Strong.

## Links

- Repo: <https://github.com/miantiao-me/BroadcastChannel>
- Memos (alt standalone): <https://github.com/usememos/memos>
