# Imagor Studio

Self-hosted image gallery with built-in editing. Browse thousands of images with virtual scrolling, manage via drag-and-drop, and edit with layered compositing — all non-destructive via URL-based transformations powered by the [imagor](https://github.com/cshum/imagor) engine and libvips.

- **Official site:** <https://imagor.net>
- **Docs:** <https://docs.studio.imagor.net/>
- **Upstream repo:** <https://github.com/cshum/imagor-studio>
- **Docker Hub:** `shumc/imagor-studio`
- **License:** Open source (check repo for license details)

---

## Compatible Combos

| Infra      | Runtime        | Notes                                         |
|------------|----------------|-----------------------------------------------|
| Any Linux  | Docker (single) | Quick-start with SQLite, no compose needed   |
| Any Linux  | Docker Compose  | Recommended for production with S3/MinIO     |
| Coolify    | Docker          | Works via docker-compose.yml                  |
| Kubernetes | Helm/manifests  | Community; reference upstream docs            |

---

## Inputs to Collect

**Phase: Pre-deploy**
- Image directory to mount (e.g., `~/Pictures`, `~/Photos`)
- `DATABASE_URL` — SQLite path (`sqlite:///app/data/imagor-studio.db`) or PostgreSQL URL for production
- Storage backend config — local filesystem (default) or S3/MinIO/R2 credentials

**Phase: Optional**
- Auth config (see upstream docs for authentication options)
- S3-compatible storage: endpoint URL, bucket, access key, secret key

---

## Software-Layer Concerns

**Quick start (SQLite + local storage):**
```bash
docker run -p 8000:8000 --rm \
  -v $(pwd)/imagor-studio-data:/app/data \
  -v ~/Pictures:/app/gallery \
  -e DATABASE_URL="sqlite:///app/data/imagor-studio.db" \
  shumc/imagor-studio
```
Open `http://localhost:8000` — first launch redirects to admin setup.

**Data directories:**
- `/app/data` — database and app state (persist this volume)
- `/app/gallery` — image library (mount your existing photo dir)

**Storage backends supported:**
- Local filesystem (default)
- S3, MinIO, Cloudflare R2 (config via env vars — see upstream docs)

**Architecture:**
- Single container includes the imagor processing engine, libvips, and the web UI
- All image transformations are URL-based and non-destructive to originals
- Templates stored as portable JSON files

---

## Upgrade Procedure

```bash
docker pull shumc/imagor-studio:latest
# Stop old container, start new with same volume mounts
```

Check [GitHub Releases](https://github.com/cshum/imagor-studio/releases) for breaking changes before upgrading.

---

## Gotchas

- **Data volume is critical** — `/app/data` holds your database; always bind-mount or use a named volume, never let it live in an ephemeral container layer.
- **Gallery mount** — mount your image directory to `/app/gallery`; the app browses files from there. You can change `~/Pictures` to any local path.
- **Non-destructive editing** — originals are never modified; transformations happen at serve time via URL parameters.
- **Early Bird pricing** — as of writing, upstream offers a paid "Early Bird" license for some features; verify the current license terms at the repo before deploying in a commercial context.

---

## Links

- Upstream README: <https://github.com/cshum/imagor-studio#readme>
- Documentation: <https://docs.studio.imagor.net/>
- Docker Hub: <https://hub.docker.com/r/shumc/imagor-studio>
- imagor engine: <https://github.com/cshum/imagor>
