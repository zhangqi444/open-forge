---
name: sigal
description: Simple static photo gallery generator written in Python. Processes image directories recursively, generates portable HTML galleries with themes, supports videos, EXIF tags, and parallel processing. MIT licensed.
website: https://sigal.readthedocs.io/
source: https://github.com/saimn/sigal
license: MIT
stars: 938
tags:
  - photo-gallery
  - static-site-generator
  - media
  - photos
platforms:
  - Python
---

# sigal

sigal (Simple Gallery) is a Python-based static photo gallery generator. Point it at a directory of images, and it produces a fully self-contained static HTML gallery — no server-side code needed. Supports Jinja2 themes, video thumbnails, EXIF data display, zip downloads, and parallel image processing.

Source: https://github.com/saimn/sigal  
Docs: https://sigal.readthedocs.io/  
PyPI: https://pypi.org/project/sigal/  
Latest release: v2.6 (February 2026)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / macOS / Windows | Python 3.11+ + pip | Install and run locally; output is static HTML |
| CI/CD pipeline | Python 3.11+ + pip | Automate gallery builds on new photos |
| Any static host | Output served as static files | Upload output to Nginx, S3, GitHub Pages, Netlify, etc. |

## Inputs to Collect

**Phase: Planning**
- Source directory of images/videos
- Output directory for generated gallery
- Theme preference: `colorbox`, `galleria`, or `photoswipe` (default: `colorbox`)
- Image resize dimensions (width × height)
- Thumbnail dimensions
- Whether to generate video thumbnails (requires FFmpeg)
- Whether to include EXIF data in gallery pages

## Software-Layer Concerns

**Install:**
```bash
pip install sigal

# For video support (optional):
pip install sigal[video]   # requires FFmpeg on PATH
```

**Quickstart:**
```bash
# Generate a default config
sigal init

# Edit sigal.conf.py with your settings, then build:
sigal build /path/to/photos /path/to/output

# Preview locally:
sigal serve    # starts dev server at http://localhost:8000
```

**Key `sigal.conf.py` settings:**
```python
# Gallery metadata
title = "My Photo Gallery"

# Image settings
img_size = (1280, 960)
thumb_size = (300, 200)

# Theme: 'colorbox', 'galleria', or 'photoswipe'
theme = 'colorbox'

# Video support (requires FFmpeg)
video_size = (1280, 720)

# Include EXIF data
use_exif = True

# Zip download links
zip_gallery = True

# Parallel workers
ncpu = 4
```

**Directory structure:**
```
photos/
  album1/
    photo1.jpg
    photo2.jpg
    index.md        # optional album description (Markdown)
  album2/
    ...
```

**Output structure:** Self-contained static site — serve from any web server or static host.

**Nginx serving example:**
```nginx
server {
    listen 80;
    server_name gallery.example.com;
    root /var/www/gallery;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

**Automation with cron (rebuild on new photos):**
```bash
0 2 * * * sigal build /media/photos /var/www/gallery && rsync -avz /var/www/gallery/ user@server:/var/www/html/gallery/
```

## Upgrade Procedure

1. `pip install --upgrade sigal`
2. Re-run `sigal build` — rebuilds entire gallery from source
3. Review changelog: https://sigal.readthedocs.io/en/latest/changelog.html

## Gotchas

- **Static only**: sigal generates static HTML — no dynamic features (comments, user accounts, etc.) without third-party services (Disqus, etc.)
- **Python 3.11+ required**: v2.6+ requires Python 3.11 or newer; older versions supported older Python
- **FFmpeg for video**: Video thumbnail generation requires FFmpeg installed on PATH; without it, videos are listed but no thumbnails
- **Full rebuild**: By default, sigal rebuilds all images on each run; use `--force` flag to skip unchanged files, or incremental mode for large galleries
- **EXIF stripping**: If privacy is a concern, sigal can strip EXIF GPS data from output images (`img_processor = 'exiftool'`)
- **Albums from subdirectories**: Gallery structure mirrors directory structure — organize photos into subdirectories for albums
- **Serving output**: The `sigal serve` development server is not production-safe; always use Nginx/Apache for production

## Links

- Upstream README: https://github.com/saimn/sigal/blob/main/README.rst
- Documentation: https://sigal.readthedocs.io/
- Themes demo: http://saimon.org/sigal-demo/
- Changelog: https://sigal.readthedocs.io/en/latest/changelog.html
- PyPI: https://pypi.org/project/sigal/
