---
name: Immich Public Proxy (IPP)
description: "Share Immich photos + albums safely without exposing Immich instance. Proxy front-end for Immich share links. Live demo. alangrainger/immich-public-proxy. Docker + Kubernetes."
---

# Immich Public Proxy (IPP)

Immich Public Proxy is **"public-facing minimal proxy for Immich share-links"** — lets you share Immich photos + albums without exposing your Immich instance to the internet. Setup <1 minute; sharing managed within Immich. Built-in **lightGallery** viewer. Custom error pages. Multi-domain support.

Built + maintained by **alangrainger**. Docker Hub + GitHub releases. Kubernetes docs. **Live demo** at immich-demo.note.sx.

Use cases: (a) **share Immich albums publicly without exposing Immich** (b) **photography portfolio via Immich** (c) **family-album sharing** (d) **embedding galleries** (e) **reduce attack-surface of Immich** (f) **multi-domain photo gallery** (g) **companion to self-hosted Immich** (h) **transitional: expose-read-only-subset**.

Features (per README):

- **Proxy for Immich share links**
- **No full-Immich exposure**
- **Manages entirely from Immich UI**
- **lightGallery** viewer
- **Custom error pages**
- **Multi-domain support**
- **Docker + Kubernetes**
- **Live demo**

- Upstream repo: <https://github.com/alangrainger/immich-public-proxy>
- Docker Hub: <https://hub.docker.com/r/alangrainger/immich-public-proxy>
- Live demo: <https://immich-demo.note.sx/share/gJfs8l4LcJJrBUpjhMnDoKXFt1Tm5vKXPbXl8BgwPtLtEBCOOObqbQdV5i0oun5hZjQ>

## Architecture in one minute

- Node.js proxy
- Calls Immich API on backend
- Stateless (no DB)
- **Resource**: very low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream (+Podman)                                                                                                     | **Primary**                                                                                   |
| **Kubernetes**     | Per docs/kubernetes.md                                                                                                 | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Immich instance URL  | `https://immich.internal/`                                  | Config       | Internal-LAN URL                                                                                    |
| Immich API key       | Admin                                                       | Secret       | **Read-scope preferred**                                                                                    |
| Public domain(s)     | `photos.example.com`                                        | URL          | TLS **MANDATORY**                                                                                    |

## Install via Docker

Per README:
```yaml
services:
  immich-public-proxy:
    image: alangrainger/immich-public-proxy:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      - IMMICH_URL=https://immich.internal
      - IMMICH_API_KEY=...
    restart: unless-stopped
```

## First boot

1. Generate Immich API key (admin; ideally read-only-scope)
2. Deploy IPP pointing at internal Immich
3. Front with reverse proxy + TLS
4. Create share-link in Immich → test via public domain
5. Customize error pages (optional)
6. (Optional) multi-domain config

## Data & config layout

- Config only — no DB

## Backup

Docker-compose + env vars = infra-as-code. Config backup = git.

## Upgrade

1. Releases: <https://github.com/alangrainger/immich-public-proxy/releases>
2. Docker pull + restart

## Gotchas

- **185th HUB-OF-CREDENTIALS Tier 3 — IMMICH-API-KEY-PROXY** (tier downgraded because it's a purpose-built proxy, but still holds Immich API key):
  - Holds: Immich API key (that backend key reaches full Immich)
  - **API-key scope matters** — read-only strongly recommended
  - **185th tool in hub-of-credentials family — Tier 3**
- **PURPOSE-BUILT-PROXY-PATTERN**:
  - Dedicated tool for "expose-read-only-subset of self-hosted app"
  - **Recipe convention: "purpose-built-public-proxy-reduce-attack-surface positive-signal"**
  - **NEW positive-signal convention** (IPP 1st formally; important architectural pattern)
  - **Purpose-built-public-proxy-tool: 1 tool** 🎯 **NEW FAMILY** (IPP — distinct from general reverse-proxies like Traefik)
- **ATTACK-SURFACE-REDUCTION-ARCHITECTURE**:
  - IPP = textbook attack-surface-reduction
  - Immich-admin (HIGH sensitivity) stays LAN-internal
  - Only read-proxy is public
  - **Recipe convention: "attack-surface-reduction-via-read-only-proxy positive-signal"**
  - **NEW positive-signal convention** (IPP 1st formally)
- **UPSTREAM-API-KEY-FULL-POWER**:
  - Even with read-only-scope, key has full-user-read
  - **Recipe convention: "proxy-API-key-scope-discipline"**
  - **NEW recipe convention** (IPP 1st formally)
- **LIVE-DEMO-WITH-USER-IDENTIFIER**:
  - Public demo link at immich-demo.note.sx
  - **Live-demo-with-public-credentials: 4 tools** 🎯 **4-TOOL MILESTONE** (+IPP)
- **KUBERNETES-NATIVE-DOCS**:
  - k8s install docs present
  - **Kubernetes-native-install-docs: 4 tools** 🎯 **4-TOOL MILESTONE** (+IPP)
- **COMPANION-TO-POPULAR-TOOL**:
  - Specifically designed for Immich
  - **Recipe convention: "companion-tool-for-popular-selfhosted-app neutral-signal"**
  - **NEW neutral-signal convention** (IPP 1st formally — distinct from "alternative-to")
  - **Companion-tool-to-popular-selfhosted: 1 tool** 🎯 **NEW FAMILY** (IPP)
- **INSTITUTIONAL-STEWARDSHIP**: alangrainger sole-dev + Docker + k8s + live-demo + releases + stateless-clean-arch. **171st tool — sole-dev-companion-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + docs + Docker + k8s. **177th tool in transparent-maintenance family.**
- **IMMICH-ECOSYSTEM-CATEGORY:**
  - **IPP** — public-proxy for share-links
  - **Immich CLI** — upload tool
  - **Reverse-proxy Immich directly** — full exposure
  - **Share-link native** — part of Immich
- **ALTERNATIVES WORTH KNOWING:**
  - **Traefik/Caddy with auth** — general-purpose proxy for Immich
  - **Choose IPP if:** you want purpose-built + minimal-surface + easy-setup.
- **PROJECT HEALTH**: active + live-demo + Docker + k8s + sole-dev-sustained. Strong.

## Links

- Repo: <https://github.com/alangrainger/immich-public-proxy>
- Immich: <https://github.com/immich-app/immich>
- lightGallery: <https://github.com/sachinchoolur/lightGallery>
