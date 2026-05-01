# Mafl

**Intuitive self-hosted homepage — organize your services with YAML config, real-time interactive cards, grouping, tags, themes, multi-language, and PWA support.**
Official site: https://mafl.hywax.space
GitHub: https://github.com/hywax/mafl

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |
| Any Linux | Node.js (bare metal) | yarn/npm/pnpm |
| Proxmox | LXC | Community script available |

---

## Inputs to Collect

### Required
- Services to display (configured via `config.yaml`)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  mafl:
    image: hywax/mafl
    restart: unless-stopped
    ports:
      - '3000:3000'
    volumes:
      - ./mafl/:/app/data/
```

Both `hywax/mafl` (Docker Hub) and `ghcr.io/hywax/mafl` (GHCR) are published.

### Ports
- `3000` — web UI

### Configuration
Services are defined in `config.yaml` (mounted at `/app/data/`). The config supports:
- Service groups and tags
- Custom themes
- Real-time status cards with extra information
- Icons (custom icon packs supported)

### Key features
- Privacy: all requests to third-party services go through the backend (no client-side leaks)
- Real-time interactive cards
- Multi-language support
- Light/dark themes, fully customizable
- Service grouping and tagging
- PWA — installable as a smartphone/desktop app

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Config file (`config.yaml`) is the only required setup — no database needed
- All third-party service checks are backend-proxied for privacy

---

## References
- Documentation: https://mafl.hywax.space
- GitHub: https://github.com/hywax/mafl#readme
