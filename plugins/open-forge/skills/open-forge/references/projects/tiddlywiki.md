---
name: TiddlyWiki
description: "A non-linear personal web notebook that is a SINGLE HTML FILE. Self-contained JavaScript wiki — content stored as 'tiddlers' (atomic notes). Works in browser (single-file) OR as Node.js server. Highly customizable via WikiText. Around since 2004. BSD-3-Clause."
---

# TiddlyWiki

TiddlyWiki is unique among self-hosted notebooks: **the entire wiki — content + UI + engine — fits into a single, self-contained HTML file**. Open it in any browser; it works. Save changes back to the same file. No server required. The wiki is simultaneously the tool and the document.

For power users, TiddlyWiki also runs as a **Node.js application** that exposes the same wiki with REST-like API, file-per-tiddler storage, multi-user access, and plugin management. Node mode trades the "zero-dependency single-file" magic for server-grade features.

Content model: the **tiddler** — an atomic note with title, body, tags, metadata. Link tiddlers together with double-bracket syntax `[[Like This]]`; filter and query them; compose them dynamically. The entire UI is implemented in **WikiText** (TiddlyWiki's hackable templating language) — you can rewrite the UI from within your own wiki.

Use cases:

- **Personal knowledge base** / Zettelkasten (atomic notes + links)
- **Journals** — each day's tiddler
- **Project wiki** — one HTML file you share or commit to git
- **Reference materials** — living documents instead of static Word docs
- **Task trackers** — community plugins (GTD, Kanban, Eisenhower)
- **Book / blog / website** — static sites generated from TiddlyWiki content
- **Teaching / curriculum** — self-contained HTML lessons

Core features:

- **Single-file mode** — one `.html` file = whole wiki (offline-friendly, version-control-friendly)
- **Node.js mode** — server + REST API + file-per-tiddler + multi-user auth
- **WikiText** — macros, transclusion, filter expressions, widgets
- **Plugin system** — thousands of community plugins; drag-and-drop to install
- **Themes + palettes**
- **Encryption** (built-in for single-file mode)
- **Export** — static HTML, PDF (via plugins), JSON
- **Sync adapters** — save to Dropbox, Google Drive, WebDAV, GitHub, IPFS, ...
- **Mobile companion apps** — Quine (iOS), TiddlyPWA (PWA with sync)

- Upstream repo: <https://github.com/TiddlyWiki/TiddlyWiki5>
- Website: <https://tiddlywiki.com>
- Dev docs: <https://tiddlywiki.com/dev/>
- Community forum: <https://talk.tiddlywiki.org>
- Reddit: <https://www.reddit.com/r/TiddlyWiki5/>
- Discord: <https://discord.gg/HFFZVQ8>

## Architecture in one minute

**Single-file mode:**

- One `wiki.html` = ~3 MB of minified JS + CSS + embedded tiddlers
- Browser renders + runs everything client-side
- "Save" is a browser-triggered file download (or via plugins to Dropbox/Drive/etc.)

**Node.js mode:**

- `tiddlywiki` npm package (CLI)
- Wiki = directory with `tiddlywiki.info` + `tiddlers/` folder (one file per tiddler)
- `tiddlywiki <wikipath> --listen` starts HTTP server (default port 8080)
- REST API for tiddler CRUD
- Basic HTTP auth or token (enterprise auth = plugins)

## Compatible install methods

| Infra       | Runtime                                         | Notes                                                           |
| ----------- | ----------------------------------------------- | --------------------------------------------------------------- |
| Any browser | **Download one HTML file + double-click**          | **The original + beloved mode**                                     |
| Single VM   | **Node.js**: `npm install -g tiddlywiki`             | Server mode with API + multi-user                                         |
| Docker      | `djmaze/tiddlywiki` (community image)                   | Easy Node-mode deploy                                                          |
| Raspberry Pi | Node.js install on Pi                                   | Works well                                                                          |
| Mobile      | Quine (iOS) / TiddlyPWA / Drogon (Android)                 | Mobile-friendly; sync via WebDAV/GitHub                                                  |
| Sync to cloud | Dropbox/Drive/WebDAV plugins; Tiddlyhost (hosted)       | Hybrid: edit offline, sync to cloud                                                           |

## Inputs to collect (Node.js mode)

| Input             | Example                       | Phase     | Notes                                                         |
| ----------------- | ----------------------------- | --------- | ------------------------------------------------------------- |
| Wiki path         | `~/mywiki`                     | Storage   | Directory with `tiddlywiki.info` + `tiddlers/`                     |
| Port              | `8080`                           | Network   | Node HTTP server port                                                     |
| Auth              | `--listen username=x password=y`   | Auth      | Basic auth; proxy-level auth is typically better                              |
| TLS               | Reverse proxy                        | Security  | TiddlyWiki HTTP is plain; TLS via Caddy/nginx                                         |

## Install — Single-file mode (fastest)

1. Go to <https://tiddlywiki.com/> → click "download empty" → save `empty.html` somewhere
2. Open in browser → create + edit tiddlers
3. **Save changes**: click the save-button in sidebar (behavior varies by browser):
   - Firefox: downloads a new copy
   - Chrome/Edge: downloads via downloads folder (or use "TiddlyFox"-style helpers like TiddlyWiki Save plugin)
   - Best browser for single-file: Firefox with [TiddlyWiki Saver browser extension](https://addons.mozilla.org/en-US/firefox/addon/tiddlywiki-saver/)
4. For auto-save: use a [Savers plugin](https://tiddlywiki.com/#Saving) — Dropbox, Google Drive, WebDAV, GitHub, GitLab, Gitea

## Install — Node.js mode

```sh
# Prereqs: Node.js 18+
npm install -g tiddlywiki
# Create a new wiki
tiddlywiki mynewwiki --init server
# Start server
tiddlywiki mynewwiki --listen host=0.0.0.0 port=8080
# Open http://localhost:8080

# With auth:
tiddlywiki mynewwiki --listen host=0.0.0.0 port=8080 \
  credentials=credentials.csv \
  readers=user1,user2 writers=user1
```

`credentials.csv`:

```
username,password
user1,<strong>
user2,<strong>
```

Create a `systemd` service or `pm2` entry for production.

## Install — Docker (Node mode)

```yaml
services:
  tiddlywiki:
    image: mazzolino/tiddlywiki:latest   # pin by SHA in prod
    container_name: tiddlywiki
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      USERNAME: admin
      PASSWORD: <strong>
    volumes:
      - ./tiddlywiki:/tiddlywiki
```

## Hosted options

- **Tiddlyhost** (<https://tiddlyhost.com>) — free + paid hosting for TiddlyWiki; single-file model; great for non-technical users
- **TiddlyWeb** (legacy) — predecessor to the Node mode
- **Feather Wiki**, **Neocities**, **GitHub Pages** — static site hosting (single-file mode)

## First boot (both modes)

1. Start wiki; open in browser
2. Create a few tiddlers — click "+" or "new tiddler" (Ctrl+N)
3. Link them: `[[Another Tiddler]]` or with display text `[[display|Target]]`
4. Tag them: add tags in tiddler editor
5. Customize: `$:/ControlPanel` → Appearance → Theme; Settings → keyboard shortcuts
6. Install plugins: Control Panel → Plugins → Official / Community — drag + drop to install, reload

## Data & config layout

**Single-file mode:** one `.html` file with everything embedded. Back up by copying the file.

**Node.js mode:**

```
mywiki/
├── tiddlywiki.info       # config
├── tiddlers/              # one .tid file per tiddler
│   ├── GettingStarted.tid
│   └── ...
├── plugins/               # local plugins
└── themes/                # local themes
```

## Backup

**Single-file**: copy the .html file. Version control with git: commit after each edit (git diff handles minified HTML OK).

**Node.js**: git-commit the `tiddlers/` directory. Each tiddler is a text file → clean diffs.

## Upgrade

1. Releases: <https://github.com/TiddlyWiki/TiddlyWiki5/releases>. Very active; 5.4.x is the current line.
2. Node: `npm update -g tiddlywiki` (or `sudo` on Mac/Linux).
3. Single-file: download new empty wiki, "upgrade" via [Upgrade Wizard](https://tiddlywiki.com/upgrade.html) in browser — upload old + new, merge.
4. Plugins: Control Panel → Plugins → check for updates.

## Gotchas

- **"Save" in single-file mode requires browser cooperation** — not all browsers save files easily. Firefox + TiddlyWiki Saver extension is the canonical path for single-file mode. Chrome requires workarounds (downloads folder, then overwrite). Safari is the worst.
- **Concurrent editing**: single-file mode is single-user-at-a-time. Two people editing a shared Dropbox TiddlyWiki = merge conflict mess. For real multi-user collaboration, use Node mode + auth.
- **Node.js auth is basic** — HTTP Basic auth via credentials.csv. No SSO, no OIDC natively. Front with an auth proxy (Authelia, Authentik, oauth2-proxy) for serious multi-user deployments.
- **WikiText learning curve**: it's NOT Markdown. There's a Markdown plugin, but TiddlyWiki's native syntax is its own language. Power users love it; beginners are sometimes surprised.
- **Plugin sprawl**: community plugins are numerous but varying quality. Popular + maintained: TW5-Saver, Projectify, Stroll, Refnotes, NoteStream, Kanban. Less-active plugins may break across major upgrades.
- **Node mode performance**: TiddlyWiki renders the whole wiki client-side, even in server mode. For wikis with 10,000+ tiddlers, UI gets slow on older devices.
- **Encryption** — single-file has built-in password encryption (Control Panel → Encryption). Strong option for sensitive notes. Lose the password = lose the wiki (no recovery).
- **Mobile editing**: single-file in mobile browsers is clunky. Use **Quine** (iOS), **TiddlyPWA**, or Node mode + mobile Safari.
- **Export to other formats**: TiddlyWiki's "render" command generates static HTML. PDF via plugins (varying quality). Export to Obsidian/Markdown is manual (community scripts exist).
- **Collaboration vs. personal**: TiddlyWiki philosophy = **personal** tool. For team docs, use a proper wiki (Outline, BookStack, Wiki.js) or docs site (Docusaurus, mdBook, Hugo).
- **Version control**: Node mode with file-per-tiddler + git = beautiful diffs. Single-file HTML in git = one huge line changes; still works with `git diff --word-diff`.
- **Offline-first philosophy**: TiddlyWiki works fully offline; no sync required for personal use. Sync to cloud (Dropbox, Drive, GitHub) for cross-device.
- **Not RAG-friendly** without plugins — LLM ingestion of TiddlyWiki content requires export to Markdown first.
- **20+ years old**: TiddlyWiki (by Jeremy Ruston) has been around since 2004. Stable, mature, quirky. Long-term backward compatibility is taken seriously.
- **BSD-3-Clause license** — permissive.
- **Hosted options**:
  - **Tiddlyhost** (ftg of tiddlyspot) — most popular hosted TiddlyWiki service
  - **RPi + Node mode** — common home-server pattern
  - **GitHub Pages** — publish static TiddlyWiki as blog / personal site
- **Alternatives worth knowing:**
  - **Obsidian** — local-first markdown; very popular; commercial app + free community license; larger plugin ecosystem
  - **Logseq** — local-first; outliner; journal-focused; open-source (AGPL)
  - **Zettlr** — markdown editor focused on academic writing
  - **Foam** — VS Code-based knowledge base
  - **Dendron** — VS Code-based structured knowledge base
  - **BookStack / Wiki.js / Outline** — multi-user team wikis (separate recipes)
  - **Notion / Anytype / Roam / Mem / Craft** — commercial; some OSS
  - **Choose TiddlyWiki if:** you want a single-file, portable, offline-first, hackable personal wiki + you're willing to learn WikiText.
  - **Choose Obsidian/Logseq if:** you want Markdown + a polished desktop app + bigger plugin ecosystem.
  - **Choose BookStack/Wiki.js if:** you need a team wiki with SSO.

## Links

- Repo: <https://github.com/TiddlyWiki/TiddlyWiki5>
- Website: <https://tiddlywiki.com>
- Download empty: <https://tiddlywiki.com/empty.html>
- Dev docs: <https://tiddlywiki.com/dev/>
- Getting started: <https://tiddlywiki.com/#GettingStarted>
- Node.js guide: <https://tiddlywiki.com/#TiddlyWiki%20on%20Node.js>
- Savers: <https://tiddlywiki.com/#Saving>
- Community forum (Talk): <https://talk.tiddlywiki.org>
- Reddit: <https://www.reddit.com/r/TiddlyWiki5/>
- Discord: <https://discord.gg/HFFZVQ8>
- Tiddlyhost (hosted): <https://tiddlyhost.com>
- Plugin library: <https://tiddlywiki.com/#Plugins>
- Releases: <https://github.com/TiddlyWiki/TiddlyWiki5/releases>
- Discussions: <https://github.com/TiddlyWiki/TiddlyWiki5/discussions>
