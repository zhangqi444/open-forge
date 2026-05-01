# selfh.st/icons

**Community icon collection for self-hosted software — SVG, PNG, WebP, AVIF, and ICO formats, served via jsDelivr CDN or self-hostable.**
Official site: https://selfh.st/icons
GitHub: https://github.com/selfhst/icons

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | CDN (jsDelivr) | Zero-setup, reference icons directly from CDN |
| Any Linux | Self-hosted | Clone repo and serve statically |

---

## Inputs to Collect

### Self-hosted deployment
- Web server (nginx, caddy, etc.) to serve static files
- See the repository wiki for self-hosting instructions

---

## Software-Layer Concerns

### CDN usage (no setup required)
Icons are served directly from the jsDelivr CDN:
```
https://cdn.jsdelivr.net/gh/selfhst/icons@main/<format>/<slug>.<ext>
```
Example: https://cdn.jsdelivr.net/gh/selfhst/icons@main/svg/home-assistant.svg

### Self-hosting
Follow the wiki: https://github.com/selfhst/icons/wiki
Clone the repo and serve the build/ directory with any static web server.

### Formats available
- SVG — most icons (best quality, scalable)
- PNG — all icons
- WebP — all icons
- AVIF — all icons
- ICO — all icons (16x16, 32x32, 48x48, 64x64, 128x128)

### Custom colors
Custom-colored SVG variants are available to paid selfh.st members or when self-hosting your own deployment.

---

## Gotchas

- This is a static asset collection, not a running service — no Docker container or runtime needed for CDN usage
- Contributions and PRs are not accepted from non-organizational members; submit requests via GitHub Discussions
- Default SVG icons come in standard, dark, and light color variants
- Icon count is dynamic — check https://selfh.st/icons for current total

---

## References
- Browse icons: https://selfh.st/icons
- Self-hosting wiki: https://github.com/selfhst/icons/wiki
- GitHub: https://github.com/selfhst/icons#readme
