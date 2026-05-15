---
name: Whoogle Search
description: Self-hosted, ad-free, privacy-respecting Google search proxy. Scrapes Google results with no JS/cookies/ads/tracking, optional Tor routing, zero external JS. Python/Flask. MIT.
---

# Whoogle Search

Whoogle is a lightweight front-end that strips every tracker and piece of JavaScript off Google search results, then serves them back to you. Think "DuckDuckGo in appearance, Google results in content, but **run by you** on your own box."

What it removes from the stock Google experience:

- Ads
- JavaScript (most pages work without it)
- Cookies / Google session tracking
- AMP links (unwrapped to the real URL)
- Referrer headers
- Search-term logging (no logs by default)
- Fingerprintable browser probes

What it adds:

- Dark mode
- Results rewriting (e.g. redirect Twitter links to nitter, YouTube to invidious, Reddit to libreddit)
- Optional basic auth (so your instance isn't public)
- Optional Tor proxying (all searches routed through Tor)
- Firefox/Chrome search-engine plugin (set Whoogle as default)

- Upstream repo: <https://github.com/benbusby/whoogle-search>
- Docker Hub: <https://hub.docker.com/r/benbusby/whoogle-search>
- Public instance list: <https://github.com/benbusby/whoogle-search#public-instances>

## Architecture in one minute

- **One container** (`benbusby/whoogle-search`) — Python Flask app
- Intercepts search queries, fetches Google HTML, strips tracking, re-serves
- Optional bundled **Tor** (embedded in the image) — requests-via-Tor button on the UI
- **Stateless by default** — no DB, no persistent state (config via env vars; user search history is per-cookie and client-side)

Runs hardened by default in upstream compose: non-root user, dropped caps, tmpfs-only writeable paths, `no-new-privileges`, `pids_limit`, `mem_limit: 256mb`.

## Compatible install methods

| Infra            | Runtime                                          | Notes                                                                  |
| ---------------- | ------------------------------------------------ | ---------------------------------------------------------------------- |
| Single VM / home | Docker / Compose                                   | **Upstream-documented**                                                 |
| Single VM        | Native Python (Flask)                              | `pip install whoogle-search && whoogle-search`                           |
| Kubernetes       | Community Helm chart + Deployment                   | Trivial; stateless                                                       |
| PaaS             | Replit / Heroku-style button-deploy                 | Upstream includes `app.json` / `replit.nix`                              |
| Single-binary    | Docker via `benbusby/whoogle-search:latest`        | Multi-arch: amd64, arm64, armv7                                           |
| Tor hidden service | Same container + Tor daemon on host                | Popular anonymity setup                                                  |

## Inputs to collect

| Input                            | Example                            | Phase     | Notes                                                    |
| -------------------------------- | ---------------------------------- | --------- | -------------------------------------------------------- |
| Port                             | `5000`                              | Network   | Container listens on 5000                                  |
| `WHOOGLE_USER` / `WHOOGLE_PASS`  | basic-auth creds                    | Security  | **Set these unless you want a public instance**            |
| `WHOOGLE_PROXY_*`                | upstream proxy settings             | Privacy   | Route searches through a proxy                             |
| `WHOOGLE_CONFIG_*`               | default search config keys           | UX        | Force dark mode / lang / country / safe-search by default  |
| `WHOOGLE_ALT_*`                  | nitter / invidious / libreddit URLs  | UX        | Replace twitter/YT/reddit links in results                 |
| `WHOOGLE_MINIMAL`                | `1`                                 | UX        | Even-more-stripped minimal UI                              |
| Reverse proxy domain             | e.g. `search.example.com`            | DNS       | For TLS                                                    |
| Tor (optional)                   | `WHOOGLE_TOR_USE_PASS=1`             | Privacy   | Bundle control port password                                |

## Install via Docker Compose (upstream, hardened)

Trimmed from upstream `docker-compose.yml`:

```yaml
services:
  whoogle-search:
    image: benbusby/whoogle-search:1.2.4    # pin (check Docker Hub tags)
    container_name: whoogle-search
    restart: unless-stopped
    pids_limit: 50
    mem_limit: 256mb
    memswap_limit: 256mb
    user: whoogle
    security_opt:
      - no-new-privileges
    cap_drop:
      - ALL
    tmpfs:
      - /config/:size=10M,uid=927,gid=927,mode=1700
      - /var/lib/tor/:size=15M,uid=927,gid=927,mode=1700
      - /run/tor/:size=1M,uid=927,gid=927,mode=1700
    ports:
      - "5000:5000"
    environment:
      WHOOGLE_USER: alice
      WHOOGLE_PASS: <strong>
      # Optional link rewriting:
      WHOOGLE_ALT_TW: farside.link/nitter
      WHOOGLE_ALT_YT: farside.link/invidious
      WHOOGLE_ALT_RD: farside.link/libreddit
```

Visit `http://<host>:5000`. For TLS, put behind a reverse proxy (nginx/Caddy/Traefik).

## Install via Docker (quick)

```sh
docker run -d --name whoogle \
  -p 5000:5000 \
  -e WHOOGLE_USER=alice -e WHOOGLE_PASS=<strong> \
  --restart unless-stopped \
  benbusby/whoogle-search:1.2.4
```

## Browser integration

After first setup:

1. Open `http://<host>:5000/`
2. Click the search bar → browser will offer "Add Whoogle as search engine"
3. In your browser settings, set it as default

OR in settings page (`/settings`), download the OpenSearch XML + install manually.

## Data & config layout

By default Whoogle is **stateless** — no DB, no writeable volumes needed beyond the in-memory tmpfs used for Tor.

Per-user preferences (dark mode, country, language) are stored as **browser cookies** — clear cookies and settings are gone.

If you want persistent config, mount a volume at `/config`:

```yaml
    volumes:
      - whoogle-config:/config
```

## Backup

Nothing to back up unless you customized `/config`. `.env` with `WHOOGLE_*` settings is the only real "state."

## Upgrade

1. Releases: <https://github.com/benbusby/whoogle-search/releases>. Frequent (Google breaks their scrape, upstream patches).
2. `docker compose pull && docker compose up -d`. No migrations.
3. **Read changelog** — env var names occasionally change.
4. Multi-arch images available (amd64/arm64/armv7).

## Gotchas

- **Google breaks scrapers regularly.** When that happens, Whoogle results go blank or look wrong. Upstream typically patches within days. Keep Whoogle updated + pin a recent version, not a super-old one.
- **Rate limits / "too many requests"** — Google may 429 your IP if searches from a single home IP get busy. Two mitigations: (1) route via Tor (`/search?tor=1`), (2) use an upstream proxy.
- **Tor drastically slows search** but also drastically improves unlinkability + avoids IP rate-limits.
- **Basic auth is NOT a substitute for TLS.** Put it behind HTTPS (reverse proxy with Let's Encrypt).
- **Default upstream compose is hardened** (`cap_drop: ALL`, non-root, tmpfs-only) — keep it that way.
- **UID 927 for `whoogle` user** — if you mount config dir from host, `chown -R 927:927` it first.
- **Public instances exist** — upstream maintains a list. Running your own avoids load-balancing risk + IP correlation.
- **Image search** works but is slower than normal search (more scraping).
- **Autocomplete suggestions** are fetched from DuckDuckGo (not Google), to avoid Google profiling the query prefix.
- **Result rewriting via `WHOOGLE_ALT_*`** points to Farside — a maintained list of working instances of nitter/invidious/libreddit. Neat feature; zero-maintenance since Farside handles uptime.
- **Not a general-purpose search engine** — it's a Google *front-end*. If Google has bad results, Whoogle has bad results.
- **No JS policy**: Whoogle works without JS, but dark mode preview + some settings UI use a bit of progressive-enhancement JS. Core search is pure HTML.
- **Firefox containers + Whoogle** — great combo; isolate all searches in a dedicated container.
- **MIT license** — use freely.
- **Alternatives worth knowing:**
  - **SearXNG** — meta-search aggregator; queries many engines (Google, Bing, Brave, Wikipedia, ...) and dedupes. More full-featured; heavier.
  - **DuckDuckGo / Brave Search / Kagi** — commercial SaaS; no self-hosting
  - **Startpage** — commercial Google-proxy SaaS
  - **Mojeek** — independent search index (not just a proxy)
  - **Librex** (dead) / **LibreY** — other Google/Bing front-ends
  - **Perplexica / FreeSearch / AI-search (LLM-backed)** — newer AI-search angle; different product
  - Choose SearXNG if you want multi-engine aggregation; choose Whoogle if you specifically want Google's index without Google's tracking

## Links

- Repo: <https://github.com/benbusby/whoogle-search>
- Docker Hub: <https://hub.docker.com/r/benbusby/whoogle-search>
- Docker Hub tags: <https://hub.docker.com/r/benbusby/whoogle-search/tags>
- Releases: <https://github.com/benbusby/whoogle-search/releases>
- Public instances: <https://github.com/benbusby/whoogle-search#public-instances>
- Env var reference: <https://github.com/benbusby/whoogle-search#environment-variables>
- Farside (for `WHOOGLE_ALT_*` defaults): <https://farside.link>
- Matrix/IRC community: <https://matrix.to/#/#whoogle-search:matrix.org>
