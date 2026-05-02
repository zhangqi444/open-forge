---
name: upvote-rss-project
description: Upvote RSS recipe for open-forge. Self-hosted RSS feed generator for Reddit, Hacker News, Lemmy, Lobsters, PieFed, Mbin, and GitHub trending. Filters posts by score/threshold/posts-per-day. Optional AI summaries, embedded media, and top comments. Upstream: https://github.com/johnwarne/upvote-rss
---

# Upvote RSS

Self-hosted RSS feed generator that surfaces the most popular posts from Reddit, Hacker News, Lemmy, Lobste.rs, PieFed, Mbin, and GitHub trending — with configurable score/volume filtering, embedded media, AI summaries, and top comments. Point your feed reader at the generated URL; Upvote RSS handles everything else.

Upstream: <https://github.com/johnwarne/upvote-rss> | Demo: <https://www.upvote-rss.com>

Built with PHP >= 8.2. Single container, filesystem caching by default. Optional Redis for distributed caching.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose (recommended) | Pre-built image; bind-mount cache dir |
| Any Linux host | `docker run` | Quick start |
| Any host with PHP | Manual / bare metal | PHP >= 8.2 required; open `index.php` in browser |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which host port should Upvote RSS bind to?" | Default: `8675` (maps container `:80`) |
| preflight | "Mount a cache directory?" | Strongly recommended (`./cache:/app/cache`) to persist parsed pages & AI summaries |
| config (Reddit) | "Reddit username, client ID, and client secret?" | Required for subreddit feeds; set up a Reddit 'web app' at reddit.com/prefs/apps |
| config (AI) | "AI summarizer?" | Optional: Ollama, OpenAI, Gemini, Anthropic, Mistral, DeepSeek, or OpenAI-compatible |
| config (Redis) | "Redis host/port?" | Optional; default is filesystem caching |

## Software-layer concerns

### Image

```
ghcr.io/johnwarne/upvote-rss:latest
```

### Compose

```yaml
services:
  upvote-rss:
    image: ghcr.io/johnwarne/upvote-rss:latest
    container_name: upvote-rss
    restart: unless-stopped
    environment:
      - REDDIT_USER=your_reddit_username
      - REDDIT_CLIENT_ID=your_reddit_client_id
      - REDDIT_CLIENT_SECRET=your_reddit_client_secret
      # Optional AI summarizer (pick one):
      # - OPENAI_API_KEY=sk-...
      # - OLLAMA_HOST=http://ollama:11434
      # Optional Redis:
      # - REDIS_HOST=redis
      # - REDIS_PORT=6379
    volumes:
      - upvote-rss-cache:/app/cache
    ports:
      - "8675:80"

volumes:
  upvote-rss-cache:
```

> Source: upstream README — <https://github.com/johnwarne/upvote-rss>

### Reddit app setup

Required before subreddit feeds work:
1. Log into Reddit → <https://www.reddit.com/prefs/apps>
2. Create a new **web app** (any name except names containing "Reddit")
3. `redirect uri` can be any valid URI (e.g. `http://upvote-rss.test`)
4. Copy the **client ID** (shown under the app name) and **client secret**
5. Set `REDDIT_USER`, `REDDIT_CLIENT_ID`, `REDDIT_CLIENT_SECRET` env vars

### Feed filter options

Build a feed URL from the UI. Available filter types:

| Filter | Description |
|---|---|
| **Score** | Filter posts below a fixed score threshold |
| **Threshold** | Use % of the community's monthly average score — more consistent across volatile communities. Not available for Lobsters. |
| **Posts Per Day** | Target a daily volume of posts based on community history — most useful for most cases |

### Supported platforms

- **Reddit** — subreddits (requires API credentials)
- **Hacker News** — Front Page, Best, New, Ask, Show
- **Lemmy** — any community on any instance (specify FQDN)
- **Lobste.rs** — all posts, by category, or by tag
- **PieFed** — communities (specify FQDN)
- **Mbin** — magazines (specify FQDN)
- **GitHub** — trending repos by language and/or topic (`+` = AND, `,` = OR)

### Caching

Three caching backends (auto-selected based on what's available):

| Backend | When used |
|---|---|
| Filesystem (`/app/cache`) | Default — bind-mount to persist across container updates |
| Redis | Set `REDIS_HOST` + `REDIS_PORT`; best for distributed/multi-instance |
| APCu | Auto-used when available for auth tokens and progress tracking |

> Bind-mount the cache directory. Container updates will otherwise clear all cached parsed pages and AI summaries.

Control cache clearing: set `CLEAR_WEBPAGES_WITH_CACHE=false` to protect AI-generated summaries from being wiped when you click "Refresh cache."

### AI summarizer options

Set **one** of these env vars:

| Provider | Env var |
|---|---|
| Ollama (local) | `OLLAMA_HOST=http://ollama:11434` |
| OpenAI | `OPENAI_API_KEY=sk-...` |
| Google Gemini | `GOOGLE_GEMINI_API_KEY=...` |
| Anthropic | `ANTHROPIC_API_KEY=...` |
| Mistral | `MISTRAL_API_KEY=...` |
| DeepSeek | `DEEPSEEK_API_KEY=...` |
| OpenAI-compatible | `OPENAI_COMPATIBLE_HOST=...` + `OPENAI_COMPATIBLE_API_KEY=...` |

### Feed URL format

Example Reddit feed URL with all features enabled:
```
https://your-instance/?platform=reddit&subreddit=technology&averagePostsPerDay=3&showScore&content&summary&comments=5&filterPinnedComments&blurNSFW&filterOldPosts=7
```

Generate the URL from the web UI — it handles all parameter encoding.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

If using a named volume for cache, data persists. If using a bind mount, data persists. Either way, no data loss on upgrade.

## Gotchas

- **Reddit API credentials are required for subreddit feeds** — without them, Reddit feeds won't work. No credentials needed for Hacker News, Lobsters, or GitHub.
- **Bind-mount the cache directory** — without it, container updates clear all cached parsed pages and expensive AI summaries.
- **AI summaries can be slow and costly** — especially with hosted providers + "Include article content" enabled. Consider using Ollama for local, cost-free summaries.
- **`CLEAR_WEBPAGES_WITH_CACHE=false`** — set this if you have AI summaries you don't want regenerated every time you refresh the cache.
- **Feed generation can take time** — first-load with both "Include article content" and "Include summary" enabled is slow. Feed readers should use long timeouts or async polling.
- **Reddit API app name must not contain "Reddit"** — enforced by Reddit's ToS during app creation.
- **Lemmy/PieFed/Mbin require the full instance domain** — e.g. `lemmy.world`, not just `lemmy`.

## Links

- Upstream README: <https://github.com/johnwarne/upvote-rss>
- Demo instance: <https://www.upvote-rss.com>
