---
name: Habitica
description: Gamified habit tracker / to-do / RPG. Treat your life like an RPG — level up by completing real-world habits, dailies, and to-dos. Node.js + MongoDB + Vue 3 client. Open source under GPL-3.0 / CC-BY-SA-3.0 (content).
---

# Habitica

Habitica (formerly HabitRPG) is a habit-building and productivity app that treats your life as an RPG. You create characters, earn XP and gold by checking off habits/dailies/to-dos, spend gold on gear, take damage when you miss dailies, join parties + guilds, fight bosses together. It's productivity through D&D mechanics.

The public hosted instance at <https://habitica.com> is the main experience. Self-hosting is possible but **officially unsupported**; upstream focuses all effort on the hosted version. The `docker-compose.yml` in the repo is a **dev environment**, not a production deployment.

- Upstream repo: <https://github.com/HabitRPG/habitica>
- Hosted instance: <https://habitica.com>
- Wiki: <https://habitica.fandom.com>
- Self-hosting guide (community): <https://habitica.fandom.com/wiki/Setting_up_Habitica_Locally_on_Linux>
- API docs: <https://habitica.com/apidoc/>

## ⚠️ Self-hosting is unsupported

Front-loaded warning: upstream says the "correct" Habitica is `habitica.com`. Self-hosted instances:

- Don't have the Google Play / App Store mobile apps (those hard-code `habitica.com`)
- Don't get content updates automatically (new pets, quests, gear are pushed to the hosted version; self-hosted misses them or must pull from `develop`)
- Don't have the "marketplace" of user content you see on the hosted site
- Have no upgrade path — `develop` is the only branch; there are no tagged releases

Self-host if: you want a private party/guild tracking experience OR you want to develop Habitica itself. For just tracking habits, use the hosted version or look at alternatives (below).

## Architecture in one minute

- **`server`** — Node.js (Express) API + content bundle
- **`client`** — Vue 3 SPA (dev-time hot-reload; production = static bundle)
- **`mongo`** — MongoDB 7 with replica set (mandatory; uses transactions)
- Background job runner is in the same server process

## Compatible install methods

| Infra       | Runtime                                                 | Notes                                                                          |
| ----------- | ------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Dev / Single VM | Docker Compose (`docker-compose.yml` from repo)      | **Dev-only** — uses `Dockerfile-Dev` which is meant for development            |
| Single VM   | Manual (`npm install`, `npm start`, MongoDB on host)    | Community wiki walkthrough; still not upstream-blessed                         |
| Kubernetes  | No official manifests                                   | Community charts exist but are stale                                           |
| Managed     | Use habitica.com                                        | **Recommended** for 99% of users                                               |

## Inputs to collect

| Input                | Example                          | Phase     | Notes                                                               |
| -------------------- | -------------------------------- | --------- | ------------------------------------------------------------------- |
| MongoDB 7 with replica set | `mongo:7.0 --replSet rs`   | DB        | **Replica set required** — standalone Mongo won't work                |
| `NODE_DB_URI`        | `mongodb://mongo/habitrpg`       | Runtime   | Default DB name is `habitrpg` (not `habitica`)                       |
| `config.json`        | copy from `config.json.example`  | Runtime   | Admin email, SMTP, base URL, secrets                                 |
| `BASE_URL`           | `https://habitica.example.com`   | Runtime   | Used in email links + client                                         |
| Admin account        | `admin: true` set via Mongo shell | Bootstrap | No UI; must shell in and promote user                                |
| SMTP                 | for password reset / welcome emails | Email  | Optional; without it, users can't reset passwords                    |

## Install via Docker Compose (dev)

The upstream `docker-compose.yml` is explicitly for development. From <https://github.com/HabitRPG/habitica/blob/develop/docker-compose.yml>:

```yaml
services:
  client:
    build:
      context: .
      dockerfile: ./Dockerfile-Dev
    command: ["npm", "run", "client:dev:docker"]
    depends_on: [server]
    environment:
      - BASE_URL=http://server:3000
    ports: ["5173:5173"]
    volumes:
      - .:/usr/src/habitica
      - /usr/src/habitica/node_modules
      - /usr/src/habitica/website/client/node_modules
  server:
    build:
      context: .
      dockerfile: ./Dockerfile-Dev
    command: ["npm", "start"]
    depends_on:
      mongo:
        condition: service_healthy
    environment:
      - NODE_DB_URI=mongodb://mongo/habitrpg
    ports: ["3000:3000"]
    volumes:
      - .:/usr/src/habitica
      - /usr/src/habitica/node_modules
  mongo:
    image: "mongo:7.0"
    ports: ["27017:27017"]
    restart: "unless-stopped"
    volumes:
      - "./mongodb-data-docker:/data/db"
    entrypoint: [ "/usr/bin/mongod", "--bind_ip_all", "--replSet", "rs" ]
    healthcheck:
      test: echo "try { rs.status() } catch (err) { rs.initiate() }" | mongosh --port 27017 --quiet
      interval: 10s
      timeout: 30s
      retries: 30

networks:
  habitica: { driver: bridge }
```

Bring up:

```sh
git clone https://github.com/HabitRPG/habitica.git
cd habitica
cp config.json.example config.json
# Edit config.json — set BASE_URL, ADMIN_EMAIL, SESSION_SECRET, SESSION_SECRET_KEY
docker compose up -d
# First time: wait several minutes for npm install inside the container
docker compose logs -f server | grep "listening"
# Browse http://localhost:5173
```

### "Production" path (community)

Because there's no official prod compose, the pattern is:

1. `npm run build:client` to produce static assets
2. Serve `website/client/dist/` via nginx
3. Run `node gulpfile.js` or `npm start` on the server
4. Proxy nginx → `localhost:3000` for API

See <https://habitica.fandom.com/wiki/Setting_up_Habitica_Locally_on_Linux> for a maintained-by-community walkthrough.

## Data & config layout

- `config.json` (root of repo) — main config: DB URI, SMTP, secrets, admin email, S3 for content delivery
- `./mongodb-data-docker/` — host-bind Mongo data (in default compose)
- `website/client/src/` — Vue 3 frontend
- `website/server/src/` — API code + game content (`content/index.js`)

`config.json` keys that matter:

```jsonc
{
  "PORT": 3000,
  "BASE_URL": "https://habitica.example.com",
  "ADMIN_EMAIL": "admin@example.com",
  "NODE_DB_URI": "mongodb://mongo/habitrpg",
  "SESSION_SECRET": "rand-hex-64",
  "SESSION_SECRET_KEY": "rand-hex-64",
  "SMTP_HOST": "...",
  "EMAIL_SERVER_URL": "smtp://...",
  "S3_ACCESS_KEY_ID": "optional — for user-uploaded images",
  "S3_SECRET_ACCESS_KEY": "..."
}
```

## Make a user admin

There's no admin UI promotion; shell in:

```sh
docker compose exec mongo mongosh habitrpg
> db.users.updateOne({ "auth.local.email": "you@example.com" }, { $set: { "contributor.admin": true } })
```

## Backup

```sh
# Mongo dump
docker compose exec -T mongo mongodump --archive --db=habitrpg > habitica-$(date +%F).archive

# Content/config
cp config.json habitica-config-$(date +%F).json
```

Restore: `docker compose exec -T mongo mongorestore --archive < habitica-XXX.archive`.

## Upgrade

1. No tagged releases — only the `develop` branch.
2. `git pull && docker compose build --no-cache && docker compose up -d`.
3. **Mongo migrations** are in `migrations/` — run via `node migrations/<file>.js` as needed after major schema changes.
4. Major Mongo version bumps require manual steps; test on a clone first.
5. Content updates (pets, gear) ship with code — `git pull` brings them in.

## Gotchas

- **Self-hosting is unsupported.** Upstream has no ETA for a production compose or release tags. Every "how to self-host" guide is community-maintained.
- **Default compose is dev-only.** `Dockerfile-Dev` mounts the repo as a volume and runs dev servers with hot reload. Not for production. Expect 2+ GB RAM per container at idle.
- **MongoDB replica set is mandatory.** Standalone Mongo fails with "Transactions require replica sets" errors. The compose's entrypoint auto-inits the replica set via healthcheck.
- **Mobile apps are hard-coded to habitica.com.** You cannot point the iOS / Android apps at your self-hosted instance. Self-hosts are web-only.
- **No release tags / versions.** `develop` is HEAD. There's no "v4.x LTS" to pin to. `git pull` = run whatever's latest.
- **Secrets default to placeholders in `config.json.example`.** Rotate `SESSION_SECRET` + `SESSION_SECRET_KEY` BEFORE first start, or you're running a public instance with well-known secrets.
- **SMTP is optional but lack of it breaks password reset.** Users with forgotten passwords = stuck without admin intervention.
- **Content updates from hosted site don't flow to self-hosted automatically.** `git pull develop` pulls them, but you miss the curated content updates that the core team pushes between commits.
- **Database name is `habitrpg`, not `habitica`.** Legacy; don't rename.
- **Admin promotion is manual via mongosh.** No UI. Keep a record of admin emails.
- **File storage for user-uploaded images** (party avatars, custom gear art) goes to S3 if configured; otherwise local disk, which doesn't scale.
- **Content bundle is huge.** `website/common/dist/` compiled content is 50+ MB. Initial load is slow on first visit.
- **License mix.** Code = GPL-3.0. Content (art, text) = CC-BY-SA-3.0. Forking either requires attribution + share-alike.
- **Alternatives worth knowing:**
  - **Hosted Habitica** (<https://habitica.com>) — what upstream actually supports
  - **Beaver Habit Tracker** — simpler self-hostable habit tracker
  - **Boost (Android)** / **Loop Habits** — local-only mobile apps
  - **Todoist** — commercial, not gamified
  - **TaskWarrior** — CLI-based, extensible
- **Community support** primarily via Discord + Trello + Fandom wiki, not GitHub issues.

## Links

- Repo: <https://github.com/HabitRPG/habitica>
- Hosted instance: <https://habitica.com>
- API docs: <https://habitica.com/apidoc/>
- Wiki: <https://habitica.fandom.com>
- Self-hosting (community wiki): <https://habitica.fandom.com/wiki/Setting_up_Habitica_Locally_on_Linux>
- Dev setup (upstream): <https://github.com/HabitRPG/habitica/wiki/Setting-up-Habitica-on-your-local-machine-(Linux)>
- Trello: <https://trello.com/b/EpoYEYod/habitica>
- Config example: <https://github.com/HabitRPG/habitica/blob/develop/config.json.example>
