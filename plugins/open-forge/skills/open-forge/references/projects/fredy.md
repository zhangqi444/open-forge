---
name: fredy
description: Fredy recipe for open-forge. Self-hosted real estate listing aggregator for Germany. Scrapes ImmoScout24, Immowelt, Immonet, eBay Kleinanzeigen, and WG-Gesucht, deduplicates results, and sends instant notifications via Slack, Telegram, email, ntfy, Discord, and more. Node.js app with web UI. Docker-deployable. Source: https://github.com/orangecoding/fredy
---

# Fredy

Self-hosted real estate listing finder for Germany. Fredy scrapes apartment and house listings from ImmoScout24, Immowelt, Immonet, eBay Kleinanzeigen, and WG-Gesucht on a configurable schedule, deduplicates results across platforms so you never see the same listing twice, and pushes instant notifications via Slack, Telegram, email (SendGrid/Mailjet), ntfy, Discord, and more. Manages searches via a clean web UI. Built on Node.js with Chromium for scraping. Docker image: `ghcr.io/orangecoding/fredy`. Upstream: https://github.com/orangecoding/fredy. Demo: https://fredy-demo.orange-coding.net/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose | Linux | Recommended |
| Docker run | Linux | Single container |
| Node.js (native) | Linux / macOS | npm start |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| notify | "Notification channel(s)?" | Telegram, Slack, email, ntfy, Discord, etc. |
| notify | "Telegram bot token + chat ID?" | If using Telegram |
| notify | "Slack webhook URL?" | If using Slack |
| search | "Configure searches in web UI" | After startup at :9998 |

## Software-layer concerns

### docker-compose.yml

  version: "3"
  services:
    fredy:
      image: ghcr.io/orangecoding/fredy:latest
      container_name: fredy
      restart: unless-stopped
      ports:
        - "9998:9998"
      volumes:
        - ./conf:/conf
        - ./db:/db
      environment:
        - NODE_ENV=production
      deploy:
        resources:
          limits:
            memory: 1G   # Chromium can be memory-hungry

### Start

  mkdir -p conf db
  docker compose up -d
  # Access web UI at http://localhost:9998

### First-run: configure searches via Web UI

  # Navigate to http://localhost:9998
  # 1. Create a new search job:
  #    - Give it a name (e.g. "Berlin 2-room apartment")
  #    - Select providers (ImmoScout24, Immowelt, etc.)
  #    - Enter search URLs from each provider (copy from the provider's website after filtering)
  #    - Set check interval (e.g. every 15 minutes)
  # 2. Configure notification channels:
  #    - Add Telegram, Slack, email, ntfy, Discord, or custom webhook
  # 3. Activate the job

### Configuration storage

  ./conf/   # Search job configs (JSON), persisted via volume
  ./db/     # SQLite deduplication database — seen listing IDs

### Notification channel config examples

  # Telegram:
  #   token: YOUR_BOT_TOKEN
  #   chatId: YOUR_CHAT_ID
  #
  # ntfy:
  #   url: https://ntfy.sh/your-topic
  #   (or self-hosted ntfy instance)
  #
  # Discord:
  #   webhookUrl: https://discord.com/api/webhooks/...
  #
  # Slack:
  #   webhookUrl: https://hooks.slack.com/services/...
  #
  # Email (SendGrid):
  #   apiKey: SG.xxxxx
  #   from: fredy@example.com
  #   to: you@example.com

### Environment variables

  NODE_ENV          production or development
  # Other config is managed entirely through the web UI

### Ports

  9998/tcp   # Web UI and API

### Reverse proxy (nginx)

  location / {
      proxy_pass http://127.0.0.1:9998;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }

## Upgrade procedure

  docker compose pull
  docker compose up -d
  # conf/ and db/ volumes persist across upgrades

## Gotchas

- **Germany-specific**: Fredy only scrapes German real estate platforms (ImmoScout24, Immowelt, Immonet, eBay Kleinanzeigen, WG-Gesucht). It is not useful outside Germany.
- **Search URLs from provider websites**: For each provider, do your filtered search on the provider's website (city, size, price range), then paste the resulting URL into Fredy. Fredy scrapes that URL.
- **Chromium inside container**: Fredy uses Chromium (via Puppeteer) to scrape JavaScript-heavy pages. This is why it needs ~1 GB RAM and may be slower to start.
- **Rate limiting / scraping ethics**: Fredy scrapes third-party sites. Excessive polling intervals may get your IP rate-limited. Use reasonable intervals (15–30 minutes).
- **db/ volume is your deduplication memory**: If you delete the `db/` volume, Fredy will re-send all listings it has already seen. Keep it backed up.
- **Memory limit in compose**: The `memory: 1G` limit prevents runaway Chromium processes from consuming all system RAM. Increase if you have many concurrent search jobs.
- **conf/ volume for persistence**: Job configs are stored in `./conf/`. Back this up if you want to restore your search jobs.

## References

- Upstream GitHub: https://github.com/orangecoding/fredy
- Website: https://fredy.orange-coding.net/
- Demo: https://fredy-demo.orange-coding.net/
- Docker image: https://ghcr.io/orangecoding/fredy
