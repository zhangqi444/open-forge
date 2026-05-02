---
name: feedcord-project
description: FeedCord recipe for open-forge. RSS/YouTube → Discord webhook bridge. Pushes new feed items as rich embeds to one or more Discord channels/Forum channels. Configured entirely via a single JSON file; no database, no web UI. Docker (recommended) or .NET SDK from source.
---

# FeedCord

Self-hosted RSS and YouTube feed reader that delivers new items to Discord via webhooks. Supports multiple simultaneous feed instances, Forum Channel gallery mode, YouTube channel URLs, and per-instance customisation (colour, description limit, Markdown formatting, persistence across restarts).

**Official URL:** <https://github.com/Qolors/FeedCord>

## Compatible runtimes

| Method | Image / runtime | When to use |
|---|---|---|
| Docker (recommended) | `qolors/feedcord:latest` | Production; one command, no build required. |
| Build from source | .NET SDK (any current LTS) | Dev / customisation. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Which Discord channel(s) should receive feed updates?" | One webhook URL per instance/channel. |
| config | "What RSS/Atom feed URLs do you want to follow?" | Comma-separated list; YouTube channel home URLs also accepted. |
| config | "Any YouTube channels to track?" | FeedCord converts the channel URL to an XML feed; alternatively use the `feeds.xml?channel_id=…` direct URL for reliability. |
| config | "How often should FeedCord check for new items? (minutes, default 25)" | `RssCheckIntervalMinutes` field. |
| config | "Is this a Discord Forum Channel?" | Enables gallery-style display with custom thread creation. Set `"Forum": true`. |
| config | "Optional: custom accent colour for embeds? (decimal integer, default 8411391)" | `Color` field. Use a decimal colour value. |

## Software-layer concerns

### `appsettings.json` structure

Create a folder (e.g. `~/feedcord/`) and place `appsettings.json` inside:

```json
{
  "Instances": [
    {
      "Id": "My News Feed",
      "YoutubeUrls": [
        "https://www.youtube.com/@SomeChannel"
      ],
      "RssUrls": [
        "https://example.com/rss",
        "https://anotherblog.net/feed"
      ],
      "Forum": false,
      "DiscordWebhookUrl": "https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN",
      "RssCheckIntervalMinutes": 25,
      "EnableAutoRemove": false,
      "Color": 8411391,
      "DescriptionLimit": 250,
      "MarkdownFormat": false,
      "PersistenceOnShutdown": true
    }
  ],
  "ConcurrentRequests": 40
}
```

Multiple instances in the `"Instances"` array → multiple Discord channels/webhooks.

Full list of all 17 `appsettings.json` properties: <https://github.com/Qolors/FeedCord/blob/master/FeedCord/docs/reference.md>

### Data directory / volumes

FeedCord stores no database — persistence across restarts is handled by `"PersistenceOnShutdown": true`, which writes a local state file at shutdown. Mount only the config file.

### Docker run

```bash
docker run -d \
  --name FeedCord \
  --restart unless-stopped \
  -v "/path/to/your/appsettings.json:/app/config/appsettings.json" \
  qolors/feedcord:latest
```

No port exposure required — FeedCord is outbound-only (pushes to Discord).

## Upgrade procedure

```bash
docker pull qolors/feedcord:latest
docker stop FeedCord && docker rm FeedCord
# Re-run the docker run command above
```

No database migrations; the config file is forward-compatible.

## Gotchas

- **YouTube URL reliability** — The channel home URL (`https://www.youtube.com/@Handle`) can silently fail to resolve the RSS feed. Prefer the direct XML URL: `https://www.youtube.com/feeds/videos.xml?channel_id=<CHANNEL_ID>`. Use an online tool (e.g. [tunepocket](https://www.tunepocket.com/youtube-channel-id-finder/)) to find the channel ID.
- **Webhook URL is sensitive** — Treat `DiscordWebhookUrl` as a secret. Anyone with the URL can post to your channel.
- **`PersistenceOnShutdown: true` prevents duplicates** — Without it, restarting FeedCord re-sends all recent feed items. Keep it `true` in production.
- **Forum Channels** — Set `"Forum": true` for gallery-style thread creation. Regular text channels use `"Forum": false`.
- **No web UI** — All configuration is via `appsettings.json`. Restart the container after any config change.
- **`ConcurrentRequests`** — Controls parallelism when polling many feeds. Lower if you see rate-limit errors from feed sources.

## Links

- GitHub: <https://github.com/Qolors/FeedCord>
- Docker Hub: <https://hub.docker.com/r/qolors/feedcord>
- appsettings.json reference: <https://github.com/Qolors/FeedCord/blob/master/FeedCord/docs/reference.md>
- awesome-rss-feeds (starter list): <https://github.com/plenaryapp/awesome-rss-feeds>
