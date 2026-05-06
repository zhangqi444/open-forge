---
name: docat
description: DOCAT recipe for open-forge. Simple self-hosted documentation hosting with versioning — upload static docs via CLI or API, browse multiple projects and versions via a web UI. Source: https://github.com/docat-org/docat
---

# DOCAT

Simple self-hosted documentation hosting server. Upload static documentation (from mkdocs, Sphinx, mdBook, etc.) for multiple projects with multiple versions, then browse it through a clean web UI. Docs are served statically once uploaded; DOCAT handles storage, versioning, and tagging. Upstream: https://github.com/docat-org/docat. No official website; GitHub is the primary source.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker (official image) | Docker | Recommended. ghcr.io/docat-org/docat. |
| Docker with volumes | Docker | Persist docs, nginx config, and token DB across restarts. |
| Source | Python 3 | Clone repo, install dependencies, run directly. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Port to expose?" | Default: 8000 (maps to container port 80). |
| storage | "Volume path for docs?" | Host path mounted to /var/docat/ in container. |
| auth | "Token for protected projects?" | Tokens are created via the API; optional. |

## Software-layer concerns

### Docker run (simplest)

  mkdir -p docat-run/doc
  docker run \
    --detach \
    --volume $PWD/docat-run:/var/docat/ \
    --publish 8000:80 \
    --name docat \
    ghcr.io/docat-org/docat

  # Open http://localhost:8000

Use ghcr.io/docat-org/docat:unstable for latest changes.

### Docker Compose

  services:
    docat:
      image: ghcr.io/docat-org/docat
      ports:
        - "8000:80"
      volumes:
        - ./docat-data:/var/docat/
      restart: unless-stopped

### Volume contents (/var/docat/)

  doc/           - uploaded documentation files (one dir per project/version)
  nginx/         - generated nginx configs for serving
  db.sqlite3     - token database (optional auth)

### Uploading documentation

Use the docatl CLI (recommended):

  # Install CLI
  pip install docatl

  # Push docs (zip of built static site)
  docatl push --host http://localhost:8000 ./site PROJECT VERSION

  # Tag a version as 'latest'
  docatl push --host http://localhost:8000 ./site PROJECT VERSION --tag latest

Or use curl directly:

  # Upload a zip of static docs
  curl -X POST \
    http://localhost:8000/api/v1/docs/PROJECT/VERSION \
    -F "file=@./docs.zip"

  # Tag version as latest
  curl -X PUT \
    http://localhost:8000/api/v1/docs/PROJECT/VERSION/tags/latest

### Token-based auth (optional)

  # Create a token for a project (returns token string)
  curl -X POST http://localhost:8000/api/v1/tokens/PROJECT

  # Use token when uploading to protected projects:
  docatl push --host http://localhost:8000 --token <TOKEN> ./site PROJECT VERSION

## Upgrade procedure

  docker pull ghcr.io/docat-org/docat
  docker stop docat && docker rm docat
  # Re-run docker run or docker compose up -d
  # Volume data persists automatically

## Gotchas

- **Static docs only**: DOCAT hosts pre-built static HTML. You must generate your docs first (e.g. mkdocs build, sphinx-build), then upload the output directory as a zip.
- **No built-in TLS**: run behind nginx/Caddy reverse proxy for HTTPS.
- **nginx config regeneration**: DOCAT writes nginx configs into the volume on each upload; the container's nginx reloads automatically.
- **Zip format**: upload must be a zip file of the documentation root. The zip contents are extracted and served from the project/version path.
- **Token DB is SQLite**: lives in the volume. Back up db.sqlite3 if you use tokens.
- **Project names in URL**: case-sensitive. Consistent naming matters for discovery.

## References

- Upstream README: https://github.com/docat-org/docat#readme
- CLI tool (docatl): https://github.com/docat-org/docatl
- Getting started guide: https://github.com/docat-org/docat/blob/main/doc/getting-started.md
- Container image: https://github.com/docat-org/docat/pkgs/container/docat
