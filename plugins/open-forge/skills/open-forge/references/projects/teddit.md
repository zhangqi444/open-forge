---
name: teddit
description: Teddit recipe for open-forge. Free and open-source alternative Reddit front-end focused on privacy. No JavaScript, no ads, unofficial API with RSS and JSON support.
---

# Teddit

Free and open-source alternative Reddit front-end focused on privacy. Inspired by Nitter. All requests proxied through the server — no client-to-Reddit direct connections. Provides an unofficial API with RSS and JSON support.

> ℹ️ **Main repository:** GitHub repo is a mirror only. Primary development at <https://codeberg.org/teddit/teddit>.

Upstream: <https://codeberg.org/teddit/teddit> (mirror: <https://github.com/teddit-net/teddit>).

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Source build (Node.js) | Custom patches |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain / hostname for your Teddit instance?" | Set as `domain` in config |
| optional | "Reddit API credentials?" | Optional; Teddit can operate without a Reddit API key (using Reddit's public JSON endpoints) or with one for higher rate limits |

## Docker Compose example

```yaml
version: "3.9"
services:
  teddit:
    image: teddit/teddit:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DOMAIN: teddit.example.com
      REDIS_HOST: redis
      USE_REDDIT_OAUTH: "false"
      # Optional Reddit OAuth (for higher rate limits):
      # REDDIT_APP_ID: your-app-id
      # REDDIT_APP_SECRET: your-app-secret
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --save "" --appendonly no
```

## Software-layer concerns

- Port: `8080`
- Redis required for caching API responses
- `USE_REDDIT_OAUTH=false` uses Reddit's public JSON API (no credentials); subject to lower rate limits
- `USE_REDDIT_OAUTH=true` requires a Reddit app registered at <https://www.reddit.com/prefs/apps>
- No persistent data beyond Redis cache — stateless
- Unofficial Teddit API available at `/r/<subreddit>.json`, `/<user>.json`, etc.

## Upgrade procedure

1. `docker compose pull teddit`
2. `docker compose up -d teddit`
3. No migration needed — stateless

## Gotchas

- Reddit periodically changes their internal API/JSON structure, which can break Teddit — check Codeberg issues for status
- Without OAuth, heavy usage may trigger Reddit rate limiting for your server's IP
- Teddit does not support posting, voting, or authentication to Reddit — read-only front-end
- Put behind a reverse proxy with TLS; Teddit does not handle HTTPS
- Docker image at `teddit/teddit` on Docker Hub; check Codeberg releases for up-to-date tags

## Links

- Codeberg (primary): <https://codeberg.org/teddit/teddit>
- GitHub (mirror): <https://github.com/teddit-net/teddit>
- Docker Hub: <https://hub.docker.com/r/teddit/teddit>
