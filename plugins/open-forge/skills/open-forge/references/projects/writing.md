---
name: Writing
description: Lightweight distraction-free browser-based text editor supporting Markdown and LaTeX/MathJax. No server required — runs as a single HTML file. MIT licensed.
website: https://josephernest.github.io/writing/
source: https://github.com/josephernest/writing
license: MIT
stars: 1114
tags:
  - text-editor
  - markdown
  - latex
  - distraction-free
  - writing
platforms:
  - JavaScript
---

# Writing

Writing is an ultra-minimal distraction-free text editor that runs entirely in the browser as a single HTML file. It supports Markdown rendering and LaTeX/MathJax math equations with no rendering lag or flickering. No server, no installation, no login — just open `index.html` and write.

Source: https://github.com/josephernest/writing  
Live version: https://josephernest.github.io/writing/  
License: MIT

> **Self-hosting note**: "Hosting" Writing means serving a single static HTML file. No backend, database, or runtime required. Any web server (Nginx, Apache, Caddy) or static host (GitHub Pages, S3) works.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any static host | Just a file server | Serve `index.html` — no backend needed |
| Local use | Any browser | Open `index.html` directly from disk — works offline |
| Nginx / Apache | Static file serving | Trivial config |
| GitHub Pages / S3 / Netlify | Static hosting | Zero-config deploy |

## Inputs to Collect

**Phase: Planning**
- Domain/URL to serve from (optional — can just use a file path)
- Whether to serve publicly or locally only

## Software-Layer Concerns

**Deploy (literally):**
```bash
# Clone or download
git clone https://github.com/josephernest/writing /var/www/writing

# Serve with Nginx
# Point root at /var/www/writing — that's it
```

**Nginx config:**
```nginx
server {
    listen 80;
    server_name writing.example.com;
    root /var/www/writing;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
```

**No config files, no environment variables, no database.**

**Keyboard shortcuts:**
- `Ctrl+D` — Toggle display/edit mode (split preview or edit-only)
- `Ctrl+P` — Print or export as PDF
- `Ctrl+S` — Save source as `.md` file
- `Ctrl+Shift+H` or `?` icon — Show help / keyboard shortcuts

**Features:**
- Markdown rendering (via Marked.js)
- LaTeX/MathJax math equations — fast, no flicker
- Split-pane edit + preview, or full-screen edit
- Save as `.md` file
- Print to PDF
- Runs 100% offline once loaded

## Upgrade Procedure

1. `git pull` in the writing directory
2. No build step needed — changes are live immediately

## Gotchas

- **No persistence**: Writing does not save to a server — files are downloaded to your local machine via `Ctrl+S`. There is no cloud sync or server-side storage
- **Single user, single document**: Not a multi-document editor or note-taking system; it's one editor instance per browser tab
- **No collaboration**: No real-time collaboration features
- **Very minimal**: By design — if you need more features (file management, tags, sync), consider Write.as, Hedgedoc, or Joplin
- **Low maintenance**: Repository has very sparse commits in recent years; the project is feature-complete by design
- **Static only**: No API, no webhooks, no plugins

## Links

- Upstream README: https://github.com/josephernest/writing/blob/master/README.md
- Live demo: https://josephernest.github.io/writing/
