# SuperBin

> All-in-one file sharing, URL shortener, and pastebin with QR code support, optional password/encryption (AES + PBKDF2), and curl-friendly upload. Stream-based processing means fixed memory/CPU usage regardless of file size. Can run on any platform including PaaS (Render, Fly.io, Repl.it).

**Official URL:** https://github.com/Zhoros/SuperBin

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Easiest; `docker compose up` |
| Any Linux VPS/VM | Binary (Go) | `go build .` — requires x86_64 gcc |
| PaaS (Render, Fly.io, Repl.it) | Container/native | Works out of the box; no DB required |
| Bare metal | Binary | Same as VPS binary path |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `PORT` | HTTP listen port (via settings.json or env) | `8080` |
| `enablePassword` | Whether to require a site-wide upload password | `true` / `false` |
| `password` | Site-wide auth password (use a long value) | strong passphrase |

### Phase: Tuning (optional, via `data/settings.json`)
| Input | Description | Default |
|-------|-------------|---------|
| `fileSizeLimitMB` | Max upload file size | `100` |
| `textSizeLimitMB` | Max paste size | `10` |
| `streamSizeLimitKB` | Buffer size for streaming (controls memory) | `4096` |
| `streamThrottleMS` | Throttle delay per buffer (controls CPU) | `100` |
| `pbkdf2Iterations` | Key derivation iterations for encryption | `100000` |
| `cmdUploadDefaultDurationMinute` | Default expiry for curl uploads | `60` |

---

## Software-Layer Concerns

### Config & Environment
- All settings live in `data/settings.json` — edit before first run or mount via Docker volume
- No database required — files stored directly on disk under `uploads/`
- Memory usage per second = `streamSizeLimitKB × (1000 / streamThrottleMS)` — tune for your hardware

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `./uploads` | Uploaded files and pastes |
| `./data` | `settings.json` configuration |
| `./static/theme.css` | Optional custom CSS theme |

### Docker Compose (minimal)
```yaml
services:
  superbin:
    image: ghcr.io/zhoros/superbin:latest   # or build from source
    ports:
      - "8080:8080"
    volumes:
      - ./uploads:/app/uploads
      - ./data:/app/data
    restart: unless-stopped
```
> Note: the README instructs cloning and running `docker compose up` — build from source if no pre-built image is published.

### Curl Upload
```bash
curl -F file=@myfile.txt -F duration=60 -F pass=secret -F burn=true https://your-superbin.com
# Minimal (no password/expiry):
curl -F file=@myfile.txt https://your-superbin.com
# If site auth is enabled:
curl -F file=@myfile.txt -F auth=sitepassword https://your-superbin.com
```

### Custom Theme
Replace `static/theme.css` with any classless CSS file (see https://github.com/dbohdan/classless-css).

---

## Upgrade Procedure

1. Pull latest: `git pull` (or `docker compose pull` if using a registry image)
2. Rebuild: `docker compose up -d --build`
3. No database migrations needed — file-based storage

---

## Gotchas

- **Upload directory must exist** before starting: `mkdir uploads` (Docker Compose handles this automatically if you use a named volume)
- **Encryption is in-transit only** — password-protected downloads decrypt on the fly; server never writes decrypted data to disk
- **No built-in expiry daemon** — files persist until manually deleted unless the app handles TTL internally; verify behavior in your version
- **Site password ≠ file password** — `enablePassword`/`password` gate the upload form; per-file `pass` encrypts the file itself
- **PaaS ephemeral storage** — on Render/Fly.io, the `uploads/` directory is wiped on redeploy unless you mount persistent storage
- **No built-in TLS** — place behind Nginx/Caddy for HTTPS

---

## Links
- GitHub: https://github.com/Zhoros/SuperBin
- Classless CSS themes: https://github.com/dbohdan/classless-css
