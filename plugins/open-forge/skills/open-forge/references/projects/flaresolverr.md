---
name: FlareSolverr
description: Proxy server that bypasses Cloudflare and DDoS-Guard anti-bot challenges by running a real headless Chromium and replaying cookies. Used as a helper by Prowlarr, Jackett, Sonarr, Radarr, etc., to scrape protected indexer sites. MIT.
---

# FlareSolverr

FlareSolverr is a **helper proxy** for the "arr" stack and other scrapers. Many indexer sites (1337x, torrentgalaxy, the-eye.eu, …) sit behind Cloudflare's "checking your browser" / Turnstile anti-bot page. Plain HTTP clients get 403. FlareSolverr fixes this by:

1. Receiving an API request (JSON) asking to fetch a URL
2. Launching a headless Chromium with undetected-chromedriver
3. Letting Cloudflare's JS challenge run in a real browser
4. Extracting the resulting cookies + `User-Agent`
5. Returning them to the caller (or proxying the whole response)

The caller (Prowlarr, Jackett, Flaresolverr-compatible apps) then re-uses those cookies for subsequent plain-HTTP requests until they expire.

Not a general-purpose web scraper or VPN. Specifically shaped for the arr ecosystem.

- Upstream repo: <https://github.com/FlareSolverr/FlareSolverr>
- Docker image: `ghcr.io/flaresolverr/flaresolverr:<VERSION>` (and `flaresolverr/flaresolverr` on Docker Hub)
- API docs: <https://github.com/FlareSolverr/FlareSolverr#-api>

## ⚠️ Effectiveness is a moving target

Cloudflare continuously improves detection; FlareSolverr continuously reacts. Front-loaded warning:

- **Some sites work one week and break the next.** Check the issues tab before debugging.
- **Cloudflare Turnstile** (the newer checkbox + invisible challenge) is increasingly hard to bypass. Many prior targets now require a paid CAPTCHA solver key (2Captcha / Anti-Captcha / CapSolver).
- **FlareSolverr is not a silver bullet.** If a site uses Cloudflare Turnstile + "strict" Under Attack mode, expect failures that even paid solvers can't always clear.

## Compatible install methods

| Infra      | Runtime                                                | Notes                                                                    |
| ---------- | ------------------------------------------------------ | ------------------------------------------------------------------------ |
| Single VM  | Docker (`ghcr.io/flaresolverr/flaresolverr:<VERSION>`) | **Recommended.** Ships Chromium + undetected-chromedriver                 |
| Single VM  | Python (source)                                        | `pip install -r requirements.txt` + system Chromium; fiddly               |
| Kubernetes | Plain Deployment                                        | Fine; needs ~512 MB RAM per pod                                           |
| ARM64      | Multi-arch image works on Pi/M-series                  |                                                                          |

## Inputs to collect

| Input               | Example                                    | Phase     | Notes                                                        |
| ------------------- | ------------------------------------------ | --------- | ------------------------------------------------------------ |
| Port                | `8191:8191`                                | Network   | HTTP API listen port                                          |
| `LOG_LEVEL`         | `info` (default) / `debug`                 | Runtime   | `debug` spams; only on for troubleshooting                    |
| `LOG_HTML`          | `false` (default)                          | Runtime   | If true, logs full HTML responses — huge + may contain creds  |
| `CAPTCHA_SOLVER`    | `none` (default) / `hcaptcha-solver`       | Runtime   | External solver integration; mostly disabled in newer versions |
| `TZ`                | `America/New_York`                         | Runtime   | For log timestamps                                            |
| Shared memory       | `shm_size: '1gb'` recommended              | Runtime   | Chromium crashes in default 64 MB container `/dev/shm`        |
| **Prowlarr / Jackett / etc. URL** | `http://flaresolverr:8191/v1`  | Integration | Configure in indexer client's settings                     |

## Install via Docker Compose

From <https://github.com/FlareSolverr/FlareSolverr/blob/master/docker-compose.yml>:

```yaml
services:
  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:v3.4.6    # pin; NEVER :latest for arr stack
    container_name: flaresolverr
    restart: unless-stopped
    environment:
      - LOG_LEVEL=${LOG_LEVEL:-info}
      - LOG_HTML=${LOG_HTML:-false}
      - CAPTCHA_SOLVER=${CAPTCHA_SOLVER:-none}
      - TZ=America/New_York
    ports:
      - "${PORT:-8191}:8191"
    shm_size: '1gb'                  # Chromium needs this; default /dev/shm = 64 MB = crashes
    # volumes:
    #   - /var/lib/flaresolver:/config   # optional; mostly empty
```

Verify it's alive:

```sh
curl http://localhost:8191/
# {"msg":"FlareSolverr is ready!","version":"...", ...}
```

Test a request:

```sh
curl -L -X POST 'http://localhost:8191/v1' \
  -H 'Content-Type: application/json' \
  -d '{
    "cmd": "request.get",
    "url": "https://nowsecure.nl",
    "maxTimeout": 60000
  }'
```

## Wire into Prowlarr / Jackett

**Prowlarr:**

1. Indexers → Settings → **Indexer Proxies** → Add → FlareSolverr
2. Host: `http://flaresolverr:8191/` (or `http://<host>:8191/`)
3. Tags: create a tag (e.g. "flaresolverr"); attach the same tag to indexers that need it
4. Prowlarr routes only tagged indexers through FlareSolverr

**Jackett:**

1. Configure → FlareSolverr API URL: `http://flaresolverr:8191/`
2. Applies globally; per-indexer opt-in via their settings

Keep FlareSolverr + arr apps on the same Docker network so `flaresolverr` resolves.

## API

Three commands:

- `sessions.create` — make a persistent browser session (reused across requests)
- `sessions.destroy` — kill a session
- `request.get` / `request.post` — fetch a URL via the browser, optionally in a session

Full API: <https://github.com/FlareSolverr/FlareSolverr#-api>.

## Data & config layout

Mostly stateless. Every request spins up a fresh Chromium instance (or re-uses a session if provided). Optional `/config` volume can hold cookie caches but is rarely used.

Memory: ~400-800 MB per concurrent request. Chromium is not lightweight.

## Backup

None needed; stateless service. Recreate the container and it's back.

## Upgrade

1. Releases: <https://github.com/FlareSolverr/FlareSolverr/releases>. Rapid when Cloudflare changes detection.
2. `docker compose pull && docker compose up -d`.
3. **Subscribe to releases.** When your arr stack starts failing with 403s, check for a new FlareSolverr release.
4. Chromium inside the image is pinned to a specific version known to bypass current Cloudflare. Upgrading = new Chromium + updated undetected-chromedriver.

## Gotchas

- **Cloudflare cat-and-mouse.** What works today may not work next month. Subscribe to releases + arr-stack Discord channels for early warning.
- **`shm_size: 1gb`** is required. Without, Chromium crashes mid-request with obscure "Session not created" errors.
- **`LOG_HTML=true`** logs the full response body — huge in terms of disk, and can leak scraped site content. Only enable for short debugging sessions.
- **Per-request Chromium overhead.** ~5-15 second latency per request. Use sessions (`sessions.create`) to keep a browser alive and reduce per-request cost.
- **Cloudflare Turnstile** (newer) defeats FlareSolverr in many cases. If you see "Solving the challenge...it took too long" in logs, Turnstile likely won.
- **CAPTCHA_SOLVER env**. Older versions supported `hcaptcha-solver`; newer versions have deprecated most built-in solvers. If you need image CAPTCHA solving, integrate 2Captcha / Anti-Captcha at the arr-app level, not FlareSolverr.
- **IP reputation matters.** Datacenter IPs (VPS) get hit harder than residential. If even FlareSolverr fails, your VPS IP may be flagged; try a residential proxy or VPN.
- **Rate limits from the target.** Even after bypassing Cloudflare, sites rate-limit by IP. Throttle your indexer calls.
- **Don't expose publicly.** FlareSolverr has no auth. Anyone who can reach port 8191 can use it to proxy requests on your behalf — including abusing other sites from your IP.
- **Run one instance per network.** Multiple parallel FlareSolverrs fighting for IP reputation on the same external IP is counterproductive.
- **ARM64 support** works but can be slower than x86 due to Chromium ARM builds being less optimized.
- **Legal/ethical note.** Bypassing Cloudflare's anti-bot on a site you don't own may violate the site's ToS. Your risk; upstream disclaims liability.
- **Some sites are lost causes.** Rarbg (dead), piratebay (intermittent), GGn / BTN (private trackers with real auth — FlareSolverr doesn't help; they don't use Cloudflare challenges).
- **FlareSolverr v2 → v3 was a rewrite.** v3 dropped some endpoints; if you see 404 on an old API call, check the current v1 (which is still v1 path but v3 internals).
- **Alternatives worth knowing:**
  - **cloudflare-scraper** (Python library) — for embedding in scripts
  - **Byparr** — community fork/alternative, sometimes ahead on Turnstile
  - **Selenium Wire / Playwright + stealth plugins** — DIY
  - **Paid residential proxies** — for serious scraping at scale

## Links

- Repo: <https://github.com/FlareSolverr/FlareSolverr>
- Docker image (GHCR): <https://github.com/FlareSolverr/FlareSolverr/pkgs/container/flaresolverr>
- Docker image (Hub): <https://hub.docker.com/r/flaresolverr/flaresolverr>
- API: <https://github.com/FlareSolverr/FlareSolverr#-api>
- Releases: <https://github.com/FlareSolverr/FlareSolverr/releases>
- Prowlarr proxy guide: <https://wiki.servarr.com/prowlarr/indexers#flaresolverr>
- Issues (common failure modes): <https://github.com/FlareSolverr/FlareSolverr/issues>
