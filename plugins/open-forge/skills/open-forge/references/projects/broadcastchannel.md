---
name: BroadcastChannel
description: "Turn a Telegram Channel into a MicroBlog. Zero-JS-on-client; SEO-friendly; RSS + RSS JSON; sitemap.xml. Astro (formerly Next.js). Cloudflare Pages / Vercel / Netlify / Docker deploy. miantiao-me."
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
- **Cloudflare Pages / Vercel / Netlify / Docker-ready**

- Upstream repo: <https://github.com/miantiao-me/BroadcastChannel>

## Architecture in one minute

- **Astro** SSG (migrated from Next.js)
- **Fetches TG channel via web-scraping** of t.me public URL
- **Deploys as static site** to CF Pages / Vercel / Netlify, or as Docker container (port 4321)
- **Zero-runtime** (static serverless); Docker option for VPS self-hosting
- **Resource**: tiny at runtime; build happens on deploy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **CF Pages / Vercel / Netlify** | **Fork + deploy (select Astro framework)** | **Primary — set CHANNEL env var**                                         |
| **Docker**         | `ghcr.io/miantiao-me/broadcastchannel:main`                   | VPS self-hosting; port 4321                                                    |
| **Self-hosted nginx**| Build + serve static output                                  | Alt                                                                            |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| TG channel name      | `miantiao_me` (no `@`, just the username)                   | Required     | Must be public — set as `CHANNEL` env var                                |
| Domain               | `memo.example.com`                                          | URL          |                                                                          |
| Rebuild trigger      | How often to rebuild                                        | Config       | Webhook on new TG post                                                   |

## Install via Docker

```sh
docker pull ghcr.io/miantiao-me/broadcastchannel:main
docker run -d --name broadcastchannel -p 4321:4321 \
  -e CHANNEL=your_channel_name \
  ghcr.io/miantiao-me/broadcastchannel:main
```

Visit `http://localhost:4321`. Key env vars:

```env
CHANNEL=miantiao_me          # Telegram channel username (required)
LOCALE=en                    # Language (default: en)
TIMEZONE=America/New_York    # Timezone for post timestamps
```

## Install via Cloudflare Pages / Vercel / Netlify (Astro)

1. Fork <https://github.com/miantiao-me/BroadcastChannel>
2. Connect to CF Pages / Vercel / Netlify -> Select fork
3. Select **Astro** as the framework
4. Set env var `CHANNEL` with your Telegram channel username (e.g. `miantiao_me`)
5. Deploy
6. Bind custom domain

## First boot

1. Fork + configure env (set `CHANNEL`)
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
2. Pull upstream -> redeploy (or `docker pull` + restart for Docker deploys)

## Gotchas

- **FULLY-STATIC / Tier 4/ZERO**:
  - No server credentials
  - No database
  - Pulls from public TG channel
- **PUBLIC-TG-CHANNEL-ONLY**:
  - Scrapes t.me public interface
  - Private channels NOT supported
- **TG-SCRAPE-MAY-BREAK**:
  - Depends on Telegram public web-view format
  - If TG changes format, BroadcastChannel breaks
- **CONTENT-OWNED-BY-THIRD-PARTY (Telegram)**:
  - If channel is banned = site empty
- **FRAMEWORK MIGRATED TO ASTRO**: recipe previously noted Next.js; upstream migrated to Astro. Docker image available at `ghcr.io/miantiao-me/broadcastchannel:main`, port 4321.
- **CLOUDFLARE-PAGES-PREFERRED**: Author default; but Docker and Vercel/Netlify also officially supported.
- **PROJECT HEALTH**: active + many-real-deployments + bilingual + CF-deploy + Docker. Strong.

## Links

- Repo: <https://github.com/miantiao-me/BroadcastChannel>
- Memos (alt standalone): <https://github.com/usememos/memos>
