---
name: Misskey
description: Federated (ActivityPub) social microblog server — a rich alternative to Mastodon with reactions, quote posts, drive (file manager), custom emoji, MFM (Markdown + emoji + styling). Node.js + Postgres + Redis. AGPL-3.0.
---

# Misskey

Misskey is the most feature-rich ActivityPub (Fediverse) server. Where Mastodon goes minimalist, Misskey goes "every feature": emoji reactions (like Discord), quote posts, custom themes, animated avatars, rich markdown (MFM), a "drive" file manager, chat channels, games, polls. Japanese-origin; very strong in EN/JP/ZH Fediverse communities.

- **ActivityPub** — federates with Mastodon, Pleroma, Akkoma, Pixelfed, PeerTube, Lemmy, etc.
- **Emoji reactions** (not just star/fav) — like/thumb/heart/any custom emoji
- **Quote posts** — a first-class feature (Mastodon keeps refusing to add this)
- **MFM (Markdown + Friends Markup)** — text formatting, animations (`$[shake text]`, `$[spin text]`), custom emoji inline
- **Drive** — file manager UI for your uploaded media
- **Antennas / lists** — saved timeline filters
- **Custom themes** per-user
- **Federated chat** — Matrix-style direct message channels (experimental across federation)
- **Role system** — fine-grained permissions for moderators
- **Registration control** — open/invite-only/approval-required
- **Federation blocking** — block problem instances at instance level

Forks worth knowing:

- **Sharkey** — Misskey fork with some Mastodon-compat tweaks
- **Firefish / Iceshrimp / CherryPick / Foundkey** — various forks

- Upstream repo: <https://github.com/misskey-dev/misskey>
- Project site: <https://misskey-hub.net>
- Docs: <https://misskey-hub.net/docs/>
- Install guide: <https://misskey-hub.net/docs/admin/install/docker/>
- Instance list: <https://join.misskey.page>

## Architecture in one minute

- **Misskey web** — Node.js (Fastify) monolith for API + frontend SSR + WebSocket
- **PostgreSQL 13+** — all app state (posts, users, follows, federation queue)
- **Redis** — caching, job queue, streaming
- **MeiliSearch** (optional) — full-text search; otherwise Postgres `pg_bigm`
- **Object storage** (optional) — S3/MinIO/R2 for media; otherwise local `./files/`
- **Port 3000** inside container

Reverse proxy **MUST** forward WebSockets (streaming timeline uses WS).

## Compatible install methods

| Infra       | Runtime                                            | Notes                                                             |
| ----------- | -------------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | Docker Compose (app + Postgres + Redis)             | **Upstream-documented** (the recommended path)                      |
| Single VM   | Native Node.js (PNPM) + external Postgres/Redis     | Power users                                                         |
| Kubernetes  | Community Helm chart                                  | Multiple community charts; no official                               |
| Managed     | <https://join.misskey.page> instances                  | Join someone else's server                                           |

## Inputs to collect

| Input                   | Example                                 | Phase     | Notes                                                        |
| ----------------------- | --------------------------------------- | --------- | ------------------------------------------------------------ |
| `url`                   | `https://social.example.com`              | DNS       | **PERMANENT** — baked into federation identity. **DO NOT CHANGE**. |
| Postgres host/user/pw   | bundled or external                       | DB        | Postgres 13+                                                 |
| Redis                   | bundled or external                       | Cache     |                                                              |
| Object storage (opt.)   | S3/MinIO bucket + creds                   | Storage   | Highly recommended for prod                                   |
| SMTP                    | host/port/user/pw/from                    | Email     | Signup verification + password reset                          |
| MeiliSearch (opt.)      | instance URL                              | Search    | For fast full-text search                                     |
| First admin             | via web UI on first signup                | Bootstrap | First-user-is-admin                                           |
| Captcha (opt.)          | hCaptcha / Turnstile                      | Antispam  | For public signup                                             |

## Install via Docker Compose

Use upstream's example compose file. Brief version:

```sh
git clone --depth 1 https://github.com/misskey-dev/misskey
cd misskey
git checkout 2026.5.1        # use a tagged release, NOT `develop`
# Copy the example configs:
cp .config/docker_example.yml .config/default.yml
cp .config/example.env .config/docker.env
cp docker-compose_example.yml docker-compose.yml
# Edit .config/default.yml — set `url`, DB creds, Redis, etc.
# Edit .config/docker.env — set POSTGRES_PASSWORD
docker compose up -d
```

Listens on port 3000 inside the container. Mount reverse proxy (nginx/Caddy) with WS passthrough for TLS.

### nginx example (WS-capable)

```nginx
server {
    listen 443 ssl http2;
    server_name social.example.com;
    client_max_body_size 80m;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## First boot

1. Browse `https://social.example.com`
2. **Sign up** — first account becomes admin
3. **Admin panel** (gear icon in top bar → "Control panel")
   - **Instance** → set name, description, icon, banner
   - **Registration** → invite-only? open? approval-required? captcha?
   - **Object storage** → configure S3/MinIO (highly recommended; local files get unmanageable)
   - **Email** → SMTP
   - **Federation** → default following/blocking behavior
4. **Write your first `note` (post)** — it federates to any remote follower
5. Follow remote accounts: `@user@other.example.com` format

## Data & config layout

- **`./files/`** — user-uploaded media (local storage mode)
- **`./redis/`** — Redis persistence (compose default: volume)
- **`./postgres/`** — Postgres data
- **`.config/default.yml`** — instance config
- **`.config/docker.env`** — env vars for compose services

## Backup

```sh
# DB (by far the most important)
docker compose exec -T db pg_dump -U misskey misskey | gzip > misskey-db-$(date +%F).sql.gz

# Media (if using local storage; not needed if on S3)
tar czf misskey-files-$(date +%F).tgz ./files

# Config
cp .config/default.yml .config/docker.env ~/backup/
```

**Redis** state is mostly cache/queue; **lose safely**, but expect ~minutes of federation delivery lag after restore as the queue rebuilds.

## Upgrade

1. Releases: <https://github.com/misskey-dev/misskey/releases>. Very active (weekly-ish).
2. **Pin to a tagged release** — do NOT run `develop` in production.
3. Pull new tag → `docker compose pull && docker compose up -d`. Migrations run on startup.
4. **Read CHANGELOG carefully** — minor versions occasionally add mandatory env/config changes.
5. **DB migrations are one-way** — back up first.
6. For major versions (like 2025.x → 2026.x), test on staging.

## Gotchas

- **`url` is federation identity and IS PERMANENT.** Once your instance has posted to the fediverse, your `@user@domain.com` handle is locked. Change `url` → remote followers' client caches now point to a dead-end; identity broken. Pick domain carefully.
- **ActivityPub requires HTTPS** — federation won't work over plain HTTP.
- **WebSockets required** — streaming timeline uses WS. Any reverse proxy must forward upgrades.
- **Redis loss** = queued federation outbox lost. Retries from remote servers recover most of it; some outbound posts may not deliver.
- **First-user-is-admin** — create the admin account FIRST, then switch registration to invite-only.
- **Run `develop` branch = game over** — it has breaking DB changes weekly. Stick to tagged releases.
- **Object storage strongly recommended** — local `./files/` grows fast with federation incoming media. S3/MinIO + CDN saves bandwidth + disk.
- **Media retention**: cached remote media can be purged periodically (admin panel → "Files" → clean old remote files).
- **Federation moderation**: "Block" an instance = no exchange with it; "Silence" = local users can't see it by default. Have a policy before federating — spam instances exist.
- **Reaction emoji** can be custom-uploaded — each federation server handles how remote reactions render; Mastodon clients show them as fav/star.
- **Quote posts** are supported locally, render as normal posts on Mastodon (with a link back).
- **MFM** renders richly on Misskey; degrades to plain markdown on Mastodon.
- **Heavy CPU during rapid federation** — a viral post incoming from a big instance can briefly spike. Tune Postgres + Redis for expected load.
- **Image optimization** — Misskey runs `sharp` on uploads; heavy. Consider disk/CPU budget for instances with active posters.
- **AGPL-3.0** — public instance = source-share obligation for any modifications.
- **Code of conduct**: Misskey the software has a CoC; **your instance has its own CoC** that federates with (or blocks) others' CoC conflicts. Think it through before opening registration.
- **Alternatives worth knowing:**
  - **Mastodon** — most popular, Ruby on Rails; simpler UX, fewer features; better for "Twitter-like minimalist" experience
  - **Pleroma / Akkoma** — Elixir, lighter weight, more flexible federation controls
  - **GoToSocial** — Go, super lightweight, minimal UI
  - **Pixelfed** — Instagram-like (image-focused)
  - **PeerTube** — federated video (see separate recipe)
  - **Bluesky / ATProto** — separate ecosystem; not ActivityPub
  - **Sharkey / Firefish / Iceshrimp** — Misskey forks with varying philosophies

## Links

- Repo: <https://github.com/misskey-dev/misskey>
- Project site: <https://misskey-hub.net>
- Docs: <https://misskey-hub.net/docs/>
- Install (Docker): <https://misskey-hub.net/docs/admin/install/docker/>
- Install (manual): <https://misskey-hub.net/docs/admin/install/manual/>
- Config reference: <https://misskey-hub.net/docs/admin/config/>
- Instance list: <https://join.misskey.page>
- Releases: <https://github.com/misskey-dev/misskey/releases>
- Discord: <https://discord.gg/kb5Ygm9rDJ>
- Crowdin (i18n): <https://crowdin.com/project/misskey>
