---
name: Mealie
description: Self-hosted recipe manager, meal planner, and shopping list with REST API + reactive Vue frontend. URL-import recipes, drag-and-drop meal planning, supermarket-aisle-aware shopping lists, cookbooks, 35+ UI translations. Python FastAPI + SQLite/Postgres. AGPL-3.0.
---

# Mealie

Mealie is the go-to self-hosted recipe manager for food nerds. Core features:

- **URL import** — paste a recipe URL, Mealie scrapes structured data (title, ingredients, instructions, image, times)
- **Meal planner** — drag recipes onto a weekly/monthly calendar
- **Shopping list** — auto-generate from a week's meals; organize by supermarket aisle; sync across devices
- **Cookbooks** — group recipes by your criteria (weeknight, favorites, vegetarian, etc.)
- **Family-friendly multi-user** with per-user permissions + shared households
- **REST API** + webhook triggers for automation (Home Assistant, personal scripts)
- **35+ language translations**
- **Paprika / Nextcloud Cookbook / Plan to Eat import**

- Upstream repo: <https://github.com/mealie-recipes/mealie>
- Website: <https://mealie.io>
- Docs: <https://docs.mealie.io>
- Install (SQLite): <https://docs.mealie.io/documentation/getting-started/installation/sqlite/>
- Install (Postgres): <https://docs.mealie.io/documentation/getting-started/installation/postgres/>

**Note**: default branch is `mealie-next`. Repo was previously at `hay-kot/mealie` → now `mealie-recipes/mealie` (fork + community takeover; both URLs work via GitHub redirect).

## Architecture in one minute

- **`mealie`** — Python FastAPI backend + compiled Vue/Nuxt frontend in one image
- **DB**: SQLite (default, 1-20 users) or Postgres (many users / NAS / heavy concurrency)
- **Data volume**: `/app/data/` — DB file (SQLite), recipe images, uploads
- **Exposes port 9000** inside container

## Compatible install methods

| Infra       | Runtime                                               | Notes                                                                |
| ----------- | ----------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker Compose (SQLite)                                | **Simplest** for 1-20 users                                           |
| Single VM   | Docker Compose (Postgres)                              | For many users or NAS-hosted DB                                       |
| Kubernetes  | Community Helm                                          | Not upstream-maintained                                               |
| NAS         | Synology / Unraid / TrueNAS apps                        | Widely packaged                                                       |
| Home Assistant | Add-on via Home Assistant Community Store            | Popular integration                                                   |

## Inputs to collect

| Input          | Example                       | Phase     | Notes                                                    |
| -------------- | ----------------------------- | --------- | -------------------------------------------------------- |
| Port           | `9925:9000`                   | Network   | Container listens on 9000                                  |
| Data volume    | `mealie-data:/app/data/`      | Storage   | DB + recipe images + uploads                              |
| `BASE_URL`     | `https://mealie.example.com`  | DNS       | For correct email links + share URLs                      |
| `ALLOW_SIGNUP` | `false` (after first admin)   | Auth      | Default is `false` — good                                 |
| `PUID`/`PGID`  | `1000` / `1000`                | Runtime   | Match host user for bind-mounted volumes                  |
| `TZ`           | `America/New_York`            | Runtime   | Meal planner dates + schedules                            |
| DB engine      | SQLite default / Postgres opt | DB        | `DB_ENGINE=postgres` + `POSTGRES_*` vars                  |
| Memory limit   | `1000M`                        | Runtime   | **Recommended** — Python pre-allocates                     |
| SMTP (opt)     | host/port/user/pw/from        | Email     | For password reset, invites                                |

## Install via Docker Compose (SQLite, 1-20 users)

```yaml
services:
  mealie:
    image: ghcr.io/mealie-recipes/mealie:v3.16.0    # pin; avoid :latest
    container_name: mealie
    restart: always
    ports:
      - "9925:9000"
    deploy:
      resources:
        limits:
          memory: 1000M
    volumes:
      - mealie-data:/app/data/
    environment:
      ALLOW_SIGNUP: "false"
      PUID: 1000
      PGID: 1000
      TZ: America/New_York
      BASE_URL: https://mealie.example.com

volumes:
  mealie-data:
```

## Install via Docker Compose (Postgres)

Recommended for multi-user, high-concurrency, or NAS-hosted data (SQLite + NFS/SMB = corruption risk).

```yaml
services:
  mealie:
    image: ghcr.io/mealie-recipes/mealie:v3.16.0
    container_name: mealie
    restart: always
    ports:
      - "9925:9000"
    deploy:
      resources:
        limits:
          memory: 1000M
    volumes:
      - mealie-data:/app/data/
    environment:
      ALLOW_SIGNUP: "false"
      PUID: 1000
      PGID: 1000
      TZ: America/New_York
      BASE_URL: https://mealie.example.com
      DB_ENGINE: postgres
      POSTGRES_USER: mealie
      POSTGRES_PASSWORD: mealie
      POSTGRES_SERVER: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DB: mealie
    depends_on:
      postgres: { condition: service_healthy }

  postgres:
    image: postgres:17
    container_name: mealie-postgres
    restart: always
    volumes:
      - mealie-pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: mealie
      POSTGRES_USER: mealie
      PGUSER: mealie
      POSTGRES_DB: mealie
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 30s
      timeout: 20s
      retries: 3

volumes:
  mealie-data:
  mealie-pgdata:
```

**Change the default postgres password** before exposing anywhere.

## First boot

1. Browse `https://mealie.example.com`
2. Create the first admin account (email + password)
3. Settings → Household → Configure for you and family
4. Import recipes via URL: "+ New Recipe" → paste URL → Mealie scrapes

## Data & config layout

Inside `/app/data/`:

- `mealie.db` — SQLite DB (if SQLite mode)
- `backups/` — scheduled exports (Settings → Backups; defaults to weekly auto-backup)
- `recipes/<slug>/` — per-recipe assets (images, files)
- `users/<id>/` — user profile images
- `groups/<id>/` — group assets

## Backup

Mealie has **built-in auto-backup** (Settings → Backups) — weekly `.zip` to `/app/data/backups/` by default. Restore via UI.

On top:

```sh
# Entire data volume (includes built-in backups)
docker run --rm -v mealie-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/mealie-$(date +%F).tgz -C /src .

# Or Postgres-only
docker compose exec -T postgres pg_dump -U mealie mealie | gzip > mealie-db-$(date +%F).sql.gz
```

## Upgrade

1. Releases: <https://github.com/mealie-recipes/mealie/releases>.
2. **Pin to `vX.Y.Z` version tag** — upstream explicitly recommends this over `:latest` (release notes may require manual actions).
3. `docker compose pull && docker compose up -d`. Alembic migrations run on startup.
4. Back up data volume before each version change.
5. **PostgreSQL major-version upgrades require manual steps** — see [postgres image docs](https://github.com/docker-library/postgres/issues/37).

## Gotchas

- **SQLite + NAS = data corruption risk.** Don't put SQLite DB on NFS/SMB shares. Use Postgres for NAS setups or keep data on local disk.
- **Memory limit recommended** (1 GB). Python's arena allocator can pre-allocate more than needed on big-RAM hosts; without a limit, idle containers look bloated.
- **Pin to semver tag** (`v3.16.0`, not `:latest`). Upstream explicitly calls this out — release notes occasionally require manual migration steps.
- **`BASE_URL` is used in email links** — OAuth redirects, invitation emails. Set correctly before inviting users.
- **Repo moved from `hay-kot/mealie` → `mealie-recipes/mealie`** in 2023 after community took over. Old docker images `hkotel/mealie` may appear stale; use `ghcr.io/mealie-recipes/mealie` for the canonical image.
- **Branch name is `mealie-next`** — the main development branch; `master` was retired. Docs link to `mealie-next`.
- **Fuzzy search** requires Postgres (PG `pg_trgm` extension). SQLite users get exact-match search only.
- **Recipe import scrapes structured data** (JSON-LD / microdata). Sites without it fall back to manual entry. Some sites actively block scrapers — workaround: copy-paste.
- **Shopping list supermarket-aisle grouping** is user-configurable per ingredient. One-time setup, huge QoL after.
- **API-first** — the REST API is first-class (used by the frontend itself). Automate away: Home Assistant integrations, Telegram bots, ChatGPT recipe-suggester → auto-add to meal plan.
- **iOS + Android apps** — unofficial community apps exist (e.g., MealieApp); no official native mobile app, but the web PWA is solid.
- **Ingredient parser** uses NLP (`parser`) to extract amounts + units + ingredient names. Not perfect; occasional manual fixes.
- **Recipe sharing**: public share links (unauthenticated), useful for emailing a recipe.
- **OIDC / OAuth login** supported (Google, Keycloak, Authelia, etc.) — configure via env vars.
- **No transcription** — video/audio recipe imports are manual.
- **AGPL-3.0** — standard OSS license; running a hosted Mealie-as-a-service would require source disclosure.
- **Alternatives worth knowing:**
  - **Tandoor Recipes** — similar space, more advanced meal-planning features
  - **Nextcloud Cookbook** — if you already run Nextcloud, just add the app
  - **Grocy** — household management, includes recipes + shopping but heavier focus on stock/waste
  - **Paprika Recipe Manager** — commercial (Mac/iOS/Android/Win), battle-tested offline
  - **Paprika Cloud Sync** — sync Paprika between devices via proprietary server
  - **Cooklang** — text-file recipe format; integrates with Obsidian

## Links

- Repo: <https://github.com/mealie-recipes/mealie>
- Website: <https://mealie.io>
- Docs: <https://docs.mealie.io>
- SQLite install: <https://docs.mealie.io/documentation/getting-started/installation/sqlite/>
- Postgres install: <https://docs.mealie.io/documentation/getting-started/installation/postgres/>
- Backend config env vars: <https://docs.mealie.io/documentation/getting-started/installation/backend-config/>
- Releases: <https://github.com/mealie-recipes/mealie/releases>
- Docker image (GHCR): <https://github.com/mealie-recipes/mealie/pkgs/container/mealie>
- Discord: <https://discord.gg/QuStdQGSGK>
- Contributors guide: <https://nightly.mealie.io/contributors/developers-guide/code-contributions/>
