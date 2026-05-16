---
name: Zim
description: Graphical desktop wiki editor that stores pages as plain-text files. Supports links, formatting, images, attachments, plugins (task lists, equation editor, version control), and can export to HTML. GPL-2.0.
website: https://zim-wiki.org/
source: https://github.com/zim-desktop-wiki/zim-desktop-wiki
license: GPL-2.0
stars: 2156
tags:
  - wiki
  - notes
  - knowledge-management
  - desktop
platforms:
  - Python
---

# Zim

Zim is a graphical desktop wiki editor. Pages are stored in plain-text files with wiki markup in a folder hierarchy, making them portable and version-control friendly. It can function as a note archive, daily journal, task manager, or brainstorming tool. A rich plugin ecosystem adds task lists, equation editing (LaTeX), a tray icon, diagram support, and more.

Official site: https://zim-wiki.org/  
Source: https://github.com/zim-desktop-wiki/zim-desktop-wiki  
Docs: https://zim-wiki.org/manual/  
Downloads: https://zim-wiki.org/downloads.html  
Latest release: v0.76.3 (2025)

> **Note**: Zim is a **desktop GUI application** — it runs on a local machine with a graphical interface (GTK3). It is not a web application. Self-hosting context: it can serve a static HTML export, or be run on a server with X11/VNC forwarding.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux desktop / laptop | Python 3.10+ + GTK3 | Primary use case; install via distro package |
| Raspberry Pi (desktop) | Python 3.10+ + GTK3 | Works well on Pi OS with desktop |
| Windows | Installer from website | Official Windows installer available |
| macOS | Python + GTK3 via Homebrew | Supported but less polished |
| Linux server (headless) | X11 forwarding / VNC | Run GUI remotely; or use CLI export mode |

## Inputs to Collect

**Phase: Planning**
- Notebook location (directory path where wiki pages will be stored)
- Whether to sync via cloud storage (Nextcloud, Dropbox, etc.) or git
- Desired plugins (task list, version control, diagram, etc.)

## Software-Layer Concerns

**Install on Debian/Ubuntu:**
```bash
sudo apt install zim
```

**Install on Fedora/RHEL:**
```bash
sudo dnf install zim
```

**Install from source (Python):**
```bash
git clone https://github.com/zim-desktop-wiki/zim-desktop-wiki
cd zim-desktop-wiki
# Run directly without installing:
./zim.py
# Or install:
pip install .
```

**Requirements:**
- Python 3.10+
- GTK+ 3.18+
- python3-gi (PyGObject / GObject Introspection bindings)
- python3-xdg (optional, recommended)
- xdg-utils (optional, Linux)
- python3-pillow (optional, for extended image format support incl. WebP)

**Notebook storage:** All pages stored as `.txt` files with wiki markup in a directory you choose. Subdirectories = sub-pages. Fully portable — back up or sync with any file sync tool.

**CLI export (for server/headless use):**
```bash
# Export entire notebook to HTML
zim --export /path/to/notebook --output /var/www/html/wiki --format html --recursive
```

**Plugins (enabled via Edit → Preferences → Plugins):**
- Task List — GTD-style task tracking across pages
- Version Control — git/bzr/hg integration
- Equation Editor — LaTeX equation rendering
- Diagram Editor — Graphviz diagrams
- Tray Icon — system tray integration

## Upgrade Procedure

1. `sudo apt upgrade zim` (or distro equivalent)
2. From source: `git pull && pip install .`
3. No database migrations — plain-text storage is always backward compatible

## Gotchas

- **Desktop app, not web app**: Zim requires a graphical environment; it is not a web-based wiki like Wiki.js or BookStack
- **No multi-user collaboration**: Designed for single-user use; concurrent access to the same notebook by multiple users is not supported
- **Plain text format**: Pages use a custom wiki markup (not Markdown); conversion possible but not seamless
- **Export for web**: Can export to static HTML for publishing, but the live app requires a desktop session
- **Version control plugin**: Commit/diff support requires git (or bzr/hg) installed; does NOT push automatically — still manual git push
- **Plugin ecosystem**: Many plugins bundled; third-party plugins available at https://github.com/jaap-karssenberg/zim-wiki/wiki/Plugins

## Links

- Upstream README: https://github.com/zim-desktop-wiki/zim-desktop-wiki/blob/master/README.md
- Manual: https://zim-wiki.org/manual/
- Downloads: https://zim-wiki.org/downloads.html
- Plugin list: https://zim-wiki.org/manual/Plugins/
