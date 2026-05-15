---
name: SilverBullet
description: "Programmable, private, browser-based, self-hosted Personal Knowledge Management platform — Markdown pages + bi-directional links + Space Lua (scripting) + Objects/Queries (database-y features) in a clean self-hosted package. Go backend + TypeScript frontend. MIT."
---

# SilverBullet

SilverBullet is **"a Programmable, Private, Browser-based, Open Source, Self Hosted, Personal Knowledge Management Platform"** (per upstream) — a Markdown-based notes + knowledge system with bi-directional wiki links, live preview, outlining, task management, AND **Lua-based programmability (Space Lua)** + a **query engine over structured "Objects"** for database-like views of your notes. Developed by **Zef Hemel (@zefhemel)**.

Positioning: **more programmable than Obsidian / Logseq self-hosted**, but **less "batteries-included" than Trilium / Outline** — SilverBullet expects you to shape it with Lua + templates + queries.

Features:

- **Markdown pages** organized as a **Space**
- **Bi-directional links** (wiki-style)
- **Live preview** — edit + render in same view
- **Outlining** tools (collapsible bullets)
- **Tasks** — first-class with due dates + projects
- **Objects + Queries** — structured data embedded in markdown (YAML + inline annotations); SQL-ish queries over them
- **Space Lua** — scripting layer; write custom commands, widgets, templates
- **Page templates** + slash commands
- **Plugs** — plugin system (TypeScript; shipped built-ins for common needs)
- **Full-text search**
- **Multi-user** (per docs) — though primarily personal
- **Sync-friendly** file-based storage

- Upstream repo: <https://github.com/silverbulletmd/silverbullet>
- Docs + landing: <https://silverbullet.md>
- Install guide: <https://silverbullet.md/Install>
- Releases: <https://github.com/silverbulletmd/silverbullet/releases>
- DeepWiki: <https://deepwiki.com/silverbulletmd/silverbullet>

## Architecture in one minute

- **Server**: Go (was Deno prior to rewrite)
- **Frontend**: TypeScript + CodeMirror 6 editor + Preact UI
- **Storage**: filesystem — Markdown files in a directory (your "Space")
- **Index**: server builds in-memory/SQLite index for Objects + queries + search
- **Lua runtime**: Space Lua — SilverBullet's Lua dialect with sandbox + syscalls
- **Plugs** (plugins): compiled TypeScript, run in isolated workers
- **Resource**: small — <200 MB RAM for typical personal spaces

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker (`zefhemel/silverbullet`)**                               | **Upstream-recommended**                                                           |
| Raspberry Pi       | arm64 Docker image                                                         | Works well                                                                                 |
| Bare-metal         | Go binary from releases                                                                       | Possible                                                                                                |
| Kubernetes         | Community manifests                                                                           | Works                                                                                                                    |

## Inputs to collect

| Input                | Example                                     | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Space path           | `./space`                                        | Storage      | Directory of markdown files                                                      |
| Auth                 | SB_USER env / no-auth LAN-only / OIDC via plug            | Auth         | Default can be password-based                                                            |
| Domain               | `notes.home.lan`                                                 | URL          | Reverse proxy + TLS                                                                             |
| Port                 | `3000` (default)                                                         | Network      | Configurable                                                                                              |

## Install via Docker

```yaml
services:
  silverbullet:
    image: zefhemel/silverbullet:2.8.0                  # pin in prod
    container_name: silverbullet
    restart: unless-stopped
    environment:
      SB_USER: "admin:CHANGE_ME_STRONG_PASSWORD"
      TZ: America/Los_Angeles
    volumes:
      - ./space:/space
    ports:
      - "3000:3000"
```

Browse `http://<host>:3000/` → log in with `SB_USER` creds.

## First boot

1. Log in
2. Create your first page (just start typing; linked pages auto-create on save)
3. Install a few built-in plugs (via `PLUGS` page)
4. Experiment with Space Lua — the "Lua" built-in page is a tutorial
5. Try Objects + Queries — embed YAML frontmatter + query with `${query...}` inline
6. Set up reverse proxy + TLS for external access
7. Consider: git-backing your space dir for version control (editor writes files; git adds history)

## Data & config layout

- `/space/` — ALL your notes as .md files (plus `_plug/` for plugs + indexes)
- Markdown file per page; subdirs optional
- Index rebuilt on startup + incrementally
- **Git-friendly** — plain Markdown; initialize git in `/space/` for free history

## Backup

```sh
# Just the space dir
sudo tar czf silverbullet-$(date +%F).tgz space/
```

Or `git push` to a remote if you've set up git in the space. Best-case: SilverBullet's Markdown-file-per-page model = version control works trivially.

## Upgrade

1. Releases: <https://github.com/silverbulletmd/silverbullet/releases>. Active (Go rewrite post-Deno).
2. Docker: bump tag → restart → indexes rebuild.
3. Check release notes for breaking Lua syntax or Objects schema changes — rewrite years shipped breakage.
4. **Back up `/space/` before major version jumps.**

## Gotchas

- **Recent Go rewrite**: SilverBullet was originally Deno; switched to **Go backend** (per current README). Some older community content references Deno-based install — check current docs for image/binary paths.
- **LLM use policy** (upstream has one): `https://silverbullet.md/LLM%20Use` — worth reading before contributing code or content generated by LLM. Upstream is explicit about expectations.
- **Personal + Private positioning**: not designed for large multi-tenant use. Works for small team collaboration but scale + per-user permissions aren't its strong suit. For team wiki use Outline / Wiki.js / BookStack.
- **Programmability = power + footgun**: Space Lua can modify anything in your Space. A buggy or malicious plug can corrupt notes. **Keep backups**. Treat Lua snippets from the internet like shell scripts — read before running.
- **Plugs are isolated workers** but still execute user code. Audit plugs before installing especially if they access network (plug-api syscalls can fetch HTTP).
- **Objects + Queries**: embedding structured data in markdown is powerful — use tags, headers, YAML frontmatter. But: this is NOT a database. Performance degrades on very large spaces (10k+ pages).
- **Live-preview vs source**: CodeMirror 6 with live preview blurs render + edit. Most users love it; some prefer strict source mode. Toggleable.
- **Authentication**: default is `SB_USER` env var (single-user basic auth). For multi-user + OIDC/SSO, check plugs + current docs — evolving.
- **TLS is your responsibility**: put behind reverse proxy + Let's Encrypt. Don't expose plaintext — session cookies + auth will leak.
- **Mobile**: web UI is responsive but mobile editing = not as polished as Obsidian mobile. Fine for quick reads/edits; heavy editing is desktop-first.
- **Sync model**: SilverBullet is server-backed; you edit via web UI → server writes files. Don't edit files on disk while server is running (file watcher will catch it, but race-y). Use git push/pull through the server or quiesce first.
- **Git + SilverBullet**: works, but watch for conflicts if you edit both in-browser + push from CLI to same files.
- **Not Obsidian-compatible files**: uses Markdown but conventions (Objects, queries, Lua blocks) differ. Migration from Obsidian works for raw markdown; queries + advanced features need rewriting.
- **Bus factor**: primarily **Zef Hemel** + small contributor community. Active; Lua rewrite + Go rewrite = signs of ongoing engagement. Same assessment as batch 70 mox / Duplicacy — single-maintainer project; strong but plan accordingly.
- **License**: **MIT**.
- **Alternatives worth knowing:**
  - **Obsidian** — commercial; local-first; huge plugin ecosystem; not self-hosted
  - **Logseq** — open-source; graph-database model; less programmable
  - **Trilium Notes** — self-hosted; tree-based; JavaScript scripting
  - **Outline** — team wiki; more structured; commercial + self-host
  - **BookStack** — book/chapter wiki; PHP; stable
  - **Wiki.js** — Node-based wiki
  - **Dendron** — VS Code extension; markdown-hierarchy
  - **TiddlyWiki** — single-file personal wiki; unique model
  - **Memos** — lightweight memo-first PKM
  - **Choose SilverBullet if:** you want Obsidian-like local-first + self-hosted + Lua-programmable + Markdown-in-files.
  - **Choose Obsidian if:** commercial-OK + giant plugin ecosystem + no server needed.
  - **Choose Logseq if:** graph-DB mental model.

## Links

- Repo: <https://github.com/silverbulletmd/silverbullet>
- Docs: <https://silverbullet.md>
- Install: <https://silverbullet.md/Install>
- LLM Use Policy: <https://silverbullet.md/LLM%20Use>
- Space Lua: <https://silverbullet.md/Space%20Lua>
- Releases: <https://github.com/silverbulletmd/silverbullet/releases>
- Docker Hub: <https://hub.docker.com/r/zefhemel/silverbullet>
- DeepWiki: <https://deepwiki.com/silverbulletmd/silverbullet>
- Obsidian (alt): <https://obsidian.md>
- Logseq (alt): <https://logseq.com>
- Trilium Notes (alt): <https://github.com/zadam/trilium>
