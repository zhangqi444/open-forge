---
name: perfice-project
description: Perfice recipe for open-forge. Open-source self-tracking platform. Track sleep, mood, food, or anything. Automatic correlations (e.g. "mood is better when you sleep longer"), goal-setting, local-first/privacy-first (IndexedDB), CSV/JSON export, Android app (Capacitor). Svelte 5 + TypeScript. Single container nginx serving static SPA. Optional backend for sync/accounts/integrations. Upstream: https://github.com/p0lloc/perfice
---

# Perfice

An open-source self-tracking platform. Define trackables for anything (sleep, mood, food, exercise, etc.), and Perfice automatically surfaces correlations between them ("Mood is better when you sleep longer"). Set goals across multiple trackables. Privacy-first and local-first — all data is stored and calculated in-browser using IndexedDB. Export everything to CSV or JSON. Available as a web app and Android app (via Capacitor).

Upstream: <https://github.com/p0lloc/perfice> | Website: <https://perfice.adoe.dev> | Docs: <https://perfice.adoe.dev/docs>

Single container: nginx serving the built Svelte SPA. The app runs entirely in-browser — no server-side data processing. An optional backend can be self-hosted for user accounts, sync across devices, and integrations.

**Note: the app runs under the `/new` subpath** — e.g. `http://host:PORT/new`

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Static SPA served by nginx; all data in browser IndexedDB |
| Android | Native app via Capacitor |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `80` — nginx |
| config | "Backend URL?" | `VITE_BACKEND_URL` — optional; only needed for sync/accounts/integrations |

## Software-layer concerns

### No prebuilt Docker image — build from source

Perfice provides a `Dockerfile` and compose file in the repo, but no published image. Build locally:

```bash
git clone https://github.com/p0lloc/perfice.git
cd perfice/client
docker build -t perfice .
```

Or use the compose file at the repo root:

```bash
docker compose up --build -d
```

### Compose (from repo)

```yaml
services:
  perfice:
    build:
      context: ./client
      dockerfile: Dockerfile
    ports:
      - "80:80"
    restart: unless-stopped
```

### Optional: backend URL

If you're running the optional Perfice backend (for sync, accounts, integrations), set the backend URL before building:

```bash
# In client/.env or client/.env.production:
VITE_BACKEND_URL=https://api.example.com
```

Or pass as a build arg if the Dockerfile supports it. The globe (🌐) icon in the app's Settings page also lets you set it at runtime.

### Architecture

- **Frontend** (this): Svelte 5 + TypeScript + TailwindCSS, compiled to static HTML/JS/CSS, served by nginx
- **Storage**: IndexedDB in the browser — data never leaves your device unless you enable backend sync
- **Backend** (optional, separate repo): required only for multi-device sync, user accounts, and integrations. See upstream docs: <https://perfice.adoe.dev/docs/selfhost>

### App subpath

The app is served at `/new` — navigate to `http://your-host/new` after deployment.

### Android app

Build with Capacitor:

```bash
cd client
CAPACITOR=true npm run build
npx cap run android
```

Or install the APK from the project's releases page if available.

### Features

- **Trackables** — define custom metrics with flexible input types
- **Automatic correlations** — statistical insights between your tracked metrics
- **Goals** — set targets across one or more trackables
- **Journals** — log entries with tags
- **Privacy first** — all data stored locally in IndexedDB; nothing sent to any server (without opt-in sync)
- **Export** — full CSV and JSON export of all data
- **Import** — restore from exported CSV/JSON

## Upgrade procedure

```bash
docker compose down
git pull
docker compose up --build -d
```

Data is stored in the browser's IndexedDB — it persists across container upgrades as long as you use the same browser/device. Export your data before major upgrades as a backup.

## Gotchas

- **No prebuilt image** — you must build from source. There is no `docker pull perfice/perfice` shortcut.
- **App runs at `/new`** — not at `/`. Linking directly to the root will show the nginx default page or a 404. Use `/new` in your reverse proxy config if you want to redirect root.
- **Local-first = browser-scoped** — data is in IndexedDB on the specific browser/device you use. Clearing browser data deletes your tracking history. Export regularly.
- **Backend is optional but separate** — sync/accounts require a separate backend deployment. The frontend alone is fully functional for single-device use.
- **`VITE_BACKEND_URL` is a build-time variable** — it gets baked into the static JS bundle. To change it, rebuild the image.

## Links

- Upstream README: <https://github.com/p0lloc/perfice>
- Website: <https://perfice.adoe.dev>
- Documentation: <https://perfice.adoe.dev/docs>
- Self-hosting backend: <https://perfice.adoe.dev/docs/selfhost>
