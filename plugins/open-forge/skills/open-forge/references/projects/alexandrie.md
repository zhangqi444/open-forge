---
name: Alexandrie
description: "Self-hosted knowledge base with extended Markdown editor. Docker Compose. Node.js + MySQL + S3. Smaug6739/Alexandrie. SSO/OIDC, FTS, offline PWA, Kanban, permissions, voice-to-text."
---

# Alexandrie

**Self-hosted, open-source knowledge base with an extended Markdown editor.** Organize, search, share, and export notes from any device — including offline via PWA. Extended Markdown: colored containers, academic blocks, KaTeX math, footnotes, interactive checkboxes. Full-text search with content snippets. Granular 5-level permissions per document. SSO/OIDC (Google, GitHub, Microsoft, Discord, any OpenID). Kanban boards, voice-to-text, one-click ZIP export.

Built + maintained by **Smaug6739**. Live demo at [alexandrie-hub.fr](https://alexandrie-hub.fr).

- Upstream repo: <https://github.com/Smaug6739/Alexandrie>
- Docs: <https://github.com/Smaug6739/Alexandrie/blob/main/docs/README.md>
- Discord: <https://discord.gg/UPsEg6egPj>
- Demo: <https://alexandrie-hub.fr>

## Architecture in one minute

- **Node.js** backend API + **Vue.js** (or similar) frontend
- **MySQL 8.0** — primary relational DB (users, docs, permissions, categories)
- **RustFS** (S3-compatible object storage) — file attachments + media
- Three-service Docker Compose stack: `mysql` + `rustfs` + `alexandrie`
- Port **3000** (frontend/API) — served by the app container
- Object storage: port **9000** (RustFS S3 API)
- PWA: installable on any device (iOS/Android/Desktop); offline-capable
- Resource: **medium** — Node.js + MySQL + object storage

## Compatible install methods

| Infra             | Runtime                                   | Notes                                                             |
| ----------------- | ----------------------------------------- | ----------------------------------------------------------------- |
| **Docker Compose**| upstream `docker-compose.yml`             | **Primary** — three services: mysql + rustfs + alexandrie         |

## Inputs to collect

| Input                          | Example                           | Phase    | Notes                                                                                      |
| ------------------------------ | --------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| MySQL root + user passwords    | random strings                    | Storage  | `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD` in `.env`                                         |
| MySQL database + username      | `alexandrie` / `alexandrie`       | Storage  | `MYSQL_DATABASE`, `MYSQL_USER`                                                             |
| RustFS access + secret keys    | random strings                    | Storage  | `RUSTFS_ACCESS_KEY`, `RUSTFS_SECRET_KEY` — S3-style credentials                           |
| Domain                         | `notes.example.com`               | URL      | Reverse proxy + TLS                                                                        |
| OIDC provider (optional)       | Google / GitHub / Discord creds   | Auth     | Client ID + Secret; configured in app settings or env                                     |
| Admin user                     | created in-app on first run       | Auth     | Via registration or OIDC                                                                   |

## Install via Docker Compose

```sh
git clone https://github.com/Smaug6739/Alexandrie.git
cd Alexandrie
cp .env.example .env   # edit passwords + keys
docker compose up -d
```

Visit `http://<host>:3000`.

### Minimal `.env` to set before starting

```env
MYSQL_ROOT_PASSWORD=<strong-random>
MYSQL_DATABASE=alexandrie
MYSQL_USER=alexandrie
MYSQL_PASSWORD=<strong-random>
RUSTFS_ACCESS_KEY=<random-key>
RUSTFS_SECRET_KEY=<strong-random-secret>
```

(Additional vars for OIDC, port overrides, etc. — see upstream docs/`.env.example`.)

## First boot

1. Set passwords + keys in `.env`.
2. `docker compose up -d` → wait for MySQL health check to pass (30s start_period).
3. Visit `http://<host>:3000` → register the first user (becomes owner).
4. Create **workspaces** and **categories** to organize notes.
5. Configure **SSO/OIDC** in Settings if desired.
6. Set **permissions** on documents (5 levels: None / Read / Write / Admin / Owner).
7. Install as PWA on mobile/desktop for offline access.
8. Put behind TLS.
9. Back up MySQL DB + RustFS data.

## Data & config layout

- MySQL volume — all structured data: users, docs, categories, permissions, tags, Kanban boards
- RustFS volume — file attachments + media (S3-compatible object store)
- App: stateless once DB + object storage are configured

## Backup

```sh
docker compose exec mysql mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > alexandrie-$(date +%F).sql
sudo tar czf alexandrie-files-$(date +%F).tgz <rustfs-volume-path>/
```

Contents: **all notes, attachments, user accounts, permissions**. Export ZIP is also available in-app (one-click — docs, files, settings).

## Upgrade

1. Releases: <https://github.com/Smaug6739/Alexandrie/releases>
2. `git pull && docker compose pull && docker compose up -d`
3. Run any DB migrations automatically on startup (check logs if something breaks).

## Gotchas

- **MySQL health check has 30s start_period** — the app container waits for MySQL to be healthy before starting. Don't worry if `alexandrie` container shows "starting" briefly; it's waiting on the DB.
- **RustFS is S3-compatible but not Amazon S3.** The compose file bundles RustFS as the object storage. You can swap in MinIO or real S3 by changing `RUSTFS_*` env vars to S3-compatible settings if you prefer.
- **`RUSTFS_CONSOLE_ENABLE`** defaults to `false` — the RustFS admin console is off. Enable it if you want to browse stored objects directly (set to `true` + expose port `9001`).
- **Permissions model is per-document.** 5 levels (None, Read, Write, Admin, Owner) can be set per user per document. Great for sharing selectively; requires deliberate setup for team wikis — default may be more restrictive than expected.
- **OIDC SSO setup** — configure Client ID/Secret via Settings or env vars. Alexandrie supports multiple providers simultaneously. First-time OIDC users are linked by email to existing accounts (or auto-created).
- **Offline PWA** — works when installed as PWA; read access to cached content offline. Writes sync when connection restores. Don't rely on this for heavy offline editing — it's best-effort browser cache.
- **Kanban boards are workspace-level** — plan project tasks visually inside each workspace. Not a full project management tool (no Gantt, no issue tracker), but handy for simple task boards alongside notes.
- **Voice-to-text** uses browser Web Speech API — works in Chrome/Edge; Firefox support is inconsistent; no server-side transcription.
- **MySQL external port is 3307** (not 3306) in the default compose — avoids conflicts if you have a local MySQL on the host. The internal Docker network still uses 3306.

## Project health

Active development, live demo, Discord, PWA, OIDC support, Kanban, offline support. Solo-maintained by Smaug6739.

## Knowledge-base-family comparison

- **Alexandrie** — Node.js + MySQL + S3, extended Markdown, OIDC, offline PWA, Kanban, granular perms
- **Outline** — Node.js + Postgres + S3, team wiki, clean UI, popular in teams
- **BookStack** — PHP + MySQL, shelf/book/page hierarchy, excellent search, mature
- **Wiki.js** — Node.js, many storage backends, multi-auth, powerful
- **Obsidian** — local-first desktop app, plugins, sync is paid
- **AppFlowy** — Notion-clone, rich blocks, offline-capable

**Choose Alexandrie if:** you want a modern self-hosted Markdown knowledge base with offline PWA, fine-grained per-doc permissions, SSO, and an S3-backed file store — all in a single `docker compose up`.

## Links

- Repo: <https://github.com/Smaug6739/Alexandrie>
- Docs: <https://github.com/Smaug6739/Alexandrie/blob/main/docs/README.md>
- Demo: <https://alexandrie-hub.fr>
- Discord: <https://discord.gg/UPsEg6egPj>
- Outline (alt): <https://www.getoutline.com>
- BookStack (alt): <https://www.bookstackapp.com>
