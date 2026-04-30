---
name: workout.cool
description: "Modern, open-source fitness coaching platform — workout builder, exercise database (videos + instructions), tracking, progress charts. Next.js + Postgres + Prisma. MIT. Self-hostable; also on workout.cool as free SaaS."
---

# workout.cool

workout.cool is a **modern, open-source fitness-coaching web app** — pick exercises from a comprehensive visual database (with video demos + muscle targeting), build workouts, track sets/reps/weight, see progress charts. Think "open-source Fitbod / Strong / Hevy" with a browser-first UX.

Use cases:

- **Home/gym workout tracking** — log what you did, see improvement
- **Personal trainer tool** — build programs for clients; clients track via the app
- **Self-coaching** — use the library to design your own program
- **Family gym log** — everyone in the household tracks

Features:

- **Exercise database** — hundreds of exercises with videos, muscle groups, equipment, difficulty
- **Workout builder** — drag-and-drop, supersets, circuits
- **Tracking** — sets, reps, weight, RPE, rest timer
- **Progress charts** — 1RM estimates, volume over time, personal records
- **Program templates** — push/pull/legs, 5/3/1, Starting Strength, etc.
- **Workout history** — full calendar view
- **Multi-language** — EN/FR/DE/ES/JA/KO/PT/RU/ZH
- **Progressive Web App** — install on phone home screen
- **Self-host or use the hosted SaaS** (free at workout.cool)

- Upstream repo: <https://github.com/Snouzy/workout-cool>
- Website / hosted: <https://workout.cool>
- Discord: <https://discord.gg/NtrsUBuHUB>
- Ko-fi: <https://ko-fi.com/workoutcool>

## Architecture in one minute

- **Next.js 14+** (App Router) — full-stack TypeScript
- **Postgres** (via Prisma ORM) — users, workouts, sessions, exercise library
- **NextAuth.js** — auth (email magic links, OAuth providers)
- **Tailwind CSS** + shadcn/ui — UI
- **Video hosting** — exercises ship as video URLs; external (YouTube / Cloudflare Stream / self-host)
- **Internationalization** — i18next
- **Vercel**-first deployment (but any Node host works)

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                             |
| ----------- | ------------------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | **Docker** (community; check current)                      | Build from the repo Dockerfile                                          |
| Vercel      | **Push-to-deploy** (matches upstream stack)                    | **Easiest**                                                               |
| Kubernetes  | DIY — Next.js + managed Postgres                                  | Works                                                                             |
| Managed     | workout.cool (free hosted)                                               | Supports project                                                                          |
| Raspberry Pi | arm64 Node build                                                         | Workable for single-user                                                                          |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                              |
| ----------------- | ------------------------------- | --------- | ------------------------------------------------------------------ |
| Domain            | `workout.example.com`             | URL       | `NEXTAUTH_URL` must match                                              |
| Postgres          | creds                                 | DB        | Managed Postgres (Neon, Supabase) simplifies                                   |
| NEXTAUTH_SECRET   | random 32 chars                          | Auth      | Don't rotate                                                                           |
| SMTP              | host/port/user/pass                           | Email     | For magic-link login                                                                               |
| OAuth (opt)       | Google/GitHub client id + secret                  | Auth      | Enables social login                                                                                       |
| Exercise DB seed  | imported on first migrate                            | Data      | Ships as JSON with the repo                                                                                             |
| Video provider    | YouTube (default) / Cloudflare Stream / local       | Media     | Upstream default uses YouTube embeds                                                                                              |

## Install via Docker (build locally)

Upstream publishes source; build your own image:

```sh
git clone https://github.com/Snouzy/workout-cool.git
cd workout-cool
# Create .env (see .env.example)
docker build -t workout-cool:local .
```

```yaml
services:
  workout-cool:
    image: workout-cool:local          # or pinned community image if available
    restart: unless-stopped
    depends_on: [db]
    environment:
      DATABASE_URL: postgresql://wc:<strong>@db:5432/workout?schema=public
      NEXTAUTH_URL: https://workout.example.com
      NEXTAUTH_SECRET: <32-random-chars>
      EMAIL_SERVER_HOST: smtp.example.com
      EMAIL_SERVER_PORT: "587"
      EMAIL_SERVER_USER: ...
      EMAIL_SERVER_PASSWORD: ...
      EMAIL_FROM: "Workout <no-reply@example.com>"
      # Optional OAuth
      GOOGLE_CLIENT_ID: ...
      GOOGLE_CLIENT_SECRET: ...
    ports:
      - "3000:3000"

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: wc
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: workout
    volumes:
      - wc-db:/var/lib/postgresql/data

volumes:
  wc-db:
```

On first boot: `docker exec workout-cool npx prisma migrate deploy` + seed exercise DB per upstream instructions.

## Install via Vercel

1. Fork the repo
2. Attach Neon/Supabase Postgres
3. Add env vars in Vercel dashboard
4. Deploy — builds + migrates automatically

## First boot

1. Browse the site → sign up (magic link or OAuth)
2. Exercise Library → browse by muscle group / equipment
3. Workouts → Create → drag exercises in → save as template
4. Start a session → log sets/reps/weight; rest timer runs
5. History + charts → see progress

## Data & config layout

- Postgres: users, workouts, sessions, set-logs, personal records
- Exercise DB: seeded from repo's JSON; static metadata
- Video URLs: stored in exercise records (YouTube embed IDs or custom URLs)
- `.env` / env vars — secrets

## Backup

```sh
docker exec wc-db pg_dump -U wc workout | gzip > workout-$(date +%F).sql.gz
```

## Upgrade

1. Releases: <https://github.com/Snouzy/workout-cool/releases>. Active.
2. **Back up DB first** — Prisma migrations happen on deploy.
3. Rebuild image or pull newer version; `prisma migrate deploy` runs.
4. Vercel: reconnect + redeploy.
5. Read release notes for exercise-DB schema changes (additions are common).

## Gotchas

- **Early-ish project** — moving fast; expect occasional UX changes and schema migrations. Read release notes before upgrading.
- **Exercise video source** — if upstream uses YouTube embeds, and YouTube later changes embed policy or the channel goes offline, videos 404. For long-term reliability, self-host videos (S3 / Cloudflare Stream / local MP4s).
- **Video copyright** — upstream exercise videos are curated; if you fork + rehost commercially, verify licenses.
- **Multi-user model** — each user has their own workouts. For "trainer with clients," check current permissions (may still be evolving).
- **Units**: metric vs imperial (kg/lbs, kg vs lb, cm vs in). Per-user setting. Check current state before deploying for mixed audiences.
- **Rest timer** — relies on browser tab staying active; mobile backgrounding may pause it. PWA helps.
- **Personal records** auto-tracked; 1RM formulas (Epley/Brzycki/Lombardi) vary — check which one is displayed.
- **Supersets / circuits** — supported; complex program types (EMOM, AMRAP, Tabata) may or may not be yet.
- **Import/export** — JSON export of your workouts; less fleshed out than competitors (Hevy/Strong).
- **Data ownership** — self-host = yours. Hosted workout.cool = on their servers (free but see their TOS).
- **AI features** — upstream may add AI form-check or routine generation; verify if opt-in and if data leaves your instance.
- **Mobile**: PWA works great on phones; consider "Add to Home Screen" for gym usage.
- **Offline**: PWA supports some offline; check current state for "log workout without internet at the gym."
- **SMTP is required** for magic-link auth by default — fall back to OAuth if you don't want SMTP.
- **Auth secrets**: don't rotate `NEXTAUTH_SECRET` without expiring all sessions.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **wger** — older OSS workout manager; Python/Django; has mobile app (separate recipe)
  - **Hevy / Strong / Fitbod / Hevy Coach** — commercial SaaS/mobile
  - **FitNotes** (Android) — minimalist local log
  - **Google Sheets** — many lifters still use a spreadsheet
  - **Exercise.com / TrueCoach** — commercial trainer-client platforms
  - **Gymrats / Fitocracy** (defunct) — historical
  - **Choose workout.cool if:** you want a modern OSS web/PWA workout platform with built-in exercise DB.
  - **Choose wger if:** you want a mature Python-based tool + mobile app.
  - **Choose FitNotes if:** you just want simple local workout logging.
  - **Choose commercial SaaS if:** you want polish + don't want to host.

## Links

- Repo: <https://github.com/Snouzy/workout-cool>
- Website (hosted): <https://workout.cool>
- Discord: <https://discord.gg/NtrsUBuHUB>
- Ko-fi: <https://ko-fi.com/workoutcool>
- Releases: <https://github.com/Snouzy/workout-cool/releases>
- Self-hosting section (in README): <https://github.com/Snouzy/workout-cool#deployment--self-hosting>
- Exercise DB import section: <https://github.com/Snouzy/workout-cool#exercise-database-import>
- Vercel OSS program: <https://vercel.com/oss>
- wger alternative: <https://github.com/wger-project/wger>
- Translation: <https://readme-i18n.com/Snouzy/workout-cool>
