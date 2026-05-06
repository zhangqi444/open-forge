---
name: flyimg
description: Flyimg recipe for open-forge. Self-hosted on-the-fly image resizing, cropping, and optimization service using ImageMagick and MozJPEG. Acts as a drop-in Cloudinary alternative via a URL-based API. Source: https://github.com/flyimg/flyimg
---

# Flyimg

Self-hosted image resizing, cropping, and compression service. Fetch any image via a URL, apply transformations (resize, crop, quality), and get back an optimized image in AVIF, WebP, MozJPEG, PNG, or JPEG XL. Results are cached for fast repeat requests. Acts as a drop-in Cloudinary-style image CDN for your own infrastructure. Upstream: https://github.com/flyimg/flyimg. Docs: https://docs.flyimg.io.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (official image) | Docker | Recommended. flyimg/flyimg on Docker Hub. |
| Docker with custom config | Docker | Mount custom parameters.yml. |
| Source (PHP/Composer) | PHP 8+ | Clone, build image, run container. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Port to expose?" | Default: 8080 (maps to container port 80) |
| config | "Allowed domains?" | Restrict which remote image domains can be fetched (in parameters.yml) |
| storage | "Cache directory?" | Container stores cached images at /var/www/html/var/cache — mount a volume for persistence |

## Software-layer concerns

### Docker run (simplest)

  docker run -itd -p 8080:80 flyimg/flyimg

### Docker run with custom config

  # Download default parameters.yml
  curl -o parameters.yml https://raw.githubusercontent.com/flyimg/flyimg/main/config/parameters.yml
  # Edit: set allowed_domains, cache settings, etc.

  docker run -itd -p 8080:80 \
    -v $(pwd)/parameters.yml:/var/www/html/config/parameters.yml \
    flyimg/flyimg

### Docker Compose

  services:
    flyimg:
      image: flyimg/flyimg
      ports:
        - "8080:80"
      volumes:
        - ./parameters.yml:/var/www/html/config/parameters.yml
        - flyimg-cache:/var/www/html/var/cache
      restart: unless-stopped
  volumes:
    flyimg-cache:

### URL-based transformation API

Transform images by constructing the URL:

  http://<host>:8080/upload/<options>/<image-url>

Common options:
  w_300           - width 300px
  h_200           - height 200px
  w_300,h_200     - resize to 300x200
  c_1             - crop (1=true)
  q_90            - quality 90%
  o_webp          - force WebP output
  o_auto          - auto-negotiate format from Accept header
  o_avif          - force AVIF output (default when browser supports it)
  o_jxl           - force JPEG XL output

Examples:

  # Resize remote image to width 300:
  http://localhost:8080/upload/w_300/https://example.com/photo.jpg

  # Crop to 200x200 at 90% quality:
  http://localhost:8080/upload/w_200,h_200,c_1,q_90/https://example.com/photo.jpg

### Key parameters.yml settings

  # Restrict which domains can be fetched (security)
  allowed_domains:
    - example.com
    - cdn.yoursite.com

  # Cache TTL and path
  cache_enabled: true

## Upgrade procedure

  docker pull flyimg/flyimg
  docker stop flyimg && docker rm flyimg
  # Re-run with same volume mounts

## Gotchas

- **Security — allowed_domains**: by default Flyimg may fetch images from any URL. Set allowed_domains in parameters.yml to restrict to your own domains only — otherwise it becomes an open proxy.
- **Cache persistence**: without a named volume for the cache directory, cached images are lost on container restart. Mount a volume for production use.
- **Memory**: ImageMagick can use significant RAM for large images. Set Docker memory limits for shared servers.
- **AVIF encoding is slow**: the first request for a new image may be slow (AVIF encoding). Cached responses are fast. Tune via parameters.yml if needed.
- **Not a CDN replacement by itself**: Flyimg processes and caches images but does not do geographic distribution. Put a CDN or reverse proxy cache in front for high-traffic use.
- **PHP 8+ required for source install**: and requires Composer and the ImageMagick PHP extension (imagick).

## References

- Upstream GitHub: https://github.com/flyimg/flyimg
- Documentation: https://docs.flyimg.io
- Docker Hub: https://hub.docker.com/r/flyimg/flyimg
- Demo: https://demo.flyimg.io
