# Note Mark

**Lightweight, fast self-hosted Markdown notes app — WASM-powered rendering, notebook sharing, OIDC SSO, flat-file storage (no database), dark/light theme, and asset uploads.**
Docs: https://notemark.docs.enchantedcode.co.uk
GitHub: https://github.com/enchant97/note-mark

> ⚠️ Working on V1 — V0.19 is maintenance mode. V1 will be a significant update.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Pre-built image available |

---

## Inputs to Collect

### Required
- Storage path for notes (flat-file — no database needed)

### Optional
- OIDC credentials — for Single Sign-On

---

## Software-Layer Concerns

### Docker run
```bash
docker run -d \
  -p 8000:8000 \
  -v /path/to/data:/data \
  ghcr.io/enchant97/note-mark:latest
```

### Docker Compose
```yaml
services:
  note-mark:
    image: ghcr.io/enchant97/note-mark:latest
    ports:
      - "8000:8000"
    volumes:
      - ./data:/data
    restart: unless-stopped
```

### Ports
- `8000` — web UI

### Storage
Notes are stored as flat files — no database required. Just back up the `/data` volume.

### Key features
- GitHub Flavored Markdown rendering (WASM-powered)
- HTML sanitization (XSS protection)
- Notebook sharing
- OIDC support for SSO
- Asset uploads (attach files to notes)
- Dark and light themes
- Keyboard shortcuts
- Mobile-friendly

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

Check changelog for V1 migration steps when V1 is released.

---

## Gotchas

- Project is in maintenance mode (V0.x) while V1 is developed — avoid building on it until V1 lands
- Flat-file storage means no SQL migration headaches — just back up the data directory
- Full install docs: https://notemark.docs.enchantedcode.co.uk/docs/setup/install/

---

## References
- Documentation: https://notemark.docs.enchantedcode.co.uk
- GitHub: https://github.com/enchant97/note-mark#readme
