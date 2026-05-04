---
name: gotenberg
description: Recipe for Gotenberg — a stateless Docker-based API for converting documents to PDF using Chromium and LibreOffice.
---

# Gotenberg

Stateless HTTP API for document-to-PDF conversion. Bundles Headless Chromium (HTML/URL/Markdown → PDF, screenshots) and LibreOffice (100+ office formats → PDF). Also supports merging, splitting, rotating, watermarking, and PDF/A compliance. Upstream: <https://github.com/gotenberg/gotenberg>. Docs: <https://gotenberg.dev>. License: MIT. ~8K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://gotenberg.dev/docs/getting-started/installation> | ✅ | Recommended. Stateless, no storage needed. |
| Docker Compose | <https://gotenberg.dev/docs/getting-started/installation> | ✅ | Multi-service stacks embedding Gotenberg as a PDF service. |
| Kubernetes | <https://gotenberg.dev/docs/getting-started/installation> | ✅ | Scale-out deployments. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "What port should Gotenberg listen on?" | Integer (default `3000`) | All methods |
| software | "Request timeout?" | Duration string (default `30s`) | All methods |
| software | "Restrict which URLs Chromium can fetch (SSRF protection)?" | Regex string (e.g. `https://.*`) | Production deployments |

## Software-layer concerns

### Docker quickstart

```bash
docker run --rm -p 3000:3000 gotenberg/gotenberg:8
```

### Docker Compose

```yaml
services:
  gotenberg:
    image: gotenberg/gotenberg:8
    ports:
      - "3000:3000"
    restart: unless-stopped
    # Optional: pass CLI flags as command
    # command:
    #   - gotenberg
    #   - --chromium-allow-list=https://.*
    #   - --api-timeout=30s
```

### Key CLI flags

Gotenberg is configured via CLI flags passed as Docker `command` arguments.

| Flag | Default | Description |
|---|---|---|
| `--api-port` | `3000` | HTTP listen port |
| `--api-timeout` | `30s` | Per-request timeout |
| `--chromium-allow-list` | (unrestricted) | Regex allowlist for URLs Chromium may fetch |
| `--chromium-deny-list` | (none) | Regex denylist for Chromium URLs |
| `--uno-listener-restart-threshold` | `10` | LibreOffice listener restart limit |
| `--log-level` | `info` | `error` / `warn` / `info` / `debug` |
| `--log-format` | `text` | `text` or `json` |

### API examples

Convert URL to PDF:
```bash
curl --request POST http://localhost:3000/forms/chromium/convert/url \
  --form url=https://example.com \
  -o output.pdf
```

Convert HTML file to PDF:
```bash
curl --request POST http://localhost:3000/forms/chromium/convert/html \
  --form files=@index.html \
  -o output.pdf
```

Convert Office document to PDF:
```bash
curl --request POST http://localhost:3000/forms/libreoffice/convert \
  --form files=@document.docx \
  -o output.pdf
```

### Data directory

None — Gotenberg is fully stateless. No volumes required.

## Upgrade procedure

```bash
docker pull gotenberg/gotenberg:8
docker compose up -d
```

No database migrations or persistent state to manage.

## Gotchas

- **SSRF risk**: Chromium can reach internal network endpoints by default. In production, always set `--chromium-allow-list` to restrict which URLs it may fetch.
- **Memory for LibreOffice**: Office-to-PDF conversions can be memory-intensive on large files. Set Docker memory limits and monitor usage.
- **No built-in auth**: Gotenberg has no authentication. Place behind a reverse proxy with auth if exposed to untrusted networks.
- **Large image (~1.5 GB)**: Bundles Chromium + LibreOffice — first pull is slow.
- **Chromium sandbox in Kubernetes**: Restricted pod security contexts can break Chromium's sandbox. May need `SYS_ADMIN` capability or `--chromium-disable-web-security` — see upstream docs.

## Links

- GitHub: <https://github.com/gotenberg/gotenberg>
- Docs: <https://gotenberg.dev/docs/getting-started/introduction>
- Docker Hub: <https://hub.docker.com/r/gotenberg/gotenberg>
