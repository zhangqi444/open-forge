---
name: world-monitor-project
description: World Monitor recipe for open-forge. AGPL-3.0 real-time global intelligence dashboard — 500+ news feeds, dual map engine, cross-stream correlation, native Tauri desktop app for macOS/Windows/Linux. The codebase is primarily a Next.js / TypeScript web app + Tauri native wrapper — self-hosting means either (a) running the dev server (`npm run dev`), (b) building the production Next.js output and serving it (Vercel / Docker / static CDN), or (c) distributing the Tauri native binary to end users. Not a traditional backend service. Local AI via Ollama (optional; no API keys required).
---

# World Monitor

AGPL-3.0 real-time global intelligence dashboard — AI-powered news aggregation, geopolitical monitoring, infrastructure tracking. Upstream: <https://github.com/koala73/worldmonitor>. Docs: <https://www.worldmonitor.app/docs/documentation>. Self-hosting guide: <https://www.worldmonitor.app/docs/getting-started>.

## What it actually is

World Monitor is **not a typical self-hosted server with a database and a backend API**. It's a **Next.js (TypeScript) web app + Tauri 2 native wrapper**. The "backend" is a set of scheduled data fetchers that pull from 500+ RSS/news/market feeds and synthesize with an LLM (OpenAI API, or local Ollama). The synthesized output is served as static + server-rendered pages.

Self-host means one of:

| Intent | What you run |
|---|---|
| "Run the web app on a VPS for my team" | `npm run build && npm start` → front with Caddy/nginx. The Node server serves SSR pages + schedules data-fetchers. |
| "Run it as a Vercel/Netlify deploy" | Connect the repo to Vercel; zero-config Next.js deploy. |
| "Use it as a personal desktop app" | Download the Tauri native `.exe` / `.dmg` / `.AppImage` from upstream releases. No self-host needed. |
| "Run it purely statically" | Supported for a subset of features (no SSR-only data) via `next export` + any CDN / S3 + CloudFront. |

This recipe covers (a) and touches on (b) and (d).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Local dev (`npm run dev`) | `README.md` §Quick Start | ✅ | Hack on it / poke around. |
| Production Node server (`npm run build && npm start`) | Next.js standard | ✅ | Self-host on your own VM. |
| Vercel | <https://www.worldmonitor.app/docs/getting-started> | ✅ | Easiest deploy. |
| Docker | <https://www.worldmonitor.app/docs/getting-started> | ✅ | Containerized self-host (upstream provides a Dockerfile; check repo). |
| Static export (`next build && next export`) | Next.js standard | ✅ | CDN / S3. Some features needing SSR won't work. |
| Native desktop (Tauri) | <https://github.com/koala73/worldmonitor/releases> | ✅ | Personal use — no server needed. Prebuilt `.exe`/`.dmg`/`.AppImage`. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Deployment target?" | `AskUserQuestion`: `Node server (VPS)` / `Vercel` / `Docker` / `Static CDN` / `Native desktop` | Drives section. |
| variant | "Which site variant?" | `AskUserQuestion`: `world` (default) / `tech` / `finance` / `commodity` / `happy` | Upstream ships 5 variants from one codebase — each has its own `npm run dev:<variant>` / `build:<variant>` command. |
| runtime | "Node version?" | Free-text, default `20 LTS` | Next.js 15 requires Node ≥ 18.18. Use Node 20 LTS. |
| ai | "LLM backend? (local Ollama / OpenAI API / skip)" | `AskUserQuestion` | Optional. Without one, feature-parity with the hosted site is limited; aggregation still works. |
| ai | "Ollama host URL?" | Free-text, default `http://localhost:11434` | If local Ollama selected. |
| ai | "OpenAI API key?" | Free-text (sensitive) | If OpenAI selected. Placed in `.env.local`. |
| dns | "Public domain?" | Free-text | Any public-facing deploy. |
| tls | "Reverse proxy / platform TLS?" | `AskUserQuestion` | Node-server deploys need Caddy/nginx/Traefik for HTTPS; Vercel/Netlify handle it automatically. |

## Install — Local dev (Quick Start from README)

```bash
git clone https://github.com/koala73/worldmonitor.git
cd worldmonitor
npm install
npm run dev
# → http://localhost:5173
```

For a variant:

```bash
npm run dev:tech        # tech.worldmonitor.app
npm run dev:finance     # finance.worldmonitor.app
npm run dev:commodity   # commodity.worldmonitor.app
npm run dev:happy       # happy.worldmonitor.app
```

## Install — Production Node server

```bash
# 1. On the VPS — install Node 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Clone + build
git clone https://github.com/koala73/worldmonitor.git /opt/worldmonitor
cd /opt/worldmonitor
npm ci
npm run build             # or build:tech, build:finance, etc.

# 3. Env config — create .env.local
cat > .env.local <<'EOF'
# Pick one AI backend (both optional)
OLLAMA_HOST=http://localhost:11434
# OPENAI_API_KEY=sk-...
NEXT_PUBLIC_SITE_URL=https://worldmonitor.example.com
EOF

# 4. Start
npm start                 # or npm run start:tech, etc.
# Listens on PORT (default 3000 for Next.js)
```

### Systemd unit

```ini
# /etc/systemd/system/worldmonitor.service
[Unit]
Description=World Monitor
After=network.target

[Service]
Type=simple
User=worldmonitor
Group=worldmonitor
WorkingDirectory=/opt/worldmonitor
Environment="NODE_ENV=production"
Environment="PORT=3000"
EnvironmentFile=/opt/worldmonitor/.env.local
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
sudo useradd --system --home /opt/worldmonitor --shell /usr/sbin/nologin worldmonitor
sudo chown -R worldmonitor:worldmonitor /opt/worldmonitor
sudo systemctl daemon-reload
sudo systemctl enable --now worldmonitor
```

### Reverse proxy (Caddy)

```caddy
worldmonitor.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

## Install — Vercel

Fork the repo on GitHub, sign into <https://vercel.com>, "New Project" → import the fork. Vercel auto-detects Next.js, builds and deploys. Set environment variables in the Vercel dashboard (the same keys as in `.env.local`). First deploy takes ~2-3 minutes.

## Install — Docker

```bash
cd /opt/worldmonitor
# Upstream ships a Dockerfile in the repo
docker build -t worldmonitor .
docker run -d --name worldmonitor \
  --restart unless-stopped \
  -p 3000:3000 \
  --env-file .env.local \
  worldmonitor
```

Verify the Dockerfile exists in the current repo clone — upstream may restructure. The README's self-hosting guide at <https://www.worldmonitor.app/docs/getting-started> is the authoritative source for container specifics.

## Install — Native desktop (no server)

For personal single-user use, just grab the prebuilt Tauri binary:

| Platform | Download |
|---|---|
| Windows | <https://worldmonitor.app/api/download?platform=windows-exe> |
| macOS (Apple Silicon) | <https://worldmonitor.app/api/download?platform=macos-arm64> |
| macOS (Intel) | <https://worldmonitor.app/api/download?platform=macos-x64> |
| Linux | <https://worldmonitor.app/api/download?platform=linux-appimage> |

The desktop app bundles the same web UI + runs the data fetchers locally. No deploy needed. Configure OpenAI / Ollama via the app's Settings.

## Local AI via Ollama (optional, no API keys)

World Monitor's AI synthesis features (brief generation, tagging, correlation) can use a local Ollama instance instead of OpenAI. Quick setup:

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.1:8b     # or any compatible model
ollama serve                  # systemd unit installed automatically on Linux
```

Then set `OLLAMA_HOST=http://localhost:11434` in `.env.local` and leave `OPENAI_API_KEY` empty. Upstream docs at <https://www.worldmonitor.app/docs/ai-configuration> cover model recommendations.

## Variants

One codebase, 5 variants, selected via build/dev scripts:

| Variant | Demo | Focus |
|---|---|---|
| `world` (default) | <https://worldmonitor.app> | General geopolitics + news |
| `tech` | <https://tech.worldmonitor.app> | Technology + AI + cybersecurity |
| `finance` | <https://finance.worldmonitor.app> | 92 stock exchanges, commodities, crypto |
| `commodity` | <https://commodity.worldmonitor.app> | Commodities-only |
| `happy` | <https://happy.worldmonitor.app> | Positive-news curation |

To self-host a specific variant, use `npm run build:<variant>` and `npm run start:<variant>`. The variant baked in at build time — separate deployments for different variants.

## Data layout

Unlike a DB-backed app, World Monitor caches fetched data in-process and on-disk (`.next/cache/` + any Redis/Ollama you configure). There's no Postgres/MySQL to back up. For a Node-server deploy:

| Path | Content |
|---|---|
| `.next/cache/` | Next.js build + fetch cache. Transient. |
| `.env.local` | API keys + config. Back this up. |
| `public/` | Static assets from the repo. Replaced on every deploy. |

To survive host loss, the only thing unique is `.env.local` — everything else is `git clone`-able.

## Upgrade procedure

```bash
cd /opt/worldmonitor
git pull origin main
npm ci
npm run build
sudo systemctl restart worldmonitor
```

For Docker:

```bash
cd /opt/worldmonitor
git pull origin main
docker build -t worldmonitor .
docker rm -f worldmonitor
docker run -d --name worldmonitor --restart unless-stopped \
  -p 3000:3000 --env-file .env.local worldmonitor
```

Releases: <https://github.com/koala73/worldmonitor/releases>. Check the changelog for breaking env-var renames or migration steps before upgrading.

## Gotchas

- **Not a traditional server.** No DB, no long-running queue workers. The Next.js process pulls feeds on a schedule inside the same process. "Self-host" means "run Next.js."
- **AGPL-3.0 license.** If you modify World Monitor and offer it as a network service, you must publish your changes. Fine for personal use; read the license if you're embedding it in a SaaS.
- **21 languages + RTL support.** Internationalization is baked in; variant build scripts don't change language selection.
- **Ollama is optional but changes capabilities.** Without a local model OR OpenAI key, the AI-synthesis features degrade to pass-through (raw feeds show, no summarization / correlation).
- **500+ RSS feeds = bandwidth.** The aggregator polls many sources. On a tiny VPS with metered bandwidth, this adds up. Rate-limit config may be needed (see upstream docs).
- **Map engines need WebGL.** Older browsers / headless environments fail to render the 3D globe + flat map. Server-side rendering paths exist but the interactive map requires a modern browser.
- **Multi-variant builds share the same output dir.** Build one variant, deploy it, build another → the first output is overwritten. Use separate build directories or separate deployments per variant.
- **Secrets in `.env.local` live outside git.** `.env.local` is in `.gitignore`. Back it up in a secret manager — losing it means reconfiguring all API keys.
- **Tauri native app auto-updates via upstream CDN.** If you distribute the native build, you're trusting upstream's update channel. Fork + self-distribute if you need air-gap.
- **Rate limits on external APIs.** News APIs, OpenAI, market data feeds — all have rate limits. Upstream docs detail which providers support free tiers and which require paid keys.
- **Not all variants have equal feature depth.** `finance` is the most feature-rich; `happy` is the simplest. Check the docs for which features each variant enables.

## Links

- Upstream repo: <https://github.com/koala73/worldmonitor>
- Website: <https://worldmonitor.app>
- Docs: <https://www.worldmonitor.app/docs/documentation>
- Getting started (self-hosting): <https://www.worldmonitor.app/docs/getting-started>
- AI configuration: <https://www.worldmonitor.app/docs/ai-configuration>
- Contributing: <https://www.worldmonitor.app/docs/contributing>
- Releases: <https://github.com/koala73/worldmonitor/releases>
- Discord: <https://discord.gg/re63kWKxaz>
