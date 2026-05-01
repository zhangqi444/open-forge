# Nextcloud Notes

**Distraction-free Markdown notes app for Nextcloud — notes saved as files in your Nextcloud storage, with categories, favorites, mobile apps (Android/iOS), and a REST API.**
GitHub: https://github.com/nextcloud/notes

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Nextcloud App Store | Requires existing Nextcloud instance |

---

## Inputs to Collect

### Required
- Existing Nextcloud installation

---

## Software-Layer Concerns

### Installation
1. In Nextcloud, go to **Apps** → **Office** → find **Notes** → click **Enable**
2. Open Notes from the Nextcloud app menu

No separate container or configuration needed — Notes is a Nextcloud app.

### Notes storage
Notes are saved as plain text/Markdown files in your Nextcloud filesystem (default folder: `Notes/`). Viewable and editable with any Nextcloud client.

### Mobile clients
- Android: https://github.com/nextcloud/notes-android
- iOS: https://github.com/nextcloud/notes-ios

### Admin configuration (optional)
Set defaults for new users via `occ`:
```bash
occ config:app:set notes noteMode --value="preview"      # edit | preview
occ config:app:set notes fileSuffix --value=".md"        # .txt | .md
occ config:app:set notes defaultFolder --value="Notes"   # custom folder name
```

### REST API
Notes exposes a JSON REST API for third-party app integration:
https://github.com/nextcloud/notes/blob/master/docs/api/README.md

---

## Upgrade Procedure

Nextcloud will notify you of available app updates. Upgrade from the Apps management page or via `occ app:update notes`.

---

## Gotchas

- Requires an existing Nextcloud instance — this is a Nextcloud app, not a standalone service
- Notes are stored as files — they're accessible from any Nextcloud client (desktop, mobile, web)
- Default file extension is `.txt`; change to `.md` via occ if you prefer Markdown files

---

## References
- REST API docs: https://github.com/nextcloud/notes/blob/master/docs/api/README.md
- GitHub: https://github.com/nextcloud/notes#readme
