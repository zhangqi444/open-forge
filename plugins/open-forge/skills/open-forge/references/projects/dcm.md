---
name: dcm-project
description: DCM (Docker Compose Maker) recipe for open-forge. Self-hostable web app for interactively composing docker-compose.yaml files. Browse curated self-hosted app catalog, select containers, configure settings, and generate ready-to-use Compose configs.
---

# DCM — Docker Compose Maker

Open-source, self-hostable web tool for composing docker-compose.yaml files interactively. Browse a curated catalog of popular self-hosted containers, click to select, configure environment variables and paths, and download a ready-to-use docker-compose.yaml + .env file. Upstream: https://github.com/ajnart/dcm. Live hosted demo: https://compose.ajnart.dev. License: not specified in repo (check upstream). 

Language: TypeScript (Next.js). Image: `ghcr.io/ajnart/dcm`. Port: 7576. No database — stateless. Multi-arch: amd64, arm64, arm/v7.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux / macOS host | Docker (single container) | Recommended |
| Any Linux / macOS host | Docker Compose | For permanent self-hosted install |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Port to expose DCM on (default: 7576) | Only customization needed; app is stateless |

## Software-layer concerns

### Run with Docker (quick start)

From upstream README at https://github.com/ajnart/dcm#-quick-start.

  docker run -p 7576:7576 --name dcm --rm ghcr.io/ajnart/dcm

Visit http://localhost:7576.

The --rm flag removes the container when stopped. For a persistent install, use the Compose approach below.

### Docker Compose (for permanent install)

  services:
    dcm:
      image: ghcr.io/ajnart/dcm
      container_name: dcm
      ports:
        - "7576:7576"
      restart: unless-stopped

  docker compose up -d

### How DCM works

1. Browse the catalog — select the containers you want to include
2. Use templates — pick from predefined stacks (media server, etc.) from the Template Gallery
3. Configure settings — adjust environment variables, volume paths, and common options
4. Generate — click "Copy Compose" to get your customized docker-compose.yaml
5. Deploy — use the generated files with docker compose up -d, Portainer Stacks, or any Compose-compatible tool

All containers in DCM's catalog are pre-configured with best-practice defaults and use environment variable placeholders like ${PUID}, ${PGID}, and ${TZ}.

### Notes on the online vs self-hosted version

- The live demo at https://compose.ajnart.dev includes usage analytics
- The self-hosted Docker image has no analytics
- Both versions are functionally equivalent

## Upgrade procedure

  docker compose pull
  docker compose up -d

DCM is stateless — no data migration needed.

## Gotchas

- Set PUID, PGID, and TZ in the generated .env file before deploying Compose stacks from DCM — many containers use these for filesystem permissions and timezone configuration.
- The generated .env file must be in the same directory as docker-compose.yaml when running docker compose up.
- Portainer Stacks does not auto-read .env files in all configurations — paste environment variables manually into the Portainer Stack editor.
- DCM is a generator tool, not a manager — it creates initial Compose configs but does not manage running containers or updates.

## Links

- Upstream README: https://github.com/ajnart/dcm
- Live demo: https://compose.ajnart.dev
- GHCR image: https://github.com/ajnart/dcm/pkgs/container/dcm
