---
name: Zen (Notes)
description: "Minimal self-hosted note-taking app. Docker or binary. Go + SQLite. sheshbabu/zen. Markdown, flexible tags, full-text BM25 search, canvas spatial view, semantic search via Zen Intelligence, MCP server, templates, pinned notes. MIT."
---

# Zen (Notes)

**Minimal self-hosted note-taking application.** Organize notes with flexible tags (not rigid folders), full-text search with BM25 ranking, standard Markdown files, and a local SQLite database. Optional spatial canvas view for organizing notes and images. Experimental semantic search and similar images via the companion Zen Intelligence service. MCP server for AI agent integration.

Built + maintained by **sheshbabu**. Personal project — limited PR/issue review. MIT license.

- Upstream repo: <https://github.com/sheshbabu/zen>
- Live demo: <https://zendemo.fly.dev>
- Features page: <http://sheshbabu.com/zen/>
- Companion: Zen Intelligence (semantic search) / Zen Backup (automated backups)

## Architecture in one minute

- **Go** binary — single executable
- **SQLite** database (local, no external DB)
- Standard **Markdown files** (`.md`) for note content
- Port: configurable (defaults vary; check startup output)
- No Docker image published yet — run as binary or build from source
- Resource: **tiny** — Go binary + SQLite

## Compatible install methods

| Infra     | Runtime                | Notes                                              |
| --------- | ---------------------- | -------------------------------------------------- |
| **Build** | `make build`           | Go 1.20+ required; produces single binary          |
| **Dev**   | `make dev`             | Runs with default config                           |

> **Note:** No pre-built binary releases or Docker images are listed in the current README. This is a personal project — build from source. Check GitHub releases for any binary packages.

```bash
git clone https://github.com/sheshbabu/zen.git
cd zen
make build
./zen   # or check output for binary name
```

For Docker Compose: check the repo for any `docker-compose.yml` at the time of install — the author may have added one since this recipe was written.

## First boot

1. Build and start Zen.
2. Visit the web UI (check terminal output for port).
3. Create your first note.
4. Add tags to organize (tags are flexible — one note can have many tags).
5. Use full-text search (BM25) to find notes.
6. (Optional) Enable Canvas for spatial layout of notes and images.
7. (Optional) Set up Zen Intelligence for semantic search.
8. (Optional) Configure MCP for AI agent access to your notes.

## Features overview

| Feature | Details |
|---------|---------|
| Notes | Create, edit, delete markdown notes |
| Flexible tags | Tag-based organization (not folders); multi-tag; filter by tag |
| Full-text search | BM25 ranking algorithm across all note content |
| Markdown | Tables, code blocks, task lists, highlights, and more |
| Templates | Create reusable note templates |
| Pinned notes | Pin frequently accessed notes to the top |
| Archive | Soft-delete notes via archive |
| Import/export | Full data portability |
| Canvas | Experimental spatial canvas for notes + images (JSON Canvas format) |
| Semantic search | Experimental — via Zen Intelligence companion service |
| Similar images | Experimental — via Zen Intelligence |
| MCP | Model Context Protocol server for AI agent access to notes |
| Automated backups | Via Zen Backup companion tool |

## MCP server

Zen exposes an MCP (Model Context Protocol) server, enabling AI agents (Claude, GPT, etc.) to:
- Search your notes
- List notes
- Read note content

Configure your AI agent/client to connect to Zen's MCP endpoint for context-aware note access.

## Zen Intelligence (experimental)

Separate companion service for:
- **Semantic search** — find notes by meaning, not just keywords
- **Similar images** — find visually similar images in your notes

See: <https://github.com/sheshbabu/zen-intelligence>

## Zen Backup (companion)

Automated backup tool for Zen notes. See: <https://github.com/sheshbabu/zen-backup>

## JSON Canvas format

The spatial canvas uses the [JSON Canvas](https://jsoncanvas.org/) open format — an interoperable canvas format supported by Obsidian and other tools.

## Gotchas

- **Personal project with limited maintenance.** The author explicitly states: "This is a personal project built for my own use... I may not actively review pull requests or respond to issues." Use this if the current feature set meets your needs; don't expect rapid feature development or support.
- **No pre-built binaries/Docker image in current README.** As of writing, the README only shows build-from-source instructions. Check GitHub releases or tags for any available pre-built packages.
- **SQLite + flat Markdown files.** Data lives in two places: SQLite DB (metadata, tags, search index) and Markdown files. Back up both. The import/export feature helps with portability.
- **Canvas is experimental.** The spatial canvas feature is marked experimental — it may change, break, or be removed. The JSON Canvas format it uses is open and interoperable.
- **Semantic search requires Zen Intelligence.** The semantic search and similar-images features are not built into Zen itself — they require running the separate Zen Intelligence companion service.
- **MCP for AI agents.** If you use Claude or similar agents, Zen's MCP server lets the agent search and read your notes directly. Configure the MCP client in your agent settings.

## Backup

```sh
# Back up SQLite DB + Markdown files
tar czf zen-$(date +%F).tgz zen.db notes/  # adjust paths per your config
```

Or use Zen Backup: <https://github.com/sheshbabu/zen-backup>

## Upgrade

```sh
git pull && make build
# Restart Zen with the new binary
```

## Project health

Active Go development, demo site, MCP server, JSON Canvas, semantic search via companion. Personal project by sheshbabu. MIT license.

## Notes-app-family comparison

- **Zen** — Go, SQLite, Markdown, tags, BM25 search, MCP, canvas, semantic search; personal/minimal
- **Joplin** — Electron, sync, E2E encryption, plugins; more polished; desktop-first
- **Logseq** — Clojure/JS, outliner, bi-directional links, graph view; heavier
- **Obsidian** — Electron, local Markdown, plugins, canvas, graph view; more features; not self-hosted server
- **SilverBullet** — TypeScript, hackable notes + server + MCP; similar niche
- **Notesnook** — React, E2E encrypted, sync; SaaS + self-host; different scope

**Choose Zen if:** you want a minimal, fast, self-hosted note-taking app built with Go + SQLite + Markdown — with tag-based organization, BM25 full-text search, and MCP for AI agent integration.

## Links

- Repo: <https://github.com/sheshbabu/zen>
- Demo: <https://zendemo.fly.dev>
- Features: <http://sheshbabu.com/zen/>
- Zen Intelligence: <https://github.com/sheshbabu/zen-intelligence>
- Zen Backup: <https://github.com/sheshbabu/zen-backup>
