# Signature PDF

**Free web app for signing PDFs (solo or multi-party), organizing (merge, sort, rotate, extract pages), editing metadata, and compressing PDFs.**
GitHub: https://github.com/24eme/signaturepdf
Demo instances: https://pdf.24eme.fr, https://framapdf.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Single container, simplest |
| Debian/Ubuntu | Native PHP | See installation.md |
| Alpine Linux | Native PHP | See installation.md |
| YunoHost | YunoHost app | One-click install |

---

## Inputs to Collect

### All phases
- `SERVERNAME` — deployment URL (default: localhost)
- `UPLOAD_MAX_FILESIZE` / `POST_MAX_SIZE` — max PDF size (default: 24M)
- `PDF_STORAGE_PATH` — required only if enabling multi-signature mode (server-side PDF storage)
- `DEFAULT_LANGUAGE` — default: fr_FR.UTF-8; set to en_US.UTF-8 for English

---

## Software-Layer Concerns

### Docker (simplest)
```bash
docker run -d --name=signaturepdf -p 8080:80 xgaia/signaturepdf
```
Access at http://localhost:8080

### Docker with config
```bash
docker run -d --name=signaturepdf -p 8080:80 \
  -e SERVERNAME=pdf.example.org \
  -e UPLOAD_MAX_FILESIZE=48M \
  -e POST_MAX_SIZE=48M \
  -e MAX_FILE_UPLOADS=401 \
  -e PDF_STORAGE_PATH=/data \
  -v ./pdf-data:/data \
  xgaia/signaturepdf
```

### Environment variables
| Variable | Default | Notes |
|----------|---------|-------|
| SERVERNAME | localhost | Public URL |
| UPLOAD_MAX_FILESIZE | 24M | Max upload size |
| POST_MAX_SIZE | 24M | Max POST size |
| MAX_FILE_UPLOADS | 201 | Max pages + original (200 pages = 401) |
| PDF_STORAGE_PATH | /data | For multi-signature mode |
| DISABLE_ORGANIZATION | false | Disable the Organize route |
| PDF_DEMO_LINK | true | Show/hide/change demo PDF link |
| DEFAULT_LANGUAGE | fr_FR.UTF-8 | UI language |
| PDF_STORAGE_ENCRYPTION | false | GPG encryption for stored PDFs |

### Multi-signature mode
Allows multiple people to sign the same PDF; requires server-side PDF storage.
Create config/config.ini from config/config.ini.example and set PDF_STORAGE_PATH.

---

## Upgrade Procedure

1. docker pull xgaia/signaturepdf
2. docker stop/rm signaturepdf && docker run ... (same args)

---

## Gotchas

- Default language is French (fr_FR.UTF-8) — set DEFAULT_LANGUAGE=en_US.UTF-8 for English
- Multi-signature mode is optional — the app works without it for single-signer use
- PDF_STORAGE_ENCRYPTION requires GPG to be installed in the container
- MAX_FILE_UPLOADS should be set to (max pages + 1) — e.g. 401 for 400-page documents
- License: AGPL v3

---

## References
- Installation guide: https://github.com/24eme/signaturepdf/blob/master/installation.md
- GitHub: https://github.com/24eme/signaturepdf#readme
