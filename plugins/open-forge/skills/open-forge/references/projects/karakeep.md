---
name: karakeep-project
description: Karakeep recipe for open-forge (formerly "Hoarder", renamed in 2024). AGPL-3.0 self-hostable bookmark/read-later/everything app with AI-powered auto-tagging and full-text search. Alternative to Raindrop.io / Pocket (now dead) / Omnivore (now dead) / Readeck / Linkwarden. Features - bookmark web pages (full-page archival + screenshot + text extraction), import/export, lists (collections), AI tagging via OpenAI or local Ollama/Llama, full-text search via Meilisearch, browser extensions (Chrome/Firefox), mobile apps (iOS/Android native), bulk operations, PDF/image/note types too (not just URLs). Three-service Docker Compose - `ghcr.io/karakeep-app/karakeep` (Next.js app on :3000) + Chrome headless browser (page archival) + Meilisearch (v1.41). OPENAI_API_KEY optional but recommended.
---

# Karakeep (formerly Hoarder)

AGPL-3.0 self-hostable "hoard everything" app — bookmarks + read-later + highlights + notes + images + PDFs, with AI-powered auto-tagging + full-text search. Upstream: <https://github.com/karakeep-app/karakeep>. Docs: <https://docs.karakeep.app>. Website: <https://karakeep.app>.

**Rename note:** this project was called "Hoarder" until 2024, renamed to Karakeep. Old image `ghcr.io/hoarder-app/hoarder` is deprecated — use `ghcr.io/karakeep-app/karakeep`.

**Positioning:** a private, AI-augmented alternative to Raindrop.io / Pocket (shut down by Mozilla in 2024) / Omnivore (shut down by ElevenLabs in 2024). Slightly different DX than Linkwarden + Readeck — Karakeep leans harder into AI auto-tagging and multi-type content (not just URLs; also images, PDFs, plain notes).

## Features

- **Bookmarks**: URL + full-page archival (HTML + screenshot + extracted text).
- **Multi-content types**: URLs, images, PDFs, plain-text notes — all in one vault.
- **AI auto-tagging** via OpenAI, or local via Ollama (any OpenAI-compatible API).
- **Full-text search** (Meilisearch) across archived content.
- **Lists / collections** for organization.
- **Sharing**: public read-only share links.
- **Bulk operations**: select multiple, tag, move, delete.
- **Browser extensions**: Chrome + Firefox (quick-save current page).
- **Mobile apps**: native iOS + Android (<https://docs.karakeep.app/quick-sharing>).
- **API + CLI** for scripting.
- **Import**: Raindrop, Pocket, Omnivore, Linkwarden, Netscape bookmark HTML.
- **Export**: full backup (HTML + JSON + archives).
- **Highlights + annotations** on archived pages.
- **RSS feed subscription** → auto-import.
- **User accounts + auth**: email/password, OIDC.
- **Dark mode**, multi-language UI.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.karakeep.app/Installation/docker> | ✅ Recommended | Standard. |
| Docker (build from source) | <https://github.com/karakeep-app/karakeep/blob/main/docker/docker-compose.build.yml> | ✅ | Contributors. |
| Umbrel / TrueNAS / CasaOS / Unraid / Synology community apps | Community | ✅ | Appliance NAS users. |
| PikaPods managed | <https://www.pikapods.com/pods?run=karakeep> | ✅ | Pay ~$1.40/mo. |

Image: `ghcr.io/karakeep-app/karakeep:release` (latest stable) or pin `0.33.0`-style. Image list: <https://github.com/karakeep-app/karakeep/pkgs/container/karakeep>.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `pikapods` / `umbrel` | Compose recommended. |
| ports | "Port?" | Default `3000` | Next.js app. |
| dns | "`NEXTAUTH_URL`?" | e.g. `https://hoard.example.com` | Public URL — used by auth callbacks. MUST match access URL. |
| secrets | "`NEXTAUTH_SECRET`?" | `openssl rand -base64 36` | Session signing. |
| secrets | "`MEILI_MASTER_KEY`?" | `openssl rand -base64 36` | Search-engine master key. |
| version | "Pin version or track release tag?" | `AskUserQuestion`: `release (auto-upgrade)` / `pinned (manual)` | Pin in prod. |
| ai | "Enable AI tagging?" | `AskUserQuestion`: `openai` / `ollama-local` / `lmstudio-local` / `none` | Optional but recommended — it's half the feature set. |
| ai | "`OPENAI_API_KEY`?" | sk-... | Only if openai. |
| ai | "`OLLAMA_BASE_URL`?" | e.g. `http://ollama:11434` | Only if local. |
| storage | "Data volume?" | Docker named volume `data` (default) | Or bind-mount `/path:/data`. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx` / `none-localhost` | Production needs TLS. |

## Install — Docker Compose (verbatim upstream)

```yaml
services:
  web:
    image: ghcr.io/karakeep-app/karakeep:${KARAKEEP_VERSION:-release}
    restart: unless-stopped
    volumes:
      - data:/data                      # default; bind-mount if you want a host path
    ports:
      - 3000:3000
    env_file:
      - .env
    environment:
      MEILI_ADDR: http://meilisearch:7700
      BROWSER_WEB_URL: http://chrome:9222
      # OPENAI_API_KEY: ...
      DATA_DIR: /data                   # DON'T CHANGE

  chrome:
    image: gcr.io/zenika-hub/alpine-chrome:124
    restart: unless-stopped
    command:
      - --no-sandbox
      - --disable-gpu
      - --disable-dev-shm-usage
      - --remote-debugging-address=0.0.0.0
      - --remote-debugging-port=9222
      - --hide-scrollbars

  meilisearch:
    image: getmeili/meilisearch:v1.42.1
    restart: unless-stopped
    env_file:
      - .env
    environment:
      MEILI_NO_ANALYTICS: "true"
    volumes:
      - meilisearch:/meili_data

volumes:
  meilisearch:
  data:
```

Bring up:

```bash
mkdir ~/karakeep && cd ~/karakeep
curl -fsSLO https://raw.githubusercontent.com/karakeep-app/karakeep/main/docker/docker-compose.yml

cat > .env <<EOF
KARAKEEP_VERSION=0.33.0
NEXTAUTH_SECRET=$(openssl rand -base64 36)
MEILI_MASTER_KEY=$(openssl rand -base64 36)
NEXTAUTH_URL=https://hoard.example.com
# OPENAI_API_KEY=sk-...
EOF

docker compose up -d
# → http://<host>:3000/
```

⚠️ **Always pin `KARAKEEP_VERSION`** in prod. The `release` tag auto-rolls; in a long-running deployment this can break things. Check releases: <https://github.com/karakeep-app/karakeep/pkgs/container/karakeep>.

## First-run

1. Open `https://hoard.example.com/`.
2. Sign up (first account becomes admin).
3. (Optional) Install browser extension → configure it with your instance URL + API key.
4. Install mobile app → configure with instance URL + API key.
5. Start hoarding.

## AI tagging setup

### OpenAI

Add to `.env`:

```bash
OPENAI_API_KEY=sk-...
# Optional overrides:
# OPENAI_BASE_URL=https://api.openai.com/v1
# INFERENCE_TEXT_MODEL=gpt-4o-mini
# INFERENCE_IMAGE_MODEL=gpt-4o-mini
```

Restart: `docker compose up -d`. Auto-tagging will now run on new + optionally existing bookmarks.

Cost guidance: <https://docs.karakeep.app/configuration/openai> — typically pennies per 100 bookmarks with `gpt-4o-mini`.

### Local (Ollama)

```bash
# In .env:
OLLAMA_BASE_URL=http://ollama:11434
INFERENCE_TEXT_MODEL=llama3.1
INFERENCE_IMAGE_MODEL=llava
```

Add an Ollama service to compose (or point at an existing one):

```yaml
ollama:
  image: ollama/ollama
  volumes:
    - ollama:/root/.ollama
  # For GPU: deploy.resources.reservations.devices ...
```

Full guide: <https://docs.karakeep.app/configuration/different-ai-providers>.

### None

Skip both env vars. Manual tagging only.

## Browser extension + mobile app

1. Karakeep → Settings → API keys → create a new API key.
2. Install browser extension (Chrome / Firefox) from the respective store.
3. Extension settings → enter instance URL + API key.
4. Pin to toolbar → click to save current page.

Mobile (iOS / Android): <https://docs.karakeep.app/quick-sharing>. Same API-key flow. Adds "Share to Karakeep" in OS share sheet.

## Reverse proxy (Caddy example)

```caddy
hoard.example.com {
    reverse_proxy web:3000
}
```

Set `NEXTAUTH_URL=https://hoard.example.com` to match.

## Data layout

| Path / volume | Content |
|---|---|
| `data:/data` (web) | SQLite DB (users, bookmarks, tags, lists), archived assets (screenshots, full-page HTML, uploaded images/PDFs) |
| `meilisearch:/meili_data` | Search index (REBUILDABLE from SQLite) |
| (chrome container) | Ephemeral — nothing persistent |

**Backup priority:**

1. **`data:/data`** — everything. SQLite `karakeep.db` + `assets/` dir.
2. **`.env`** — `NEXTAUTH_SECRET` + `MEILI_MASTER_KEY` (needed for existing sessions + search-index auth).
3. `meilisearch:` — optional; `karakeep` can rebuild the index from SQLite on startup if lost.

Backup while running is usually safe (SQLite WAL), but for crash-consistent snapshots use a filesystem-level snapshot (ZFS / LVM / btrfs) OR pause briefly.

## Upgrade procedure

### If `KARAKEEP_VERSION=release`

```bash
docker compose pull
docker compose up -d
```

### If pinned version

```bash
# Edit .env: KARAKEEP_VERSION=0.34.0
docker compose up -d
```

Release notes: <https://github.com/karakeep-app/karakeep/releases>.

**Meilisearch upgrades**: Meilisearch has strict version compatibility — upgrading Meilisearch's major-minor can require a dump + re-index. See upstream troubleshooting: <https://docs.karakeep.app/administration/troubleshooting>. Typically Karakeep pins a tested Meilisearch version; don't independently bump it.

## Gotchas

- **Renamed from Hoarder → Karakeep in 2024.** If you see `ghcr.io/hoarder-app/hoarder` in old guides, that's stale — use `ghcr.io/karakeep-app/karakeep`.
- **Don't run `KARAKEEP_VERSION=release` in prod.** `release` tag auto-rolls; a breaking release can take down your instance silently. Pin.
- **`NEXTAUTH_SECRET` + `MEILI_MASTER_KEY` must be stable.** Changing invalidates all sessions + requires Meilisearch re-auth.
- **`NEXTAUTH_URL` must match the user-facing URL exactly** (scheme + host + port). Mismatch = auth callbacks redirect somewhere wrong.
- **Chrome container uses `--no-sandbox`** — runs as root inside container. This is fine inside a throwaway container but don't expose the Chrome debug port (9222) outside the docker network.
- **Full-page archival stores the entire rendered HTML + screenshot PER BOOKMARK.** Disk usage grows fast — expect ~1-5 MB per bookmark. Budget accordingly.
- **AI auto-tagging sends URL title + description (or full text if enabled) to OpenAI.** If you care about privacy, use Ollama locally. OpenAI sees your bookmark stream otherwise.
- **Ollama integration needs a decent model.** Llama3.1 8B works for tagging; smaller models hallucinate tags. For image captioning, Llava requires VRAM.
- **Meilisearch stores a plaintext search index of your content** — treat the meilisearch volume like SQLite (sensitive).
- **Email / notifications**: Karakeep supports SMTP for password reset etc. — configure `SMTP_*` env vars; otherwise no email out.
- **OIDC**: supported for SSO. Set `OIDC_*` env vars. See docs.
- **RSS feed crawler**: subscribe → auto-imports new items as bookmarks. Great with Miniflux or directly.
- **Bookmarks with paywalls / JavaScript-heavy SPAs** — Chrome headless handles most, but some (NYT, WSJ, some SPA-heavy apps) produce garbage archives. Use a cookie-passing browser extension or archive.today fallback.
- **PDFs uploaded directly** are OCR'd (Tesseract built-in) → searchable. Quality depends on PDF.
- **Mobile apps are NATIVE** (not Capacitor / PWA), unusual for a self-hosted project — feels good to use.
- **Scaling**: single-container Next.js app + single Meilisearch. For 10k+ bookmarks, more RAM for Meilisearch helps (`MEILI_MAX_INDEXING_MEMORY`).
- **Browser extension vs mobile share-sheet** — browser extension saves full-page archive; mobile usually saves just the URL + screenshot. Different UX.
- **Highlights / annotations** are synced but only visible in Karakeep's web reader, not in the original URL.
- **Imports**:
  - Pocket export HTML → works great.
  - Omnivore export → works; Omnivore's full-text archives may not all transfer.
  - Raindrop CSV → tags preserved, content NOT re-archived (links only).
- **vs Linkwarden**: Linkwarden does bookmarking + full-page archival + collections too; Karakeep leans more AI. Both good.
- **vs Readeck**: Readeck is more reader-focused (distraction-free read mode, highlights); Karakeep is more catalog-focused.
- **vs Wallabag**: Wallabag is read-later-only, older, more mature. Karakeep is multi-content + AI.
- **Default SQLite** DB is fine to 100k bookmarks. Postgres backend is experimental (as of 0.33).
- **No telemetry** — Meilisearch analytics disabled in upstream compose.
- **AGPL-3.0** — if you host Karakeep for others + modify it, share source with users.
- **API key generation** in-UI is per-user; secure them like passwords.

## Links

- Upstream repo: <https://github.com/karakeep-app/karakeep>
- Docs: <https://docs.karakeep.app>
- Install (Docker): <https://docs.karakeep.app/Installation/docker>
- Configuration: <https://docs.karakeep.app/configuration/environment-variables>
- AI providers: <https://docs.karakeep.app/configuration/different-ai-providers>
- OpenAI setup: <https://docs.karakeep.app/configuration/openai>
- Quick sharing (browser ext + mobile): <https://docs.karakeep.app/quick-sharing>
- Troubleshooting: <https://docs.karakeep.app/administration/troubleshooting>
- Releases: <https://github.com/karakeep-app/karakeep/releases>
- Image: <https://github.com/karakeep-app/karakeep/pkgs/container/karakeep>
- Docker Compose file: <https://github.com/karakeep-app/karakeep/blob/main/docker/docker-compose.yml>
- Website: <https://karakeep.app>
- PikaPods (managed): <https://www.pikapods.com/pods?run=karakeep>
- Mobile app (iOS): App Store "Karakeep"
- Mobile app (Android): Play Store / F-Droid
- Browser extensions: Chrome Web Store / Firefox Add-ons
- Comparable projects: Linkwarden <https://github.com/linkwarden/linkwarden>, Readeck <https://readeck.org>, Wallabag <https://wallabag.org>, Shiori <https://github.com/go-shiori/shiori>
