---
name: Rustpad
description: "Minimal collaborative code editor — real-time multi-cursor editing in browser. Rust server (warp) + WASM OT engine + React + Monaco. Fits in a 6 MB Docker image. No database required (in-memory with optional SQLite snapshot). MIT-licensed."
---

# Rustpad

Rustpad is **"Etherpad but for code, tiny, no database"** — a self-hosted collaborative text/code editor that fits in a **6 MB Docker image**. Open a Rustpad URL, share the link → everyone on the link sees each other's cursor + edits in real time. Uses **operational transformation** for conflict-free merge semantics; the OT engine is written in Rust compiled to **WebAssembly** so it runs in both the server (Rust) and the browser (WASM), giving low-latency merges. The frontend uses **Monaco**, the same editor that powers VS Code.

Built + maintained by **ekzhang (Eric Zhang)** — prolific OSS maintainer; other projects include Sshx (batch 68). **MIT-licensed**. Public instance at <https://rustpad.io>. Philosophy: **minimal + fast + fit in one Docker image + no database to operate**. Tradeoff: documents are **transient by default** — **lost on server restart** or after 24 hours of inactivity. Optional SQLite snapshot for persistence.

Use cases: (a) **interview code-pair-sharing** (quick throwaway url) (b) **ad-hoc live coding** with a colleague (c) **teaching scenarios** where students follow instructor code (d) **pastebin-with-cursor** for collaborative debugging (e) **sketchpad for code** — faster-than-a-gist single-file collaboration.

Features:

- **Real-time multi-cursor** collaborative editing
- **Operational-transformation** for conflict-free merge
- **Monaco editor** (syntax highlight, autocomplete for common languages)
- **No account / no login** — URL is the identifier (security-by-obscurity caveat)
- **Tiny Docker image** (6 MB; multi-arch amd64 + arm64)
- **In-memory by default** — documents expire after 24h inactivity
- **Optional SQLite persistence** — set `SQLITE_URI` to persist
- **WebSocket** transport

- Upstream repo: <https://github.com/ekzhang/rustpad>
- Public instance: <https://rustpad.io>
- Docker Hub: <https://hub.docker.com/r/ekzhang/rustpad>
- Related by same author: <https://github.com/ekzhang/sshx> (batch 68)

## Architecture in one minute

- **Rust** server using `warp` web framework
- **WebAssembly** module for shared OT logic (same code in server + browser)
- **React + Monaco + TypeScript** frontend
- **Pure in-memory** state by default (no Redis, no Postgres)
- **Single binary** in a ~6 MB Alpine-free scratch-based image
- **WebSocket** for real-time sync
- **Resource**: tiny — 20-50MB RAM, near-zero CPU at idle
- **Port 3030** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ekzhang/rustpad`** (multi-arch 6 MB image)                   | **Upstream-primary**                                                               |
| From source        | `cargo run` + `wasm-pack build` + `npm run dev`                            | For development                                                                            |
| Fly.io / Cloudflare / any container host                       | Trivial (stateless by default)                                                             | Great demo-app for PaaS deploys                                                                                         |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Port                 | `3030`                                                      | Network      | `PORT` env                                                                                    |
| `EXPIRY_DAYS`        | `1` (default) / `7` for week-long pads                                  | Retention    | Inactivity timeout                                                                                    |
| `SQLITE_URI` (opt)   | `/data/rustpad.db`                                                              | Persistence  | Enables snapshot-to-disk; pads survive restarts                                                                                    |
| `RUST_LOG`           | `info`                                                                                      | Logging      | `env_logger` directives                                                                                              |

## Install via Docker

```sh
docker run --rm -dp 3030:3030 ekzhang/rustpad:latest      # pin tag in prod
```

With SQLite persistence:
```sh
docker run --rm -dp 3030:3030 \
  -v $PWD/rustpad-data:/data \
  -e SQLITE_URI=/data/rustpad.db \
  -e EXPIRY_DAYS=7 \
  ekzhang/rustpad:latest
```

Per upstream.

## First boot

1. Deploy container
2. Browse `http://host:3030` → a new random URL opens with an empty pad
3. Share the URL with collaborators
4. (opt) Place behind reverse proxy with TLS (mandatory for anyone not on localhost)
5. (opt) Configure SQLite snapshot path + volume

## Data & config layout

- **Pure in-memory** by default — pad contents live in process RAM; lost on restart
- **SQLite snapshot** (optional) — `SQLITE_URI` path; Rustpad writes pad contents so they survive restarts
- **No user accounts, no auth data** — pads are addressable by URL only
- **No file uploads** — text-only

## Backup

```sh
# Only meaningful if SQLITE_URI is set:
sudo cp rustpad.db rustpad-$(date +%F).db
# Or back up the whole volume.
```

## Upgrade

1. Releases: <https://github.com/ekzhang/rustpad/releases>. Slow / stable.
2. `docker pull ekzhang/rustpad + restart`.
3. In-memory pads = lost on upgrade (by design). SQLite-persisted pads survive.

## Gotchas

- **Pads are TRANSIENT by default** — if your Rustpad instance restarts (container restart, host reboot, cloud auto-restart), **ALL pads are lost**. This is the documented behavior, not a bug. **Set users' expectations**: "This is a scratch pad, copy your content somewhere durable before closing the tab." For persistence use `SQLITE_URI`.
- **24-hour inactivity garbage-collection** — pads untouched for 24h disappear (tune with `EXPIRY_DAYS`). Again: feature, not bug. **Don't use Rustpad as a wiki.**
- **Security-by-obscurity URL model** — anyone with the URL can edit the pad. No password, no invite, no auth. The URL IS the access token. If users share URLs in public channels (Slack, email, chat logs), the pad content is effectively public. **Same model as Etherpad, Cryptpad (without E2E), Google Docs without permission checks.** Suitable for throwaway + low-sensitivity content; **NOT for sensitive material.** Warn your users.
- **No TLS by default** — running `docker run -p 3030:3030` gives you HTTP. Behind a reverse proxy with TLS is mandatory for anyone accessing over the internet (WebSockets transmitted in cleartext = cursor moves + code edits observable).
- **No E2E encryption** — server sees all content. If you want zero-knowledge collaborative editing, use **Cryptpad** (different project, E2E-encrypted).
- **Monaco editor heft in browser** — the Monaco JS bundle is several MB; first load slow on low-bandwidth. Subsequent loads cached. Fine for most users; mind it for mobile + slow connections.
- **No file uploads** — text only. Want to collaborate on images/binaries? Different tool.
- **Single pad per URL** — no "folder of pads", no navigation. Each pad is standalone. By design; simplicity feature.
- **Intentional minimalism**: author ekzhang maintains a "small + focused" ethos across his projects (Sshx + Rustpad are both intentionally minimalist). If you want features (auth, workspaces, folders), use a different tool. **Right-sized + not-to-be-blamed-for-absence.**
- **Same author as Sshx** (batch 68 — browser-based shared terminal). Rustpad + Sshx are complementary: "collaborative code editor" + "collaborative terminal" = minimalist pair for remote debugging.
- **Public rustpad.io instance**: worth knowing exists for quick ad-hoc use. Don't put sensitive content there; it's a public shared resource.
- **No granular auth / RBAC** available — if your use case needs "only alice + bob can edit this pad", Rustpad can't express that. Use something else.
- **Project health**: ekzhang solo + MIT + proven codebase + stable for years + slow cadence (infrequent-but-non-zero releases). Bus-factor-1 but low-complexity codebase + readable. If abandoned, forkable.
- **Alternatives worth knowing:**
  - **Cryptpad** — E2E-encrypted collaborative office suite; heavy but private
  - **Etherpad** — classic collaborative editor; PHP/Node; has history + richer features
  - **HedgeDoc** (formerly CodiMD) — collaborative Markdown
  - **Obsidian Publish / Obsidian Sync** — commercial personal/knowledge management
  - **Coder / pad.ws** (this batch) — whiteboard+IDE heavier approach
  - **Google Docs / Notion** — commercial SaaS
  - **VS Code Live Share** — pair-programming in VS Code
  - **tldraw** — similar minimalism in whiteboards
  - **Choose Rustpad if:** you want minimal + ephemeral + no-database + quick-to-share code scratch.
  - **Choose Cryptpad if:** you need E2E privacy.
  - **Choose HedgeDoc if:** Markdown + persistence + users.
  - **Choose Etherpad if:** mature text collaboration with plugins.

## Links

- Repo: <https://github.com/ekzhang/rustpad>
- Public instance: <https://rustpad.io>
- Docker Hub: <https://hub.docker.com/r/ekzhang/rustpad>
- Sshx (same author, related): <https://github.com/ekzhang/sshx>
- Cryptpad (alt, E2E): <https://cryptpad.org>
- Etherpad (alt, classic): <https://etherpad.org>
- HedgeDoc (alt, markdown): <https://hedgedoc.org>
- Monaco editor (engine): <https://github.com/microsoft/monaco-editor>
- operational-transform library: <https://github.com/spebern/operational-transform-rs>
