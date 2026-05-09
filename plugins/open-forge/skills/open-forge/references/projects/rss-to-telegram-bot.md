---
name: rss-to-telegram-bot
description: "Self-hosted RSS to Telegram bot. AGPL-3.0. Rongronggg9. Docker Compose (single container). Converts RSS/Atom/RDF feeds to richly formatted Telegram messages preserving images, video, audio, and formatting. Multi-user, OPML import/export, per-feed proxy settings, Telegraph integration, i18n."
---

# RSS to Telegram Bot (RSStT)

**Self-hosted Telegram bot that converts RSS feeds to rich Telegram messages.** Sends full post content (not just links) with images, video, audio, and proper formatting preserved. Multi-user, with OPML import/export, Telegraph fallback for long posts, and per-feed proxy support. AGPL-3.0.

Built + maintained by **Rongronggg9**.

- Upstream repo: <https://github.com/Rongronggg9/RSS-to-Telegram-Bot>
- Deployment guide: <https://github.com/Rongronggg9/RSS-to-Telegram-Bot/blob/master/docs/deployment-guide.md>
- Docker Hub: <https://hub.docker.com/r/rongronggg9/rss-to-telegram>
- Public bot (optional): <https://t.me/RSStT_Bot>

## Architecture in one minute

- Single Python container (`rongronggg9/rss-to-telegram`)
- Persistent storage in a mounted `./config` directory (SQLite database by default; PostgreSQL supported)
- No web UI — bot is controlled entirely via Telegram commands

## Compatible install methods

| Method | Notes |
|--------|-------|
| **Docker Compose** | **Primary** — single container, config via environment variables |
| PyPI / pip | `pip install rsstt` — for advanced users |
| Railway.app | PaaS deployment (paid plan required) |
| Source | Python — for contributors |

## Prerequisites

1. **Create a Telegram bot** via [@BotFather](https://t.me/BotFather) → `/newbot` → get the bot token
   - Also send `/setinline` to BotFather and enable inline mode for a better UX
2. **Get your Telegram user ID** via [@userinfobot](https://t.me/userinfobot)
3. *(Optional)* **Get Telegraph API tokens** at:
   `https://api.telegra.ph/createAccount?short_name=RSStT&author_name=Generated%20by%20RSStT&author_url=https%3A%2F%2Fgithub.com%2FRongronggg9%2FRSS-to-Telegram-Bot`
   Refresh the page for each additional token (recommended: 5+ tokens for high-volume use)

## Inputs to collect

| Input | Env var | Notes |
|-------|---------|-------|
| Bot token | `TOKEN` | From @BotFather |
| Manager user ID | `MANAGER` | Your Telegram user ID; can be a semicolon-separated list |
| Telegraph tokens | `TELEGRAPH_TOKEN` | Optional; enables sending long posts via Telegraph |
| Database URL | `DATABASE_URL` | Optional; defaults to SQLite at `./config/db.sqlite3` |
| Telegram proxy | `T_PROXY` | Optional; e.g. `socks5://172.17.0.1:1080` |
| Feed proxy | `R_PROXY` | Optional; separate proxy for fetching RSS feeds |

## Install via Docker Compose

### Step 1 — Download the sample Compose file

```bash
mkdir rsstt
cd rsstt
wget https://raw.githubusercontent.com/Rongronggg9/RSS-to-Telegram-Bot/dev/docker-compose.yml.sample -O docker-compose.yml
```

### Step 2 — Edit `docker-compose.yml`

Minimum required configuration:

```yaml
version: '3.6'

services:
  main:
    image: rongronggg9/rss-to-telegram:dev  # or :latest for stable
    container_name: rsstt
    restart: unless-stopped
    volumes:
      - ./config:/app/config
    environment:
      - TOKEN=1234567890:YourBotTokenFromBotFather
      - MANAGER=1234567890  # your Telegram user ID
      # Optional Telegraph tokens (one per line):
      # - TELEGRAPH_TOKEN=
      #   <token1>
      #   <token2>
```

Uncomment additional env vars from the sample file as needed (proxies, cron interval, multi-user toggle, etc.).

### Step 3 — Start the bot

```bash
docker compose up -d
```

### Step 4 — Interact with the bot

Open Telegram, find your bot, send `/start` to begin. Use `/sub <feed-url>` to subscribe to an RSS feed.

## Key features

- **Rich message formatting**: Converts HTML/Markdown to Telegram-native formatting; preserves bold, italic, links
- **Full media support**: Inline images, video, and audio forwarded as Telegram media; oversized images sent as files
- **Telegraph fallback**: Long posts automatically sent as Telegraph articles to bypass Telegram's message length limit
- **Multi-user**: Multiple users can subscribe independently (enabled by default; disable with `MULTIUSER=0`)
- **OPML import/export**: Import and export subscriptions via OPML files
- **Per-feed proxy**: Individual proxy settings per subscription
- **HTTP caching**: Respects `ETag`/`Last-Modified` headers to reduce bandwidth
- **i18n**: English, Chinese (Simplified/Traditional), Cantonese, Italian, and more
- **Customizable formatting**: Hashtags, custom titles, media filtering — see [formatting settings docs](https://github.com/Rongronggg9/RSS-to-Telegram-Bot/blob/master/docs/formatting-settings.md)

## Common bot commands

| Command | Description |
|---------|-------------|
| `/sub <url>` | Subscribe to an RSS feed |
| `/unsub <url>` | Unsubscribe |
| `/list` | List all subscriptions |
| `/import` | Import OPML file |
| `/export` | Export subscriptions as OPML |
| `/set` | Per-feed settings (formatting, media, etc.) |
| `/help` | Show help |

## Advanced settings

Set via environment variables in `docker-compose.yml`:

| Env var | Default | Notes |
|---------|---------|-------|
| `CRON_SECOND` | `0` | Seconds offset for the polling cron (0–59) |
| `DATABASE_URL` | `sqlite://...` | PostgreSQL URL for multi-instance or larger deployments |
| `MULTIUSER` | `1` | Set to `0` to make it a single-user (manager-only) bot |
| `TABLE_TO_IMAGE` | `0` | Set to `1` to render HTML tables as images |
| `IPV6_PRIOR` | `0` | Prefer IPv6 for outbound connections |

Full list: [advanced-settings.md](https://github.com/Rongronggg9/RSS-to-Telegram-Bot/blob/master/docs/advanced-settings.md)

## Updating

```bash
docker compose pull
docker compose up -d
```

## Notes

- Closed-source distribution or bot-hosting is prohibited under AGPL-3.0. If you modify and distribute the bot, the source code must be made available to users.
- The public bot at [@RSStT_Bot](https://t.me/RSStT_Bot) is available but comes with no uptime guarantees; self-hosting is recommended for reliability.
