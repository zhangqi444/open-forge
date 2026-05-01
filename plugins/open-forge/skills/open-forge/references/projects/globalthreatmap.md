---
name: Global Threat Map
description: "Real-time global situational awareness and OSINT platform. Next.js. unicodeveloper/globalthreatmap. Conflict mapping, intel dossiers, military bases, country conflict history. Requires Mapbox + Valyu API keys."
---

# Global Threat Map

**Real-time global situational awareness platform.** Plot security events, geopolitical developments, and threat indicators on an interactive map. Conflict mapping, country intelligence (historical + current conflicts), US/NATO military bases overlay, intel dossiers with AI-generated reports (PDF/CSV/PowerPoint export), keyword alerts, and a real-time event feed. An OSINT command center built on Next.js and Mapbox.

Built + maintained by **Prosper Otemuyiwa (unicodeveloper)** and contributors.

- Upstream repo: <https://github.com/unicodeveloper/globalthreatmap>
- Deploy on Railway: badge in repo README
- License: MIT

## Architecture in one minute

- **Next.js 16** (App Router) frontend + API routes — single unified app
- **Mapbox GL JS** for interactive mapping
- **Valyu API** — powers event search, conflict intelligence, entity deep research
- **OpenAI API** (optional) — AI-powered location extraction from event text
- Port: **3000** (Next.js dev/production server)
- **No database** — all intelligence data fetched live from Valyu API + cached at the API-route level
- **No Docker image** in upstream — deploy via Node.js or Railway/Vercel

## Compatible install methods

| Infra            | Runtime              | Notes                                                                 |
| ---------------- | -------------------- | --------------------------------------------------------------------- |
| **Node.js**      | `npm run dev` / `npm run build && npm run start` | Local or VPS; Node 18+ required |
| **Railway**      | one-click deploy     | "Deploy on Railway" button in README                                  |
| **Vercel**       | import from GitHub   | Next.js native; zero-config                                           |

## Required API keys (not optional)

| Key | Source | Notes |
|-----|--------|-------|
| `NEXT_PUBLIC_MAPBOX_TOKEN` | [mapbox.com](https://account.mapbox.com/access-tokens/) | Map rendering; free tier available |
| `VALYU_API_KEY` | [valyu.ai](https://valyu.ai) | Events, conflict intel, deep research; **billed per use** |
| `OPENAI_API_KEY` | [openai.com](https://platform.openai.com/api-keys) | Optional; improves location extraction accuracy |

> ⚠️ **This app is API-cost driven.** Valyu API charges per query. The deep research feature (50-page intelligence reports) is particularly expensive. Budget accordingly before deploying for heavy use.

## Inputs to collect

| Input                            | Example                         | Phase  | Notes                                                              |
| -------------------------------- | ------------------------------- | ------ | ------------------------------------------------------------------ |
| `NEXT_PUBLIC_MAPBOX_TOKEN`       | `pk.eyJ1...`                    | Config | Required; Mapbox public token                                      |
| `VALYU_API_KEY`                  | `vly_...`                       | Config | Required; server-side key; billed per use                          |
| `NEXT_PUBLIC_APP_MODE`           | `self-hosted`                   | Config | `self-hosted` (no auth) or `valyu` (OAuth mode)                    |
| `OPENAI_API_KEY`                 | `sk-...`                        | Config | Optional; improves location extraction                             |

## Install (Node.js / VPS)

```bash
git clone https://github.com/unicodeveloper/globalthreatmap.git
cd globalthreatmap
npm install

# Create .env.local
cat > .env.local << 'ENV'
NEXT_PUBLIC_MAPBOX_TOKEN=your_mapbox_token
VALYU_API_KEY=your_valyu_key
NEXT_PUBLIC_APP_MODE=self-hosted
# OPENAI_API_KEY=optional
ENV

# Development
npm run dev

# Production
npm run build && npm run start
```

Visit `http://localhost:3000`.

## App modes

| Mode | `NEXT_PUBLIC_APP_MODE` | Behavior |
|------|------------------------|----------|
| **Self-hosted** | `self-hosted` | No auth; all features free to all visitors; API costs billed to your Valyu account |
| **Valyu OAuth** | `valyu` | Users sign in with Valyu; feature gating; contact `contact@valyu.ai` for OAuth creds |

For private personal/team use: `self-hosted` mode with a non-public URL is simplest.

## Features overview

| Feature | Details |
|---------|---------|
| Event mapping | Real-time global events (conflicts, protests, disasters) on Mapbox dark-theme map |
| Event feed | Filterable by threat level (Critical/High/Medium/Low/Info) and category |
| Country conflicts | Click any country → current + historical conflicts with sources |
| Military bases | US (green) + NATO (blue) base markers worldwide |
| Intel dossiers | AI-generated 50-page reports on any actor (nation, militia, PMC, political figure) |
| CSV export | Structured data from dossier (locations, key figures, events, sources) |
| PowerPoint | 8-slide executive briefing generated from dossier |
| PDF | Downloadable full intel report |
| Alerts | Keyword + threat-level based notification rules |
| Auto-pan | Globe-panning playback mode |
| Heatmap | Toggle event-density heatmap layer |
| Clustering | Group nearby events at low zoom |

## Gotchas

- **Valyu API costs money.** Every map load, event search, country conflict lookup, and (especially) deep research report hits the Valyu API. Deep research reports take 5–10 minutes and likely consume significant API credits. Set a budget limit in your Valyu account before deploying publicly.
- **No database or persistent storage.** Events, conflicts, and intelligence are fetched fresh from Valyu each time. No local history, no offline mode.
- **Military base data is static.** Loaded from a hardcoded dataset in `api/military-bases/`, not a live API. May be outdated.
- **Deep research reports are cached at the API route level (1hr for military bases, ad-hoc for others).** Keep this in mind for cost — repeated identical queries within the cache window don't re-bill.
- **OpenAI key improves location extraction** from event text — without it, location extraction falls back to simpler heuristics (more events may plot incorrectly).
- **`self-hosted` mode = no authentication.** Anyone who can reach the URL can use the app and trigger API calls (at your cost). Put behind auth (Cloudflare Access, nginx basic auth, Authelia) if you're not serving internally.
- **Valyu OAuth mode requires credentials from Valyu.** Contact `contact@valyu.ai` — not a self-service setup; gated by the vendor.
- **Railway is the easiest deploy path.** The README has a "Deploy on Railway" one-click button; Railway handles Node.js hosting, env vars, and public URL automatically.
- **Wikipedia is excluded from Valyu search results.** By design in the Valyu integration. All conflict intelligence cites non-Wikipedia sources.

## Ethical / legal note

This is an OSINT tool for researchers, analysts, and security professionals. Intelligence reports generated by AI should be cross-referenced with primary sources before any consequential use. Conflict and threat data is AI-synthesized — treat as a starting point for research, not ground truth.

## Project health

Active Next.js development, Railway deploy template, Mapbox + Valyu integration. MIT license. Maintained by Prosper Otemuyiwa (unicodeveloper).

## OSINT/threat-map-family comparison

- **Global Threat Map** — Next.js, Valyu-powered, self-hostable, deep research exports
- **Bellingcat OSINT tools** — browser-based OSINT utilities; not a unified map
- **Liveuamap** — SaaS real-time conflict map; not self-hosted
- **Crisis24/AidData** — enterprise SaaS geopolitical risk; not open source

**Choose Global Threat Map if:** you're an OSINT researcher or security professional who wants a self-hosted, AI-powered situational awareness map with exportable intelligence reports — and can afford the Valyu API costs.

## Links

- Repo: <https://github.com/unicodeveloper/globalthreatmap>
- Mapbox: <https://account.mapbox.com/access-tokens/>
- Valyu: <https://valyu.ai>
- Railway deploy: see README badge
