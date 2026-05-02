# Workout Challenge

**What it is:** A self-hosted fitness competition web app. Run step challenges, distance competitions, or calorie contests with friends and colleagues across any device or fitness tracker (Apple, Android, Garmin, etc.). Participants connect Strava for automatic workout import or log manually. Earns points proportionally to goal progress with configurable caps/floors for fair play.

**Official URL:** https://github.com/vanalmsick/workout_challenge
**Docker Hub:** `vanalmsick/workout_challenge`
**License:** MIT
**Stack:** Django (Python) + PostgreSQL + Celery + Redis

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended for production |
| Any Linux VPS / bare metal | Docker run (quick try) | Single container, SQLite fallback |
| Homelab | Docker Compose | Needs PostgreSQL + Redis sidecars |

---

## Inputs to Collect

### Pre-deployment
- `MAIN_HOST` — public URL (e.g. `http://your-url.com`) — required for email links and Strava OAuth
- `HOSTS` — comma-separated list of allowed hosts (same as MAIN_HOST plus `localhost`)
- `SECRET_KEY` — random string for Django crypto (`openssl rand -hex 32`)
- `TIME_ZONE` — e.g. `Europe/London`
- PostgreSQL credentials: `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
- Email/SMTP: `EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD`, `EMAIL_FROM`

### Optional integrations
- Strava: `STRAVA_CLIENT_ID` + `STRAVA_CLIENT_SECRET` — from https://www.strava.com/settings/api
- `OPENAI_API_KEY` — optional AI features
- `SENTRY_DSN` — error tracking

---

## Software-Layer Concerns

**Quick try (no PostgreSQL):**
```bash
docker run -p 80:80 -e ALLOW_ALL_HOSTS=true vanalmsick/workout_challenge
```

**Production Docker Compose:**
```yaml
services:
  workoutchallenge:
    image: vanalmsick/workout_challenge
    ports:
      - "80:80"
      # Do NOT expose publicly:
      # - "5555:5555"  # Celery Flower (debug)
      # - "9001:9001"  # Supervisord (debug)
      # - "8000:8000"  # Django admin (debug)
    volumes:
      - ./data:/workout_challenge/src-backend/data
    environment:
      - POSTGRES_HOST=workoutchallenge-database
      - POSTGRES_DB=workoutchallenge
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - MAIN_HOST=http://your-url.com
      - HOSTS=http://your-url.com,http://localhost
      - SECRET_KEY=<random>
      - TIME_ZONE=Europe/London
      - EMAIL_HOST=smtp.gmail.com
      - EMAIL_PORT=465
      - EMAIL_HOST_USER=you@example.com
      - EMAIL_HOST_PASSWORD=password
      - EMAIL_USE_SSL=True
      - EMAIL_FROM=competition@yourdomain.com
      # Optional Strava:
      - STRAVA_CLIENT_ID=000000
      - STRAVA_CLIENT_SECRET=<secret>
```

**Ports (internal use only — do not expose to internet):**
- `5555` — Celery Flower task monitoring
- `9001` — Supervisord process monitoring
- `8000` — Django admin panel

**Email schedule:**
- Monday: weekly leaderboard email to all participants
- Thursday (optional): personal progress email

**Strava sync:** Runs daily at 4 AM via Celery. Participants link their free Strava account through the web UI.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **MAIN_HOST required for Strava OAuth** — Strava redirect URI must match exactly; use the full URL including protocol
- **Do not expose debug ports** (5555, 9001, 8000) to the public internet — for LAN/debugging only
- **Cross-device compatibility by design** — points are based on % progress toward goal, so Apple Watch users and Garmin users compete on equal footing
- **Strava API limits** — daily sync at 4 AM; manual workouts can be added instantly via web UI
- **Min/max caps per workout/day/week** — configure these to prevent a single ultra-marathon from dominating; makes the competition about consistency

---

## Links
- GitHub: https://github.com/vanalmsick/workout_challenge
- Docker Hub: https://hub.docker.com/r/vanalmsick/workout_challenge
- Strava API setup: https://www.strava.com/settings/api
