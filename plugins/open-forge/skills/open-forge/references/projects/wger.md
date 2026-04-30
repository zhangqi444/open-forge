---
name: wger
description: "Self-hosted workout manager + nutrition tracker — exercise database (~500 exercises), workout plan builder, nutrition/calorie tracking, body-weight log, progress charts, BMI/calorie calculators. Mobile app. Django + Vue.js. AGPL-3.0."
---

# wger

wger (pronounced *vay-ger*) is **a self-hosted workout manager + nutrition tracker** — plan your weightlifting / bodyweight / cardio routines, log nutrition + calorie intake, record body weight over time, follow an exercise library with demo images/GIFs, generate workout plans, and track progress charts. Cross-platform: web + official mobile app.

Long-running European open-source project (started 2013).

Features:

- **Exercise database** — ~500+ exercises with descriptions, images, muscle-group tags, variations (community-contributed + translated)
- **Workout plans** — create custom routines; log sets/reps/weight per session
- **Workout schedule** — rotate through multiple plans
- **Nutrition tracking** — build meal plans; log actual intake; calorie/macro summary
- **Food database** — USDA + Open Food Facts (ingredient barcode lookup)
- **Weight log** + chart
- **Measurements log** — chest/arms/waist/etc.
- **Progress charts** — weight, lifts, volume over time
- **BMI + calorie calculator**
- **Mobile app** — Android + iOS
- **REST API**
- **i18n** — many languages; community-translated
- **Public demo server** — wger.de

- Upstream repo: <https://github.com/wger-project/wger>
- Website: <https://wger.de>
- Docs: <https://wger.readthedocs.io/en/latest/>
- Docker repo: <https://github.com/wger-project/docker>
- Android app: <https://f-droid.org/en/packages/de.rapilabs.wger/>
- Google Play: <https://play.google.com/store/apps/details?id=de.rapilabs.wger>

## Architecture in one minute

- **Django (Python)** backend with Django REST Framework
- **Vue.js** frontend (newer SPA) + classic Django templates
- **Celery + Redis** for background tasks (exercise image sync, etc.)
- **DB**: **Postgres** (recommended) or **SQLite** (dev)
- **Static files**: Nginx serves exercise images + JS/CSS
- **Docker Compose** is the blessed self-host path
- **Resource**: ~500 MB RAM for the full stack

## Compatible install methods

| Infra              | Runtime                                                      | Notes                                                                       |
| ------------------ | ------------------------------------------------------------ | --------------------------------------------------------------------------- |
| Single VM          | **Docker Compose (`wger-project/docker`)**                       | **Upstream-documented primary path**                                            |
| Single VM          | Native Django install                                                    | Fiddly; requires Python + PG + Redis + Nginx manual                                      |
| Kubernetes         | Community manifests                                                                   | Works                                                                                              |
| Managed            | **wger.de** (free public instance)                                                              | Use this if you just want the app                                                                                  |
| Raspberry Pi       | arm64 Docker                                                                                              | Works fine                                                                                                                 |

## Inputs to collect

| Input              | Example                               | Phase      | Notes                                                                    |
| ------------------ | ------------------------------------- | ---------- | ------------------------------------------------------------------------ |
| Domain             | `wger.example.com`                        | URL        | For app + API                                                                     |
| Django SECRET_KEY  | `openssl rand -hex 32`                         | Security   | Required                                                                                |
| DB creds           | Postgres user/pass                                | DB         | Docker Compose sets up                                                                                |
| SMTP (opt)         | for password resets + notifications                    | Email      | Nice-to-have                                                                                                  |
| Admin user         | created via `wger createsuperuser`                              | Bootstrap  | Or via first-boot wizard                                                                                                                |
| Exercise images    | synced from wger.de on first boot                                       | Feature    | ~1 GB; optional but great UX                                                                                                                                |

## Install via Docker Compose

```sh
git clone https://github.com/wger-project/docker.git wger-docker
cd wger-docker
cp config/prod.env.example config/prod.env
# Edit config/prod.env: set SECRET_KEY, DB passwords, domain
docker compose -f docker-compose.yml up -d
```

Browse `http://<host>/` (or with reverse proxy at your domain).

On first start, the exercise DB + images sync from wger.de — takes a few minutes.

## First boot

1. Create admin: `docker compose exec web python manage.py createsuperuser`
2. Log in → **Training → Workout Plans → Create** → add exercises from library → sets/reps
3. **Nutrition → Meal Plans** → add foods → log intake
4. **Profile → Weight Log** → record weight; chart populates
5. Install mobile app → point at your self-host URL → sync your plan
6. Go work out

## Data & config layout

- Postgres — all user data (workouts, nutrition logs, weight, measurements)
- `exercise-images/` — static assets (can regenerate via sync)
- `media/` — user uploads (profile pictures, custom exercise images)
- `.env` — Django secret + DB creds

## Backup

```sh
# DB (critical — all user workout + nutrition history)
docker exec wger-db pg_dump -U wger wger | gzip > wger-db-$(date +%F).sql.gz
# Media uploads
tar czf wger-media-$(date +%F).tgz media/
```

## Upgrade

1. Releases: <https://github.com/wger-project/wger/releases>. Moderate cadence.
2. Back up DB + media.
3. `git pull && docker compose pull && docker compose up -d` → Django migrations run automatically.
4. Read release notes for config changes.

## Gotchas

- **Public wger.de vs self-host**: wger.de is free, open to all, supported by donations. If you don't need self-host + your data is OK on a public European server, just use wger.de. Self-host is for power users + privacy-strict + offline.
- **Exercise DB sync** requires outbound internet on first boot. For airgapped, pre-stage the exercise archive.
- **Mobile app** expects sync URL pointing at your instance. Configure in-app under Settings → Server.
- **Food database** is contributor-driven (Open Food Facts-like). Less comprehensive than commercial (MyFitnessPal) — for niche foods you may need to add manually.
- **Barcode scan**: mobile app can scan food barcodes → Open Food Facts lookup → add to log.
- **Multi-user**: supported; each user has isolated workouts + nutrition. No "trainer dashboard for coaching clients" UI yet.
- **No Apple HealthKit / Google Fit integration**: manual logging only. Some users script this via API.
- **Pre-built workout plans**: community-contributed; browse and adopt.
- **Measurement units**: metric by default; imperial supported — set in profile.
- **API** — Django REST Framework; docs at `/api/v2/`. Use for custom integrations (scripts, Home Assistant, dashboards).
- **Django admin** at `/admin/` — powerful but dangerous; use for seeded data only.
- **Celery worker**: required for async tasks (exercise sync). Make sure it's running.
- **Redis**: required for Celery broker.
- **Translations**: crowdsourced via Weblate; UI has many languages; exercise descriptions may be English-only for some entries.
- **Performance**: Django + PG scales well for single-user or small multi-user.
- **License**: **AGPL-3.0**.
- **Alternatives worth knowing:**
  - **Hevy** (SaaS) — polished commercial workout tracker
  - **Strong** (SaaS) — iOS-first workout tracker
  - **MyFitnessPal** (SaaS) — comprehensive food DB; commercial
  - **Cronometer** (SaaS) — nutrition-focused
  - **GymPad** — older
  - **OpenFitnessTracker** — niche OSS
  - **Google Fit / Apple Health** — passive tracking; no workout planning
  - **Choose wger if:** you want OSS, self-hosted, integrated workout + nutrition, privacy, mobile app.
  - **Choose Hevy/Strong if:** polished iOS-first UX + don't mind SaaS.
  - **Choose MyFitnessPal if:** nutrition DB is the most important feature.
  - **Choose wger.de (public)** if you want wger but not self-host ops.

## Links

- Repo: <https://github.com/wger-project/wger>
- Docker repo: <https://github.com/wger-project/docker>
- Website: <https://wger.de>
- Docs: <https://wger.readthedocs.io/en/latest/>
- Installation: <https://wger.readthedocs.io/en/latest/production.html>
- Releases: <https://github.com/wger-project/wger/releases>
- API docs: <https://wger.de/en/software/api>
- Android app: <https://f-droid.org/en/packages/de.rapilabs.wger/>
- iOS app: check <https://wger.de>
- Discord / Matrix: via wger.de
- Translations: <https://hosted.weblate.org/projects/wger/>
- Open Food Facts (food DB): <https://world.openfoodfacts.org>
