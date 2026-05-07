---
name: feedmixer
description: FeedMixer recipe for open-forge. Micro web service that merges multiple RSS/Atom/JSON feeds into one. Python WSGI app. Docker or gunicorn. WTFPL. Source: https://github.com/cristoper/feedmixer
---

# FeedMixer

Tiny Python WSGI web service that takes a list of feed URLs and returns a merged feed of the most recent N entries from each source. Returns Atom, RSS 2.0, or JSON Feed (v1.1). Useful for building personal "planet"-style aggregators or combining topic feeds. In-memory cache, configurable CORS, configurable timeout. Docker or gunicorn deployment. WTFPL licensed.

Upstream: https://github.com/cristoper/feedmixer

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker | Official Dockerfile (Alpine, ~60MB) |
| Any | gunicorn + venv | Manual Python deployment |
| Any | Any WSGI server | uWSGI, mod_wsgi, etc. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 8000 |
| config (optional) | FM_LOG_LEVEL | Log verbosity (default: WARNING; e.g. DEBUG, INFO, ERROR) |
| config (optional) | FM_ALLOW_CORS | Set to any non-empty value to enable CORS headers |
| config (optional) | FM_TIMEOUT | Request timeout in seconds (default: 60) |
| config (optional) | FM_CACHE_SIZE | Number of parsed feed results to cache in memory (default: 8) |

## API

FeedMixer exposes three endpoints:

| Endpoint | Returns |
|---|---|
| GET /atom | Atom feed |
| GET /rss | RSS 2.0 feed |
| GET /json | JSON Feed v1.1 |

Query parameters:

- `f` — URL-encoded feed URL. Repeat for multiple feeds.
- `n` — Number of entries to include per feed (0 = all, default: all).
- `full` — If set, prefer full entry content over summary.

Example (fetch 1 entry each from two feeds as Atom):

```
http://localhost:8000/atom?f=https%3A//hnrss.org/newest&f=https%3A//lobste.rs/rss&n=1
```

## Install -- Docker

```bash
git clone https://github.com/cristoper/feedmixer.git
cd feedmixer
docker build . -t feedmixer

# Run:
docker run --rm -p 8000:8000 feedmixer

# With options:
docker run --rm -p 8000:8000 \
  -e FM_LOG_LEVEL=INFO \
  -e FM_ALLOW_CORS=1 \
  -e FM_TIMEOUT=20 \
  feedmixer
```

## Install -- gunicorn (venv)

```bash
git clone https://github.com/cristoper/feedmixer.git
cd feedmixer
uv venv
. .venv/bin/activate
uv sync
uv pip install gunicorn
gunicorn feedmixer_wsgi
# Listening on port 8000
```

## Upgrade procedure

```bash
git pull
uv sync
# Restart gunicorn or rebuild Docker image
```

## Gotchas

- URL-encode the `f` parameter: when building request URLs programmatically, the feed URLs passed as `f` must be percent-encoded; raw `&` and `?` in feed URLs will break query string parsing.
- In-memory cache only: the cache does not persist across restarts. Cold-start requests will always hit upstream feeds.
- No authentication: FeedMixer has no built-in auth. If you expose it publicly, consider putting it behind a reverse proxy with basic auth or firewall restrictions.
- Podcast / enclosure support: since v2.1.0, RSS enclosures and Atom links are included in output, making it suitable for aggregating podcast feeds.
- JSON Feed v1.1: the JSON output conforms to JSON Feed v1.1 since v2.0.0. Clients expecting the older ad-hoc format should use the v1 branch.

## Links

- Source: https://github.com/cristoper/feedmixer
- JSON Feed spec: https://jsonfeed.org/
