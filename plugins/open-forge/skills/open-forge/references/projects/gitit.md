---
name: gitit
description: Gitit recipe for open-forge. Git-backed wiki — pages stored in a git/darcs/mercurial repository, Markdown/reStructuredText/LaTeX markup, plugins, math, syntax highlighting. Haskell/cabal install. Upstream: https://github.com/jgm/gitit
---

# Gitit

Wiki program where every page is stored in a git repository. Edit pages through the web interface or directly with git command-line tools. Supports Markdown, reStructuredText, LaTeX, HTML, DocBook, and Org-mode markup.

2,261 stars · GPL-2.0

Upstream: https://github.com/jgm/gitit
Hackage: https://hackage.haskell.org/package/gitit

## What it is

Gitit provides a wiki backed by version control:

- **Git storage** — Every page and uploaded file stored in a git repository; full version history, diffs, rollback
- **VCS flexibility** — Also supports darcs and Mercurial as backends
- **Rich markup** — pandoc-powered: Markdown (extended), reStructuredText, LaTeX, HTML, DocBook, Emacs Org-mode
- **TeX math** — Display and inline math via MathJax/texmath
- **Syntax highlighting** — Source code blocks highlighted via skylighting
- **Categories** — Tag pages with categories for organization
- **Atom feeds** — Site-wide and per-page Atom feeds
- **Caching** — Built-in page caching for performance
- **Plugins** — Dynamically-loaded Haskell page transformations
- **Authentication** — Local accounts, RPXNOW (OpenID), GitHub
- **Search** — Full-text search across all pages
- **Export** — Export pages in various formats via pandoc
- **Library** — Can be embedded as a Haskell library in other Happstack apps

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Bare metal | Haskell / stack / cabal | Primary install method |
| Docker | Community images | Not officially maintained |
| Reverse proxy | Nginx + gitit | Recommended for production |

## Inputs to collect

### Phase 1 — Pre-install
- Port to run on (default: 5001)
- Repository type (git, darcs, or mercurial)
- Authentication mode (form, github, rpxnow, or none)
- Wiki title and front page name

## Software-layer concerns

### Install via stack (recommended)
  git clone https://github.com/jgm/gitit
  cd gitit
  stack install
  # Binary installed to ~/.local/bin/gitit (add to PATH)

### Install via cabal
  cabal update
  cabal install gitit

### Running gitit
  mkdir /var/wiki && cd /var/wiki
  gitit                    # starts on port 5001
  gitit -p 4000            # custom port
  gitit -f my-config.conf  # custom config file

On first start, gitit creates:
- wikidata/ — git repository with pages
- static/ — static web assets
- templates/ — HStringTemplate templates
- gitit-users — user accounts file
- gitit.log

### Config file (gitit.conf)
Generate a default config: gitit --print-default-config > gitit.conf

Key options:
  port: 5001
  wiki-title: My Wiki
  repository-type: git
  repository-path: wikidata
  authentication-method: form
  require-authentication: modify    # none | read | modify
  default-extension: markdown
  default-page-type: markdown

### Data paths
- wikidata/ — git repository (all wiki pages as .page files + uploaded files)
- gitit-users — user accounts (local auth)
- static/ — CSS, JS, images

### systemd service
  [Unit]
  Description=Gitit Wiki
  After=network.target

  [Service]
  User=wiki
  WorkingDirectory=/var/wiki
  ExecStart=/home/wiki/.local/bin/gitit -f /var/wiki/gitit.conf
  Restart=on-failure

  [Install]
  WantedBy=multi-user.target

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name wiki.example.com;
    location / {
      proxy_pass http://localhost:5001;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
    }
  }

## Upgrade procedure

1. Stop gitit
2. git pull in gitit source directory (or cabal update && cabal install gitit)
3. stack install (rebuilds binary)
4. Start gitit — no database migrations; wiki pages are plain files in git

## Gotchas

- UTF-8 locale required — gitit assumes UTF-8 file encoding; ensure locale is UTF-8 (check with: locale)
- Haskell compilation — stack install compiles from source; expect 10-30 minutes and ~1-2GB disk for dependencies
- No Docker official image — no official maintained Docker image; bare-metal is the standard install
- wikidata is a real git repo — you can push/pull it to/from a remote, use branches, etc.
- Page files use .page extension — actual file is FrontPage.page inside wikidata/
- require-authentication — set to modify to allow public reading with login for editing; none for fully public
- Low activity — minimal commits in recent years; consider alternatives like Wiki.js or DokuWiki for active development and more features
- Plugin system — plugins require Haskell development to write; not for non-Haskell users

## Links

- Upstream README: https://github.com/jgm/gitit/blob/master/README.markdown
- Hackage package: https://hackage.haskell.org/package/gitit
- pandoc: https://pandoc.org (markup processing engine)
