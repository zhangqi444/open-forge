---
name: RSS-Bridge
description: "Generates RSS/Atom feeds for websites that don't publish one. 500+ built-in 'bridges' (Twitter, Instagram, Mastodon, Facebook, LinkedIn, Reddit-subs, YouTube-channels, news sites, blogs). PHP; no DB. Stateless; behind a reverse proxy. MIT."
---

# RSS-Bridge

RSS-Bridge is "the missing RSS feed for the website-that-never-gave-you-one." It's a PHP web app that scrapes/adapts a target site into a proper RSS/Atom/MRSS/JSON-feed feed. Pair it with Miniflux, FreshRSS, Tiny Tiny RSS, or any feed reader → suddenly you can subscribe to YouTube channels, Twitter/X accounts (when possible), Reddit subs, Mastodon timelines, Instagram users, LinkedIn company pages, arbitrary news sites, shops, and so on.

Each **bridge** is a PHP class that knows how to parse one site. The project ships 500+ bridges maintained by the community. You can write your own in ~50 lines of PHP.

Features:

- **500+ bridges** — massive catalog at <https://rss-bridge.org/bridge01/>
- **Output formats** — Atom (default), RSS 2.0, MRSS, JSON, HTML, plaintext
- **Stateless** — no DB, no persistent storage needed
- **Self-hosted or hosted instance** — many public hosted instances exist
- **Caching** — file or memcached; adjustable TTL to avoid hammering upstream
- **Whitelist/blacklist** — restrict which bridges users can call
- **Bridge autoloader** — just drop a new `XBridge.php` file in `bridges/`
- **API** — structured query params; URLs are copy-paste-able

- Upstream repo: <https://github.com/RSS-Bridge/rss-bridge>
- Hosted instance list: <https://github.com/RSS-Bridge/rss-bridge/wiki/Public-Hosts>
- Docs: <https://rss-bridge.github.io/rss-bridge/>
- Docker Hub: <https://hub.docker.com/r/rssbridge/rss-bridge>

## Architecture in one minute

- **PHP 7.4+ / 8.x** (Composer-managed)
- **No DB** — config + whitelist files on disk; stateless
- **Caching**: file (default), memcached, sqlite (some plugins)
- **Reverse proxy friendly** — run behind nginx/Apache/Caddy with TLS
- **Resource use**: tiny — can run on a VPS with 128 MB RAM
- **Per-request**: spawns one PHP process, fetches target, parses, returns feed

## Compatible install methods

| Infra       | Runtime                                           | Notes                                                           |
| ----------- | ------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | **Docker (`rssbridge/rss-bridge`)**                   | **Simplest**                                                        |
| Single VM   | Native LAMP/LEMP                                        | Standard PHP deploy                                                     |
| Shared host | cPanel PHP; drop into `public_html`                       | Works                                                                       |
| Kubernetes  | Minimal nginx-pod + PHP-FPM sidecar                          | Stateless                                                                        |
| Edge        | Serverless PHP (Bref) — experimental                           | Community                                                                             |

## Inputs to collect

| Input             | Example                       | Phase     | Notes                                                            |
| ----------------- | ----------------------------- | --------- | ---------------------------------------------------------------- |
| Port              | `80`                            | Network   | Behind reverse proxy with TLS                                        |
| Access control    | LAN-only / Basic auth / VPN      | Security  | **Public instances get scraped + abused** — see gotchas                  |
| Timezone          | `Europe/Berlin`                    | Locale    | Used for feed timestamps                                                       |
| Whitelist         | `whitelist.txt` with bridge names    | Config    | Default includes ALL bridges; trim for production                                     |
| Cache TTL         | `3600s` default                        | Perf      | Lower = fresher but more load on upstream                                                     |
| Reverse proxy     | Caddy/Nginx/Traefik                       | Network   | Terminate TLS + add auth                                                                     |

## Install via Docker

```sh
docker run -d --name rss-bridge \
  --restart unless-stopped \
  -p 3000:80 \
  -v /opt/rss-bridge/config:/app/config \
  rssbridge/rss-bridge:latest   # pin specific tag in prod
```

Browse `http://<host>:3000`.

## Install via Docker Compose

```yaml
services:
  rss-bridge:
    image: rssbridge/rss-bridge:2024-02-01   # pin by date tag or commit SHA
    container_name: rss-bridge
    restart: unless-stopped
    ports:
      - "3000:80"
    volumes:
      - ./config:/app/config
      - ./whitelist.txt:/app/whitelist.txt
    environment:
      TZ: UTC
      # Optional: override defaults via env
      # RSSBRIDGE_SYSTEM_ENABLED_DEBUG_MODE: "true"
```

Front with Caddy:

```
rss-bridge.example.com {
    basicauth {
        user <hashed-with-caddy-hash-password>
    }
    reverse_proxy 127.0.0.1:3000
}
```

## Install natively (LAMP/LEMP)

```sh
cd /var/www
git clone https://github.com/RSS-Bridge/rss-bridge.git
chown -R www-data:www-data rss-bridge
cd rss-bridge
cp config.default.ini.php config.ini.php
# Edit config.ini.php: set timezone, enabled_bridges, cache settings, ...

# Nginx → proxy_pass to PHP-FPM with root pointing at /var/www/rss-bridge
# Apache → docroot + FollowSymLinks
```

## Whitelist (important for production)

By default, `whitelist.txt` is empty → ALL bridges enabled. For a public-ish instance:

```sh
cat > config/whitelist.txt << 'EOF'
YoutubeBridge
RedditBridge
MastodonBridge
RumbleBridge
TelegramBridge
# add only what you need
EOF
```

## Using bridges

Via the web UI: browse `/`, find a bridge, fill in params, pick output format (Atom), click "Generate feed". Copy the URL.

Via URL:

```
https://rss-bridge.example.com/?action=display&bridge=YoutubeBridge&context=By+channel+id&c=UCxxxxxxxxxx&duration_min=&duration_max=&format=Atom
```

Subscribe that URL in your feed reader.

## Data & config layout

- `config.ini.php` — global config
- `whitelist.txt` — enabled bridges
- `bridges/` — bridge PHP classes (500+)
- `cache/` — cached fetches (file backend)
- `logs/` — optional
- `custom/` — custom bridges you write

## Backup

Almost nothing to back up — it's stateless. Back up `config.ini.php` + `whitelist.txt` + any `custom/` bridges.

```sh
tar czf rss-bridge-config-$(date +%F).tgz config/ custom/ 2>/dev/null
```

## Upgrade

1. Releases: <https://github.com/RSS-Bridge/rss-bridge/releases>. Very active (bridges break when sites change DOM → frequent patches).
2. Docker: `docker compose pull && docker compose up -d`. Zero state; instant.
3. Native: `git pull` in the install dir.
4. Bridge-level breakage is common when upstream sites change HTML — subscribe to repo or release notifications to pick up fixes fast.
5. Sometimes bridges are deprecated (site goes away, or authors abandon the bridge). The release notes list deprecations.

## Gotchas

- **DON'T run publicly without access control.** A public RSS-Bridge instance becomes an unauthenticated proxy — spammers, scrapers, and abusers love them. At minimum: LAN-only, VPN, Tailscale, or reverse-proxy auth. Public-hosted instances (community-run) absorb this abuse on purpose, but don't run your own open to the internet.
- **Bridges break** — when a target site changes its HTML/API, the bridge fails until someone pushes a fix. RSS-Bridge has hundreds of active contributors, so fixes are usually quick. If you rely on a specific bridge, pin a recent image and set up an RSS-feed-of-the-GitHub-releases (meta).
- **Rate limiting / IP bans** — aggressive polling = upstream sites block your IP. Cache TTL matters. For Twitter/X / Instagram / Facebook specifically, these platforms actively fight scrapers; those bridges are often in a broken state. Mastodon + RSS-native sites (newspapers, blogs, YouTube via their official feeds) are much more reliable.
- **Twitter/X** — historically broken often because Twitter actively blocks. Nitter-based bridges help but Nitter instances also break.
- **Legal gray zone** — scraping Terms of Service violations. For personal use on your data, low-risk. For commercial products or re-publishing, consult a lawyer. Don't host a public RSS-Bridge whose only purpose is enabling ToS violations at scale.
- **PHP process model** — each feed request spawns a PHP process. Large fan-out (500+ subscribers polling every 5 min) can saturate a small VPS. Scale by adding FPM workers + memory or putting a CDN in front.
- **Cache backend choice**: file cache is default and fine for personal use. For high traffic, switch to memcached or Redis.
- **Debug mode leaks info** — never enable in production (`RSSBRIDGE_SYSTEM_ENABLED_DEBUG_MODE=true` only for troubleshooting).
- **User-agent management** — some sites need specific user agents to serve HTML instead of JS shells. Configure per-bridge if needed.
- **Timezone for feed timestamps** — set `date.timezone = UTC` (or your preference) in PHP config for consistent Atom output.
- **Writing a custom bridge** is easy (PHP class with `collectData()` method, ~50 lines). Drop in `bridges/` and it appears in the UI. PR worthy bridges back upstream.
- **Alternative to RSS-Bridge when target site has an API**: write a direct feed generator (e.g., use `yt-dlp` for YouTube, `snscrape` for Twitter archives). RSS-Bridge is the lazy-common path.
- **Feedburner + Google Reader extinction** — RSS-Bridge is part of the ecosystem keeping RSS alive. Contributing is a public good.
- **Companion projects**:
  - **YouTube-RSS-Tool** — dedicated YouTube-feed tool
  - **Nitter** — Twitter RSS/HTML (often unstable because of Twitter's blocks)
  - **PipedAPI** / **Invidious** — YouTube alternatives with RSS (separate recipes)
  - **Mastodon** — natively has per-user RSS at `<instance>/@user.rss`
- **Docker tags**: `latest` exists but pinning to a date-based tag (`2024-02-01`) or commit SHA is safer for production because bridges break/change constantly.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **FreshRSS + its own "scraping" plugins** — handle simple cases without RSS-Bridge
  - **MonitoRSS** — Discord bot that posts feed items
  - **Huginn** — agent-based; more general (scraping + automation); heavier (separate recipe)
  - **n8n / Node-RED** — low-code automation; can build RSS generators
  - **sift.sh / changedetection.io** — "monitor URL for changes, emit RSS/webhook"; different use case (separate recipe)
  - **Yarr** — minimal RSS reader itself (not a bridge)
  - **Choose RSS-Bridge if:** you want to feed-ify 500+ known sites with zero code.
  - **Choose changedetection.io if:** you want generic "monitor this URL diff" as RSS.
  - **Choose Huginn if:** you want programmable agents doing more than feeds.

## Links

- Repo: <https://github.com/RSS-Bridge/rss-bridge>
- Bridge catalog: <https://rss-bridge.org/bridge01/>
- Docs: <https://rss-bridge.github.io/rss-bridge/>
- Docker Hub: <https://hub.docker.com/r/rssbridge/rss-bridge>
- Releases: <https://github.com/RSS-Bridge/rss-bridge/releases>
- Public host list: <https://github.com/RSS-Bridge/rss-bridge/wiki/Public-Hosts>
- Writing a bridge: <https://rss-bridge.github.io/rss-bridge/For_Developers/Create_your_own_bridge.html>
- Matrix chat: <https://matrix.to/#/#rss-bridge:matrix.org>
- Translation: <https://hosted.weblate.org/projects/rss-bridge/>
