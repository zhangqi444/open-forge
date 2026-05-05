---
name: imgproxy-project
description: imgproxy recipe for open-forge. Covers Docker single-container install as documented at https://docs.imgproxy.net.
---

# imgproxy

Fast and secure standalone server for resizing, processing, and converting images on the fly. Drop-in replacement for in-app image processing code. OSS edition is MIT-licensed. imgproxy Pro adds video/PDF preview generation, advanced smart cropping, and more. Upstream: <https://github.com/imgproxy/imgproxy>. Official site: <https://imgproxy.net/>. Docs: <https://docs.imgproxy.net/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker (single container) | <https://docs.imgproxy.net/installation> | Recommended; official GHCR image |
| Helm (Kubernetes) | <https://github.com/imgproxy/imgproxy-helm> | Production Kubernetes deploy |
| Binary (pre-built) | <https://github.com/imgproxy/imgproxy/releases> | Bare-metal without Docker |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| security | "IMGPROXY_KEY (hex, 64+ chars)?" | Hex string | Generate: `xxd -g 2 -l 64 -p /dev/random \| tr -d '\n'` |
| security | "IMGPROXY_SALT (hex, 64+ chars)?" | Hex string | Generate same way as KEY |
| preflight | "Which port should imgproxy listen on?" | Number (default `8080`) | `IMGPROXY_BIND` env var |
| sources (optional) | "Which source domains/buckets are allowed?" | Comma-separated URLs | `IMGPROXY_ALLOWED_SOURCES` — restrict to prevent abuse |

## Docker quick-start (from upstream docs)

```bash
# Generate key and salt first:
IMGPROXY_KEY=$(xxd -g 2 -l 64 -p /dev/random | tr -d '\n')
IMGPROXY_SALT=$(xxd -g 2 -l 64 -p /dev/random | tr -d '\n')

docker run -d \
  --name imgproxy \
  -p 8080:8080 \
  -e IMGPROXY_KEY=$IMGPROXY_KEY \
  -e IMGPROXY_SALT=$IMGPROXY_SALT \
  ghcr.io/imgproxy/imgproxy
```

## URL format

imgproxy processes images via specially constructed URLs:
```
http://host/SIGNATURE/PROCESSING_OPTIONS/plain/IMAGE_URL
```

Example — resize to 300×200, WebP output:
```
http://localhost:8080/sig/resize:fill:300:200/plain/https://example.com/image.jpg@webp
```

Signatures are HMAC-SHA256 of the path, using KEY+SALT. Use an imgproxy client library to generate signed URLs.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Port | Default `8080`. Override with `IMGPROXY_BIND=:9000` |
| URL signing | Required by default. KEY+SALT generate HMAC signatures to prevent URL forgery and abuse. |
| Allowed sources | `IMGPROXY_ALLOWED_SOURCES` — restrict which remote URLs imgproxy will fetch. Essential if publicly accessible. |
| Supported formats | JPEG, PNG, GIF, WebP, AVIF, JPEG XL, HEIC, SVG, BMP, TIFF, and more |
| Max resolution | `IMGPROXY_MAX_SRC_RESOLUTION` (megapixels) — prevent processing huge source images; default 16.8 MP |
| S3 / GCS sources | Set `IMGPROXY_USE_S3=true` + AWS env vars for S3; `IMGPROXY_USE_GCS=true` + `IMGPROXY_GCS_KEY` for GCS |
| Stateless | imgproxy is fully stateless — no database, no local storage. Safe to run multiple replicas. |
| Health check | `GET /health` → `200 OK` |

## Upgrade procedure

Per <https://github.com/imgproxy/imgproxy/releases>:

1. Pull the new image: `docker pull ghcr.io/imgproxy/imgproxy`
2. Stop and restart the container with the same env vars.
3. imgproxy is stateless — no migrations required.

## Gotchas

- **Always set KEY+SALT**: running without them (or with the insecure default) allows anyone to craft arbitrary image processing URLs, potentially hitting internal services or consuming server resources.
- **`IMGPROXY_ALLOWED_SOURCES`**: without this, imgproxy will fetch images from any URL. Set it to your CDN/storage domains to prevent SSRF.
- **Resolution limits**: very large source images (>16.8 MP by default) are rejected. Raise `IMGPROXY_MAX_SRC_RESOLUTION` if needed, but watch RAM usage.
- **GIF animation**: animated GIF processing is CPU-intensive. For heavy workloads, limit with `IMGPROXY_MAX_ANIMATION_FRAMES`.
- **OSS vs Pro**: video/PDF thumbnails, advanced smart cropping, and color adjustments require imgproxy Pro (commercial).

## Links

- Upstream README: <https://github.com/imgproxy/imgproxy>
- Documentation: <https://docs.imgproxy.net/>
- GHCR image: <https://github.com/imgproxy/imgproxy/pkgs/container/imgproxy>
- imgproxy Pro: <https://imgproxy.net/#pro>
- Helm chart: <https://github.com/imgproxy/imgproxy-helm>
