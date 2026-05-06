---
name: draw.io
description: draw.io (diagrams.net) recipe for open-forge. Self-hosted diagramming and whiteboarding app — flowcharts, UML, ER diagrams, org charts, network diagrams. Docker install. Upstream: https://github.com/jgraph/drawio
---

# draw.io (diagrams.net)

Self-hosted diagramming and whiteboarding application. Create flowcharts, process diagrams, org charts, UML, ER diagrams, network diagrams, and more. The same engine that powers diagrams.net/draw.io — hosted on your own infrastructure.

5,167 stars · Apache-2.0

Upstream: https://github.com/jgraph/drawio
Docker image: https://github.com/jgraph/docker-drawio
Website: https://draw.io / https://app.diagrams.net
Docker Hub: https://hub.docker.com/r/jgraph/drawio

## What it is

draw.io provides a full-featured diagramming editor:

- **Diagram types** — Flowcharts, UML class/sequence/state, ER, BPMN, C4, network, org charts, wireframes, Kanban
- **Rich shape libraries** — AWS, Azure, GCP, network, general shapes, custom stencils
- **Export formats** — PNG, SVG, PDF, HTML embed, XML, Viso (VSDX)
- **Import** — Gliffy, Lucidchart, Visio, PlantUML, Mermaid, CSV
- **Integrations** — Confluence, Jira, VS Code, Notion, Obsidian, Chrome extension
- **Themes** — Multiple UI themes including dark mode
- **Offline support** — Works without internet after loading
- **No real-time collaboration** — Single-user editor; files shared externally
- **Storage agnostic** — Save to local browser, GitHub, GitLab, OneDrive, Google Drive

Note: draw.io does not accept pull requests; the Docker image is maintained at github.com/jgraph/docker-drawio.

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Single container | Official jgraph/drawio image; recommended |
| GitHub Pages | Static JS | Fork and publish for a basic editor without integrations |
| WAR file | Tomcat/Java | Download .war from releases page |

## Inputs to collect

### Phase 1 — Pre-install
- Domain / public URL for the instance
- SSL setup (required for secure embedding in third-party tools)
- Port to expose (default: 8080 HTTP, 8443 HTTPS)
- Organisation details for self-signed cert (if not using reverse proxy for TLS)

## Software-layer concerns

### Config paths
No persistent data directory — draw.io is stateless; diagrams are stored in browser or connected storage (GitHub, Google Drive, etc.)

### Docker environment variables (for self-signed cert generation)
  PUBLIC_DNS=diagrams.example.com
  ORGANISATION_UNIT=IT
  ORGANISATION=ACME Corp
  CITY=San Francisco
  STATE=California
  COUNTRY_CODE=US

These are used only if relying on the container's built-in self-signed HTTPS. For production, use a reverse proxy with Let's Encrypt.

### Ports
- 8080 — HTTP
- 8443 — HTTPS (built-in self-signed cert or via reverse proxy)

## Docker Compose install

  version: '3.5'
  services:
    drawio:
      image: jgraph/drawio
      container_name: drawio
      restart: unless-stopped
      ports:
        - "8080:8080"
        - "8443:8443"
      environment:
        PUBLIC_DNS: diagrams.example.com
        ORGANISATION_UNIT: IT
        ORGANISATION: ACME
        CITY: San Francisco
        STATE: California
        COUNTRY_CODE: US
      healthcheck:
        test: ["CMD-SHELL", "curl -f http://diagrams.example.com:8080 || exit 1"]
        interval: 90s
        timeout: 10s
        retries: 5

Access at http://<host>:8080 or https://<host>:8443

### Reverse proxy (Nginx + Let's Encrypt)
  server {
    listen 443 ssl;
    server_name diagrams.example.com;
    ssl_certificate /etc/letsencrypt/live/diagrams.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/diagrams.example.com/privkey.pem;
    location / {
      proxy_pass http://localhost:8080;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto https;
    }
  }

## Upgrade procedure

1. Pull latest: docker pull jgraph/drawio
2. Restart container: docker compose up -d --force-recreate drawio
3. Verify at http://<host>:8080 — no data migration needed (stateless)

## Gotchas

- Stateless — diagrams are not stored on the server; users must save files locally or connect cloud storage (Google Drive, GitHub, OneDrive)
- No real-time collaboration — multi-user concurrent editing is not supported in the self-hosted version; use diagrams.net cloud for that
- Icon/stencil license restriction — icon sets may not be redistributed as software assets in Atlassian products (see upstream README)
- Trademark — do not use the draw.io name or logo in ways suggesting affiliation; the project is "draw.io" or "diagrams.net"
- HTTPS for integrations — Confluence and other integrations require HTTPS; use a reverse proxy with a real cert
- Large diagrams — very complex diagrams may be slow in browser; no server-side rendering involved
- WAR alternative — if you need Tomcat-based deploy, download .war from github.com/jgraph/drawio/releases

## Links

- Upstream README: https://github.com/jgraph/drawio/blob/dev/README.md
- Docker image repo: https://github.com/jgraph/docker-drawio
- Docker Hub: https://hub.docker.com/r/jgraph/drawio
- Releases: https://github.com/jgraph/drawio/releases
