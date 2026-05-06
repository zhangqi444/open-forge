---
name: nextcloud-memories
description: Nextcloud Memories recipe for open-forge. Fast, batteries-included photo management app for Nextcloud. Timeline, face recognition, albums, video transcoding, and map view. Installed as a Nextcloud app. Source: https://github.com/pulsejet/memories. Docs: https://memories.gallery.
---

# Nextcloud Memories

Feature-rich photo management app for Nextcloud. Provides a fast timeline sorted by EXIF date, face/object recognition (via Recognize or Face Recognition apps), albums, external sharing, video transcoding with HLS, map view with reverse geocoding, and bulk metadata editing. Scales to millions of photos. Upstream: <https://github.com/pulsejet/memories>. Docs: <https://memories.gallery>.

> **Prerequisite:** Requires a running Nextcloud instance. Memories is a Nextcloud app — not a standalone application. See nextcloud.md for Nextcloud setup.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Nextcloud instance | Nextcloud app (PHP) | Install from Nextcloud App Store; all major Nextcloud install methods supported |
| Nextcloud + go-vod | go-vod sidecar | Recommended for video transcoding; significantly better performance than PHP-only |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Is Nextcloud already running?" | Must be set up first |
| nextcloud | "Nextcloud version?" | Memories requires NC 28+; check app store for exact requirement |
| photos | "Where are your photos stored in Nextcloud?" | Path set in Memories settings; typically /Photos or /pictures |
| transcoding | "Enable video transcoding with go-vod?" | Recommended; requires go-vod binary or Docker sidecar alongside Nextcloud |
| ai | "Enable face/object recognition?" | Requires Nextcloud Recognize or Face Recognition app installed separately |

## Software-layer concerns

- Install: Nextcloud App Store (Apps > Photos > Memories) or manual zip install
- Config: Nextcloud admin settings → Memories section
- Index: must run `php occ memories:index` after install to index existing photos
- Database: uses Nextcloud's database (MySQL/MariaDB/PostgreSQL/SQLite)
- go-vod: separate video transcoding daemon; significant performance improvement for video-heavy libraries
- EXIF parsing: reads date/GPS/camera metadata from photos; requires exiftool (recommended) or PHP EXIF extension
- Preview generation: uses Nextcloud's built-in preview generator; enable and configure for best performance

### Install steps

```bash
# 1. Install via Nextcloud web UI
# Admin → Apps → search "Memories" → Install

# OR install manually
cd /var/www/nextcloud/apps
curl -L https://github.com/pulsejet/memories/releases/latest/download/memories.tar.gz | tar xz

# 2. Enable the app
php occ app:enable memories

# 3. Index existing photos (run as web server user)
sudo -u www-data php occ memories:index

# 4. (Recommended) Install exiftool for better metadata parsing
sudo apt-get install libimage-exiftool-perl
```

### go-vod setup (video transcoding — recommended)

```bash
# Download go-vod binary
curl -L https://github.com/pulsejet/memories/releases/latest/download/go-vod-linux-amd64 -o /usr/local/bin/go-vod
chmod +x /usr/local/bin/go-vod

# Configure in Nextcloud admin → Memories → Video transcoding
# Set go-vod binary path to /usr/local/bin/go-vod
```

Or run as a Docker sidecar — see https://memories.gallery/config/#video-transcoding.

### Periodic re-indexing (cron)

```bash
# Add to Nextcloud's cron.php schedule or run manually after bulk uploads
sudo -u www-data php /var/www/nextcloud/occ memories:index
```

## Upgrade procedure

1. Upgrade via Nextcloud admin → Apps → Updates, or manually replace the app directory
2. After upgrade, run `php occ memories:index --clear` if prompted (schema changes may require re-index)
3. Check release notes: https://github.com/pulsejet/memories/releases

## Gotchas

- **Index must be run manually**: After installing or bulk-uploading photos, run `occ memories:index`. It does not run automatically unless you set up a background job.
- **exiftool improves accuracy**: Without exiftool, Memories falls back to PHP's EXIF reader which is less reliable for some formats. Install libimage-exiftool-perl.
- **Nextcloud preview generation**: For smooth thumbnails, enable and configure the Preview Generator app alongside Memories (not the same app).
- **go-vod required for good video UX**: Without go-vod, video transcoding falls back to PHP ffmpeg wrapper which is slow and memory-intensive. Install go-vod for any video-heavy library.
- **Face recognition needs separate app**: AI tagging requires Nextcloud Recognize (object detection) or Face Recognition (face detection) app installed separately — not bundled in Memories.
- **Memory/CPU for indexing**: Initial indexing of large libraries is CPU/IO intensive. Run during off-hours; indexing can take hours for 100k+ photos.

## Links

- Upstream repo: https://github.com/pulsejet/memories
- Docs / config guide: https://memories.gallery/config/
- Nextcloud App Store: https://apps.nextcloud.com/apps/memories
- Demo: https://demo.memories.gallery
- Android app: https://f-droid.org/packages/gallery.memories/
- Release notes: https://github.com/pulsejet/memories/releases
