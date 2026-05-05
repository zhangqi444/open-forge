---
name: Thumbor
description: "Smart on-demand image processing service — crop, resize, apply filters, and optimize images via URL parameters with AI-powered face/feature detection for smart cropping. Python. MIT."
---

# Thumbor

Thumbor is a smart imaging service that performs on-demand image cropping, resizing, filtering, and optimization via simple URL parameters. Its key differentiator is **smart cropping** — it uses AI/computer vision (face detection, feature detection) to intelligently determine the best crop region instead of naively cutting from corners.

Created at globo.com (Brazilian media company); now an independent project. Used by Wikipedia, Vox Media, Forbes, Square, Deliveroo, Canal+, and many others in production at scale.

Use cases: (a) image CDN with on-demand resizing (b) responsive images without storing multiple pre-generated sizes (c) smart cropping for thumbnails that avoid severing heads/faces (d) image optimization pipeline (WebP conversion, compression) (e) replacing Imgix or Cloudinary with self-hosted alternative.

Features:

- **On-demand resizing** — specify dimensions in the URL; images scaled on first request and cached
- **Smart cropping** — face detection + feature detection to choose best crop point
- **Manual cropping** — explicit crop coordinates in URL
- **Fit modes** — fit-in (letterbox), adaptive fit-in, stretch
- **Filters** — brightness, contrast, grayscale, blur, rotate, sharpen, format conversion (WebP, AVIF), quality, watermark, and more
- **Result storage** — cache processed images to avoid reprocessing (local, S3, Redis, memcached)
- **Loader plugins** — load source images from HTTP, S3, filesystem, or custom sources
- **Security** — URL signing to prevent unauthorized image processing
- **Extensions** — Python-based plugin system for custom detectors, filters, loaders, result stores

- Upstream repo: https://github.com/thumbor/thumbor
- Homepage: http://thumbor.org/
- Docs: https://thumbor.readthedocs.io/

## Architecture

- **Python** — Tornado async HTTP server
- **Source loader** — fetches original images (HTTP URL, S3, local)
- **Detectors** — OpenCV face/feature detection (optional; requires OpenCV)
- **Processors** — Pillow (default) or OpenCV for image operations
- **Result storage** — where processed images are cached (local filesystem, S3, Redis, memcached)
- **Storage** — where original images are stored if using Thumbor as origin (optional; can proxy to any HTTP source)
- **Security key** — HMAC URL signing to prevent abuse

## Compatible install methods

| Infra       | Runtime              | Notes                                                        |
|-------------|----------------------|--------------------------------------------------------------|
| Docker      | `thumbororg/thumbor` | Official Docker image; quick start                           |
| Python      | pip install thumbor  | Python 3.8+; requires Pillow                                 |
| Docker Compose | with Redis cache  | Redis for result storage; standard production pattern        |
| Kubernetes  | Deployment           | Horizontally scalable; shared result storage (S3/Redis)      |

## Inputs to collect

| Input            | Example                    | Phase   | Notes                                                         |
|------------------|----------------------------|---------|---------------------------------------------------------------|
| Security key     | `MY_SECURITY_KEY`          | Security| Used to sign URLs; required to prevent abuse on public installs|
| Result storage   | filesystem / S3 / Redis     | Config  | Where to cache processed images                               |
| Source loader    | http / file / s3            | Config  | Where source images come from                                 |
| Port             | `8888`                     | Config  | Default Thumbor port                                          |
| Allowed sources  | `example.com`              | Security| Restrict which domains Thumbor will load source images from   |

## Quick start (Docker)

```sh
docker run -p 8888:8888 \
  -e SECURITY_KEY=MY_SECURITY_KEY \
  -e ALLOWED_SOURCES=example.com \
  thumbororg/thumbor:latest
```

## URL format

```
http://thumbor-host:8888/<hmac>/<width>x<height>/smart/<source-url>
```

Examples:
```
# Resize to 300x200, smart crop
http://localhost:8888/unsafe/300x200/smart/https://example.com/photo.jpg

# Resize width only (proportional height)
http://localhost:8888/unsafe/300x0/https://example.com/photo.jpg

# Fit-in (letterbox) 300x200
http://localhost:8888/unsafe/fit-in/300x200/https://example.com/photo.jpg

# Apply filters: grayscale + blur
http://localhost:8888/unsafe/300x200/filters:grayscale():blur(5)/https://example.com/photo.jpg

# Convert to WebP with quality 80
http://localhost:8888/unsafe/300x200/filters:format(webp):quality(80)/https://example.com/photo.jpg
```

Note: `unsafe` bypasses HMAC signing — only use on trusted internal networks. For public deployments, always use signed URLs.

## URL signing

```python
# Generate signed Thumbor URL
from libthumbor import CryptoURL

crypto = CryptoURL(key='MY_SECURITY_KEY')
url = crypto.generate(
    width=300, height=200,
    smart=True,
    image_url='https://example.com/photo.jpg'
)
# → /abc123.../300x200/smart/https://example.com/photo.jpg
```

Or use the `thumbor-url` CLI: `thumbor-url -k MY_SECURITY_KEY -s https://example.com/photo.jpg -w 300 -e 200`

## Docker Compose (with Redis result storage)

```yaml
services:
  thumbor:
    image: thumbororg/thumbor:latest
    ports:
      - "8888:8888"
    environment:
      - SECURITY_KEY=change-this-to-a-strong-key
      - RESULT_STORAGE=thumbor.result_storages.redis_storage
      - RESULT_STORAGE_REDIS_HOST=redis
      - ALLOWED_SOURCES=example.com,cdn.example.com
    depends_on:
      - redis

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

volumes:
  redis-data:
```

## Config essentials

```python
# thumbor.conf
SECURITY_KEY = 'your-strong-key'
ALLOWED_SOURCES = ['example.com', 'images.example.com']

# Result storage (cache processed images)
RESULT_STORAGE = 'thumbor.result_storages.file_storage'
RESULT_STORAGE_FILE_STORAGE_ROOT_PATH = '/data/result_storage'

# Smart detection (requires OpenCV)
DETECTORS = [
    'thumbor.detectors.face_detector',
    'thumbor.detectors.feature_detector',
]

# Image quality
QUALITY = 80
WEBP_QUALITY = 80
MAX_WIDTH = 4096
MAX_HEIGHT = 4096
```

## Gotchas

- **`unsafe` mode must not be used in production** — `unsafe` in the URL skips HMAC verification. Anyone can use your Thumbor instance to proxy-resize any image from the internet, consuming your bandwidth and CPU. Always enable and use URL signing for public deployments. Use `ALLOWED_SOURCES` to restrict which domains can be loaded.
- **First request is slow** — Thumbor fetches and processes on demand; the first request for a new size/crop is synchronous. With result storage enabled, subsequent identical requests are served from cache. Without caching, every request re-processes.
- **Smart detection requires OpenCV** — the face/feature detection that powers smart cropping needs OpenCV (cv2). The standard Docker image may not include it; use `thumbororg/thumbor-opencv` or install `thumbor[cv]` extras. Without OpenCV, smart crop falls back to focal-point-based cropping.
- **Memory usage scales with concurrent requests** — each active image processing operation uses memory. Size your instance based on expected concurrency × average image size. 512 MB RAM handles light traffic; plan for 1–2 GB+ for busy installations.
- **SSRF risk without ALLOWED_SOURCES** — without `ALLOWED_SOURCES`, Thumbor will fetch any URL passed to it, including internal services. Always set `ALLOWED_SOURCES` to only your trusted domains.
- **Max dimensions** — set `MAX_WIDTH` and `MAX_HEIGHT` to prevent abuse (requesting huge output images wastes CPU/RAM).
- **Python 3.8+ required** — older Python versions not supported in recent releases.
- **Alternatives:** Imgproxy (Go, faster, Docker-ready, more formats), imaginary (Go, no OpenCV dependency), Cloudinary (SaaS, full-featured), Imgix (SaaS), sharp (Node.js library, not a service).

## Links

- Repo: https://github.com/thumbor/thumbor
- Homepage: http://thumbor.org/
- Documentation: https://thumbor.readthedocs.io/
- Docker Hub: https://hub.docker.com/r/thumbororg/thumbor
- Python package: https://pypi.org/project/thumbor/
- thumbor-bootcamp (learn/contribute): https://github.com/thumbor/thumbor-bootcamp
