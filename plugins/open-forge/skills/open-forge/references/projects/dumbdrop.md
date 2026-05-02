# DumbDrop

**What it is:** Stupidly simple self-hosted file upload app. Drag and drop files into a folder via a clean web interface. No database, no accounts required (optional PIN). Supports directory uploads, file size limits, extension filtering, Apprise notifications, and optional file listing. Built with Node.js and vanilla JS.

**GitHub:** https://github.com/DumbWareio/DumbDrop  
**Docker Hub:** `dumbwareio/dumbdrop`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended |
| Any Linux | Docker run | Single command start |
| Bare metal | Node.js | Run directly |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description | Default |
|----------|-------------|---------|
| `UPLOAD_DIR` | Upload directory inside container | `/app/uploads` |
| `PORT` | Server port | `3000` |

### Phase: Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `BASE_URL` | Full public URL — required for subpath deploys (must end with `/`) | `http://localhost:PORT` |
| `DUMBDROP_PIN` | Optional PIN protection (4–10 digits) | None |
| `DUMBDROP_TITLE` | Title shown in the UI header | `DumbDrop` |
| `MAX_FILE_SIZE` | Max upload size in MB | `1024` |
| `ALLOWED_EXTENSIONS` | Comma-separated list of allowed extensions | None (all) |
| `SHOW_FILE_LIST` | Show uploaded files with download/delete buttons | `false` |
| `AUTO_UPLOAD` | Automatically upload on file selection | `false` |
| `APPRISE_URL` | Apprise URL for upload notifications | None |
| `APPRISE_MESSAGE` | Notification message template | `New file uploaded {filename} ({size}), Storage used {storage}` |
| `TRUST_PROXY` | Trust `X-Forwarded-For` headers (only if behind reverse proxy) | `false` |
| `TRUSTED_PROXY_IPS` | Comma-separated trusted proxy IPs (requires `TRUST_PROXY=true`) | None |
| `ALLOWED_ORIGINS` | CORS origins (defaults to `*`) | `*` |

---

## Software-Layer Concerns

- **No database** — files land directly in the upload directory; no metadata stored
- **Upload directory** (`./uploads` → `/app/uploads`) — mount to desired host path; ensure it's writable
- **`BASE_URL` must end with a trailing slash** if set — app will fail to start without it
- **Reverse proxy note:** Set `TRUST_PROXY=true` only when behind a trusted proxy; prevents PIN brute-force bypass via spoofed IPs
- **Apprise notifications** — supports any Apprise-compatible notification service (Slack, Telegram, Gotify, Discord, etc.)
- **No built-in auth beyond optional PIN** — restrict at network/proxy level for sensitive use

---

## Example Docker Compose

```yaml
services:
  dumbdrop:
    image: dumbwareio/dumbdrop:latest
    container_name: dumbdrop
    ports:
      - "3000:3000"
    volumes:
      - ./uploads:/app/uploads
    environment:
      UPLOAD_DIR: /app/uploads
      MAX_FILE_SIZE: "2048"
      DUMBDROP_PIN: "1234"       # optional
      DUMBDROP_TITLE: "File Drop"
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. No state to migrate — uploaded files stay in the volume

---

## Gotchas

- **`BASE_URL` must end with `/`** if deployed under a subpath — e.g. `https://example.com/drop/`
- **`TRUST_PROXY=false` by default** — enable only behind a known trusted proxy; leaving it on with an untrusted proxy allows PIN bypass
- `SHOW_FILE_LIST=false` by default — enabling it exposes all uploaded files to anyone with access to the UI
- No virus scanning or content validation — treat uploaded files as untrusted

---

## Links

- GitHub: https://github.com/DumbWareio/DumbDrop
- Docker Hub: https://hub.docker.com/r/dumbwareio/dumbdrop
