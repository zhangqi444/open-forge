---
name: homepage-by-tomershvueli
description: Homepage by tomershvueli recipe for open-forge. Simple self-hosted PHP personal dashboard page with a curated links menu, Unsplash or custom background images, clock, and keyboard shortcut unlock. Single PHP file. Source: https://github.com/tomershvueli/homepage
---

# Homepage (by tomershvueli)

Simple, standalone, self-hosted PHP page as a personal browser homepage. Displays a rotating background (Unsplash API or custom URL), a clock, and a configurable grid of links to your most-used services. Menu is revealed via a configurable keyboard shortcut. All assets bundled in the repo — works offline (without background image fetching). MIT licensed.

> Note: This is a different project from gethomepage.dev. It is a minimalist single-PHP-file dashboard, last active ~2021.

Upstream: <https://github.com/tomershvueli/homepage>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Apache + PHP | Original stack |
| Any | nginx + PHP-FPM | Also works |
| Any | Docker (any PHP image) | Mount as web root |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Links to your services | Array of `{link, icon, alt}` objects in config.json |
| config (optional) | Unsplash client ID | For rotating Unsplash backgrounds; get from developer.unsplash.com |
| config (optional) | Custom background URL + selector | Alternative to Unsplash |
| config (optional) | unlock_pattern | Mousetrap key sequence to show menu |
| config (optional) | clock_format | PHP date() format string |

## Software-layer concerns

### config.json

Copy `config.sample.json` → `config.json` and edit:

```json
{
  "unlock_pattern": "up up down down left right left right b a",
  "clock_format": "g:i A",
  "hover_color": "#999",
  "time_to_refresh_bg": 90000,
  "show_menu_on_page_load": false,
  "idle_timer": 30000,
  "unsplash_client_id": "your-unsplash-demo-key",
  "items": [
    {
      "link": "https://your-service.local",
      "icon": "fa-server",
      "alt": "My Server",
      "new_tab": true
    }
  ]
}
```

Alternatively, use a custom background image source:
```json
{
  "custom_url": "https://picsum.photos/info",
  "custom_url_selector": ["download_url"]
}
```

### PHP requirement

PHP with cURL extension — required for fetching external background images.

## Install — Apache + PHP

```bash
git clone https://github.com/tomershvueli/homepage.git /var/www/homepage
cd /var/www/homepage
cp config.sample.json config.json
# Edit config.json with your links and preferences

# Apache vhost pointing to /var/www/homepage
# Or just drop in any PHP-served directory
```

## Install — Docker

```bash
git clone https://github.com/tomershvueli/homepage.git
cd homepage
cp config.sample.json config.json
# Edit config.json

docker run -d \
  --name homepage \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  php:8-apache
```

## Upgrade procedure

```bash
git pull
# config.json is gitignored — preserved automatically
```

## Gotchas

- **Unsplash API rate limits**: demo keys are limited to 50 requests/hour. Set `time_to_refresh_bg` to at least `90000` (90 seconds) to stay within limits. Applying for a production Unsplash key has been reported to trigger key revocation — stick to the demo key.
- This is different from the popular gethomepage.dev project — both are named "homepage" but are unrelated. This one is a minimalist single-page PHP dashboard.
- PHP cURL is required for fetching external background images. Without it, background image fetching will silently fail — the page still works, just without backgrounds.
- Last upstream commit was ~2021; the project is functional but not actively maintained.

## Links

- Source: https://github.com/tomershvueli/homepage
- Mousetrap key patterns: https://craig.is/killing/mice
- Unsplash developers: https://unsplash.com/developers
- Font Awesome icons: https://fontawesome.io/icons/
