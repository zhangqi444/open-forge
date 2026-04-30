---
name: LittleLink
description: "Self-hosted static LinkTree alternative. 100+ branded button styles. Pure HTML + CSS (no framework, no build, no DB). Deploy anywhere — CF Pages/DigitalOcean/Vercel/Netlify/Amplify/GitHub Pages/home-server. MIT (verify). Active community."
---

# LittleLink

LittleLink is **"LinkTree / Beacons / Bio.link — self-hosted + static + DIY"** — a minimalist personal landing page ("link in bio") with 100+ pre-built branded button styles. Pure vanilla HTML + CSS: no build step, no npm/gulp, no database, no JavaScript framework. Fork + edit `index.html` + deploy to any static host. Auto/light/dark themes; WCAG-aware contrast outlines; 100/100 PageSpeed Insights scores. Button Builder tool for creating custom brand buttons.

Built + maintained by **Seth Cottle (sethcottle)** + community + "LittleLink Extended" (niche buttons). License: check repo (MIT likely given ecosystem openness). Active; Button Builder tool (builder.littlelink.io); Figma template; TechnoTim's LittleLink-Server Docker alternative.

Use cases: (a) **Instagram/TikTok/YouTube bio link** — one URL pointing to all your accounts (b) **personal landing page** — portfolio/resume one-pager (c) **creator-monetization link hub** — OnlyFans/Patreon/Ko-fi/Twitch links (d) **podcast host page** — Spotify/Apple/RSS/social (e) **musician link-in-bio** — Spotify/Bandcamp/SoundCloud (f) **self-host because LinkTree raised prices / tracks users / UX degraded** (g) **non-tracking bio page** — LittleLink doesn't phone home by default (h) **event/conference landing** — schedule + social + sponsors (i) **small business local landing** — hours + contact + social.

Features (per README):

- **100+ pre-built branded buttons** (Instagram, Twitter, YouTube, Spotify, etc.)
- **LittleLink Extended** — additional niche buttons
- **Button Builder** — visual tool for custom buttons (builder.littlelink.io)
- **auto/light/dark themes**
- **Accessibility** — WCAG contrast outlines
- **100/100 PageSpeed** (Google Lighthouse)
- **Vanilla CSS only** — no framework bloat
- **One-click deploys**: Cloudflare / DigitalOcean / Vercel / Netlify / AWS Amplify
- **Figma template**
- **Docker alternative**: TechnoTim's LittleLink-Server

- Upstream repo: <https://github.com/sethcottle/littlelink>
- LittleLink Extended: <https://github.com/sethcottle/littlelink-extended>
- Button Builder: <https://builder.littlelink.io>
- Sample: <https://littlelink.io/sample/seth>
- Figma: <https://www.figma.com/community/file/846568099968305613>
- LittleLink-Server (TechnoTim Docker): <https://github.com/techno-tim/littlelink-server>

## Architecture in one minute

- **Static HTML + CSS** — that's it
- **No backend**, **no DB**, **no server-side logic**
- **Resource**: zero — static files served by any web host
- Deploy anywhere that serves HTML

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Cloudflare Pages** | **One-click deploy**                                          | **Free, fast, edge CDN**                                                                        |
| **GitHub Pages**   | Fork repo + Pages on                                            | Free                                                                                   |
| **Netlify / Vercel / Amplify / DigitalOcean** | One-click                               | Free/paid tiers                                                                                   |
| Home-server static | nginx / Caddy serving the dir                                                                    | DIY                                                                                   |
| TechnoTim LittleLink-Server | Docker wrapper adding admin + DB                                                                          | Alternative                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `links.example.com`                                         | URL          | TLS via host                                                                                    |
| Fork of repo         | GitHub fork                                                 | Source       | Edit `index.html`                                                                                    |
| Links to show        | Your social/web URLs                                        | Content      |                                                                                    |
| Brand buttons        | Pick from the library                                                                           | Design       |                                                                                    |
| Theme                | auto / light / dark                                                                                 | Design       |                                                                                    |
| Avatar / profile pic | Your image                                                                                                         | Design       |                                                                                                            |

## Install via Cloudflare Pages (typical)

1. Fork <https://github.com/sethcottle/littlelink> to your GitHub account
2. Go to Cloudflare Pages → Connect to GitHub → pick fork
3. Edit `index.html` — change name + avatar + links (copy/paste brand-button snippets)
4. Commit → CF Pages auto-builds + deploys
5. Configure custom domain
6. Share the URL

## Data & config layout

- `index.html` — your landing page (edit this)
- `css/` — theme stylesheets
- `images/` — your avatar + assets
- That's it. No DB, no secrets, no backup needed beyond git-versioning

## Backup

```sh
# Just your git repo
git clone https://github.com/YOUR-USERNAME/littlelink.git
# All of your config is in index.html
```

## Upgrade

1. Upstream releases: <https://github.com/sethcottle/littlelink/releases>. Active.
2. Merge upstream via `git pull upstream main` in your fork
3. Resolve merge conflicts in `index.html` (your links) — usually trivial

## Gotchas

- **STATELESS-TOOL-RARITY PATTERN EXTENDED**: 8th tool in the family.
  - Previous: OpenSpeedTest 91, Moodist 93, dashdot 93, Redlib-no-OAuth 95, Converse 96, Speaches 96, Sshwifty 99, **LittleLink 103**
  - **Stateless-tool-rarity: 8 tools** — pattern extremely solidified
  - LittleLink is the MOST-stateless of the class — literally just HTML+CSS; zero backend state
  - **Recipe convention: "pure-static-site" sub-category** of stateless-tool-rarity — no runtime at all
  - **NEW sub-category**: pure-static-site (distinct from Go-single-binary-no-persistence like OpenSpeedTest)
- **NO DATABASE = ZERO BACKUP SURFACE**:
  - Everything in git
  - Disaster recovery = re-clone + redeploy
  - **Recipe convention: "git-as-backup" pattern** for static tools
- **NO CREDENTIALS = NOT IN HUB-OF-CREDENTIALS FAMILY**:
  - LittleLink is one of the rare self-host tools that stores ZERO user credentials
  - Not counted in hub-of-credentials family
  - **Recipe convention: "no-credentials-at-all" positive-signal** — rare
  - **NEW positive-signal convention** — 1st tool named (LittleLink)
- **CDN DEPENDENCY FOR SOME DEPLOYMENTS**:
  - Cloudflare/Netlify/Vercel host your content
  - Privacy: they see your visitors' IPs + user-agents
  - **Mitigation**: self-host on home-server or VPS if privacy matters
- **NO ANALYTICS BY DEFAULT**:
  - Unlike LinkTree which tracks clicks + shows you "analytics"
  - Privacy-win; but no "how many clicked my Twitter?" data
  - Can add optional: Plausible / Umami / Tianji (100) for privacy-respecting analytics
- **ONE-CLICK DEPLOY = CONVENIENCE + LOCK-IN**:
  - Cloudflare/Netlify/etc. are commercial free tiers
  - Free tiers can be discontinued; terms change
  - **Portable**: source is in git; re-deploy to another host easily
- **CLIENT-SIDE ONLY = NO-SERVER-COMPROMISE-RISK**:
  - Attackers can't "hack your LittleLink" server-side (there isn't one)
  - Social attacks: domain hijacking, DNS compromise, host-provider account takeover
  - **Threat model = DIFFERENT from server-based tools**
- **CSS-ONLY = BRAND-BUTTONS ARE STATIC**:
  - Buttons are pre-styled CSS
  - When a brand rebrands (e.g., Twitter → X) LittleLink needs manual update
  - Upstream usually updates; pull in changes via git
- **LITTLELINK EXTENDED vs CORE**:
  - Core = mainstream brands (100+)
  - Extended = niche brands; community-contributed
  - Adding niche brand to core = long PR process; Extended = faster merges
- **PAGESPEED 100/100 = ACHIEVEMENT**:
  - Pure CSS, no JS framework, tiny HTML = perfect scores
  - **Recipe convention: "PageSpeed-100 positive-signal"** — pristine web perf is rare
- **ACCESSIBILITY EMPHASIS**:
  - WCAG contrast-ratio outlines for light+dark themes
  - **Recipe convention: "accessibility-first design" positive-signal**
  - **NEW positive-signal convention**
- **TECHNOTIM'S LITTLELINK-SERVER**:
  - Adds admin UI + user DB on top of LittleLink design
  - If you want non-developers to edit the page, consider that fork
  - But: then you've added DB + auth + attack surface (no longer a pure-static tool)
- **INSTITUTIONAL-STEWARDSHIP**: Seth Cottle + Extended-community + TechnoTim ecosystem. **54th tool — sole-maintainer-with-community sub-tier (27th tool in sub-tier).**
- **TRANSPARENT-MAINTENANCE**: active + Button-Builder + Extended repo + Figma template + Docker-alternative + wiki + clean-commit-history. **61st tool in transparent-maintenance family.**
- **LICENSE CHECK**: verify LICENSE (convention).
- **LINK-IN-BIO CATEGORY**:
  - **LittleLink** — static HTML; DIY; MIT
  - **Bio** (by jeromedotcom) — PHP; DB-based
  - **LinkStack** — PHP Laravel; multi-user + DB; feature-rich
  - **LittleLink-Server (TechnoTim)** — Docker + Node wrapper over LittleLink
  - **Linkwarden** — link-archive tool (related but different scope)
  - **Dumbdrop / Dumb-pad / dumb-_** (unrelated brand)
  - **Commercial**: LinkTree, Beacons, Bio.link, Carrd (static alternative but commercial)
- **ALTERNATIVES WORTH KNOWING:**
  - **LinkStack** — if you want multi-user + DB
  - **LittleLink-Server** — if you want admin UI + Docker
  - **Carrd** (commercial) — polished one-pager editor
  - **GitHub profile README** — if you just want a link-in-bio for dev audience
  - **Choose LittleLink if:** you want PURE STATIC + MIT + vanilla CSS + edit-HTML.
  - **Choose LinkStack if:** you want multi-user + rich admin + DB.
  - **Choose LittleLink-Server if:** you want LittleLink + Docker + admin UI.
  - **Choose Carrd if:** you want commercial polished UX.
- **PROJECT HEALTH**: active + Button-Builder tool + Figma template + Extended repo + Docker-alternative ecosystem. Strong for a static tool.

## Links

- Repo: <https://github.com/sethcottle/littlelink>
- Extended: <https://github.com/sethcottle/littlelink-extended>
- Button Builder: <https://builder.littlelink.io>
- LittleLink-Server (TechnoTim): <https://github.com/techno-tim/littlelink-server>
- Figma: <https://www.figma.com/community/file/846568099968305613>
- LinkStack (alt multi-user): <https://linkstack.org>
- Carrd (commercial alt): <https://carrd.co>
- LinkTree (commercial origin): <https://linktr.ee>
- Bio.link (commercial alt): <https://bio.link>
- Beacons (commercial alt): <https://beacons.ai>
