# Youlag

**What it is:** FreshRSS extension that modernizes the interface for watching YouTube and reading article RSS feeds. Provides a distraction-free, algorithm-free YouTube subscription experience via RSS — no Google account required. Adds a video-tailored layout, miniplayer, video chapters, and thumbnail replacement.

**GitHub:** https://github.com/civilblur/youlag  
**License:** GNU GPL v3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any FreshRSS install | Extension (PHP) | Requires FreshRSS ≥ 1.28.0 |
| Docker (FreshRSS container) | Extension file copy | Copy extension folder into FreshRSS extensions dir |
| Bare metal FreshRSS | Extension file copy | Same process |

> **Note:** Youlag is a FreshRSS extension, not a standalone app. You need FreshRSS installed first.

---

## Prerequisites

- FreshRSS **1.28.0 or higher**
- A working FreshRSS installation (self-hosted)

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| FreshRSS extensions path | Typically `freshrss/extensions/` on your server |
| Youlag release zip | Download from GitHub releases |

---

## Install Procedure

1. Update FreshRSS to `1.28.0` or higher
2. Download the [latest release](https://github.com/civilblur/youlag/releases)
3. Unzip — you'll get a folder named `xExtension-Youlag`
4. Move `xExtension-Youlag` into your FreshRSS extensions directory: `freshrss/extensions/`
5. In FreshRSS: **Settings → Extensions** → enable **Youlag**
6. Click the ⚙️ gear icon to configure settings

### Docker volume path example
```bash
docker cp xExtension-Youlag freshrss:/var/www/FreshRSS/extensions/
```

---

## Software-Layer Concerns

- **No database of its own** — all data lives in FreshRSS
- **Extension settings** are stored in FreshRSS user preferences
- **YouTube subscriptions** are added as RSS feeds using YouTube's RSS URL format:  
  `https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID`
- No YouTube account or Google login required — purely RSS-based
- Works with [Invidious](https://invidious.io/) as a YouTube proxy alternative

---

## Upgrade Procedure

1. Delete old extension: `freshrss/extensions/xExtension-Youlag`
2. Download new release zip
3. Extract and copy `xExtension-Youlag` to `freshrss/extensions/`
4. Re-enable in FreshRSS settings if needed

---

## Features

- Video-tailored browsing interface for YouTube RSS feeds
- Miniplayer: keep video in corner while reading articles
- Video chapters navigation
- Replace clickbait thumbnails with screen captures
- Compatible with [Invidious](https://invidious.io/) for privacy-respecting playback
- Article reading mode for non-video RSS feeds
- Keyboard shortcut: `Esc` or browser Back to exit video/article view

---

## Gotchas

- **FreshRSS must be ≥ 1.28.0** — older versions are not supported
- YouTube RSS feeds don't include video descriptions or chapters by default; chapter support depends on the video's own description format
- Background playback on Firefox for Android requires the [Video Background Play Fix](https://addons.mozilla.org/en-US/firefox/addon/video-background-play-fix/) addon
- This is an extension, not a standalone server — no Docker image; it must be installed into an existing FreshRSS installation

---

## Links

- GitHub: https://github.com/civilblur/youlag
- Releases: https://github.com/civilblur/youlag/releases
- FreshRSS: https://github.com/FreshRSS/FreshRSS
