---
name: KitchenOwl
description: "Self-hosted grocery list + recipe + meal-plan + expense tracker. Flutter native apps (iOS, Android, Desktop, Web) + Python/Flask backend. AGPL-3.0. Active; sole-maintainer-with-community; Home Assistant integration."
---

# KitchenOwl

KitchenOwl is **"AnyList / OurGroceries / Out of Milk + a recipe manager + a meal planner + an expense tracker — self-hosted + yours"**. Add items to a shared grocery list; sync in real-time with household members; manage recipes; get meal suggestions; plan meals across the week; track household expenses + balances. Works offline-ish for the "I'm in the supermarket and lost cell signal" case. Native Flutter apps on iOS + Android + Desktop + Web. Home Assistant HACS integration.

Built + maintained by **Tom Bursch** + community. **License: AGPL-3.0**. Active + native apps on Play Store + App Store + F-Droid + Matrix room + Weblate translations + HACS (Home Assistant Community Store) integration. Sole-maintainer-with-community.

Use cases: (a) **household grocery coordination** — partner/roommates sync list in real-time (b) **meal planning + recipe archive** — shared family recipes + plan-what-to-cook-this-week (c) **escape AnyList / OurGroceries commercial SaaS** (d) **expense tracking for households** — who-paid-what-for-groceries balances (e) **HA integration** — shout at Alexa/Google/HA-voice: "add milk to the list" (f) **shareable recipes** between friends (g) **shopping list import from recipes** — click the recipe + ingredients fly to the shopping list.

Features (from upstream README):

- **Native apps**: iOS, Android, Desktop, Web (Flutter cross-platform)
- **Real-time multi-user sync** — shopping list updates live
- **Partial offline support** — still-works at the supermarket
- **Recipe management + sharing**
- **Meal plans** — weekly plan with list-add suggestions
- **Expense + balance tracking** — household finance
- **Home Assistant integration** via HACS
- **Weblate translations** (many languages)
- **Docker + docker-compose deployment**

- Upstream repo: <https://github.com/TomBursch/kitchenowl>
- Homepage: <https://kitchenowl.org>
- Docs: <https://docs.kitchenowl.org>
- Self-host docs: <https://docs.kitchenowl.org/latest/self-hosting/>
- Matrix: <https://matrix.to/#/#kitchenowl:matrix.org>
- Translations: <https://hosted.weblate.org/engage/kitchenowl/>
- Play Store: <https://play.google.com/store/apps/details?id=com.tombursch.kitchenowl>
- F-Droid: <https://f-droid.org/packages/com.tombursch.kitchenowl/>
- App Store: <https://apps.apple.com/app/kitchenowl/id1557453670>
- HACS integration: <https://github.com/TomBursch/kitchenowl-ha>
- Docker Hub: <https://hub.docker.com/r/tombursch/kitchenowl>

## Architecture in one minute

- **Flutter** frontend (cross-platform native + web)
- **Python/Flask** backend — REST + WebSocket
- **PostgreSQL** or **SQLite** — DB
- **Resource**: modest — 200-500MB RAM
- **Port 8080** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Per upstream self-host docs**                                 | **Primary path**                                                                   |
| Kubernetes / Helm  | Community chart                                                         | Homelab k8s                                                                                   |
| Bare-metal Python  | Flask app + DB                                                                              | DIY                                                                                               |
| Native mobile apps | Install on iOS/Android; connect to self-hosted backend                                                                                                | For end users                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `kitchen.example.com`                                       | URL          | TLS recommended                                                                                    |
| DB                   | Postgres or SQLite                                          | DB           | Postgres for multi-user                                                                                    |
| `JWT_SECRET_KEY`     | Session signing                                                                                    | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| Admin creds          | First-boot registration                                                                                         | Bootstrap    | Strong password                                                                                                            |
| Front-end URL        | Frontend app must know backend URL                                                                                                        | Connection   | Mobile apps need reachable URL                                                                                                                            |

## Install via Docker compose (upstream)

```yaml
services:
  kitchenowl:
    image: tombursch/kitchenowl:latest    # **pin specific version**
    container_name: kitchenowl
    restart: unless-stopped
    environment:
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
      - FRONT_URL=https://kitchen.example.com
    ports: ["8080:8080"]
    volumes:
      - ./kitchenowl-data:/data
```

See upstream docs at <https://docs.kitchenowl.org/latest/self-hosting/> for production setup with Postgres + reverse proxy.

## First boot

1. Start → browse URL → register first user (becomes admin-ish)
2. Create household
3. Invite partner / roommates
4. Add first shopping list item
5. Test real-time sync (open on 2 devices)
6. Install mobile apps + point at backend URL
7. Configure HA integration via HACS (optional)
8. Put behind TLS reverse proxy
9. Back up DB

## Data & config layout

- `/data/` — SQLite DB (if using) + uploads + caches
- Postgres volume (if using) — everything
- `.env` — JWT_SECRET_KEY + DB creds

## Backup

```sh
# SQLite
sudo tar czf kitchenowl-data-$(date +%F).tgz kitchenowl-data/
# Postgres
docker compose exec db pg_dump -U kitchenowl kitchenowl > kitchenowl-$(date +%F).sql
```

## Upgrade

1. Releases: <https://github.com/TomBursch/kitchenowl/releases>. Active + semver.
2. Docker: pull + restart; migrations run.
3. Follow release notes for breaking changes.
4. **Project still in active development per README** — keep an eye on changelog.

## Gotchas

- **"PROJECT STILL IN DEVELOPMENT"** warning from upstream README: KitchenOwl explicitly flags active-development status. Not "unstable" — but expect evolving features + occasional breaking changes. Recipe convention: honor upstream's self-stated maturity level. Recommend: pin image versions; test-upgrades in staging; don't run on mission-critical household workflows without backups.
- **REAL-TIME SYNC = WEBSOCKET REQUIREMENTS**: reverse proxy must support WebSocket upgrade (nginx proxy_pass with `Upgrade` + `Connection` headers; Caddy handles natively). Common homelab stumble.
- **MOBILE APPS NEED REACHABLE-FROM-MOBILE BACKEND URL**: if running behind Tailscale / VPN only, mobile apps must be on the same network. For on-the-go shopping, you need a public URL or tailnet access on phone.
- **HUB-OF-CREDENTIALS LIGHT**: KitchenOwl stores:
  - User accounts + JWT tokens
  - Household data (grocery history = personal habits)
  - Expense + balance data (household finance)
  - Recipes (your curated collection)
  - **46th tool in hub-of-credentials family — LIGHT tier** (moderate sensitivity; financial + grocery-habits)
- **HOUSEHOLD-FINANCIAL DATA = MILD REGULATORY**: expense tracking in KitchenOwl is lightweight household-level; not Bigcapital/Lunar/Invoice-class. Still: partner-facing financial transparency = threat model if relationship sours. **DV-threat-model sub-note** applies (reinforces SparkyFitness 94, Ryot 95): shared household apps must consider "what happens when household dissolves" scenarios — data access revocation, export-then-leave flows.
- **`JWT_SECRET_KEY` IMMUTABILITY**: **31st tool in immutability-of-secrets family.**
- **HOME ASSISTANT INTEGRATION = EXTERNAL-CREDENTIAL ATTACHMENT**: HACS integration stores KitchenOwl API key in HA config. Standard HA-integration pattern. HA user needs to understand they're adding auth surface.
- **FLUTTER APP DISTRIBUTION**: Play Store + App Store + F-Droid. F-Droid requires reproducible builds — signal of OSS-commitment. **F-Droid-available = OSS-rigor-signal**; not all self-hosted-apps make it to F-Droid due to dependency-on-non-free libraries. Positive signal.
- **AGPL-3.0** — if you modify KitchenOwl + expose it as a network service, you must publish changes. Fine for private household self-host.
- **SOLE-MAINTAINER-WITH-COMMUNITY**: Tom Bursch + Matrix community + translators. **14th tool in sole-maintainer-with-community class.**
- **SUSTAINABILITY**: no commercial-Cloud tier (unlike LinkAce/Kaneo/Ryot); no explicit sponsor-model visible. Pure community + sole-maintainer. **Fragility risk** — if Tom stops, community fork may be needed. **16th tool in pure-donation/community or sole-maintainer-sustainability-risk**.
- **TRANSPARENT-MAINTENANCE**: AGPL + Weblate + Matrix + docs + native apps + F-Droid + HACS + semver + "in-development" disclosure. **27th tool in transparent-maintenance family.**
- **TRANSLATION VIA WEBLATE** — pattern continues (Converse 96, Kometa 95).
- **MATRIX COMMUNITY** — not Discord; healthy signal for self-host-aligned project (matrix.org users are more-likely-self-hosters than Discord users).
- **OFFLINE-SUPPORT PARTIAL**: valuable for the at-the-supermarket use case. Partial = you can view + possibly add; sync when back online. Don't expect robust-offline-first like Obsidian.
- **EXPENSE-BALANCE FEATURE SCOPE**: household-finance-light. For serious household-finance, pair with Firefly III or Actual Budget. KitchenOwl expense-tracking is for the "who paid for groceries this week" casual case.
- **RECIPE STORAGE = YOUR CURATED COLLECTION**: valuable to you + hard-to-rebuild. Back up religiously. Recipe export for portability (verify support).
- **SHARED-RECIPE SOCIAL FEATURE**: if enabled, be mindful of DMCA if users upload copyrighted recipes from cookbooks. **Recipe-copyright nuance** — recipes in USA are NOT copyrightable as ingredients-lists; the DESCRIPTIVE TEXT / narrative is. Fine line.
- **ALTERNATIVES WORTH KNOWING:**
  - **Mealie** — recipe-focused; FastAPI+Vue; AGPL; heavier recipe-centric
  - **Tandoor Recipes** — recipe-focused; Django; AGPL; strong recipe-import + meal-planning
  - **Grocy** — household-inventory-focused; PHP; MIT; more "what's-in-the-freezer" than list-focused
  - **Paprika** — commercial recipe-app; native-desktop+mobile; paid
  - **AnyList** — commercial grocery-list app; freemium
  - **OurGroceries** — commercial grocery list; freemium; has ads
  - **Bring!** — commercial grocery list; free + ads
  - **Recipe + Grocery combined (like KitchenOwl):**
    - **Cooklist** — commercial
    - **Paprika** — commercial
  - **Choose KitchenOwl if:** you want BALANCED (lists + recipes + meal plan + expenses) + native apps + AGPL + Flutter.
  - **Choose Mealie if:** you want recipe-centric with better import + stronger recipe features.
  - **Choose Tandoor if:** you want Django + strong recipe-import + shopping lists.
  - **Choose Grocy if:** you want inventory-centric (track what's in your fridge + freezer + pantry, not just the shopping list).
  - **Choose commercial AnyList/Paprika if:** you accept paid + want polish + no self-host burden.
- **PROJECT HEALTH**: active + AGPL + native apps + F-Droid + HACS + Weblate + Matrix. Strong community engagement; sustainability depends on sole-maintainer continuation.

## Links

- Repo: <https://github.com/TomBursch/kitchenowl>
- Homepage: <https://kitchenowl.org>
- Docs: <https://docs.kitchenowl.org>
- Self-host: <https://docs.kitchenowl.org/latest/self-hosting/>
- Matrix: <https://matrix.to/#/#kitchenowl:matrix.org>
- Translations: <https://hosted.weblate.org/engage/kitchenowl/>
- HACS integration: <https://github.com/TomBursch/kitchenowl-ha>
- Docker: <https://hub.docker.com/r/tombursch/kitchenowl>
- Mealie (alt): <https://mealie.io>
- Tandoor (alt): <https://tandoor.dev>
- Grocy (alt): <https://grocy.info>
- Paprika (commercial alt): <https://www.paprikaapp.com>
