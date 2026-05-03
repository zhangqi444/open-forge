# Refeed

> Open-source RSS reader with timed bookmarks (auto-expire after a set time), keyword/author filters, bookmark folders, inline note-taking, fullscreen reading mode, full-content fetching, and newsletter-to-RSS conversion via a custom email address. Next.js web app backed by Supabase (self-hostable or hosted).

**Official URL:** https://github.com/michaelkremenetsky/Refeed  
**Live demo:** https://refeedreader.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; requires Supabase |
| Any Linux VPS/VM | Node.js (pnpm) | Build from source |

> **Dependency:** Refeed requires a [Supabase](https://supabase.com/) instance — either self-hosted via Docker or the Supabase hosted platform. There is no bundled database.

---

## Inputs to Collect

### Phase: Supabase Setup
| Input | Description | Example |
|-------|-------------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | `https://xxxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon/public key | from Supabase dashboard |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key | from Supabase dashboard |
| `DATABASE_URL` | Postgres connection string | `postgresql://...` |

### Phase: Image Storage
| Input | Description | Example |
|-------|-------------|---------|
| `IMAGE_ACCOUNT_ID` | Cloudflare Images account ID | `abc123` |
| `IMAGE_ACCESS_KEY_ID` | Image storage access key ID | from provider |
| `IMAGE_ACCESS_KEY_SECRET` | Image storage secret | from provider |
| `IMAGE_BUCKET_URL` | URL for article image storage | `https://...` |
| `ICON_BUCKET_URL` | URL for favicon/icon storage | `https://...` |

---

## Software-Layer Concerns

### Architecture
- **Frontend/API:** Next.js (pnpm monorepo with Turborepo)
- **Database/Auth:** Supabase (Postgres + Auth + Storage)
- **Schema:** Must run the [setup SQL](https://github.com/michaelkremenetsky/Refeed/blob/main/setup/SUPABASE.sql) in the Supabase SQL Editor before first use

### Setup Steps (Self-Hosted)
1. Clone repo: `git clone http://github.com/michaelkremenetsky/personal-refeed-version refeed`
2. Set up Supabase (self-hosted Docker or hosted platform)
3. Run the setup SQL in the Supabase SQL Editor
4. Copy `.env.example` to `.env` and fill in all required variables
5. `pnpm db:push`
6. `docker-compose up --build`

### Ports
| Service | Port |
|---------|------|
| Web UI  | `3000` |

---

## Upgrade Procedure

1. Pull latest: `git pull`
2. Rebuild: `docker-compose up --build -d`
3. Run any new migrations: `pnpm db:push`
4. Check logs for errors

---

## Gotchas

- **Supabase is a hard dependency** — there is no alternative DB backend; you must run or connect to a Supabase instance
- **Image storage requires external object storage** — Cloudflare Images credentials are needed for article images and favicons; no local storage fallback documented
- **Mobile app does not support self-hosted** — the iOS/Android app connects to the hosted service only; self-hosted is web-only
- **Monorepo/pnpm setup** — requires pnpm, not npm or yarn; the build process involves Turborepo
- **No built-in HTTPS** — proxy with Nginx/Caddy behind TLS for production use

---

## Links
- GitHub: https://github.com/michaelkremenetsky/Refeed
- Self-hosting guide: https://github.com/michaelkremenetsky/Refeed/blob/main/setup/SELFHOSTING.md
- Setup SQL: https://github.com/michaelkremenetsky/Refeed/blob/main/setup/SUPABASE.sql
