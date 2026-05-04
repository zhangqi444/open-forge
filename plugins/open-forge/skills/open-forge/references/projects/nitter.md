---
name: nitter
description: Nitter recipe for open-forge. Privacy-focused alternative Twitter/X front-end. No JavaScript, no ads, no tracking. RSS feeds for any Twitter profile.
---

# Nitter

Free and open-source alternative Twitter/X front-end focused on privacy. All requests go through the backend — the client never talks to Twitter directly. No JavaScript, no ads, no tracking fingerprint.

> ⚠️ **Requires real Twitter/X accounts:** Since Twitter removed unauthenticated API access, Nitter instances require real Twitter account session tokens to function. Guest-only access no longer works. See [Creating session tokens](https://github.com/zedeus/nitter/wiki/Creating-session-tokens).

Upstream: <https://github.com/zedeus/nitter>. Written in Nim.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Source build (Nim) | Custom patches or ARM builds |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Twitter/X session tokens?" | Required — see wiki link above for how to extract them |
| preflight | "Hostname for your Nitter instance?" | Set in `nitter.conf` as `hostname` |
| optional | "Redis connection?" | Optional caching; improves performance |

## Docker Compose example

```yaml
version: "3.9"
services:
  nitter:
    image: zedeus/nitter:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./nitter.conf:/src/nitter.conf:ro
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --save "" --appendonly no
```

### nitter.conf (minimal)

```ini
[Server]
hostname = "nitter.example.com"
port = 8080
https = true

[Cache]
listMinutes = 240
rssMinutes = 10
redisHost = "redis"
redisPort = 6379

[Tokens]
# Add one or more extracted session tokens:
[[Tokens.guestTokens]]
auth_token = "your-auth-token-here"
csrf_token = "your-csrf-token-here"
```

## Software-layer concerns

- Port: `8080` (configurable in `nitter.conf`)
- Redis recommended for caching — reduces Twitter API calls and improves response time
- Session tokens must be extracted from real Twitter/X accounts (see [wiki](https://github.com/zedeus/nitter/wiki/Creating-session-tokens)); tokens expire and must be refreshed periodically
- RSS feeds available at `https://nitter.example.com/<username>/rss` — useful for following users without a Twitter account
- No data stored beyond Redis cache; stateless beyond config

## Upgrade procedure

1. `docker compose pull nitter`
2. `docker compose up -d nitter`
3. Check `nitter.conf` for any new config keys in the release notes

## Gotchas

- **Token maintenance:** Twitter session tokens expire; instances go dark when tokens expire. Automate token refresh or monitor the instance
- **Rate limiting:** Twitter aggressively rate-limits — avoid very high-traffic public instances
- **Twitter API changes:** Twitter/X has repeatedly changed their API in ways that break Nitter; check the GitHub issues before deploying
- Not suitable for use as a replacement for full Twitter functionality — replies, DMs, posting are not supported
- Put behind a reverse proxy with TLS; Nitter itself does not handle HTTPS

## Links

- GitHub: <https://github.com/zedeus/nitter>
- Docker Hub: <https://hub.docker.com/r/zedeus/nitter>
- Session token guide: <https://github.com/zedeus/nitter/wiki/Creating-session-tokens>
- Instance list: <https://github.com/zedeus/nitter/wiki/Instances>
