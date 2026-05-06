---
name: rstudio-server
description: RStudio Server recipe for open-forge. Web browser-based IDE for R — run RStudio in a browser, share with multiple users, access remote data. Docker install via rocker/rstudio. Upstream: https://github.com/rstudio/rstudio
---

# RStudio Server

Web browser-based IDE for R. Run a full RStudio development environment accessible via browser — syntax highlighting, code completion, plots, workspace, help, history, and Shiny support. Multi-user server version ideal for teams and data science platforms.

4,989 stars · AGPL-3.0

Upstream: https://github.com/rstudio/rstudio
Website: https://posit.co/products/open-source/rstudio-server/
Docs: https://docs.posit.co/ide/server-pro/ (open-source docs at docs.posit.co/ide/user/)
Docker images: https://hub.docker.com/r/rocker/rstudio (community) or https://hub.docker.com/u/rstudio (official)
Rocker project: https://rocker-project.org

## What it is

RStudio Server provides a full R development environment in a browser:

- **Full IDE** — Console, source editor, plots, workspace, help, history, file browser
- **Syntax highlighting & completion** — R, Python, SQL, Markdown, C++, and more
- **Code execution** — Run lines, selections, or entire files directly
- **Sweave & R Markdown** — Author and render documents with embedded R
- **Shiny** — Run and preview Shiny apps directly in the IDE
- **Multi-user** — Multiple users each get isolated R sessions
- **Package management** — Install R packages via GUI or console
- **Git integration** — Built-in git panel
- **Terminal** — Access system shell from within the IDE
- **Project support** — RStudio projects with .Rproj files

Recommended Docker path: use the **rocker/rstudio** image maintained by the Rocker project (rocker-project.org) — it bundles R + RStudio Server with reproducible R version pinning.

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | rocker/rstudio | Recommended; version-pinned R + RStudio |
| Docker | rstudio/rstudio-server | Official Posit image |
| Bare metal | Ubuntu/Debian | Install via posit.co .deb package |
| Kubernetes | rocker + K8s | Expose via Ingress |

## Inputs to collect

### Phase 1 — Pre-install
- R version required (e.g. 4.4.3 — use rocker/rstudio:4.4.3 for reproducibility)
- Number of concurrent users expected
- Data paths to mount into container
- Password for default rstudio user

### Phase 2 — Runtime config
- USER — default user (typically rstudio)
- PASSWORD — password for rstudio user
- ROOT=TRUE — if users need sudo inside container
- DISABLE_AUTH=true — disable auth (LAN/trusted networks only)

## Software-layer concerns

### Ports
- 8787 — RStudio Server web interface

### Config paths (inside container)
- /home/rstudio/ — default user home directory (mount as volume for persistence)
- /etc/rstudio/rserver.conf — server configuration
- /etc/rstudio/rsession.conf — session configuration
- /usr/local/lib/R/ — R library (consider mounting for package persistence)

### User management
RStudio Server uses PAM for authentication. In Docker with rocker/rstudio:
- Default user: rstudio (UID 1000)
- Password set via PASSWORD env var
- Add users: useradd -m -p <hash> username (or use adduser)

## Docker Compose install

  version: '3'
  services:
    rstudio:
      image: rocker/rstudio:4.4.3
      container_name: rstudio
      restart: unless-stopped
      ports:
        - "8787:8787"
      environment:
        - PASSWORD=yourpassword
        - ROOT=TRUE
      volumes:
        - ./home:/home/rstudio
        - ./packages:/usr/local/lib/R/site-library

Access at http://<host>:8787
Login: rstudio / <PASSWORD>

### Version pinning
Use a specific tag (e.g. rocker/rstudio:4.4.3) for reproducible environments.
Latest R: rocker/rstudio:latest

### Multi-user via adduser (run in container)
  docker exec -it rstudio adduser --disabled-password --gecos "" alice
  docker exec -it rstudio sh -c "echo 'alice:password123' | chpasswd"

### geospatial / tidyverse extended images
  rocker/tidyverse:4.4.3  — adds tidyverse packages
  rocker/verse:4.4.3      — adds TeX + publishing tools
  rocker/geospatial:4.4.3 — adds spatial packages

## Upgrade procedure

1. Update image tag in docker-compose.yml (e.g. rocker/rstudio:4.4.3 -> 4.5.0)
2. Note: changing R version means package recompilation; backup /home/rstudio and package library
3. docker compose pull && docker compose up -d --force-recreate rstudio
4. Reinstall R packages if version changed: install.packages(c(...)) in console
5. For bare metal: download new .deb from https://posit.co/download/rstudio-server/ and dpkg -i

## Gotchas

- Password required — do not use DISABLE_AUTH=true on public-facing deployments; always set a strong PASSWORD
- Package persistence — by default packages install inside the container and are lost on rebuild; mount /usr/local/lib/R/site-library to a volume
- Home directory persistence — mount /home/rstudio to keep user files across container restarts
- R version vs package compatibility — switching R versions may break installed packages; use version-pinned images for reproducibility
- CRAN mirror — rocker images use Posit Public Package Manager (RSPM) for faster binary package installs on amd64
- ARM64 support — rocker/rstudio has experimental arm64 support from R 4.1+; not all packages may have arm64 binaries
- AGPL-3.0 — open-source server edition; commercial RStudio Server Pro (now Posit Workbench) has additional enterprise features
- Memory — R loads data into RAM; ensure the host has enough memory for your data science workloads
- Shiny Server — for serving Shiny apps to users, use rocker/shiny instead (separate product)

## Links

- Upstream README: https://github.com/rstudio/rstudio/blob/main/README.md
- Rocker project: https://rocker-project.org
- rocker/rstudio Docker Hub: https://hub.docker.com/r/rocker/rstudio
- rocker-versioned2: https://github.com/rocker-org/rocker-versioned2
- RStudio Server admin guide: https://docs.posit.co/ide/server-pro/
- Download .deb: https://posit.co/download/rstudio-server/
