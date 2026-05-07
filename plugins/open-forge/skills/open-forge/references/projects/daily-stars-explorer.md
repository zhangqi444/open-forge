---
name: Daily Stars Explorer
description: Explore the full daily star history of any GitHub repository. Compare repos, view hourly trends, activity timelines (commits, PRs, issues), feed mentions, and CSV/JSON export.
website: https://emanuelef.github.io/daily-stars-explorer
source: https://github.com/emanuelef/daily-stars-explorer
license: MIT
stars: 352
tags:
  - github
  - analytics
  - developer-tools
  - statistics
platforms:
  - Go
  - JavaScript
---

# Daily Stars Explorer

Daily Stars Explorer is a tool for exploring the complete star history of any GitHub repository — day by day, not just cumulative totals. Unlike services that show a smooth interpolated curve, this tool fetches actual daily star counts. Also shows hourly activity, side-by-side repo comparison, commit/PR/issue/fork timelines, feed mentions (HN, Reddit, YouTube), and CSV/JSON export.

Live instance: https://emanuelef.github.io/daily-stars-explorer
Source: https://github.com/emanuelef/daily-stars-explorer

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Go backend + static frontend | Self-host for private rate limits |
| GitHub Pages | Static frontend only | Official live instance; API calls from browser |

## Inputs to Collect

**Phase: Planning**
- GitHub Personal Access Token (for API rate limits — required for meaningful use)
- Port for Go API server (default: check repo)
- Whether to self-host the frontend or use the live GitHub Pages instance

## Software-Layer Concerns

**The live instance** (https://emanuelef.github.io/daily-stars-explorer) requires no self-hosting — just open it in a browser and enter a GitHub repo name. A GitHub PAT is needed for non-trivial repos due to rate limits.

**Self-host the backend (Go):**

```bash
git clone https://github.com/emanuelef/daily-stars-explorer
cd daily-stars-explorer

# Build and run the Go API server
go build -o daily-stars-server ./server
export GITHUB_TOKEN=ghp_your_token_here
./daily-stars-server
```

**Self-host the frontend:**

```bash
cd website
npm install
npm run build
# Serve dist/ with any static file server or Nginx
```

**Nginx for both (if self-hosting):**

```nginx
server {
    listen 80;
    server_name stars.example.com;

    root /path/to/daily-stars-explorer/website/dist;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8080/;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**GitHub Token:** Set `GITHUB_TOKEN` environment variable — without it, GitHub API rate limits (60 req/hr unauthenticated) will quickly block large repo analysis.

**Features overview:**
- Full daily star history for any public GitHub repo
- Hourly star counts with timezone support
- Side-by-side comparison of two repos
- Activity timelines: commits, PRs, issues, forks, contributors
- Feed mentions: HN, Reddit, YouTube, GitHub discussions
- Pin favorite repos for quick access
- Export data as CSV or JSON
- Dark mode

## Upgrade Procedure

```bash
git pull
go build -o daily-stars-server ./server
# Rebuild frontend if self-hosting: npm run build in website/
```

## Gotchas

- **GitHub API rate limits**: Without a PAT, analysis is limited to 60 requests/hour — set `GITHUB_TOKEN` for 5,000/hour
- **Public repos only**: Can only analyze public GitHub repositories
- **Large repos are slow**: Repos with 40K+ stars require many API calls — expect a few minutes for full history fetch
- **Not a metrics platform**: Daily Stars Explorer is a read-only analysis tool, not a live monitoring system
- **Live instance is free**: The GitHub Pages instance at https://emanuelef.github.io/daily-stars-explorer is public — self-hosting is only needed if you want private API keys or custom modifications

## Links

- Source: https://github.com/emanuelef/daily-stars-explorer
- Live instance: https://emanuelef.github.io/daily-stars-explorer
- Releases: https://github.com/emanuelef/daily-stars-explorer/releases
