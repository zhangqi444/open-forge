---
name: ConvertX
description: Self-hosted online file converter. Browser UI that wraps 20+ CLI converters (FFmpeg, ImageMagick, Calibre, LibreOffice, Pandoc, Inkscape, Vips, Potrace, …) for over 1000 format conversions. TypeScript + Bun + Elysia. AGPL-3.0.
---

# ConvertX

ConvertX is a browser frontend that dispatches to whichever CLI tool knows how to convert a given file type. Upload a file, pick a target format, watch progress, download. Supports multi-account login, password protection, subpath hosting behind a reverse proxy, optional unauthenticated mode for LAN use, and scheduled auto-delete of processed files.

- Upstream repo: <https://github.com/C4illin/ConvertX>
- Image: `ghcr.io/c4illin/convertx` or `c4illin/convertx`

## Compatible install methods

| Infra     | Runtime                     | Notes                                                                     |
| --------- | --------------------------- | ------------------------------------------------------------------------- |
| Single VM | Docker (single container)   | **Recommended.** All converters are baked into the image                   |
| Bare metal | Bun + system packages      | Possible; you install 20+ converter binaries yourself                      |
| Kubernetes | Plain manifests            | Trivial — stateless app + single persistent volume                        |

## Inputs to collect

| Input                     | Example                                     | Phase    | Notes                                                              |
| ------------------------- | ------------------------------------------- | -------- | ------------------------------------------------------------------ |
| `JWT_SECRET`              | 32+ chars random                            | Runtime  | **Set this.** Defaults to a fresh UUID on each boot, invalidating all sessions on restart |
| Port                      | `3000:3000`                                 | Network  | No built-in TLS; behind reverse proxy for HTTPS                    |
| Data volume               | `./data:/app/data`                          | Data     | SQLite DB + uploaded/converted files                               |
| `HTTP_ALLOWED`            | `false` (default) / `true` (lan only)       | Security | Set `true` only for non-HTTPS local access — see Gotchas           |
| `ACCOUNT_REGISTRATION`    | `false` (default)                           | Security | Allow open signup? First account creation is always allowed        |
| `ALLOW_UNAUTHENTICATED`   | `false` (default)                           | Security | Lan-only kiosk mode; never expose publicly                         |
| `AUTO_DELETE_EVERY_N_HOURS` | `24` (default)                           | Runtime  | Auto-cleanup; `0` disables                                         |
| `WEBROOT`                 | `/convert`                                  | Runtime  | Mount under a subpath behind a reverse proxy                       |
| `FFMPEG_ARGS` / `FFMPEG_OUTPUT_ARGS` | `-hwaccel vaapi` / `-preset veryfast` | Runtime | Inject flags for hardware accel or quality presets              |
| `MAX_CONVERT_PROCESS`     | `0` (unlimited)                              | Runtime  | Bound concurrency for small hosts                                  |

## Install via Docker Compose (recommended)

From upstream README:

```yaml
services:
  convertx:
    image: ghcr.io/c4illin/convertx:0.x   # pin; check releases for latest tag
    container_name: convertx
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - JWT_SECRET=REPLACE_WITH_LONG_RANDOM_STRING
      - ACCOUNT_REGISTRATION=false
      - AUTO_DELETE_EVERY_N_HOURS=24
      # - HTTP_ALLOWED=true       # only if accessing over HTTP on localhost
      # - ALLOW_UNAUTHENTICATED=false
      # - WEBROOT=/convert        # if reverse-proxying under a subpath
      # - FFMPEG_ARGS=-hwaccel vaapi
      - TZ=UTC
    volumes:
      - ./data:/app/data
```

Generate `JWT_SECRET`:

```sh
tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo
```

After `docker compose up -d`, browse `http://<host>:3000` and **immediately create the admin account** — the first user to hit `/register` becomes admin. If you leave the instance up without registering, a random internet drive-by can claim it.

## Converters included

Per upstream README, the image bundles:

- **Images**: ImageMagick, GraphicsMagick, Vips, libheif, libjxl, resvg, Inkscape, Potrace, VTracer
- **Video/Audio**: FFmpeg (~472 input, ~199 output formats)
- **Documents**: LibreOffice, Pandoc, XeLaTeX, Markitdown
- **eBooks**: Calibre (`ebook-convert`)
- **Data**: Dasel (JSON/YAML/TOML/XML/CSV)
- **3D**: Assimp
- **Outlook**: msgconvert
- **Misc**: VCF to CSV, dvisvgm

All are invoked via CLI — ConvertX is a thin wrapper + web UI.

## Data layout

- `/app/data/convertx.db` — SQLite: users, conversion history
- `/app/data/files/` — uploaded and converted files (retention controlled by `AUTO_DELETE_EVERY_N_HOURS`)

File permissions sometimes bite — if you get "unable to open database file", run `chown -R $USER:$USER ./data` on the host (ConvertX runs as PID 1 inside the container; by default not a specific UID).

## Backup

```sh
# Stop the container to avoid mid-write DB corruption
docker compose stop convertx
tar czf "convertx-$(date +%F).tgz" ./data
docker compose start convertx
```

Converted files are ephemeral by design (auto-delete); backups usually only need the SQLite DB (tiny — users + history).

## Upgrade

1. Releases: <https://github.com/C4illin/ConvertX/releases>.
2. Bump image tag, `docker compose pull && docker compose up -d`.
3. Image tag `:latest` = latest release; `:main` = latest commit (pre-release). **Use pinned release tags in production** — the project is active and has shipped breaking env-var renames between minor versions.

## Gotchas

- **Leaving an empty instance public is the #1 mistake.** First hit to `/register` becomes admin, regardless of `ACCOUNT_REGISTRATION`. Create your admin account *before* DNS-pointing a public domain at the container.
- **`JWT_SECRET` defaults to `randomUUID()` on boot** — meaning if you don't set it, every restart logs everyone out. Worse: the generated UUID is not persisted, so sessions from the previous run are permanently invalidated.
- **`HTTP_ALLOWED=true` disables the "cookies only over HTTPS" check.** Necessary for plain-HTTP localhost access; never set over the public internet without TLS termination.
- **No built-in rate limits or quotas.** A single large FFmpeg transcode can pin CPU or fill disk. `MAX_CONVERT_PROCESS=1` + host-level resource limits (cgroups, Docker `--cpus`/`--memory`) are your only guardrails.
- **Hardware acceleration requires passing devices in.** `FFMPEG_ARGS=-hwaccel vaapi` on its own does nothing — you also need `devices: ['/dev/dri:/dev/dri']` in compose and the host user in `video`/`render` groups. Upstream issue #190 has platform-specific guides.
- **`WEBROOT` must match reverse-proxy path** exactly (e.g. `WEBROOT=/convert` + Caddy `handle_path /convert*`). Mismatch = broken asset URLs.
- **`ALLOW_UNAUTHENTICATED=true` + `UNAUTHENTICATED_USER_SHARING=true`** exposes all anonymous users' history to each other — fine for a personal kiosk, never for multi-tenant LAN use.
- **Disk fills up** if `AUTO_DELETE_EVERY_N_HOURS=0` and users are active. Leave the default `24` or monitor `/app/data/files/` size.
- **Mobile uploads can be huge.** No built-in per-upload size limit; cap it at the reverse proxy (`client_max_body_size 5G;` in nginx).
- **The Docker image is large** (~2 GB+) because it bundles 20+ converter toolchains including LaTeX + LibreOffice + Calibre. Not suitable for tiny VPS disks.
- **`:main` tag moves with every commit.** Running `:main` means you get breakage-of-the-day. Pin to release tags.
- **Bun-based backend.** If you run bare-metal instead of Docker, you need Bun 1.x (not Node) + every converter binary on `$PATH`. Dockerfile is the source of truth for the list.
- **AGPL-3.0 license.** If you host a modified ConvertX as a network service (SaaS), you must offer source to users. Unmodified redistributions + private internal use are fine.
- **No undo for deleted files.** Once `AUTO_DELETE_EVERY_N_HOURS` reaps a conversion, it's gone. Users should download results promptly.

## Links

- Repo: <https://github.com/C4illin/ConvertX>
- Releases: <https://github.com/C4illin/ConvertX/releases>
- GHCR: <https://github.com/C4illin/ConvertX/pkgs/container/convertx>
- Docker Hub: <https://hub.docker.com/r/c4illin/convertx>
- Env var reference: <https://github.com/C4illin/ConvertX/blob/main/README.md#environment-variables>
- HW accel (FFmpeg) notes: <https://github.com/C4illin/ConvertX/issues/190>
