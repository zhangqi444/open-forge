---
name: Memories (Nextcloud app)
description: "Advanced photo management app for Nextcloud — timeline, rewind, AI tagging, albums, external sharing, video transcoding, map view. Requires an existing Nextcloud instance. AGPL-3.0. Mobile-friendly via web + native Android app."
---

# Memories

Memories is **"modern Google-Photos-like photo management — inside your Nextcloud"**. Unlike Piwigo / Immich (which are standalone apps), Memories is a **Nextcloud app** — it installs as an extension into an existing Nextcloud instance + uses Nextcloud's auth, storage, sharing, mobile-sync infrastructure. If you already run Nextcloud, Memories turns your `/Photos` folder into a feature-rich photo archive with timeline, AI-powered face recognition, map view, video transcoding, and more. If you don't run Nextcloud, look at Immich / PhotoPrism / Piwigo instead.

Built + maintained by **pulsejet** (Varun Patil) — GitHub-sponsored single-maintainer project with Nextcloud AppStore presence. **AGPL-3.0**. Actively developed; tested with million-photo instances per upstream. Companion Android app available.

Use cases: (a) **Google Photos replacement** for Nextcloud users (b) **family photo library** with auto-mobile-upload via Nextcloud mobile app (c) **timeline / rewind** browsing of decades of photos (d) **AI face grouping** (requires companion apps `recognize` + `facerecognition`) (e) **video library** with HLS transcoding (f) **photo map** for travel-photo browsing (g) **migrate from Nextcloud Photos or Google Takeout**.

Features (from upstream README):

- **📸 Timeline** — sort by date taken from EXIF
- **⏪ Rewind** — jump to any moment in past instantly
- **🤖 AI tagging** — people + objects (requires `recognize` + `facerecognition` Nextcloud apps)
- **🖼️ Albums** with external-sharing support
- **🫱🏻🫲🏻 External sharing** to non-Nextcloud users
- **📱 Mobile-friendly web UI**
- **✏️ Bulk metadata editing**
- **📦 Archive folder** for photos hidden from timeline
- **📹 Video transcoding** with HLS
- **🗺️ Map view** with reverse geocoding
- **📦 Migration** from Nextcloud Photos + Google Takeout
- **⚡ Performance** — tested with million-photo instances

- Upstream repo: <https://github.com/pulsejet/memories>
- Homepage: <https://memories.gallery>
- Demo: <https://demo.memories.gallery/apps/memories/>
- Docs / Config: <https://memories.gallery/config/>
- Nextcloud App Store: <https://apps.nextcloud.com/apps/memories>
- Android app: <https://play.google.com/store/apps/details?id=gallery.memories> / <https://f-droid.org/packages/gallery.memories/>
- Discord: <https://discord.gg/7Dr9f9vNjJ>
- Sponsors: <https://github.com/sponsors/pulsejet>

## Architecture in one minute

- **Nextcloud app** — installs inside your Nextcloud via app store
- **PHP** (Nextcloud backend extension) + **Vue** frontend
- **go-vod** — external Go-based video transcoder (optional but recommended for video)
- **Metadata index** — built by `php occ memories:index` over your photos
- **Resource**: depends on Nextcloud + photo library size; go-vod adds CPU on demand for video transcoding
- **Storage**: your photos live in Nextcloud's standard storage; Memories adds an index

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Nextcloud AppStore | **Install via admin UI** → enable → configure                   | **Upstream-primary path**                                                          |
| AIO / Docker Nextcloud | Works inside Nextcloud AIO (extra config for go-vod)                                  | Mainstream path                                                                            |
| Self-built Nextcloud | Works; follow docs for go-vod + FFmpeg setup                                          | Advanced                                                                                              |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Working Nextcloud    | v25+ strongly recommended                                   | Prerequisite | Memories is a Nextcloud app — you MUST have Nextcloud first                                                                         |
| Photo directory      | Default `/Photos` or a configured folder                                | Config       | Set per-user in the Memories UI                                                                                    |
| FFmpeg + go-vod (video)| Install on Nextcloud host                                           | Video        | Required for HLS video playback                                                                                    |
| `recognize` + `facerecognition` apps (opt) | Install in Nextcloud for AI features                             | AI           | Separate Nextcloud apps                                                                                                      |
| Exiftool             | Recommended for metadata editing                                                                               | Metadata     | System package                                                                                                              |

## Install (the upstream-supported path)

1. Open Nextcloud as admin → **Apps** → search **"Memories"** → Install
2. Configure per <https://memories.gallery/config/>: set photos directory, enable video transcoding, etc.
3. On the Nextcloud host shell, run the index for existing photos:
   ```sh
   sudo -u www-data php /var/www/nextcloud/occ memories:index
   ```
4. Open Memories app from Nextcloud app launcher → configure photo source folder
5. (opt) Install **recognize** + **facerecognition** Nextcloud apps for AI tagging
6. (opt) Install **go-vod** binary + configure ffmpeg for video transcoding
7. Optional: install Android app from Play Store or F-Droid
8. Use standard Nextcloud mobile apps for auto-upload from phone

## Data & config layout

- **Your photos** live in Nextcloud's storage (unchanged; Memories doesn't duplicate)
- **Memories metadata index** — stored in Nextcloud DB (Postgres/MySQL/SQLite — whatever Nextcloud uses)
- **go-vod cache** — transcoded video segments (optional; regeneratable)
- **AI metadata** (if `recognize`/`facerecognition` installed) — in their app tables

## Backup

Memories adds rows to your Nextcloud DB; photos remain in Nextcloud's storage. **Back up Nextcloud per your existing Nextcloud backup strategy** — Memories piggybacks.

```sh
# Nextcloud standard backup (pseudocode):
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --on
pg_dump -Fc nextcloud > nextcloud-$(date +%F).dump  # or mysqldump
sudo tar czf nextcloud-data-$(date +%F).tgz /var/www/nextcloud/data/
sudo -u www-data php /var/www/nextcloud/occ maintenance:mode --off
```

## Upgrade

1. Releases: <https://github.com/pulsejet/memories/releases>. Active.
2. Upgrade via Nextcloud Apps UI — **Memories follows your Nextcloud version compatibility**. Each Memories major tracks specific Nextcloud majors.
3. `occ memories:index` may need to re-run after some upgrades (docs say when).
4. Back up Nextcloud DB FIRST.
5. go-vod binary updates separately — match to Memories version.

## Gotchas

- **REQUIRES NEXTCLOUD** — this is the #1 decision point. If you don't have Nextcloud + don't want to run it, Memories is not for you. Nextcloud is a full collaboration suite (files / calendar / contacts / Office / etc.); running it just for Memories is overkill. **Evaluate Immich / PhotoPrism / Piwigo for standalone photo management.**
- **Nextcloud performance matters**: Memories inherits Nextcloud's performance characteristics. Slow-Nextcloud = slow-Memories. Photo-heavy Nextcloud needs proper DB (Postgres/MySQL, NOT SQLite), Redis for caching, FPM tuning.
- **`memories:index` can take HOURS** on large libraries. Let it run to completion. Progress printed.
- **AI features require SEPARATE apps**: `recognize` (object tagging) + `facerecognition` (face grouping) are independent Nextcloud apps. Install + configure them; Memories displays the results. **Not built-in; don't expect AI-on-install-day.**
  - `recognize` runs CPU-heavy ML locally (Tensorflow / ONNX)
  - `facerecognition` is separately configured + indexed
  - Both can be slow on weak hardware
- **Video transcoding via go-vod**: external binary that Nextcloud launches for on-the-fly HLS generation. **Separate install step**; follow <https://memories.gallery/config/>. Without go-vod, video playback is direct-stream (may not work for all codecs in all browsers).
- **FFmpeg version** matters for transcoding compat. Upstream specifies minimum versions; old distro FFmpeg packages may fail.
- **Photo metadata = privacy surface** (same as Piwigo): EXIF contains GPS + camera + sometimes author. Memories USES this data (that's the point). **Don't share albums publicly if EXIF-stripping is required** — configure per-album + per-share.
- **Single-maintainer project** — pulsejet is solo (GitHub Sponsors funded). Active + well-loved + high quality. **Bus-factor-1 risk is real** but mitigated by: AGPL + Nextcloud AppStore presence + Discord community + sponsors funding. If you depend on Memories for production, sponsor the maintainer.
- **AGPL-3.0 compliance** in a Nextcloud context: Memories is distributed through the Nextcloud AppStore + integrated into your Nextcloud. AGPL triggers network-distribution requirements if you modify + publicly expose. Typical homelab / org-internal use = fine.
- **Nextcloud's own Photos app** exists (first-party, simpler, less featureful). Memories is more featureful. Choosing depends on whether you want minimal or feature-rich.
- **Immich comparison**: Immich is standalone + has more polish + larger team + faster development. Memories is Nextcloud-integrated. **If you're Nextcloud-centric** → Memories. **If you're not** → Immich.
- **Migration FROM Google Photos (Takeout)**: Memories supports this; follow upstream docs. Takeout JSON metadata gets parsed + merged with photos.
- **Migration FROM Nextcloud Photos**: first-class path per upstream; your photos stay where they are.
- **Mobile auto-upload path**: use the **official Nextcloud mobile app** for auto-upload; then Memories displays what was uploaded. The Memories Android app is for VIEWING, not uploading. (Per upstream README.)
- **Hub-of-credentials tier**: Memories itself doesn't add much credential surface; it inherits Nextcloud's. Your Nextcloud IS the crown jewel. If Nextcloud is compromised, Memories-seen-photos are compromised along with everything else. **Pattern: "app-that-inherits-host-app-security".**
- **Rapid development**: frequent releases. Good — active maintenance + quick bug fixes. Pin versions in production; test before updating.
- **Alternatives worth knowing:**
  - **Immich** — standalone + modern + mobile-upload-first + AI; FASTEST growing
  - **PhotoPrism** — standalone + AI + polished; freemium commercial tier
  - **Piwigo** — mature standalone gallery
  - **Nextcloud Photos** (first-party) — simpler + less featureful
  - **LibrePhotos** — standalone + Django + AI
  - **Ente Photos** — E2E-encrypted alternative (OSS + commercial)
  - **Choose Memories if:** you ALREADY run Nextcloud + want the best photo UX inside it.
  - **Choose Immich if:** you want standalone + best mobile-upload UX + don't want Nextcloud overhead.
  - **Choose Piwigo if:** you want mature + multi-user + rich-permissions + PHP/MySQL stack.

## Links

- Repo: <https://github.com/pulsejet/memories>
- Homepage: <https://memories.gallery>
- Docs: <https://memories.gallery/config/>
- Demo: <https://demo.memories.gallery>
- AppStore: <https://apps.nextcloud.com/apps/memories>
- Android app (Play): <https://play.google.com/store/apps/details?id=gallery.memories>
- Android app (F-Droid): <https://f-droid.org/packages/gallery.memories/>
- Discord: <https://discord.gg/7Dr9f9vNjJ>
- Sponsor maintainer: <https://github.com/sponsors/pulsejet>
- `recognize` (AI tagging): <https://apps.nextcloud.com/apps/recognize>
- `facerecognition`: <https://apps.nextcloud.com/apps/facerecognition>
- Immich (standalone alt): <https://immich.app>
- PhotoPrism (alt): <https://www.photoprism.app>
- Ente Photos (E2E alt): <https://ente.io>
