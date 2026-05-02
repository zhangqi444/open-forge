# Paaster

**What it is:** Secure, privacy-first self-hosted pastebin with end-to-end encryption. Pastes are encrypted client-side before upload — the server never sees plaintext. Features paste history, delete-after-view or TTL expiry, QR code sharing, file drag-and-drop, themes, i18n, and a CLI tool.

**Official site:** https://paaster.io  
**GitHub:** https://github.com/WardPearce/paaster  
**Docker Hub:** `wardpearce/paaster`  
**CLI tool:** https://github.com/WardPearce/paaster-cli

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | App + MongoDB + MinIO (or external S3) |

---

## Stack Components

| Container | Image | Role |
|-----------|-------|------|
| `paaster` | `wardpearce/paaster:latest` | Main app (Svelte frontend + backend) |
| `paaster_mongodb` | `mongo` | Paste metadata storage |
| `paaster_minio` | `quay.io/minio/minio` | Paste content storage (S3-compatible) |

> MinIO can be replaced with any S3-compatible hosted service (AWS S3, Backblaze B2, etc.)

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `COOKIE_SECRET` | Secure random value for cookie signing |
| `S3_ENDPOINT` | S3/MinIO endpoint URL |
| `S3_REGION` | S3 region (e.g. `us-east-1`) |
| `S3_ACCESS_KEY_ID` | S3/MinIO access key |
| `S3_SECRET_ACCESS_KEY` | S3/MinIO secret key |
| `S3_BUCKET` | S3 bucket name for paste storage |
| `s3_FORCE_PATH_STYLE` | Set `true` for MinIO (path-style URLs required) |
| `MONGO_URL` | MongoDB connection string (default `mongodb://paaster_mongodb:27017`) |
| `MONGO_DB` | MongoDB database name (default `paasterv3`) |

### Phase: MinIO (if self-hosting S3)

| Variable | Description |
|----------|-------------|
| `MINIO_ROOT_USER` | MinIO root username |
| `MINIO_ROOT_PASSWORD` | MinIO root password — use a strong random value |

---

## Software-Layer Concerns

- **End-to-end encryption** — encryption happens in the browser; the server stores only ciphertext; decryption key is in the URL fragment (never sent to server)
- **S3 storage is required** — paste content stored in S3/MinIO; MongoDB stores metadata only
- **MinIO must be reverse-proxied** if self-hosting — clients need direct access to MinIO for uploads/downloads; configure CORS accordingly
- **No dynamically loaded 3rd-party dependencies** — all assets bundled at build time for supply chain security
- **CLI tool available** for terminal-based paste creation/retrieval

---

## Reverse Proxy (Caddy example)

```caddy
paaster.example.com {
  reverse_proxy localhost:3015
}

# Required if self-hosting MinIO
s3.paaster.example.com {
  header Access-Control-Allow-Origin "https://paaster.example.com" { defer }
  reverse_proxy localhost:9000
}
```

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. MongoDB and MinIO data persist in volumes

---

## Gotchas

- **MinIO must be publicly accessible** — the browser uploads/downloads paste content directly to MinIO; it cannot be purely internal
- `s3_FORCE_PATH_STYLE: true` is required for MinIO — without it, requests use virtual-hosted style which MinIO may not handle correctly
- **Decryption key is in the URL fragment** — if someone shares only the base URL without the fragment, the paste cannot be decrypted; share the full URL
- CORS must be configured on MinIO to allow requests from the Paaster frontend origin

---

## Links

- Website: https://paaster.io
- GitHub: https://github.com/WardPearce/paaster
- CLI: https://github.com/WardPearce/paaster-cli
