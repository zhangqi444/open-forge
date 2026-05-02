---
name: dumbpad-project
description: DumbPad recipe for open-forge. Stupidly simple no-auth web notepad with auto-save, dark mode, markdown rendering, fuzzy search, PIN protection, and PWA. File-based storage. Single container. GPL-3.0. Upstream: https://github.com/DumbWareio/DumbPad
---

# DumbPad

A stupidly simple web notepad with auto-save. No accounts, no fuss — open the URL and start typing. Supports multiple named notepads, markdown rendering (GitHub-style alerts, tables, code highlighting), fuzzy search, dark mode, direct notepad linking, and optional PIN protection. PWA installable. File-based storage.

Upstream: <https://github.com/DumbWareio/DumbPad>

GPL-3.0. Single container. Part of the [DumbWare](https://github.com/DumbWareio) family of "dumb simple" self-hosted tools.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; file-based data store |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `3000` |
| config | "Site title?" | `SITE_TITLE`; shown in web UI; default `DumbPad` |
| config | "Base URL?" | `BASE_URL`; used for shareable links; default `http://localhost:3000` |
| config | "Enable PIN protection?" | `DUMBPAD_PIN`; 4–10 digits; leave empty to disable |

## Software-layer concerns

### Image

```
dumbwareio/dumbpad:latest
```

Docker Hub: <https://hub.docker.com/r/dumbwareio/dumbpad>

### Compose

```yaml
services:
  dumbpad:
    image: dumbwareio/dumbpad:latest
    container_name: dumbpad
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
    environment:
      SITE_TITLE: DumbPad
      DUMBPAD_PIN: ""              # leave empty to disable PIN; set 4-10 digit PIN to enable
      BASE_URL: "http://localhost:3000"
      # ALLOWED_ORIGINS: "http://localhost:3000,https://pad.example.com"
      # LOCKOUT_TIME: "15"         # minutes before lockout resets (default: 15)
      # MAX_ATTEMPTS: "5"          # wrong PINs before lockout (default: 5)
      # COOKIE_MAX_AGE: "24"       # hours auth cookie is valid (default: 24)
```

> Source: upstream docker-compose.yml — <https://github.com/DumbWareio/DumbPad>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `SITE_TITLE` | `DumbPad` | Title shown in web UI and browser tab |
| `DUMBPAD_PIN` | `""` | 4–10 digit PIN for access protection; empty = no auth |
| `BASE_URL` | `http://localhost:3000` | Public base URL — used for shareable notepad links |
| `ALLOWED_ORIGINS` | `*` | Comma-separated CORS origins; comment out / omit to allow all |
| `LOCKOUT_TIME` | `15` | Minutes before PIN lockout resets |
| `MAX_ATTEMPTS` | `5` | Failed PIN attempts before lockout |
| `COOKIE_MAX_AGE` | `24` | Hours the auth cookie lasts |
| `PAGE_HISTORY_COOKIE_AGE` | `365` | Days the "last opened notepad" cookie persists (max 400) |

### Markdown features

- GitHub-style alert blocks: `> [!NOTE]`, `> [!TIP]`, `> [!WARNING]`, `> [!CAUTION]`, `> [!IMPORTANT]`
- Extended table formatting
- Code syntax highlighting in fenced code blocks (highlight.js; ~180 languages by default)
- Auto-expand collapsible `<details>` in print mode (configurable)

To restrict syntax highlighting to specific languages (reduces bundle size):
```
HIGHLIGHT_LANGUAGES=javascript,python,go,yaml,json,bash
```

### Multiple notepads

DumbPad supports multiple named notepads. Create and switch between them via the UI. Link directly to a specific notepad via URL parameter.

### Fuzzy search

Search across all notepad filenames and contents from the UI.

### PWA

Install DumbPad as a Progressive Web App:
- Chrome (desktop/Android): install via browser menu
- Safari (iOS/iPadOS): Share → Add to Home Screen

### Docker permissions

If the container crashes with permission errors on the `./data` volume:

```bash
# Create data directory and set ownership (container runs as UID 1001)
mkdir -p ./data
chown -R 1001:1001 ./data
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

All notepads persist in `./data` across upgrades.

## Gotchas

- **Permission errors on `./data`** — the container runs as a non-root user (UID 1001). Pre-create the directory and set ownership before first run.
- **`BASE_URL` must match your actual URL** — shareable notepad links are constructed from this value. Set it to your public URL or reverse proxy domain; `localhost` produces broken links for others.
- **PIN is the only auth** — there is no username/password or multi-user support. The PIN applies to the whole instance. For stronger access control, use a reverse proxy with HTTP auth.
- **CORS: `ALLOWED_ORIGINS` is optional** — omit it (or comment it out) to allow all origins. Set it when you want to restrict which domains can embed or call DumbPad's API.
- **No encryption at rest** — notepad files are stored as plain text on the host. Do not store secrets unless you trust your host's file system security.
- **`LOCKOUT_TIME` only applies when `DUMBPAD_PIN` is set** — without a PIN, lockout settings are irrelevant.

## Links

- Upstream README: <https://github.com/DumbWareio/DumbPad>
- Docker Hub: <https://hub.docker.com/r/dumbwareio/dumbpad>
- Markdown syntax highlighting docs: <https://github.com/DumbWareio/DumbPad/blob/HEAD/docs/MARKDOWN_SYNTAX_HIGHLIGHTING_USAGE.md>
