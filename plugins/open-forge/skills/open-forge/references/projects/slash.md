---
name: Slash
description: "Open-source self-hosted link shortener. \"s/shortcut\" URLs. Go backend + React frontend. Browser extensions (Chrome/Firefox). Tags + collections + analytics + teams. MIT. Active by yourselfhosted org (Memos same author). Alternative to Bitly/Rebrandly."
---

# Slash

Slash is **"Bitly / Rebrandly / short.io — self-hosted"** — a link shortener that turns long URLs into easy `s/shortcut` shortcuts. Create + share + organize; view analytics on traffic + sources; install the browser extension to type `s/shortcut` in the address bar and go; group links into Collections you can share with teams or publicly. Go backend + React frontend.

Built + maintained by **yourselfhosted org** — same organization that builds **Memos** (popular note-taking app). **License: MIT**. Active; Discord + Chrome/Firefox extensions published; Docker + bolt-easy deployment.

Use cases: (a) **team link shortener** — `s/wiki`, `s/support`, `s/recruiting` — every department has its go-to URLs (b) **personal bookmarks-as-shortcuts** — muscle-memory `s/hackernews` > bookmarks (c) **public link-sharing** — Bitly alternative for campaigns (d) **URL-aware redirects** with analytics (e) **collection-sharing** with coworkers / public (f) **escape Bitly tracking** — own your redirects (g) **corporate `go/` links** (Google's famous internal convention) — self-hosted version (h) **QR-code-worthy short URLs** for events / business cards.

Features (from upstream README):

- **Create** customizable `s/` short links
- **Share** public or team-only
- **Analytics** — traffic, sources
- **Browser extension** (Chrome, Firefox) for quick access
- **Collections** — grouped shortcuts
- **Simple Docker deployment**
- **MIT** license

- Upstream repo: <https://github.com/yourselfhosted/slash>
- Discord: <https://discord.gg/QZqUuUAhDV>
- Shortcuts docs: <https://github.com/yourselfhosted/slash/blob/main/docs/getting-started/shortcuts.md>
- Collections docs: <https://github.com/yourselfhosted/slash/blob/main/docs/getting-started/collections.md>
- Install docs: <https://github.com/yourselfhosted/slash/blob/main/docs/install.md>
- Docker: <https://hub.docker.com/r/yourselfhosted/slash>
- Chrome extension: <https://chrome.google.com/webstore/detail/slash/ebaiehmkammnacjadffpicipfckgeobg>
- Firefox extension: <https://addons.mozilla.org/firefox/addon/your-slash/>
- Memos (same author): <https://www.usememos.com>

## Architecture in one minute

- **Go** backend — single binary
- **React** frontend
- **SQLite** by default; **Postgres + MySQL** supported
- **Resource**: tiny — 50-150MB RAM
- **Port 5231** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`yourselfhosted/slash:latest`**                              | **Primary**                                                                        |
| Docker compose     | For reverse-proxy integration                                             | Typical                                                                                   |
| Binary release     | Go binary + systemd                                                                              | Bare-metal                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `s.example.com` (short!)                                    | URL          | Shorter-is-better; TLS recommended                                                                                    |
| DB                   | SQLite default; Postgres/MySQL optional                     | DB           | SQLite fine for most                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong password                                                                                    |
| Browser-extension host | Matches Slash domain                                                                           | Config       | Extension talks to your instance                                                                                                            |

## Install via Docker

```sh
docker run -d --name slash \
  -p 5231:5231 \
  -v ~/.slash/:/var/opt/slash \
  yourselfhosted/slash:latest     # **pin version**
```

## First boot

1. Start → browse `http://host:5231`
2. Register admin user
3. Create first shortcut (e.g., `s/wiki` → your wiki URL)
4. Test redirect: browse `http://host:5231/s/wiki` → wiki opens
5. Install browser extension; configure to point at your instance
6. Create a Collection; share with team or public
7. Put behind short TLS domain (`s.example.com` pattern)
8. Back up `~/.slash/` (the bind-mount)

## Data & config layout

- `/var/opt/slash/` — SQLite DB + config + logs (bind-mounted to `~/.slash/` on host)
- Postgres/MySQL: external

## Backup

```sh
sudo tar czf slash-$(date +%F).tgz ~/.slash/
# Postgres: pg_dump as usual
```

## Upgrade

1. Releases: <https://github.com/yourselfhosted/slash/releases>. Active.
2. Docker: pull + restart; migrations auto-run.
3. Active development; pin versions.

## Gotchas

- **URL-SHORTENER = PHISHING-VECTOR IF PUBLIC**: anyone who can create shortcuts can create phishing URLs pointing at lookalike sites. If Slash is:
  - **Private / team-only**: low risk (only trusted users)
  - **Public with signups**: **HIGH phishing + scam-relay risk**. Spammers will sign up, create `s/urgent-bank-verify → phishing-site.com`, and spam the links
  - **Open-signup self-hosted link shortener = attractive-nuisance**
  - **Mitigations**: disable public signups; require invite codes; manual approval; content-moderation; rate-limiting; URL-preview in admin UI; domain-deny-lists; integrate with Google Safe Browsing + abuse APIs
- **NEW: "URL-shortener-as-phishing-vector-risk" sub-family of network-service-legal-risk** (Slash) — distinct from all prior 10 sub-families. Link-shorteners face takedown requests + potential ISP threats + domain-blocklisting by Gmail/Twitter/Facebook/etc. if abused. **20th tool in network-service-legal-risk family. 11th sub-family.**
- **DOMAIN BLOCKLISTING IS A REAL THREAT**: if abusers spam Slash-based links through social platforms, your domain can be blocklisted by:
  - Gmail (email links rejected)
  - Safe-browsing (Chrome warnings)
  - Bitly's + other shorteners' deny-lists
  - **Once blocklisted, recovery is hard**
  - **Private/team instance avoids this entirely**
- **HUB-OF-CREDENTIALS LIGHT**: Slash stores:
  - User accounts
  - Shortcuts + their destinations
  - Click analytics (traffic sources — mildly sensitive)
  - **53rd tool in hub-of-credentials family — LIGHT tier.**
- **YOURSELFHOSTED ORG = MEMOS TEAM**: same team that builds Memos (the popular note-taking app — batch <future>). Sign of commitment + quality. Memos is ~30k stars + mature; Slash benefits from the team's experience + shared UX patterns. **"Team-with-prior-successful-OSS-project" institutional-stewardship sub-pattern** — positive signal. Recipe convention: flag when a tool comes from a team with other successful projects (transitive-trust).
- **INSTITUTIONAL-STEWARDSHIP**: yourselfhosted org + multi-project team. **29th tool in institutional-stewardship — team-with-prior-successful-OSS-project sub-tier (NEW)**. 1st tool explicitly named with this sub-tier framing.
- **ANALYTICS = GDPR CONSIDERATIONS**: click-tracking analytics captures:
  - IP (geolocated if anonymized)
  - User agent
  - Referrer
  - Timestamps
  - **GDPR applies** — include cookie-consent / privacy policy for public-serving instances. Recipe convention: analytics-tool-regulatory-framework (OpnForm 95 precedent extends here).
- **BROWSER EXTENSION TRUST**: the Chrome/Firefox extensions read URL patterns + intercept. Extensions hosted on official stores under yourselfhosted-org = moderate-trust; verify manifest permissions before install.
- **TRANSPARENT-MAINTENANCE**: MIT + active + Discord + docs + extensions published + from-memos-team-credibility. **35th tool in transparent-maintenance family.**
- **MIT LICENSE**: permissive.
- **SUSTAINABILITY**: yourselfhosted org has Memos + Slash (and possibly others). Funding model not obvious from README — may rely on side-project / donation. For an org with multiple projects, sustainability depends on continued organizational priority.
- **COMMERCIAL-TIER**: none visible. Pure OSS.
- **ALTERNATIVES WORTH KNOWING:**
  - **Shlink** — PHP + MySQL; mature; self-hosted link shortener with rich analytics
  - **YOURLS** — PHP; classic self-hosted link shortener; GPL
  - **Kutt** — Node.js; modern; MIT
  - **Simplelogin-open-source-url-aliasing** — different niche
  - **Polr** — PHP; open-source; somewhat dormant
  - **Bitly / Rebrandly / TinyURL** — commercial SaaS
  - **Google short.url** / **goo.gl** — historical Google SaaS (discontinued)
  - **Choose Slash if:** you want GO + modern UX + browser extension + team-collections + MIT + Memos-team-credibility.
  - **Choose Shlink if:** you want PHP + richer analytics + more-established.
  - **Choose YOURLS if:** you want oldest + simplest + stable.
  - **Choose Kutt if:** you want Node + free + simple.
- **PROJECT HEALTH**: active + MIT + browser-extensions + from-successful-team + Discord. Strong positive signals.

## Links

- Repo: <https://github.com/yourselfhosted/slash>
- Docs-install: <https://github.com/yourselfhosted/slash/blob/main/docs/install.md>
- Discord: <https://discord.gg/QZqUuUAhDV>
- Docker: <https://hub.docker.com/r/yourselfhosted/slash>
- Chrome ext: <https://chrome.google.com/webstore/detail/slash/ebaiehmkammnacjadffpicipfckgeobg>
- Firefox ext: <https://addons.mozilla.org/firefox/addon/your-slash/>
- Memos (same team): <https://www.usememos.com>
- Shlink (alt): <https://shlink.io>
- YOURLS (alt): <https://yourls.org>
- Kutt (alt): <https://kutt.it>
- Bitly (commercial alt): <https://bitly.com>
