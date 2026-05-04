---
name: kroki-project
description: Kroki recipe for open-forge. Unified diagram-as-code HTTP API that converts plain-text diagram descriptions into images. Covers the gateway container (yuzutech/kroki) plus optional companion containers for extended diagram types (mermaid, bpmn, excalidraw, diagramsnet), Docker Compose setup, environment configuration, upgrade procedure, and gotchas. Stateless service — no database required. Upstream: https://github.com/yuzutech/kroki.
---

# Kroki

Unified diagram-as-code HTTP gateway that converts plain-text diagram descriptions into SVG/PNG/PDF images. Supports 20+ diagram types including PlantUML, Mermaid, Graphviz, BPMN, Excalidraw, D2, Ditaa, C4 and more. Upstream: <https://github.com/yuzutech/kroki>. Official docs: <https://docs.kroki.io/>.

Kroki is stateless — no database, no persistent storage required. A single gateway container handles most diagram types; optional companion containers extend coverage for Mermaid, BPMN, Excalidraw, and diagrams.net (draw.io). The gateway communicates with companion containers over HTTP.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (gateway only) | <https://docs.kroki.io/kroki/setup/install/> | ✅ | Most diagram types in one container. Simplest setup. |
| Docker Compose (gateway + companions) | <https://docs.kroki.io/kroki/setup/install/#docker-compose> | ✅ | Full diagram-type coverage including Mermaid, BPMN, Excalidraw, diagrams.net. |
| Run from source (Gradle) | <https://github.com/yuzutech/kroki#build-and-install> | ✅ | Development on the Kroki codebase itself. Not for production. |
| Kubernetes (community) | Community | ⚠️ Community-maintained | Cluster deployments — no official Helm chart; see community contributions. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Gateway only, or include companion containers for Mermaid / BPMN / Excalidraw / diagrams.net?" | `AskUserQuestion`: `Gateway only` / `Full (gateway + all companions)` / `Custom (select companions)` | Drives which Compose services to include. |
| network | "Expose Kroki on which host port?" (default `8000`) | Free-text | Kroki listens on `8000` inside the container. |
| access | "Should Kroki be publicly accessible or only on localhost / internal network?" | `AskUserQuestion`: `Localhost only` / `Behind reverse proxy` / `Public (no auth)` | Kroki has no built-in auth — if public-facing, a reverse proxy with rate-limiting / auth is strongly recommended. |
| dns | "Domain / base URL for reverse proxy?" | Free-text | Required if placing Kroki behind a proxy. |
| safe_mode | "Enable unsafe mode for PlantUML includes / remote resources?" | `AskUserQuestion`: `No (secure, default)` / `Yes (unsafe — internal only)` | Required for PlantUML !include directives. |

## Software-layer concerns

### Docker images

| Container | Image | Purpose |
|---|---|---|
| Gateway | `yuzutech/kroki` | Core HTTP API — handles most diagram types natively |
| Mermaid | `yuzutech/kroki-mermaid` | Mermaid diagrams (requires Chromium headless) |
| BPMN | `yuzutech/kroki-bpmn` | BPMN diagrams |
| Excalidraw | `yuzutech/kroki-excalidraw` | Excalidraw diagrams |
| diagrams.net | `yuzutech/kroki-diagramsnet` | draw.io / diagrams.net diagrams |

All images published on Docker Hub: <https://hub.docker.com/u/yuzutech>.

### Environment variables (gateway)

| Variable | Default | Description |
|---|---|---|
| `KROKI_MERMAID_HOST` | unset | Hostname of the mermaid companion container |
| `KROKI_BPMN_HOST` | unset | Hostname of the bpmn companion container |
| `KROKI_EXCALIDRAW_HOST` | unset | Hostname of the excalidraw companion container |
| `KROKI_DIAGRAMSNET_HOST` | unset | Hostname of the diagramsnet companion container |
| `KROKI_MAX_URI_LENGTH` | JVM default ~8192 | Max URL length in bytes for GET requests |
| `KROKI_SAFE_MODE` | `secure` | Safety mode: `unsafe` allows includes/fetching remote resources |

> KROKI_SAFE_MODE=unsafe is needed for PlantUML !include directives. Only enable on internal/trusted deployments.

### Ports

- Gateway listens on port `8000` inside the container.
- Companion containers each listen on port `8002` inside their containers.

### Data directory

Kroki is stateless — no persistent data directory required.

### Docker Compose (gateway + all companions)

Based on the upstream install docs at <https://docs.kroki.io/kroki/setup/install/>:

```yaml
# compose.yaml
services:
  kroki:
    image: yuzutech/kroki
    depends_on:
      - mermaid
      - bpmn
      - excalidraw
      - diagramsnet
    environment:
      - KROKI_MERMAID_HOST=mermaid
      - KROKI_BPMN_HOST=bpmn
      - KROKI_EXCALIDRAW_HOST=excalidraw
      - KROKI_DIAGRAMSNET_HOST=diagramsnet
    ports:
      - "127.0.0.1:8000:8000"
    restart: unless-stopped

  mermaid:
    image: yuzutech/kroki-mermaid
    expose:
      - "8002"
    restart: unless-stopped

  bpmn:
    image: yuzutech/kroki-bpmn
    expose:
      - "8002"
    restart: unless-stopped

  excalidraw:
    image: yuzutech/kroki-excalidraw
    expose:
      - "8002"
    restart: unless-stopped

  diagramsnet:
    image: yuzutech/kroki-diagramsnet
    expose:
      - "8002"
    restart: unless-stopped
```

```bash
docker compose up -d
# Test
curl http://localhost:8000/health
```

### Gateway only (single container)

```bash
docker run -d \
  --name kroki \
  --restart unless-stopped \
  -p 127.0.0.1:8000:8000 \
  yuzutech/kroki
```

### Verify

```bash
# Health check
curl http://localhost:8000/health

# Simple PlantUML test
curl "http://localhost:8000/plantuml/svg/SyfFKj2rKt3CoKnELR1Io4ZDoSa70000"
# Should return SVG content
```

## Upgrade procedure

Kroki is stateless — no backup needed before upgrading.

```bash
cd /path/to/kroki

# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d

# Verify
curl http://localhost:8000/health
```

For pinned tags, update image tags in `compose.yaml` before pulling. Check latest tags at <https://hub.docker.com/r/yuzutech/kroki/tags>.

## Gotchas

- **No built-in authentication.** Kroki has no auth layer — anyone who can reach the port can render diagrams. For public-facing deployments, place behind a reverse proxy with access controls.
- **`KROKI_SAFE_MODE=secure` blocks remote includes.** PlantUML `!include https://...` and other remote-resource fetches are rejected in secure mode (the default). Set `KROKI_SAFE_MODE=unsafe` only if needed and only on internal deployments.
- **Large diagrams may exceed URI length limit.** GET requests encode diagrams in the URL; complex diagrams can hit the JVM default ~8 KB limit. Use POST requests (supported by the API) or increase `KROKI_MAX_URI_LENGTH`.
- **Companion containers use Docker's internal network.** Set `KROKI_*_HOST` env vars to Compose service names (not `localhost`) — the gateway reaches companions via Docker DNS.
- **Mermaid companion is large.** The `kroki-mermaid` image includes a Chromium browser for headless rendering (~900 MB). Plan disk space accordingly.
- **First-start delay for Mermaid.** The Mermaid companion initialises a headless browser on startup; the first request may take several seconds.
- **Missing companion = error on that diagram type.** Without companion containers, diagram types that require them return an error. Check what's available at startup in the gateway logs.

## Upstream references

- GitHub: <https://github.com/yuzutech/kroki>
- Official docs: <https://docs.kroki.io/>
- Install guide: <https://docs.kroki.io/kroki/setup/install/>
- Docker Hub: <https://hub.docker.com/r/yuzutech/kroki>
- Supported diagram types: <https://kroki.io/#support>
- HTTP API reference: <https://docs.kroki.io/kroki/api/http-api/>
