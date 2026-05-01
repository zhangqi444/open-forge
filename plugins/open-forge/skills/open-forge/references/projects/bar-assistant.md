---
name: Bar Assistant
description: "Self-hosted cocktail recipe manager and bar inventory tracker. Docker. PHP/Laravel + Vue (Salt Rim) + Meilisearch. karlomikus/bar-assistant. 500+ recipes, ABV calculation, ingredient inventory, shopping lists, SSO, public bar menus. MIT."
---

# Bar Assistant

**Self-hosted cocktail recipe manager and home bar tracker.** Manage your home bar inventory, discover recipes from 500+ built-in cocktails, filter by what you have on hand, calculate ABV, and generate shopping lists for missing ingredients. Multi-bar support, user roles, SSO, public bar menus, price calculation. API backend + [Salt Rim](https://github.com/karlomikus/vue-salt-rim) web frontend.

Built + maintained by **karlomikus**. MIT license.

- API repo: <https://github.com/karlomikus/bar-assistant>
- Frontend (Salt Rim): <https://github.com/karlomikus/vue-salt-rim>
- Docker Hub: <https://hub.docker.com/r/barassistant/server>
- Docs: <https://docs.barassistant.app>
- Demo: <https://demo.barassistant.app>

## Architecture in one minute

- **PHP / Laravel** API backend (`barassistant/server`)
- **Vue.js** frontend: Salt Rim (`barassistant/salt-rim`) — separate image
- **Meilisearch** for full-text search and filtering
- **Redis** for caching and sessions
- Port: **8085** (API), **8080** (Salt Rim frontend)
- Resource: **medium** — PHP + Meilisearch

## Compatible install methods

| Infra              | Runtime                     | Notes                                           |
| ------------------ | --------------------------- | ----------------------------------------------- |
| **Docker Compose** | `barassistant/server` + `barassistant/salt-rim` | **Primary** — see docs |

> No `latest` tag. Use versioned tags: `barassistant/server:v4`, `v4.4`, or `v4.4.1`.

## Install via Docker Compose

See the official installation guide: <https://docs.barassistant.app/>

Example minimal stack:
```yaml
services:
  bar-assistant:
    image: barassistant/server:v4
    restart: unless-stopped
    environment:
      - APP_URL=https://bar.example.com
      - MEILISEARCH_URL=http://meilisearch:7700
      - MEILISEARCH_KEY=masterKeyThatIsReallyReallyLong4Real
      - REDIS_HOST=redis
      - ALLOW_REGISTRATION=true
    volumes:
      - ba_data:/var/www/cocktails/storage

  salt-rim:
    image: barassistant/salt-rim:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - API_URL=https://bar.example.com

  meilisearch:
    image: getmeili/meilisearch:v1.11
    environment:
      - MEILI_MASTER_KEY=masterKeyThatIsReallyReallyLong4Real
    volumes:
      - meili_data:/meili_data

  redis:
    image: redis
    environment:
      - ALLOW_EMPTY_PASSWORD=yes

volumes:
  ba_data:
  meili_data:
```

## Inputs to collect

| Input | Notes |
|-------|-------|
| `APP_URL` | Public URL of the API |
| `MEILISEARCH_KEY` | Meilisearch master key (must match between services) |
| `APP_SECRET_KEY` | Laravel app key (generate with `artisan key:generate`) |
| `ALLOW_REGISTRATION` | `true` to allow open registration; `false` to lock down |

## Features overview

| Feature | Details |
|---------|---------|
| Recipe library | 500+ built-in cocktail recipes with detailed info |
| Ingredient library | 250+ base ingredients with categories |
| Inventory tracking | Mark ingredients you have; filter recipes accordingly |
| Shopping list | Auto-generate list of missing ingredients for a recipe |
| Filter by what you have | Show only recipes you can make right now |
| ABV calculation | Automatic alcohol by volume per recipe |
| Unit switching | Toggle between metric/imperial measurements |
| Ingredient substitutes | Define and show cocktail ingredient swaps |
| Multi-bar | Create and manage multiple bars (home bar, work bar, etc.) |
| Bar members | Invite users; role-based access per bar |
| Recipe import | Import from URL, JSON, YAML, or custom collections |
| Recipe variations | Define variants of the same cocktail |
| Cocktail ratings | Rate drinks and see averages |
| Collections | User collections for grouping and sharing |
| Notes | Per-cocktail and per-ingredient notes |
| Public bar menu | Share a public read-only menu page |
| Price calculation | Track ingredient prices; auto-calculate cocktail cost |
| Statistics | Insights about your recipes and taste preferences |
| Data export | Export your bar data in various formats |
| SSO | Single sign-on support |
| API tokens | Personal access tokens with custom permissions |

## Gotchas

- **No `latest` tag.** Bar Assistant doesn't publish a `latest` Docker image. Always specify a versioned tag (`v4`, `v4.4`, `v4.4.1`). The `dev` tag is unstable.
- **Meilisearch master key must match.** The key in the `bar-assistant` container env and the Meilisearch `MEILI_MASTER_KEY` must be identical. Mismatch → search fails.
- **Two separate images.** The backend (`barassistant/server`) and frontend (`barassistant/salt-rim`) are separate Docker images. Both are needed. Salt Rim needs to know the API URL via `API_URL`.
- **Registration control.** Set `ALLOW_REGISTRATION=false` after creating your account to prevent others from signing up on your instance.
- **First login.** Default admin credentials are in the docs. Change them immediately after first login.

## Backup

```sh
docker compose exec bar-assistant php artisan bar:export
# Plus back up the ba_data volume and meili_data volume
```

## Upgrade

```sh
# Check release notes first; major versions may have migration steps
docker compose pull && docker compose up -d
docker compose exec bar-assistant php artisan migrate --force
```

## Project health

Active PHP/Laravel + Vue development, 500+ recipes, Meilisearch, multi-bar, SSO, price calculation. MIT license.

## Cocktail-manager-family comparison

- **Bar Assistant** — PHP+Laravel, 500+ recipes, Meilisearch search, inventory, shopping lists, bar menus, MIT
- **Receta** — simpler recipe manager; not cocktail-specific
- **Nextcloud Cookbook** — Nextcloud app; general recipes; not bar-specific
- **Grocy** — PHP, home inventory + EAN barcodes; general grocery; not cocktail-focused

**Choose Bar Assistant if:** you want a dedicated self-hosted cocktail manager with ingredient inventory, "what can I make?" filtering, ABV calculation, shopping lists, and a polished Vue frontend.

## Links

- API repo: <https://github.com/karlomikus/bar-assistant>
- Frontend (Salt Rim): <https://github.com/karlomikus/vue-salt-rim>
- Docs: <https://docs.barassistant.app>
- Demo: <https://demo.barassistant.app>
