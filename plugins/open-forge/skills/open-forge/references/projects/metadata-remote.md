# Metadata Remote (mdrm)

**Web-based audio metadata editor for headless servers — edit tags on MP3, FLAC, OGG, OPUS, M4A, M4B, WMA, WAV files through a browser, with MusicBrainz suggestions, bulk operations, and full undo/redo.**
GitHub: https://github.com/wow-signal-dev/metadata-remote

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux (incl. ARM) | Docker Compose | Multi-arch: x86_64, ARM64, ARMv7 |

---

## Inputs to Collect

### Required
- Path to music library on host

---

## Software-Layer Concerns

### Quick start
```bash
wget https://raw.githubusercontent.com/wow-signal-dev/metadata-remote/main/docker-compose.yml
# Edit docker-compose.yml — change /path/to/your/music to your music path
docker compose up -d
```
Access at http://localhost:8338

### Docker Compose
```yaml
services:
  metadata-remote:
    image: ghcr.io/wow-signal-dev/metadata-remote:latest
    ports:
      - "8338:8338"
    volumes:
      - /path/to/your/music:/music
    restart: unless-stopped
```

### Ports
- `8338` — web UI

### Supported formats
MP3, FLAC, OGG, OPUS, M4A, M4B, WMA, WAV, WavPack

### Key features
- Edit all text metadata fields (standard and extended)
- Create custom fields, delete existing ones
- Bulk operations — apply changes to individual files or entire folders
- Long-form editor for lyrics and long metadata (auto-appears for content > 100 chars)
- Smart metadata suggestions — analyzes filenames, folder patterns, and sibling files
- MusicBrainz integration with confidence scoring
- Handles classical music, compilations, and live recordings
- In-browser audio playback
- File and folder rename directly from UI
- Album art: upload, preview, delete, bulk apply, automatic corruption repair
- Full undo/redo for up to 1000 operations (including bulk changes)
- Keyboard-first: full navigation without a mouse
- Container size: ~81.6 MB

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Music directory must be writable by the container — metadata edits write directly to files
- MusicBrainz suggestions require internet access from the container

---

## References
- GitHub: https://github.com/wow-signal-dev/metadata-remote#readme
