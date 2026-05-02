# Cially

Open-source Discord server analytics dashboard. A Discord bot listens to all server events and logs them to a PocketBase backend; a Next.js web app displays member activity, message analytics, growth metrics, and engagement trends.

- **Official site:** <https://cially.org>
- **Docs:** <https://cially.org/guide/1-introduction/features/>
- **Upstream repo:** <https://github.com/cially/cially>
- **License:** CC BY-NC-ND 2.0 (non-commercial, no derivatives — see gotchas)

---

## Compatible Combos

| Infra      | Runtime        | Notes                                              |
|------------|----------------|----------------------------------------------------|
| Any Linux  | Docker Compose | Official path; compose file in `docker/` folder   |
| Pangolin   | Docker Compose | Special setup file included in `docker/` folder   |

---

## Inputs to Collect

**Phase: Discord setup (must do before deploy)**
1. Create application at [Discord Developer Portal](https://discord.com/developers/applications)
2. Enable all **Privileged Gateway Intents** under Bot settings
3. Invite bot to server with **View Channel** and **View Message History** permissions
4. Optional: **Manage Server** permission for vanity URL tracking

**Phase: Pre-deploy**
- `TOKEN` — Discord bot token
- `CLIENT_ID` — Discord application client ID
- `POCKETBASE_URL` — URL of PocketBase instance (can be internal Docker URL: `http://cially-pocketbase:8090`)

---

## Software-Layer Concerns

**Setup steps:**
```bash
# 1. Get docker-compose.yaml and .env.example from the docker/ folder
# 2. Rename .env.example → .env, fill in TOKEN, CLIENT_ID, POCKETBASE_URL
docker compose up
```

**Services (docker-compose):**
- `cially-bot` — Discord bot (event listener, logs to PocketBase)
- `cially-pocketbase` — PocketBase backend (port 8090 by default)
- `cially-web` — Next.js frontend dashboard

**Data directories:**
- PocketBase data volume — persist this for all analytics history

**Important architectural note:**
- Only events captured while the bot is **online** are tracked — historical messages are not backfilled automatically. There is an option to retrieve older messages from the Messages page.
- Data accuracy depends on bot uptime; downtime = data gaps.

**Password reset:**
- If you forget your Cially password, run `/reset-account` Discord slash command (server owners only).

---

## Upgrade Procedure

Pull latest images and restart:
```bash
docker compose pull
docker compose up -d
```

Check [GitHub releases](https://github.com/cially/cially/releases) or the repo for changelogs before upgrading.

---

## Gotchas

- **Non-commercial license** — Cially uses CC BY-NC-ND 2.0. You cannot use it for commercial purposes or modify/redistribute it. Verify license terms at the repo before deployment in any business context.
- **Version 2.0 Beta** — as of writing, Cially is in beta. Expect rough edges and potential breaking changes between updates.
- **Bot must stay online** — data is only as good as uptime. If the bot restarts, events during the downtime are lost.
- **PocketBase URL config** — if you change the PocketBase port, update the Application URL in the PocketBase dashboard as well.
- **Privileged Gateway Intents** — all three privileged intents must be enabled in the Discord Developer Portal or the bot won't function correctly.

---

## Links

- Docker setup README: <https://github.com/cially/cially/tree/v2.x/docker>
- Features docs: <https://cially.org/guide/1-introduction/features/>
- Upstream repo: <https://github.com/cially/cially>
