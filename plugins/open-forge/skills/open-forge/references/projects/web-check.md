---
name: web-check-project
description: Web-Check recipe for open-forge. MIT-licensed OSINT dashboard for analyzing websites — runs 30+ checks (IP/SSL/DNS/headers/cookies/TLS ciphers/DNSSEC/carbon footprint/screenshot/trackers/security headers/mail config/open ports/traceroute/etc) on any URL. Self-host = single stateless container on port 3000. Designed to be deployed as serverless/edge (Netlify/Vercel) or Docker; we focus on Docker. Optional API keys expand coverage (Google Cloud, Shodan, WhoAPI, Tranco, etc). Needs `chromium` for screenshot + some checks — bundled in the Docker image.
---

# Web-Check

MIT-licensed website OSINT dashboard. Upstream: <https://github.com/Lissy93/web-check>. Docs: <https://web-check.xyz/about>. Live demo: <https://web-check.as93.net>.

Give it a URL, get a dashboard of everything that can be learned about the site from outside: IP info, SSL chain, DNS records (A/AAAA/MX/TXT/CAA/NS), cookies, headers, domain WHOIS, `robots.txt` + `sitemap.xml`, server geo, redirect chain, open ports, traceroute, DNSSEC, page performance, trackers, associated hostnames, carbon footprint, security headers, TLS cipher suites + handshake simulation, firewall detection, archive history (Wayback Machine), mail config (SPF/DKIM/DMARC/BIMI), HSTS, screenshot, malicious URL check, and more.

Useful for:

- Security audits / recon of your own assets
- CTF / bug bounty scoping
- "what tech is this site running?" checks
- Comparing two sites side-by-side
- Teaching students about web / DNS / TLS internals

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`lissy93/web-check` on Docker Hub or `ghcr.io/lissy93/web-check`) | ✅ | ✅ Recommended | Self-host. Stateless container on :3000. |
| Netlify (1-click) | ✅ | ✅ | Serverless deployment; free tier fine for personal use. |
| Vercel (1-click) | ✅ | ✅ | Same idea; edge functions. |
| From source (`yarn serve`) | ✅ | ✅ | Contributors / custom. Needs Node.js 18.16+, yarn, Chromium, traceroute, dns. |
| Build Docker image yourself | `docker build -t web-check .` | ✅ | Inspect build. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `netlify` / `vercel` / `source` | Drives section. |
| ports | "Host port?" | Default `3000` | Image listens on `:3000` internally. |
| dns | "Public hostname?" | Free-text, optional | For reverse proxy + TLS. Most people run this LAN-only or single-user. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Web-Check doesn't terminate TLS. Optional for LAN. |
| api-keys | "Optional API keys to configure?" | Multi-select of: `GOOGLE_CLOUD_API_KEY` / `REACT_APP_SHODAN_API_KEY` / `REACT_APP_WHO_API_KEY` / `SECURITY_TRAILS_API_KEY` / `CLOUDMERSIVE_API_KEY` / `TRANCO_*` / `URL_SCAN_API_KEY` / `BUILT_WITH_API_KEY` / `TORRENT_IP_API_KEY` | All optional. Each enables one or more additional checks or lifts rate limits. |
| limits | "Enable API rate-limiting?" | Boolean, default true | `API_ENABLE_RATE_LIMIT=true`. Recommended if public-facing. |
| cors | "CORS allowed origins?" | Free-text | `API_CORS_ORIGIN=example.com`. Leave blank = same-origin only. |
| mode | "API-only (no GUI)?" | Boolean, default false | `DISABLE_GUI=true` if you only want the JSON API. |

## Install — Docker

Minimal run:

```bash
docker run -d \
  --name web-check \
  --restart unless-stopped \
  -p 3000:3000 \
  lissy93/web-check:2.1.0
```

Open `http://<host>:3000/`.

### Docker Compose

```yaml
# compose.yaml
services:
  web-check:
    container_name: web-check
    image: lissy93/web-check:2.1.0     # pin a specific tag in production
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      # Rate-limiting (strongly recommended for public-facing)
      API_ENABLE_RATE_LIMIT: 'true'
      API_TIMEOUT_LIMIT: '10000'
      # Chromium is bundled in the image — path is already correct
      # CHROME_PATH: /usr/bin/chromium
      # Optional API keys (uncomment + fill to enable extra checks)
      # GOOGLE_CLOUD_API_KEY: ''
      # REACT_APP_SHODAN_API_KEY: ''
      # REACT_APP_WHO_API_KEY: ''
      # SECURITY_TRAILS_API_KEY: ''
      # TRANCO_USERNAME: ''
      # TRANCO_API_KEY: ''
      # URL_SCAN_API_KEY: ''
      # BUILT_WITH_API_KEY: ''
```

### Image sources

- Docker Hub: `lissy93/web-check:2.1.0`
- GHCR: `ghcr.io/lissy93/web-check:2.1.0`

Both auto-built from `master` by the `Build + Publish Docker Image` workflow.

## Install — Netlify / Vercel (serverless)

Upstream provides 1-click deploy buttons in the README:

- **Netlify:** `https://app.netlify.com/start/deploy?repository=https://github.com/lissy93/web-check`
- **Vercel:** `https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Flissy93%2Fweb-check&...`

Each fork the repo into your account + deploys. Configure env vars (API keys) in the hosting provider's UI.

**Caveat:** Netlify/Vercel free-tier function timeouts (10-30s) can be too short for some checks (e.g. traceroute, Lighthouse). Self-host via Docker if you need the full feature set.

## Install — From source

```bash
# Prereqs
node --version    # need ≥ 18.16.1
yarn --version
# Also need: chromium, traceroute, dns/dig — checks silently skip without them

git clone https://github.com/Lissy93/web-check.git
cd web-check
yarn install
yarn build
yarn serve           # starts both API + GUI on :3000
# Or:
# yarn dev           # dev mode with live reload
```

## Configuration (all optional)

From the README:

**API keys (enable extra checks or lift rate limits):**

| Env var | Signup | Adds |
|---|---|---|
| `GOOGLE_CLOUD_API_KEY` | <https://cloud.google.com/api-gateway/docs/authenticate-api-keys> | Site quality / Lighthouse metrics |
| `REACT_APP_SHODAN_API_KEY` | <https://account.shodan.io/> | Associated hostnames from Shodan's index |
| `REACT_APP_WHO_API_KEY` | <https://whoapi.com/> | Richer WhoIs records |
| `SECURITY_TRAILS_API_KEY` | <https://securitytrails.com/corp/api> | Org info tied to IP |
| `CLOUDMERSIVE_API_KEY` | <https://account.cloudmersive.com/> | Known-threat IP check |
| `TRANCO_USERNAME` + `TRANCO_API_KEY` | <https://tranco-list.eu/> | Site traffic rank |
| `URL_SCAN_API_KEY` | <https://urlscan.io/> | Miscellaneous site info |
| `BUILT_WITH_API_KEY` | <https://api.builtwith.com/> | Tech stack ID ("main features") |
| `TORRENT_IP_API_KEY` | <https://iknowwhatyoudownload.com/en/api/> | Torrents tied to an IP |

**Runtime settings:**

| Env var | Purpose |
|---|---|
| `PORT` | Port to listen on (default `3000`) |
| `API_ENABLE_RATE_LIMIT` | Enable rate-limiting on `/api/*` endpoints (`true` recommended for public) |
| `API_TIMEOUT_LIMIT` | Per-API-request timeout in ms (default `10000`) |
| `API_CORS_ORIGIN` | Allowed CORS origin(s), e.g. `example.com` |
| `CHROME_PATH` | Path to Chromium binary (default inside image is correct) |
| `DISABLE_GUI` | `true` = API-only, no web UI |
| `REACT_APP_API_ENDPOINT` | Override the API URL the GUI calls (for split deployments) |

## Reverse proxy (Caddy)

```caddy
web-check.example.com {
    reverse_proxy web-check:3000
}
```

Caddy handles TLS + HTTP/2 automatically. No further config needed.

## Data layout

**None.** Web-Check is **stateless** — no DB, no user accounts, no persistent cache. Every check runs fresh per request. Env-var config is the only "state."

No backup required (config + image tag is all you need to reproduce).

## Upgrade procedure

```bash
docker pull lissy93/web-check:2.1.0
docker stop web-check && docker rm web-check
# Re-run docker run OR docker compose up -d
```

`:latest` auto-pulled from upstream CI — pin a specific image digest in production if you want reproducibility.

## Gotchas

- **No authentication.** Anyone who can reach port 3000 can run scans. This is fine for LAN use, BUT:
  - Public exposure = anyone can use you as a scanning proxy. Put auth (Authelia / oauth2-proxy / basic auth) in front, OR rate-limit aggressively.
  - Your server's IP does the outbound scans — if those scans trigger an IDS or WAF at the target, the alert points at YOU. Treat your Web-Check instance like a modest penetration-testing tool and only run it against hosts you own or have authorization to check.
- **Some checks are intrusive.** "Open ports" runs a TCP port scan against the target. "Traceroute" does ICMP probes. Running Web-Check against targets you don't own could trigger their security team's pagers. Use responsibly.
- **Rate-limiting is opt-in.** `API_ENABLE_RATE_LIMIT=true` must be set explicitly; otherwise a single user (or abuser) can hammer external APIs (Shodan, WhoAPI, etc.) and exhaust your key quotas in minutes.
- **`REACT_APP_*` vars are client-visible.** Anything prefixed with `REACT_APP_` (including API keys like `REACT_APP_SHODAN_API_KEY`) is baked into the frontend bundle and visible to anyone inspecting browser network traffic. Use read-only / scoped API keys, and treat these as semi-public.
- **Chromium is memory-hungry.** The Screenshot + Lighthouse checks launch Chromium per request. Under concurrent load, RAM can balloon. Set Docker memory limits (`mem_limit: 2g`) to cap.
- **Netlify / Vercel function timeouts.** Many checks (TLS handshake sim, full port scan, Lighthouse) take 10-30+ seconds. Free-tier serverless functions will time out mid-check. Docker self-host doesn't have this limit.
- **Some checks require specific Linux tools.** `traceroute`, `dig`, `openssl`, `chromium` — all bundled in the Docker image. If building from source, install these on the host.
- **Self-hosted instance is NOT anonymous.** DNS lookups, TCP probes, HTTP fetches all originate from your server's IP. Target sites see your IP in their logs. For anonymity use Tor / proxy per-request (not supported out-of-box).
- **API endpoints are at `/api/<check-name>`.** See <https://web-check.xyz/api-docs> or the `api/` directory in the repo for the list. You can call these directly for scripted monitoring (e.g. in an uptime dashboard).
- **Archives / Wayback Machine check depends on archive.org responsiveness.** Sometimes slow or returns partial data. Not Web-Check's fault.
- **No user accounts, no scan history.** Each scan is ad-hoc. If you want persistent "compliance dashboard"-style tracking over time, Web-Check is the wrong tool — use something like Security Scorecard, SSL Labs continuous monitor, or run Web-Check on a cron + log results elsewhere.
- **Upstream is actively maintained by a single maintainer (Alicia "Lissy" Sykes).** Pace of updates varies; GitHub Sponsors support the hosted instance's $25/mo lambda costs. If you depend on this in production, consider sponsoring or mirroring the image.
- **Mirror caution.** Upstream README mentions there's a mirror at `web-check.xyz`; the hosted `web-check.as93.net` is the original. Community-run mirrors exist but aren't vetted — self-host for privacy-sensitive use.

## Links

- Upstream repo: <https://github.com/Lissy93/web-check>
- Live demo: <https://web-check.as93.net>
- About: <https://web-check.xyz/about>
- Docker Hub: <https://hub.docker.com/r/lissy93/web-check>
- GHCR: <https://github.com/Lissy93/web-check/pkgs/container/web-check>
- README (full check descriptions): <https://github.com/Lissy93/web-check#readme>
- Deploy to Netlify: <https://app.netlify.com/start/deploy?repository=https://github.com/lissy93/web-check>
- Deploy to Vercel: <https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Flissy93%2Fweb-check>
- Issues: <https://github.com/Lissy93/web-check/issues>
- Sponsor: <https://github.com/sponsors/Lissy93>
