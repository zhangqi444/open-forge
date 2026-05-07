---
name: bubo-reader
description: Bubo Reader recipe for open-forge. Irrationally minimal RSS/Atom/JSON feed reader. Generates a static HTML page of latest feed links. Node.js. Netlify or any static host. MIT. Source: https://github.com/georgemandis/bubo-rss
---

# Bubo Reader

Hyper-minimalist RSS, Atom, and JSON feed reader. Fetches your configured feeds, parses them, and generates a single static HTML page listing the latest links organized by category and site. No database, no login, no UI beyond the generated page. Deploy the built output to any static host (Nginx, Caddy, Netlify, GitHub Pages). Run periodically via cron or GitHub Actions to keep feeds fresh. Node.js + TypeScript. MIT licensed.

Upstream: https://github.com/georgemandis/bubo-rss | Demo: https://bubo-rss-demo.netlify.app

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Node.js (npm) + cron | Build locally, serve static output |
| Any | Nginx / Caddy | Serve the generated public/ directory |
| Netlify | Netlify deploy | One-click; auto-rebuild on push |
| GitHub Pages | GitHub Actions | Schedule builds via workflow cron |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Feed list | Edit conf/feeds.json with your feed URLs organized by category |
| config (optional) | Template | Edit config/template.html (Nunjucks) to customize the output layout |
| config (optional) | Cron schedule | How often to rebuild (e.g. every hour via cron or GitHub Actions schedule) |
| config (optional) | MAX_CONNECTIONS | Max parallel feed requests per batch (in src/index.ts) |
| config (optional) | DELAY_MS | Delay between batches in milliseconds (for throttling) |

## Software-layer concerns

### Key files

| File | Description |
|---|---|
| conf/feeds.json | Your feed URLs organized by category |
| config/template.html | Nunjucks HTML template for the output page |
| public/index.html | Generated output -- serve this directory |
| public/style.css | Stylesheet (customize freely) |
| src/index.ts | Main build script (feed fetching + rendering) |

### Notes

- Bubo generates a completely static HTML file on each run; it has no server-side component
- Feeds are fetched at build time, not at read time -- the page shows a snapshot of feeds at last build
- To keep feeds fresh, schedule the build to run periodically (cron, GitHub Actions, etc.)

## Install -- Local build + Nginx

```bash
git clone https://github.com/georgemandis/bubo-rss.git
cd bubo-rss
npm install

# Edit your feeds
nano conf/feeds.json

# Build
npm run build:bubo
# Output in public/

# Serve with Nginx (or any static server)
cp -r public/ /var/www/bubo/
```

Nginx config:

```nginx
server {
    listen 80;
    server_name feeds.example.com;
    root /var/www/bubo;
    index index.html;
}
```

## Keeping feeds updated -- cron

```cron
0 * * * * cd /path/to/bubo-rss && npm run build:bubo && cp -r public/ /var/www/bubo/
```

## Keeping feeds updated -- GitHub Actions

Create .github/workflows/build.yml:

```yaml
on:
  schedule:
    - cron: '0 * * * *'   # every hour
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install
      - run: npm run build:bubo
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

## feeds.json format

```json
{
  "categories": [
    {
      "name": "Technology",
      "feeds": [
        "https://hnrss.org/frontpage",
        "https://lobste.rs/rss"
      ]
    },
    {
      "name": "Blogs",
      "feeds": [
        "https://example.com/feed.xml"
      ]
    }
  ]
}
```

## Upgrade procedure

```bash
git pull
npm install
npm run build:bubo
```

## Gotchas

- Read-only / no login: Bubo is a static page. There is no web UI to manage feeds -- you edit feeds.json directly and rebuild.
- Stale feeds: the page only shows items from the last build. If you want near-real-time feeds, run the build frequently (every 15-30 minutes via cron).
- Feed compatibility: supports RSS, Atom, and JSON Feed formats. Malformed or unreachable feeds are skipped silently by default.
- Throttling: if you subscribe to many feeds, adjust MAX_CONNECTIONS and DELAY_MS in src/index.ts to avoid rate-limiting or network timeouts.

## Links

- Source: https://github.com/georgemandis/bubo-rss
- Demo: https://bubo-rss-demo.netlify.app
- Blog post: https://george.mand.is/2019/11/introducing-bubo-rss-an-absurdly-minimalist-rss-feed-reader/
