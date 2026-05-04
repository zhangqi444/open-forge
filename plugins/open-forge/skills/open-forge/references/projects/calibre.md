# Calibre

Comprehensive e-book manager and library server. Calibre can view, convert, edit, and catalog e-books in all major formats (EPUB, MOBI, PDF, AZW3, etc.). It includes a built-in **Content Server** that allows you to read, download, and browse your library from any browser or e-reader over the network. Upstream: <https://github.com/kovidgoyal/calibre>. Docs: <https://manual.calibre-ebook.com>.

> Note: The core Calibre app is a desktop GUI application. Self-hosting refers to running the **Calibre Content Server** (headless or via the linuxserver.io Docker image which includes a full GUI via VNC/web browser). For a lighter web-only frontend, see `calibre-web.md` or `calibre-web-automated.md`.

The Content Server listens on port `8080` by default. The linuxserver.io Docker image exposes ports `8080` (Content Server) and `8081` (web UI for the Calibre desktop app via KasmVNC).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| linuxserver/calibre Docker | <https://hub.docker.com/r/linuxserver/calibre> | Community (LSIO) | Headless server with full Calibre GUI via browser (KasmVNC). Recommended for NAS/homelab. |
| linuxserver/calibre-web Docker | <https://hub.docker.com/r/linuxserver/calibre-web> | Community (LSIO) | Lightweight read-only web UI over an existing Calibre library. See `calibre-web.md`. |
| Binary installer (Linux/macOS/Windows) | <https://calibre-ebook.com/download> | ✅ | Desktop install. Run `calibre-server` for headless content server. |
| Flatpak / snap / package managers | <https://calibre-ebook.com/download_linux> | ✅ | Desktop Linux. Not recommended for headless server use. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| storage | "Path to your Calibre library directory?" | Free-text (e.g. `/data/calibre-library`) | All |
| auth | "Enable content server username/password?" | Yes/No | All |
| port | "Port for Content Server?" | Number (default 8080) | All |
| gui | "Need full Calibre GUI via browser (for editing metadata, conversions)?" | Yes/No | Docker LSIO |

## Software-layer concerns

### Key environment variables (linuxserver/calibre)

| Variable | Purpose | Notes |
|---|---|---|
| `PUID` / `PGID` | File ownership (user/group ID) | Match your host user to avoid permission issues |
| `TZ` | Timezone | e.g. `America/New_York` |
| `PASSWORD` | Password for the web GUI (KasmVNC) | Optional but recommended |
| `CLI_ARGS` | Additional args to pass to `calibre-server` | e.g. `--username=admin --password=secret` |

### Docker Compose (linuxserver/calibre)

```yaml
services:
  calibre:
    image: lscr.io/linuxserver/calibre:latest
    container_name: calibre
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/New_York
      # PASSWORD: "guipassword"  # Optional: password for KasmVNC web UI
    volumes:
      - ./config:/config          # Calibre config and preferences
      - /data/calibre-library:/library  # Your book library
    ports:
      - "8080:8080"   # Content Server (browse/download books)
      - "8081:8081"   # Calibre desktop GUI via browser (KasmVNC)
    restart: unless-stopped
```

Access:
- Content Server (browse/download): `http://localhost:8080`
- Full Calibre GUI: `http://localhost:8081` (for adding books, converting, editing metadata)

### Running headless content server only (no GUI)

If you don't need the GUI and just want to serve an existing library:

```bash
calibre-server /path/to/library --port 8080 --with-library /path/to/library
```

Or using the lightweight `calibre-web` Docker image (see `calibre-web.md`).

### Data directories

| Path | Contents |
|---|---|
| `/config` (Docker) | Calibre preferences, settings, plugins |
| `/library` (Docker) | Calibre library: books + `metadata.db` |
| `metadata.db` | SQLite database with all book metadata (inside library dir) |

### Content Server authentication

Enable via Calibre GUI: Preferences → Sharing → Sharing over the net → Require username and password. Or pass `--username` and `--password` as CLI args.

## Upgrade procedure

For linuxserver/calibre Docker:
1. `docker compose pull`
2. `docker compose up -d`
3. The container auto-updates to the latest Calibre release.

For binary installs:
- Calibre has a built-in updater: Help → Check for Updates.
- Or re-run the installer script from <https://calibre-ebook.com/download_linux>.

## Gotchas

- **`metadata.db` is the single point of truth.** Back it up. All metadata lives here. Losing it means losing all your custom metadata, covers, and book organization (the book files themselves are unaffected).
- **The linuxserver image includes the full GUI**, which is heavier than needed if you only want to serve books. For read-only serving, `calibre-web` is lighter.
- **Format conversions are CPU-intensive.** Running conversions via the GUI on a low-power NAS may be slow. Consider doing conversions on a desktop.
- **Content Server vs calibre-web.** The built-in Content Server is functional but minimal. calibre-web provides a more polished reading experience with OPDS support and user management.
- **Library path must be consistent.** If you move the library directory, update the path in Calibre preferences; otherwise it won't find your books.

## Links

- Upstream: <https://github.com/kovidgoyal/calibre>
- Calibre website: <https://calibre-ebook.com>
- User manual: <https://manual.calibre-ebook.com>
- Content Server docs: <https://manual.calibre-ebook.com/server.html>
- linuxserver/calibre Docker: <https://hub.docker.com/r/linuxserver/calibre>
- Downloads: <https://calibre-ebook.com/download>
