---
name: Inventaire
description: Libre/open web app to inventory and share books. Powered by Wikidata and ISBNs, with federation support. CouchDB + Elasticsearch backend. AGPL-3.0 licensed.
website: https://inventaire.io/welcome
source: https://codeberg.org/inventaire/inventaire
license: AGPL-3.0
stars: 458
tags:
  - books
  - library
  - inventory
  - wikidata
  - federated
platforms:
  - JavaScript
  - Docker
---

# Inventaire

Inventaire is a libre/open web application for building and sharing book inventories. It maps books using Wikidata and ISBNs, allowing you to catalog your personal library, share books with others, and discover what your community has. Supports federation between Inventaire instances. The flagship instance is https://inventaire.io.

Source: https://codeberg.org/inventaire/inventaire
Flagship instance: https://inventaire.io
Wiki: https://wiki.inventaire.io
Docs (self-hosting): https://git.inventaire.io/inventaire/src/branch/main/docs
Client repo: https://codeberg.org/inventaire/inventaire-client
Docker repo: https://codeberg.org/inventaire/docker

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VM / VPS (4GB+ RAM) | Docker Compose | Recommended for self-hosting; see docker repo |
| Linux development machine | Node.js 18+ + CouchDB + Elasticsearch | For development |

## Inputs to Collect

**Phase: Planning**
- Domain/hostname for your instance
- CouchDB credentials (admin user and password)
- Elasticsearch version (7.10+ required)
- SMTP credentials (for email notifications)
- Whether to federate with other Inventaire instances

## Software-Layer Concerns

**Docker Compose (recommended for self-hosting):**

```bash
# Use the official Docker repo
git clone https://codeberg.org/inventaire/docker inventaire-docker
cd inventaire-docker
# Follow the README in that repo for configuration
docker compose up -d
```

The Docker repo is maintained separately from the application code. Check:
https://codeberg.org/inventaire/docker for the current compose file and configuration instructions.

**Development stack dependencies:**

- Node.js >= 18 (LTS recommended)
- CouchDB >= 3.1 (port 5984)
- Elasticsearch >= 7.10 (port 9200)
- inotify-tools (for watch scripts on Linux)

**Development install:**

```bash
git clone https://codeberg.org/inventaire/inventaire
cd inventaire
npm install

# Configure (copy and edit)
cp config/default.js config/local.js
# Edit config/local.js: set CouchDB and Elasticsearch URIs, SMTP, etc.

npm start
```

**Key configuration areas (config/local.js):**
- CouchDB connection and credentials
- Elasticsearch URL
- SMTP server for emails
- Instance public URL
- Federation settings

**Two repos — server + client:**

The server repo (this recipe) handles the API. The client (SPA) is a separate repository:
https://codeberg.org/inventaire/inventaire-client

In Docker deployments both are bundled together.

## Upgrade Procedure

1. Pull updated Docker images: `docker compose pull && docker compose up -d`
2. For source installs: `git pull && npm install && npm start`
3. Check release notes: https://codeberg.org/inventaire/inventaire/releases

## Gotchas

- **Heavy stack**: Requires CouchDB + Elasticsearch + Node.js — minimum 4GB RAM recommended; Elasticsearch alone needs ~2GB
- **Two repositories**: Server and client are separate repos; the Docker deployment bundles both, but development requires cloning both
- **CouchDB not MongoDB**: Inventaire uses CouchDB (document store), not MongoDB — ensure you're using the right database
- **Elasticsearch 7.10+**: Required; Elasticsearch 8.x compatibility should be checked against current docs
- **Federation**: Inventaire supports ActivityPub-style federation between instances; configure the public URL correctly for this to work
- **Wikidata integration**: Book metadata is pulled from Wikidata at runtime — requires internet access from the server
- **AGPL**: If you modify and deploy Inventaire, AGPL requires you to share your modifications

## Links

- Source: https://codeberg.org/inventaire/inventaire
- Self-hosting docs: https://git.inventaire.io/inventaire/src/branch/main/docs
- Docker repo: https://codeberg.org/inventaire/docker
- Client repo: https://codeberg.org/inventaire/inventaire-client
- Wiki: https://wiki.inventaire.io
- Flagship instance: https://inventaire.io
