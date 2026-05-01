---
name: Haptic
description: "Open-source local-first privacy-focused markdown editor. Docker or Vercel or Tauri desktop. SvelteKit + PGlite. chroxify/haptic. Minimal notes home."
---

# Haptic

**Open-source markdown editor — your new home for notes.** Local-first, privacy-focused, minimal, lightweight. Runs as a desktop app (Tauri) or as a self-hostable web app. Uses **PGlite** (Postgres in WASM, all-client-side) so your notes never leave your device unless you explicitly sync them.

Built + maintained by **chroxify**. Hosted free tier at <https://haptic.md/app>.

- Upstream repo: <https://github.com/chroxify/haptic>
- Website: <https://haptic.md>
- Web app: <https://haptic.md/app>
- Docker Hub: <https://hub.docker.com/r/chroxify/haptic-web>

## Architecture in one minute

- **Desktop**: Tauri (Rust shell + Svelte UI)
- **Web**: **SvelteKit** frontend, **PGlite** (Postgres-in-WASM) for local DB — all in the browser
- **Server-side**: essentially a static + SSR SvelteKit app; no user DB on the host
- Port **80** inside the Docker image (upstream maps to host `3000`)
- Resource: **tiny** — static asset serving
- Mobile: not yet; roadmap (PGlite mobile support pending)
- Windows/Linux desktop: not yet; macOS first

## Compatible install methods

| Infra              | Runtime                      | Notes                                                                  |
| ------------------ | ---------------------------- | ---------------------------------------------------------------------- |
| **Docker**         | `chroxify/haptic-web`        | **Primary self-host path.** Serves on `:80` inside.                    |
| **Vercel**         | One-click deploy             | <https://vercel.com/new/clone?repository-url=https://github.com/chroxify/haptic> |
| **Tauri desktop**  | Native macOS binary          | Build from source; see `apps/desktop/` in repo                         |
| **Hosted**         | <https://haptic.md/app>      | Free — no account, all data local to browser                           |

## Inputs to collect

| Input       | Example                    | Phase   | Notes                                                      |
| ----------- | -------------------------- | ------- | ---------------------------------------------------------- |
| Domain      | `notes.example.com`        | URL     | Optional — local-first, no real server state to protect    |
| Port        | `3000:80`                  | Network | Default upstream example                                   |

**No server-side auth.** No SMTP. No DB credentials. There's nothing on the server side beyond static SvelteKit assets.

## Install via Docker

```sh
docker pull chroxify/haptic-web:latest
docker run -d --name haptic \
  -p 3000:80 \
  --restart unless-stopped \
  chroxify/haptic-web:latest
```

Visit `http://<host>:3000`.

## Install via Docker Compose

```yaml
services:
  haptic:
    image: chroxify/haptic-web:latest
    container_name: haptic
    ports:
      - "3000:80"
    restart: unless-stopped
```

## Install via Vercel (one-click)

Click the Deploy button in the [README](https://github.com/chroxify/haptic#deploy-your-own), pick your Vercel account, let it clone + build. Vercel handles TLS + domain.

## First boot

1. Start the container.
2. Visit `http://<host>:3000`.
3. Start writing. **All data lives in your browser's PGlite store** (IndexedDB-backed). Closing the tab doesn't delete anything; clearing browser storage does.
4. Optionally put behind TLS (Caddy/Traefik/nginx).
5. Nothing to back up server-side — backup is **per-browser** via Haptic's export feature.

## Data & config layout

- **Server**: static assets only — nothing to back up
- **Client (browser)**: IndexedDB (PGlite) holds all notes — export from the app UI if you want an offline copy
- **Desktop (Tauri)**: local FS + PGlite — check `~/Library/Application Support/Haptic/` on macOS

## Backup

Server has nothing to back up. **User-facing backup is critical** — remind users:

- Use the app's **export** feature regularly
- Browser storage eviction can wipe data (private windows, aggressive clear-on-exit, OS reinstall)
- No cross-device sync yet (roadmap item: "Haptic Sync")

## Upgrade

1. Releases: <https://github.com/chroxify/haptic/releases>
2. `docker pull chroxify/haptic-web:latest && docker compose up -d`

## Gotchas

- **Local-first means server has no data.** This is a feature, not a bug. If the browser cache is cleared, notes are gone. Users must manually export backups. Educate users; put a "back up often" banner in your own deployment if you expect non-technical users.
- **No multi-device sync yet.** Roadmap ("Haptic Sync") but not shipped as of the current README. For multi-device notes use Logseq, Obsidian+sync, or SilverBullet.
- **Mobile web doesn't work yet.** PGlite's mobile support is pending; upstream says desktop-web only for now. On iOS/Android, use the hosted `haptic.md/app` and hope PGlite mobile lands soon.
- **Desktop: macOS only (for now).** Windows + Linux desktop are roadmap items. If you're on Linux/Windows, use the Docker web app.
- **Self-hosting provides zero privacy advantage over the hosted version.** Since everything is client-side, `haptic.md/app` and your self-hosted instance give the same data isolation. Self-host only buys: (a) offline availability, (b) control over the version served, (c) air-gapped deployments.
- **Vercel is a peer deploy target, not "cloud lock-in".** Upstream README offers both Vercel and Docker equivalently.
- **No server-side auth / users / backups to worry about.** Dead simple to run. The operational burden is entirely on the browser side.
- **PGlite is Postgres-in-WASM.** If you need to migrate data out, you can dump it to SQL via the browser. Novel tech; expect rough edges on very large notebooks.
- **Not an Obsidian/Logseq killer yet.** Markdown editing is clean but lacks plugins, graph view, daily-notes workflows, and mobile sync. It's positioned as a minimal notes home — if that matches, great; if you want a power tool, look elsewhere.

## Project health

Active development, hosted demo, Docker CI, Vercel deploy template, publicly tracked roadmap, solo-ish maintainership (chroxify).

## Markdown-notes-family comparison

- **Haptic** — local-first, PGlite, minimal, SvelteKit + Tauri; macOS desktop + web
- **Obsidian** — closed-source but most full-featured, plugins, graph view, paid sync
- **Logseq** — open-source, block-based, outliner-style, mobile apps exist
- **SilverBullet** — self-hosted, server-side DB, federated
- **AppFlowy** — Notion-clone, richer blocks
- **Joplin** — older, solid, E2E sync, mobile + desktop

**Choose Haptic if:** you want a minimal, local-first markdown editor and can accept the current platform limits (macOS desktop + desktop web only, no sync yet).

## Links

- Repo: <https://github.com/chroxify/haptic>
- Website: <https://haptic.md>
- Roadmap: [README § Roadmap](https://github.com/chroxify/haptic/tree/main#roadmap)
- SilverBullet (alt): <https://silverbullet.md>
- Logseq (alt): <https://logseq.com>
