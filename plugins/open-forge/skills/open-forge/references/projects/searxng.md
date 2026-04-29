---
name: searxng-project
description: SearXNG recipe for open-forge. AGPL-3.0 privacy-respecting metasearch engine — aggregates results from 230+ search engines (Google, Bing, DuckDuckGo, YouTube, Wikipedia, GitHub, Stack Overflow, Mojeek, Reddit, arxiv, etc.) without tracking users. Fork of searx. Canonical upstream is `searxng/searxng`. Deploy methods: the NEW "compose-instancing" pattern in the main repo's `container/` dir (the old `searxng-docker` repo is deprecated), manual Docker run, script install, apt/yum, Nix, uWSGI/Granian behind nginx/Apache, and Kubernetes. Pairs with Valkey (Redis fork) for rate limiting + query caching. Covers all install methods plus the mandatory `settings.yml` + `secret_key` setup, public-instance safety, and the limiter/bot-protection posture.
---

# SearXNG

AGPL-3.0 privacy-respecting metasearch engine. Upstream: <https://github.com/searxng/searxng>. Docs: <https://docs.searxng.org>. Public instances list: <https://searx.space>.

Queries the user → SearXNG → proxies to many upstream search engines → aggregates + de-dupes results → returns to user. Upstream engines see only the SearXNG instance's IP; the user never directly contacts Google / Bing / etc. No JavaScript required on the user side (optional UI enhancements only); no tracking, no cookies by default, no account system.

**Fork lineage:** searx (original, maintenance mode) → searxng (active fork, current upstream) → many public instances run SearXNG.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| **Compose instancing** (`container/docker-compose.yml` in main repo) | ✅ Recommended | Most self-hosters. This is the CURRENT canonical Docker path. |
| Manual Docker run | <https://docs.searxng.org/admin/installation-docker.html> | ✅ | Custom Docker setups. |
| Installation script (bare-metal) | <https://docs.searxng.org/admin/installation-scripts.html> | ✅ | VPS install, systemd service via uWSGI/Granian + nginx/Apache. |
| `searxng-docker` repo | <https://github.com/searxng/searxng-docker> | ⚠️ **Deprecated** | Do NOT use for new installs. Migrate existing to compose-instancing. |
| Debian/Ubuntu apt | `searxng` package (may lag) | Community | Debian-based hosts. |
| Nix / NixOS | NixOS module | Community | NixOS hosts. |
| Kubernetes | <https://github.com/searxng/searxng-helm-chart> | Community chart | K8s. |
| Public instance | <https://searx.space> | Free | Don't self-host at all. Pick one with a good uptime score. |

**DockerHub now applies pull rate limits on unauthenticated pulls.** Upstream recommends GHCR mirror: `ghcr.io/searxng/searxng` as an alternative to `docker.io/searxng/searxng`.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose (recommended)` / `docker-manual` / `script-bare-metal` / `kubernetes` | Drives section. |
| dns | "Public hostname?" | e.g. `search.example.com` | Sets `base_url` in `settings.yml`. |
| ports | "Exposed port?" | Default `8080` | Bind to `127.0.0.1:8080` if behind reverse proxy. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `nginx` / `traefik` / `none` | Required for HTTPS / public instance. |
| secret | "Secret key?" | Random 64+ chars | REQUIRED in `settings.yml` — `secret_key`. Do not use the default. |
| cache | "Valkey / Redis URL?" | Default `valkey://searxng-valkey:6379/0` (compose-instancing defaults) | For rate-limiter + image-proxy cache. Optional but strongly recommended. |
| limiter | "Enable bot/abuse limiter?" | Boolean, default `true` for public instances | Rate-limits per-IP, detects scrapers. |
| locale | "Default language + locale?" | Defaults: `en-US` | Language prefs are per-session via cookie / URL param. |
| engines | "Any engines to disable?" | Free-text | Some engines (Yandex, Google in some jurisdictions) have quirks; defaults are safe. |
| instance | "Public or private instance?" | `AskUserQuestion`: `private (auth-wall)` / `public (list on searx.space)` | Different security posture. |

## Install — Compose instancing (canonical)

Upstream-documented procedure:

```bash
mkdir -p ./searxng/core-config/
cd ./searxng/

# Fetch the current compose + env template from main repo
curl -fsSL \
  -O https://raw.githubusercontent.com/searxng/searxng/master/container/docker-compose.yml \
  -O https://raw.githubusercontent.com/searxng/searxng/master/container/.env.example

cp -i .env.example .env
# Edit .env:  set SEARXNG_VERSION, optionally SEARXNG_HOST / SEARXNG_PORT
$EDITOR .env

docker compose up -d
# Visit http://localhost:8080
```

The compose file (shipped upstream) is deliberately minimal:

```yaml
# container/docker-compose.yml (upstream)
name: searxng

services:
  core:
    container_name: searxng-core
    image: docker.io/searxng/searxng:${SEARXNG_VERSION:-latest}
    restart: always
    ports:
      - ${SEARXNG_HOST:+${SEARXNG_HOST}:}${SEARXNG_PORT:-8080}:${SEARXNG_PORT:-8080}
    env_file: ./.env
    volumes:
      - ./core-config/:/etc/searxng/:Z
      - core-data:/var/cache/searxng/

  valkey:
    container_name: searxng-valkey
    image: docker.io/valkey/valkey:9-alpine
    command: valkey-server --save 30 1 --loglevel warning
    restart: always
    volumes:
      - valkey-data:/data/

volumes:
  core-data:
  valkey-data:
```

### Configure `core-config/settings.yml`

First start creates `./core-config/settings.yml` from defaults. Then customize:

```yaml
# core-config/settings.yml (excerpt)
use_default_settings: true   # inherit defaults; only override what you change

general:
  instance_name: "Private SearXNG"
  privacypolicy_url: false
  donation_url: false
  contact_url: false

server:
  port: 8080
  bind_address: "0.0.0.0"
  secret_key: "CHANGE-ME-LONG-RANDOM-STRING-64-PLUS-CHARS"  # REQUIRED
  base_url: "https://search.example.com/"
  image_proxy: true

ui:
  static_use_hash: true
  default_theme: simple
  theme_args:
    simple_style: auto   # auto/light/dark

redis:
  url: valkey://searxng-valkey:6379/0

limiter: true            # enable the bot-detection limiter (good for public instances)

search:
  safe_search: 0         # 0 none, 1 moderate, 2 strict
  autocomplete: duckduckgo

engines:
  - name: google
    disabled: false
  - name: bing
    disabled: false
  # ... override per-engine settings as needed
```

Full settings reference: <https://docs.searxng.org/admin/settings/index.html>.

Restart after edits:

```bash
docker compose restart core
```

### Updating

```bash
# 1. Refresh templates (occasional; check release notes)
docker compose down
curl -fsSLO \
  https://raw.githubusercontent.com/searxng/searxng/master/container/docker-compose.yml \
  https://raw.githubusercontent.com/searxng/searxng/master/container/.env.example
# Merge any new env vars into your .env

# 2. Pull new image
docker compose pull
docker compose up -d
```

Pin a specific version in `.env` (`SEARXNG_VERSION=2026.3.25-541c6c3cb`) for predictable production upgrades.

## Install — Manual Docker run (no compose)

```bash
mkdir -p ./searxng/config/ ./searxng/data/
cd ./searxng/

docker run --name searxng -d \
  -p 8888:8080 \
  -v "./config/:/etc/searxng/" \
  -v "./data/:/var/cache/searxng/" \
  docker.io/searxng/searxng:latest

# Edit ./config/settings.yml after first run, then:
docker restart searxng
```

## Install — Bare-metal (Debian/Ubuntu) via official script

```bash
# One-command install (examines the script before running is strongly recommended)
curl -fsSL https://raw.githubusercontent.com/searxng/searxng/master/utils/searxng.sh | sudo bash -s -- install all
```

This installs: uWSGI + SearXNG + nginx site + systemd units. Config lives at `/etc/searxng/`. See <https://docs.searxng.org/admin/installation-scripts.html>.

## Reverse proxy (Caddy)

```caddy
search.example.com {
    reverse_proxy searxng-core:8080
}
```

Ensure `settings.yml`'s `server.base_url` matches the public URL (including trailing slash!).

## Migrate from deprecated `searxng-docker` → compose-instancing

Upstream procedure: <https://docs.searxng.org/admin/installation-docker.html#migrate-from-searxng-docker>.

Rough sketch:

```bash
# 1. Stop old stack
cd /path/to/searxng-docker
docker compose down

# 2. Create new compose-instancing dir
mkdir -p ~/searxng/core-config/
cd ~/searxng/
curl -fsSL -O https://raw.githubusercontent.com/searxng/searxng/master/container/docker-compose.yml
curl -fsSL -O https://raw.githubusercontent.com/searxng/searxng/master/container/.env.example
cp .env.example .env

# 3. Copy settings.yml from old to new
cp /path/to/searxng-docker/searxng/settings.yml ./core-config/

# 4. Start
docker compose up -d
```

Old data cache is disposable; settings + secret_key are what matter.

## Data layout

| Path (compose-instancing) | Content |
|---|---|
| `./core-config/settings.yml` | Main config |
| `./core-config/limiter.toml` | Optional — limiter overrides |
| `core-data` volume → `/var/cache/searxng/` | App cache (throwable) |
| `valkey-data` volume → `/data/` | Rate-limiter counters + query cache |

Zero PII stored by default (no user accounts, no history). Only `valkey-data` contains rate-limit counters keyed by IP.

**Backup** = tar `./core-config/` (tiny). Cache + valkey are fully rebuildable.

## Upgrade procedure

```bash
# Check release notes
# https://github.com/searxng/searxng/releases

docker compose pull
docker compose up -d
docker compose logs -f core
```

Settings-schema changes are rare but DO happen. Watch for deprecation warnings on startup.

## Public instance vs private instance

| Aspect | Private (LAN / auth-wall) | Public (listed on searx.space) |
|---|---|---|
| Limiter | Optional | **Required.** Enable `limiter: true`. |
| `bot_detection` | Optional | **Required.** |
| `image_proxy` | Optional | **Required.** (otherwise leaks user IP to image-host servers) |
| `admin` contact | Optional | Required to be listed on searx.space. |
| User count | ~5-50 | Can be thousands; plan for load. |
| Upstream bans | Unlikely | Very likely — Google, Bing, etc. ban IPs that search too much. Rotate via Tor or multiple IPs if sustained load. |

For public instances, also review <https://docs.searxng.org/admin/installation-uwsgi.html> for production-hardening tips.

## Gotchas

- **The `searxng-docker` repo is DEPRECATED.** Use `container/` dir of the main repo (compose-instancing). Old tutorials referencing `searxng/searxng-docker` are stale.
- **`secret_key` MUST be set to something unique.** Default `ultrasecretkey` or empty = instance will refuse to start OR will be trivially fingerprintable. Generate: `openssl rand -hex 64`.
- **`server.base_url` must match the public URL EXACTLY**, trailing slash included. Mismatch → broken result URLs (missing CSS, broken links).
- **`image_proxy: true` is important for privacy.** Without it, image thumbnails load directly from upstream hosts (your browser's IP leaks to Google Images / Bing Images / etc.). Costs CPU + bandwidth on your SearXNG instance.
- **Upstream engines ban scraper IPs.** Running a SearXNG instance with heavy traffic from a single datacenter IP → Google returns captcha pages within hours. The limiter mitigates this client-side; server-side, you may need to disable Google or route requests through a pool.
- **DockerHub rate limits** affect unauthenticated pulls. Upstream now recommends `ghcr.io/searxng/searxng` mirror. In your compose, swap the image if you hit limits.
- **Valkey vs Redis.** SearXNG uses `valkey://` protocol now (Redis fork after Redis's license change). Compose-instancing ships Valkey; older setups may still use `redis://`. Both protocols are wire-compatible.
- **Engines are disabled/enabled via `settings.yml`.** Some engines (Yandex for non-Russian locales, Baidu for non-Chinese locales) return degraded results; disable them. Default engine list is curated but per-locale tuning helps.
- **`use_default_settings: true`** lets your `settings.yml` be small — only overrides. If you omit it, you must provide the ENTIRE defaults, including all engine configs (painful).
- **`limiter: true` requires a valkey/redis.** Without one, limiter is disabled regardless of setting.
- **Session cookies for user prefs.** Users' chosen language / theme / engines persist via cookie. If your reverse proxy strips cookies, prefs don't stick.
- **OpenSearch XML + auto-discovery** is included — browsers can add SearXNG as a search engine automatically. Set `server.base_url` correctly for this to work.
- **`/static/` assets** are served by SearXNG itself. For heavy traffic, offload to nginx (see <https://docs.searxng.org/admin/installation-nginx.html>).
- **Morty** is an optional separate service (<https://github.com/asciimoo/morty>) that proxies result-page content (making "view proxied" links work). Not in default compose; add manually if needed.
- **Legal / ToS:** metasearch engines are in a grey area with upstream providers' ToS. Private instances fine; public high-volume instances may draw cease-and-desist letters from some engines.
- **Don't expose the unauthenticated `http://:8080`** directly on the internet without the limiter. Script-kiddies will use it as a free scraping proxy.
- **Theme changes require a container rebuild** for custom themes — default themes are fine to toggle via `settings.yml`.
- **Weather / formula / calculator** answers come from "engines" too (Wolfram Alpha, Open-Meteo, etc.). Some require API keys; configure in `settings.yml` engine blocks.

## Links

- Upstream repo: <https://github.com/searxng/searxng>
- Docs: <https://docs.searxng.org>
- Container install (compose-instancing): <https://docs.searxng.org/admin/installation-docker.html#compose-instancing>
- Manual Docker: <https://docs.searxng.org/admin/installation-docker.html>
- Bare-metal script: <https://docs.searxng.org/admin/installation-scripts.html>
- uWSGI/Granian production guide: <https://docs.searxng.org/admin/installation-uwsgi.html>
- nginx reverse proxy: <https://docs.searxng.org/admin/installation-nginx.html>
- Settings reference: <https://docs.searxng.org/admin/settings/index.html>
- Public instances: <https://searx.space>
- Deprecated searxng-docker repo: <https://github.com/searxng/searxng-docker>
- Helm chart (community): <https://github.com/searxng/searxng-helm-chart>
- Releases: <https://github.com/searxng/searxng/releases>
- DockerHub: <https://hub.docker.com/r/searxng/searxng>
- GHCR mirror: <https://ghcr.io/searxng/searxng>
- Matrix: <https://matrix.to/#/#searxng:matrix.org>
