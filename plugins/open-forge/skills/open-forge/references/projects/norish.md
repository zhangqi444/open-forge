---
name: Norish
description: "Self-hosted household recipe and meal planning app. Docker. Next.js + PostgreSQL + Redis. norish-recipes/norish. URL/video/image recipe import, AI-powered import fallback, meal planning, shopping lists, OIDC SSO, real-time household sync. MIT."
---

# Norish

**Self-hosted household-first recipe and meal planning app.** Import recipes from any URL, YouTube Shorts, Instagram Reels, TikTok videos, or screenshots. AI-powered import fallback for tricky sites. Collaborative meal planning and shopping lists for households. Nutritional info generation (with AI), allergy detection, OIDC/OAuth2 SSO. Real-time sync across household members.

Built + maintained by **mikevanes**. MIT license.

- Upstream repo: <https://github.com/norish-recipes/norish>
- Docker Hub: <https://hub.docker.com/r/norishapp/norish>

## Architecture in one minute

- **Next.js** frontend + backend (API routes)
- **PostgreSQL** database
- **Redis** for caching and real-time
- **Headless Chrome** (via `chrome-headless` container) for web scraping
- Optional: **yt-dlp** for video recipe import
- Port **3000**
- Resource: **medium** — Next.js + PostgreSQL + Redis + headless Chrome

## Compatible install methods

| Infra              | Runtime              | Notes                                                      |
| ------------------ | -------------------- | ---------------------------------------------------------- |
| **Docker Compose** | `norishapp/norish`   | **Primary** — see `docker/docker-compose.example.yml`      |

## Install via Docker Compose

See the example compose: `docker/docker-compose.example.yml` in the repo.

Minimal example:
```yaml
services:
  norish:
    image: norishapp/norish:latest
    restart: always
    ports:
      - "3000:3000"
    user: "1000:1000"
    volumes:
      - norish_data:/app/uploads
    environment:
      AUTH_URL: https://norish.example.com
      DATABASE_URL: postgres://postgres:secret@db:5432/norish
      MASTER_KEY: ""   # openssl rand -base64 32
      CHROME_WS_ENDPOINT: ws://chrome-headless:3000
      REDIS_URL: redis://redis:6379
      UPLOADS_DIR: /app/uploads
    depends_on:
      - db
      - redis
      - chrome-headless

  db:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: norish
    volumes:
      - pg_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    volumes:
      - redis_data:/data

  chrome-headless:
    image: browserless/chrome:latest
    restart: unless-stopped

volumes:
  norish_data:
  pg_data:
  redis_data:
```

## Inputs to collect

| Input | Notes |
|-------|-------|
| `AUTH_URL` | Your public URL — used for auth redirects and CORS |
| `DATABASE_URL` | PostgreSQL connection string |
| `MASTER_KEY` | 32-byte base64 secret — `openssl rand -base64 32` |
| `REDIS_URL` | Redis connection string |
| `CHROME_WS_ENDPOINT` | WebSocket URL of headless Chrome (for web scraping) |
| AI provider credentials (optional) | For AI import fallback, nutritional info, allergy detection |
| OIDC/OAuth2 credentials (optional) | For SSO (OIDC, GitHub, Google) |

## Features overview

| Feature | Details |
|---------|---------|
| URL recipe import | Import recipes from any cooking website by pasting a URL |
| AI import fallback | When structured data isn't available, AI parses the page (requires AI provider) |
| Video recipe import | Import from YouTube Shorts, Instagram Reels, TikTok, and more (requires AI + yt-dlp) |
| Image recipe import | Import from screenshots/photos of recipe cards (requires AI) |
| Nutritional info | AI-generated nutritional information per recipe (requires AI) |
| Allergy detection | Detect allergens in recipe ingredients (requires AI for detection) |
| Meal planning | Plan meals for the week; assign recipes to days |
| Shopping lists | Auto-generate shopping lists from meal plans; share with household |
| Household sharing | Real-time sync of recipes and plans across household members |
| OIDC SSO | Log in via OIDC providers (Authentik, Keycloak, etc.) |
| OAuth2 SSO | Log in via GitHub or Google |
| Custom auth | Email/password local accounts |
| Recipe management | Edit, categorize, tag, and search your recipe collection |
| Responsive UI | Clean, minimal interface that works on mobile and desktop |

## AI provider configuration (optional)

Configure an AI provider (OpenAI, Anthropic, or any OpenAI-compatible API) to enable:
- **AI import fallback** — parse recipes from sites that block scrapers
- **Video recipe import** — transcribe and parse video recipes
- **Image recipe import** — OCR + parse recipe screenshots
- **Nutritional information** — auto-generate per-recipe nutrition data
- **Allergy detection** — identify allergens in ingredient lists

Without an AI provider, Norish still works for URL import (from sites with structured recipe data), manual entry, and meal planning.

## Gotchas

- **Headless Chrome is required for URL import.** Norish uses headless Chrome to scrape recipe websites. Without `CHROME_WS_ENDPOINT`, URL import won't work. The `browserless/chrome` image provides this.
- **`MASTER_KEY` must not change.** This key encrypts sensitive data. If you change it, encrypted data becomes unreadable. Store it securely and back it up separately.
- **AI features are strictly optional.** Norish works as a recipe manager without AI. AI only enhances import (for difficult sites/videos/images) and nutritional/allergy data.
- **`AUTH_URL` must match your actual URL.** This is used for OIDC redirects and CORS. Mismatch causes auth failures.
- **TRUSTED_ORIGINS for local network.** If accessing from multiple addresses (e.g. local IP + domain), add them to `TRUSTED_ORIGINS` (comma-separated) to prevent CSRF issues.
- **yt-dlp for video import.** Video recipe import requires yt-dlp binary. Set `YT_DLP_BIN_DIR` to the directory containing the yt-dlp binary, or let Norish download it automatically.
- **First user setup.** On first run, register via the web UI. The first account becomes the household owner.

## Backup

```sh
docker compose exec db pg_dump -U postgres norish > norish-$(date +%F).sql
docker compose stop norish
sudo tar czf norish-uploads-$(date +%F).tgz norish_data/
docker compose start norish
```

## Upgrade

```sh
docker compose pull && docker compose up -d
# Database migrations run automatically
```

## Project health

Active Next.js development, video/image recipe import, AI integration, household sharing, OIDC/OAuth2. MIT license.

## Recipe-manager-family comparison

- **Norish** — Next.js, household-first, AI video/image import, OIDC/OAuth2, meal planning, MIT
- **Mealie** — Vue.js/FastAPI, comprehensive recipe manager, meal planning, shopping lists; larger community
- **Tandoor** — Django, recipe manager, cook books, meal planner; strong search
- **Grocy** — PHP, inventory + meal planning; more complex; broader scope than recipes
- **Nextcloud Cookbook** — simple Nextcloud app; basic recipe storage; no AI import

**Choose Norish if:** you want a household recipe manager with AI-powered import from URLs, YouTube videos, and photos, plus meal planning, shopping lists, and real-time household sync.

## Links

- Repo: <https://github.com/norish-recipes/norish>
- Docker Hub: <https://hub.docker.com/r/norishapp/norish>
