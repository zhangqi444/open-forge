---
name: draw.io (diagrams.net)
description: "Open-source diagramming + whiteboarding web app — the engine behind app.diagrams.net. Self-host your own editor; works offline. Apache-2.0 source; restricted stencil/icon license (no Atlassian marketplace). No PRs accepted; developed by core team."
---

# draw.io (diagrams.net)

draw.io is **the dominant free + open-source web-based diagramming application** — runs the publicly-hosted `https://app.diagrams.net` and is the engine behind Google Drive's "Diagrams.net" add-on + Confluence's diagramming. Supports flowcharts, UML, network diagrams, AWS/Azure/GCP architecture, floor plans, org charts, BPMN, ER diagrams, mind maps, and whiteboarding. Jointly developed + owned by **draw.io Ltd (formerly JGraph)** and **draw.io AG**.

**Important licensing distinction** (quoted from README):
- **Source code** (the Java/JS app) — **Apache 2.0**
- **Icon sets, stencil libraries, diagram templates** — **separately licensed**, with specific restriction: *"may not be used as software assets in, distributed for use with, or incorporated into Atlassian products or products distributed through the Atlassian marketplace or plugin ecosystem, without explicit written permission."*
- End-user diagrams (images you export) are YOUR property + unrestricted.

**Development model** (quoted): *"We do not accept pull requests. The project is developed entirely by the core team."* — community fixes happen via issues; core team decides + implements. Unusual for open source; honest about it.

Features:

- **Diagram types**: flowcharts, UML, network, AWS/Azure/GCP, floorplans, org charts, ER, BPMN, mind maps
- **Stencil libraries** — huge collection of icons + shapes
- **Multiple storage** — local device, Google Drive, OneDrive, Dropbox, GitHub, GitLab, WebDAV (when hosted)
- **Export** — PNG, JPG, SVG, PDF, HTML, XML (.drawio)
- **Offline-capable** web app (PWA in some deployments)
- **Desktop apps** — draw.io Desktop for Windows/macOS/Linux
- **Server rendering** (optional; separate component) — for thumbnails + PDF export at scale
- **Confluence/Jira plugins** (commercial)
- **No real-time collaboration** in self-hosted OSS version (per README)

- Upstream repo (web editor): <https://github.com/jgraph/drawio>
- Docker image repo: <https://github.com/jgraph/docker-drawio>
- Homepage: <https://www.drawio.com>
- App: <https://app.diagrams.net>
- Desktop: <https://get.diagrams.net>
- Releases (WARs): <https://github.com/jgraph/draw.io/releases>

## Architecture in one minute

- **JavaScript frontend** (served as static web app)
- **Java servlet** for some server features (PDF export, etc.)
- **No server storage required** for base use — browser-local saves to files; optional cloud-storage integrations
- **Self-hosted deployment** = serve static webapp; users save to their own storage (local file, Git, WebDAV)
- **Resource**: near-zero server side; CPU on client browser

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single host        | **Docker (`jgraph/drawio`)** — official image                      | **Most popular**                                                                   |
| Any static host    | Fork repo + publish via GitHub Pages                                       | Works: "fully functional editor without integrations"                                                      |
| Kubernetes         | Deploy the Docker image                                                                       | Works                                                                                                   |
| Desktop use        | **draw.io Desktop** (download)                                                                              | Great for offline individual use                                                                                                |
| Confluence/Jira    | **Commercial plugin**                                                                                          | Paid; not self-hosted OSS                                                                                                                    |

## Inputs to collect

| Input                | Example                                       | Phase        | Notes                                                                    |
| -------------------- | --------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `draw.home.lan`                                     | URL          | TLS via reverse proxy                                                            |
| Port                 | `8080` (default)                                          | Network      | Reverse proxy to 443                                                                     |
| Storage integrations | Google Drive / OneDrive / WebDAV / GitHub / GitLab        | Config       | Per-user; no server config needed for local-files-only                                                    |
| Server rendering     | optional separate image                                                   | Export       | For PDF/PNG export at scale                                                                              |

## Install via Docker

```yaml
services:
  drawio:
    image: jgraph/drawio:latest                            # pin specific version in prod
    container_name: drawio
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8443:8443"
    environment:
      PUBLIC_DNS: draw.home.lan
      DRAWIO_BASE_URL: https://draw.home.lan
```

Browse `http://<host>:8080/` → editor loads → start diagramming.

## First boot

1. Open editor → default view
2. Create a test diagram → save locally (browser file API or "save as")
3. Configure storage integrations if needed:
   - Point at your WebDAV (Nextcloud/OpenCloud batch 72) for team sharing
   - GitLab/GitHub for PR-based diagram review (`.drawio` files)
4. Put behind TLS reverse proxy for team use
5. No server-side accounts; users authenticate to their chosen storage backend

## Data & config layout

- **Self-hosted draw.io has no server-side data** by default — users save to THEIR storage
- Docker image is essentially stateless web server
- No database, no uploads volume, no DB backup needed
- **User data lives wherever they save**: Git repo, WebDAV, Nextcloud, browser localStorage, desktop file

## Backup

**Nothing server-side to back up** — the container is stateless. Users are responsible for their own diagrams (same as Office apps). Back up wherever users save (Git repo, Nextcloud, etc.).

## Upgrade

1. Releases: <https://github.com/jgraph/draw.io/releases>. Active.
2. Docker: bump tag → restart. Users' diagrams are in their storage, unaffected by container version.
3. Desktop: built-in auto-updater.

## Gotchas

- **No PRs accepted.** Upstream explicitly: *"We do not accept pull requests. The project is developed entirely by the core team."* File issues for bugs/feature requests; don't expect to contribute code. Unusual for open source but explicit + upfront.
- **Stencil/icon license is MORE restrictive than the code.** Quoted: may NOT be embedded in Atlassian products/marketplace plugins without permission. Why? draw.io sells commercial Confluence/Jira plugins; they protect that revenue. **If you're building a commercial plugin for Atlassian → read the stencil license carefully, contact jgraph for written permission.**
- **End-user output is yours.** Exported diagrams are unrestricted. You can use them anywhere, including in Confluence pages (via the commercial plugin).
- **No real-time collaboration in OSS** (per README). Multi-user editing on a single diagram = conflicts. Works through Git-based workflows (diffable `.drawio` XML) or commercial plugins.
- **Self-hosted = privacy win**: diagrams stay on your infra / your storage. No telemetry concerns vs diagrams.net public instance (which doesn't transmit diagrams to server anyway, but self-host removes any question).
- **Airgapped deployments**: works great. Docker image + users save to local files. No cloud dependency.
- **Browser support**: Chrome 123+, Firefox 120+, Safari 17.5+, Opera 109+, Edge 123+ (per README). Modern browsers only.
- **Server rendering (PDF export)**: optional separate image (`export-server`). For high-volume PDF generation, deploy it.
- **Desktop app vs web**: Desktop is Electron-wrapped web app. Same editor. Desktop is convenient for offline-heavy users.
- **File format**: `.drawio` / `.xml` — human-diffable XML. Works with Git + code review. One of the best-in-class formats for this reason.
- **SVG export**: "for embedding; not for editing in other tools" (README). Don't expect SVG round-trip to Illustrator / Inkscape to preserve everything.
- **Cloud storage integrations**: Google Drive / OneDrive / Dropbox / GitHub / GitLab. Your choice; each has their own ToS + privacy impact.
- **Trademark**: "draw.io" is EU registered trademark #018062448. Don't name your own project "drawio-something" or use the logo without permission.
- **Commercial vs OSS**: drawio team makes money from Confluence/Jira plugins. The OSS web app is solid + not stripped. Respect the business model.
- **Active + sustained**: 20+ year codebase, commercial revenue, stable team. Not bus-factor-1. Confident long-term.
- **License**: **Apache 2.0** (source); **restricted license** (stencils + templates — see README).
- **Alternatives worth knowing:**
  - **Excalidraw** — simpler, whiteboard-y, hand-drawn style; trendy
  - **tldraw** — React-based; dev-friendly embeddable
  - **Mermaid / PlantUML** — text-based diagrams; code-in-markdown
  - **Lucidchart** — commercial SaaS; market leader
  - **Microsoft Visio** — commercial desktop
  - **yEd** — free-but-closed desktop; fantastic layout algorithms
  - **Visual Paradigm** — commercial UML-heavy
  - **Diagrams.net (hosted)** — same editor as self-hosted
  - **Choose draw.io if:** general-purpose diagramming + huge stencil library + self-host + Git-friendly XML format.
  - **Choose Excalidraw if:** whiteboarding + hand-drawn aesthetic.
  - **Choose tldraw if:** embedding in your own app / React-based.
  - **Choose Mermaid if:** markdown-driven docs + diagram-as-code.

## Links

- Repo: <https://github.com/jgraph/drawio>
- Docker repo: <https://github.com/jgraph/docker-drawio>
- Docker Hub: <https://hub.docker.com/r/jgraph/drawio>
- Homepage: <https://www.drawio.com>
- Hosted app: <https://app.diagrams.net>
- Desktop download: <https://get.diagrams.net>
- Releases: <https://github.com/jgraph/draw.io/releases>
- Export server: <https://github.com/jgraph/docker-drawio> (same repo)
- Confluence plugin (commercial): <https://www.drawio.com/atlassian>
- Excalidraw (alt): <https://excalidraw.com>
- tldraw (alt): <https://www.tldraw.com>
- Mermaid (alt text-based): <https://mermaid.js.org>
