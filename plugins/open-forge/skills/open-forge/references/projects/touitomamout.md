---
name: touitomamout
description: Recipe for Touitomamout — synchronizes Twitter/X tweets to Mastodon and Bluesky posts. ARCHIVED project — no future updates but Docker images remain available.
---

# Touitomamout

Synchronize Twitter/X tweets to Mastodon and Bluesky posts. Upstream: https://github.com/louisgrasset/touitomamout

> **ARCHIVED** — The project is archived and will receive no future updates. Docker images remain available on Docker Hub and GitHub Packages. Repository is read-only.

Node.js-based sync bridge: scrapes Twitter via twitter-scraper, posts to Mastodon (masto.js) and/or Bluesky (atproto). Configuration docs at the project documentation site.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Primary method — see upstream documentation |
| Docker run | Supported |

> Because the project is archived, always review the upstream documentation for the last known-working configuration before deploying.

## Inputs to collect

Exact inputs depend on the current upstream deployment docs at:
https://louisgrasset.github.io/touitomamout/docs/discover

Typically:
| Phase | Prompt | Notes |
|---|---|---|
| preflight | Twitter/X username(s) to sync | Account(s) whose tweets will be mirrored |
| mastodon | Mastodon instance URL + access token | Target Mastodon account credentials |
| bluesky | Bluesky handle + app password | Target Bluesky account credentials |
| config | Sync interval | How often to check for new tweets |

## Software-layer concerns

**Config:** Environment variables — see upstream docs for the full variable list.

**Twitter scraping:** Uses twitter-scraper (no official API) — depends on Twitter's HTML structure which can break without warning since the project is archived and won't be patched.

**No external DB:** Stateless or minimal state for deduplication. Check upstream docs for volume requirements.

**Port:** Not a web service — runs as a headless background process.

## Docker Compose

Follow the current upstream deployment guide:
https://louisgrasset.github.io/touitomamout/docs/discover

Do not fabricate a compose file — the exact env var names and config schema are documented upstream.

## Upgrade procedure

As the project is archived, no new versions will be published. Pin to the last known-good tag. Check GitHub releases for the final stable version.

## Gotchas

- **ARCHIVED PROJECT** — no security patches, no bug fixes. Twitter/X scraping may break at any time due to upstream site changes.
- **No official Twitter API** — scraping Twitter without an API key is subject to rate limits, IP bans, and structural changes. Reliability is not guaranteed.
- **Author's note** — archived due to the author's values stance on Twitter/X. Docker images remain available but use at your own discretion.
- **Check for forks** — community forks may maintain the project; search GitHub for active forks before adopting.

## Links

- Upstream repository (read-only): https://github.com/louisgrasset/touitomamout
- Documentation: https://louisgrasset.github.io/touitomamout/docs/discover
- Docker Hub: https://hub.docker.com/r/louisgrasset/touitomamout
