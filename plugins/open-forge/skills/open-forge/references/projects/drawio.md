---
name: drawio
description: Recipe for draw.io (diagrams.net) — self-hosted diagramming and whiteboarding application via the official Docker image.
---

# draw.io (diagrams.net)

Open-source diagramming and whiteboarding application. Self-host the same editor available at app.diagrams.net. Supports flowcharts, UML, network diagrams, org charts, BPMN, and more. Integrates with Nextcloud, Confluence, and VS Code. The Docker image is maintained at <https://github.com/jgraph/docker-drawio>. Upstream editor: <https://github.com/jgraph/drawio>. Hosted: <https://app.diagrams.net>. License: Apache-2.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://github.com/jgraph/docker-drawio> | Yes | Recommended self-hosted deployment |
| Docker Compose (with export server) | <https://github.com/jgraph/docker-drawio> | Yes | Full-featured: PDF/image export support |
| GitHub Pages fork | <https://github.com/jgraph/drawio#running> | Yes | Static hosting; no export server |
| WAR file | <https://github.com/jgraph/draw.io/releases> | Yes | Java Tomcat deployment |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for draw.io? | Port (default 8080 HTTP / 8443 HTTPS) | All |
| infra | Let's Encrypt domain? | FQDN | Optional; enables auto-TLS |
| software | Offline mode? | Boolean | Set ?offline=1 in URL to disable cloud storage |
| software | Enable export server? | Boolean | Required for PDF/image export from self-hosted instance |

## Software-layer concerns

### Docker run (quickstart)

```bash
docker run -it --rm --name draw \
  -p 8080:8080 \
  -p 8443:8443 \
  jgraph/drawio
```

Access: http://localhost:8080/?offline=1&https=0 (HTTP) or https://localhost:8443/?offline=1 (HTTPS with self-signed cert).

`?offline=1` disables cloud storage integrations (Google Drive, OneDrive) — recommended for air-gapped or privacy-focused setups.

### Docker Compose (with export server)

```yaml
services:
  drawio:
    image: jgraph/drawio
    container_name: drawio
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8443:8443"
    environment:
      DRAWIO_SELF_HOSTED: "1"
      DRAWIO_EXPORT_URL: http://export-server:8000/
    depends_on:
      - export-server

  export-server:
    image: jgraph/export-server
    container_name: drawio-export
    restart: unless-stopped
    expose:
      - "8000"
    volumes:
      - export-fonts:/usr/share/fonts/drawio
    environment:
      DRAWIO_BASE_URL: http://drawio:8080

volumes:
  export-fonts:
```

### Docker Compose with Let's Encrypt

```yaml
services:
  drawio:
    image: jgraph/drawio
    container_name: drawio
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      LETS_ENCRYPT_ENABLED: "true"
      PUBLIC_DNS: draw.example.com
```

### Key environment variables

| Variable | Default | Description |
|---|---|---|
| LETS_ENCRYPT_ENABLED | false | Auto-issue Let's Encrypt cert |
| PUBLIC_DNS | draw.example.com | Domain for TLS cert |
| DRAWIO_SELF_HOSTED | (unset) | Set to 1 to indicate self-hosted mode |
| DRAWIO_EXPORT_URL | (unset) | URL of export-server container |

### Nextcloud integration

Use the official docker-compose with Nextcloud support — see <https://github.com/jgraph/docker-drawio> for the Nextcloud compose file. The draw.io Nextcloud app is installed separately from the Nextcloud app store.

### Offline / self-contained mode

For fully air-gapped deployments (no calls to diagrams.net), use the self-contained compose that includes PlantUML, Google Drive proxy, OneDrive proxy, and EMF conversion — all optional. See the docker-drawio repo for `docker-compose-self-contained.yml`.

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

draw.io releases frequently. No database migrations required — it is stateless (diagrams stored locally in browser or uploaded to your file storage).

## Gotchas

- No built-in persistence: draw.io is a stateless web app. Diagrams are not stored on the server — users save to local files, browser storage, or configured cloud storage (Google Drive, Nextcloud, OneDrive).
- Export server is optional but required for PDF/SVG export from the browser: without it, "Export as PDF" in the self-hosted editor will fail.
- `?offline=1` parameter: required in the URL to prevent the editor from attempting calls to diagrams.net for fonts and resources. Important for air-gapped environments.
- Pull requests not accepted: the draw.io project does not accept external contributions to the editor codebase.
- No real-time collaboration: the self-hosted version does not support simultaneous multi-user editing (unlike Confluence's draw.io plugin).

## Links

- Docker image GitHub: <https://github.com/jgraph/docker-drawio>
- Editor GitHub: <https://github.com/jgraph/drawio>
- Hosted version: <https://app.diagrams.net>
- Docker Hub: <https://hub.docker.com/r/jgraph/drawio>
- Export server Docker Hub: <https://hub.docker.com/r/jgraph/export-server>
