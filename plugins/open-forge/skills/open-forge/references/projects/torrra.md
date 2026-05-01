---
name: Torrra
description: "CLI + TUI torrent search and download tool. Python/pip/pipx or Docker. stabldev/torrra. Jackett/Prowlarr integration, Textual TUI, libtorrent, pause/resume, config file, themes. MIT."
---

# Torrra

**Command-line torrent search and download tool with a beautiful Textual TUI.** Search torrents without leaving your terminal — powered by Jackett or Prowlarr as the indexer backend. Paste results directly into libtorrent for downloading with pause/resume support. Smart config file, opt-in caching for fast searches, customizable themes.

Built + maintained by **stabldev**. MIT license.

- Upstream repo: <https://github.com/stabldev/torrra>
- Docs: <https://torrra.readthedocs.io>
- PyPI: <https://pypi.org/project/torrra/>
- Docker Hub: <https://hub.docker.com/r/stabldev/torrra>
- AUR: `torrra`
- Homebrew: `Maniacsan/homebrew-torrra`

## Architecture in one minute

- **Python** tool with **Textual** TUI (rich terminal UI framework)
- **Jackett** or **Prowlarr** as indexer backend (you configure which one)
- **libtorrent** for actual torrent downloading
- No server/daemon — runs as a one-shot CLI command or interactive TUI
- Config stored in `~/.config/torrra/config.toml`
- Resource: **tiny** — Python CLI; downloads are libtorrent-bound

## Compatible install methods

| Infra       | Runtime                        | Notes                                               |
| ----------- | ------------------------------ | --------------------------------------------------- |
| **pipx**    | `pipx install torrra`          | **Recommended** — isolated Python env               |
| **pip**     | `pip install torrra`           | Standard Python install                             |
| **uv**      | `uv tool install torrra`       | Fast modern Python tool installer                   |
| **AUR**     | `yay -S torrra`                | Arch Linux                                          |
| **Homebrew**| `brew install Maniacsan/homebrew-torrra/torrra` | macOS                                |
| **Binary**  | GitHub Releases                | Standalone binaries (no Python required)            |
| **Docker**  | `stabldev/torrra`              | Docker Hub                                          |

## Quick start

```bash
# Install
pipx install torrra

# Point to your Jackett instance
torrra config set indexers.jackett.url http://localhost:9117
torrra config set indexers.jackett.api_key your_jackett_api_key
torrra config set indexers.default jackett

# Launch TUI
torrra

# Or search directly
torrra search "arch linux iso"

# Download directly from a magnet/torrent file
torrra download "magnet:?xt=urn:btih:..."
torrra download "/path/to/file.torrent"
```

## Commands

| Command | Description |
|---------|-------------|
| `torrra` | Launch interactive TUI with default indexer |
| `torrra jackett` | Launch TUI using Jackett |
| `torrra prowlarr` | Launch TUI using Prowlarr |
| `torrra search "query"` | Direct search (bypass welcome screen) |
| `torrra download "magnet:..."` | Download from magnet URI |
| `torrra download "file.torrent"` | Download from .torrent file |
| `torrra config set key value` | Set a config value persistently |
| `torrra config get key` | Get a config value |

## Config file (`~/.config/torrra/config.toml`)

```toml
[indexers]
default = "jackett"

[indexers.jackett]
url = "http://localhost:9117"
api_key = "your_api_key"

[indexers.prowlarr]
url = "http://localhost:9696"
api_key = "your_api_key"

[downloads]
path = "~/Downloads"

[ui]
theme = "dark"   # dark, light, or others
```

## Docker run

```bash
docker run -it \
  -e JACKETT_URL=http://jackett:9117 \
  -e JACKETT_API_KEY=your_api_key \
  -v ./downloads:/root/Downloads \
  stabldev/torrra:latest
```

Or with Docker Compose alongside Jackett:

```yaml
services:
  torrra:
    image: stabldev/torrra:latest
    stdin_open: true
    tty: true
    volumes:
      - torrra_config:/root/.config
      - ./downloads:/root/Downloads

  jackett:
    image: linuxserver/jackett
    ports:
      - "9117:9117"
    volumes:
      - jackett_config:/config
    restart: unless-stopped

volumes:
  torrra_config:
  jackett_config:
```

## TUI controls

The Textual-based TUI supports:
- Search bar with instant query submission
- Results table (name, size, seeds, leechers, indexer)
- Select result → download (libtorrent)
- Pause / resume downloads
- Keyboard-first navigation

Full TUI/CLI guide: <https://torrra.readthedocs.io/en/latest/usage.html>

## Indexer setup

Torrra needs either **Jackett** or **Prowlarr** as a backend — it uses their APIs to search across configured torrent indexers.

- **Jackett**: <https://github.com/Jackett/Jackett> — add indexers in Jackett web UI → get API key
- **Prowlarr**: <https://github.com/Prowlarr/Prowlarr> — part of the \*arr ecosystem; integrates with Radarr/Sonarr automatically

## Gotchas

- **Requires Jackett or Prowlarr.** Torrra doesn't search torrent sites directly — it proxies through Jackett/Prowlarr, which handle site-specific scraping. You must have one of these running and configured with your desired indexers before Torrra is useful.
- **`pipx` is recommended.** Using plain `pip install` in a system Python can conflict with system packages. `pipx` installs Torrra in an isolated virtualenv while making it available globally.
- **libtorrent must be available.** On some systems, libtorrent's Python bindings may need separate installation. If you get import errors, install `python3-libtorrent` (Debian/Ubuntu) or `libtorrent-rasterbar` via pip.
- **Docker image is interactive.** The Docker image runs the TUI, which requires a TTY (`-it` flag). Without `-it`, Docker runs the container non-interactively and it exits immediately.
- **Downloads go to `~/Downloads` by default.** Configure `downloads.path` in `config.toml` or pass a volume mount in Docker.
- **Caching.** Torrra caches search results by default for faster repeated searches. Use `--no-cache` to bypass the cache for fresh results.
- **Themes.** Textual supports multiple themes — configure via `ui.theme` in config. Includes dark, light, and more.

## Project health

Active Python development, ReadTheDocs docs, PyPI, AUR, Homebrew, binary releases, Docker Hub. Solo-maintained by stabldev. MIT license.

## Torrent-TUI-family comparison

- **Torrra** — Python+Textual, Jackett/Prowlarr backend, libtorrent, pause/resume, themes, MIT
- **nTorrent** — C++ TUI torrent client; no search integration
- **rtorrent + ruTorrent** — C++ daemon + PHP web UI; more complex; no terminal-native search
- **Transmission CLI** — C, minimal CLI; no search integration
- **qBittorrent** — Qt GUI + web UI; no Jackett/Prowlarr search from CLI
- **Jackett/Prowlarr** — indexer aggregators; Torrra uses these as backends

**Choose Torrra if:** you want to search and download torrents entirely from the terminal using a beautiful Textual TUI, with Jackett or Prowlarr as the indexer backend.

## Links

- Repo: <https://github.com/stabldev/torrra>
- Docs: <https://torrra.readthedocs.io>
- PyPI: <https://pypi.org/project/torrra/>
- Docker Hub: <https://hub.docker.com/r/stabldev/torrra>
