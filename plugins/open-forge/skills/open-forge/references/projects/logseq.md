---
name: logseq-project
description: Logseq recipe for open-forge. AGPLv3-licensed privacy-first knowledge management platform — outliner, block-level references, local-first plain-text (Markdown / Org-mode) storage. Primarily a desktop/mobile app (Electron) with data stored in a user-chosen local directory; there is NO first-party server/self-host Docker image. Covers the desktop install paths, the experimental community Docker image for a web-served Logseq, and the two major forks/transitions (classic file-based graph vs the new DB-based graph).
---

# Logseq

AGPLv3 privacy-first knowledge management platform. Upstream: <https://github.com/logseq/logseq>. Docs: <https://docs.logseq.com/>.

**Not a traditional self-hosted service.** Logseq is a desktop/mobile app that reads/writes plain-text Markdown/Org-mode files from a local directory (your "graph"). The "self-hosting" conversation for Logseq is really three separate questions:

1. **Where do the graph files live?** Local disk, cloud-sync folder (Dropbox/iCloud/Nextcloud/Syncthing), or a git repo.
2. **How do I access Logseq UI from a browser on another machine?** Either a community Docker image of the web build, or the experimental real-time-collaboration (RTC) server.
3. **Do I want the free self-host sync or paid Logseq Sync?** Official sync is a paid subscription; free alternatives are file-sync (Syncthing/Dropbox/iCloud) or git.

## DB-vs-file graph transition (important context)

Upstream is actively transitioning from the original **file-based graph** (each block is a line in a Markdown file) to a **DB-based graph** (SQLite index). As of mid-2025:

- Stable / production: file-based graph (what most tutorials cover).
- `master` branch + Nightly builds: DB-based graph, still labelled "DB Test." Upstream recommends the `test/db` branch for stable DB-graph features, `master` for bleeding edge.
- Existing file graphs are NOT auto-migrated; users opt-in per-graph.

This recipe covers the file-based graph (stable). For DB-graph experimentation, see <https://github.com/logseq/db-test>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Desktop app (Electron) | <https://github.com/logseq/logseq/releases> | ✅ Recommended | Mac / Windows / Linux (AppImage). Primary supported path. |
| Mobile | App Store / Play | ✅ | iOS / Android. |
| Web at `logseq.com` (hosted) | <https://demo.logseq.com/> | ✅ (demo only) | Not intended for real use — data loss risk. |
| Build from source | `clojure -M:cljs release frontend` | ✅ | Contributors. |
| Docker (community) | <https://github.com/logseq/logseq/blob/master/Dockerfile> + community Helm/compose | ⚠️ Experimental / community | Web Logseq served over HTTP; no official upstream image published. |
| nixpkgs / AUR / Homebrew cask | Various community packages | ⚠️ Community | Distro-specific packaging. |
| `logseq/publish-spa` GitHub Action | <https://github.com/logseq/publish-spa> | ✅ | Publishes a static read-only version of a graph (good for personal wikis). |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "How are you using Logseq?" | `AskUserQuestion`: `Desktop app (just install it)` / `Web self-host (Docker)` / `Published static site (read-only)` / `File sync between devices` | Determines which section. |
| graph | "Graph directory path?" | Free-text | The folder Logseq opens; holds `pages/`, `journals/`, `logseq/`, `assets/`. |
| sync | "How do you sync graphs between devices?" | `AskUserQuestion`: `Paid Logseq Sync` / `Syncthing` / `iCloud/Dropbox/OneDrive` / `git` / `None (single-device)` | Drives the sync-setup step. |
| web | "Public domain for web Logseq?" | Free-text | Only for the community Docker path. |

## Install — Desktop app (upstream-recommended)

```bash
# macOS
brew install --cask logseq
# or download .dmg from https://github.com/logseq/logseq/releases

# Linux — AppImage
# Download the .AppImage from the releases page, chmod +x, run it
curl -L -o ~/Logseq.AppImage \
  https://github.com/logseq/logseq/releases/latest/download/Logseq-linux-x64.AppImage
chmod +x ~/Logseq.AppImage
~/Logseq.AppImage

# Windows: .msi installer from the releases page
# Mobile: App Store / Google Play
```

First launch → "Open/Create a graph" → pick a folder. Logseq creates:

| Subdir | Content |
|---|---|
| `pages/` | One `.md` file per page. |
| `journals/` | Daily note Markdown files (`2026_04_29.md`). |
| `logseq/` | `config.edn`, plugins, custom.css. |
| `assets/` | Uploaded images/files. |

That directory IS your data. Back it up; sync it across devices with any file-sync tool.

## Sync options (free alternatives to paid Logseq Sync)

### Syncthing (self-hosted, recommended)

- Install Syncthing on every device holding the graph (Syncthing has its own open-forge recipe).
- Share the graph folder between devices as a Syncthing folder.
- Turn on `ignoreDelete` and `.stversions` for a soft undo.
- Use `Send & Receive` with `receiveOnly` on mobile if you want mobile as read-only.

Conflict resolution is file-level, not block-level: if you edit the same page from two devices concurrently, you get `page.sync-conflict-2026-04-29.md`. Handle by diff + manual merge.

### iCloud / Dropbox / OneDrive / Nextcloud

Point every device at the same cloud-synced folder. Mobile Logseq on iOS integrates with iCloud natively.

### Git

- `cd /path/to/graph && git init && git add . && git commit -m "initial"`
- Add a remote (GitHub private / Gitea self-host).
- Set up a plugin (`logseq-git-auto-commit-plugin`) or manual `git pull/push` cadence.
- Good audit trail; manual conflict resolution.

## Install — Web (community Docker; experimental)

Upstream ships a Dockerfile for the web build at <https://github.com/logseq/logseq/blob/master/Dockerfile> but does NOT push an official image to Docker Hub. Community maintainers run their own images; verify the Dockerfile before pulling.

Example run (build it yourself):

```bash
git clone https://github.com/logseq/logseq.git
cd logseq
docker build -t logseq-web .
docker run -d --name logseq -p 3001:80 --restart always logseq-web
# Opens web Logseq at http://<host>:3001
```

The web build uses browser-local IndexedDB for storage by default. **This is volatile** — clearing browser storage loses the graph. For a real backend, use the desktop app, OR plug the web app into a Git-backed / WebDAV-backed storage layer (experimental).

## Install — Publish-SPA (static read-only wiki)

<https://github.com/logseq/publish-spa> ships a GitHub Action that:

1. Takes a Logseq graph (as a repo).
2. Renders a static-site version with navigation, search, pages.
3. Publishes to GitHub Pages / any static host.

```yaml
# .github/workflows/publish.yml
name: Publish Logseq Graph
on:
  push:
    branches: [main]
jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - uses: logseq/publish-spa@v0.3.0
        with:
          version: '0.10.9'
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./www
```

Push to `main` → visitors see a read-only site version of the graph. Great for personal wikis / documentation.

## Real-Time Collaboration (RTC) server

Upstream has an experimental RTC server in <https://github.com/logseq/rtc-server> for multi-user simultaneous editing on the DB-graph branch. Not production-ready as of 2025; covered here for awareness only.

## Upgrade procedure

```bash
# Desktop app — auto-updater prompts on new releases, or redownload from releases page.
# AppImage: replace the file.
# brew: brew upgrade --cask logseq

# Graph migrations: if a release bumps the graph format (rare), Logseq prompts on open
# and creates a .bak folder first.
```

**Back up the graph folder before every major version bump.** The desktop updater is usually safe; but any graph-format change should have a known-good copy stashed.

## Backup

The graph dir is plain files. Back it up like any other folder:

```bash
# tar snapshot
tar -czf logseq-graph-$(date +%F).tar.gz /path/to/graph

# rclone to object storage
rclone sync /path/to/graph myremote:logseq-backups/$(hostname)
```

Logseq has an in-app **Export** (File → Export graph → JSON/EDN) for a single-file dump, but raw-file backups are the canonical approach.

## Gotchas

- **Not a traditional server.** Most "self-host Logseq" guides end up describing file-sync, not a web daemon. The community Docker image is experimental — if a user wants a production-grade self-hosted web note app, SiYuan or AppFlowy are closer fits.
- **DB-graph transition is partial.** Stable releases still default to the file-based graph. Do not mix DB-graph nightly builds with production data; migrations are one-way and still evolving.
- **Multi-device sync is user's problem.** Logseq does NOT ship a free sync server. Options: paid Sync, Syncthing, cloud storage, or git. All have tradeoffs (conflict handling, mobile support, latency).
- **Syncthing conflicts are per-file.** Concurrent edits on the same page from two devices create `.sync-conflict-*` files; check weekly and merge manually.
- **Mobile + cloud storage limits.** iOS Logseq opens graphs from iCloud Drive; Android needs Logseq to have full-storage permission (not scoped storage) for external-SD graphs.
- **Web build + IndexedDB = data-loss trap.** If you run web Logseq and it stores in browser local storage, clearing cache wipes everything. For web, plug in a persistent backend or don't use it for real notes.
- **Plugins have filesystem access.** Logseq plugins are Node/Electron; a malicious plugin can read arbitrary files. Only install from the Marketplace with care, or review source.
- **AGPLv3 on server use.** Running a modified web Logseq as a service to users triggers AGPL's network-use clause — must expose source.
- **Paid Logseq Sync is end-to-end encrypted; the free alternatives typically are NOT.** Syncthing is E2E-encrypted in transit but not at rest; cloud storage depends on the provider. For adversarial-threat scenarios, encrypt the graph dir (e.g., gocryptfs / rclone crypt).
- **No first-party multi-user deployment.** Logseq is single-user by design. Teams should look at the RTC server (alpha) or pick a different tool.
- **Config is EDN (Clojure edition format), not JSON.** `logseq/config.edn` uses `{:key "value"}` syntax; editing with a JSON parser breaks.

## Links

- Upstream repo: <https://github.com/logseq/logseq>
- Desktop releases: <https://github.com/logseq/logseq/releases>
- Docs site: <https://docs.logseq.com/>
- Publish-SPA: <https://github.com/logseq/publish-spa>
- DB-test branch: <https://github.com/logseq/db-test>
- RTC server (alpha): <https://github.com/logseq/rtc-server>
- Plugins marketplace: in-app, or <https://logseq.com/plugins>
- Forum (Discourse): <https://discuss.logseq.com>
- Discord: <https://discord.gg/KpN4eHY>
