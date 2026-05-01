---
name: An Otter Wiki
description: "Minimalist Python wiki with git-backed storage and Markdown. Docker. redimp/otterwiki. Dark mode, full changelog, user auth, attachments, mermaid diagrams, experimental git HTTP server."
---

# An Otter Wiki

**A minimalist Python-based wiki with git-backed content storage.** All content stored in a git repository — every edit is a commit; full history included. Markdown with extended syntax (tables, footnotes, fancy blocks, alerts, mermaid diagrams). User authentication, page attachments, customizable sidebar (menu and/or page index), dark mode, and an experimental git HTTP server (clone/pull/push the wiki content directly). MIT license.

Built + maintained by **redimp**. Demo at <https://demo.otterwiki.com>.

- Upstream repo: <https://github.com/redimp/otterwiki>
- Website + docs: <https://otterwiki.com>
- Installation guide: <https://otterwiki.com/Installation>
- Configuration: <https://otterwiki.com/Configuration>
- Demo: <https://demo.otterwiki.com>
- Docker Hub: `redimp/otterwiki`

## Architecture in one minute

- **Python / Flask** web app
- Content stored in a **git repository** (on disk, mounted volume)
- Port **80** inside Docker (upstream maps `8080:80`)
- Auth: built-in user accounts (email + password); LDAP optional; can disable auth for public wikis
- Resource: **tiny** — Python + git; runs on any hardware

## Compatible install methods

| Infra         | Runtime              | Notes                                                                 |
| ------------- | -------------------- | --------------------------------------------------------------------- |
| **Docker**    | `redimp/otterwiki:2` | **Primary** — minimal one-volume setup                                |
| **pip**       | `pip install otterwiki-server` | Bare metal; see installation guide                          |

## Install via Docker Compose

```yaml
services:
  otterwiki:
    image: redimp/otterwiki:2
    restart: unless-stopped
    ports:
      - 8080:80
    volumes:
      - ./app-data:/app-data
```

```bash
docker compose up -d
```

Visit `http://localhost:8080`.

## First boot

1. Deploy container.
2. Visit `http://localhost:8080`.
3. **Register an account** — the **first account is auto-promoted to admin**.
4. Access **Settings** tab (admin-only) to configure:
   - Wiki name + logo
   - Registration policy (open, invite-only, or admin-creates-only)
   - Email settings (for verification/reset)
   - Sidebar content (menu links, page index, or both)
   - Read/write permissions (public or authenticated-only)
5. Create your first pages.
6. Put behind TLS.
7. Back up `./app-data/` (git repo + SQLite user DB).

## Markdown features

Standard Markdown plus:

| Extension | Syntax |
|-----------|--------|
| Tables | GFM-style `|---|` |
| Footnotes | `[^1]` |
| Fancy blocks | `:::info`, `:::warning`, `:::danger` |
| Alerts | GitHub-style `> [!NOTE]` |
| Mermaid diagrams | ` ```mermaid ` code blocks |
| Task lists | `- [x]` |

## Data & config layout

- `./app-data/` — all data:
  - `repository/` — git repo (all wiki pages as `.md` files + attachments)
  - `otterwiki.db` — SQLite user database (accounts, sessions)
  - `settings.cfg` — app config

## Backup

```sh
docker compose stop otterwiki
sudo tar czf otterwiki-$(date +%F).tgz app-data/
docker compose start otterwiki
```

Contents: all wiki content (git history) + user accounts. Since it's a plain git repo, you can also `git clone` the `repository/` subdirectory to a remote as an additional backup.

## Upgrade

1. Releases: <https://github.com/redimp/otterwiki/releases>
2. The `:2` tag tracks the stable v2.x branch — `docker compose pull && docker compose up -d`.
3. For major version bumps (e.g. v2 → v3), check the upgrade guide.

## Experimental: git HTTP server

An Otter Wiki can act as a git HTTP server for the content repository. Enable in admin Settings. Once enabled, you can clone the wiki:

```bash
git clone https://your-wiki.example.com/wiki.git
```

...make edits locally, and push back. Pages pushed via git appear in the wiki. This is marked **experimental** — test before relying on it.

## Gotchas

- **First registered user = admin.** Register your own account before opening registration to others.
- **Git is the storage format.** This is a feature (full history, clone/push, plain Markdown files) and a gotcha (don't delete or corrupt `repository/`; git operations on it outside the app should use `--no-index` caution to avoid corrupting the wiki's state).
- **No built-in search for very large wikis.** Search is full-text grep over files — fast for normal wikis but may slow on very large repositories. For enormous wikis, consider an external search index.
- **SQLite for users.** User accounts live in a separate SQLite DB (not in git). Back up both `repository/` and `otterwiki.db`.
- **The demo shows read-only mode.** <https://demo.otterwiki.com> demonstrates the UI but has editing restricted. Install locally to test the full edit experience.
- **Email config required for registration verification + password reset.** Without SMTP, user registration and password reset don't send emails — configure `[email]` in `settings.cfg` or admin Settings.
- **`:2` Docker tag tracks v2.x stable.** Pin to a specific version tag (e.g. `:2.7.0`) for reproducible deploys if you want to control upgrade timing.
- **Mermaid diagrams render client-side.** Mermaid JS is loaded from the page — network-dependent on first render if not cached. For air-gapped deploys, check if Mermaid assets are bundled.

## Project health

Active Python/Flask development, Docker Hub, pip package, demo site, docs site. Solo-maintained by redimp. MIT license.

## Wiki-family comparison

- **An Otter Wiki** — Python, git-backed, Markdown, minimal, mermaid, experimental git push
- **Wiki.js** — Node.js, many storage backends, multi-auth, feature-rich
- **BookStack** — PHP + MySQL, shelf/book/page hierarchy, rich search, mature
- **Gollum** — Ruby, git-backed (GitHub's wiki backend), CLI-centric
- **TiddlyWiki** — single-file or self-hosted, personal knowledge base style
- **Outline** — Node.js + Postgres + S3, team wiki, clean UI

**Choose An Otter Wiki if:** you want a minimal, git-backed Markdown wiki that stores all content as plain `.md` files in a git repository — with full history, the option to push via git, and a clean dark-mode UI.

## Links

- Repo: <https://github.com/redimp/otterwiki>
- Docs: <https://otterwiki.com>
- Installation: <https://otterwiki.com/Installation>
- Demo: <https://demo.otterwiki.com>
- BookStack (richer alt): <https://www.bookstackapp.com>
