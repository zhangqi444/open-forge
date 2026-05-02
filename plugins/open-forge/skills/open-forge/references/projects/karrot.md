# Karrot

**What it is:** An activity planning and community coordination platform for grassroots initiatives — food-saving groups, community gardens, neighborhood collectives, etc. Features group management, activity scheduling, recurring pickups, member trust levels, notifications, and a community forum. Federated via ActivityPub. Used by real food-saving groups worldwide.

**Official URL:** https://docs.karrot.world
**Backend repo:** https://codeberg.org/karrot/karrot-backend
**Frontend repo:** https://codeberg.org/karrot/karrot-frontend
**License:** AGPL-3.0
**Stack:** Django (Python) + Vue.js + PostgreSQL + Redis + Celery

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS | Docker Compose | Standard production deploy |
| Linux VPS | Manual (Python venv) | Developer/advanced setup |

---

## Inputs to Collect

### Pre-deployment
- PostgreSQL credentials — database, user, password, host
- Redis URL — for Celery task queue and caching
- `SECRET_KEY` — Django secret key (generate with `python -c "import secrets; print(secrets.token_hex(50))"`)
- `ALLOWED_HOSTS` — your domain (e.g. `karrot.example.com`)
- Email settings — SMTP host, port, user, password, from address (required for notifications)
- `HOSTNAME` — public hostname used in links sent in emails/notifications

---

## Software-Layer Concerns

**Refer to the official deployment docs:** The Karrot project maintains up-to-date deployment documentation at https://docs.karrot.world — follow it for production setup as the configuration can change between versions.

**Key services required:**
- **PostgreSQL** — primary database
- **Redis** — Celery broker and Django cache backend
- **Celery worker** — processes background tasks (notifications, recurring activities)
- **Celery beat** — schedules periodic tasks
- **Web/WSGI** — Django served via gunicorn

**Developer local setup:**
```bash
python -m venv .venv
source .venv/bin/activate
./sync.py           # install deps
./scripts/dev       # starts all services
```
Services available locally: API at `localhost:8000`, pgweb at `localhost:8081`, maildev at `localhost:1080`.

**Frontend:** Deploy `karrot-frontend` separately, or download a pre-built release archive from https://codeberg.org/karrot/karrot/releases and set `FRONTEND_DIR` to the unpacked folder.

**ActivityPub:** Karrot supports federation — groups and activities can be visible to other ActivityPub-compatible platforms.

**Upgrade procedure:**
1. Pull the latest images / `git pull`
2. Run database migrations: `python manage.py migrate`
3. Restart all services

---

## Gotchas

- **Two repos** — backend (`karrot-backend`) and frontend (`karrot-frontend`) are separate; both need to be deployed or use a pre-built frontend archive
- **Celery is required** — without the Celery worker and beat scheduler, notifications, recurring activities, and background tasks won't function
- **Email is essential** — Karrot relies heavily on email notifications for activity reminders and member management; configure SMTP before inviting users
- **AGPL-3.0** — if you modify and distribute Karrot, you must release your modifications
- **Community-focused** — designed for groups with multiple members and trust levels; not a single-user tool

---

## Links
- Docs: https://docs.karrot.world
- Backend: https://codeberg.org/karrot/karrot-backend
- Frontend: https://codeberg.org/karrot/karrot-frontend
- Releases: https://codeberg.org/karrot/karrot/releases
