---
name: Redlib
description: "Private front-end for Reddit — proxy that shows Reddit content without JavaScript, ads, tracking, or login. Rust; minimal footprint; strong CSP. Fork of Libreddit (archived). AGPL-3.0. Reddit's 2023 API-pricing + enforcement actions make public instances unstable."
---

# Redlib

Redlib is **"Reddit without the tracking + the nag-login-wall + the app-push + the ads + the JavaScript bloat"** — a private front-end proxy that fetches Reddit content server-side + renders clean HTML. You browse Reddit through Redlib; Redlib browses Reddit for you. Reddit sees the Redlib server, not you. Written in Rust for speed + memory safety. No JavaScript required (SSR-only). Strong Content Security Policy blocks browser-side requests to Reddit. **Fork of Libreddit** (which was archived in 2023).

Built + maintained by **redlib-org community** (redlib-org contributors). **License: AGPL-3.0**. Active fork; sister-project of Invidious (YouTube front-end). **Reddit's ongoing API-pricing + enforcement actions (June 2023 + onwards) have destabilized public instances** — self-hosting for personal use works; public instances are a whack-a-mole.

Use cases: (a) **private Reddit browsing** — no tracking, no data to Reddit (b) **escape Reddit login wall** — view content without account (c) **low-bandwidth / slow-device** — no JS means fast + simple HTML rendering (d) **archive Reddit viewing history** — via your self-hosted instance logs (e) **bypass regional restrictions** (if your server is elsewhere) (f) **accessibility** — SSR + clean HTML works with screen readers + old devices.

Features (from upstream README):

- **Fast** — Rust; SSR; no JS
- **Light** — minimal assets; minimal memory
- **Private** — all requests through server; your IP never hits Reddit
- **Secure** — strong CSP prevents browser-side requests to Reddit
- **RSS feeds** for subreddits
- **Settings** — themes, layout, preferences stored in cookies (client-side)
- **Media proxying** — images + videos served through Redlib (no Reddit CDN access from browser)
- **Podman Quadlets** support (new!)
- **Docker** (Compose + CLI)
- **Binary** releases

- Upstream repo: <https://github.com/redlib-org/redlib>
- Instances list: <https://github.com/redlib-org/redlib-instances>
- Libreddit archive (ancestor): <https://github.com/libreddit/libreddit>
- Docker Hub: <https://hub.docker.com/r/redlib/redlib>
- Releases: <https://github.com/redlib-org/redlib/releases>
- Farside (meta-instance-selector): <https://farside.link>
- Invidious (sister project YouTube): <https://invidious.io>

## Architecture in one minute

- **Rust binary** — single executable
- **Stateless** — no DB; config via env
- **Resource**: tiny — 30-80MB RAM
- **Port 8080** default
- **Acts as HTTP proxy** — fetches from Reddit API (or OAuth with account), renders HTML

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`redlib/redlib:latest`**                                     | **Primary**                                                                        |
| Docker compose     | For reverse-proxy integration                                             | Typical                                                                                   |
| Podman + Quadlets  | Upstream now supports this natively                                                                          | Systemd-integrated                                                                                               |
| Binary release     | Static Rust binary — drop in + run                                                                                           | Tiny footprint                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Port                 | 8080 default                                                | Network      | Behind reverse proxy                                                                                    |
| Reddit OAuth         | (optional) OAuth app for authenticated API access           | **CRITICAL if used** | **Reddit has throttled + banned**; see gotchas                                                                                    |
| `REDLIB_DEFAULT_*`   | Various defaults (theme, layout)                            | Config       | Env-var-based                                                                                    |
| Rate-limiting        | Configure to avoid upstream bans                                                                           | Config       | Critical for staying under Reddit's radar                                                                                                            |

## Install via Docker

```yaml
services:
  redlib:
    image: quay.io/redlib/redlib:latest     # **pin version**
    container_name: redlib
    restart: unless-stopped
    ports: ["8080:8080"]
    # Optional OAuth for authenticated API
    # environment:
    #   - REDLIB_DEFAULT_USE_HLS=on
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
```

## First boot

1. Browse `http://host:8080` → instance loads
2. Browse `/r/unpopularopinion` or whatever — should render cleanly
3. Configure themes + defaults via `/settings`
4. Put behind TLS reverse proxy for HTTPS
5. **Personal use only** — don't publish your instance list

## Data & config layout

- **NO PERSISTENT STATE** — stateless
- User preferences stored in browser cookies client-side
- Reddit OAuth tokens (if configured) in env vars

## Backup

- **Nothing to back up** — stateless.

## Upgrade

1. Releases: <https://github.com/redlib-org/redlib/releases>. Active.
2. Docker: pull + restart.
3. Read release notes for Reddit-compat changes.

## Gotchas

- **REDDIT'S 2023 API CRACKDOWN = EXISTENTIAL THREAT** to public front-ends:
  - **June 2023**: Reddit announced API pricing ($0.24 per 1000 requests for higher tiers) that killed Apollo, RIF, Sync, BaconReader, many third-party clients
  - **Enforcement actions**: Reddit actively detects + blocks public Libreddit / Redlib / Teddit instances via IP blocks + OAuth revocation
  - **Public instances are a whack-a-mole** — many public instances are down most of the time
  - **Private instance for personal use**: Reddit generally ignores single-user IPs with normal browsing patterns. Running Redlib for yourself + family usually works.
  - **14th tool in network-service-legal-risk family — API-TOS-platform-enforcement sub-family** joining GrowChief ToS-violation (batch 94). **Distinct from GrowChief (B2B outreach automation) — Redlib doesn't automate; it proxies client requests.** New sub-family member: "platform-front-end-proxy-risk".
- **OAUTH ACCOUNT RISK**: Redlib can be configured with a Reddit OAuth app for authenticated API access. **Your Reddit account may be banned** for running bot-like access patterns. **Don't use your main Reddit account** — create a throwaway.
- **RATE-LIMITING MATTERS** for longevity:
  - Reddit's public API: 10 requests/minute for unauth; 60/minute for OAuth
  - Redlib aggressive-cache strategies help
  - **Aggressive rate-limiting = longer instance life**
  - Personal-use single-user fits in rate limits easily
- **REDDIT CONTENT COPYRIGHT**: Redlib serves Reddit content without ads. Reddit asserts IP-rights over submitted content + comments (users grant Reddit licenses in ToS). Redlib proxying doesn't violate copyright (similar to a browser), but redistribution / archival of proxied content is different. **Personal browsing only; no archiving / redistribution.**
- **PRIVACY WIN: YOUR IP NEVER HITS REDDIT**: this is Redlib's core value. If you care about Reddit's data collection / cross-site tracking, Redlib shields you. Your Redlib server's IP hits Reddit; your browser IP hits only your Redlib server.
- **HUB-OF-CREDENTIALS: 0-to-LIGHT**: Redlib stateless + no user accounts + sometimes Reddit OAuth in env. If using OAuth:
  - **42nd tool in hub-of-credentials family — LIGHT tier** (Reddit OAuth token only)
  - If no OAuth: **ZERO credentials stored** — 4th tool in stateless-tool-rarity
- **STATELESS-TOOL-RARITY: 4 tools now** (OpenSpeedTest 91, Moodist 93, dashdot 93, **Redlib 95**) — pattern solidifying; family-doc at batch 100 mandatory.
- **AGPL-3.0 = DISTRIBUTED-NETWORK-SERVICE-DISCLOSURE** obligation: if you modify Redlib + serve as a public instance, you must publish your modifications. Fine for self-host personal.
- **PUBLIC-INSTANCE LIABILITY + LEGAL-FRONT-LINE**: running a public Redlib instance:
  - Reddit may send legal letters + API enforcement
  - DMCA takedowns for proxied content
  - Potential CFAA concerns (US) for circumventing Reddit's access control
  - **Personal use: low risk; public-instance: real legal exposure**
  - **Recipe convention: flag public-vs-personal use distinction** for front-end-proxy tools (Redlib, Invidious, Nitter, FreeTube, NewPipe-backends, etc.)
- **FORK LINEAGE**: Redlib forked from **Libreddit** after Libreddit became archived (2023). Forks after upstream death are a healthy OSS pattern. **Forking-after-upstream-archival** pattern — 1st tool named explicitly. Applicable to: Redlib←Libreddit, Nitter-forks, Invidious-community-forks, and many reactive forks.
- **SISTER-PROJECT ECOSYSTEM**: Redlib is part of a **"private-front-end ecosystem"**: Invidious (YouTube), Nitter (X/Twitter, multiple forks), FreeTube, Piped, LibreTranslate-category. Meta-pattern: **"private-front-end ecosystem"** — front-ends that proxy commercial platforms for privacy + ad-free access. Worth naming.
- **CSP STRICTNESS as SIGNATURE FEATURE**: Redlib explicitly implements strong Content Security Policy — positive security-engineering signal. **Transparent-maintenance signal (22nd tool)** — engineering-quality-signal sub-type.
- **COMMERCIAL-TIER**: none. Pure community + donations. **13th tool in pure-donation/community.**
- **STABILITY OF UPSTREAM-DEPENDENCY**: Redlib is fundamentally DEPENDENT on Reddit API existing + being accessible. Reddit can kill it anytime. **Upstream-platform-dependency risk** — 1st tool explicitly flagged; applicable to all private-front-end tools.
- **ALTERNATIVES WORTH KNOWING:**
  - **Libreddit** (ancestor, archived) — historical; Redlib is the continuation
  - **Teddit** — Python-based similar tool (still exists)
  - **RedReader** — Android app (native, different approach)
  - **Slide** / **Joey** (now dead) — legacy third-party apps
  - **Private-front-end ecosystem**:
    - **Invidious** — YouTube private front-end
    - **Nitter** (various forks) — X/Twitter private front-end
    - **Piped** — YouTube alternative
    - **FreeTube** — YouTube desktop client
    - **SearXNG** — meta-search engine
    - **LibreTranslate** — translation
  - **Choose Redlib if:** you want Rust + fast + private + Reddit-front-end + actively-maintained fork.
  - **Choose Teddit if:** Python alternative + different codebase.
  - **Give up on Reddit if:** enforcement wins + instability becomes untenable.
- **PROJECT HEALTH**: active fork + AGPL-3 + solid engineering + Rust performance. Project's long-term viability depends on Reddit's tolerance policy.

## Links

- Repo: <https://github.com/redlib-org/redlib>
- Instances: <https://github.com/redlib-org/redlib-instances>
- Docker: <https://hub.docker.com/r/redlib/redlib>
- Farside (instance-selector): <https://farside.link>
- Libreddit (ancestor): <https://github.com/libreddit/libreddit>
- Invidious (YouTube sister): <https://invidious.io>
- Nitter (X sister, fork-rich): <https://github.com/zedeus/nitter>
- Piped (YouTube alt): <https://piped.video>
- Teddit (Reddit alt): <https://codeberg.org/teddit/teddit>
