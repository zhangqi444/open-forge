---
name: trilium
description: Trilium Notes recipe for open-forge. Hierarchical note-taking application for building large personal knowledge bases. Actively maintained under TriliumNext/Trilium.
---

# Trilium Notes

Hierarchical, feature-rich note-taking application focused on building large personal knowledge bases. Supports rich text, code notes, mind maps, geo maps, relation maps, scripting, end-to-end encryption, and web clipping.

> ℹ️ **Active fork:** The original `zadam/trilium` repository is succeeded by [`TriliumNext/Trilium`](https://github.com/TriliumNext/Trilium) which is the actively maintained version. Docker image: `triliumnext/trilium`.

Upstream: <https://github.com/TriliumNext/Trilium>. Docs: <https://docs.triliumnotes.org/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted server deployment |
| Desktop app (Electron) | Single-user local use; sync to server optional |
| Binary / deb package | Direct install on Linux server without Docker |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Port to expose Trilium on?" | Default `8080` |
| preflight | "Data directory path on host?" | Persisted as Docker volume; default `~/trilium-data` |

## Docker Compose example

```yaml
version: "3.9"
services:
  trilium:
    image: triliumnext/trilium:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - trilium-data:/home/node/trilium-data

volumes:
  trilium-data:
```

## Software-layer concerns

- Data directory: `/home/node/trilium-data` inside container — always persist this volume
- Default port: `8080`
- First launch: creates an admin password via setup wizard in the browser
- **Sync server mode:** same image can act as a sync server; client desktop apps (Windows/Mac/Linux) sync to it
- OpenID Connect (OIDC) and TOTP MFA supported for server login
- Backup: built-in automatic daily backups to `trilium-data/backup/`; also export via Notes → Export

## Upgrade procedure

1. `docker compose pull trilium`
2. `docker compose up -d trilium`
3. Data volume persists across upgrades

## Gotchas

- **TriliumNext vs zadam:** Use `triliumnext/trilium` image — the original `zadam/trilium` is no longer maintained
- Desktop sync clients connect to the server via a sync URL + password configured in the client
- Large knowledge bases (100k+ notes) are supported but search indexing takes time on first run
- Web clipper browser extension available for Chrome/Firefox
- No multi-user support — single-user application; each user needs their own server instance

## Links

- GitHub (active): <https://github.com/TriliumNext/Trilium>
- Documentation: <https://docs.triliumnotes.org/>
- Docker Hub: <https://hub.docker.com/r/triliumnext/trilium>
- Original repo (archived): <https://github.com/zadam/trilium>
