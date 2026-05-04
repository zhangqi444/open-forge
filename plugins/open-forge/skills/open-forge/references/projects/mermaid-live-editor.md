---
name: mermaid-live-editor
description: Recipe for Mermaid Live Editor — self-hosted web editor for creating, previewing, and sharing Mermaid diagrams.
---

# Mermaid Live Editor

Self-hosted web application for editing, previewing, and sharing Mermaid diagrams in real time. Same editor as mermaid.live but deployable on your own infrastructure. Supports flowcharts, sequence diagrams, Gantt charts, class diagrams, and all other Mermaid diagram types. Export to SVG. Source: <https://github.com/mermaid-js/mermaid-live-editor>. Live demo: <https://mermaid.live>. License: MIT.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://github.com/mermaid-js/mermaid-live-editor#docker> | Yes | Recommended |
| Build from source | <https://github.com/mermaid-js/mermaid-live-editor#development> | Yes | Custom builds with different renderer URLs |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for editor UI? | Port (default 8000, maps to container 8080) | All |
| software | Custom renderer URL? | URL (default https://mermaid.ink) | Optional; for fully offline diagram rendering |
| software | Custom Kroki instance URL? | URL (default https://kroki.io) | Optional; for Kroki diagram export |
| software | Analytics instance? | Plausible URL + domain | Optional |

## Software-layer concerns

### Docker run (published image)

```bash
docker run --platform linux/amd64 \
  --publish 8000:8080 \
  --name mermaid-live-editor \
  --restart unless-stopped \
  ghcr.io/mermaid-js/mermaid-live-editor
```

Access at http://localhost:8000

> The published image uses default environment variables baked at build time. To customize renderer URLs, build the image yourself (see below).

### Docker Compose

```yaml
services:
  mermaid-live-editor:
    image: ghcr.io/mermaid-js/mermaid-live-editor
    container_name: mermaid-live-editor
    platform: linux/amd64
    restart: unless-stopped
    ports:
      - "8000:8080"
```

### Custom build (to override renderer URLs)

```bash
git clone https://github.com/mermaid-js/mermaid-live-editor.git
cd mermaid-live-editor

# Build with custom renderer
docker build \
  --build-arg MERMAID_RENDERER_URL=https://your-mermaid-renderer.example.com \
  --build-arg MERMAID_KROKI_RENDERER_URL=https://your-kroki.example.com \
  -t my-mermaid-editor .

docker run -p 8000:8080 my-mermaid-editor
```

### Build arguments

| Argument | Default | Description |
|---|---|---|
| MERMAID_RENDERER_URL | https://mermaid.ink | URL for PNG/SVG rendering service |
| MERMAID_KROKI_RENDERER_URL | https://kroki.io | URL for Kroki diagram export |
| MERMAID_ANALYTICS_URL | (empty) | Plausible analytics instance URL |
| MERMAID_DOMAIN | (empty) | Domain for analytics |

### Fully offline setup (with local renderer)

For air-gapped environments, pair with a local Kroki instance or mermaid.ink deployment:
- Kroki (supports many diagram types including Mermaid): <https://kroki.io/> — self-host via Docker
- Set `MERMAID_RENDERER_URL` to your local mermaid.ink instance
- Set `MERMAID_KROKI_RENDERER_URL` to your local Kroki instance

## Upgrade procedure

```bash
docker pull ghcr.io/mermaid-js/mermaid-live-editor
docker compose up -d
```

## Gotchas

- `linux/amd64` only: the published Docker image is amd64-only. On ARM64 (Apple Silicon, ARM servers), add `--platform linux/amd64` or build from source for native ARM.
- Renderer calls external services by default: the published image calls `mermaid.ink` and `kroki.io` for PNG/SVG exports. For fully private use, build a custom image pointing to local instances.
- Stateless: the editor stores diagram state in the URL (base64 encoded) or browser local storage. No server-side persistence.
- Share links encode diagram in URL: share links embed the full diagram definition in the URL. They don't "phone home" — but the URL can be long for complex diagrams.
- Mermaid.js version: the editor version determines which Mermaid.js version (and diagram syntax) is supported. Pin to a specific image tag for consistency.

## Links

- GitHub: <https://github.com/mermaid-js/mermaid-live-editor>
- Live demo: <https://mermaid.live>
- Container registry: <https://github.com/mermaid-js/mermaid-live-editor/pkgs/container/mermaid-live-editor>
- Mermaid.js docs (diagram syntax): <https://mermaid.js.org/intro/>
- Kroki (multi-format diagram renderer): <https://kroki.io/>
