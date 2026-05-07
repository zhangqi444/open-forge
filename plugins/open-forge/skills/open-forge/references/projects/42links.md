---
name: 42links
description: 42links recipe for open-forge. Web-based bookmarking server supporting multiple accounts, HTTP/HTTPS/Gopher links. Common Lisp + PostgreSQL. Source: https://code.rosaelefanten.org/42links
---

# 42links

An open-source, web-based bookmarking server for HTTP, HTTPS, and Gopher links, supporting multiple user accounts. Inspired by Espial but designed to work on OpenBSD. Written in Common Lisp (SBCL), backed by PostgreSQL. BSD-3-Clause-No-Military-License. Upstream: <https://code.rosaelefanten.org/42links>. Website: <https://42links.tuxproject.de>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux / OpenBSD | SBCL (Common Lisp) | PostgreSQL | Build from source; no Docker image provided |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "PostgreSQL host, database, user, password?" | Connection details | Must create empty DB before first run |
| "Port for 42links?" | Number | Configured in app config |
| "Domain?" | FQDN | For reverse proxy |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Reverse proxy?" | NGINX / Caddy / none | Recommended for HTTPS |

## Software-Layer Concerns

- **Common Lisp (SBCL)**: Requires SBCL (Steel Bank Common Lisp) + Quicklisp. Uncommon runtime — factor into your maintenance comfort level.
- **PostgreSQL required**: Empty database + dedicated user must exist before first run. 42links creates its own schema on startup.
- **No Docker image**: Must compile from source. SBCL + Quicklisp setup required.
- **Gopher support**: Can bookmark Gopher-protocol links in addition to HTTP/HTTPS — niche but notable.
- **Multi-account**: Multiple users can have separate bookmark collections on the same instance.
- **Fossil SCM**: Source hosted on Fossil (code.rosaelefanten.org) — not GitHub. Clone with `fossil clone`.

## Deployment

### Prerequisites

```bash
# Install SBCL
apt install sbcl  # Debian/Ubuntu
# or: pkg install sbcl  (OpenBSD)

# Install Quicklisp
curl -O https://beta.quicklisp.org/quicklisp.lisp
sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(ql:add-to-init-file)' --quit
```

### Build and run

```bash
# Clone from Fossil
fossil clone https://code.rosaelefanten.org/42links 42links.fossil
mkdir 42links && cd 42links
fossil open ../42links.fossil

# Configure (edit config file — connection details asked on first run)

# Run
sbcl --eval '(ql:quickload "42links")' --eval '(42links:start)'
```

### PostgreSQL setup

```sql
CREATE USER bookmarks WITH PASSWORD 'yourpassword';
CREATE DATABASE bookmarks OWNER bookmarks;
```

42links will prompt for connection details and create its schema on first start.

## Upgrade Procedure

1. `fossil update` to get latest code.
2. Restart the SBCL process.
3. Check upstream changelog for schema migration notes.

## Gotchas

- **Uncommon runtime**: Common Lisp (SBCL) is a niche technology. Build errors and dependency resolution require familiarity with the Lisp ecosystem.
- **Fossil SCM**: Source is hosted on Fossil, not Git. Use `fossil clone` and `fossil update` — standard `git` commands don't apply.
- **No Docker image**: No official container — must build from source on each target machine.
- **First-run config**: Connection details entered interactively on first run — not via a config file by default.
- **Niche project**: Low stargazer count; likely maintained for personal use. Verify active maintenance before deploying for a team.

## Links

- Source: https://code.rosaelefanten.org/42links
- Website: https://42links.tuxproject.de
- SBCL: http://www.sbcl.org
- Quicklisp: https://www.quicklisp.org/beta/
