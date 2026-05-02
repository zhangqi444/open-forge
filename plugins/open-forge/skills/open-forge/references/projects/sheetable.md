---
name: sheetable-project
description: SheetAble recipe for open-forge. Self-hosted music sheet organizer. Upload and organize PDF/image sheet music by instrument, composer, or tag. Multi-user with accounts. Go backend + React frontend. Companion iPad/Android tablet app available. Upstream: https://github.com/SheetAble/SheetAble
---

# SheetAble

A self-hosted music sheet organizer. Upload, organize, and browse sheet music PDFs and images — sorted by instrument, composer, tag, or custom category. Multi-user: create accounts for family and friends to share access to the library or let them upload their own sheets. Available as a web app and companion iPad/Android tablet app.

Built with Go (backend) and React (frontend).

Upstream: <https://github.com/SheetAble/SheetAble> | Docs: <https://sheetable.net/docs/Installation/installation> | Tablet app: <https://github.com/SheetAble/tablet-client>

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Docker recommended; Go backend + React frontend |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Web UI port |
| config | "Admin credentials?" | Set on first run or via config |

## Software-layer concerns

For full Docker Compose instructions and environment variable reference, see the official installation docs:

👉 <https://sheetable.net/docs/Installation/installation>

The upstream README links directly to the docs page for production setup — base your deployment on those instructions rather than the development compose in the repo.

### General architecture

- **Backend**: Go API server
- **Frontend**: React SPA served by the Go server or a static file server
- **Storage**: File system for PDFs/images; SQLite or similar for metadata

### Multi-user

Create accounts for friends and family from the admin panel. Users can browse the shared library and optionally upload their own sheets depending on their role.

### Tablet app

A dedicated tablet client (iPad and Android) is available at: <https://github.com/SheetAble/tablet-client>

## Upgrade procedure

Follow the upgrade instructions in the official docs: <https://sheetable.net/docs/Installation/installation>

## Gotchas

- **Follow the docs for production setup** — the GitHub repo README is minimal and defers to the docs site for installation. Always refer to <https://sheetable.net/docs/Installation/installation> for the canonical compose file and environment variables.
- **Large PDF library** — ensure your volume has enough space for your sheet music collection. PDFs can be large; plan storage accordingly.
- **Multi-user permissions** — review the user role docs before inviting others, especially if you don't want all users to be able to upload.

## Links

- Upstream README: <https://github.com/SheetAble/SheetAble>
- Installation docs: <https://sheetable.net/docs/Installation/installation>
- Development guide: <https://sheetable.net/docs/development>
- Tablet client: <https://github.com/SheetAble/tablet-client>
- Discord: <https://discord.com/invite/QnFbxyPbRj>
