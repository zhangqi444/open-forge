# Beets

The media library management system for obsessive music geeks. Beets catalogs your music collection, auto-corrects metadata from MusicBrainz, organizes files into a clean directory structure, and provides a plugin ecosystem for fetching album art, lyrics, ReplayGain, acoustic fingerprints, and more. Includes `bukuserver` — a web UI for browsing and playing your library.

**Official site:** https://beets.io/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (bukuserver web UI) | `bukuserver/bukuserver` image |
| Any Linux host | pip / pipx (CLI) | Primary use case; no Docker needed for CLI |
| Raspberry Pi / ARM | Docker or pip | ARM builds available |
| NAS (Synology, QNAP) | pip in Python venv | CLI import/management on NAS directly |

---

## Inputs to Collect

### Phase 1 — Planning
- Music library location (source directory for import)
- Target directory structure template (e.g. `~/Music/$albumartist/$album/$track`)
- Whether to use the web UI (bukuserver) or CLI only
- MusicBrainz lookup: automatic (default) or manual confirmation per import

### Phase 2 — Deployment
- Beets config file path (`~/.config/beets/config.yaml`)
- Library database path (default `~/.config/beets/library.db`)
- Plugins to enable (fetchart, lyrics, lastgenre, etc.)

---

## Software-Layer Concerns

### Docker Compose (Bukuserver Web UI)

```yaml
services:
  bukuserver:
    image: bukuserver/bukuserver
    restart: unless-stopped
    environment:
      - BUKUSERVER_PER_PAGE=100
      - BUKUSERVER_OPEN_IN_NEW_TAB=true
      # - BUKUSERVER_SECRET_KEY=change-me-random-string
    ports:
      - "5001:5001"
    volumes:
      - ./data:/root/.local/share/buku

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./data/nginx:/etc/nginx/conf.d
```

> **Note:** `bukuserver` is the web UI companion for the `buku` bookmark manager, which beets uses for its web interface. For beets' own web plugin, see the `web` plugin below.

### Beets Web Plugin (built-in)

```yaml
# ~/.config/beets/config.yaml
plugins: web
web:
  host: 0.0.0.0
  port: 8337
  cors: '*'
```

Then run: `beet web` — browse your library at `http://localhost:8337/`

### pip / pipx Install

```bash
# Install beets with common plugins
pip3 install beets

# Or with server extras
pip3 install "beets[web]"

# Or via pipx (isolated)
pipx install beets
```

### Beets Configuration (`~/.config/beets/config.yaml`)

```yaml
directory: ~/Music
library: ~/.config/beets/library.db

import:
  move: yes         # move files (vs copy)
  write: yes        # write tags to files

plugins: fetchart lyrics lastgenre web chroma

fetchart:
  auto: yes

lastgenre:
  auto: yes

web:
  host: 0.0.0.0
  port: 8337
```

### Basic Usage

```bash
# Import music (interactive)
beet import ~/Downloads/music/

# Import non-interactively (auto-tag)
beet import -A ~/Downloads/music/

# Search your library
beet list artist:radiohead

# List with format
beet list -f '$artist - $title' year:2024
```

### Environment Variables (Docker bukuserver)
| Variable | Purpose |
|----------|---------|
| `BUKUSERVER_PER_PAGE` | Items per page in web UI |
| `BUKUSERVER_OPEN_IN_NEW_TAB` | Open links in new tab |
| `BUKUSERVER_SECRET_KEY` | Session secret key |

---

## Upgrade Procedure

**pip:** `pip3 install --upgrade beets`

**pipx:** `pipx upgrade beets`

**Docker:** `docker compose pull && docker compose up -d`

After upgrading, run `beet migrate` if prompted to update the library database schema.

---

## Gotchas

- **Import is destructive if `move: yes`** — beets moves files to the target directory; ensure source is backed up or use `copy: yes` instead.
- **MusicBrainz lookups require internet** — import will be slow or fail without connectivity; use `-A` flag for offline import (no lookup).
- **The `web` plugin is read-only** — it's for browsing/searching, not editing. Use the CLI for tag corrections.
- **Chroma plugin requires `fpcalc`** (from Chromaprint) installed separately for acoustic fingerprinting.
- **File permissions:** Beets needs write access to both the source (for moves) and destination directories.
- **Library DB is SQLite** — back it up regularly; it's the index of your entire collection.

---

## References
- GitHub: https://github.com/beetbox/beets
- Docs: https://beets.readthedocs.io/
- Plugin list: https://beets.readthedocs.io/en/stable/plugins/
- Docker image: https://hub.docker.com/r/bukuserver/bukuserver
