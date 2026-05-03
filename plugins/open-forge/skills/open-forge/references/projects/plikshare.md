# PlikShare

> Self-hosted file sharing application with per-storage encryption, OIDC SSO, shareable "boxes" (embeddable widgets), built-in file preview and editing, and optional AWS Textract (OCR) and ChatGPT integrations. Supports local disk, Cloudflare R2, AWS S3, DigitalOcean Spaces, and Backblaze B2. AGPL-3.0.

**Official URL:** https://plikshare.com  
**Install guide:** https://plikshare.com/download  
**Docker Hub:** https://hub.docker.com/r/damiankrychowski/plikshare  
**GitHub:** https://github.com/damian-krychowski/plikshare

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker (AMD64 / ARM64) | Recommended; single image, all-in-one |
| Any Linux VPS/VM | Docker Compose | For compose-managed deployments |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| Storage backend | Where files are stored | `local` / `s3` / `r2` / `spaces` / `b2` |
| SMTP settings | Required for email notifications, user confirmation | host, port, user, pass |
| `PlikShare_EncryptionPasswords` | Master password for managed encryption (leave empty to skip encryption) | strong random string |

### Phase: Storage Config (in-app)
| Input | Description |
|-------|-------------|
| Storage name | Friendly label for this storage |
| Backend credentials | AWS keys / R2 token / B2 app key (if not local disk) |
| Encryption mode | `none` / `managed` / `full` — set at storage creation, cannot be changed later |

---

## Software-Layer Concerns

### Quick Start (Docker)
```bash
docker run -d \
  --name plikshare \
  -p 8080:8080 \
  -v plikshare_data:/app/data \
  -e PlikShare_EncryptionPasswords="your-master-password" \
  --restart unless-stopped \
  damiankrychowski/plikshare:latest
```

Access at http://localhost:8080 — first user to register becomes admin.

### Two Required Setup Steps
After first launch, configure both in the admin settings:
1. **Email client** — SMTP credentials for notifications, email confirmation, and password reset
2. **Storage** — at least one storage backend (local disk or cloud)

The app prompts for these on first login.

### Encryption Modes
Three modes, chosen **per storage at creation time** — cannot be changed after creation:

| Mode | What's encrypted | Key holder | Threat coverage |
|------|-----------------|------------|-----------------|
| `none` | Nothing | N/A | No file-at-rest protection |
| `managed` | File contents (AES-256-GCM) | Server (master password) | File-storage-only breach |
| `full` | Contents + filenames + audit log fields | Per-user (encryption password) | Full DB + file-storage breach |

- **Managed**: requires `PlikShare_EncryptionPasswords` env var; generates a 24-word BIP-39 recovery code at storage creation — save it
- **Full**: each user sets an encryption password; losing it (without the recovery code) means losing access to their data

### Sharing via Boxes
A "box" connects a folder to the outside world:
1. Create a box → assign a folder
2. Create a link → set permissions (read-only / upload-only / read-write)
3. Share the link, or embed the `<plikshare-box-widget>` web component on another site

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/data` | Database + local file storage — bind-mount or named volume to persist |

### Ports
- Default: `8080` — reverse-proxy with Nginx/Caddy for TLS

---

## Upgrade Procedure

1. Pull latest image: `docker pull damiankrychowski/plikshare:latest`
2. Stop and remove the old container: `docker stop plikshare && docker rm plikshare`
3. Re-run with the same flags and the same data volume
4. DB migrations run automatically on startup

---

## Gotchas

- **Encryption mode is immutable** — chosen at storage creation and cannot be changed; plan the threat model before creating a storage
- **Save the BIP-39 recovery code** — for managed and full encryption, the 24-word code is shown once at storage creation; losing it without the master password / user encryption password means data is unrecoverable
- **SMTP required for user workflows** — without SMTP configured, email confirmation, password reset, and notifications all fail; set it up before inviting users
- **First user is admin** — whoever registers first gets the admin role; secure the URL before going public or pre-register the admin account
- **Full encryption limits server-side features** — Textract OCR and ChatGPT integrations operate on plaintext in memory; they work with full encryption but keys are in process memory during the operation

---

## Links
- Install guide: https://plikshare.com/download
- Docker Hub: https://hub.docker.com/r/damiankrychowski/plikshare
- GitHub: https://github.com/damian-krychowski/plikshare
- Managed encryption design: https://github.com/damian-krychowski/plikshare/blob/main/docs/managed-encryption.md
- Full encryption design: https://github.com/damian-krychowski/plikshare/blob/main/docs/full-encryption.md
