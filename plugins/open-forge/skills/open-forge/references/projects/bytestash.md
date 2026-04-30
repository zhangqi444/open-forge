---
name: ByteStash
description: "Self-hosted code-snippet manager. SQLite-backed. Unraid + PikaPods + Docker. jordan-dalby sole. JWT auth + secret-key + optional new-accounts."
---

# ByteStash

ByteStash is **"GitHub Gist / Notion code-block — but self-hosted + simple + SQLite"** — a self-hosted web app to **store, organize, and manage code snippets** efficiently. Create, edit, filter by language or content. SQLite backend. Demo on PikaPods. Unraid App Store. GHCR Docker image.

Built + maintained by **Jordan Dalby (jordan-dalby)** (sole). License: check LICENSE. Active; demo + PikaPods + Unraid-app + Docker.

Use cases: (a) **personal snippet library** — replace Gists (b) **team internal snippets** self-hosted (c) **learning log** — save patterns (d) **interview-prep archive** (e) **stack-specific cheatsheets** (f) **security-team snippet-share** — sensitive snippets stay local (g) **air-gapped-dev-environment** (h) **teacher code-examples server**.

Features (per README):

- **Snippet CRUD** (create, edit, delete)
- **Filter by language or content**
- **SQLite** single-file DB
- **JWT auth** (configurable secret + token expiry)
- **Configurable**: allowed hosts, base path, allow-new-accounts
- **Unraid app-store listing**
- **PikaPods** one-click

- Upstream repo: <https://github.com/jordan-dalby/ByteStash>
- Demo: <https://bytestash-demo.pikapod.net> (demo/demodemo)
- Wiki: <https://github.com/jordan-dalby/ByteStash/wiki>

## Architecture in one minute

- **Node.js** (likely)
- **SQLite** single-file
- **JWT auth**
- **Resource**: low — 50-150MB RAM
- **Port**: 5000 (default)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/jordan-dalby/bytestash`**                            | **Primary**                                                                        |
| **Unraid**         | App-store                                                                                                              | Unraid convenience                                                                                   |
| **PikaPods**       | Managed hosted                                                                                                         | Pay                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `snippets.example.com`                                      | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| `JWT_SECRET`         | Random strong secret                                        | **CRITICAL** | **Token-forgery if compromised**                                                                                    |
| `TOKEN_EXPIRY`       | `24h`                                                       | Config       |                                                                                    |
| `ALLOW_NEW_ACCOUNTS` | `true`/`false`                                              | Config       | **Set to false after first user**                                                                                    |
| `ALLOWED_HOSTS`      | `localhost,snippets.example.com`                            | Config       |                                                                                    |

## Install via Docker

```yaml
services:
  bytestash:
    image: ghcr.io/jordan-dalby/bytestash:latest        # **pin version**
    environment:
      BASE_PATH: ""
      JWT_SECRET: ${BYTESTASH_JWT_SECRET}        # 32+ bytes random
      TOKEN_EXPIRY: 24h
      ALLOW_NEW_ACCOUNTS: "false"        # **after first signup**
      DEBUG: "false"
      # ALLOWED_HOSTS: localhost,snippets.example.com
    volumes:
      - ./bytestash-snippets:/data/snippets
    ports: ["5000:5000"]
    restart: always
```

## First boot

1. Generate strong `JWT_SECRET` (32+ bytes random)
2. Start with `ALLOW_NEW_ACCOUNTS=true`
3. Create first account
4. **Set `ALLOW_NEW_ACCOUNTS=false` and restart** (lock down)
5. Import snippets
6. Put behind TLS reverse proxy
7. Back up SQLite + snippets dir

## Data & config layout

- `/data/snippets/` — SQLite + snippets content

## Backup

```sh
sudo tar czf bytestash-$(date +%F).tgz bytestash-snippets/
```

## Upgrade

1. Releases: <https://github.com/jordan-dalby/ByteStash/releases>. Active.
2. Docker pull + restart
3. SQLite auto-migrate

## Gotchas

- **118th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — SNIPPETS-WITH-CREDENTIALS**:
  - Developers often paste secrets (API keys, passwords, .env content) into snippet-tools "just to save a template"
  - **118th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "code-snippet-archive-credentials-spillover"** (1st — ByteStash; applies to any snippet/note tool)
  - CROWN-JEWEL Tier 1: 33 tools / 30 sub-categories 🎯 **30-SUB-CATEGORY MILESTONE**
- **JWT_SECRET = TOKEN-FORGERY CREDENTIAL**:
  - Losing JWT_SECRET = anyone can mint valid tokens
  - Rotating JWT_SECRET invalidates all active sessions
  - **Recipe convention: "JWT-secret-rotation-discipline" callout**
  - **NEW recipe convention** (ByteStash 1st formally)
- **ALLOW_NEW_ACCOUNTS=TRUE DURING BOOTSTRAP**:
  - Must be true for first signup, then lock down
  - If left true on public instance = anyone can register
  - **Recipe convention: "signup-window-lockdown-after-bootstrap" callout**
  - **NEW recipe convention** (ByteStash 1st formally; applies broadly)
- **DEBUG=TRUE SECURITY-LEAK**:
  - Debug-mode often exposes stack traces, internal state
  - Production MUST be false
  - **Recipe convention: "debug-flag-production-check" callout**
  - **NEW recipe convention** (ByteStash 1st formally)
- **CODE-SNIPPET-CREDENTIALS-SPILLOVER (UNIVERSAL)**:
  - Same issue as note-taking tools (NoteDiscovery 112) but even more acute — dev-snippets intentionally include creds
  - **Recipe convention: "dev-tool-credentials-in-snippets-inevitable" callout**
  - **NEW recipe convention** (ByteStash 1st formally)
  - **Applies retroactively** to Grimoire (106), Silex (106), NoteDiscovery (112), Mamadou-Note-*, etc.
- **PIKAPODS + UNRAID LISTINGS**:
  - Platform-integrations positive-signal
  - **Recipe convention: "Unraid-app-store-listing positive-signal"**
  - **NEW positive-signal convention** (ByteStash 1st formally)
- **SINGLE-SQLITE-FILE BACKUP-SIMPLICITY**:
  - **LiteDB-single-file-backup-simplicity / SQLite-single-file: 3 tools** (LubeLogger+Spoolman+ByteStash) 🎯 **3-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: jordan-dalby sole + Unraid + PikaPods + demo + docs-wiki. **104th tool — sole-maintainer-with-platform-integrations sub-tier** (reinforces NoteDiscovery precedent).
- **TRANSPARENT-MAINTENANCE**: active + demo + wiki + Unraid + PikaPods + GHCR. **112th tool in transparent-maintenance family.**
- **SNIPPET-MANAGER-CATEGORY:**
  - **ByteStash** — SQLite; simple; self-hosted
  - **SnippetBox** — PHP, self-hosted
  - **Cacher** — cloud SaaS
  - **GitHub Gists** — not self-hosted
  - **Pastebin/Rentry** — temporary (not manager)
- **ALTERNATIVES WORTH KNOWING:**
  - **SnippetBox** — if you want PHP self-hosted
  - **Gitea / Forgejo snippets** — if you want full-git-ecosystem
  - **Cacher** — if you want cloud-hosted
  - **Choose ByteStash if:** you want simple + SQLite + self-hosted + JWT-auth.
- **PROJECT HEALTH**: active + sole + PikaPods-demo + Unraid + docs. Strong.

## Links

- Repo: <https://github.com/jordan-dalby/ByteStash>
- Demo: <https://bytestash-demo.pikapod.net>
- Wiki: <https://github.com/jordan-dalby/ByteStash/wiki>
