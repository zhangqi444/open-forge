---
name: mycart
description: myCart recipe for open-forge. Shopping cart in a single Go binary. Sell files, license keys, or physical goods. SQLite embedded DB, built-in HTTPS, card/crypto payments. Docker or binary install. Source: https://github.com/shurco/mycart
---

# myCart

Single-binary e-commerce shopping cart. Sell digital files, license keys, or physical products. SQLite embedded database — no external DB needed. Built-in HTTPS support, admin dashboard, card and cryptocurrency payment support, multi-language (i18n), free product support (price=0). Written in Go. MIT licensed.

> Previously known as **litecart** — the project was renamed due to a trademark claim. Codebase is unchanged.
> 
> **Status:** v0.x — pre-1.0, no backward compatibility guaranteed yet.

Upstream: <https://github.com/shurco/mycart>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux / macOS | Binary (install script) | Single executable, recommended |
| macOS | Homebrew | `brew install shurco/tap/mycart` |
| Any | Docker | DockerHub + GitHub Packages |
| Any | Docker Compose / Swarm / Kubernetes | Supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Default: 8080 |
| config | Data directories | lc_base (DB), lc_digitals (files), lc_uploads (images), site (templates) |
| config | Payment provider credentials | Stripe, crypto, etc. — configured via admin panel |
| config (optional) | TLS cert/key | For built-in HTTPS; or use a reverse proxy |

## Software-layer concerns

### Architecture

- Single Go binary — serves admin panel + storefront
- SQLite (embedded) — stored in `lc_base/`
- File storage:
  - `lc_digitals/` — downloadable digital products
  - `lc_uploads/` — uploaded images
  - `site/` — customizable frontend templates

### Data dirs (Docker volume mounts)

| Host path | Container path | Description |
|---|---|---|
| `./lc_base` | `/lc_base` | SQLite database |
| `./lc_digitals` | `/lc_digitals` | Digital product files |
| `./lc_uploads` | `/lc_uploads` | Uploaded images |
| `./site` | `/site` | Frontend templates |

## Install — Binary (Linux/macOS)

```bash
# One-command install
curl -L https://raw.githubusercontent.com/shurco/mycart/main/scripts/install | sh

# Initialize (creates data directories and default config)
mycart init

# Run
mycart
# Access at http://localhost:8080
```

## Install — Homebrew (macOS)

```bash
brew install shurco/tap/mycart
mycart init
mycart
```

## Install — Docker

```bash
mkdir mycart && cd mycart

# Initialize data directories
docker run \
  -v ./lc_base:/lc_base \
  -v ./lc_digitals:/lc_digitals \
  -v ./lc_uploads:/lc_uploads \
  -v ./site:/site \
  --rm shurco/mycart:latest init

# Run
docker run \
  --name mycart \
  --restart unless-stopped \
  -p 8080:8080 \
  -v ./lc_base:/lc_base \
  -v ./lc_digitals:/lc_digitals \
  -v ./lc_uploads:/lc_uploads \
  -v ./site:/site \
  shurco/mycart:latest
```

Access admin panel at http://localhost:8080/admin (credentials set during init or first visit).

## Upgrade procedure

```bash
# Binary: re-run install script
curl -L https://raw.githubusercontent.com/shurco/mycart/main/scripts/install | sh

# Docker
docker pull shurco/mycart:latest
docker rm -f mycart
# Re-run docker run command (data dirs preserved via volumes)
```

## Gotchas

- Always run `init` before first start — it creates the SQLite database and required directory structure. Starting without init results in errors.
- v0.x — breaking changes between minor versions are possible before v1.0. Check release notes before upgrading.
- Data directories (lc_base, lc_digitals, lc_uploads, site) must all be mounted if using Docker — missing any will cause runtime errors.
- The project was renamed from `litecart` due to a trademark claim — if upgrading from litecart, references to volume paths and image names have changed.
- Third-party payment integrations (Stripe, crypto) require accounts and API keys configured in the admin panel.
- `depends_3rdparty: true` in upstream catalog — payment processing depends on third-party payment provider APIs.

## Links

- Source: https://github.com/shurco/mycart
- DockerHub: https://hub.docker.com/r/shurco/mycart
- GitHub Packages: https://github.com/shurco/mycart/pkgs/container/mycart
