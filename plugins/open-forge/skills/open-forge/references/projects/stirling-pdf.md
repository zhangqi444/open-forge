---
name: stirling-pdf-project
description: Stirling PDF recipe for open-forge. Open-source PDF editing platform with 50+ tools. Covers Docker and Docker Compose deployment, configuration volumes, lite vs fat image variants, and upgrade procedure. Derived from https://github.com/Stirling-Tools/Stirling-PDF and https://docs.stirlingpdf.com.
---

# Stirling PDF

Open-source PDF editing platform with 50+ tools. Upstream: <https://github.com/Stirling-Tools/Stirling-PDF>. Documentation: <https://docs.stirlingpdf.com>. License: MIT.

Stirling PDF supports editing, merging, splitting, signing, redacting, converting (including OCR), compressing, and automating PDF workflows. Available as a desktop app, browser UI, and self-hosted server with REST API. Interface available in 40+ languages.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://docs.stirlingpdf.com> | yes | Quickest deploy. |
| Docker Compose | <https://docs.stirlingpdf.com> | yes | Recommended for persistent config/data. |
| Desktop app | <https://docs.stirlingpdf.com> | yes | Windows/Mac/Linux local app. |
| Kubernetes (Helm) | <https://docs.stirlingpdf.com> | yes | Large-scale deployments. |
| Bare metal | <https://docs.stirlingpdf.com> | yes | Manual server setup without Docker. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should Stirling PDF run on?" | Integer default 8080 | Maps to 8080:8080 in compose. |
| preflight | "Use lite image or fat image?" | lite / fat | fat includes extra fonts and tools for highest quality conversions and full format support. |
| config | "Where to store config files on the host?" | Path default ./stirling-data | Mounted to /configs inside container. |

## Docker install

Upstream: <https://docs.stirlingpdf.com>

```bash
docker run -d \
  -p 8080:8080 \
  -v ./stirling-data:/configs \
  stirlingtools/stirling-pdf:latest
```

Access at http://localhost:8080.

For the fat image (extra fonts, full format support):

```bash
docker run -d \
  -p 8080:8080 \
  -v ./stirling-data:/configs \
  stirlingtools/stirling-pdf:latest-fat
```

## Docker Compose install

```yaml
services:
  stirling-pdf:
    image: stirlingtools/stirling-pdf:latest
    ports:
      - "8080:8080"
    volumes:
      - ./stirling-data:/configs
      # Optional: custom fonts
      # - ./custom-fonts:/customFiles/fonts
    restart: unless-stopped
```

Deploy:
```bash
docker compose up -d
```

## Software-layer concerns

### Image variants

| Tag | Contents | Use when |
|---|---|---|
| latest | Standard image | Most users |
| latest-fat | Extra fonts + Calibre, LibreOffice tools | Need highest quality conversions, full format support |

### Ports

| Port | Use |
|---|---|
| 8080 | Web UI and REST API (HTTP) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /configs | Application configuration, settings, login config |
| /customFiles/fonts | Optional custom font files |
| /customFiles/signatures | Optional custom signature files |
| /logs | Application logs |

### Configuration

Settings are persisted in /configs. The web UI Settings panel controls most options. For server-level config (authentication, API keys, security), edit /configs/settings.yml.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Configuration in /configs is preserved across upgrades.

## Gotchas

- **lite vs fat**: The standard (lite) image omits some conversion tools for a smaller image size. If conversions fail or quality is poor, switch to latest-fat.
- **No login by default**: Authentication is disabled by default. For internet-facing deployments, enable login in Settings -> Security, or use a reverse proxy with auth.
- **REST API**: All 50+ tools have REST API endpoints. See <https://docs.stirlingpdf.com> for the API reference (also accessible at /swagger-ui on a running instance).
- **OCR**: OCR functionality requires Tesseract, which is included in the container. Language packs beyond English can be configured in settings.
- **Memory**: Complex PDF operations (large files, OCR, conversion) are memory-intensive. Allocate 2+ GB RAM for the container.

## Links

- GitHub: <https://github.com/Stirling-Tools/Stirling-PDF>
- Documentation: <https://docs.stirlingpdf.com>
- Docker Hub: <https://hub.docker.com/r/stirlingtools/stirling-pdf>
