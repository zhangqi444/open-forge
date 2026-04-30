---
name: Tandoor Recipes
description: "Open-source recipe manager + meal planner. URL recipe import from 100+ sites, meal plan calendar, auto-generated shopping list, ingredient tagging, step-by-step cooking mode, supermarket-aisle-based shopping, multi-user/sharing. Django + Vue + Postgres. AGPL-3.0."
---

# Tandoor Recipes

Tandoor is a powerhouse self-hosted **recipe manager + meal planner**. Paste a URL from 100+ recipe sites (Allrecipes, BBC Good Food, Bon Appétit, Serious Eats, Tasty, NYT Cooking, blogs with schema.org/Recipe markup) and it extracts ingredients + steps. Build meal plans on a calendar, generate shopping lists grouped by supermarket aisle, track ingredient substitutions, and share with household members.

If Mealie is "recipe manager + mealplanner," Tandoor is "recipe manager + mealplanner + meal-planning power-tool" — deeper data model, more features, slightly steeper learning curve.

Features:

- **URL import** from 100+ sites via schema.org/Recipe + custom scrapers
- **PDF/image OCR** — upload recipe scans
- **Meal plan** — calendar view; drag-and-drop
- **Auto shopping list** — grouped by aisle; combine ingredients across recipes
- **Supermarket categories** — your local store's aisle layout
- **Ingredient substitutions** — "I have X, suggest recipes"
- **Cooking mode** — step-by-step guided cooking, timer integration
- **Books** — organize recipes into cookbooks
- **Multi-user + spaces** — per-household isolation
- **Sharing** — public links, community view
- **Nutrition** (from ingredient DB)
- **Tags, keywords, custom properties**
- **Import/export** — JSON, PDF, link
- **Mealie + Paprika + Chowdown + JSON import**
- **API** — REST; mobile app in development
- **Integration** with Grocy (pass shopping list to Grocy)

- Upstream repo: <https://github.com/TandoorRecipes/recipes>
- Docs: <https://docs.tandoor.dev>
- Docker Hub: <https://hub.docker.com/r/vabene1111/recipes>
- Discord: <https://discord.gg/9HGZf3sShw>
- Community: <https://community.tandoor.dev>
- Hosted: <https://www.tandoor.dev> (SaaS option)

## Architecture in one minute

- **Backend**: Django (Python 3.11+)
- **Frontend**: Vue 2/3 (check current)
- **DB**: Postgres 13+
- **Cache**: optional Redis (for production)
- **File storage**: local disk or S3 (images, uploaded PDFs)
- **Gunicorn** (WSGI) + **nginx** (in the official image stack)
- **Reverse proxy** required for TLS

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                          |
| ----------- | ------------------------------------------------ | -------------------------------------------------------------- |
| Single VM   | **Docker Compose** (upstream provides)              | **The way**                                                        |
| Kubernetes  | Community Helm + manifests                             | Straightforward                                                        |
| Managed     | Tandoor SaaS (`tandoor.dev`)                               | Supports project                                                            |
| Raspberry Pi | arm64 Docker                                              | Works on Pi 4/5                                                                 |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                           |
| ----------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| Domain            | `recipes.example.com`             | URL       | Reverse proxy with TLS                                              |
| DB                | Postgres user/pass                   | DB        | v13+                                                                        |
| Secret key        | 64-char random                         | Crypto    | Django `SECRET_KEY`; don't rotate after deployment                                   |
| Admin user        | created via env or first-run wizard      | Bootstrap | Superuser                                                                                    |
| SMTP              | host + port + creds                         | Email     | Invites, password reset                                                                                       |
| S3 (opt)          | bucket + creds                                  | Storage   | For media if you want off-host uploads                                                                                        |
| Timezone          | `America/Los_Angeles`                            | Locale    | Affects meal-plan display                                                                                                   |
| Language          | `en` (default) — 20+ languages supported            | Locale    | Separate from spelling-locale                                                                                                       |

## Install via Docker Compose

Upstream provides a canonical compose file. Outline:

```yaml
services:
  db_recipes:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: djangodb
      POSTGRES_USER: djangouser
      POSTGRES_PASSWORD: <strong>
    volumes:
      - ./postgresql:/var/lib/postgresql/data

  web_recipes:
    image: vabene1111/recipes:1.x              # pin specific version
    restart: unless-stopped
    depends_on: [db_recipes]
    env_file: .env
    environment:
      DB_ENGINE: django.db.backends.postgresql
      POSTGRES_HOST: db_recipes
      POSTGRES_PORT: 5432
      POSTGRES_USER: djangouser
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: djangodb
      SECRET_KEY: <64-random-chars>
      ALLOWED_HOSTS: recipes.example.com
      TIMEZONE: America/Los_Angeles
      GUNICORN_MEDIA: 1       # serve uploads via gunicorn (or disable + use nginx)
    volumes:
      - ./staticfiles:/opt/recipes/staticfiles
      - ./mediafiles:/opt/recipes/mediafiles

  nginx_recipes:
    image: nginx:mainline-alpine
    restart: unless-stopped
    env_file: .env
    depends_on: [web_recipes]
    ports:
      - "8088:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./staticfiles:/static:ro
      - ./mediafiles:/media:ro
```

Set env vars (see `.env.template` at upstream). Front with Caddy/nginx for TLS. Browse `https://recipes.example.com` → sign up.

## First boot

1. Sign up → admin
2. Create **Space** (household) → invite family members
3. Go to Food → build ingredient database (or let URL imports populate)
4. Supermarkets → define your store's aisle order (once)
5. Import first recipe: Recipes → + → URL import → paste Allrecipes / BBC Food / etc. URL → imports with ingredients + steps
6. Meal Plan → drag recipes to calendar days
7. Shopping List → auto-generated, aisle-sorted, checkbox items in store

## Recipe import sources

Via **schema.org/Recipe** (auto):

- Allrecipes, BBC Good Food, Bon Appétit, NYT Cooking, Serious Eats, Tasty, Food52, Epicurious, Delish, Cookie and Kate, Minimalist Baker, Pinch of Yum, Smitten Kitchen — most schema.org-aware food blogs work

Via **custom scrapers**:

- <https://docs.tandoor.dev/features/url_import/> lists supported sites

Via **import**:

- Mealie, Paprika, Chowdown, JSON, CSV

Via **image/PDF OCR**:

- Upload a photo of a cookbook page; OCR extracts text; AI-assisted parsing in recent versions.

## Data & config layout

- Postgres: recipes, ingredients, meal plans, shopping lists, users, spaces
- `mediafiles/` — uploaded images + PDFs
- `staticfiles/` — collected Django statics
- `.env` — config + secrets

## Backup

```sh
# DB (CRITICAL — all recipes, plans, lists)
pg_dump -U djangouser djangodb | gzip > tandoor-db-$(date +%F).sql.gz

# Media
tar czf tandoor-media-$(date +%F).tgz mediafiles/
```

## Upgrade

1. Releases: <https://github.com/TandoorRecipes/recipes/releases>. Active.
2. **Back up DB first** — migrations common; occasional Django-minor upgrades.
3. Docker: bump image tag → `docker compose pull && docker compose up -d`. Migrations run on startup.
4. 2.x → current; read release notes.

## Gotchas

- **URL import misses**: sites that block bots or use JS-rendered recipe content won't scrape. Paste recipe text manually for those.
- **Ingredient parsing** is heuristic — "1 cup flour, sifted" parses into quantity=1, unit=cup, ingredient=flour, note=sifted. Not perfect for unusual formats ("a handful of spinach"). Fix by editing the parsed result.
- **Duplicates + aliases**: "sugar", "granulated sugar", "white sugar" are three different entries unless you set aliases. Invest time early in ingredient hygiene or the shopping list will bloat.
- **Shopping list aisle mapping**: supermarket categories are powerful but require upfront config (tell Tandoor "flour → baking, milk → dairy, ..."). Worth it if shopping at one store; pain if shopping at multiple.
- **Multi-space isolation** — Spaces are fully separate (different recipes, different plans). Inviting a roommate to YOUR space shares everything; giving them their own space = separate.
- **Permissions** within a space are coarse (admin / user / view-only).
- **Meal plan ≠ grocery list auto-refresh** — shopping list updates when you regenerate it. Recipes you delete from meal plan don't auto-remove from the shopping list.
- **Grocy integration** is one-way (push to Grocy); bidirectional is not supported. Useful for pantry-aware shopping.
- **Mobile**: PWA is functional but there's no native app. "Tandoor mobile" is community-developed.
- **Cooking mode** (step-by-step) requires screen-on during cooking; consider a waterproof tablet mounted in your kitchen.
- **Nutrition**: requires ingredient database with nutrition data. Tandoor has a basic DB; community-maintained expansions exist.
- **Book feature** (cookbooks) organizes recipes; not a literal "book export" — for printable cookbook, use Tandoor's "Export to PDF" (page-styled).
- **AI features** (in newer versions) help with ingredient parsing + suggestions; require OpenAI API key or self-hosted LLM endpoint. Opt-in.
- **Performance**: for collections <5000 recipes, fine on Pi 4. For 10k+ recipes with heavy images, bigger host + Redis cache + nginx-serve-media helps.
- **Tandoor hosted** (`tandoor.dev`) is upstream's SaaS offering — reasonable if you don't want to operate.
- **AGPL-3.0** — strong copyleft; network-use counts; forking + hosting others = open source your fork.
- **Recipe licensing** — you import from blogs/sites; their recipes are their copyright. Tandoor stores them for your personal use; sharing public links pushes into "maybe" territory. Fair use for personal cooking is broadly OK; public republishing = check source license.
- **Alternatives worth knowing:**
  - **Mealie** — simpler UX; similar features; great for beginners (separate recipe)
  - **Grocy** — household ERP; recipes are one feature among many (separate recipe)
  - **KitchenOwl** — meal-plan-focused; minimal UX
  - **Chowdown / Cooklang / Recipester** — text-file-centric
  - **Paprika** — commercial desktop/mobile
  - **Plan to Eat / Emeals / Paprika Cloud** — SaaS
  - **Saffron / YummyRecipes / RecipeSage** — niche OSS
  - **Choose Tandoor if:** you want the most powerful OSS recipe manager + meal planner, with supermarket-aware shopping lists.
  - **Choose Mealie if:** you want something simpler + prettier.
  - **Choose Grocy if:** stock tracking matters more than recipe depth.

## Links

- Repo: <https://github.com/TandoorRecipes/recipes>
- Docs: <https://docs.tandoor.dev>
- Install: <https://docs.tandoor.dev/install/docker/>
- URL import list: <https://docs.tandoor.dev/features/url_import/>
- Discord: <https://discord.gg/9HGZf3sShw>
- Community forum: <https://community.tandoor.dev>
- Docker Hub: <https://hub.docker.com/r/vabene1111/recipes>
- Releases: <https://github.com/TandoorRecipes/recipes/releases>
- Hosted: <https://www.tandoor.dev>
- API docs: <https://docs.tandoor.dev/api/>
- Translation: <https://hosted.weblate.org/projects/tandoor/>
- Donate: <https://www.buymeacoffee.com/tandoor>
