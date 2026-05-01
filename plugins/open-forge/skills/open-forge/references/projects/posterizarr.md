# Posterizarr

**PowerShell script with a web UI that auto-generates textless poster artwork for Plex, Jellyfin, and Emby libraries using Fanart.tv, TMDB, TVDB, and IMDb.**
GitHub: https://github.com/fscorrupt/posterizarr
Documentation: https://fscorrupt.github.io/posterizarr/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / Windows / macOS | Docker | Web UI included |
| Windows / Linux | Bare PowerShell | Requires PowerShell 7+ |
| Unraid | Community App | Available via Unraid store |
| ARM (Raspberry Pi etc.) | Docker (ARM image) | ARM-compatible image available |

---

## Inputs to Collect

### All phases
- Media server type — Plex, Jellyfin, or Emby
- Media server URL + API token
- API keys — Fanart.tv, TMDB, TVDB (optional but recommended for richer artwork)
- `CONFIG_DIR` — host path for config and assets

---

## Software-Layer Concerns

### Config
- Settings managed via the Web UI or config file
- Kometa-compatible asset folder structure for Plex metadata managers

### Integrations
- Tautulli webhook — trigger runs on new media
- Sonarr / Radarr — trigger runs on import
- Kometa — write assets directly to Kometa's expected folder layout

### Ports
- Web UI accessible via Docker port mapping (see full docs for default port)

### Install
Full installation guide: https://fscorrupt.github.io/posterizarr/installation

---

## Upgrade Procedure

1. docker compose pull (or docker pull)
2. docker compose up -d
3. Check Web UI for any config migration notices

---

## Gotchas

- Posterizarr focuses on textless artwork — it won't add title text overlays by default (that's configurable)
- All install steps and config details live in the documentation site, not the README
- Custom overlays and text can be applied on top of fetched artwork
- Triggers from Tautulli/Sonarr/Radarr require webhook configuration on the source app

---

## References
- Full documentation: https://fscorrupt.github.io/posterizarr/
- Installation guide: https://fscorrupt.github.io/posterizarr/installation
- GitHub: https://github.com/fscorrupt/posterizarr#readme
