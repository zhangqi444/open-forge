# Wagtail

Open-source CMS built on Django. Used by NASA, Google, MIT, the NHS, Mozilla, and the UK government. Focused on editor experience, developer flexibility, and scale. Supports headless/API mode, StreamField for flexible content, image management, multi-site, and multi-language. BSD 3-Clause. 18K+ GitHub stars. Upstream: <https://github.com/wagtail/wagtail>. Docs: <https://docs.wagtail.org>.

Wagtail is a **Django app** — you don't deploy Wagtail itself, you deploy a Django project that uses Wagtail. Self-hosting typically means containerizing your own Django/Wagtail project with PostgreSQL and optional Redis + Elasticsearch.

## Compatible install methods

Verified against upstream README at <https://github.com/wagtail/wagtail>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `pip install wagtail` + `wagtail start` | Core CLI scaffold | ✅ | Generate a new Django/Wagtail project from scratch. |
| Docker Compose (bakerydemo) | <https://github.com/wagtail/bakerydemo> | ✅ | Reference deploy — PostgreSQL + Redis + Django. Good starting point. |
| Docker (custom image) | Build your own Dockerfile | ✅ | Standard production path: containerize your Django/Wagtail project. |
| Wagtail Space / Managed hosting | Various providers | Community | Providers that host Wagtail: Heroku, Render, Railway, DigitalOcean App Platform. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| secret_key | "Django SECRET_KEY (generate: `openssl rand -hex 50`)?" | Free-text (sensitive) | All |
| db_password | "PostgreSQL password?" | Free-text (sensitive) | All |
| domain | "Public domain (e.g. `cms.example.com`)?" | Free-text | Production |
| media_storage | "Where to store uploaded media?" | `AskUserQuestion`: `Local filesystem (Docker volume)` / `S3 / S3-compatible (Cloudflare R2, MinIO)` | All |
| search_backend | "Search backend?" | `AskUserQuestion`: `PostgreSQL full-text (built-in)` / `Elasticsearch` | Optional |

## Software-layer concerns

### Quick scaffold (new project)

```bash
pip install wagtail
wagtail start mysite
cd mysite
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Access admin at `http://localhost:8000/cms` (default Wagtail admin URL).

### Docker Compose (bakerydemo reference)

```bash
git clone https://github.com/wagtail/bakerydemo
cd bakerydemo
cp .env.example .env   # edit credentials
docker compose up
docker compose exec app python manage.py migrate
docker compose exec app python manage.py load_initial_data  # load demo content
```

**bakerydemo `docker-compose.yml` services:**

| Service | Image | Port |
|---|---|---|
| `app` | Custom Dockerfile (Django/Wagtail) | 8000 |
| `db` | `postgres:18` | 5432 |
| `redis` | `redis:8` | 6379 |

### Key environment variables

| Variable | Purpose |
|---|---|
| `DJANGO_SECRET_KEY` | Django session/CSRF — **change from default** |
| `DATABASE_URL` | e.g. `postgres://user:pass@db:5432/mydb` |
| `REDIS_URL` | e.g. `redis://redis:6379` |
| `DJANGO_SETTINGS_MODULE` | e.g. `mysite.settings.production` |
| `DJANGO_ALLOWED_HOSTS` | Comma-separated hostnames |
| `WAGTAILADMIN_BASE_URL` | Full base URL e.g. `https://cms.example.com` (used in emails) |
| `EMAIL_HOST` / `EMAIL_PORT` | SMTP for notifications |
| `DEFAULT_FILE_STORAGE` | Set to S3/R2 backend for cloud media |
| `AWS_STORAGE_BUCKET_NAME` | S3 bucket for `django-storages` |

### Admin URL

Wagtail's admin panel lives at `/cms/` by default. To change it, set `WAGTAILADMIN_BASE_URL` and configure `wagtail_urls` in your project's `urls.py`.

### Search backends

Wagtail supports multiple search backends:

| Backend | Package | Notes |
|---|---|---|
| PostgreSQL (default) | Built-in | Full-text search via `pg_search`. No extra services. |
| Elasticsearch | `wagtail[elasticsearch]` | More powerful; requires ES 7.x or 8.x running separately. |

### Media file handling

| Storage | When to use |
|---|---|
| Local (`MEDIA_ROOT`) | Development or single-server deploys. Use a Docker volume. |
| S3 / S3-compatible | Multi-server, CDN offload, or container restarts. Install `django-storages[s3]`. |

### Image renditions

Wagtail auto-generates image variants (thumbnails, crops) on demand and caches them. In production, ensure your `MEDIA_ROOT` volume or S3 bucket is persistent and writable.

### Data directories

| Path | Contents |
|---|---|
| `MEDIA_ROOT` (default: `media/`) | Uploaded images, documents, and generated renditions |
| `STATIC_ROOT` | Collected static files (CSS/JS for admin + frontend) |
| PostgreSQL volume | All Wagtail data — pages, images, revisions, users |

### Multi-site setup

Wagtail supports multiple sites from a single installation via the **Sites** settings in the admin panel. Each site maps a hostname + port to a root page.

### Headless / API mode

Wagtail's built-in API (headless mode) is enabled by adding `wagtail.api.v2` to `INSTALLED_APPS` and configuring API endpoints. Returns JSON for pages, images, and documents — suitable for React/Next.js/Nuxt frontends.

## Upgrade procedure

1. Upgrade `wagtail` in `requirements.txt`
2. Rebuild your Docker image: `docker compose build app`
3. Run migrations: `docker compose exec app python manage.py migrate`
4. Restart: `docker compose up -d`

Always check the [Wagtail release notes](https://docs.wagtail.org/en/stable/releases/) and migration guide before upgrading major versions.

## Gotchas

- **Wagtail is a Django app, not a standalone server.** You need to build and maintain a Django project. There is no off-the-shelf Docker image (unlike WordPress) — use bakerydemo as your starting template or build your own.
- **`SECRET_KEY` must be changed.** Default scaffolded projects ship with an insecure key. Rotate immediately and never commit to source control.
- **Media files are not in the database.** Uploaded images and documents live in `MEDIA_ROOT` (or S3). Backup both the database and your media storage.
- **Image renditions are cached.** Don't delete `MEDIA_ROOT/images/` — Wagtail stores generated thumbnails there. If you delete them, they will be regenerated on next request.
- **Static files must be collected.** Run `python manage.py collectstatic` in production. Serve via WhiteNoise or a CDN; don't serve from Django directly.
- **Admin URL is `/cms/` not `/admin/`.** Configure appropriately in your `urls.py`.
- **Page revisions accumulate.** Wagtail stores every page revision. For content-heavy sites, periodically purge old revisions: `python manage.py purge_revisions --days=90`.
- **License: BSD 3-Clause.** Fully open-source.

## Links

- Upstream: <https://github.com/wagtail/wagtail>
- Docs: <https://docs.wagtail.org>
- Getting started tutorial: <https://docs.wagtail.org/en/stable/getting_started/tutorial.html>
- Deploying Wagtail: <https://docs.wagtail.org/en/stable/deployment/index.html>
- Bakerydemo reference project: <https://github.com/wagtail/bakerydemo>
- Headless API: <https://docs.wagtail.org/en/stable/advanced_topics/api/v2/usage.html>
- Wagtail Space (community): <https://wagtail.org/wagtail-space/>
