# Tiny Tiny RSS (tt-rss)

**Free, open source, self-hosted web-based RSS/Atom feed reader and aggregator. Community fork maintained after the original project retired in November 2025.**
GitHub: https://github.com/tt-rss/tt-rss
Docs: https://tt-rss.org/docs/Installation-Guide.html
Docker Hub: https://hub.docker.com/r/supahgreg/tt-rss

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended — images on Docker Hub and GHCR |
| Any Linux | Bare metal (PHP) | PHP version must match current Debian stable |

---

## Inputs to Collect

### Required
- Database credentials (PostgreSQL recommended)
- Application URL (used for feed fetching and self-links)

---

## Software-Layer Concerns

### Docker images (drop-in replacements for original)
- Docker Hub: `supahgreg/tt-rss` and `supahgreg/tt-rss-web-nginx`
- GHCR: `ghcr.io/tt-rss/tt-rss` and `ghcr.io/tt-rss/tt-rss-web-nginx`

Full Docker Compose setup in the official installation guide:
https://tt-rss.org/docs/Installation-Guide.html

### Typical compose structure
- `tt-rss` app container (PHP backend + feed updater)
- `tt-rss-web-nginx` web container (nginx frontend)
- PostgreSQL database container

### Ports
- `80` — web UI via nginx container

### PHP version
Tracks PHP version in Debian's current `stable` release (per original project policy).

---

## Upgrade Procedure

Using `latest` or `sha-*` tags (rolling releases):
1. docker compose pull
2. docker compose up -d

Using the `latest` tag is strongly encouraged — it tracks stable `main` branch.

---

## Gotchas

- The original tt-rss project (tt-rss.org) was **retired 2025-11-01**; this GitHub repo is the community continuation fork
- Docker images are published by `supahgreg` (the fork maintainer), not the original author
- GitHub may incorrectly attribute some pre-2025 commits to `ivanivanov884` due to email mismatch — this is a known display artifact
- Plugins previously at `gitlab.tt-rss.org` have been mirrored to `github.com/tt-rss/tt-rss-plugin-*`

---

## References
- Installation guide: https://tt-rss.org/docs/Installation-Guide.html
- GitHub: https://github.com/tt-rss/tt-rss#readme
