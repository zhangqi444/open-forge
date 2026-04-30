---
name: Moodist
description: "Ambient-sound web player for focus + relaxation. 75+ nature/white-noise sounds, presets, sleep timer, pomodoro, notepad. React + Astro SPA. No data collection. MIT. Self-hostable or use public instance at moodist.mvze.net."
---

# Moodist

Moodist is **"Noisli / MyNoise / A Soft Murmur, self-hosted"** — a browser-based ambient-sound mixer that lets you blend 75+ natural + synthetic sounds (rain, forest, ocean, café, white/pink/brown noise, fireplace, keyboard typing, etc.) into a personalized focus/relaxation soundscape. Adjust per-sound volume, save presets, share mix URLs, set sleep timer, run a Pomodoro, jot notes in an integrated notepad. Privacy-first: no tracking, no analytics, no account. MIT license. Single-page app — serve from anywhere static files go.

Built + maintained by **remvze** (Remvze + contributors). **License: MIT**. Active; public instance at <https://moodist.mvze.net> free to use; funded via BuyMeACoffee donations.

Use cases: (a) **focus-work background** — drown out office / apartment noise (b) **sleep aid** — ocean + rain + fan until timer cuts (c) **study aid** — coffee shop simulator without the actual coffee shop (d) **baby/toddler white noise** — pink noise for nap time (e) **meditation / mindfulness** — forest-stream-bird mix (f) **workplace productivity app** — host internally for the whole team (g) **replace proprietary apps** — myNoise.net / Endel / Calm / Headspace.

Features (from upstream README):

- **75+ ambient sounds** across nature, urban, white/pink/brown noise categories
- **Persistent sound selection** (localStorage)
- **Shareable mix URLs** — send a friend your current soundscape
- **Custom presets** — save + label your favorites
- **Sleep timer** — auto-stop after N minutes
- **Notepad** for quick notes
- **Pomodoro timer**
- **To-do list** (per README, coming soon / maybe shipped)
- **Media controls** (keyboard media keys)
- **Full keyboard shortcuts**
- **Privacy-focused: NO DATA COLLECTION** — upstream explicit
- **Completely free + MIT + self-hostable**

## Architecture in one minute

- **TypeScript + React + Astro** — meta-framework for static+SSR
- **CSS modules + PostCSS** — styling
- **Zustand** — state
- **Framer Motion** — animation
- **Radix** — accessible UI primitives
- **Build output**: static site (no server logic after build) — deployable anywhere
- **Resource**: trivial — browser runs everything; server just serves static files

- Upstream repo: <https://github.com/remvze/moodist>
- Public instance: <https://moodist.mvze.net>
- BMC (donate): <https://buymeacoffee.com/remvze>

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static web host** | **Any HTTP server serving the `dist/` output**                  | **Easiest — nginx / Caddy / Apache / GitHub Pages / Netlify / Cloudflare Pages / S3+CDN** |
| Docker (community) | Community-built images (check repo forks)                                 | Not upstream-primary                                                                                   |
| Node.js (dev)      | `npm run dev` for local development                                                                  | Dev only                                                                                               |
| Public instance    | moodist.mvze.net                                                                                             | Just use the hosted one                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `moodist.example.com`                                       | URL          | Optional — LAN-hosting works fine                                                                                    |
| TLS                  | Let's Encrypt / self-signed / reverse proxy                                                | Security     | Recommended but not mandatory (static SPA; no backend)                                                                                    |

## Install (static build)

```sh
git clone https://github.com/remvze/moodist
cd moodist
npm install
npm run build
# Serve dist/
caddy file-server --root ./dist --listen :8080
```

Or nginx with `try_files $uri /index.html;` for SPA routing.

## First boot

1. Browse URL → UI loads
2. Click sounds to add to your mix
3. Adjust volumes → save as preset
4. Share URL generates deep-link with encoded state
5. Use sleep timer + Pomodoro + notepad as needed

## Data & config layout

- **NO SERVER-SIDE STATE** — all user prefs in browser localStorage
- **Sound assets** — bundled with build output (static audio files)

## Backup

- **Nothing server-side to back up** — users' data is in their own browsers
- Preset URLs can be shared/saved by users

## Upgrade

1. Releases: <https://github.com/remvze/moodist/releases>. Active.
2. Pull latest → rebuild → redeploy static assets.
3. No DB migrations, no server state — trivial upgrades.

## Gotchas

- **PLEASANT RARITY: STATELESS SPA** (2nd tool after OpenSpeedTest batch 91 in "stateless-tool rarity" framing): no DB, no secrets, no backend, no auth, no upgrade-migrations, no backup. Just static files. **Deploy-and-forget simplicity.** Pattern applies to: Moodist + OpenSpeedTest + most static-site-generators-as-apps.
- **AUDIO FILE SIZES**: 75+ high-quality ambient audio samples = probably 10-100MB of static assets. Plan:
  - CDN-friendly (cache-control headers set by your static host)
  - Lazy-load sounds (likely done by Moodist — audio not fetched until enabled)
  - Consider compression quality vs file size tradeoff if bandwidth-constrained
- **BROWSER AUDIO POLICY**: modern browsers block autoplay — first user interaction is required to start audio. Moodist handles this (click-to-start UX); no server-side concern.
- **PRIVACY-FIRST = NO-TRACKING, ALSO NO-ANALYTICS**: you won't know how many people use your instance without adding analytics yourself. If adding analytics:
  - Use privacy-respecting analytics (Plausible, Umami) — self-hosted
  - Avoid Google Analytics / similar third-party scripts
  - Disclose in a privacy notice
  - **Don't break Moodist's privacy-first ethos** just to get vanity metrics
- **SOUND LIBRARY COPYRIGHT**: 75+ audio samples — Moodist bundles these per MIT. Verify upstream has cleared licensing for all samples (royalty-free sources + attributions). For commercial / enterprise deployments, **perform your own audio-licensing audit** — MIT covers the code but individual audio files may have different licenses (CC-BY requiring attribution, CC-BY-SA requiring derivative-licensing, public-domain-no-obligation, etc.).
- **ACCESSIBILITY (Radix-powered)**: Radix UI primitives provide baseline accessibility (keyboard nav, screen readers, focus management). Moodist inherits this — positive accessibility signal.
- **KEYBOARD SHORTCUTS CONFLICT**: Moodist uses many keyboard shortcuts. When embedded in other contexts (iframe, kiosk) consider shortcut conflicts. Standalone deployment is fine.
- **SLEEP TIMER + POMODORO + NOTEPAD = FEATURE CREEP WATCH**: core value is ambient-sound-mixer. Additional features (notepad, Pomodoro, to-do) are nice but could drift toward productivity-app bloat. Author's discretion; watch roadmap for focus.
- **SOLE-MAINTAINER + community model** (8th tool in sole-maintainer-with-community class): remvze + community + BMC funding. Static-SPA architecture simplifies handoff if maintainer changes.
- **PUBLIC INSTANCE at moodist.mvze.net** — free + hosted by the maintainer. **"Pure-donation-SaaS-variant"** tier reinforced (8th tool): CommaFeed 92 was 1st-named; Moodist joins. Support via BMC donations keeps it running.
- **HUB-OF-CREDENTIALS: 0 TOOLS** — Moodist has no credentials, no accounts, no auth. **Not in hub-of-credentials family.** Another pleasant rarity.
- **IMMUTABILITY-OF-SECRETS: 0 TOOLS** — no secrets at all. **Not in immutability family.**
- **MIT LICENSE**: fork-friendly; commercial-reuse-friendly; standard.
- **CSP + SECURITY HEADERS on your static host**: even for a stateless SPA, set reasonable security headers (CSP, X-Frame-Options, Referrer-Policy) on your web server. Don't need to be strict; just reasonable defaults.
- **TRANSPARENT-MAINTENANCE**: MIT + no-data-collection + active + clear-feature-list. **16th tool in transparent-maintenance family.**
- **COMMERCIAL-TIER**: pure-donation (BMC). **9th tool in pure-donation (or 2nd in pure-donation-SaaS-variant with public instance).**
- **WELLNESS CLAIM BOUNDARIES**: ambient sound tools are often marketed for sleep/anxiety/stress relief. Moodist's README doesn't overreach into medical-claim territory — clean. Recipe convention: **flag tools that make wellness / therapy / medical claims** requiring regulatory scrutiny (FDA class II device, GDPR special-category data, etc.). Moodist is OK — stays in "ambient sounds" framing not "therapeutic".
- **ALTERNATIVES WORTH KNOWING:**
  - **Noisli** — commercial SaaS with similar UX; freemium
  - **myNoise** — commercial by Stéphane Pigeon; binaural-noise-specialist; extensive library
  - **A Soft Murmur** — commercial; beautiful minimalism
  - **Endel** — AI-adaptive-soundscape commercial app
  - **Calm / Headspace** — meditation + sleep + sound commercial
  - **Brain.fm** — focus-music research-backed commercial
  - **Rainy Mood** — rain-specialist simple
  - **I Miss My Café** — café-ambience classic
  - **Choose Moodist if:** you want SELF-HOSTED + MIT + 75+ sounds + mix + share + free.
  - **Choose myNoise if:** you want scientific-grade noise tuning + accept commercial + deep-customization.
  - **Choose Noisli if:** you want polished UX + accept SaaS + simpler than Moodist.
- **PROJECT HEALTH**: active + MIT + 75+ sounds + privacy-first + public instance funded by donations. Healthy + sustainable-feeling signals.

## Links

- Repo: <https://github.com/remvze/moodist>
- Public instance: <https://moodist.mvze.net>
- BMC: <https://buymeacoffee.com/remvze>
- Noisli (commercial alt): <https://www.noisli.com>
- myNoise (specialist commercial): <https://mynoise.net>
- A Soft Murmur (commercial alt): <https://asoftmurmur.com>
- Endel (AI-adaptive commercial): <https://endel.io>
- Calm (commercial): <https://www.calm.com>
- Headspace (commercial): <https://www.headspace.com>
- Brain.fm (commercial): <https://www.brain.fm>
- Plausible (privacy-analytics): <https://plausible.io>
- Umami (privacy-analytics): <https://umami.is>
