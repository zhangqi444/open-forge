# Foldergram

A self-hosted photo and video gallery that turns your local folders into an Instagram-style browsing experience. Point it at a gallery root directory; it indexes media, generates thumbnails and previews, and serves a fast PWA with Home feed, Reels (video-only), Explore, Library, Likes/Highlights, and per-folder profile pages. No cloud sync, no uploads, no multi-user accounts — just your local files, beautifully presented. Built with Node.js 22 + Vue 3 + SQLite.

- **GitHub:** https://github.com/foldergram/foldergram
- **Docker image:** `ghcr.io/foldergram/foldergram:latest`
- **Live demo:** https://foldergram.intentdeep.com/
- **License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Recommended; bind-mount your media directory |
| Any Node.js host | Source install | Node.js 22 + ffmpeg/ffprobe required |

---

## Inputs to Collect

### Deploy Phase (environment variables in docker-compose.yml)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| IMAGE_DETAIL_SOURCE | No | preview | preview (fast generated thumbnail) or original (serve original file) |
| DERIVATIVE_MODE | No | eager | eager (generate all thumbnails on scan) or lazy (generate on first request) |
| GALLERY_EXCLUDED_FOLDERS | No | — | Comma-separated folder names to skip (e.g. @eaDir,thumbnails,Archive/cache) |
| CSRF_TRUSTED_ORIGINS | No | — | Set to your public HTTPS URL if browser origin differs from upstream Node host |
| PUBLIC_DEMO_MODE | No | — | Set 1 for a read-only public demo mode (disables delete/likes changes) |

### Optional access control
| Variable | Description |
|----------|-------------|
| ADMIN_PASSWORD | Password for admin access (enables admin/viewer role split) |
| VIEWER_PASSWORD | Password for viewer access |

---

## Software-Layer Concerns

### Folder → Gallery mapping
- Any non-hidden folder directly under `GALLERY_ROOT` that contains supported media becomes one **App Folder** (like an Instagram profile)
- Files placed directly in `GALLERY_ROOT` are ignored
- Nested sub-folders become their own separate App Folders (not merged into parent)

### Supported formats
- Images: `.jpg`, `.jpeg`, `.png`, `.webp`, `.gif` (animated GIFs stay animated in viewer)
- Videos: `.mp4`, `.mov`, `.m4v`, `.webm`, `.mkv`

### Data Directories
| Mount | Contents |
|-------|----------|
| ./data/gallery | Your media files (source of truth) |
| ./data/db | SQLite database (index + likes) |
| ./data/thumbnails | Generated thumbnail derivatives |
| ./data/previews | Generated preview derivatives |

### Ports
- 4141 — Web UI (PWA)

---

## Minimal docker-compose.yml

```yaml
services:
  foldergram:
    image: ghcr.io/foldergram/foldergram:latest
    ports:
      - "4141:4141"
    environment:
      IMAGE_DETAIL_SOURCE: preview
      DERIVATIVE_MODE: eager
      # GALLERY_EXCLUDED_FOLDERS: "@eaDir,thumbnails"
      # CSRF_TRUSTED_ORIGINS: https://photos.example.com
    volumes:
      - ./data/gallery:/app/data/gallery
      - ./data/db:/app/data/db
      - ./data/thumbnails:/app/data/thumbnails
      - ./data/previews:/app/data/previews
    restart: unless-stopped
```

Or mount an existing photo library:
```yaml
volumes:
  - /path/to/your/photos:/app/data/gallery
  - ./db:/app/data/db
  - ./thumbs:/app/data/thumbnails
  - ./previews:/app/data/previews
```

---

## Upgrade Procedure

```bash
docker compose pull foldergram
docker compose up -d foldergram
```

Derivative migration (thumbnail path format changes) runs automatically on the next full scan; existing libraries stay readable during the upgrade.

---

## Gotchas

- **Folder structure is the gallery structure:** Foldergram reads your filesystem directly — organise your photos into subdirectories (one per album/person/event) before pointing Foldergram at them
- **Root-level files ignored:** Only files inside subdirectories are indexed; files placed directly in the gallery root are skipped
- **Initial scan can be slow:** On first run with DERIVATIVE_MODE=eager, Foldergram generates thumbnails for all media — large libraries take time; progress is shown in the UI
- **Video derivatives require ffmpeg:** The Docker image includes ffmpeg/ffprobe; bare-metal installs must install them separately
- **CSRF_TRUSTED_ORIGINS for reverse proxy:** If serving behind a proxy where the browser-visible domain differs from the Node.js host, set this to avoid CSRF errors
- **No multi-user accounts:** Role-based access (admin vs viewer vs public) is available via passwords, but it's not a full user management system
- **Delete from UI deletes from disk:** Delete actions remove the source file from your gallery directory permanently — be careful

---

## References
- GitHub: https://github.com/foldergram/foldergram
- docker-compose.yml: https://raw.githubusercontent.com/foldergram/foldergram/main/docker-compose.yml
- Demo: https://foldergram.intentdeep.com/
