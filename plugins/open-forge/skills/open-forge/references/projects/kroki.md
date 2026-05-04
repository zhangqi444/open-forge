---
name: kroki
description: Recipe for Kroki — self-hosted unified diagram rendering API supporting 30+ diagram types (PlantUML, Mermaid, Graphviz, D2, Ditaa, and more).
---

# Kroki

Unified diagram-as-code rendering server. Accepts diagram source text and returns rendered images (SVG, PNG, PDF). Supports 30+ diagram types including PlantUML, Mermaid, Graphviz, D2, Ditaa, BlockDiag, C4 (via PlantUML), Excalidraw, and more — all via a single HTTP API. Deploy once, use from any tool that supports Kroki (draw.io, GitLab, Confluence plugins, etc.). Upstream: <https://github.com/yuzutech/kroki>. Docs: <https://docs.kroki.io>. Hosted: <https://kroki.io>. License: MIT.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (core image) | <https://hub.docker.com/r/yuzutech/kroki> | Yes | Basic rendering (PlantUML, Graphviz, Mermaid, D2, etc.) |
| Docker Compose (full) | <https://docs.kroki.io/kroki/setup/install/#_with_docker_compose> | Yes | All diagram types including BlockDiag, Excalidraw, Diagrams.net |
| Hosted service | <https://kroki.io> | Yes (managed) | No self-hosting needed |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for Kroki API? | Port (default 8000) | All |
| software | Which diagram types needed beyond core? | blockdiag / excalidraw / diagramsnet | Optional companion containers |

## Software-layer concerns

### Docker run (core — most diagram types)

```bash
docker run -d \
  --name kroki \
  -p 8000:8000 \
  --restart unless-stopped \
  yuzutech/kroki
```

The core image supports: PlantUML, Mermaid, GraphViz, D2, Ditaa, Nomnoml, Pikchr, Structurizr, BPMN, WireViz, Vega, Vega-Lite, and more.

### Docker Compose (full — all diagram types)

```yaml
services:
  core:
    image: yuzutech/kroki
    container_name: kroki
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      KROKI_BLOCKDIAG_HOST: blockdiag
      KROKI_MERMAID_HOST: mermaid
      KROKI_EXCALIDRAW_HOST: excalidraw
      KROKI_DIAGRAMSNET_HOST: diagramsnet

  blockdiag:
    image: yuzutech/kroki-blockdiag
    container_name: kroki-blockdiag
    restart: unless-stopped
    expose:
      - "8001"

  mermaid:
    image: yuzutech/kroki-mermaid
    container_name: kroki-mermaid
    restart: unless-stopped
    expose:
      - "8002"

  excalidraw:
    image: yuzutech/kroki-excalidraw
    container_name: kroki-excalidraw
    restart: unless-stopped
    expose:
      - "8004"

  diagramsnet:
    image: yuzutech/kroki-diagramsnet
    container_name: kroki-diagramsnet
    restart: unless-stopped
    expose:
      - "8005"
```

### API usage

```bash
# GET request with base64-encoded compressed diagram
curl https://kroki.io/plantuml/svg/SoWkIImgAStDuNBAJrBGjLDmpCbCJbMmKiX8pSd9vt98pKi1IW80

# POST request with diagram source
curl -X POST \
  -H "Content-Type: text/plain" \
  -d 'digraph G { A -> B -> C }' \
  http://localhost:8000/graphviz/svg

# POST with JSON
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"diagram_source": "A --> B", "diagram_type": "mermaid", "output_format": "svg"}' \
  http://localhost:8000/
```

### Supported diagram types (core image)

PlantUML, Mermaid, GraphViz (DOT), D2, Ditaa, Nomnoml, Pikchr, Structurizr, BPMN, WireViz, Vega, Vega-Lite, Erd, Svgbob, UMLet, Wavedrom, Bytefield, Nwdiag, Actdiag, Seqdiag, Rackdiag, Packetdiag (last six via companion blockdiag container), Excalidraw (companion), Diagrams.net/drawio (companion).

### URL encoding helper (CLI tool)

```bash
# Install kroki CLI
npm install -g @asciidoctor/kroki

# Or use the online encoder: https://kroki.io/#try
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- Companion containers: blockdiag, excalidraw, and diagramsnet diagram types require separate companion containers. The core image alone won't render them.
- Security: Kroki executes diagram rendering code server-side. Run behind a firewall or reverse proxy with auth if exposing to untrusted users — malicious PlantUML/Graphviz input could potentially abuse server resources.
- PlantUML server: Kroki bundles its own PlantUML — no separate PlantUML server needed.
- Mermaid companion: the core image includes Mermaid support via a lightweight renderer. The separate `kroki-mermaid` companion uses a full Chromium-based renderer for better compatibility.
- Output formats: not all diagram types support all output formats. SVG is universally supported; PNG requires a compatible renderer; PDF is supported for some types.

## Links

- GitHub: <https://github.com/yuzutech/kroki>
- Docs: <https://docs.kroki.io>
- Hosted service: <https://kroki.io>
- Docker Hub: <https://hub.docker.com/r/yuzutech/kroki>
- Supported diagram types: <https://kroki.io/#support>
