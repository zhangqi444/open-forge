# SuperBin

**What it is:** An all-in-one file sharing, URL shortening, and pastebin service. Uses stream-based cryptography for memory-efficient handling of large files, supports password-protected uploads, QR code generation, and curl-based upload. Designed to be extremely easy to deploy and customize.

**Official URL:** https://github.com/Zhoros/SuperBin
**License:** MIT
**Stack:** Go + flat-file storage

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Any Linux VPS / bare metal | Go binary | `go build .` then run directly |
| PaaS (Render, Fly.io, Repl.it) | Docker / native | Works on platform-as-a-service |
| Homelab (Pi, NAS) | Docker Compose | Low resource use |

---

## Inputs to Collect

### Pre-deployment
- `uploads/` directory — create before first run: `mkdir uploads`
- `data/settings.json` — configure file/text size limits, password, and stream settings

### Runtime
- `fileSizeLimitMB` — max file upload size
- `textSizeLimitMB` — max paste text size
- `enablePassword` — site-wide upload password (leave empty to disable)
- `password` — password value if `enablePassword` is true

---

## Software-Layer Concerns

**Docker Compose quick start:**
```bash
git clone https://github.com/Zhoros/SuperBin.git
cd SuperBin
mkdir uploads
docker compose up -d
```

**Binary build (no Docker):**
```bash
# Requires x86_64 gcc installed
go build .
./SuperBin
```

**Config file:** `data/settings.json`
```json
{
  "fileSizeLimitMB": 100,
  "textSizeLimitMB": 10,
  "streamSizeLimitKB": 512,
  "streamThrottleMS": 25,
  "pbkdf2Iterations": 100000,
  "cmdUploadDefaultDurationMinute": 60,
  "enablePassword": false,
  "password": ""
}
```

**Memory/CPU tuning:** Memory usage per second = `streamSizeLimitKB × (1000 / streamThrottleMS)`. Default handles ~40 MB/s. Reduce `streamSizeLimitKB` or increase `streamThrottleMS` for low-spec hardware.

**Theming:** Replace `static/theme.css` with any classless CSS file (e.g. from https://github.com/dbohdan/classless-css).

**Curl upload:**
```bash
curl -F file=@yourfile.txt https://yoursite.com
# With options:
curl -F file=@main.go -F duration=10 -F pass=123 -F burn=true https://yoursite.com
```

**URL shortening:** Paste any `http://` or `https://` URL into the text box — SuperBin auto-detects and creates a short redirect.

**Upgrade procedure:**
1. `docker compose pull && docker compose up -d`
2. Or rebuild binary: `go build .`

---

## Gotchas

- **Flat-file storage** — no database; all uploads stored in `uploads/` directory; back it up regularly
- **Encryption is stream-based** — password-protected content uses AES+pbkdf2; data is never decrypted to disk during download
- **QR code support** — all uploads generate a QR code for easy mobile sharing
- **Short URLs use collision detection** — ambiguous characters (l, i, I, 1) are excluded from generated slugs
- **No built-in HTTPS** — put behind a reverse proxy for TLS in production
- **Site password vs upload password** — `enablePassword` controls a site-wide auth gate; individual upload passwords are separate

---

## Links
- GitHub: https://github.com/Zhoros/SuperBin
- CSS themes: https://github.com/dbohdan/classless-css
