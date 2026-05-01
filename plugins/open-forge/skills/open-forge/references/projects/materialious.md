---
name: Materialious
description: "Self-hosted Material Design YouTube/Invidious frontend with account system. Docker. SvelteKit. Materialious/Materialious. No ads, no tracking, SponsorBlock, Return YouTube Dislike, DeArrow, E2E encrypted subscriptions, Android/TV apps, PWA."
---

# Materialious

**Self-hosted modern YouTube frontend with Material Design.** Privacy-respecting YouTube viewing: no ads, no tracking, SponsorBlock built-in, Return YouTube Dislike, DeArrow clickbait removal. Optional E2E encrypted account system (subscription sync, watch history, watch progress across devices). Works standalone with YouTube backend or with a self-hosted Invidious instance. Android, Android TV, Windows, macOS apps. PWA.

Built + maintained by **wardpearce / Materialious team**. See repo license.

- Upstream repo: <https://github.com/Materialious/Materialious>
- Docker Hub: `wardpearce/materialious-full` (feature-rich, with account system)

## Architecture in one minute

Two deployment modes:

| Mode | Image | Notes |
|------|-------|-------|
| **Full** (recommended) | `wardpearce/materialious-full` | Account system, E2E encrypted subs, watch progress sync, easier setup |
| **Legacy** | `wardpearce/materialious` | Invidious-only frontend; no account system; harder to configure |

- **SvelteKit** frontend
- Built-in account system (optional) — subscriptions E2E encrypted at rest
- Port **3000**
- Supports Invidious companion for better video streaming
- Resource: **low** — SvelteKit static/SSR + optional SQLite/PostgreSQL/MySQL

## Compatible install methods

| Infra      | Runtime                         | Notes                                              |
| ---------- | ------------------------------- | -------------------------------------------------- |
| **Docker** | `wardpearce/materialious-full`  | **Recommended** — see full guide in docs           |

## Install (Full mode)

```yaml
services:
  materialious:
    image: wardpearce/materialious-full:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      COOKIE_SECRET: "change-me-to-random-string"
      DATABASE_CONNECTION_URI: "sqlite:///materialious-data/materialious.db"
      PUBLIC_INTERNAL_AUTH: "true"
      PUBLIC_REQUIRE_AUTH: "true"
      PUBLIC_REGISTRATION_ALLOWED: "false"
      PUBLIC_CAPTCHA_DISABLED: "false"
    volumes:
      - ./materialious-data:/materialious-data
```

Full setup guide: <https://github.com/Materialious/Materialious/blob/main/docs/DOCKER-FULL.md>

## Features overview

| Feature | Details |
|---------|---------|
| No ads | No YouTube or third-party ads |
| No tracking | No Google tracking or analytics |
| SponsorBlock | Skip sponsored segments, intros, outros, etc. |
| Return YouTube Dislike (RYD) | Shows dislike counts on videos |
| DeArrow | Replaces clickbait titles and thumbnails with community-sourced ones |
| Account system | Optional built-in accounts; E2E encrypted subscriptions |
| Subscription sync | Subscriptions sync across all devices via encrypted account |
| Watch progress sync | Resume videos where you left off across devices |
| Watch history | Local history tracking |
| Import/Export subscriptions | Import from Invidious/YouTube; export at any time |
| Invidious support | Optional: use with a self-hosted Invidious instance |
| Invidious companion | Better video streaming quality when using Invidious |
| Local video fallback | Falls back to YouTube direct if Invidious fails to load a video |
| Live streams | Watch YouTube live streams |
| DASH/HLS | Adaptive bitrate streaming |
| Chapters | Video chapter navigation |
| Playlists | Browse and play playlists |
| Mini player (PIP) | Picture-in-picture mini player |
| PWA | Install as a Progressive Web App on any device |
| Android app | Native Android app (APK, F-Droid, Obtainium) |
| Android TV | Android TV support |
| Desktop apps | Windows (EXE) and macOS (DMG) apps available |
| Dark/Light themes | Theme switching |
| Custom color themes | Pick your own accent colors |
| YT path redirects | YouTube.com links auto-redirect to your Materialious instance (with browser extension) |
| Proof-of-work captcha | Optional bot protection on registration |

## Inputs to collect

| Input | Notes |
|-------|-------|
| `COOKIE_SECRET` | Random string for signing session cookies |
| `DATABASE_CONNECTION_URI` | SQLite, PostgreSQL, MySQL, or MariaDB URL |
| `PUBLIC_INTERNAL_AUTH` | `true` to enable built-in account system |
| `PUBLIC_REQUIRE_AUTH` | `true` to require login before watching |
| `PUBLIC_REGISTRATION_ALLOWED` | `false` to disable open registration |

## Gotchas

- **Two images: `materialious-full` vs `materialious`.** The `materialious-full` image has the built-in account system, E2E encrypted subscriptions, and is easier to deploy. The legacy `materialious` image is Invidious-only (no account system). Use `materialious-full`.
- **Invidious is optional.** Materialious can use YouTube's backend directly without a self-hosted Invidious instance. You don't need to run Invidious to use Materialious. Invidious is only needed if you want an extra privacy layer.
- **Captcha requires HTTPS.** The proof-of-work captcha only works over HTTPS. Set `PUBLIC_CAPTCHA_DISABLED=true` if running over HTTP (e.g. local LAN without TLS).
- **Proxy domain whitelist.** Materialious proxies certain requests (thumbnails, API calls). If you add Invidious or other services, add their base domains to `WHITELIST_BASE_DOMAIN` (comma-separated, base domain only — not full URL).
- **`PUBLIC_REGISTRATION_ALLOWED=false` after setup.** After creating your account, set this to `false` to prevent others from registering.
- **Android/TV apps.** The Android app APK is available on GitHub Releases and F-Droid. Android TV is supported via APK. Desktop apps (Windows/macOS) are also on Releases.

## Backup

```sh
# SQLite
cp materialious-data/materialious.db materialious-$(date +%F).db
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active SvelteKit development, E2E encrypted account system, SponsorBlock/RYD/DeArrow built-in, Android/TV/desktop apps, F-Droid. See repo license.

## YouTube-frontend-family comparison

- **Materialious** — SvelteKit, account system, E2E encrypted subs, SponsorBlock/RYD/DeArrow, Android/TV/desktop apps
- **Invidious** — Go, lightweight YT frontend, no built-in account system; Materialious can use it as a backend
- **Piped** — Java, YT frontend with account system; different tech stack
- **FreeTube** — Electron desktop app; not a web server; self-hosted not applicable
- **NewPipe** — Android app only

**Choose Materialious if:** you want a self-hosted YouTube frontend with a beautiful Material Design UI, E2E encrypted account system, SponsorBlock/RYD/DeArrow, and native Android/TV/desktop apps.

## Links

- Repo: <https://github.com/Materialious/Materialious>
- Full Docker guide: <https://github.com/Materialious/Materialious/blob/main/docs/DOCKER-FULL.md>
