---
name: geneweb
description: GeneWeb recipe for open-forge. Open-source genealogy software with a web interface. Handles millions of individuals, GEDCOM import/export, privacy controls for living persons. Binary download or build from OCaml source. Source: https://github.com/geneweb/geneweb
---

# GeneWeb

Open-source genealogy software with a built-in web interface, written in OCaml. Powers some of the largest genealogical databases in the world including Roglo (11M+ individuals) and formerly Geneanet. Features: advanced relationship search, GEDCOM import/export, privacy controls for living persons, multi-user web access. Can run locally (desktop) or as a web server. GPL-2.0. Version 7.1 in beta as of 2025.

Upstream: <https://github.com/geneweb/geneweb> | Docs: <https://geneweb.tuxfamily.org/wiki/GeneWeb>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux / macOS / Windows | Pre-built binary release | Easiest — download and run |
| Any | Google Colab notebook | Try in browser with no install |
| Linux | Build from source (OCaml + opam) | For developers or custom builds |
| Linux | systemd service | For persistent web server deployment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port for web server (`gwd`) | Default: 2317 |
| config | Port for setup interface (`gwsetup`) | Default: 2316 |
| config | Data directory | Where genealogy databases are stored |
| config | Public or private access | GeneWeb has built-in privacy controls for living persons |

## Software-layer concerns

### Architecture

GeneWeb consists of two main programs:
- `gwd` — the web server serving genealogy databases (port 2317 by default)
- `gwsetup` — web-based setup/admin tool for creating/managing databases (port 2316)

Databases are stored as flat files in a directory (`bases/` by default). No external database required.

### Data dirs

| Path | Description |
|---|---|
| `bases/` (relative to gwd) | Genealogy database files |
| `gw/` | Binary and config directory (in release package) |

### Command-line flags

```bash
gwd [options]
  -p <port>       Web server port (default 2317)
  -bd <dir>       Database directory
  -conn <n>       Max simultaneous connections
  -auth <file>    Authentication file

gwsetup [options]
  -p <port>       Setup UI port (default 2316)
```

## Install — Binary release (recommended)

```bash
# Download latest release from:
# https://github.com/geneweb/geneweb/releases/latest

# Linux
tar -xzf geneweb-*.tar.gz
cd geneweb-*/gw

# Start the web server
./gwd.sh
# Open http://localhost:2317

# In a separate terminal, start the setup UI (first-time DB creation)
./gwsetup
# Open http://localhost:2316
```

**macOS:**
```bash
# After extracting, authorize the binaries (first time only):
# Right-click gwd → Open → Open in security dialog
# Right-click gwsetup → Open → Open in security dialog
open geneweb.command
```

**Windows:** Double-click `START.htm` in the extracted folder.

## Running as a service (Linux systemd)

```ini
# /etc/systemd/system/geneweb.service
[Unit]
Description=GeneWeb genealogy server
After=network.target

[Service]
Type=simple
User=geneweb
WorkingDirectory=/opt/geneweb/gw
ExecStart=/opt/geneweb/gw/gwd -p 2317 -bd /opt/geneweb/bases
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now geneweb
```

## Running on port 80 (Linux)

```bash
# Grant gwd permission to bind to port 80 without root
sudo setcap 'cap_net_bind_service=+ep' gwd
./gwd -p 80
```

## Build from source

```bash
# Requires OCaml 4.10+ and opam
opam install . --deps-only
ocaml ./configure.ml
make distrib
```

## Upgrade procedure

1. **Export all databases to `.gw` format before upgrading** (critical — database format may change between versions)
2. Download new release
3. Replace binary files
4. Re-import databases if format changed

```bash
# Export a database named 'myfamily'
gwu myfamily > myfamily-backup.gw

# After upgrade, re-import if needed
gwc myfamily-backup.gw -o myfamily
```

## Gotchas

- **Always export `.gw` backups before upgrading** — the internal database format is not guaranteed to be forward-compatible between major versions. `gwu` (export) and `gwc` (import/compile) are the migration tools.
- Version 7.1 is labeled "beta" only because of compatibility with Geneanet's infrastructure — it is stable for self-hosting.
- `gwsetup` is only needed for initial database creation and admin tasks — you can stop it after setup and only run `gwd` for normal access.
- Privacy controls: GeneWeb automatically hides details of living persons from public access — configure access levels in the database settings.
- Port 2317 is the default — if exposing to the internet, put a reverse proxy (nginx/Caddy) in front for TLS.
- macOS Gatekeeper will block the binaries on first run — authorize each binary (`gwd` and `gwsetup`) once via right-click → Open.

## Links

- Source: https://github.com/geneweb/geneweb
- Wiki/docs: https://geneweb.tuxfamily.org/wiki/GeneWeb
- Releases: https://github.com/geneweb/geneweb/releases/latest
- Try in browser: https://github.com/geneweb/geneweb/blob/master/geneweb_colab.ipynb
