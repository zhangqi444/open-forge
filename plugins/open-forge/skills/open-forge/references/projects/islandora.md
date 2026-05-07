# Islandora

**Drupal-based digital repository system** — a Drupal module (and broader ecosystem) for building institutional digital repositories backed by Fedora Commons. Used by libraries, archives, and cultural institutions for managing digital collections with full IIIF support.

**Official site:** https://www.islandora.ca  
**Source:** https://github.com/Islandora/islandora  
**Sandbox / demo:** https://sandbox.islandora.ca/  
**License:** GPL-3.0

> ⚠️ **Framework, not a standalone app.** Islandora is a Drupal module that must be installed within a Drupal site. The full stack includes Fedora, Solr/Triplestore, and microservices (Crayfish).

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose (ISLE) | Recommended; ISLE provides the full stack |
| Linux | Drupal + Composer (native) | Manual stack setup |

---

## System Requirements

- Drupal (latest stable)
- Fedora Commons (object storage)
- Solr (search)
- Blazegraph or other triplestore
- ActiveMQ (message queue)
- Crayfish microservices (image/video/text processing)
- PHP ≥ 7.4

---

## Inputs to Collect

| Input | Description |
|-------|-------------|
| Drupal site URL | Public URL of the Drupal/Islandora site |
| Fedora URL | Fedora Commons repository endpoint |
| Solr URL | Solr core URL |
| JWT secret | For Drupal ↔ microservices authentication |
| Admin credentials | Drupal admin user |

---

## Software-layer Concerns

### ISLE (Islandora Enterprise) — recommended
The **ISLE** (Islandora Enterprise) project provides a Docker Compose stack with all required components:
```bash
git clone https://github.com/Islandora-Devops/isle-dc
cd isle-dc
make demo  # Spins up a full demo environment
```
See https://islandora.github.io/documentation/installation/docker-local/ for full ISLE setup.

### Composer install (within existing Drupal)
```bash
composer require islandora/islandora
drush en islandora islandora_core_feature
drush cr
```

### Required Drupal modules
- `context`, `search_api`, `jsonld`, `jwt`, `filehash`, `prepopulate`, `eva`, `features`, `migrate_plus`, `migrate_source_csv`, `flysystem`

### Crayfish microservices
Islandora uses the [Crayfish](https://github.com/Islandora/Crayfish) microservices suite for:
- **Houdini** — ImageMagick image processing
- **Homarus** — ffmpeg audio/video processing
- **Hypercube** — Tesseract OCR and pdftotext

### Key submodules
| Module | Purpose |
|--------|---------|
| `islandora_core_feature` | Required configuration |
| `islandora_image` | Image processing via Houdini |
| `islandora_audio` / `islandora_video` | A/V processing via Homarus |
| `islandora_text_extraction` | OCR via Hypercube |
| `islandora_iiif` | IIIF manifest generation |
| `islandora_breadcrumbs` | Collection-following breadcrumbs |

---

## Upgrade Procedure

```bash
composer update islandora/islandora
drush updatedb
drush cr
```
Follow official [upgrade guides](https://islandora.github.io/documentation/technical-documentation/versioning/) for major version changes.

---

## Gotchas

- **Not a standalone app.** Requires a full Drupal + Fedora + Solr + ActiveMQ + Crayfish stack. Plan for significant infrastructure complexity.
- **Use ISLE for local/production deploys.** Manually assembling the stack is error-prone; ISLE Docker Compose is the supported path.
- **JWT configuration** must be consistent across Drupal and all Crayfish microservices for authentication to work.
- **Fedora 5 (Fedora API-X) required.** Islandora 2.x is not compatible with Fedora 3.x/4.x.
- **Drupal 11 compatibility** is actively being worked on (check the `drupal/jwt` `^3` constraint note in README).

---

## References

- Islandora documentation: https://islandora.github.io/documentation/
- ISLE Docker setup: https://islandora.github.io/documentation/installation/docker-local/
- Upstream README: https://github.com/Islandora/islandora#readme
- Sandbox: https://sandbox.islandora.ca/
